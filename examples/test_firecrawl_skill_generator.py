"""
Unit tests for firecrawl_skill_generator.py

Tests cover:
- Schema validation
- Firecrawl API interaction (mocked)
- Markdown rendering
- Language detection
- CLI argument parsing
- Error handling
"""

import json
import os
import sys
import unittest
from io import StringIO
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import urllib.error
import urllib.request

# Import the module under test
import firecrawl_skill_generator as fsg


class TestSkillSchema(unittest.TestCase):
    """Test the SKILL_SCHEMA definition."""

    def test_schema_has_required_fields(self):
        """Verify schema contains all required top-level fields."""
        self.assertIn("type", fsg.SKILL_SCHEMA)
        self.assertEqual(fsg.SKILL_SCHEMA["type"], "object")
        self.assertIn("properties", fsg.SKILL_SCHEMA)
        self.assertIn("required", fsg.SKILL_SCHEMA)

    def test_schema_required_fields(self):
        """Verify required fields list is correct."""
        required = fsg.SKILL_SCHEMA["required"]
        expected = [
            "name",
            "description",
            "trigger_conditions",
            "overview",
            "steps",
            "key_endpoints_or_methods",
        ]
        self.assertEqual(required, expected)

    def test_schema_properties_structure(self):
        """Verify all required properties are defined in schema."""
        props = fsg.SKILL_SCHEMA["properties"]
        for field in fsg.SKILL_SCHEMA["required"]:
            self.assertIn(field, props)
            self.assertIn("type", props[field])


class TestLanguageDetection(unittest.TestCase):
    """Test the _detect_lang helper function."""

    def test_detect_python(self):
        """Should detect Python code."""
        self.assertEqual(fsg._detect_lang("import os"), "python")
        self.assertEqual(fsg._detect_lang("from typing import List"), "python")
        self.assertEqual(fsg._detect_lang("def foo():\n    pass"), "python")
        # Note: "import " matches Python even with braces (heuristic limitation)
        self.assertEqual(fsg._detect_lang("import { something }"), "python")

    def test_detect_typescript(self):
        """Should detect TypeScript/JavaScript code."""
        self.assertEqual(fsg._detect_lang("const x = 5;"), "typescript")
        self.assertEqual(fsg._detect_lang("const fn = () => {}"), "typescript")
        self.assertEqual(fsg._detect_lang("x => x * 2"), "typescript")

    def test_detect_bash(self):
        """Should detect Bash code."""
        self.assertEqual(fsg._detect_lang("curl https://example.com"), "bash")
        self.assertEqual(fsg._detect_lang("$ ls -la"), "bash")

    def test_detect_json(self):
        """Should detect JSON code."""
        self.assertEqual(fsg._detect_lang('{"key": "value"}'), "json")
        self.assertEqual(fsg._detect_lang('["item1", "item2"]'), "json")

    def test_detect_unknown(self):
        """Should return empty string for unknown code."""
        self.assertEqual(fsg._detect_lang("some random text"), "")
        self.assertEqual(fsg._detect_lang(""), "")


class TestRenderSkillMarkdown(unittest.TestCase):
    """Test the render_skill_markdown function."""

    def setUp(self):
        """Set up test data."""
        self.minimal_data = {
            "name": "test-skill",
            "description": "Test skill description",
            "trigger_conditions": ["test trigger"],
            "overview": "Test overview",
            "steps": [
                {"title": "Step One", "body": "Do something"}
            ],
            "key_endpoints_or_methods": [
                {"name": "test_method", "description": "Test method description"}
            ],
        }

    def test_render_minimal_skill(self):
        """Should render a minimal valid skill file."""
        result = fsg.render_skill_markdown(self.minimal_data)

        # Check frontmatter
        self.assertIn("---", result)
        self.assertIn("name: test-skill", result)
        self.assertIn("description: Test skill description", result)

        # Check title
        self.assertIn("# Test Skill", result)

        # Check overview
        self.assertIn("Test overview", result)

        # Check trigger conditions
        self.assertIn("## When to Use", result)
        self.assertIn('"test trigger"', result)

        # Check steps
        self.assertIn("## Step 1 — Step One", result)
        self.assertIn("Do something", result)

        # Check endpoints
        self.assertIn("## Key Endpoints / Methods", result)
        self.assertIn("`test_method`", result)

    def test_render_with_environment_variables(self):
        """Should render environment variables as a table."""
        data = self.minimal_data.copy()
        data["environment_variables"] = [
            {"name": "API_KEY", "purpose": "Authentication token"},
            {"name": "BASE_URL", "purpose": "API base URL"},
        ]

        result = fsg.render_skill_markdown(data)

        self.assertIn("## Environment Variables", result)
        self.assertIn("| Variable | Purpose |", result)
        self.assertIn("| `API_KEY` | Authentication token |", result)
        self.assertIn("| `BASE_URL` | API base URL |", result)

    def test_render_with_common_pitfalls(self):
        """Should render common pitfalls as a bullet list."""
        data = self.minimal_data.copy()
        data["common_pitfalls"] = [
            "Don't forget to set the API key",
            "Rate limits apply",
        ]

        result = fsg.render_skill_markdown(data)

        self.assertIn("## Common Pitfalls", result)
        self.assertIn("- Don't forget to set the API key", result)
        self.assertIn("- Rate limits apply", result)

    def test_render_with_code_examples(self):
        """Should render code examples with language detection."""
        data = self.minimal_data.copy()
        data["key_endpoints_or_methods"] = [
            {
                "name": "create_user",
                "description": "Creates a new user",
                "example": "import requests\nresponse = requests.post('/users')",
            }
        ]

        result = fsg.render_skill_markdown(data)

        self.assertIn("```python", result)
        self.assertIn("import requests", result)
        self.assertIn("```", result)

    def test_render_multiple_steps(self):
        """Should render multiple steps in order."""
        data = self.minimal_data.copy()
        data["steps"] = [
            {"title": "First", "body": "Do first thing"},
            {"title": "Second", "body": "Do second thing"},
            {"title": "Third", "body": "Do third thing"},
        ]

        result = fsg.render_skill_markdown(data)

        self.assertIn("## Step 1 — First", result)
        self.assertIn("## Step 2 — Second", result)
        self.assertIn("## Step 3 — Third", result)


class TestCallFirecrawlAgent(unittest.TestCase):
    """Test the call_firecrawl_agent function."""

    @patch('urllib.request.urlopen')
    def test_successful_api_call(self, mock_urlopen):
        """Should successfully call Firecrawl API and parse response."""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "data": {
                "name": "test-skill",
                "description": "Test description",
                "trigger_conditions": ["test"],
                "overview": "Overview",
                "steps": [],
                "key_endpoints_or_methods": [],
            }
        }).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        result = fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
        )

        self.assertIn("name", result)
        self.assertEqual(result["name"], "test-skill")
        mock_urlopen.assert_called_once()

    @patch('urllib.request.urlopen')
    def test_api_call_with_custom_model(self, mock_urlopen):
        """Should pass model parameter to API."""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"data": {}}).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            model="spark-1-pro",
        )

        # Verify the request was made with correct model
        call_args = mock_urlopen.call_args
        request = call_args[0][0]
        body = json.loads(request.data.decode('utf-8'))
        self.assertEqual(body["model"], "spark-1-pro")

    @patch('urllib.request.urlopen')
    def test_api_call_with_extra_prompt(self, mock_urlopen):
        """Should append extra prompt text."""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"data": {}}).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
            prompt_extra="Additional instructions",
        )

        call_args = mock_urlopen.call_args
        request = call_args[0][0]
        body = json.loads(request.data.decode('utf-8'))
        self.assertIn("Additional instructions", body["prompt"])

    @patch('urllib.request.urlopen')
    def test_api_http_error(self, mock_urlopen):
        """Should raise RuntimeError on HTTP error."""
        # Create a proper mock HTTPError with a read() method
        error_fp = StringIO('{"error": "invalid request"}')
        error = urllib.error.HTTPError(
            url="https://example.com",
            code=400,
            msg="Bad Request",
            hdrs={},
            fp=error_fp,
        )
        # Mock the read() method to return bytes
        error.read = MagicMock(return_value=b'{"error": "invalid request"}')
        mock_urlopen.side_effect = error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key",
            )

        self.assertIn("HTTP 400", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_api_network_error(self, mock_urlopen):
        """Should raise RuntimeError on network error."""
        error = urllib.error.URLError("Connection refused")
        mock_urlopen.side_effect = error

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key",
            )

        self.assertIn("Network error", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_api_missing_data_key(self, mock_urlopen):
        """Should raise RuntimeError when response missing 'data' key."""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"status": "ok"}).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        with self.assertRaises(RuntimeError) as ctx:
            fsg.call_firecrawl_agent(
                url="https://example.com",
                api_key="test-key",
            )

        self.assertIn("no 'data' key", str(ctx.exception))

    @patch('urllib.request.urlopen')
    def test_api_includes_schema(self, mock_urlopen):
        """Should include SKILL_SCHEMA in API request."""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"data": {}}).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        fsg.call_firecrawl_agent(
            url="https://example.com",
            api_key="test-key",
        )

        call_args = mock_urlopen.call_args
        request = call_args[0][0]
        body = json.loads(request.data.decode('utf-8'))
        self.assertIn("schema", body)
        self.assertEqual(body["schema"], fsg.SKILL_SCHEMA)


class TestParseArgs(unittest.TestCase):
    """Test the parse_args CLI argument parser."""

    def test_parse_minimal_args(self):
        """Should parse minimal required arguments."""
        test_args = ["prog", "--url", "https://example.com"]
        with patch.object(sys, 'argv', test_args):
            args = fsg.parse_args()
            self.assertEqual(args.url, "https://example.com")
            self.assertIsNone(args.output)
            self.assertEqual(args.model, "spark-1-mini")

    def test_parse_with_output(self):
        """Should parse output file path."""
        test_args = ["prog", "--url", "https://example.com", "--output", "skill.md"]
        with patch.object(sys, 'argv', test_args):
            args = fsg.parse_args()
            self.assertEqual(args.output, "skill.md")

    def test_parse_with_model(self):
        """Should parse model selection."""
        test_args = ["prog", "--url", "https://example.com", "--model", "spark-1-pro"]
        with patch.object(sys, 'argv', test_args):
            args = fsg.parse_args()
            self.assertEqual(args.model, "spark-1-pro")

    def test_parse_with_timeout(self):
        """Should parse custom timeout."""
        test_args = ["prog", "--url", "https://example.com", "--timeout", "60"]
        with patch.object(sys, 'argv', test_args):
            args = fsg.parse_args()
            self.assertEqual(args.timeout, 60)

    def test_parse_with_prompt_extra(self):
        """Should parse extra prompt text."""
        test_args = ["prog", "--url", "https://example.com", "--prompt-extra", "More info"]
        with patch.object(sys, 'argv', test_args):
            args = fsg.parse_args()
            self.assertEqual(args.prompt_extra, "More info")

    def test_missing_required_url(self):
        """Should exit when required --url is missing."""
        test_args = ["prog"]
        with patch.object(sys, 'argv', test_args):
            with self.assertRaises(SystemExit):
                fsg.parse_args()


class TestMain(unittest.TestCase):
    """Test the main function."""

    @patch.dict(os.environ, {}, clear=True)
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_missing_api_key(self, mock_stderr):
        """Should exit with error when FIRECRAWL_API_KEY is missing."""
        test_args = ["prog", "--url", "https://example.com"]
        with patch.object(sys, 'argv', test_args):
            with self.assertRaises(SystemExit) as ctx:
                fsg.main()

            self.assertEqual(ctx.exception.code, 1)
            self.assertIn("FIRECRAWL_API_KEY", mock_stderr.getvalue())

    @patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"})
    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_success_to_stdout(self, mock_stderr, mock_call):
        """Should output to stdout when no output file specified."""
        mock_call.return_value = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": ["test"],
            "overview": "Test overview",
            "steps": [{"title": "Step", "body": "Body"}],
            "key_endpoints_or_methods": [],
        }

        test_args = ["prog", "--url", "https://example.com"]
        with patch.object(sys, 'argv', test_args):
            with patch('sys.stdout', new_callable=StringIO) as mock_stdout:
                fsg.main()

                output = mock_stdout.getvalue()
                self.assertIn("name: test-skill", output)
                self.assertIn("# Test Skill", output)

    @patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"})
    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_success_to_file(self, mock_stderr, mock_call):
        """Should write to file when output path specified."""
        mock_call.return_value = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": ["test"],
            "overview": "Test overview",
            "steps": [{"title": "Step", "body": "Body"}],
            "key_endpoints_or_methods": [],
        }

        with tempfile.TemporaryDirectory() as tmpdir:
            output_file = os.path.join(tmpdir, "test-skill.md")
            test_args = ["prog", "--url", "https://example.com", "--output", output_file]

            with patch.object(sys, 'argv', test_args):
                fsg.main()

                self.assertTrue(os.path.exists(output_file))
                with open(output_file, 'r') as f:
                    content = f.read()
                    self.assertIn("name: test-skill", content)

    @patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"})
    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_api_error(self, mock_stderr, mock_call):
        """Should exit with error on API failure."""
        mock_call.side_effect = RuntimeError("API error")

        test_args = ["prog", "--url", "https://example.com"]
        with patch.object(sys, 'argv', test_args):
            with self.assertRaises(SystemExit) as ctx:
                fsg.main()

            self.assertEqual(ctx.exception.code, 1)
            self.assertIn("Error:", mock_stderr.getvalue())

    @patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"})
    @patch('firecrawl_skill_generator.call_firecrawl_agent')
    @patch('sys.stderr', new_callable=StringIO)
    def test_main_creates_output_directory(self, mock_stderr, mock_call):
        """Should create output directory if it doesn't exist."""
        mock_call.return_value = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": ["test"],
            "overview": "Test overview",
            "steps": [{"title": "Step", "body": "Body"}],
            "key_endpoints_or_methods": [],
        }

        with tempfile.TemporaryDirectory() as tmpdir:
            nested_path = os.path.join(tmpdir, "nested", "dir", "skill.md")
            test_args = ["prog", "--url", "https://example.com", "--output", nested_path]

            with patch.object(sys, 'argv', test_args):
                fsg.main()

                self.assertTrue(os.path.exists(nested_path))


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and boundary conditions."""

    def test_render_empty_arrays(self):
        """Should handle empty optional arrays gracefully."""
        data = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": [],
            "overview": "Test overview",
            "steps": [],
            "key_endpoints_or_methods": [],
            "environment_variables": [],
            "common_pitfalls": [],
        }

        result = fsg.render_skill_markdown(data)

        # Should still have basic structure
        self.assertIn("name: test-skill", result)
        self.assertIn("# Test Skill", result)

        # Optional sections should not appear
        self.assertNotIn("## When to Use", result)
        self.assertNotIn("## Environment Variables", result)
        self.assertNotIn("## Common Pitfalls", result)

    def test_render_missing_optional_fields(self):
        """Should handle missing optional fields."""
        data = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": ["test"],
            "overview": "Test overview",
            "steps": [{"title": "Step", "body": "Body"}],
            "key_endpoints_or_methods": [],
        }
        # Note: environment_variables and common_pitfalls are not present

        result = fsg.render_skill_markdown(data)
        self.assertIn("name: test-skill", result)

    def test_detect_lang_with_multiline(self):
        """Should detect language from multiline code."""
        python_code = """
import sys
def main():
    print("hello")
"""
        self.assertEqual(fsg._detect_lang(python_code), "python")

    def test_render_with_special_characters(self):
        """Should handle special markdown characters in content."""
        data = {
            "name": "test-skill",
            "description": "Test with *asterisks* and _underscores_",
            "trigger_conditions": ["test `code` here"],
            "overview": "Overview with **bold** text",
            "steps": [{"title": "Step #1", "body": "Body with | pipes |"}],
            "key_endpoints_or_methods": [],
        }

        result = fsg.render_skill_markdown(data)
        # Should preserve special characters
        self.assertIn("*asterisks*", result)
        self.assertIn("`code`", result)
        self.assertIn("**bold**", result)

    def test_render_endpoint_without_example(self):
        """Should render endpoint even without example code."""
        data = {
            "name": "test-skill",
            "description": "Test",
            "trigger_conditions": ["test"],
            "overview": "Test overview",
            "steps": [{"title": "Step", "body": "Body"}],
            "key_endpoints_or_methods": [
                {"name": "method_name", "description": "Description only, no example"}
            ],
        }

        result = fsg.render_skill_markdown(data)
        self.assertIn("`method_name`", result)
        self.assertIn("Description only", result)
        # Should not have code fence without example
        self.assertNotIn("```", result)


class TestIntegrationScenarios(unittest.TestCase):
    """Integration-style tests simulating real usage scenarios."""

    @patch.dict(os.environ, {"FIRECRAWL_API_KEY": "test-key"})
    @patch('urllib.request.urlopen')
    def test_full_pipeline_success(self, mock_urlopen):
        """Test complete pipeline from API call to file output."""
        # Mock successful API response
        api_response = {
            "data": {
                "name": "stripe-payments",
                "description": "Integrate Stripe payment processing",
                "trigger_conditions": [
                    "add Stripe payments",
                    "integrate payment processing",
                    "set up Stripe checkout",
                ],
                "overview": "Stripe is a payment processing platform.",
                "steps": [
                    {
                        "title": "Install SDK",
                        "body": "Install the Stripe SDK:\n```bash\npip install stripe\n```"
                    },
                    {
                        "title": "Configure API Key",
                        "body": "Set your API key:\n```python\nimport stripe\nstripe.api_key = 'sk_test_...'\n```"
                    }
                ],
                "key_endpoints_or_methods": [
                    {
                        "name": "stripe.Charge.create",
                        "description": "Create a new charge",
                        "example": "stripe.Charge.create(amount=1000, currency='usd')"
                    }
                ],
                "environment_variables": [
                    {"name": "STRIPE_API_KEY", "purpose": "API authentication"}
                ],
                "common_pitfalls": [
                    "Use test keys in development",
                    "Handle webhook signature verification"
                ],
            }
        }

        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps(api_response).encode('utf-8')
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        with tempfile.TemporaryDirectory() as tmpdir:
            output_file = os.path.join(tmpdir, "stripe-payments.md")
            test_args = [
                "prog",
                "--url", "https://stripe.com/docs",
                "--output", output_file,
                "--model", "spark-1-pro",
            ]

            with patch.object(sys, 'argv', test_args):
                with patch('sys.stderr', new_callable=StringIO):
                    fsg.main()

            # Verify file was created
            self.assertTrue(os.path.exists(output_file))

            # Verify file content
            with open(output_file, 'r') as f:
                content = f.read()

                # Check frontmatter
                self.assertIn("name: stripe-payments", content)
                self.assertIn("description: Integrate Stripe payment processing", content)

                # Check sections
                self.assertIn("# Stripe Payments", content)
                self.assertIn("## When to Use", content)
                self.assertIn("## Step 1 — Install SDK", content)
                self.assertIn("## Step 2 — Configure API Key", content)
                self.assertIn("## Key Endpoints / Methods", content)
                self.assertIn("`stripe.Charge.create`", content)
                self.assertIn("## Environment Variables", content)
                self.assertIn("STRIPE_API_KEY", content)
                self.assertIn("## Common Pitfalls", content)

                # Check code blocks
                self.assertIn("```bash", content)
                self.assertIn("pip install stripe", content)
                self.assertIn("```python", content)


if __name__ == "__main__":
    unittest.main()