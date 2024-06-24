module("zen", package.seeall)

gui.RegisterParam("tPanel", function(pnl, value)
    for k, v in pairs(value) do
        pnl[k] = v
    end

    if pnl.zen_PreInit then pnl:zen_PreInit() end
    if value.Init then value.Init(pnl) end
end)

gui.RegisterParam("uniqueName", function(pnl, value)
    pnl.uniqueName = value
end, {
    "uniqueName",
})


gui.RegisterParam("set_size_middle", function(pnl, value)
    value = value or 0
    local pnlOwner = pnl:GetParent()
    local w, h = pnlOwner:GetSize()

    pnl:SetSize(w*0.5 + value, h*0.5 + value)
end, {
    "set_size_middle",
    "size_middle",
    "middle_size",
})

gui.RegisterParam("size_auto", function(pnl, value)
    local w, h = pnl:GetSize()
    local w1, h1 = pnl:ChildrenSize()
    local w2, h2 = pnl:GetContentSize()

    local mw, mh = math.max(w1 or 0, w2 or 0, w), math.max(h1 or 0, h2 or 0, h)

    pnl:SetSize(mw, mh)
end, {
    "size_auto",
    "auto_size",
})

gui.RegisterParam("size_auto_wide", function(pnl, value)
    local w, h = pnl:GetSize()
    local w1, h1 = pnl:ChildrenSize()
    local w2, h2 = pnl:GetContentSize()

    local mw, mh = math.max(w1 or 0, w2 or 0, w)

    pnl:SetWide(mw)
end, {
    "size_auto_wide",
    "size_auto_width",
    "auto_wide",
    "auto_width",
    "width_auto",
    "wide_auto",
})

gui.RegisterParam("size_auto_tall", function(pnl, value)
    local w, h = pnl:GetSize()
    local w1, h1 = pnl:ChildrenSize()
    local w2, h2 = pnl:GetContentSize()

    local mw, mh = math.max(h1 or 0, h2 or 0, h)

    pnl:SetTall(mh)
end, {
    "size_auto_tall",
    "size_auto_height",
    "auto_tall",
    "auto_height",
    "height_auto",
    "tall_auto",
})


gui.RegisterParam("size_children", function(pnl, value)
    pnl:SizeToChildren(true, true)
end, {
    "children_size",
})

gui.RegisterParam("set_size", function(pnl, value)
    pnl:SetSize(unpack(value))
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

gui.RegisterParam("dock_margin", function(pnl, value)
    if value == nil then value = {0,0,0,0} end
    pnl:DockMargin(unpack(value))
    pnl:InvalidateParent(true)
end, {
    "dock_margin",
    "margin",
})

gui.RegisterParam("dock_margin_top", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockMargin()
    pnl:DockMargin(a1, value, a3, a4)
    pnl:InvalidateParent(true)
end, {
    "margin_top",
    "margin_up",
    "top_margin",
    "up_margin",
})

gui.RegisterParam("dock_margin_bottom", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockMargin()
    pnl:DockMargin(a1, a2, a3, value)
    pnl:InvalidateParent(true)
end, {
    "margin_bottom",
    "margin_down",
    "bottom_margin",
    "down_margin",
})

gui.RegisterParam("dock_margin_left", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockMargin()
    pnl:DockMargin(value, a2, a3, a4)
    pnl:InvalidateParent(true)
end, {
    "margin_left",
    "left_margin",
})

gui.RegisterParam("dock_margin_right", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockMargin()
    pnl:DockMargin(a1, a2, value, a4)
    pnl:InvalidateParent(true)
end, {
    "margin_right",
    "right_margin",
})

gui.RegisterParam("dock_padding", function(pnl, value)
    if value == nil then value = {0,0,0,0} end
    pnl:DockPadding(unpack(value))
    pnl:InvalidateParent(true)
end, {
    "dock_padding",
    "padding",
})

gui.RegisterParam("dock_padding_top", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockPadding()
    pnl:DockPadding(a1, value, a3, a4)
    pnl:InvalidateParent(true)
end, {
    "padding_top",
    "padding_up",
    "top_padding",
    "up_padding",
})

gui.RegisterParam("dock_padding_bottom", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockPadding()
    pnl:DockPadding(a1, a2, a3, value)
    pnl:InvalidateParent(true)
end, {
    "padding_bottom",
    "padding_down",
    "bottom_padding",
    "down_padding",
})

gui.RegisterParam("dock_padding_left", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockPadding()
    pnl:DockPadding(value, a2, a3, a4)
    pnl:InvalidateParent(true)
end, {
    "padding_left",
    "left_padding",
})

gui.RegisterParam("dock_padding_right", function(pnl, value)
    local a1, a2, a3, a4 = pnl:GetDockPadding()
    pnl:DockPadding(a1, a2, value, a4)
    pnl:InvalidateParent(true)
end, {
    "padding_right",
    "right_padding",
})


gui.RegisterParam("set_auto_delete", function(pnl, value)
    if value == nil then value = true end
    pnl:SetAutoDelete(value)
end, {
    "set_auto_delete",
    "auto_delete",
    "delete_auto",
})

gui.RegisterParam("set_bg_color", function(pnl, value)
    pnl:SetBGColor(unpack(value))
end, {
    "set_bg_color",
    "bg_color",
    "background_color",
    "color_bg",
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

gui.RegisterParam("set_cookie", function(pnl, value)
    pnl:SetCookie(unpack(value))
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
    if value == nil then value = true end
    pnl:SetDrawLanguageIDAtLeft(value)
end, {
    "draw_language_id_at_left",
    "language_id_left",
    "language_at_left",
    "language_left",
})

gui.RegisterParam("set_draw_on_top", function(pnl, value)
    if value == nil then value = true end
    pnl:SetDrawOnTop(value)
end, {
    "draw_on_top",
    "draw_top",
    "top_draw",
})

gui.RegisterParam("set_drop_target", function(pnl, value)
    pnl:SetDropTarget(unpack(value))
end, {
    "drop_target",
    "target_drop",
})

gui.RegisterParam("set_enabled", function(pnl, value)
    if value == nil then value = true end
    pnl:SetEnabled(value)
end, {
    "set_enabled",
    "enabled",
})

gui.RegisterParam("set_disable", function(pnl, value)
    if value == nil then value = true end
    pnl:SetEnabled(not value)
end, {
    "set_disable",
    "disable",
})

gui.RegisterParam("expensive_shadow", function(pnl, value)
    pnl:SetExpensiveShadow(unpack(value))
end, {
    "expensive_shadow",
    "shadow_expensive",
})

gui.RegisterParam("set_fg_color", function(pnl, value)
    pnl:SetFGColor(unpack(value))
end, {
    "set_fg_color",
    "fg_color",
    "color_fg",
})

gui.RegisterParam("set_focus_top_level", function(pnl, value)
    if value == nil then value = true end
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
    if pnl.SetFont then
        pnl:SetFont(value)
    end
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

gui.RegisterParam("set_keyboard_input_enabled", function(pnl, value)
    if value == nil then value = true end
    pnl:SetKeyboardInputEnabled(value)
end, {
    "set_keyboard_input_enabled",
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

gui.RegisterParam("set_minimal_size", function(pnl, value)
    pnl:SetMinimumSize(unpack(value))
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
    if value == nil then value = true end
    pnl:SetMouseInputEnabled(value)
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
    if value == nil then value = true end
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
    if value == nil then value = true end
    pnl:SetPaintBorderEnabled(value)
end, {
    "set_paint_border_enabled",
    "paint_border_enabled",
    "paint_border",
    "border_paint",
})

gui.RegisterParam("set_painted_manually", function(pnl, value)
    if value == nil then value = true end
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

gui.RegisterParam("set_player", function(pnl, value)
    pnl:SetPlayer(unpack(value))
end, {
    "set_player",
    "player",
})

gui.RegisterParam("set_popup_stay_at_back", function(pnl, value)
    if value == nil then value = true end
    pnl:SetPopupStayAtBack(value)
end, {
    "set_popup_stay_at_back",
    "popup_stay_at_back",
    "popup_at_back",
    "popup_back",
})

gui.RegisterParam("set_pos", function(pnl, value) -- TODO: Think about it
    pnl:SetPos(unpack(value))
end, {
    "set_pos",
    "set_position",
    "pos",
    "position",
})

gui.RegisterParam("set_render_in_screenshots", function(pnl, value)
    if value == nil then value = true end
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
    if value == nil then value = true end
    pnl:SetSelectable(value)
end, {
    "set_selectable",
    "selectable",
})

gui.RegisterParam("set_selected", function(pnl, value)
    if value == nil then value = true end
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
})

gui.RegisterParam("set_text_inset", function(pnl, value)
    pnl:SetTextInset(unpack(value))
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
    if value == nil then value = true end
    pnl:SetVerticalScrollbarEnabled(value)
end, {
    "set_vertical_scrollbar_enabled",
    "vertical_scrollbar_enabled",
    "scrollbar_enabled",
})

gui.RegisterParam("set_visible", function(pnl, value)
    if value == nil then value = true end
    pnl:SetVisible(value)
end, {
    "set_visible",
    "visible",
})

gui.RegisterParam("set_world_clicker", function(pnl, value)
    if value == nil then value = true end
    pnl:SetWorldClicker(value)
end, {
    "set_world_clicker",
    "world_clicker",
    "clicker_world",
    "world_click",
    "click_world",
})

gui.RegisterParam("set_wrap", function(pnl, value)
    if value == nil then value = true end
    pnl:SetWrap(value)
end, {
    "set_wrap",
    "wrap",
})

gui.RegisterParam("set_multiline", function(pnl, value)
    if value == nil then value = true end
    pnl:SetMultiline(value)
end, {
    "set_multiline",
    "multiline",
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
    if value == nil then value = true end
    pnl:SetKeyboardInputEnabled(value)
    pnl:SetMouseInputEnabled(value)
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
    if value == nil then value = true end
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

gui.RegisterParam("center_horizontal", function(pnl, value)
    if value == nil then value = 0.5 end
    pnl:CenterHorizontal(value)
end, {
    "center_horizontal",
    "horizontal_center",
    "center_wide",
    "center_width",
    "width_center",
    "wide_center",
    "wide_middle",
    "width_middle",
    "horizontal_middle",
    "middle_wide",
    "middle_width",
    "middle_horizontal",
})

gui.RegisterParam("center_vertical", function(pnl, value)
    if value == nil then value = 0.5 end
    pnl:CenterVertical(value)
end, {
    "center_vertical",
    "vertical_center",
    "center_tall",
    "center_height",
    "height_center",
    "tall_center",
    "tall_middle",
    "height_middle",
    "vertical_middle",
    "middle_tall",
    "middle_height",
    "middle_vertical",
})


gui.RegisterParam("set_data", function(pnl, value)
    pnl:SetData(value)
end, {
    "set_data",
    "data",
})

gui.RegisterParam("set_value", function(pnl, value)
    pnl:SetValue(value)
end, {
    "set_value",
    "value",
})

gui.RegisterParam("cc", function(pnl, value)
    assertTable(value, "value")

    for k, v in pairs(value) do
        pnl[k] = v
    end
end, {
    "cc",
    "CC",
})

gui.RegisterParam("nopaint", function(pnl, value)
    pnl.Paint = nil
end, {
    "no_paint",
    "paint_no",
    "-paint",
    "disable_paint",
    "paint_disable",
})

gui.RegisterParam("save_pos", function(pnl, value)
    local pnlInh = pnl.zen_MotherPanel or pnl.zen_OriginalPanel
    local name = value or pnlInh.zen_UniqueName

    assertStringNice(name, "name")

    pnl:zen_AddStyled("func_save_pos", {cc = {zen_pnlSavePos = pnlInh}, cookie_name = name})
end, {
    "save_pos",
    "pos_save",
})


gui.mt_ParentVisible = gui.mt_ParentVisible or {}

local IsValid = IsValid
local table_IsEmpty = table.IsEmpty
local IsVisible = META.PANEL.IsVisible

ihook.Listen("Think", "zen.gui.ParentParentVisible", function()
    for pnlParent, childrens in pairs(gui.mt_ParentVisible) do
        if table_IsEmpty(childrens) then gui.mt_ParentVisible[pnlParent] = nil continue end

        local isRemove = IsValid(pnlParent) != true
        

        if not isRemove then
            local isVisible = IsVisible(pnlParent)
            if pnlParent.zen_bParentVisible != isVisible then
                pnlParent.zen_bParentVisible = isVisible

                print("Set Visible", isVisible)

                for pnlChildren in pairs(childrens) do
                    if not IsValid(pnlChildren) then
                        childrens[pnlChildren] = nil
                        continue
                    end
                    pnlChildren:SetVisible(isVisible)
                end
            end
        else
            for pnlChildren in pairs(childrens) do
                if not IsValid(pnlChildren) then continue end
                pnlChildren:Remove()
            end
            gui.mt_ParentVisible[pnlParent] = nil
        end
    end
end)

gui.RegisterParam("visible_parent", function(pnl, pnlParent)
    assert(ispanel(pnlParent), "pnlParent not is panel")
    assertValid(pnlParent, "pnlParent")

    pnlParent.zen_bParentVisible = nil
    gui.mt_ParentVisible[pnlParent] = gui.mt_ParentVisible[pnlParent] or {}
    gui.mt_ParentVisible[pnlParent][pnl] = true
end, {
    "visible_parent",
    "parent_visible",
})



gui.RegisterParam("override_mouse_hooks", function(pnl)
    pnl.pnlOverRideMouse = pnl:zen_AddStyled("base", {cc = {
        pnl_Parent = pnl,
        bLastHover = false,
        Think = function(self)
            if not IsValid(self.pnl_Parent) then return end
            local w, h = self.pnl_Parent:GetSize()
            self:SetSize(w, h)

            local cx, cy = self:LocalCursorPos()
            local isHovered = self:zen_IsHovered()

            if self.bLastHover != isHovered then
                self.bLastHover = isHovered

                if isHovered then
                    if self.pnl_Parent.OnCursorEntered then
                        self.pnl_Parent:OnCursorEntered()
                    end
                else
                    if self.pnl_Parent.OnCursorExited then
                        self.pnl_Parent:OnCursorExited()
                    end
                end
            end

            if self.bLastHover then
                if self.pnl_Parent.OnCursorMoved then
                    self.pnl_Parent:OnCursorMoved(cx, cy)
                end
            end
        end,
    }, input = false})


    ihook.Listen("PlayerButtonPress", pnl.pnlOverRideMouse, function(self, ply, but)
        if but < MOUSE_FIRST or but > MOUSE_LAST then return end
        if not vgui.CursorVisible() then return end

        if but == MOUSE_WHEEL_DOWN then
            if self.pnl_Parent.OnMouseWheeled then
                self.pnl_Parent:OnMouseWheeled(1)
            end
            return
        end

        if but == MOUSE_WHEEL_UP then
            if self.pnl_Parent.OnMouseWheeled then
                self.pnl_Parent:OnMouseWheeled(-1)
            end
            return
        end


        if self.bLastHover then
            if self.pnl_Parent.OnMousePressed then
                self.pnl_Parent:OnMousePressed(but)
            end
        end
    end, HOOK_MONITOR_HIGH)
    ihook.Listen("PlayerButtonUnPress", pnl.pnlOverRideMouse, function(self, ply, but)
        if but < MOUSE_FIRST or but > MOUSE_LAST then return end
        if but == MOUSE_WHEEL_DOWN or but == MOUSE_WHEEL_UP then return end
        if not vgui.CursorVisible() then return end

        if self.bLastHover then
            if self.pnl_Parent.OnMouseReleased then
                self.pnl_Parent:OnMouseReleased(but)
            end
        end
    end, HOOK_MONITOR_HIGH)
end)