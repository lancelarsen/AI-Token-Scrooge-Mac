# Development guidance

- Preserve feature and visual parity with the pinned Windows source described in README.md. Record remaining gaps honestly; do not replace missing behavior with invented success.
- Keep domain models pure, I/O in Services and Stores, and presentation in Views.
- Never invoke inference to check quota. Isolate provider CLI profiles from the user's normal CLI configuration.
- Keep credentials in Keychain. Do not log tokens, auth payloads, or raw provider responses.
- Serialize persistent state updates; adopt new in-memory state only after persistence succeeds. Reject stale refreshes and changed identities.
- Use `script/build_and_run.sh` for the build/run loop. Regenerate the checked-in Xcode project with XcodeGen after adding files.
- Run relevant builds and tests and distinguish demo evidence from live provider verification.
- When the user requests step-by-step instructions, provide only one step and wait for their result.
