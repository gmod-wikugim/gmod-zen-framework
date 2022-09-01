local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.RegisterPreset("base", nil, {})

gui.RegisterPreset("header", "base", {
    "input",
    "dock_top",
    tall = 50,
})

gui.RegisterPreset("footer", "base", {
    "input",
    "dock_top",
    tall = 50,
})

gui.RegisterPreset("frame", "base", {
    "input",
    "popup",
    "center",
    min_size = {150, 100},
})