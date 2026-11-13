# Burnin' Rubber 3 — Godot 4.8 Recreation

A recreation of **Burnin' Rubber 3** (an Adobe Shockwave game by Xform Games)
built with **Godot 4.8**, using **only the original game's assets** from the
adjacent `br3-src` folder.

## Layout

```
br3-godot4.8/
├── project.godot        # Godot 4.8 project (Forward+, full input map)
├── icon.svg
├── setup_assets.sh      # populates assets/ from ../br3-src/Data
├── assets/              # real directory populated by setup_assets.sh
├── scenes/
│   └── main.tscn        # root scene (plain Node; logic is in autoloads)
└── scripts/
    ├── game_data.gd     # singleton: parses all original .txt data files
    ├── audio_manager.gd # singleton: plays the original WAV SFX + music
    ├── main_manager.gd  # singleton: save/load, UI/race switching, rewards
    ├── ui_manager.gd    # 2D menu screens (main, tracks, cars, options, help)
    ├── car.gd           # arcade car: input, AI, health, weapons, nitro
    └── race.gd          # 3D race scene: track build, cars, HUD, camera, modes
```

## Assets

All art, models, audio and data come from the original game in `br3-src/Data`.
The `assets/` directory is populated from there by `setup_assets.sh` (it uses
**hard links**, so it is instant and uses no extra disk; it falls back to a
copy if hard links are unavailable):

- **Models** — the ASCII `FBX 6.1.0` conversions of the `.w3d` models
  (`Cars/3d/*.fbx`, `Tracks/*/3d/*Assets.fbx`, `Shared/3d/*.fbx`).
  Godot's built-in ufbx FBX importer loads them; it converts the original
  Z-up scene to Godot's Y-up with no scale change (the files use
  `UnitScaleFactor=100`, which maps to 1.0 meter, so positions line up
  directly with the track event coordinates).
- **Textures** — the original PNG textures (street lightmaps, car skins,
  UI, particles, skyboxes).
- **Audio** — the original WAV sound effects and music.
- **Data** — the original XForm `.txt` data files (`Globals.txt`,
  `Menu/TrackInfo.txt`, `Cars/CarsData.txt`, `Shared/SharedData.txt`,
  per-track `*Events.txt` and `*Data.txt` AI paths).

## How it works

- **`GameData`** parses every original data file into dictionaries and exposes
  `load_track_events()` (the `CreateTile` build list + player/AI car spawns)
  and `load_ai_paths()` (the per-tile waypoint lists).
- **`Race`** rebuilds each track by instantiating the `<type>_Root` node (and
  its children) from the world's `*Assets.fbx` at every `CreateTile` position,
  applies the original street/building textures (with lightmap shader for
  streets), assembles the global AI waypoint path, spawns the player + AI +
  traffic cars, places pickups, and runs the game loop (HUD, camera,
  finish/win conditions for each game mode).
- **`Car`** is an arcade vehicle with player input, AI waypoint steering,
  health, hitscan/area weapons, nitro and damage.
- **`MainManager`** persists progress (`user://br3_save.json`) and applies
  the original `Rewards`/`PrizeMoney` on completion.
- **`UIManager`** builds the menu screens from the original menu textures.
- **`AudioManager`** plays the original SFX and per-world music.

## Controls

| Key | Action |
|-----|--------|
| W / S | Accelerate / Brake |
| A / D | Steer Left / Right |
| Space | Nitro boost |
| Z | Fire primary weapon |
| X | Fire secondary weapon |
| C | Toggle rear camera |
| Esc | (pause handled in-game) |

## Running

1. From the `br3-godot4.8` folder, run the asset setup script:
   ```
   ./setup_assets.sh
   ```
   This populates `assets/` from `../br3-src/Data` using hard links (instant).
2. Open `br3-godot4.8` in the **Godot 4.8 editor** (File → Import, browse to
   the folder, click Import). On first open Godot will scan and import the
   FBX/PNG/WAV assets — this can take a little while given the size of the
   original asset tree, so be patient.
3. Press Play. The game starts at the main menu; pick a track, pick a car,
   and race.
