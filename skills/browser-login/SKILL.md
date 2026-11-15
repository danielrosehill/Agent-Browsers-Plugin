---
name: browser-login
description: Get an agent browser signed in to a site by handing the sign-in to the user (the agent never types credentials), then confirming the session is live. Use when a site shows a login wall, when setting up a fresh profile, or on "log me in", "I'll log in", "sign the browser into X".
---

# Hand a sign-in to the user

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

The agent never types passwords. The user signs in themselves, and the agent checks the result.

## How the user reaches the browser

`python3 $PLUGIN/scripts/registry.py resolve <id>`:
- **local**: it's on the agent's desktop. Follow `show-me` (ask, then `desktop.sh show`, and `kde-browser-workspace.sh takeover on` so they can type in it). Afterwards: `takeover off`, and offer `desktop.sh back`.
- **lan / vps**: give them the resolved `viewer_url`. `ok` false: the viewer isn't reachable from here, so run `browser-status`.

## Sign in through the login source first

`registry.py get <id>` → `login_source.kind`:
- **`chrome-cookies`**: the browser is seeded from a Chrome profile at launch. Ask the user to sign in **in that
  Chrome profile** (`login_source.chrome_profile`), not in the agent browser. It reaches the agent browser at its next
  launch after the cookie sync. Usually that means `browser_close`, then `browser_navigate` again, or reconnecting the MCP
  server with `/mcp` if the state is only read when the server starts. Sites that keep the session in localStorage
  won't follow over cookies: for those, use the manual route below.
- **`manual-in-viewer`** / **`none`**: the user signs in inside the agent browser.

**Identity provider first.** If the entry has `accounts` (e.g. `{"google": "you@example.com"}`) and the profile has no
session there, sign that in first (`https://myaccount.google.com/`: a signed-in page shows the email). After that,
most sites are one "Sign in with Google" click. Name the account to use in your message.

## Steps

1. Open the target's sign-in page in a **new tab** (`browser_tabs` `new`), so it's waiting when the user looks.
2. One message: which browser, which site, which account, and how to reach it (above). A passkey prompt may not reach
   their phone from a server browser: "Try another way", then password.
3. **Make no browser calls until they say they're done.** Automation calls during a Google sign-in can trip "this
   browser may not be secure". Don't poll.
4. Check the session itself: reload the target, `browser_snapshot`, and find a signed-in marker (account name, avatar,
   "Sign out"). A URL change or a 200 is not proof.
5. Say "signed in as …", undo any `takeover` / desktop switch, and carry on with the original task.

## Google refuses ("Couldn't sign you in / browser may not be secure")

Check that no agent call ran during the attempt, then retry once. If it still refuses, tell the user, and note the date
and message in the browser's `ops_doc` if it has one.
