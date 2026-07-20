# hunk_review_changes

Review a diff hunk-by-hunk in your browser, then hand the comments back to your AI coding agent.

Your agent groups a diff into pieces — each a hunk with a plain-language what/why — and launches a local web app. You read the highlighted hunks and comment on each at your own pace. No model tokens are spent while you review. Click **Done** and the agent picks up your comments and implements them.

Works with Claude Code, Codex, Cursor, and OpenCode.

[![CI](https://github.com/ghinda/hunk-review-changes/actions/workflows/ci.yml/badge.svg)](https://github.com/ghinda/hunk-review-changes/actions/workflows/ci.yml)

## Installation

Install the gem:

```sh
gem install hunk_review_changes
```

Then install the companion skill into your agents:

```sh
hunk-review-changes install
```

It asks which agents to set up and installs the skill for each.

## How it works

1. You ask your agent to review a change — a branch, PR, commit, or your working tree.
2. The skill resolves the target, groups it into hunks, and writes a `bundle.json`.
3. It runs `hunk-review-changes bundle.json`, which opens the review UI in your browser.
4. For each hunk you leave a comment, mark it **Looks good**, or **Flag for discussion**.
5. You click **Done**. The app writes `export.md` and exits.
6. Your agent reads the export and implements every requested change.

## Usage

Serve a bundle:

```sh
hunk-review-changes bundle.json
```

Options:

```sh
hunk-review-changes bundle.json --port 4321   # bind a specific port
hunk-review-changes bundle.json --no-open      # do not open the browser
```

Install the skill for specific agents without the prompt:

```sh
hunk-review-changes install --agent claude,codex,cursor,opencode
```

## The review UI

- **120-column diffs** with syntax highlighting, in [Atkinson Hyperlegible](https://www.brailleinstitute.org/freefont/) fonts.
- **Word-level highlighting** shows exactly what changed within a modified line.
- **Dark mode** follows your operating system setting.
- **Keyboard navigation** — `j`/`k` to move between hunks, `c` to comment, `g` to mark Looks good, `?` for help.
- **Reviewed state** — every hunk tracks whether you have seen it, so you know what is left.

Your review persists as you go, so closing the tab loses nothing. Re-running the same bundle resumes it.

## Skills marketplace

The skill lives in its own repo, [hunk-review-changes-skills](https://github.com/ghinda/hunk-review-changes-skills), a marketplace that serves every supported agent. `hunk-review-changes install` uses it: it calls the Claude Code plugin CLI, and copies the skill into the directory Codex, Cursor, and OpenCode scan.

## Development

Get the dependencies:

```sh
bundle install
```

Run the tests and linter:

```sh
bundle exec rake
```

Rebuild the stylesheet after changing `assets/tailwind.css` or the fonts:

```sh
bundle exec rake css
```

Release a new version with:

```sh
bundle exec rake release
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/ghinda/hunk-review-changes).

## License

The gem is available as open source under the [MIT License](LICENSE.txt). The bundled Atkinson Hyperlegible fonts are licensed under the [SIL Open Font License](lib/hunk_review_changes/public/fonts/OFL.txt).
