# shindo toolkit

### Overview

Shindo Toolkit is a small unofficial Shindo Life utility written in Luau with Rayfield Gen2.

Source-available under the PolyForm Noncommercial License 1.0.0.

### Features

- **KG Changer**
  - Bloodline selection;
  - Bloodline presets;
  - Kenjutsu selection;
  - restore original values.
- **RCGenkai**
  - `item1` Bloodline override;
  - restore original `item1`.
- **Misc**
  - Outfit loading;
  - Home;
  - Rejoin;
  - Date rollback and restore;
  - Rollback + Rejoin;
  - Player Data;
  - language, theme, notifications and local preset settings.

### Stable loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau"))()
```

The stable loader uses the immutable `v1.0.0` runtime tag.

### Development loader

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau"))()
```

The dev build tracks active development and may be unstable.

### Requirements

- A supported Roblox executor with `loadstring` and HTTP support;
- optional filesystem support for persistent settings and presets;
- optional clipboard support for copy buttons.

### Development

`dev` contains active development, while `main` contains released code. Releases use tags such as `v1.0.0`. Pull requests and bug reports are welcome through GitHub.

### License and attribution

Shindo Toolkit uses the PolyForm Noncommercial License 1.0.0. Required notices are in [NOTICE](NOTICE). Rayfield Gen2 1.1.0 is licensed under MPL-2.0.

This project is unofficial and is not affiliated with RELL World, Roblox Corporation, or Sirius Software.
