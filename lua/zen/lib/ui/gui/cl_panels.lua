local ui, gui, draw = zen.Init("ui", "gui", "ui.draw")

gui.RegisterStylePanel("base", {}, "EditablePanel", {}, {})
gui.RegisterStylePanel("frame", {}, "DFrame", {title = "zen.frame", size = {300, 300}}, {"frame"})
gui.RegisterStylePanel("text", {}, "DLabel", {text = "zen.text", content_align = 5, text_color = COLOR.WHITE, font = ui.ffont(8)}, {})

gui.RegisterStylePanel("footer", {}, "EditablePanel", {}, {"footer"})
gui.RegisterStylePanel("header", {}, "EditablePanel", {}, {"header"})
gui.RegisterStylePanel("nav_left", {}, "EditablePanel", {"input", "dock_left", wide = 50}, {})
gui.RegisterStylePanel("nav_right", {}, "EditablePanel", {"input", "dock_right", wide = 50}, {})

gui.RegisterStylePanel("content", {}, "EditablePanel", {"dock_fill", "input"}, {})
gui.RegisterStylePanel("list", {}, "DScrollPanel", {"dock_fill", "input"}, {})

gui.RegisterStylePanel("button", {}, "DButton", {"input", text = "zen.button"}, {})

gui.RegisterStylePanel("func_panel", {}, "EditablePanel", {key_input = false, mouse_input = false})


gui.RegisterStylePanel("white_fill", {
    Paint = function(self, w, h)
        draw.Box(0,0,w,h,COLOR.WHITE)
    end
}, "EditablePanel", {"dock_fill"}, {})