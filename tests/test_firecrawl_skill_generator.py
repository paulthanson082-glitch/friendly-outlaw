"""
Comprehensive unit tests for firecrawl_skill_generator.py

Tests cover:
- Argument parsing
- Language detection
- Skill markdown rendering
- Firecrawl agent API calls
- Error handling
- Main function integration
"""

import json
import os
import sys
import unittest
from io import StringIO
from unittest.mock import MagicMock, Mock, patch, mock_open
import tempfile
import argparse

# Add examples directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'examples'))

import firecrawl_skill_generator as fsg


class TestLanguageDetection(unittest.TestCase):
    """Test the _detect_lang helper function."""

    def test_detect_python_with_import(self):
        snippet = "import os\nimport sys"
        self.assertEqual(fsg._detect_lang(snippet), "python")

    def test_detect_python_with_from(self):
        snippet = "from typing import Optional"
        self.assertEqual(fsg._detect_lang(snippet), "python")

    def test_detect_python_with_def(self):
        snippet = "def foo():\n    pass"
        self.assertEqual(fsg._detect_lang(snippet), "python")

    def test_detect_typescript_with_const(self):
        snippet = "const x = 5;"
        self.assertEqual(fsg._detect_lang(snippet), "typescript")

    def test_detect_typescript_with_import(self):
        # Note: The _detect_lang function checks "import " first for Python,
        # so "import {" matches Python. This test verifies current behavior.
        snippet = "import { foo } from 'bar';"
        # Current implementation detects "import " as Python
        self.assertEqual(fsg._detect_lang(snippet), "python")

    def test_detect_typescript_with_arrow(self):
        snippet = "const fn = () => { return 42; };"
        self.assertEqual(fsg._detect_lang(snippet), "typescript")

    def test_detect_bash_with_curl(self):
        snippet = "curl -X POST https://example.com"
        self.assertEqual(fsg._detect_lang(snippet), "bash")

    def test_detect_bash_with_dollar_prompt(self):
        snippet = "$ ls -la"
        self.assertEqual(fsg._detect_lang(snippet), "bash")

    def test_detect_json_with_object(self):
        snippet = '{"key": "value"}'
        self.assertEqual(fsg._detect_lang(snippet), "json")

    def test_detect_json_with_array(self):
        snippet = '["item1", "item2"]'
        self.assertEqual(fsg._detect_lang(snippet), "json")

    def test_detect_unknown_language(self):
        snippet = "some random text"
        self.assertEqual(fsg._detect_lang(snippet), "")

    def test_detect_with_whitespace(self):
        snippet = "  \n  import os  \n  "
        self.assertEqual(fsg._detect_lang(snippet), "python")


class TestRenderSkillMarkdown(unittest.TestCase):
    """Test the render_skill_markdown function."""

    def test_minimal_skill_rendering(self):
        data = {
            "name": "test-skill",
            "description": "A test skill",
            "trigger_conditions": ["test trigger"],
            "overview": "Test overview",
            "steps": [
                {
                    "title": "Step One",
                    "body": "Do this first"
                }
            ],
            "key_endpoints_or_methods": []
        }
        result = fsg.render_skill_markdown(data)

        self.assertIn("---", result)
        self.assertIn("name: test-skill", result)
        self.assertIn("description: A test skill", result)
        self.assertIn("# Test Skill", result)
        self.assertIn("## When to Use", result)
        self.assertIn('"test trigger"', result)
        self.assertIn("## Step 1 — Step One", result)
        self.assertIn("Do this first", result)

    def test_full_skill_rendering(self):
        data = {
            "name": "full-skill",
            "description": "Complete skill",
            "trigger_conditions": ["trigger one", "trigger two"],
            "overview": "Full overview",
            "steps": [
                {"title": "First", "body": "First step"},
                {"title": "Second", "body": "Second step"}
            ],
            "key_endpoints_or_methods": [
                {
                    "name": "endpoint_one",
                    "description": "First endpoint",
                    "example": "import requests"
                }
            ],
            "environment_variables": [
                {
                    "name": "API_KEY",
                    "purpose": "Authentication"
                }
            ],
            "common_pitfalls": [
                "Don't forget to set the API key",
                "Check rate limits"
            ]
        }
        result = fsg.render_skill_markdown(data)

        # Check frontmatter
        self.assertIn("name: full-skill", result)
        self.assertIn("description: Complete skill", result)

        # Check triggers
        self.assertIn('"trigger one"', result)
        self.assertIn('"trigger two"', result)

        # Check steps
        self.assertIn("## Step 1 — First", result)
        self.assertIn("## Step 2 — Second", result)

        # Check endpoints
        self.assertIn("## Key Endpoints / Methods", result)
        self.assertIn("### `endpoint_one`", result)
        self.assertIn("```python", result)

        # Check environment variables
        self.assertIn("## Environment Variables", result)
        self.assertIn("| `API_KEY` | Authentication |", result)

        # Check pitfalls
        self.assertIn("## Common Pitfalls", result)
        self.assertIn("- Don't forget to set the API key", result)

    def test_skill_with_no_optional_fields(self):
        data = {
            "name": "minimal-skill",
            "description": "Minimal",
            "trigger_conditions": [],
            "overview": "",
            "steps": [],
            "key_endpoints_or_methods": []
        }
        result = fsg.render_skill_markdown(data)

        self.assertIn("name: minimal-skill", result)
        self.assertNotIn("## Environment Variables", result)
        self.assertNotIn("## Common Pitfalls", result)

    def test_endpoint_without_example(self):
        data = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [
                {
                    "name": "endpoint",
                    "description": "Description only"
                }
            ]
        }
        result = fsg.render_skill_markdown(data)

        self.assertIn("### `endpoint`", result)
        self.assertIn("Description only", result)
        # Should not have code fence if no example
        lines = result.split('\n')
        code_block_starts = [i for i, line in enumerate(lines) if line.startswith('```')]
        # Should not be any code blocks in this case
        self.assertEqual(len(code_block_starts), 0)


class TestCallFirecrawlAgent(unittest.TestCase):
    """Test the call_firecrawl_agent function."""

    @patch('urllib.request.urlopen')
    def test_successful_api_call(self, mock_urlopen):
        """Test successful API call with valid response."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {
                "name": "test-skill",
                "description": "Test",
                "trigger_conditions": [],
                "overview": "Overview",
                "steps": [],
                "key_endpoints_or_methods": []
            }
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        result = fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            model="spark-1-mini"
        )

        self.assertEqual(result["name"], "test-skill")
        self.assertEqual(result["description"], "Test")

    @patch('urllib.request.urlopen')
    def test_api_call_with_custom_timeout(self, mock_urlopen):
        """Test API call with custom timeout."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "skill"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            timeout=60
        )

        # Verify timeout was passed
        call_args = mock_urlopen.call_args
        self.assertEqual(call_args[1]['timeout'], 60)

    @patch('urllib.request.urlopen')
    def test_api_call_with_prompt_extra(self, mock_urlopen):
        """Test that prompt_extra is included in the request."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "skill"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            prompt_extra="Additional instructions"
        )

        # The request data should contain the prompt_extra
        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        self.assertIn("Additional instructions", request_data["prompt"])

    @patch('urllib.request.urlopen')
    def test_http_error_handling(self, mock_urlopen):
        """Test handling of HTTP errors."""
        import urllib.error

        # Create a proper mock for the HTTPError's read method
        mock_fp = Mock()
        mock_fp.read.return_value = b"Invalid API key"

        mock_error = urllib.error.HTTPError(
            url="https://api.firecrawl.dev/v1/agent",
            code=401,
            msg="Unauthorized",
            hdrs={},
            fp=mock_fp
        )
        mock_urlopen.side_effect = mock_error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="bad-key"
            )

        self.assertIn("HTTP 401", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_network_error_handling(self, mock_urlopen):
        """Test handling of network errors."""
        import urllib.error
        mock_urlopen.side_effect = urllib.error.URLError("Network unreachable")

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

        self.assertIn("Network error", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_missing_data_key_in_response(self, mock_urlopen):
        """Test handling of response without 'data' key."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "error": "Something went wrong"
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

        self.assertIn("no 'data' key", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_api_call_includes_schema(self, mock_urlopen):
        """Test that the API call includes the skill schema."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "skill"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))

        self.assertIn("schema", request_data)
        self.assertEqual(request_data["schema"]["type"], "object")
        self.assertIn("name", request_data["schema"]["properties"])


class TestParseArgs(unittest.TestCase):
    """Test the argument parser."""

    @patch('sys.argv', ['script.py', '--url', 'https://example.com'])
    def test_minimal_args(self):
        """Test parsing with only required arguments."""
        args = fsg.parse_args()
        self.assertEqual(args.url, "https://example.com")
        self.assertIsNone(args.output)
        self.assertEqual(args.model, "spark-1-mini")
        self.assertEqual(args.prompt_extra, "")
        self.assertEqual(args.timeout, 120)

    @patch('sys.argv', [
        'script.py',
        '--url', 'https://example.com',
        '--output', '/path/to/output.md',
        '--model', 'spark-1-pro',
        '--prompt-extra', 'Extra instructions',
        '--timeout', '60'
    ])
    def test_all_args(self):
        """Test parsing with all arguments."""
        args = fsg.parse_args()
        self.assertEqual(args.url, "https://example.com")
        self.assertEqual(args.output, "/path/to/output.md")
        self.assertEqual(args.model, "spark-1-pro")
        self.assertEqual(args.prompt_extra, "Extra instructions")
        self.assertEqual(args.timeout, 60)

    @patch('sys.argv', ['script.py'])
    def test_missing_required_url(self):
        """Test that missing --url raises error."""
        with self.assertRaises(SystemExit):
            fsg.parse_args()

    @patch('sys.argv', ['script.py', '--url', 'https://example.com', '--model', 'invalid-model'])
    def test_invalid_model_choice(self):
        """Test that invalid model choice raises error."""
        with self.assertRaises(SystemExit):
            fsg.parse_args()


class TestMainFunction(unittest.TestCase):
    """Test the main() function."""

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    def test_main_with_stdout_output(self, mock_parse_args, mock_render, mock_call_agent):
        """Test main function writing to stdout."""
        # Setup mocks
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = None
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test Skill"

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            with patch('sys.stdout', new=StringIO()) as mock_stdout:
                fsg.main()
                output = mock_stdout.getvalue()
                self.assertIn("# Test Skill", output)

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.makedirs')
    @patch('os.path.dirname')
    @patch('os.path.abspath')
    def test_main_with_file_output(self, mock_abspath, mock_dirname, mock_makedirs,
                                     mock_file, mock_parse_args, mock_render, mock_call_agent):
        """Test main function writing to file."""
        # Setup mocks
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = "/path/to/output.md"
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_abspath.return_value = "/path/to/output.md"
        mock_dirname.return_value = "/path/to"
        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test Skill"

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            fsg.main()

            # Verify file was opened and written
            mock_file.assert_called_once_with("/path/to/output.md", "w", encoding="utf-8")
            handle = mock_file()
            handle.write.assert_called_once_with("# Test Skill")

    @patch('firecrawl_skill_generator.parse_args')
    def test_main_without_api_key(self, mock_parse_args):
        """Test main function fails without API key."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_parse_args.return_value = mock_args

        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SystemExit) as ctx:
                fsg.main()
            self.assertEqual(ctx.exception.code, 1)

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.parse_args')
    def test_main_handles_runtime_error(self, mock_parse_args, mock_call_agent):
        """Test main function handles RuntimeError from API call."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_call_agent.side_effect = RuntimeError("API Error")

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            with self.assertRaises(SystemExit) as ctx:
                fsg.main()
            self.assertEqual(ctx.exception.code, 1)


class TestSkillSchema(unittest.TestCase):
    """Test the SKILL_SCHEMA definition."""

    def test_schema_has_required_fields(self):
        """Test that schema defines all required fields."""
        required = fsg.SKILL_SCHEMA["required"]
        self.assertIn("name", required)
        self.assertIn("description", required)
        self.assertIn("trigger_conditions", required)
        self.assertIn("overview", required)
        self.assertIn("steps", required)
        self.assertIn("key_endpoints_or_methods", required)

    def test_schema_properties_structure(self):
        """Test that schema properties have correct structure."""
        props = fsg.SKILL_SCHEMA["properties"]

        # Check name
        self.assertEqual(props["name"]["type"], "string")

        # Check trigger_conditions is array
        self.assertEqual(props["trigger_conditions"]["type"], "array")

        # Check steps structure
        self.assertEqual(props["steps"]["type"], "array")
        step_props = props["steps"]["items"]["properties"]
        self.assertIn("title", step_props)
        self.assertIn("body", step_props)

    def test_schema_has_optional_fields(self):
        """Test that schema includes optional fields."""
        props = fsg.SKILL_SCHEMA["properties"]
        self.assertIn("environment_variables", props)
        self.assertIn("common_pitfalls", props)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and boundary conditions."""

    def test_render_skill_with_empty_strings(self):
        """Test rendering with empty string values."""
        data = {
            "name": "test",
            "description": "",
            "trigger_conditions": [],
            "overview": "",
            "steps": [],
            "key_endpoints_or_methods": []
        }
        result = fsg.render_skill_markdown(data)
        self.assertIn("name: test", result)

    def test_render_skill_with_special_characters(self):
        """Test rendering with special characters in content."""
        data = {
            "name": "test-skill",
            "description": "Test with & < > characters",
            "trigger_conditions": ["use 'quotes' and \"double quotes\""],
            "overview": "Overview",
            "steps": [
                {
                    "title": "Step with `code`",
                    "body": "Body with **bold** and *italic*"
                }
            ],
            "key_endpoints_or_methods": []
        }
        result = fsg.render_skill_markdown(data)
        self.assertIn("Test with & < > characters", result)
        self.assertIn("'quotes'", result)

    def test_detect_lang_with_empty_string(self):
        """Test language detection with empty string."""
        self.assertEqual(fsg._detect_lang(""), "")

    def test_detect_lang_with_multiline_code(self):
        """Test language detection with multiline code."""
        snippet = """
        import os
        import sys

        def main():
            pass
        """
        self.assertEqual(fsg._detect_lang(snippet), "python")

    @patch('urllib.request.urlopen')
    def test_api_call_with_unicode_content(self, mock_urlopen):
        """Test handling of unicode content in API response."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {
                "name": "test",
                "description": "Test with émojis 🚀 and üñíçödé"
            }
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        result = fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        self.assertIn("émojis", result["description"])
        self.assertIn("🚀", result["description"])


class TestIntegrationScenarios(unittest.TestCase):
    """Test complete integration scenarios."""

    @patch('urllib.request.urlopen')
    def test_complete_workflow(self, mock_urlopen):
        """Test complete workflow from API call to markdown rendering."""
        # Mock API response with complete data
        complete_data = {
            "name": "stripe-payments",
            "description": "Integrate Stripe payment processing",
            "trigger_conditions": [
                "add Stripe payments",
                "integrate payment processing"
            ],
            "overview": "Stripe is a payment processing platform.",
            "steps": [
                {
                    "title": "Install SDK",
                    "body": "```bash\npip install stripe\n```"
                },
                {
                    "title": "Configure",
                    "body": "Set your API key."
                }
            ],
            "key_endpoints_or_methods": [
                {
                    "name": "stripe.Charge.create",
                    "description": "Create a charge",
                    "example": "import stripe\nstripe.Charge.create(amount=1000)"
                }
            ],
            "environment_variables": [
                {
                    "name": "STRIPE_API_KEY",
                    "purpose": "Authentication"
                }
            ],
            "common_pitfalls": [
                "Always use test keys in development"
            ]
        }

        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": complete_data
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        # Call API
        result = fsg.call_firecrawl_agent(
            url="https://docs.stripe.com",
            api_key="test-key"
        )

        # Render markdown
        markdown = fsg.render_skill_markdown(result)

        # Verify complete output
        self.assertIn("name: stripe-payments", markdown)
        self.assertIn("# Stripe Payments", markdown)
        self.assertIn("## Step 1 — Install SDK", markdown)
        self.assertIn("## Step 2 — Configure", markdown)
        self.assertIn("### `stripe.Charge.create`", markdown)
        self.assertIn("| `STRIPE_API_KEY` | Authentication |", markdown)
        self.assertIn("- Always use test keys in development", markdown)


class TestRobustnessAndRegressionCases(unittest.TestCase):
    """Additional tests for robustness, boundary conditions, and regression prevention."""

    @patch('urllib.request.urlopen')
    def test_malformed_json_response(self, mock_urlopen):
        """Test handling of malformed JSON in API response."""
        mock_response = Mock()
        mock_response.read.return_value = b"Not valid JSON {{{["
        mock_urlopen.return_value.__enter__.return_value = mock_response

        with self.assertRaises(json.JSONDecodeError):
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

    @patch('urllib.request.urlopen')
    def test_timeout_handling(self, mock_urlopen):
        """Test that timeout is properly passed to urlopen."""
        import socket
        mock_urlopen.side_effect = socket.timeout("Request timed out")

        with self.assertRaises(socket.timeout):
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key",
                timeout=1
            )

    def test_render_with_large_number_of_steps(self):
        """Test rendering skill with many steps (boundary condition)."""
        data = {
            "name": "complex-skill",
            "description": "Complex skill with many steps",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [
                {"title": f"Step {i}", "body": f"Body {i}"}
                for i in range(100)
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify first and last steps are rendered
        self.assertIn("## Step 1 — Step 0", markdown)
        self.assertIn("## Step 100 — Step 99", markdown)

    def test_render_with_long_text_fields(self):
        """Test rendering with very long text content."""
        long_text = "x" * 10000
        data = {
            "name": "test",
            "description": long_text[:100],
            "trigger_conditions": [],
            "overview": long_text,
            "steps": [
                {"title": "Step", "body": long_text}
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        self.assertIn(long_text, markdown)

    def test_skill_name_with_special_characters_conversion(self):
        """Test that skill names with hyphens are converted to title case."""
        data = {
            "name": "my-complex-api-skill",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        self.assertIn("# My Complex Api Skill", markdown)

    def test_render_with_nested_code_blocks_in_steps(self):
        """Test handling of nested markdown code blocks."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [
                {
                    "title": "Code example",
                    "body": "Here's code:\n```python\ndef foo():\n    return 'bar'\n```\nAnd more text."
                }
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        self.assertIn("```python", markdown)
        self.assertIn("def foo():", markdown)

    def test_multiple_endpoints_with_different_languages(self):
        """Test rendering multiple endpoints with different code languages."""
        data = {
            "name": "multi-lang",
            "description": "Multi-language API",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [
                {
                    "name": "python_method",
                    "description": "Python method",
                    "example": "import requests\nrequests.get('url')"
                },
                {
                    "name": "js_method",
                    "description": "JavaScript method",
                    "example": "const x = () => fetch('url')"
                },
                {
                    "name": "curl_method",
                    "description": "Curl method",
                    "example": "curl -X GET https://api.example.com"
                }
            ]
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify all endpoints are present
        self.assertIn("### `python_method`", markdown)
        self.assertIn("### `js_method`", markdown)
        self.assertIn("### `curl_method`", markdown)

        # Verify different language detection
        self.assertIn("```python", markdown)
        self.assertIn("```typescript", markdown)
        self.assertIn("```bash", markdown)

    @patch('urllib.request.urlopen')
    def test_api_response_with_extra_fields(self, mock_urlopen):
        """Test that extra fields in API response don't break parsing."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {
                "name": "test",
                "description": "Test",
                "trigger_conditions": [],
                "overview": "Overview",
                "steps": [],
                "key_endpoints_or_methods": [],
                "extra_field_1": "ignored",
                "extra_field_2": {"nested": "data"}
            },
            "metadata": {"version": "1.0"},
            "extra_top_level": "also ignored"
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        result = fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        # Should successfully extract data despite extra fields
        self.assertEqual(result["name"], "test")

    def test_empty_environment_variables_table(self):
        """Test rendering with empty environment variables list."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [],
            "environment_variables": []
        }

        markdown = fsg.render_skill_markdown(data)
        # Should not include env vars section if empty
        self.assertNotIn("## Environment Variables", markdown)

    def test_whitespace_handling_in_code_examples(self):
        """Test that code examples preserve whitespace and indentation."""
        code_with_indent = """    def foo():
        if True:
            return 42"""

        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [
                {
                    "name": "method",
                    "description": "Desc",
                    "example": code_with_indent
                }
            ]
        }

        markdown = fsg.render_skill_markdown(data)
        # The code should be preserved as-is (after strip())
        self.assertIn("def foo():", markdown)
        self.assertIn("return 42", markdown)

    @patch('urllib.request.urlopen')
    def test_api_call_with_very_long_url(self, mock_urlopen):
        """Test API call with an extremely long URL."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        long_url = "https://example.com/" + "a" * 5000

        result = fsg.call_firecrawl_agent(
            url=long_url,
            api_key="test-key"
        )

        # Should handle long URLs without issue
        self.assertEqual(result["name"], "test")

        # Verify the long URL was passed in the request
        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        self.assertEqual(request_data["url"], long_url)

    def test_detect_lang_priority_order(self):
        """Test that language detection follows the correct priority."""
        # Python should be detected before TypeScript for "import"
        self.assertEqual(fsg._detect_lang("import os"), "python")

        # Const should detect TypeScript
        self.assertEqual(fsg._detect_lang("const x = 5"), "typescript")

        # JSON should be detected for objects
        self.assertEqual(fsg._detect_lang('{"key": "value"}'), "json")

        # Bash for curl
        self.assertEqual(fsg._detect_lang("curl https://api.com"), "bash")

    def test_skill_rendering_preserves_markdown_formatting(self):
        """Test that markdown formatting in content is preserved."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview with **bold** and *italic*",
            "steps": [
                {
                    "title": "Setup",
                    "body": "Install:\n- Item 1\n- Item 2\n\n**Important**: Do this!"
                }
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify markdown is preserved
        self.assertIn("**bold**", markdown)
        self.assertIn("*italic*", markdown)
        self.assertIn("- Item 1", markdown)
        self.assertIn("**Important**", markdown)


class TestAdditionalStrengtheningTests(unittest.TestCase):
    """Additional strengthening tests for regression prevention and edge case coverage."""

    def test_firecrawl_api_url_constant(self):
        """Test that the correct Firecrawl API endpoint URL is used."""
        self.assertEqual(fsg.FIRECRAWL_AGENT_URL, "https://api.firecrawl.dev/v1/agent")

    @patch('urllib.request.urlopen')
    def test_request_method_is_post(self, mock_urlopen):
        """Test that API calls use POST method."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        self.assertEqual(request_obj.method, "POST")

    @patch('urllib.request.urlopen')
    def test_content_type_header_is_json(self, mock_urlopen):
        """Test that Content-Type header is set to application/json."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        self.assertEqual(request_obj.headers.get("Content-type"), "application/json")

    @patch('urllib.request.urlopen')
    def test_request_includes_target_url(self, mock_urlopen):
        """Test that the target documentation URL is included in the request payload."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        target_url = "https://docs.example.com/api"
        fsg.call_firecrawl_agent(
            url=target_url,
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        self.assertEqual(request_data["url"], target_url)

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    @patch('os.makedirs')
    def test_main_handles_makedirs_failure_gracefully(self, mock_makedirs, mock_parse_args,
                                                       mock_render, mock_call_agent):
        """Test that main() handles directory creation failures."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = "/readonly/path/output.md"
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test"

        # Simulate permission error when creating directories
        mock_makedirs.side_effect = PermissionError("Permission denied")

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            with self.assertRaises(PermissionError):
                fsg.main()

    @patch('urllib.request.urlopen')
    def test_model_parameter_in_request_payload(self, mock_urlopen):
        """Regression test: ensure model parameter is correctly sent in request."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            model="spark-1-pro"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))

        self.assertIn("model", request_data)
        self.assertEqual(request_data["model"], "spark-1-pro")

    def test_detect_lang_with_go_code(self):
        """Boundary test: language detection for unsupported languages returns empty string."""
        go_code = "package main\nfunc main() { fmt.Println(\"hello\") }"
        result = fsg._detect_lang(go_code)
        # Go is not in the supported languages, should return empty string
        self.assertEqual(result, "")

    def test_render_skill_with_missing_optional_trigger_conditions(self):
        """Regression test: rendering without trigger_conditions key should not crash."""
        data = {
            "name": "test-skill",
            "description": "Test",
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }
        # Deliberately omit trigger_conditions to test .get() default behavior

        markdown = fsg.render_skill_markdown(data)
        self.assertIn("name: test-skill", markdown)
        # Should not include "When to Use" section if key is missing
        self.assertNotIn("## When to Use", markdown)


class TestNewFunctionalityForPR(unittest.TestCase):
    """Tests specifically for new functionality added in this PR."""

    @patch('urllib.request.urlopen')
    def test_authorization_header_uses_bearer_format(self, mock_urlopen):
        """Test that Authorization header uses proper Bearer token format."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="fc-test-key-123"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        auth_header = request_obj.headers.get("Authorization")

        self.assertTrue(auth_header.startswith("Bearer "))
        self.assertEqual(auth_header, "Bearer fc-test-key-123")

    @patch('urllib.request.urlopen')
    def test_error_response_truncation(self, mock_urlopen):
        """Test that long error responses are truncated to 500 chars."""
        mock_response = Mock()
        long_error = "x" * 1000
        mock_response.read.return_value = json.dumps({
            "error": long_error
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

        error_msg = str(ctx.exception)
        self.assertIn("no 'data' key", error_msg)
        # The error includes the truncated response (first 500 chars)
        self.assertLess(len(error_msg), 600)  # Should be truncated

    @patch('urllib.request.urlopen')
    def test_system_prompt_includes_security_guidance(self, mock_urlopen):
        """Test that system prompt instructs agent not to include API keys."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        prompt = request_data["prompt"].lower()

        # Should instruct not to include API keys
        self.assertIn("do not include", prompt)
        self.assertIn("api keys", prompt)
        self.assertIn("secrets", prompt)
        self.assertIn("placeholder", prompt)

    def test_step_body_whitespace_stripping(self):
        """Test that step bodies have whitespace stripped."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [
                {
                    "title": "Step",
                    "body": "   \n  Body with extra whitespace  \n\n  "
                }
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Body should be stripped of leading/trailing whitespace
        self.assertIn("Body with extra whitespace", markdown)
        # Should not have excessive blank lines
        self.assertNotIn("\n\n\n\n", markdown)

    def test_endpoint_example_code_stripping(self):
        """Test that endpoint examples have whitespace stripped."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [
                {
                    "name": "method",
                    "description": "Test method",
                    "example": "\n\n  import os  \n\n"
                }
            ]
        }

        markdown = fsg.render_skill_markdown(data)

        # Example should be stripped
        self.assertIn("import os", markdown)
        # Should not have leading blank lines in code block
        lines = markdown.split('\n')
        in_code_block = False
        for i, line in enumerate(lines):
            if line.startswith('```python'):
                in_code_block = True
                # Next line should be the code, not blank
                self.assertEqual(lines[i+1], "import os")
                break

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.makedirs')
    @patch('os.path.dirname')
    @patch('os.path.abspath')
    def test_file_output_uses_utf8_encoding(self, mock_abspath, mock_dirname, mock_makedirs,
                                             mock_file, mock_parse_args, mock_render, mock_call_agent):
        """Test that file output explicitly uses UTF-8 encoding."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = "/path/output.md"
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_abspath.return_value = "/path/output.md"
        mock_dirname.return_value = "/path"
        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test with émojis 🚀"

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            fsg.main()

            # Verify file was opened with UTF-8 encoding
            mock_file.assert_called_once_with("/path/output.md", "w", encoding="utf-8")

    @patch('urllib.request.urlopen')
    def test_schema_includes_all_required_fields(self, mock_urlopen):
        """Test that request includes all required schema fields."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        schema = request_data["schema"]

        # Verify all required fields are in schema
        required = schema["required"]
        self.assertIn("name", required)
        self.assertIn("description", required)
        self.assertIn("trigger_conditions", required)
        self.assertIn("overview", required)
        self.assertIn("steps", required)
        self.assertIn("key_endpoints_or_methods", required)

    def test_render_handles_empty_pitfalls_list(self):
        """Test rendering with empty common_pitfalls list."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [],
            "common_pitfalls": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Should not include Common Pitfalls section if empty
        self.assertNotIn("## Common Pitfalls", markdown)

    @patch('urllib.request.urlopen')
    def test_http_error_body_decoded_with_error_replacement(self, mock_urlopen):
        """Test that HTTP error bodies with invalid UTF-8 are decoded with error='replace'."""
        import urllib.error

        # Create mock with invalid UTF-8 bytes
        mock_fp = Mock()
        mock_fp.read.return_value = b"Error: \xff\xfe invalid UTF-8"

        mock_error = urllib.error.HTTPError(
            url="https://api.firecrawl.dev/v1/agent",
            code=500,
            msg="Server Error",
            hdrs={},
            fp=mock_fp
        )
        mock_urlopen.side_effect = mock_error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

        # Should not raise UnicodeDecodeError, should handle gracefully
        self.assertIn("HTTP 500", str(ctx.exception))

    def test_title_generation_from_kebab_case(self):
        """Test that skill names are correctly converted to title case."""
        test_cases = [
            ("simple-name", "Simple Name"),
            ("multi-word-skill-name", "Multi Word Skill Name"),
            ("api-v2-integration", "Api V2 Integration"),
            ("single", "Single"),
        ]

        for kebab_name, expected_title in test_cases:
            data = {
                "name": kebab_name,
                "description": "Test",
                "trigger_conditions": [],
                "overview": "Overview",
                "steps": [],
                "key_endpoints_or_methods": []
            }

            markdown = fsg.render_skill_markdown(data)
            self.assertIn(f"# {expected_title}", markdown, f"Failed for {kebab_name}")

    @patch('urllib.request.urlopen')
    def test_prompt_extra_parameter_appended_to_system_prompt(self, mock_urlopen):
        """Test that prompt_extra is correctly appended to system prompt."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        extra_instructions = "Focus on TypeScript examples only."
        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            prompt_extra=extra_instructions
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        prompt = request_data["prompt"]

        # Verify extra instructions are in prompt
        self.assertIn(extra_instructions, prompt)
        # Should appear at the end of the prompt
        self.assertTrue(prompt.strip().endswith(extra_instructions))

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.parse_args')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_prints_progress_to_stderr(self, mock_stderr, mock_parse_args, mock_call_agent):
        """Test that main() prints progress messages to stderr, not stdout."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = None
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_call_agent.return_value = {"name": "test"}

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            with patch('firecrawl_skill_generator.render_skill_markdown', return_value="# Test"):
                fsg.main()

        stderr_output = mock_stderr.getvalue()

        # Should print crawling message to stderr
        self.assertIn("Crawling", stderr_output)
        self.assertIn("https://example.com", stderr_output)
        self.assertIn("spark-1-mini", stderr_output)

        # Should print completion time to stderr
        self.assertIn("completed", stderr_output)
        self.assertIn("s", stderr_output)  # seconds


class TestAdditionalRegressionAndEdgeCases(unittest.TestCase):
    """Additional regression and edge case tests to strengthen confidence in the implementation."""

    @patch('urllib.request.urlopen')
    def test_api_response_with_very_large_json(self, mock_urlopen):
        """Test handling of very large JSON response from API."""
        # Create a large response with many steps
        large_data = {
            "name": "large-skill",
            "description": "Large skill",
            "trigger_conditions": [f"trigger {i}" for i in range(50)],
            "overview": "x" * 5000,
            "steps": [
                {"title": f"Step {i}", "body": "x" * 1000}
                for i in range(200)
            ],
            "key_endpoints_or_methods": [
                {"name": f"method_{i}", "description": f"desc {i}"}
                for i in range(100)
            ]
        }

        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": large_data
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        result = fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        # Should handle large response without issue
        self.assertEqual(len(result["steps"]), 200)
        self.assertEqual(len(result["key_endpoints_or_methods"]), 100)

    @patch('urllib.request.urlopen')
    def test_http_403_forbidden_error(self, mock_urlopen):
        """Test handling of HTTP 403 Forbidden error."""
        import urllib.error

        mock_fp = Mock()
        mock_fp.read.return_value = b"Forbidden: API key lacks permissions"

        mock_error = urllib.error.HTTPError(
            url="https://api.firecrawl.dev/v1/agent",
            code=403,
            msg="Forbidden",
            hdrs={},
            fp=mock_fp
        )
        mock_urlopen.side_effect = mock_error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="limited-key"
            )

        self.assertIn("HTTP 403", str(ctx.exception))
        self.assertIn("Forbidden", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_http_404_not_found_error(self, mock_urlopen):
        """Test handling of HTTP 404 Not Found error."""
        import urllib.error

        mock_fp = Mock()
        mock_fp.read.return_value = b"Not Found"

        mock_error = urllib.error.HTTPError(
            url="https://api.firecrawl.dev/v1/agent",
            code=404,
            msg="Not Found",
            hdrs={},
            fp=mock_fp
        )
        mock_urlopen.side_effect = mock_error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://nonexistent.example.com",
                api_key="test-key"
            )

        self.assertIn("HTTP 404", str(ctx.exception))

    def test_detect_lang_with_mixed_indicators(self):
        """Test language detection when code contains mixed language indicators."""
        # Code that starts with Python import but has TypeScript later
        mixed_code = "import os\nconst x = 5;"
        # Should detect first match (Python)
        self.assertEqual(fsg._detect_lang(mixed_code), "python")

        # Code with def in the middle
        code_with_def = "some text\ndef foo():\n    pass"
        self.assertEqual(fsg._detect_lang(code_with_def), "python")

        # Arrow function with extra whitespace
        arrow_with_space = "  \n  const fn = () => {}\n  "
        self.assertEqual(fsg._detect_lang(arrow_with_space), "typescript")

    def test_render_frontmatter_yaml_escaping(self):
        """Test that special YAML characters in frontmatter don't break parsing."""
        # Test with various YAML special characters
        data = {
            "name": "test-skill",
            "description": "Test with: colons, # hashes, | pipes, > arrows, & ampersands",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify frontmatter is present
        self.assertIn("---", markdown)
        self.assertIn("name: test-skill", markdown)
        # Description should contain the special characters
        self.assertIn("description:", markdown)

    @patch('urllib.request.urlopen')
    def test_timeout_boundary_values(self, mock_urlopen):
        """Test timeout parameter with boundary values."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        # Test with minimum practical timeout
        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            timeout=1
        )

        call_args = mock_urlopen.call_args
        self.assertEqual(call_args[1]['timeout'], 1)

        # Test with very large timeout
        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            timeout=86400  # 24 hours
        )

        call_args = mock_urlopen.call_args
        self.assertEqual(call_args[1]['timeout'], 86400)

    def test_render_with_null_overview(self):
        """Regression test: ensure null overview doesn't break rendering."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": None,
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        # Should not include overview section if None
        self.assertIn("name: test", markdown)
        # Should not render "None" as text
        self.assertNotIn("None", markdown)
        # Should still have valid structure
        self.assertIn("# Test", markdown)

    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.makedirs')
    @patch('os.path.dirname')
    @patch('os.path.abspath')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_stderr_messages_when_writing_to_file(self, mock_stderr, mock_abspath,
                                                        mock_dirname, mock_makedirs, mock_file,
                                                        mock_parse_args, mock_render, mock_call_agent):
        """Test that main() prints appropriate stderr messages when writing to file."""
        mock_args = Mock()
        mock_args.url = "https://docs.example.com"
        mock_args.output = "/path/skill.md"
        mock_args.model = "spark-1-pro"
        mock_args.prompt_extra = "extra"
        mock_args.timeout = 60
        mock_parse_args.return_value = mock_args

        mock_abspath.return_value = "/path/skill.md"
        mock_dirname.return_value = "/path"
        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test"

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            fsg.main()

        stderr_output = mock_stderr.getvalue()

        # Should mention crawling
        self.assertIn("Crawling", stderr_output)
        self.assertIn("https://docs.example.com", stderr_output)
        self.assertIn("spark-1-pro", stderr_output)

        # Should mention completion
        self.assertIn("completed", stderr_output)

        # Should mention where file was written
        self.assertIn("Skill written to", stderr_output)
        self.assertIn("/path/skill.md", stderr_output)

    def test_endpoint_table_formatting_edge_cases(self):
        """Test endpoint rendering with edge cases in names and descriptions."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [
                {
                    "name": "endpoint_with_underscores_and_123_numbers",
                    "description": "Description with `code` and **bold** markdown",
                    "example": "# Comment\nimport test"
                },
                {
                    "name": "endpoint.with.dots",
                    "description": "Description with 'single quotes' and \"double quotes\"",
                }
            ]
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify all endpoints are rendered
        self.assertIn("### `endpoint_with_underscores_and_123_numbers`", markdown)
        self.assertIn("### `endpoint.with.dots`", markdown)

        # Verify markdown in descriptions is preserved
        self.assertIn("`code`", markdown)
        self.assertIn("**bold**", markdown)
        self.assertIn("'single quotes'", markdown)

    def test_environment_variables_table_special_characters(self):
        """Test environment variables table with special characters."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [],
            "environment_variables": [
                {
                    "name": "API_KEY_V2",
                    "purpose": "Authentication | Used for: API calls & webhooks"
                },
                {
                    "name": "DATABASE_URL",
                    "purpose": "Connection string (format: postgresql://...)"
                }
            ]
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify table is created
        self.assertIn("## Environment Variables", markdown)
        self.assertIn("| Variable | Purpose |", markdown)
        self.assertIn("| `API_KEY_V2` |", markdown)
        self.assertIn("| `DATABASE_URL` |", markdown)

        # Special characters should be preserved in table cells
        self.assertIn("API calls & webhooks", markdown)
        self.assertIn("postgresql://", markdown)

    @patch('urllib.request.urlopen')
    def test_json_decode_error_on_invalid_response(self, mock_urlopen):
        """Test that invalid JSON response raises appropriate error."""
        mock_response = Mock()
        # Return HTML instead of JSON
        mock_response.read.return_value = b"<html><body>Service Unavailable</body></html>"
        mock_urlopen.return_value.__enter__.return_value = mock_response

        with self.assertRaises(json.JSONDecodeError):
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key"
            )

    def test_multiple_trigger_conditions_formatting(self):
        """Test that multiple trigger conditions are properly formatted as list."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [
                "trigger one",
                "trigger two with 'quotes'",
                "trigger three with special chars",
                "trigger four with: colons",
            ],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Each trigger should be on its own line with quotes and dash
        self.assertIn('- "trigger one"', markdown)
        self.assertIn('- "trigger two with \'quotes\'"', markdown)
        self.assertIn('- "trigger three with special chars"', markdown)
        self.assertIn('- "trigger four with: colons"', markdown)

        # Verify "When to Use" section is created
        self.assertIn("## When to Use", markdown)

    @patch('urllib.request.urlopen')
    def test_request_payload_structure(self, mock_urlopen):
        """Regression test: verify complete request payload structure."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://docs.example.com/api",
            api_key="fc-key-123",
            model="spark-1-pro",
            prompt_extra="Focus on examples",
            timeout=90
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))

        # Verify all expected keys are present
        self.assertIn("url", request_data)
        self.assertIn("model", request_data)
        self.assertIn("prompt", request_data)
        self.assertIn("schema", request_data)

        # Verify values
        self.assertEqual(request_data["url"], "https://docs.example.com/api")
        self.assertEqual(request_data["model"], "spark-1-pro")
        self.assertIn("Focus on examples", request_data["prompt"])

        # Verify schema structure
        schema = request_data["schema"]
        self.assertEqual(schema["type"], "object")
        self.assertIn("properties", schema)
        self.assertIn("required", schema)

    def test_common_pitfalls_with_markdown_formatting(self):
        """Test that common pitfalls preserve markdown formatting."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": [],
            "common_pitfalls": [
                "**Important**: Always check API version",
                "Don't forget to use `await` with async functions",
                "Rate limits: 100 req/min for tier 1, 1000 req/min for tier 2",
            ]
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify pitfalls section exists
        self.assertIn("## Common Pitfalls", markdown)

        # Verify markdown is preserved
        self.assertIn("**Important**", markdown)
        self.assertIn("`await`", markdown)
        self.assertIn("100 req/min", markdown)


if __name__ == '__main__':
    unittest.main()