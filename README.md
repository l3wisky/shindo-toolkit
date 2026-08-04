# Shindo Toolkit

[Русская версия](README.ru.md)

This script mainly provides basic QOL features available to most Shindo Life players and is not designed to provide an obvious advantage.

Shindo Toolkit is intentionally kept small.
The project focuses on a limited set of practical features and does not try to become a huge universal script hub.

## Loader

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/main/loader.luau"))()
```

## Dev Loader

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/l3wisky/shindo-toolkit/dev/loader.dev.luau"))()
```

The dev version may contain unstable, unfinished, or not yet tested changes.

## KGCHANGER

Simplifies the use of a known vulnerability that is also available without the script.

In normal scenarios, the same result can be reproduced through the known `Load Loadout` timing. KGCHANGER simply makes this behavior much more convenient.

## RCGENKAI

Allows any limited bloodline to be purchased in the RELLshop for approximately 300,000–500,000 RELL Coins without waiting for special events.

## MISC

- Allows desired outfits to be loaded anywhere without going to Home.
- DATA MANIPULATION. Provides the widely known basic progress rollback function (affects any progress, including RC and Spins, but not leaderboard progress). It has been used by players for a very long time to obtain desired races/bloodlines, grant RC through RELLbloodline, obtain a huge Rank, or test without spending resources. By default, the script does not provide automation related to this vulnerability and will not.
- Convenient viewing and use of all data/statistics of a specific player (STILL IN PROGRESS).

## Planned Future Features

- [ ] Protection against scripts used by players who use powerful exploits.
- [ ] FUN features

## License

Source code is available under the PolyForm Noncommercial License 1.0.0.
