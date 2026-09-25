# Jelly Sumo

[English](README.en.md) | [日本語](README.jp.md)

A 3D prototype built with Godot 4.x where soft, jelly-like characters push against one another.

The goal is to explore whether body-to-body pushing feels fun: press into another character, watch the belly squash, then pull away and see it wobble back into shape. The prototype focuses on that interaction rather than a complete competitive game.

## What you can try

- Control the mint-colored character and push against two simple AI characters, orange and purple
- Watch the belly dent on the contact side and bulge slightly sideways and upward
- Move other characters by pushing them with your body
- Pull away to see the shape recover, overshoot, and wobble
- Fall off the platform and automatically return

## Requirements

- **Verified on: macOS / Godot 4.7.2 stable**
- Renderer: Compatibility
- Input: keyboard
- No external assets, additional plugins, or .NET installation required

The current project settings were saved with Godot 4.7. Other Godot versions and operating systems have not been verified.

## Getting started

1. Clone this repository, or download and extract its ZIP archive.
2. In the Godot Project Manager, select **Import** and choose `project.godot`.
3. Open the project and press **F5 (Run Project)**.

The three characters start pushing as soon as the project runs.

## Controls

| Key | Action |
| --- | --- |
| W / A / S / D | Move forward, left, backward, and right relative to the camera |
| R | Reset all three characters to their starting positions |

You control the mint-colored character. Press against another character's belly for a few seconds, then move away in the opposite direction. Watch the compression, displacement, and spring recovery in sequence.

## How the softness works

Standard `RigidBody3D` bodies with spherical collision shapes handle pushing. Each character is built from simple `SphereMesh` parts.

A shader deforms the belly vertices based on the distance and direction to another character. It dents the contact side and adds a slight sideways and vertical bulge. A damped spring restores the deformation, producing overshoot and wobble after release. The upper body also leans in response to movement and collisions.

### Simplifications

- Collision shapes do not deform. This is not a full soft-body simulation.
- Compression is estimated from the distance between characters near contact.
- When squeezed from multiple directions, the strongest contact direction takes priority.
- AI characters simply approach a nearby opponent and push, occasionally easing off.

There is no title screen, score, win/loss detection, character selection, audio, effects, or online multiplayer.

## Project structure

```text
.
├── project.godot           # Project settings
├── main.tscn               # Startup scene
├── scripts/
│   ├── main.gd             # Stage, camera, input, character setup, control hints
│   └── jelly.gd            # Movement, AI, compression spring, sway, respawn
├── shaders/
│   └── jelly.gdshader      # Belly dents and bulges
└── tests/
    └── verify.gd           # Automated behavior checks
```

Include Godot-generated `.uid` files in version control. Exclude the regenerable `.godot/` cache.

## Tuning the feel

| File | Setting | What it changes |
| --- | --- | --- |
| `scripts/jelly.gd` | `SPRING` | How quickly the shape returns |
| `scripts/jelly.gd` | `DAMPING` | How quickly the wobble settles |
| `scripts/jelly.gd` | Force values in `apply_central_force` | Player and AI pushing strength |
| `scripts/jelly.gd` | Multiplier in `pressure` | Compression on contact |
| `shaders/jelly.gdshader` | `deform` function | Shape of the dents and bulges |

## Automated checks

Run from the project root. If the `godot` command is available on your PATH:

```sh
godot --headless --path . --script res://tests/verify.gd
```

On macOS, with `Godot.app` installed in Applications:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/verify.gd
```

The script checks seven behaviors: spawning three characters, movement input, pushing another character, compression of both bellies, overshoot after release, return to the rest shape, and falling followed by automatic respawn. When all checks pass, it prints `RESULT: 0 failures` and exits with code 0.

These checks verify behavior and numeric values. Run the project normally to evaluate rendering and the actual feel of pushing.

## License

[MIT License](LICENSE)
