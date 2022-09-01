local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.CreatePreset("base", nil, {})

gui.CreatePreset("header", "base", {
    "input",
    "dock-top",
    min_size = {100, 100},
})

gui.CreatePreset("footer", "base", {
    "input",
    "dock-top",
    min_size = {100, 100},
})

gui.CreatePreset("frame", "base", {
    "input",
    "popup",
    "center",
    min_size = {150, 100},
})