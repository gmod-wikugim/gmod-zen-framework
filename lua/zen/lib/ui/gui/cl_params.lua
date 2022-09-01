local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.RegisterParam("set_size", function(pnl, value1, value2)
    pnl:SetSize(value1, value2)
end, {
    "set_size",
    "size",
})

gui.RegisterParam("set_wide", function(pnl, value)
    pnl:SetWide(value)
end, {
    "set_wide",
    "set_width",
    "wide",
    "width",
})

gui.RegisterParam("set_tall", function(pnl, value)
    pnl:SetTall(value)
end, {
    "set_tall",
    "set_height",
    "tall",
    "height",
})

gui.RegisterParam("set_text", function(pnl, value)
    pnl:SetText(value)
end, {
    "set_text",
    "text",
})

gui.RegisterParam("set_text_color", function(pnl, value)
    pnl:SetTextColor(value)
end, {
    "set_text_color",
    "text_color",
    "color_text",
})

gui.RegisterParam("set_alpha", function(pnl, value)
    pnl:SetAlpha(value)
end, {
    "set_alpha",
    "alpha",
})

gui.RegisterParam("dock_fill", function(pnl, value)
    pnl:Dock(FILL)
    pnl:InvalidateParent(true)
end, {
    "dock_fill",
    "fill_dock",
})

gui.RegisterParam("dock", function(pnl, value)
    pnl:Dock(value)
    pnl:InvalidateParent(true)
end, {
    "dock",
})

gui.RegisterParam("dock_top", function(pnl, value)
    pnl:Dock(TOP)
    pnl:InvalidateParent(true)
end, {
    "dock_top",
    "dock_up",
    "top_dock",
    "up_dock",
})

gui.RegisterParam("dock_bottom", function(pnl, value)
    pnl:Dock(BOTTOM)
    pnl:InvalidateParent(true)
end, {
    "dock_bottom",
    "dock_down",
    "bottom_dock",
    "down_dock",
})

gui.RegisterParam("dock_right", function(pnl, value)
    pnl:Dock(RIGHT)
    pnl:InvalidateParent(true)
end, {
    "dock_right",
    "right_dock",
})

gui.RegisterParam("dock_left", function(pnl, value)
    pnl:Dock(LEFT)
    pnl:InvalidateParent(true)
end, {
    "dock_left",
    "left_dock",
})

gui.RegisterParam("set_auto_delete", function(pnl, value)
    value = value != nil and value or true
    pnl:SetAutoDelete(value)
end, {
    "set_auto_delete",
    "auto_delete",
    "delete_auto",
})

gui.RegisterParam("set_bg_color", function(pnl, value1, value2, value3, value4)
    pnl:SetBGColor(value1, value2, value3, value4)
end, {
    "set_bg_color",
    "bg_color",
    "background_color",
    "color_bg",
    "background_color",
})

gui.RegisterParam("set_caret_pos", function(pnl, value)
    pnl:SetCaretPos(value)
end, {
    "caret_pos",
    "caretpos",
})

gui.RegisterParam("set_command", function(pnl, value)
    pnl:SetCommand(value)
end, {
    "set_command",
    "command_set",
    "command",
})

gui.RegisterParam("set_content_alignment", function(pnl, value)
    pnl:SetContentAlignment(value)
end, {
    "set_content_alignment",
    "content_alignment",
    "content_align",
    "alignment_content",
    "align_content",
})

gui.RegisterParam("set_convar", function(pnl, value)
    pnl:SetConVar(value)
end, {
    "convar",
})

gui.RegisterParam("set_cookie", function(pnl, value1, value2)
    pnl:SetCookie(value1, value2)
end, {
    "cookie",
})

gui.RegisterParam("set_cookie_name", function(pnl, value)
    pnl:SetCookieName(value)
end, {
    "cookie_name",
    "cookiename",
})

gui.RegisterParam("set_cursor", function(pnl, value) -- TODO: Think about it
    pnl:SetCursor(value)
end, {
    "cursor",
})

gui.RegisterParam("set_drag_parent", function(pnl, value)
    pnl:SetDragParent(value)
end, {
    "drag_parent",
    "dragparent",
})

gui.RegisterParam("set_draw_language_id", function(pnl, value)
    pnl:SetDrawLanguageID(value)
end, {
    "draw_language_id",
    "language_drawid",
    "language_draw_id",
})

gui.RegisterParam("set_draw_language_id_at_left", function(pnl, value)
    value = value != nil and value or true
    pnl:SetDrawLanguageIDAtLeft(value)
end, {
    "draw_language_id_at_left",
    "language_id_left",
    "language_at_left",
    "language_left",
})

gui.RegisterParam("set_draw_on_top", function(pnl, value)
    value = value != nil and value or true
    pnl:SetDrawOnTop(value)
end, {
    "draw_on_top",
    "draw_top",
    "top_draw",
})

gui.RegisterParam("set_drop_target", function(pnl, value1, value2, value3, value4)
    pnl:SetDrawOnTop(value1, value2, value3, value4)
end, {
    "drop_target",
    "target_drop",
})

gui.RegisterParam("set_enabled", function(pnl, value)
    value = value != nil and value or true
    pnl:SetEnabled(value)
end, {
    "set_enabled",
    "enabled",
})

gui.RegisterParam("set_disable", function(pnl, value)
    value = value != nil and value or true
    pnl:SetEnabled(not value)
end, {
    "set_disable",
    "disable",
})

gui.RegisterParam("expensive_shadow", function(pnl, value1, value2)
    pnl:SetExpensiveShadow(value1, value2)
end, {
    "expensive_shadow",
    "shadow_expensive",
})

gui.RegisterParam("set_fg_color", function(pnl, value1, value2, value3, value4)
    pnl:SetFGColor(value1, value2, value3, value4)
end, {
    "set_fg_color",
    "fg_color",
    "color_fg",
})

gui.RegisterParam("set_focus_top_level", function(pnl, value)
    value = value != nil and value or true
    pnl:SetFocusTopLevel(value)
end, {
    "set_focus_top_level",
    "focus_top_level",
    "top_focus",
    "focus_top",
    "top_level_focus",
    "top_focus_level",
    "focus_top_level",
})

gui.RegisterParam("set_font_internal", function(pnl, value)
    pnl:SetFontInternal(value)
end, {
    "set_font_internal",
    "font_internal",
    "internal_font",
    "font",
})

gui.RegisterParam("set_html", function(pnl, value)
    pnl:SetHTML(value)
end, {
    "html",
    "set_html",
})

gui.RegisterParam("set_keyboard_input", function(pnl, value)
    value = value != nil and value or true
    pnl:SetKeyboardInputEnabled(value)
end, {
    "set_keyboard_input",
    "keyboard_input_enabled",
    "keyboard_input",
    "key_input",
    "input_keyboard",
    "input_key",
})

gui.RegisterParam("set_maximum_char_count", function(pnl, value)
    pnl:SetMaximumCharCount(value)
end, {
    "set_maximum_char_count",
    "maximum_char_count",
    "max_char_count",
    "max_char",
    "max_chars_count",
    "max_chars",
})

gui.RegisterParam("set_minimal_size", function(pnl, value1, value2)
    pnl:SetMinimumSize(value1, value2)
end, {
    "set_minimal_size",
    "minimal_size",
    "size_minimal",
    "min_size",
    "size_min",
})

gui.RegisterParam("set_model", function(pnl, value)
    pnl:SetModel(value)
end, {
    "model",
    "set_model",
})

gui.RegisterParam("set_mouse_input_enabled", function(pnl, value)
    value = value != nil and value or true
    pnl:SetKeyboardInputEnabled(value)
end, {
    "set_mouse_input_enabled",
    "mouse_input_enabled",
    "mouse_input",
    "input_mouse",
})

gui.RegisterParam("set_name", function(pnl, value)
    pnl:SetName(value)
end, {
    "name",
    "set_name",
})

gui.RegisterParam("set_paint_background_enabled", function(pnl, value)
    value = value != nil and value or true
    pnl:SetPaintBackgroundEnabled(value)
end, {
    "set_paint_background_enabled",
    "paint_background_enabled",
    "paint_background",
    "background_paint",
    "paint_bg",
    "bg_paint",
    "bg_paint_enabled",
})

gui.RegisterParam("set_paint_border_enabled", function(pnl, value)
    value = value != nil and value or true
    pnl:SetPaintBorderEnabled(value)
end, {
    "set_paint_border_enabled",
    "paint_border_enabled",
    "paint_border",
    "border_paint",
})

gui.RegisterParam("set_painted_manually", function(pnl, value)
    value = value != nil and value or true
    pnl:SetPaintedManually(value)
end, {
    "set_painted_manually",
    "painted_manually",
    "paint_manually",
    "paint_manual",
    "manual_paint",
    "manually_paint",
    "manually_painted",
})

gui.RegisterParam("set_parent", function(pnl, value)
    pnl:SetParent(value)
end, {
    "set_parent",
    "parent",
})

gui.RegisterParam("set_player", function(pnl, value1, value2)
    pnl:SetPlayer(value1, value2)
end, {
    "set_player",
    "player",
})

gui.RegisterParam("set_popup_stay_at_back", function(pnl, value)
    value = value != nil and value or true
    pnl:SetPopupStayAtBack(value)
end, {
    "set_popup_stay_at_back",
    "popup_stay_at_back",
    "popup_at_back",
    "popup_back",
})

gui.RegisterParam("set_pos", function(pnl, value1, value2) -- TODO: Think about it
    pnl:SetPos(value1, value2)
end, {
    "set_pos",
    "set_position",
    "pos",
    "position",
})

gui.RegisterParam("set_render_in_screenshots", function(pnl, value)
    value = value != nil and value or true
    pnl:SetRenderInScreenshots(value)
end, {
    "set_render_in_screenshots",
    "render_in_screenshots",
    "render_screenshots",
    "render_screen",
    "screen_render",
    "screenshots_render",
})

gui.RegisterParam("set_selectable", function(pnl, value)
    value = value != nil and value or true
    pnl:SetSelectable(value)
end, {
    "set_selectable",
    "selectable",
})

gui.RegisterParam("set_selected", function(pnl, value)
    value = value != nil and value or true
    pnl:SetSelected(value)
end, {
    "set_selected",
    "selected",
})

gui.RegisterParam("set_selection_canvas", function(pnl, value)
    pnl:SetSelectionCanvas(value)
end, {
    "set_selection_canvas",
    "selection_canvas",
    "canvas_selection",
})

gui.RegisterParam("set_skin", function(pnl, value)
    pnl:SetSkin(value)
end, {
    "set_skin",
    "skin",
})

gui.RegisterParam("set_spawn_icon", function(pnl, value)
    pnl:SetSpawnIcon(value)
end, {
    "set_spawn_icon",
    "spawn_icon",
    "icon_spawn",
})

gui.RegisterParam("set_steamid", function(pnl, value) -- TODO: Think about it
    pnl:SetSteamID(value)
end, {
    "set_steamid",
    "set_steamid64",
    "set_sid64",
    "steamid",
    "steamid64",
})

gui.RegisterParam("set_tab_position", function(pnl, value)
    pnl:SetTabPosition(value)
end, {
    "set_tab_position",
    "tab_position",
    "tab_pos",
    "position_tab",
    "pos_tab",
})

gui.RegisterParam("set_term", function(pnl, value)
    pnl:SetTerm(value)
end, {
    "set_term",
    "term",
    "tab_pos",
})

gui.RegisterParam("set_text_inset", function(pnl, value1, value2)
    pnl:SetTextInset(value1, value2)
end, {
    "set_text_inset",
    "text_inset",
    "inset_text",
})

gui.RegisterParam("set_to_full_height", function(pnl, value)
    pnl:SetToFullHeight()
end, {
    "set_to_full_height",
    "to_full_height",
    "full_height",
    "full_tall",
    "height_full",
    "tall_full",
})

gui.RegisterParam("set_tooltip", function(pnl, value)
    pnl:SetTooltip(value)
end, {
    "set_tooltip",
    "tooltip",
})

gui.RegisterParam("set_tooltip_panel", function(pnl, value)
    pnl:SetTooltipPanel(value)
end, {
    "set_tooltip_panel",
    "set_tooltip",
    "tooltip_panel",
    "panel_tooltip",
})

gui.RegisterParam("set_tooltip_panel_override", function(pnl, value)
    pnl:SetTooltipPanelOverride(value)
end, {
    "set_tooltip_panel_override",
    "tooltip_panel_override",
    "tooltip_override",
})

gui.RegisterParam("set_underline_font", function(pnl, value)
    pnl:SetUnderlineFont(value)
end, {
    "set_underline_font",
    "underline_font",
    "font_underline",
})

gui.RegisterParam("set_url", function(pnl, value)
    pnl:SetURL(value)
end, {
    "set_url",
    "url",
})

gui.RegisterParam("set_vertical_scrollbar_enabled", function(pnl, value)
    value = value != nil and value or true
    pnl:SetVerticalScrollbarEnabled(value)
end, {
    "set_vertical_scrollbar_enabled",
    "vertical_scrollbar_enabled",
    "scrollbar_enabled",
})

gui.RegisterParam("set_visible", function(pnl, value)
    value = value != nil and value or true
    pnl:SetVisible(value)
end, {
    "set_visible",
    "visible",
})

gui.RegisterParam("set_world_clicker", function(pnl, value)
    value = value != nil and value or true
    pnl:SetWorldClicker(value)
end, {
    "set_world_clicker",
    "world_clicker",
    "clicker_world",
    "world_click",
    "click_world",
})

gui.RegisterParam("set_wrap", function(pnl, value)
    value = value != nil and value or true
    pnl:SetWrap(value)
end, {
    "set_wrap",
    "wrap",
})

gui.RegisterParam("set_x", function(pnl, value)
    pnl:SetX(value)
end, {
    "set_x",
    "x",
})

gui.RegisterParam("set_y", function(pnl, value)
    pnl:SetY(value)
end, {
    "set_y",
    "y",
})

gui.RegisterParam("set_z_pos", function(pnl, value)
    pnl:SetZPos(value)
end, {
    "set_z_pos",
    "set_zpos",
    "z_pos",
    "zpos",
})

gui.RegisterParam("focus", function(pnl, value)
    local pnlOwner = pnl:GetParent()

    local focus = pnlOwner:HasFocus() or pnlOwner:HasHierarchicalFocus()
    if not focus then
        pnl:RequestFocus()
    end
end, {
    "focus",
    "request_focus",
    "focus_request"
})

gui.RegisterParam("input", function(pnl, value)
    pnl:SetKeyboardInputEnabled(true)
    pnl:SetMouseInputEnabled(true)
end, {
    "input",
})

gui.RegisterParam("make_popup", function(pnl, value)
    pnl:MakePopup()
end, {
    "make_popup",
    "popup",
})

gui.RegisterParam("set_sizable", function(pnl, value)
    value = value != nil and value or true
    pnl:SetSizable(value)
end, {
    "set_sizable",
    "sizable",
})

gui.RegisterParam("set_title", function(pnl, value)
    pnl:SetTitle(value)
end, {
    "set_title",
    "title",
})

gui.RegisterParam("center", function(pnl, value)
    pnl:Center()
end, {
    "center",
    "middle",
})

gui.RegisterParam("center-horizontal", function(pnl, value)
    value = value != nil and value or 0.5
    pnl:CenterHorizontal(value)
end, {
    "center-horizontal",
    "horizontal-center",
    "center-wide",
    "center-width",
    "width-center",
    "wide-center",
    "wide-middle",
    "width-middle",
    "horizontal-middle",
    "middle-wide",
    "middle-width",
    "middle-horizontal",
})

gui.RegisterParam("center-vertical", function(pnl, value)
    value = value != nil and value or 0.5
    pnl:CenterVertical(value)
end, {
    "center-vertical",
    "vertical-center",
    "center-tall",
    "center-height",
    "height-center",
    "tall-center",
    "tall-middle",
    "height-middle",
    "vertical-middle",
    "middle-tall",
    "middle-height",
    "middle-vertical",
})