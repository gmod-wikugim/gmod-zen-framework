### Zen Framework
Garry's mod lua framework

**It's use lua module system.**
```lua
module("zen", package.seeall)

-- Your code
```

Framework includes libraries:
- interface
    - draw (draw, draw3d, draw3d2d)
    - gui (panels, skins, params)
    - ui (font)
- network
    - channels
    - entity variables
    - client commands
    - shared hooks
    - shared table key-value editor
    - string tables for byte optimization
    - strict type for send and receive functions
- input - Hook all buttons press and release (include in GameMenu/GameConsole/Any active TextEntry)
- convars
    - callback
    - strict types
- developer log
    - log() warn() log_error() commands
- hook library (Don't replace default hook library)
    - connect ot [srLit hooks](https://github.com/Srlion/Hook-Library)
    - runSecure with pcall
- string interpolate
- util
    - Strict type enum/core for values and tables
    - Nice table print function
    - traces functions
    - utf8 lower and upper
    - Mesh Model Bounds Calculator
    - IcoSphere Vertex Generator
Where are modules:
- Internal console
    - AutoComplete Engine
    - Command send strict checker
- FastCommand (like Grand There Auto: SA cheats "hesoyam")
- HUD (3d2d entity info)
- Permission Engine with Tags (targetSelector, trasmitSettings, availableTime)
    - Support Offline permission check.
- Save - Easy and fast save variables in SQLLite for Player and not
- Zone - InGame zone
    - Work on EngineCollision or Vector Check
    - Has Entity Join and Exit hooks (entity, entity_class)
