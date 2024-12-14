module("zen", package.seeall)

---@class zen.panel.zspawn_menu: zen.panel.zpanelbase
local PANEL = {}

function PANEL:Init()

    self:zen_MakePopup()

    self.ContentPanel = gui.Create("zpanelbase", self, {dock = FILL})

    do -- LeftMenu
        self.LeftMenu = gui.Create("zpanelbase", self.ContentPanel, {dock = FILL})
        function self.LeftMenu:PaintOnce(w, h)
            draw.BoxRounded(8, 0, 0, w, h, "161616ff")
        end
        self.LeftMenu:DockMargin(5,5,5,5)

        self:LoadLeftMenu()
    end

    self.RightMenu = gui.Create("zpanelbase", self.ContentPanel)
    function self.RightMenu:PaintOnce(w, h)
        draw.BoxRounded(8, 0, 0, w, h, "DA1F9B80")
    end
    -- self.RightMenu:DockPadding(5,5,5,5)
    self.RightMenu:SDock(RIGHT, 300)

end


function PANEL:LoadLeftMenu()
    self.LeftMenuHeader = gui.Create("zpanelbase", self.LeftMenu)
    function self.LeftMenuHeader:PaintOnce(w, h)
        draw.BoxRounded(8, 0, 0, w, h, "202020ff")
    end
    self.LeftMenuHeader:SDock(TOP, 25)


    self.LeftMenuContent = gui.Create("zpanelbase", self.LeftMenu, {dock = FILL})

    local function AddHeaderButton(headerName, doClick)
        local pnlButton = gui.Create("zlabel", self.LeftMenuHeader)
        pnlButton:SDock(LEFT, 120)
        pnlButton:SetText(headerName)
        pnlButton:SetFont("14:DejaVu Sans")
        pnlButton:SetCursor("hand")
        pnlButton.DoClick = doClick
        -- pnlButton:SizeToContentsX(true)
        -- pnlButton:SetAutoReSizeToChildrenWidth(true)
        return pnlButton
    end

    self.t_Workspaces = {}

    local function AddWorkspace(workspaceName)
        local WORKSPACE = {}
        self.t_Workspaces[workspaceName] = WORKSPACE

        WORKSPACE.headerButton = AddHeaderButton(workspaceName, function()

            if self.ACTIVE_WORKSPACE then
                self.ACTIVE_WORKSPACE.pnlContent:SetVisible(false)
            end

            self.ACTIVE_WORKSPACE  = WORKSPACE

            self.ACTIVE_WORKSPACE.pnlContent:SetVisible(true)
        end)

        WORKSPACE.pnlContent = gui.Create("zpanelbase", self.LeftMenuContent, {dock = FILL, visible = false})

        return WORKSPACE
    end


    local WORKSPACE_MDL = AddWorkspace("MDLs")
    self:LoadWorkspaceMDL(WORKSPACE_MDL)

    local WORKSPACE_ENTITY = AddWorkspace("Entities")
    self:LoadWorkspaceEntity(WORKSPACE_ENTITY)

    local WORKSPACE_WEAPON = AddWorkspace("Weapons")
    self:LoadWorkspaceWeapon(WORKSPACE_WEAPON)

    local WORKSPACE_NPC = AddWorkspace("NPC")
    self:LoadWorkspaceNPC(WORKSPACE_NPC)

    local WORKSPACE_VEHICLE = AddWorkspace("Vehicle")
    self:LoadWorkspaceVehicle(WORKSPACE_VEHICLE)
end

function PANEL:PostRemove()
    util.StopIndexFolder("models")
end

function PANEL:LoadWorkspaceMDL(WORKSPACE)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)


        WORKSPACE.itemsContent = {}

        util.IndexFolderFiles("models", function()

        end, function(file_name, file_path, file_folder)

            if file_folder then
                WORKSPACE.itemsContent[file_folder] = WORKSPACE.itemsContent[file_folder] or {}

                table.insert(WORKSPACE.itemsContent[file_folder], file_path)
            end
        end, function(folder_name, folder_path, owner_folder_path)
            if owner_folder_path == "" then owner_folder_path = nil end

            if folder_path == "" then folder_path = folder_name end

            local pnlNode = WORKSPACE.pnlTree:AddNode(folder_path, owner_folder_path)
            pnlNode:SetText(folder_name)
        end)


        -- WORKSPACE.pnlTree:AddNode(1)
        -- WORKSPACE.pnlTree:AddNode(2, 1)
        -- WORKSPACE.pnlTree:AddNode(3)
        WORKSPACE.pnlTree:Expand()
    end


    do -- Content
        WORKSPACE.pnlTreeContent = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlTreeContent:SDock(FILL)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlTreeContent:Clear()
            if item_list then
                print("Item amount: ", #item_list)


                WORKSPACE.pnlTreeContent.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlTreeContent)
                WORKSPACE.pnlTreeContent.pnlLayout:SDock(FILL)
                WORKSPACE.pnlTreeContent.pnlLayout:SetLayoutScheme(true, 25, 2, 2, true)

                for _, file_path in pairs(item_list) do
                    local ext = string.GetExtensionFromFilename(file_path)

                    if ext != "mdl" then continue end

                    local pnlItem = gui.Create("zbutton", WORKSPACE.pnlTreeContent.pnlLayout)

                    function pnlItem:PaintOnce(w, h)
                        draw.Box(0,0,w,h,"191919")

                        if self:IsHovered() then
                            draw.BoxOutlined(1, 0, 0, w, h, "666666")
                        else
                            draw.BoxOutlined(1, 0, 0, w, h, "444444")
                        end
                    end

                    function pnlItem:DoClick()
                        RunConsoleCommand("gm_spawn", file_path)
                    end

                    pnlItem:SetSize(150, 150)

                    local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                    pnlSpawnIcon:SetModel(Model(file_path))
                    pnlSpawnIcon:SetMouseInputEnabled(false)
                end

            end
        end
    end
end

function PANEL:LoadWorkspaceEntity(WORKSPACE)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)

        WORKSPACE.itemsContent = {}

        for k, v in pairs(scripted_ents.GetList()) do

            ---@type ENT
            local ENT = v.t

            ---@type boolean
            local isBaseType = v.isBaseType

            ---@type string
            local Base = v.Base

            ---@type string
            local type = v.type

            local category = ENT.Category or "Other"

            if !WORKSPACE.pnlTree:IsNodeExists(category) then
                WORKSPACE.pnlTree:AddNode(category)
            end

            WORKSPACE.itemsContent[category] = WORKSPACE.itemsContent[category] or {}

            table.insert(WORKSPACE.itemsContent[category], ENT)
        end


        WORKSPACE.pnlTree:Expand()
    end


    do -- Content
        WORKSPACE.pnlTreeContent = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlTreeContent:SDock(FILL)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlTreeContent:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                WORKSPACE.pnlTreeContent.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlTreeContent)
                WORKSPACE.pnlTreeContent.pnlLayout:SDock(FILL)
                WORKSPACE.pnlTreeContent.pnlLayout:SetLayoutScheme(true, 25, 2, 2, true)

                for _, ITEM in pairs(item_list) do
                    local pnlItem = gui.Create("zbutton", WORKSPACE.pnlTreeContent.pnlLayout)

                    function pnlItem:PaintOnce(w, h)
                        draw.Box(0,0,w,h,"191919")

                        if self:IsHovered() then
                            draw.BoxOutlined(1, 0, 0, w, h, "666666")
                        else
                            draw.BoxOutlined(1, 0, 0, w, h, "444444")
                        end
                    end

                    function pnlItem:DoClick()
                        RunConsoleCommand("gm_spawnsent", ITEM.ClassName)
                    end

                    pnlItem:SetSize(150, 150)

                    local path = string.format("materials/entities/%s.png", ITEM.ClassName)

                    if file.Exists(path, "GAME") then
                        local mat_icon = Material(path)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif ITEM.Icon or ITEM.IconOverride then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.IconOverride or ITEM.Icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif ITEM.WorldModel or ITEM.Model then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.WorldModel or ITEM.Model))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    end
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceWeapon(WORKSPACE)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)

        WORKSPACE.itemsContent = {}

        for k, v in pairs(weapons.GetList()) do
            local category = v.Category or "Other"

            if !WORKSPACE.pnlTree:IsNodeExists(category) then
                WORKSPACE.pnlTree:AddNode(category)
            end

            WORKSPACE.itemsContent[category] = WORKSPACE.itemsContent[category] or {}

            table.insert(WORKSPACE.itemsContent[category], v)
        end


        WORKSPACE.pnlTree:Expand()
    end


    do -- Content
        WORKSPACE.pnlTreeContent = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlTreeContent:SDock(FILL)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlTreeContent:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                WORKSPACE.pnlTreeContent.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlTreeContent)
                WORKSPACE.pnlTreeContent.pnlLayout:SDock(FILL)
                WORKSPACE.pnlTreeContent.pnlLayout:SetLayoutScheme(true, 25, 2, 2, true)

                for _, ITEM in pairs(item_list) do
                    local pnlItem = gui.Create("zbutton", WORKSPACE.pnlTreeContent.pnlLayout)

                    function pnlItem:PaintOnce(w, h)
                        draw.Box(0,0,w,h,"191919")

                        if self:IsHovered() then
                            draw.BoxOutlined(1, 0, 0, w, h, "666666")
                        else
                            draw.BoxOutlined(1, 0, 0, w, h, "444444")
                        end
                    end

                    function pnlItem:DoClick()
                        RunConsoleCommand("give", ITEM.ClassName)
                    end

                    pnlItem:SetSize(150, 150)

                    local path = string.format("materials/entities/%s.png", ITEM.ClassName)

                    if file.Exists(path, "GAME") then
                        local mat_icon = Material(path)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif ITEM.Icon or ITEM.IconOverride then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.IconOverride or ITEM.Icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif ITEM.WorldModel or ITEM.Model then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.WorldModel or ITEM.Model))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    end
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceNPC(WORKSPACE)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)

        WORKSPACE.itemsContent = {}

        for k, v in pairs(list.Get( "NPC" )) do
            local category = v.Category or "Other"

            if !WORKSPACE.pnlTree:IsNodeExists(category) then
                WORKSPACE.pnlTree:AddNode(category)
            end

            WORKSPACE.itemsContent[category] = WORKSPACE.itemsContent[category] or {}

            v._KEY = k

            table.insert(WORKSPACE.itemsContent[category], v)
        end


        WORKSPACE.pnlTree:Expand()
    end


    do -- Content
        WORKSPACE.pnlTreeContent = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlTreeContent:SDock(FILL)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlTreeContent:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                WORKSPACE.pnlTreeContent.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlTreeContent)
                WORKSPACE.pnlTreeContent.pnlLayout:SDock(FILL)
                WORKSPACE.pnlTreeContent.pnlLayout:SetLayoutScheme(true, 25, 2, 2, true)

                for _, ITEM in pairs(item_list) do
                    local pnlItem = gui.Create("zbutton", WORKSPACE.pnlTreeContent.pnlLayout)

                    function pnlItem:PaintOnce(w, h)
                        draw.Box(0,0,w,h,"191919")

                        if self:IsHovered() then
                            draw.BoxOutlined(1, 0, 0, w, h, "666666")
                        else
                            draw.BoxOutlined(1, 0, 0, w, h, "444444")
                        end
                    end

                    function pnlItem:DoClick()
                        RunConsoleCommand("gmod_spawnnpc", ITEM._KEY)
                    end

                    pnlItem:SetSize(150, 150)

                    local path = string.format("materials/entities/%s.png", ITEM.ClassName)
                    local path2 = string.format("materials/entities/%s.png", ITEM._KEY)

                    if file.Exists(path, "GAME") then
                        local mat_icon = Material(path)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif file.Exists(path2, "GAME") then
                        local mat_icon = Material(path2)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif (ITEM.IconOverride and ITEM.IconOverride != "") then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.IconOverride)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif (ITEM.Icon and ITEM.Icon != "") then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.Icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif type(ITEM.WorldModel) == "string" and file.Exists(ITEM.WorldModel, "GAME") then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.WorldModel))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif type(ITEM.Model) == "string" and file.Exists(ITEM.Model, "GAME") then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.Model))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    end
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceVehicle(WORKSPACE)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)

        WORKSPACE.itemsContent = {}

        for k, v in pairs(list.Get( "Vehicles" )) do
            local category = v.Category or "Other"

            if !WORKSPACE.pnlTree:IsNodeExists(category) then
                WORKSPACE.pnlTree:AddNode(category)
            end

            WORKSPACE.itemsContent[category] = WORKSPACE.itemsContent[category] or {}

            v._KEY = k

            table.insert(WORKSPACE.itemsContent[category], v)
        end


        WORKSPACE.pnlTree:Expand()
    end


    do -- Content
        WORKSPACE.pnlTreeContent = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlTreeContent:SDock(FILL)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlTreeContent:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                WORKSPACE.pnlTreeContent.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlTreeContent)
                WORKSPACE.pnlTreeContent.pnlLayout:SDock(FILL)
                WORKSPACE.pnlTreeContent.pnlLayout:SetLayoutScheme(true, 25, 2, 2, true)

                for _, ITEM in pairs(item_list) do
                    local pnlItem = gui.Create("zbutton", WORKSPACE.pnlTreeContent.pnlLayout)

                    function pnlItem:PaintOnce(w, h)
                        draw.Box(0,0,w,h,"191919")

                        if self:IsHovered() then
                            draw.BoxOutlined(1, 0, 0, w, h, "666666")
                        else
                            draw.BoxOutlined(1, 0, 0, w, h, "444444")
                        end
                    end

                    function pnlItem:DoClick()
                        RunConsoleCommand("gm_spawnvehicle", ITEM._KEY)
                    end

                    pnlItem:SetSize(150, 150)

                    local path = string.format("materials/entities/%s.png", ITEM.Name)
                    local path2 = string.format("materials/entities/%s.png", ITEM._KEY)

                    if file.Exists(path, "GAME") then
                        local mat_icon = Material(path)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif file.Exists(path2, "GAME") then
                        local mat_icon = Material(path2)
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetMaterial(mat_icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif (ITEM.IconOverride and ITEM.IconOverride != "") then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.IconOverride)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif (ITEM.Icon and ITEM.Icon != "") then
                        local pnlSpawnIcon = gui.Create("DImage", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetIcon(ITEM.Icon)
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif type(ITEM.WorldModel) == "string" and file.Exists(ITEM.WorldModel, "GAME") then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.WorldModel))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    elseif type(ITEM.Model) == "string" and file.Exists(ITEM.Model, "GAME") then
                        local pnlSpawnIcon = gui.Create("SpawnIcon", pnlItem, {dock_fill = true})
                        pnlSpawnIcon:SetModel(Model(ITEM.Model))
                        pnlSpawnIcon:SetMouseInputEnabled(false)
                    end
                end
            end
        end
    end
end

function PANEL:PaintOnce(w, h)
    draw.BoxRounded(20, 0, 0, w, h, "1010109f")
end

vgui.Register("zspawn_menu", PANEL, "zpanelbase")

/*
if IsValid(zen.zspawn_menu ) then
    zen.zspawn_menu:Remove()
end

zen.zspawn_menu = gui.Create("zspawn_menu")
zen.zspawn_menu:SetSize(1800, 1000)
zen.zspawn_menu:Center()

print(10)
*/