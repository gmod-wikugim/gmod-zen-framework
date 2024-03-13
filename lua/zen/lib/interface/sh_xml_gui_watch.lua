module("zen", package.seeall)

zen.t_WatchGuiFiles = zen.t_WatchGuiFiles or {}
local function WatchGUIFile(path)
    assert(file.Exists(path, "GAME"), "GUI not exists: ".. path)
    if zen.t_WatchGuiFiles[path] then return end

    zen.t_WatchGuiFiles[path] = file.Time(path, "GAME")
end

local function OnGUIUpdated(path)
    local gui_name = string.GetFileFromFilename(path)

    print("WatchGUIFile: ", gui_name, " was updated")
    zen.IncludeGUI(gui_name)
end

local function WatchGUITick()
    for path, last_time in pairs(zen.t_WatchGuiFiles) do
        if !file.Exists(path, "GAME") then
            zen.t_WatchGuiFiles[path] = nil
            print("WatchGUIFile: ", path, " was deleted")
            continue
        end

        local now_time = file.Time(path, "GAME")
        if now_time == last_time then continue end
        zen.t_WatchGuiFiles[path] = now_time

        OnGUIUpdated(path)
    end
end
timer.Remove("zen:WatchGUI:AutoUpdate")
timer.Create("zen:WatchGUI:AutoUpdate", 0.5, 0, WatchGUITick)


function zen.IncludeGUI(gui_name)
    assert(isstring(gui_name), "GUI name is not string")
    gui_name = gui_name:gsub(".xml", "")
    local gui_path = "data_static/zen_gui/".. gui_name.. ".xml"
    assert(file.Exists(gui_path, "GAME"), "GUI not exists: ".. gui_path)

    local file_data = file.Read(gui_path, "GAME")

    if SERVER then resource.AddSingleFile(gui_path) end

    WatchGUIFile(gui_path)

    local data = zen.ParseXML(file_data)

    if _CFG.bZen_Developer then
        print("ParseResult: ", gui_name)
        if istable(data) then
            PrintTable(data)
        end
    end
end
