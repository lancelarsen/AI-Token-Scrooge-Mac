import importlib.util
import os
import subprocess
import tempfile
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location("check_update_version", Path(__file__).parents[1] / "check_update_version.py")
versions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(versions)


def feed(*numbers):
    items = "".join(f"<item><sparkle:version>{number}</sparkle:version></item>" for number in numbers)
    return f'<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel>{items}</channel></rss>'.encode()


class UpdateVersionTests(unittest.TestCase):
    def test_new_build_advances_channel(self):
        versions.check("1449", feed("1361"))

    def test_equal_and_older_builds_are_rejected(self):
        for value in ["1360", "1361"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                versions.check(value, feed("1361"))

    def test_all_items_count_even_when_feed_is_unsorted(self):
        with self.assertRaises(ValueError):
            versions.check("1400", feed("1300", "1450", "1361"))

    def test_comparison_is_numeric(self):
        versions.check("1000", feed("999"))

    def test_legacy_enclosure_version_is_supported(self):
        versions.check("1449", b'<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><item><enclosure sparkle:version="1361" /></item></channel></rss>')

    def test_missing_or_invalid_published_versions_fail_closed(self):
        for payload in [feed(), feed(""), feed("0"), feed("2026.11.6"), b'<rss><channel><item /></channel></rss>']:
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                versions.check("1449", payload)

    def test_invalid_candidate_is_rejected(self):
        for value in ["", "0", "-1", "1449.1", "1e4"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                versions.check(value, feed("1361"))

    def test_malformed_feed_is_rejected(self):
        with self.assertRaises(ET.ParseError):
            versions.check("1449", b"<rss>")


class PublishPreflightTests(unittest.TestCase):
    def run_preflight(self, channel_error=""):
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            fixture = temporary / "feed.xml"
            fixture.write_bytes(feed("1361"))
            (temporary / "git").write_text("""#!/bin/sh
case "$1" in
 status) exit 0;;
 branch) echo main;;
 rev-parse) echo fixture-head;;
 ls-remote) printf 'fixture-head\\trefs/heads/main\\n';;
 rev-list) echo 361;;
 *) exit 90;;
esac
""")
            (temporary / "gh").write_text("""#!/bin/sh
case "$1 $2" in
 'release view') exit 1;;
 api*)
   if [ -n "$CHANNEL_ERROR" ]; then echo "$CHANNEL_ERROR" >&2; exit 1; fi;;
 'release download')
   while [ "$#" -gt 0 ]; do
     if [ "$1" = --dir ]; then shift; cp "$FIXTURE_FEED" "$1/appcast.xml"; exit; fi
     shift
   done
   exit 90;;
 *) exit 90;;
esac
""")
            for command in ["git", "gh"]:
                (temporary / command).chmod(0o755)
            environment = dict(os.environ, PATH=str(temporary) + os.pathsep + os.environ["PATH"],
                               FIXTURE_FEED=str(fixture), CHANNEL_ERROR=channel_error)
            script = Path(__file__).resolve().parents[1] / "publish_update.sh"
            return subprocess.run(["bash", str(script), "999", "--publish"], env=environment,
                                  text=True, capture_output=True, timeout=10)

    def test_equal_build_stops_before_packaging_or_upload(self):
        result = self.run_preflight()
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("does not advance the published build 1361", result.stderr)

    def test_network_error_cannot_bypass_existing_feed_check(self):
        result = self.run_preflight("connection timed out")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("Could not verify the existing update channel", result.stderr)
