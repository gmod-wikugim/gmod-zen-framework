local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.RegisterPreset("base", nil, {})

gui.RegisterPreset("header", "base", {
    "input",
    "dock-top",
    min_size = {100, 100},
})

gui.RegisterPreset("footer", "base", {
    "input",
    "dock-top",
    min_size = {100, 100},
})

gui.RegisterPreset("frame", "base", {
    "input",
    "popup",
    "center",
    min_size = {150, 100},
})