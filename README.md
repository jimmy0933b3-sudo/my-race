# MONSTER KART 3D 🏎️👾

An original, offline, landscape 3D arcade racing game for Android, built with Godot 4.5.2.

## Play
- 12 original, selectable monster karts with different speed and handling.
- 8 competitors per race, 3 laps, automatic acceleration, touch steering, drifting, boosts, and item battles.
- A themed fantasy circuit with four festival gateways, candy lanes, mushroom forest, crystal displays, monster towers, curved illuminated guardrails, kerbs and racing line markers.
- New pause menu, instant home button, replay, and a dedicated settings screen, including from the garage and result view.
- Original generated chiptune background music and 8 synthesised arcade sound effects. No external music packs or internet permission needed.
- Adjustable music and sound effect levels saved to the Godot `user://` directory between runs.
- Keyboard: arrow keys for steering, Shift to drift, E/Space for items, Esc for pause/resume or closing settings.

## Builds

Every push to `main` runs GitHub Actions script checks, a headless gameplay regression, and a signed Android export. The workflow uses the existing repository Action secrets for the release signing key, publishes an APK as the latest GitHub Release, and retains only the newest Release.

Open `project.godot` in Godot 4.5.2 to play locally. Track models, karts, effects, and music are generated procedurally with no paid assets.
