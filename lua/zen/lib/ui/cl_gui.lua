local ui = zen.Init("ui")
local gui = ui.Init("gui")

gui.t_Commands = gui.t_Commands or {}
gui.t_CommandsAliases = gui.t_CommandsAliases or {}
gui.t_UniquePanels = gui.t_UniquePanels or {}
gui.t_Presets = gui.t_Presets or {}

function gui.ApplyParams(pnl, data)
    for k, v in pairs(data) do
        if isnumber(k) then
            if isstring(v) then
                local key = gui.t_CommandsAliases[v]
                local func = gui.t_Commands[key]
                if not isfunction(func) then
                    pnl:Remove()
                    error("func not exists: " .. v)
                end
                func(pnl)
            elseif isfunction(v) then
                v(pnl)
            else
                pnl:Remove()
                error("nothing to create: " .. tostring(v))
            end
        elseif isstring(k) then
            local key = gui.t_CommandsAliases[k]
            local func = gui.t_Commands[key]
            if not isfunction(func) then
                pnl:Remove()
                error("func not exists: " .. k)
            end
            
            if istable(v) then
                func(pnl, unpack(v))
            else
                func(pnl, v)
            end
        else
            pnl:Remove()
            error("nothing to create #2: " .. tostring(k))
        end
    end
end

function gui.Create(pnl_name, pnlOwner, data, uniqueName, presets)
    if uniqueName then
        local lastPanel = gui.t_UniquePanels[uniqueName]
        if IsValid(lastPanel) then lastPanel:Remove() end
    end

    local pnl = vgui.Create(pnl_name, pnlOwner)

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
            assert(tPreset != nil, "preset not exists")
            table.Merge(tData, tPreset)
        end
    end

    table.Merge(tData, data)

    gui.ApplyParams(pnl, tData)
end

function gui.CreatePreset(preset_name, preset_base, data)
    local tPreset = {}

    if preset_base then
        local tPresetBase = gui.t_Presets[preset_base]
        assert(tPresetBase != nil, "preset_base not exists")
        table.Merge(tPreset, tPresetBase)
    end

    table.Merge(tPreset, data)
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
