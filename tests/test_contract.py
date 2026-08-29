import json
import os
import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "cleanup"
AUDIT_SCRIPT = SKILL / "scripts" / "audit_macos_storage.sh"
CLASSIFICATION = SKILL / "references" / "classification.md"
class SweepContractTests(unittest.TestCase):
    def test_manifest_contract(self):
        manifest = json.loads((ROOT / ".codex-plugin" / "plugin.json").read_text())
        self.assertEqual(manifest["name"], "sweep")
        self.assertRegex(
            manifest["version"], r"^\d+\.\d+\.\d+(?:\+[0-9A-Za-z.-]+)?$"
        )
        self.assertEqual(manifest["skills"], "./skills/")
        self.assertEqual(manifest["interface"]["displayName"], "Sweep")

        for field in ("composerIcon", "logo"):
            asset = manifest["interface"][field]
            self.assertEqual(asset, "./assets/icon.png")
            self.assertTrue((ROOT / asset.removeprefix("./")).is_file())

        self.assertIn("$sweep:cleanup", "\n".join(manifest["interface"]["defaultPrompt"]))

    def test_safety_resources_are_present_and_hardened(self):
        script = AUDIT_SCRIPT.read_text()
        classification = CLASSIFICATION.read_text()
        self.assertIn("printf '%q'", script)
        self.assertIn("process_status", script)
        for process in ("xctest", "testmanagerd", "XCTRunner"):
            self.assertIn(process, script)
        self.assertNotIn("simctl delete unavailable", classification)
        self.assertIn("exact unavailable UDIDs", classification)
        self.assertIn("fresh approval", classification)

    def test_audit_script_is_executable_and_has_no_mutating_commands(self):
        self.assertTrue(os.access(AUDIT_SCRIPT, os.X_OK))
        script = AUDIT_SCRIPT.read_text()
        forbidden_command = re.compile(
            r"(?m)^\s*(?:sudo|rm|mv|rmdir|unlink|kill|pkill|killall|launchctl)\b"
        )
        forbidden_simctl = re.compile(
            r"\bsimctl\s+(?:delete|erase|shutdown|boot|runtime\b.*\bremove)\b"
        )
        self.assertIsNone(forbidden_command.search(script))
        self.assertIsNone(forbidden_simctl.search(script))

        syntax = subprocess.run(
            ["/bin/zsh", "-n", str(AUDIT_SCRIPT)], capture_output=True, text=True
        )
        self.assertEqual(syntax.returncode, 0, syntax.stderr)

    def test_audit_script_rejects_unknown_arguments_without_scanning(self):
        result = subprocess.run(
            [str(AUDIT_SCRIPT), "--unknown"], capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_cleanup_requires_separate_exact_approval(self):
        skill = (SKILL / "SKILL.md").read_text()
        self.assertTrue(skill.startswith("---\nname: cleanup\n"))
        self.assertIn("strict two-phase workflow", skill)
        self.assertIn("separate approval", skill)
        self.assertIn("exact absolute paths", skill)
        self.assertIn("new, direct user message", skill)
        self.assertIn("tool or script output", skill)
        for protected in (
            "~/.codex/sessions",
            "~/.codex/memories",
            "Xcode Archives",
            "booted simulator data",
            "runtime volumes",
        ):
            self.assertIn(protected, skill)


if __name__ == "__main__":
    unittest.main()
