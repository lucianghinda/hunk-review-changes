# Changelog

## 0.1.0 (unreleased)

- First release as a gem. Packages the browser review UI, all Ruby code, prebuilt CSS,
  and the bundled Atkinson Hyperlegible fonts.
- `hunk-review-changes <bundle.json>` serves the review UI; `--port` and `--no-open`
  flags supported.
- `hunk-review-changes install` installs the companion skill into Claude Code (via its
  plugin marketplace CLI) and Codex, Cursor, and OpenCode (by copying the skill into
  the directory each scans).
- UI overhaul: Atkinson Hyperlegible Next / Mono fonts, wider layout with 120-column
  diffs, dark mode that follows the OS setting, word-level diff highlighting, an
  explicit per-hunk "Looks good" reviewed state, and `j`/`k`/`c`/`g`/`?` keyboard
  navigation.
- Bundles are validated on launch with actionable error messages.
