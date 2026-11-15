---
name: captcha-handoff
description: Get past a CAPTCHA or bot check in an agent browser by first trying once to clear it, then handing it to the user and carrying on after they solve it. A challenge is never a reason to stop the task. Use on reCAPTCHA, hCaptcha, Cloudflare Turnstile / "Checking your browser" / "Verify you are human", "unusual traffic", slider or image puzzles, or an SMS/email verification step.
---

# Clear or hand off a CAPTCHA

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

A CAPTCHA is a pause, not a reason to stop. Either clear it or have the user clear it, then finish the task.

## 1. Try once yourself (about 30 seconds)

1. **Interstitials** ("Checking your browser", "Just a moment", Turnstile with no box): `browser_wait_for`
   `{"time": 8}`, then `browser_snapshot`. Still there: reload once and wait again.
2. **A single checkbox** ("I'm not a robot", "Verify you are human"): `browser_click` once, wait 3 to 5 seconds, then snapshot.
3. **Stop at a puzzle** (images, slider, audio, distorted text, a second checkbox round). Don't loop: repeated attempts
   raise the risk score for the whole profile. Don't use paid solving services.

Past the challenge (the target content is in the snapshot)? Carry on.

## 2. Hand it to the user

## How the user reaches the browser

`python3 $PLUGIN/scripts/registry.py resolve <id>`:
- **local**: it's on the agent's desktop. Follow `show-me` (ask, then `desktop.sh show`, and `kde-browser-workspace.sh takeover on` so they can type in it). Afterwards: `takeover off`, and offer `desktop.sh back`.
- **lan / vps**: give them the resolved `viewer_url`. `ok` false: the viewer isn't reachable from here, so run `browser-status`.

1. Leave the challenge tab open and selected (`browser_tabs` `select`).
2. One message: which browser, the site, the challenge, how to reach it, and what you'll do next. E.g. "The shop is
   showing a slider CAPTCHA in the local agent browser. Want me to switch you over to solve it? Then I'll carry on with the search."
3. **Make no browser calls until they reply.** Calls during a challenge can reset it or flag the session. Don't poll.
4. When they say done: `browser_snapshot` and confirm the target content. If the challenge is back, ask once more.
   If it comes back a third time, report the site and the challenge type.
5. Undo any `takeover` / desktop switch and continue from where the task paused.

A local headed Playwright browser gets challenged more often than a long-lived server profile. If one site keeps
blocking it, offer to switch to a `lan`/`vps` browser (`pick-browser`).

## Unattended (no one to ask)

Do step 1. If that fails, finish every part of the task that doesn't need the blocked page, then report the page, the
challenge type and a short URL so the user can clear it and rerun.

## Verification codes (SMS, email, authenticator)

Treat these like a sign-in (`browser-login`). If the code arrives in a mailbox you can read with the user's tools and
the task allows it, you may type it in yourself, but say that you did.
