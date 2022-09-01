local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.t_StylePanels =gui.t_StylePanels or {}
gui.t_Commands = gui.t_Commands or {}
gui.t_CommandsAliases = gui.t_CommandsAliases or {}
gui.t_UniquePanels = gui.t_UniquePanels or {}
gui.t_Presets = gui.t_Presets or {}

function gui.MergeParams(tSource, tDestination)
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

        table.insert(tSource, k)
    end
end

local ParamsPriority = {
    "set_size",
    "set_wide",
    "set_tall",
    "dock",
    "dock_fill",
    "dock_bottom",
    "dock_top",
    "dock_right",
    "dock_left",
    "set_pos",
    "set_x",
    "set_y",
    "center",
}

function gui.ApplyParam(pnl, param, value)
    local func = gui.t_Commands[param]
    if not isfunction(func) then
        pnl:Remove()
        error("param not exists: " .. param)
    end
    
    if istable(value) then
        func(pnl, unpack(value))
    else
        func(pnl, value)
    end
end


function gui.GetClearedParams(data)
    local tParams = {}
    local tFuncs = {}

    for k, v in pairs(data) do
        if isstring(k) then
            local param = gui.t_CommandsAliases[k]
            if not param then return false, "param not exists: " .. k end

            tParams[param] = v
        elseif isnumber(k) then

            if isstring(v) then
                local param = gui.t_CommandsAliases[v]
                if not param then return false, "param not exists: " .. v end

                tParams[param] = {}
            elseif isfunction(v) then
                table.insert(tFuncs, v)
            else
                return false, "UnSupported param type: " .. tostring(v) .. " - " .. type(v)
            end
        else
            return false, "UnSupported type: " .. tostring(k) .. " - " .. type(k)
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

    for _, param in pairs(ParamsPriority) do
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
end

function gui.Create(pnl_name, pnlParent, data, uniqueName, presets)
    if uniqueName then
        local lastPanel = gui.t_UniquePanels[uniqueName]
        if IsValid(lastPanel) then lastPanel:Remove() end
    end

    local pnl = vgui.Create(pnl_name, pnlParent)

    if not IsValid(pnl) then
        error("Panel not IsValid")
    end

    if uniqueName then
        gui.t_UniquePanels[uniqueName] = pnl
    end

    local tData = {}

    if presets then
        if not istable(presets) then presets = {presets} end
        for _, presetName in ipairs(presets) do
            local tPreset = gui.t_Presets[presetName]
            if tPreset == nil then
                pnl:Remove()
                error("preset not exists: " .. presetName)
            end
            gui.MergeParams(tData, tPreset)
        end
    end

    gui.MergeParams(tData, data)

    gui.ApplyParams(pnl, tData)
end

function gui.RegisterPreset(preset_name, preset_base, data)
    local tPreset = {}

    if preset_base then
        local tPresetBase = gui.t_Presets[preset_base]
        assert(tPresetBase != nil, "preset_base not exists")
        gui.MergeParams(tPreset, tPresetBase)
    end

    gui.MergeParams(tPreset, data)
    gui.t_Presets[preset_name] = tPreset
end

function gui.RegisterParam(param, func, aliases)
    assertString(param, "param")
    assertFunction(func, "func")

    gui.t_Commands[param] = func
    for k, alias in ipairs(aliases) do
        gui.t_CommandsAliases[alias] = param
    end
end

function gui.CreateStyled(styleName, pnlParent, uniqueName, extraData, extraPresets)
    assertStringNice(styleName, "styleName")
    local tStylePanel = gui.t_StylePanels[styleName]
    assert(tStylePanel != nil, "tStylePanel is nil")

    local tData = {}

    local tPresets = {}

    if tStylePanel.data then
        gui.MergeParams(tData, tStylePanel.data)
    end
    if extraData then
        gui.MergeParams(tData, extraData)
    end

    if tStylePanel.presets then
        gui.MergeParams(tPresets, tStylePanel.presets)
    end
    if extraPresets then
        gui.MergeParams(tPresets, extraPresets)
    end

    gui.Create(tStylePanel.vguiBase, pnlParent, tData, uniqueName, tPresets)
end

function gui.RegisterStylePanel(styleName, tPanel, vguiBase, data, presets)
    assertStringNice(styleName, "styleName")
    assert(istable(tPanel) or istable == nil, "tPanel presets should be table|nil")
    assertStringNice(vguiBase, "vguiBase")
    assert(istable(data) or data == nil, "data should be table|nil")
    assert(istable(presets) or presets == presets, "presets should be table|nil")

    gui.t_StylePanels[styleName] = {}
    tPanel = tPanel or {}
    local tStylePanel = gui.t_StylePanels[styleName]

    tStylePanel.tPanel = tPanel
    tStylePanel.vguiBase = vguiBase
    tStylePanel.data = data
    tStylePanel.presets = presets
end
