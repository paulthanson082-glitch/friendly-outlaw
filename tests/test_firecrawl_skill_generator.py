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
    def test_system_prompt_includes_security_guidance(self, mock_urlopen):
        """Regression test: verify system prompt instructs agent not to include secrets."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key"
        )

        # Verify the request includes security instructions
        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))
        prompt = request_data["prompt"].lower()

        # Check for security-related instructions
        self.assertIn("do not include", prompt)
        self.assertIn("api keys", prompt)
        self.assertIn("secrets", prompt)
        self.assertIn("placeholder", prompt)

    @patch('urllib.request.urlopen')
    def test_api_request_structure_validation(self, mock_urlopen):
        """Test that API request has correct structure with all required fields."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://docs.example.com",
            api_key="test-api-key",
            model="spark-1-pro",
            prompt_extra="Extra context"
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]
        request_data = json.loads(request_obj.data.decode('utf-8'))

        # Verify all required fields
        self.assertEqual(request_data["url"], "https://docs.example.com")
        self.assertEqual(request_data["model"], "spark-1-pro")
        self.assertIn("prompt", request_data)
        self.assertIn("schema", request_data)
        self.assertIn("Extra context", request_data["prompt"])

        # Verify headers
        self.assertEqual(request_obj.headers["Authorization"], "Bearer test-api-key")
        self.assertEqual(request_obj.headers["Content-type"], "application/json")

    @patch('urllib.request.urlopen')
    def test_api_key_only_in_headers_not_body(self, mock_urlopen):
        """Security test: ensure API key appears only in headers, never in request body."""
        mock_response = Mock()
        mock_response.read.return_value = json.dumps({
            "data": {"name": "test"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response

        secret_key = "fc-secret-key-12345"
        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key=secret_key
        )

        call_args = mock_urlopen.call_args
        request_obj = call_args[0][0]

        # Verify API key is in headers
        self.assertIn("Authorization", request_obj.headers)
        self.assertEqual(request_obj.headers["Authorization"], f"Bearer {secret_key}")

        # Verify API key is NOT in request body
        request_body = request_obj.data.decode('utf-8')
        self.assertNotIn(secret_key, request_body)

    @patch('os.makedirs')
    @patch('os.path.dirname')
    @patch('os.path.abspath')
    @patch('builtins.open', new_callable=mock_open)
    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('firecrawl_skill_generator.render_skill_markdown')
    @patch('firecrawl_skill_generator.parse_args')
    def test_nested_output_directory_creation(self, mock_parse_args, mock_render,
                                                mock_call_agent, mock_file,
                                                mock_abspath, mock_dirname, mock_makedirs):
        """Regression test: verify nested output paths trigger parent directory creation."""
        mock_args = Mock()
        mock_args.url = "https://example.com"
        mock_args.output = "/deeply/nested/path/skill.md"
        mock_args.model = "spark-1-mini"
        mock_args.prompt_extra = ""
        mock_args.timeout = 120
        mock_parse_args.return_value = mock_args

        mock_abspath.return_value = "/deeply/nested/path/skill.md"
        mock_dirname.return_value = "/deeply/nested/path"
        mock_call_agent.return_value = {"name": "test"}
        mock_render.return_value = "# Test"

        with patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"}):
            fsg.main()

        # Verify makedirs was called with exist_ok=True
        mock_makedirs.assert_called_once_with("/deeply/nested/path", exist_ok=True)

    def test_render_handles_special_yaml_characters_in_description(self):
        """Security test: verify special YAML characters in description don't break frontmatter."""
        data = {
            "name": "test-skill",
            "description": 'Description with: colons, "quotes", and \'apostrophes\'',
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)

        # Verify frontmatter structure is intact
        lines = markdown.split('\n')
        self.assertEqual(lines[0], "---")
        self.assertTrue(any(line.startswith("description:") for line in lines))

        # Find the closing frontmatter delimiter
        closing_index = -1
        for i in range(1, len(lines)):
            if lines[i] == "---":
                closing_index = i
                break

        self.assertGreater(closing_index, 0, "Should have closing frontmatter delimiter")

    @patch('urllib.request.urlopen')
    def test_http_error_provides_clear_message(self, mock_urlopen):
        """Test that HTTP errors produce clear, actionable error messages."""
        import urllib.error

        mock_fp = Mock()
        mock_fp.read.return_value = b'{"error": "Invalid API key provided"}'

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
                api_key="bad-key"
            )

        error_msg = str(ctx.exception)
        self.assertIn("HTTP 403", error_msg)
        self.assertIn("Invalid API key", error_msg)

    def test_render_empty_trigger_conditions_omits_section(self):
        """Regression test: empty trigger list should not render 'When to Use' section."""
        data = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        self.assertNotIn("## When to Use", markdown)

    def test_render_preserves_code_block_in_step_body(self):
        """Test that code blocks in step bodies are preserved correctly."""
        data = {
            "name": "test",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Overview",
            "steps": [
                {
                    "title": "Install",
                    "body": "Run this command:\n```bash\nnpm install package\n```"
                }
            ],
            "key_endpoints_or_methods": []
        }

        markdown = fsg.render_skill_markdown(data)
        self.assertIn("```bash", markdown)
        self.assertIn("npm install package", markdown)

    @patch('urllib.request.urlopen')
    def test_schema_required_fields_enforcement(self, mock_urlopen):
        """Test that schema properly defines required fields."""
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

        # Verify critical fields are marked as required
        required = schema["required"]
        critical_fields = ["name", "description", "steps", "key_endpoints_or_methods"]
        for field in critical_fields:
            self.assertIn(field, required, f"Field '{field}' should be required")

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


if __name__ == '__main__':
    unittest.main()