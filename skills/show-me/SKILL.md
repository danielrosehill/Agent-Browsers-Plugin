---
name: show-me
description: Let the user look at what the agent browser is showing by switching their screen to the agent's virtual desktop, only after they say yes, and switching back afterwards. Use when there's something worth seeing (a preview, a result, a captcha, a login form), or when the user says "show me", "let me see", "take me there", "switch back", "I'm done looking".
---

# Show the user the agent browser

`$PLUGIN` below is this plugin's root: two directories above this skill's base directory. Every script prints JSON.

The agent browser lives on its own desktop so it never interrupts the user. Never switch their view unasked.

1. **Ask first:** one line, e.g. "The preview is up in the agent browser. Want to look?" Don't switch until they say yes.
   If they already said "show me", that's the yes.
2. **Switch:** `$PLUGIN/scripts/desktop.sh show`. This records where they were. Check `on_agent` is true. `ok` false with
   exit 3 means the desktop backend isn't built for their environment: give them the desktop name to switch to themselves.
3. **If they need to type in it** (sign in, solve a captcha): `$PLUGIN/scripts/kde-browser-workspace.sh takeover on`.
   This lets the window take focus. Turn it off again when they're done (step 4).
4. **Back:** when they're done, or say so: `desktop.sh back`, and `kde-browser-workspace.sh takeover off` if step 3 ran.
   Offer this; don't do it while they may still be looking.
