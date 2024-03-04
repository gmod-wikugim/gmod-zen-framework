module("zen", package.seeall)

local ui, gui, map_edit = zen.Init("ui", "gui", "map_edit")

function map_edit.Request_SpawnProp(model)
    print("Request_SpawnProp: " .. model)
    local pos = map_edit.GetViewHitPosNoCursor()
    local angle = Angle(0,0,0)
    nt.Send("map_edit.SpawnProp", {"string", "vector", "angle"}, {model, pos, angle})
end

function map_edit.ReadSpawnList()
    local files = file.Find("settings/spawnlist/*.txt", "GAME")

    local done_spawnlist = {}

    for k, fl_name in pairs(files) do
        local full_path = "settings/spawnlist/".. fl_name
        local data = file.Read(full_path, "GAME")
        local spawnlist = util.KeyValuesToTable(data)

        local name = spawnlist.name or fl_name

        if done_spawnlist[name] then
            name = fl_name
        end

        done_spawnlist[name] = spawnlist
    end

    return done_spawnlist
end

function map_edit.LoadProps(sheet_props)
    local left = gui.Create("DPanel", sheet_props, {"dock_left", wide = 200})
    local right = gui.Create("DPanel", sheet_props, {"dock_fill"})


    local SearchFunction, LastSearchTerm
    local input = gui.CreateStyled("input_text", left, nil, {"dock_top", tall = 20})
    input:Setup(
        {
            type = TYPE.STRING,
            optional = true,
            default = '',
            NoHelp = true,
        },
        function(val)
            if isstring(val) and val == LastSearchTerm then
                return
            end

            if SearchFunction then
                SearchFunction(val)
            end

            LastSearchTerm = val
            return true
        end
    )

    local tree = gui.Create("DTree", left, {"dock_fill"})

    local lastActiveSheet
    local function CreateNode(parent, name, icon)
        local new_node = parent:AddNode(name, icon)
        new_node:SetExpanded(true)
        local new_list = gui.Create("DScrollPanel", right, {"dock_fill", visible = false})

        new_node.DoClick = function()
            if IsValid(lastActiveSheet) then
                lastActiveSheet:SetVisible(false)
            end
            new_list:SetVisible(true)
            lastActiveSheet = new_list
        end

        return new_node, new_list
    end

    local function CreateNodeLayout(parent, name, icon)
        local new_node, new_list = CreateNode(parent, name, icon)

        local new_layout = gui.Create("DIconLayout", new_list, {"dock_fill"})
        new_layout:SetSpaceY( 5 )
        new_layout:SetSpaceX( 5 )
        new_layout:InvalidateParent(true)

        return new_node, new_list, new_layout
    end

    local tSearchTable = {}
    local function AddLayoutModel(layout, model, bNoSearch)
        if !model or !isstring(model) or IsUselessModel(model) then return end

        local new_spawnicon = layout:Add("SpawnIcon")
        new_spawnicon:SetSize(50, 50)
        new_spawnicon:SetModel(model)
        new_spawnicon.DoClick = function()
            map_edit.Request_SpawnProp(model)
        end

        if !bNoSearch then
            table.insert(tSearchTable, string.lower(model))
        end
    end


    local nodeSearch, listSearch, layoutSearch = CreateNodeLayout(tree, "Search", "icon16/bin.png")

    local function SearchResult(model)
        AddLayoutModel(layoutSearch, model, true)

        listSearch:InvalidateLayout(true)
    end

    local search = string.find

    function SearchFunction(val)
        layoutSearch:Clear()
        nodeSearch:DoClick()
        if val == "" or val == nil then
            timer.Remove("zen.map_edit.SearchFunction.props")
            return
        end

        local searchTerm = string.lower(val)

        local step = 1000
        local last = 1
        local max = #tSearchTable
        timer.Remove("zen.map_edit.SearchFunction.props")
        timer.Create("zen.map_edit.SearchFunction.props", 0.1, 0, function()
            local next_end = math.min(last + step, max)
            for k = last, next_end do
                local model = tSearchTable[k]
                if search(model, searchTerm, 1, true) then
                    SearchResult(model)
                end
            end
            last = last + step
            if last >= max then
                timer.Remove("zen.map_edit.SearchFunction.props")
                return
            end
        end)
    end


    local nodeSpawn, listSpawn, layoutSpawn = CreateNodeLayout(tree, "Spawnlist", "icon16/brick.png")


    local ParentIDs = {}
    for name, data in pairs(map_edit.ReadSpawnList()) do
        local icon = data.icon or "icon16/page.png"
        local contents = data.contents
        local parentID = tonumber(data.parentid)
        local ID = tonumber(data.id)

        local parent = nodeSpawn

        if parentID and parentID > 0 and ParentIDs[parentID] then
            parent = ParentIDs[parentID]
        end

        local newNode, newList, newLayout = CreateNodeLayout(parent, name, icon)

        if ID then
            newNode:SetZPos(ID)
        end

        if parentID and ID and parentID == 0 then
            ParentIDs[ID] = newNode
        end


        if istable(contents) and next(contents) then
            for id, mdl_data in pairs(contents) do
                local type = mdl_data.type
                local model =  mdl_data.model

                AddLayoutModel(newLayout, model)
            end
        end
    end
end