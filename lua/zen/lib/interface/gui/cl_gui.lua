module("zen", package.seeall)

gui = _GET("gui", gui)

local sub = string.sub

gui.t_StylePanels =gui.t_StylePanels or {}
gui.t_Commands = gui.t_Commands or {}
gui.t_CommandsAliases = gui.t_CommandsAliases or {}
gui.t_UniquePanels = gui.t_UniquePanels or {}
gui.t_PresetsParams = gui.t_PresetsParams or {}

gui.proxyEmpty = gui.proxyEmpty or newproxy(true)
gui.proxySkip = gui.proxySkip or newproxy(true)

debug.setmetatable(gui.proxyEmpty, {__tostring = function() return "<gui.proxyEmpty>" end})
debug.setmetatable(gui.proxySkip, {__tostring = function() return "<gui.proxySkip>" end})



function gui.GetAliasParam(alias)
    local param = gui.t_CommandsAliases[alias]
    if param != nil then return param end

    local char1 = sub(alias, 1, 1)

    if char1 == "!" then
        local alias = sub(alias, 2)
        local param = gui.t_CommandsAliases[alias]
        if param != nil then return param, true end
    end
end

function gui.GetParam(data, key, bErrOrStrErr)
    local param, isNot = gui.GetAliasParam(key)

    if param == nil then
        error("param not exists: " .. tostring(key))
    end

    local value = data[param]

    if value == nil then
        if bErrOrStrErr == true then
            error("param value not exists: " .. tostring(param) .. "|" .. tostring(key))
        elseif isstring(bErrOrStrErr) then
            error(bErrOrStrErr)
        end
    end

    if isNot == true and (value == true or value == gui.proxyEmpty) then
        value = false
    end
    return value, param
end

function gui.SelectDuplicated(val1, val2, param, key)
    return val2
end

function gui.MergeTables(tSource, tDestination)
    local tSourceSingleParams = {}

    for k, v in pairs(tSource) do
        if isnumber(k) then
            tSourceSingleParams[k] = true
        end
    end

    local tDestinationSingleParams = {}

    for k, v in pairs(tDestination) do
        if isnumber(k) then tDestinationSingleParams[v] = true continue end

        if isstring(k) then
            tSource[k] = v
        end
    end

    for k, v in pairs(tDestinationSingleParams) do
        if tSourceSingleParams[k] then continue end
        if tSource[v] then continue end

        table.insert(tSource, k)
    end
end

function gui.MergeParams(tSource, tDestination)
    local tActiveParams = {}

    for k, v in pairs(tSource) do
        if isnumber(k) then

            if not isstring(v) then
                error("number-keys can't be not a string")
            end

            local old_value, param = gui.GetParam(tSource, v)
            if old_value != nil then
                tSource[param] = gui.SelectDuplicated(old_value, gui.proxyEmpty, param, v)
            else
                tSource[param] = gui.proxyEmpty
            end
            tActiveParams[param] = true
        elseif isstring(k) then

            local old_value, param = gui.GetParam(tSource, k)
            if old_value != nil then
                tSource[param] = gui.SelectDuplicated(old_value, v, param, k)
            else
                tSource[param] = v
            end
            tActiveParams[param] = true
        end
    end

    for k, v in pairs(tDestination) do
        if isnumber(k) then
            if not isstring(v) then
                error("number-keys can't be not a string")
            end

            local old_value, param = gui.GetParam(tSource, v)
            if old_value != nil then
                tSource[param] = gui.SelectDuplicated(old_value, gui.proxyEmpty, param, v)
            else
                tSource[param] = gui.proxyEmpty
            end
            tActiveParams[param] = true
        elseif isstring(k) then
            local old_value, param = gui.GetParam(tSource, k)
            if old_value != nil then
                tSource[param] = gui.SelectDuplicated(old_value, v, param, k)
            else
                tSource[param] = v
            end
            tActiveParams[param] = true
        end
    end

    for k, v in pairs(tSource) do
        if tActiveParams[k] == nil then
            tSource[k] = nil
        end
    end
end

local ParamsFirst = { -- 1, 2, 3
    "tPanel",

    "set_text",

    "set_minimal_size",
    "size_auto",
    "size_auto_tall",
    "size_auto_wide",
    "set_size",
    "set_wide",
    "set_tall",
    "set_size_middle",
    "center_vertical",
    "center_horizontal",
    "dock",
    "dock_fill",
    "dock_bottom",
    "dock_top",
    "dock_right",
    "dock_left",
    "dock_padding",
    "dock_margin",
    "set_pos",
    "set_x",
    "set_y",
    "center",
    "make_popup",
    "set_keyboard_input_enabled",
    "set_mouse_input_enabled",
}

local ParamPost_Repeat = {
    "size_auto",
    "size_auto_tall",
    "size_auto_wide",
}

function gui.ApplyParam(pnl, param, value)
    local func = gui.t_Commands[param]
    if not isfunction(func) then
        pnl:Remove()
        error("param not exists: " .. param)
    end

    if value == gui.proxySkip then return end
    if value == gui.proxyEmpty then
        value = nil
    end

    func(pnl, value)
end


function gui.GetClearedParams(data)
    local tParams = {}
    local tFuncs = {}

    for k, v in pairs(data) do
        if isstring(k) then
            local param = gui.GetAliasParam(k)
            if not param then return false, "param not exists: " .. k end

            if v != gui.proxySkip then
                tParams[param] = v
            end
        elseif isnumber(k) then

            if isstring(v) then
                local param = gui.GetAliasParam(v)
                if not param then return false, "param not exists: " .. v end

                tParams[param] = gui.proxyEmpty
            elseif isfunction(v) then
                table.insert(tFuncs, v)
            else
                return false, "UnSupported param type: " .. tostring(v) .. " - " .. type(v)
            end
        elseif isfunction(k) then
            table.insert(tFuncs, k)
        else
            return false, "UnSupported type #2: " .. tostring(k) .. " - " .. type(k)
        end
    end

    return true, tParams, tFuncs
end

function gui.ApplyParams(pnl, data)
    local tCalled = {}

    local succ, tParams, tFuncs = gui.GetClearedParams(data)
    if not succ then
        pnl:Remove()
        error(tParams or "unknown error")
    end

    pnl.zen_tmp_Params = data

    for _, param in pairs(ParamsFirst) do
        local vParam = tParams[param]
        if vParam then
            tCalled[param] = true
            gui.ApplyParam(pnl, param, vParam)
        end
    end

    for param, vParam in pairs(tParams) do
        if tCalled[param] then continue end

        gui.ApplyParam(pnl, param, vParam)
    end

    for _, tFunc in ipairs(tFuncs) do
        tFunc(pnl)
    end

    if pnl.zen_PostInit and not pnl.zen_bPostInitSucc then
        pnl.zen_bPostInitSucc = true
        pnl:zen_PostInit()
    end

    for _, param in pairs(ParamPost_Repeat) do
        local vParam = tParams[param]
        if vParam then
            timer.Simple(0, function()
                if IsValid(pnl) then
                    gui.ApplyParam(pnl, param, vParam)
                end
            end)
        end
    end

    pnl.zen_tmp_Params = nil
end

---@param pnl_name string
---@param pnlParent? Panel
---@param data? table
---@param uniqueName? string
---@param presets? table
---@param isAdd? boolean -- Use pnlParent:Add function
---@return Panel pnlCustom
function gui.Create(pnl_name, pnlParent, data, uniqueName, presets, isAdd)
    data = data or {}

    if uniqueName then
        assertStringNice(uniqueName, "uniqueName")

        local lastPanel = gui.t_UniquePanels[uniqueName]
        if IsValid(lastPanel) then lastPanel:Remove() end
    end

    if not pnlParent then
        local pnlOwner = gui.GetParam(data, "parent")
        pnlParent = pnlOwner
    end

    local pnl
    if pnlParent and isAdd then
        pnl = pnlParent:Add(pnl_name)
        if uniqueName then
            pnl:SetName(uniqueName)
        end
    else
        pnl = vgui.Create(pnl_name, pnlParent, uniqueName)
    end

    if not IsValid(pnl) then
        error("Panel not IsValid")
    end

    if uniqueName then
        gui.t_UniquePanels[uniqueName] = pnl
    end

    pnl.zenCreated = true

    local pnlOwner = pnl:GetParent()

    if pnlOwner.zenCreated then
        pnl.zen_MotherPanel = pnlOwner.zen_MotherPanel
    else
        pnl.zen_MotherPanel = pnl
        pnl.zen_MotherPanel.zen_UniqueName = uniqueName
    end

    pnl.zen_OriginalPanel = pnlOwner.zen_OriginalPanel or pnlOwner
    if pnl.zen_OriginalPanel == vgui.GetWorldPanel() and pnl.zen_OriginalPanel != GetHUDPanel() then
        pnl.zen_OriginalPanel = pnl
    end

    local tData = {}

    if presets then
        if not istable(presets) then presets = {presets} end
        for _, presetName in ipairs(presets) do
            local tPreset = gui.t_PresetsParams[presetName]
            if tPreset == nil then
                pnl:Remove()
                error("preset not exists: " .. presetName)
            end
            gui.MergeParams(tData, tPreset)
        end
    end

    gui.MergeParams(tData, data)

    gui.ApplyParams(pnl, tData)
    return pnl
end

function gui.RegisterPreset(preset_name, preset_base, data)
    local tPreset = {}

    if preset_base then
        local tPresetBase = gui.t_PresetsParams[preset_base]
        assert(tPresetBase != nil, "preset_base not exists")
        gui.MergeParams(tPreset, tPresetBase)
    end

    gui.MergeParams(tPreset, data)
    gui.t_PresetsParams[preset_name] = tPreset
end

function gui.RegisterParam(param, func, aliases)
    assertString(param, "param")
    assertFunction(func, "func")

    gui.t_Commands[param] = func
    gui.t_CommandsAliases[param] = param
    if aliases then
        for k, alias in ipairs(aliases) do
            if param == alias then continue end

            local ownerParam = gui.t_CommandsAliases[alias]
            if ownerParam and ownerParam != param then
                error("Alias already exists: " ..  tostring(alias))
            end

            gui.t_CommandsAliases[alias] = param
        end
    end
end

META.PANEL.zen_Add = function(self, pnl_name, extraData, extraPresets)
    return gui.Create(pnl_name, self, extraData, nil, extraPresets, true)
end
META.PANEL.zen_AddStyled = function(self, styleName, extraData, extraPresets)
    return gui.CreateStyled(styleName, self, nil, extraData, extraPresets, true)
end

function gui.CreateStyled(styleName, pnlParent, uniqueName, extraData, extraPresets, isAdd)
    assertStringNice(styleName, "styleName")
    local tStylePanel = gui.t_StylePanels[styleName]
    assert(tStylePanel != nil, "stylePanel not exists: " .. tostring(styleName))

    local tData = {}

    local tPresets = {}

    if tStylePanel.presets then
        gui.MergeTables(tPresets, tStylePanel.presets)
    end
    if tStylePanel.data then
        gui.MergeParams(tData, tStylePanel.data)
    end

    if extraPresets then
        gui.MergeTables(tPresets, extraPresets)
    end
    if extraData then
        gui.MergeParams(tData, extraData)
    end

    if istable(tStylePanel.tPanel) then
        tData.tPanel = tStylePanel.tPanel
    end

    local pnl = gui.Create(tStylePanel.vguiBase, pnlParent, tData, uniqueName, tPresets, isAdd)

    if pnl.zen_PostInit and not pnl.zen_bPostInitSucc then
        pnl.zen_bPostInitSucc = true
        pnl:zen_PostInit()
    end

    return pnl
end

function gui.RegisterStylePanel(styleName, tPanel, vguiBase, data, presets)
    assertStringNice(styleName, "styleName")
    assert(istable(tPanel) or tPanel == nil, "tPanel presets should be table|nil")
    assertStringNice(vguiBase, "vguiBase")
    assert(istable(data) or data == nil, "data should be table|nil")
    assert(istable(presets) or presets == nil, "presets should be table|nil")

    gui.t_StylePanels[styleName] = {}
    tPanel = tPanel or {}
    local tStylePanel = gui.t_StylePanels[styleName]

    tStylePanel.tPanel = tPanel
    tStylePanel.vguiBase = vguiBase
    tStylePanel.data = data
    tStylePanel.presets = presets
end


local type = type
local function isNav(key)
    return type(key) == "table" and type(key[1]) == "string" and type(key[1]) == "string"
end

local function isTableOrNil(value)
    return value == nil or type(value) == "table"
end

local function isFragmentNav(fragment)
    return type(fragment) == "table" and isNav(fragment[1]) and isTableOrNil(fragment[2]) and isTableOrNil(fragment[2]) and isTableOrNil(fragment[3]) and isTableOrNil(fragment[4])
end

function gui.SuperCreate_Content(nav, data, nav_spawn_queue, nav_parent)
    for id, fragment in pairs(data) do
        if isFragmentNav(fragment) then
            local nav_keys = fragment[1]

            local nav_name = nav_keys[1]
            if nav[nav_name] then error("nav_name already exists: \"" .. nav_name .. "\"") end
            if nav_name == "v" then error("nav_name can't be \"v\"") end


            nav[nav_name] = true

            local style = nav_keys[2]
            if type(style) != "string" then error("nav style not is string") end

            nav[nav_name] = {}

            local extraData = fragment[2]
            local extraPresets = fragment[3]

            if extraData != nil and type(extraData) != "table" then error("nav extraData not is table") end
            if extraPresets != nil and type(extraPresets) != "table"then error("nav extraPresets not is table") end

            nav[nav_name].data = extraData
            nav[nav_name].presets = extraPresets
            nav[nav_name].style = style
            nav[nav_name].nav_parent = nav_parent
            table.insert(nav_spawn_queue, nav_name)

            local next_nav_data = fragment[4]

            if type(next_nav_data) == "table" then
                gui.SuperCreate_Content(nav, {next_nav_data}, nav_spawn_queue, nav_name)
            end
        elseif type(fragment) == "table" then
            gui.SuperCreate_Content(nav, fragment, nav_spawn_queue, nav_parent)
        end
    end

    return nav, nav_spawn_queue
end


function gui.SuperCreate(data, uniqueName)
    assertTableNice(data, "data")

    local nav = {}
    local nav_spawn_queue = {}

    local nav_result = gui.SuperCreate_Content(nav, data, nav_spawn_queue)

    local nav_panels = {}


    local isUniqueFree = true
    for id, nav_name in pairs(nav_spawn_queue) do
        local dat = nav_result[nav_name]

        local style = dat.style
        local presets = dat.presets
        local data = dat.data

        local parent = dat.nav_parent

        local pnlParent = parent and nav_panels[parent] or nil

        local newUniqueName
        if isUniqueFree then
            newUniqueName = uniqueName
            isUniqueFree = false
        end

        local pnl = gui.CreateStyled(style, pnlParent, newUniqueName, data, presets, true)
        nav_panels[nav_name] = pnl
    end

    return nav_panels, nav_result
end

--[[
local nav = gui.SuperCreate(
{
    {
        {"main", "frame"};
        {size = {300, 500}, title = "SuperCreate", "pos_save"};
        {};
        {
            {"content", "content"};
            {};
            {};
            {
                {
                    {"items", "list"}
                };
                {
                    {"add_point", "button"};
                    {"dock_bottom", text = "Add Point"};
                };
                {
                    {"remove_all", "button"};
                    {"dock_bottom", text = "Remove All Points"};
                };
                {
                    {"test_lastpos", "button"};
                    {"dock_bottom", text = "Test Last"};
                }
            }
        }
    }
}, "PanelName")

nav.add_point.DoClick = function(self)
    print("Add Point")
end
]]--


function META.PANEL:zen_IsHovered(ignoreVisible)
    if not ignoreVisible and not self:IsVisible() then return end
    local w, h = self:GetSize()
    local cx, cy = self:LocalCursorPos()
    if cx > 0 and cy > 0 and cx < w and cy < h then
        return true
    else
        return false
    end
end


function META.PANEL:zen_ChildrenHasKeyboardFocus()
    local key_focus = vgui.GetKeyboardFocus()
    return IsValid(key_focus) and key_focus:IsVisible() and key_focus:HasParent(self)
end

function META.PANEL:zen_MakePopup()
    self:MakePopup(true)
	self:SetKeyboardInputEnabled(false)

    ihook.Listen("OnTextEntryGetFocus", self, function(self, pnl)
		if pnl:HasParent(self) then
            timer.Simple(0.01, function()
                self:SetKeyboardInputEnabled(true)
                pnl.zen_iFocusLastStart = CurTime()
                pnl.zen_iLastButton = input.GetLastPressedButton()
            end)
		end
	end)

	ihook.Listen("OnTextEntryLoseFocus", self, function(self, pnl)
		if pnl:HasParent(self) then
			self:SetKeyboardInputEnabled(false)
            pnl.zen_iFocusLastEnd = CurTime()
		end
	end)
end