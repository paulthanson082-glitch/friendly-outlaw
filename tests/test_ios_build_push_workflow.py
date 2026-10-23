"""
Comprehensive tests for .github/workflows/ios-build-push.yml

Tests cover:
- Workflow triggers (push/pull_request branches and paths)
- Job structure, dependencies, and run conditions
- The "build" job's steps and environment configuration
- The "archive-and-push" job's steps, secrets usage, and conditions
- General structural/security invariants of the workflow file
"""

import os
import unittest

import yaml

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORKFLOW_PATH = os.path.join(REPO_ROOT, ".github", "workflows", "ios-build-push.yml")


def _load_workflow():
    with open(WORKFLOW_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def _on_section(workflow):
    # PyYAML follows the YAML 1.1 spec, which parses the unquoted `on:` key
    # as the boolean `True` rather than the string "on".
    if "on" in workflow:
        return workflow["on"]
    return workflow[True]


def _steps_by_name(job):
    return {step["name"]: step for step in job.get("steps", []) if "name" in step}


class WorkflowFileTests(unittest.TestCase):
    def test_workflow_file_exists(self):
        self.assertTrue(os.path.isfile(WORKFLOW_PATH))

    def test_workflow_is_valid_yaml_mapping(self):
        workflow = _load_workflow()
        self.assertIsInstance(workflow, dict)

    def test_workflow_name(self):
        workflow = _load_workflow()
        self.assertEqual(workflow["name"], "iOS Build and Push")


class TriggerTests(unittest.TestCase):
    def setUp(self):
        self.workflow = _load_workflow()
        self.on = _on_section(self.workflow)

    def test_only_push_and_pull_request_triggers_defined(self):
        self.assertEqual(set(self.on.keys()), {"push", "pull_request"})

    def test_push_trigger_branches(self):
        self.assertEqual(self.on["push"]["branches"], ["main", "claude/**", "copilot/**"])

    def test_push_trigger_paths_scoped_to_ios_pronotes(self):
        self.assertEqual(self.on["push"]["paths"], ["ios/ProNotes/**"])

    def test_pull_request_trigger_branches(self):
        self.assertEqual(self.on["pull_request"]["branches"], ["main"])

    def test_pull_request_trigger_paths_scoped_to_ios_pronotes(self):
        self.assertEqual(self.on["pull_request"]["paths"], ["ios/ProNotes/**"])


class JobStructureTests(unittest.TestCase):
    def setUp(self):
        self.workflow = _load_workflow()
        self.jobs = self.workflow["jobs"]

    def test_expected_jobs_present(self):
        self.assertEqual(set(self.jobs.keys()), {"build", "archive-and-push"})

    def test_both_jobs_run_on_macos(self):
        for job_id, job in self.jobs.items():
            self.assertEqual(job["runs-on"], "macos-latest", f"{job_id} should run on macos-latest")

    def test_archive_job_depends_on_build_job(self):
        self.assertEqual(self.jobs["archive-and-push"]["needs"], "build")

    def test_build_job_has_no_run_condition(self):
        # The build job should run for both pushes and pull requests.
        self.assertNotIn("if", self.jobs["build"])

    def test_archive_job_only_runs_on_push_to_main(self):
        condition = self.jobs["archive-and-push"]["if"]
        self.assertIn("github.event_name == 'push'", condition)
        self.assertIn("github.ref == 'refs/heads/main'", condition)


class BuildJobTests(unittest.TestCase):
    def setUp(self):
        self.workflow = _load_workflow()
        self.job = self.workflow["jobs"]["build"]
        self.steps = _steps_by_name(self.job)

    def test_job_display_name(self):
        self.assertEqual(self.job["name"], "Build ProNotes iOS App")

    def test_environment_variables(self):
        env = self.job["env"]
        self.assertEqual(env["SCHEME"], "ProNotes")
        self.assertEqual(env["WORKSPACE"], "ios/ProNotes/ProNotes.xcworkspace")
        self.assertEqual(env["PROJECT"], "ios/ProNotes/ProNotes.xcodeproj")
        self.assertEqual(
            env["DESTINATION"],
            "platform=iPadOS Simulator,name=iPad Pro 13-inch (M4),OS=latest",
        )

    def test_checks_out_repository_first(self):
        first_step = self.job["steps"][0]
        self.assertEqual(first_step["uses"], "actions/checkout@v4")

    def test_selects_xcode_version(self):
        step = self.steps["Select Xcode version"]
        self.assertIn("xcode-select -s /Applications/Xcode.app", step["run"])

    def test_shows_build_environment(self):
        step = self.steps["Show build environment"]
        self.assertIn("xcodebuild -version", step["run"])
        self.assertIn("swift --version", step["run"])

    def test_resolves_package_dependencies_with_workspace_and_project_fallback(self):
        run = self.steps["Resolve Swift Package dependencies"]["run"]
        self.assertIn('-f "$WORKSPACE"', run)
        self.assertIn('-f "$PROJECT"', run)
        self.assertIn("-resolvePackageDependencies", run)
        self.assertIn('-scheme "$SCHEME"', run)

    def test_build_step_disables_code_signing(self):
        run = self.steps["Build for simulator"]["run"]
        self.assertIn('CODE_SIGN_IDENTITY=""', run)
        self.assertIn("CODE_SIGNING_REQUIRED=NO", run)

    def test_build_step_uses_configured_destination(self):
        run = self.steps["Build for simulator"]["run"]
        self.assertIn('-destination "$DESTINATION"', run)
        self.assertIn("-configuration Debug", run)

    def test_build_step_gracefully_skips_when_no_project_or_workspace(self):
        run = self.steps["Build for simulator"]["run"]
        self.assertIn("No Xcode project or workspace found. Skipping build.", run)
        self.assertIn("exit 0", run)

    def test_run_tests_step_only_runs_on_push_events(self):
        step = self.steps["Run tests"]
        self.assertEqual(step["if"], "github.event_name == 'push'")

    def test_run_tests_step_invokes_xcodebuild_test(self):
        run = self.steps["Run tests"]["run"]
        self.assertIn("xcodebuild test", run)

    def test_step_order(self):
        names = [step.get("name") for step in self.job["steps"]]
        self.assertEqual(
            names,
            [
                "Checkout repository",
                "Select Xcode version",
                "Show build environment",
                "Resolve Swift Package dependencies",
                "Build for simulator",
                "Run tests",
            ],
        )


class ArchiveAndPushJobTests(unittest.TestCase):
    def setUp(self):
        self.workflow = _load_workflow()
        self.job = self.workflow["jobs"]["archive-and-push"]
        self.steps = _steps_by_name(self.job)

    def test_job_display_name(self):
        self.assertEqual(self.job["name"], "Archive and Push to TestFlight")

    def test_environment_variables(self):
        env = self.job["env"]
        self.assertEqual(env["SCHEME"], "ProNotes")
        self.assertEqual(env["WORKSPACE"], "ios/ProNotes/ProNotes.xcworkspace")
        self.assertEqual(env["PROJECT"], "ios/ProNotes/ProNotes.xcodeproj")
        self.assertEqual(env["ARCHIVE_PATH"], "build/ProNotes.xcarchive")
        self.assertEqual(env["EXPORT_PATH"], "build/ProNotes-ipa")

    def test_checks_out_repository_first(self):
        first_step = self.job["steps"][0]
        self.assertEqual(first_step["uses"], "actions/checkout@v4")

    def test_certificate_step_declares_expected_secrets(self):
        env = self.steps["Install Apple certificate and provisioning profile"]["env"]
        self.assertEqual(env["BUILD_CERTIFICATE_BASE64"], "${{ secrets.BUILD_CERTIFICATE_BASE64 }}")
        self.assertEqual(env["P12_PASSWORD"], "${{ secrets.P12_PASSWORD }}")
        self.assertEqual(env["BUILD_PROVISION_PROFILE_BASE64"], "${{ secrets.BUILD_PROVISION_PROFILE_BASE64 }}")
        self.assertEqual(env["KEYCHAIN_PASSWORD"], "${{ secrets.KEYCHAIN_PASSWORD }}")

    def test_certificate_step_creates_and_unlocks_keychain(self):
        run = self.steps["Install Apple certificate and provisioning profile"]["run"]
        self.assertIn("security create-keychain", run)
        self.assertIn("security unlock-keychain", run)
        self.assertIn("security import", run)

    def test_archive_step_has_workspace_project_and_missing_fallback(self):
        run = self.steps["Archive app"]["run"]
        self.assertIn('-f "$WORKSPACE"', run)
        self.assertIn('-f "$PROJECT"', run)
        self.assertIn("xcodebuild archive", run)
        self.assertIn("No Xcode project or workspace found. Skipping archive.", run)

    def test_export_ipa_uses_expected_export_options_plist(self):
        run = self.steps["Export IPA"]["run"]
        self.assertIn("-exportOptionsPlist ios/ProNotes/ExportOptions.plist", run)
        self.assertIn('-archivePath "$ARCHIVE_PATH"', run)
        self.assertIn('-exportPath "$EXPORT_PATH"', run)

    def test_upload_step_declares_expected_secrets(self):
        env = self.steps["Upload to TestFlight"]["env"]
        self.assertEqual(env["APP_STORE_CONNECT_API_KEY_ID"], "${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}")
        self.assertEqual(env["APP_STORE_CONNECT_ISSUER_ID"], "${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}")
        self.assertEqual(
            env["APP_STORE_CONNECT_API_KEY_BASE64"], "${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}"
        )

    def test_upload_step_uses_altool_with_ios_type(self):
        run = self.steps["Upload to TestFlight"]["run"]
        self.assertIn("xcrun altool --upload-app", run)
        self.assertIn("--type ios", run)

    def test_cleanup_step_always_runs(self):
        step = self.steps["Clean up keychain"]
        self.assertEqual(step["if"], "always()")

    def test_cleanup_step_deletes_keychain_and_ignores_failures(self):
        run = self.steps["Clean up keychain"]["run"]
        self.assertIn("security delete-keychain", run)
        self.assertIn("|| true", run)

    def test_step_order(self):
        names = [step.get("name") for step in self.job["steps"]]
        self.assertEqual(
            names,
            [
                "Checkout repository",
                "Select Xcode version",
                "Install Apple certificate and provisioning profile",
                "Archive app",
                "Export IPA",
                "Upload to TestFlight",
                "Clean up keychain",
            ],
        )


class SecurityInvariantTests(unittest.TestCase):
    """Guards against accidentally hardcoding secrets in the workflow file."""

    def setUp(self):
        with open(WORKFLOW_PATH, "r", encoding="utf-8") as f:
            self.content = f.read()

    def test_no_pem_or_private_key_material_present(self):
        self.assertNotIn("-----BEGIN", self.content)

    def test_all_sensitive_values_are_referenced_via_secrets_context(self):
        expected_secret_names = [
            "BUILD_CERTIFICATE_BASE64",
            "P12_PASSWORD",
            "BUILD_PROVISION_PROFILE_BASE64",
            "KEYCHAIN_PASSWORD",
            "APP_STORE_CONNECT_API_KEY_ID",
            "APP_STORE_CONNECT_ISSUER_ID",
            "APP_STORE_CONNECT_API_KEY_BASE64",
        ]
        for secret_name in expected_secret_names:
            self.assertIn(f"secrets.{secret_name}", self.content)


if __name__ == "__main__":
    unittest.main()