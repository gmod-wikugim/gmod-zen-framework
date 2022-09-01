local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.RegisterStylePanel("frame", {}, "DFrame", {title = "zen.frame", size = {300, 300}}, {"frame"})
gui.RegisterStylePanel("text", {}, "DLabel", {text = "zen.text", content_align = 5, text_color = COLOR.WHITE, font = ui.ffont(8)}, {})