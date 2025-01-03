module("zen")

---@class zen.panel.zspawn_menu: zen.panel.zpanelbase
local PANEL = {}

local file_Exists = file.Exists
local file_Size = file.Size

---Input entity name and receive path with default path exists
---@vararg string
local function GetValidImagePath(full_paths, single_words)

    local patches = {}

    local try_path = function(format, path)
        local path = string.format(format, path)
        table.insert(patches, path)
    end

    for _, v in pairs(full_paths) do
        if v == nil then continue end

        try_path("%s", v)
        try_path("%s.png", v)
        try_path("%s.vmt", v)
    end

    for _, v in pairs(single_words) do
        if v == nil then continue end

        try_path("materials/vgui/entities/%s.vmt", v)
        try_path("materials/vgui/entities/%s.png", v)

        try_path("materials/entities/%s.png", v)
        try_path("materials/entities/%s.vmt", v)
    end


    for _, path in ipairs(patches) do
        if file_Exists(path, "GAME") and file_Size(path, "GAME") > 0 then
            path = path:gsub("materials/", "")
            return path
        end
    end
end

---@return Panel?
local function CreateItemSpawnIcon(ITEM)
    local path = GetValidImagePath({ITEM.IconOverride},{ITEM.ClassName, ITEM._KEY, ITEM.spawnname, ITEM.Spawnname, ITEM.Name, ITEM.name})

    local function SpawnPanel(classname, onSpawned)
        local pnlImage = vgui.Create(classname)
        if !IsValid(pnlImage) then return end

        local pnlFather = pnlImage:GetParent()


        timer.Simple(1, function()
            if !IsValid(pnlImage) then return end

            local pnlParent = pnlImage:GetParent()

            if pnlParent == nil or pnlParent == pnlFather or pnlParent == vgui.GetWorldPanel() or pnlParent == GetHUDPanel() then
                pnlImage:Remove()
                print("Panel was autoremove ", tostring(pnlImage), " don't parented!")
            end
        end)

        xpcall(onSpawned, function(...)
            pnlImage:Remove()
            error(...)
        end, pnlImage)

        return pnlImage
    end

    if path then
        local pnlImage = SpawnPanel("DImage", function(self)
            self:SetImage(path)
            self:SetMouseInputEnabled(false)
        end)

        return pnlImage
    end

    local SelModel
    if type(ITEM.WorldModel) == "string" and file.Exists(ITEM.WorldModel, "GAME") and !IsUselessModel(Model(ITEM.WorldModel)) then
        SelModel = ITEM.WorldModel
    elseif type(ITEM.Model) == "string" and file.Exists(ITEM.Model, "GAME") and !IsUselessModel(Model(ITEM.Model)) then
        SelModel = ITEM.Model
    end


    if SelModel then
        local pnlImage = SpawnPanel("SpawnIcon", function(self)
            self:SetModel(SelModel)
            self:SetMouseInputEnabled(false)
        end)

        return pnlImage
    end

end



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

function PANEL:CreateWorkspaceTree(WORKSPACE, onCreated)
    do -- Tree
        WORKSPACE.pnlTree = gui.Create("ztree", WORKSPACE.pnlContent)
        WORKSPACE.pnlTree:SDock(LEFT, 200)
        WORKSPACE.pnlTree:Expand()

        if onCreated then
            onCreated(WORKSPACE, WORKSPACE.pnlTree)
        end
    end
end

function PANEL:CreateItemPanel(WORKSPACE, ITEM)
    WORKSPACE.mt_Items = WORKSPACE.mt_Items or {}

    local pnlItem = vgui.Create("zspawn_item", WORKSPACE.pnlLayout)
    WORKSPACE.mt_Items[pnlItem] = ITEM

    pnlItem:SetItem(ITEM)
end

function PANEL:CreateWorkspaceLayout(WORKSPACE, onCreated)
    do -- Content
        assert(IsValid(WORKSPACE.pnlTree), "WORKSPACE.pnlTree don't valid")

        WORKSPACE.pnlLayout = gui.Create("zpanelbase", WORKSPACE.pnlContent)
        WORKSPACE.pnlLayout:SDock(FILL)
        WORKSPACE.pnlLayout:SetLayoutScheme(true, 10, 2, 2, true)

        if onCreated then
            onCreated(WORKSPACE, WORKSPACE.pnlLayout)
        end
    end
end

function PANEL:LoadWorkspaceMDL(WORKSPACE)
    local this = self
    self:CreateWorkspaceTree(WORKSPACE)

    do -- Tree
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
        self:CreateWorkspaceLayout(WORKSPACE)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlLayout:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                for _, file_path in pairs(item_list) do
                    local ext = string.GetExtensionFromFilename(file_path)

                    if ext != "mdl" then continue end

                    this:CreateItemPanel(WORKSPACE, {
                        TYPE = "SANDBOX_MODEL",
                        VALUE = file_path
                    })
                end

            end
        end
    end
end

function PANEL:LoadWorkspaceEntity(WORKSPACE)
    local this = self

    do -- Tree
        self:CreateWorkspaceTree(WORKSPACE)

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
        self:CreateWorkspaceLayout(WORKSPACE)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlLayout:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                for _, ITEM in pairs(item_list) do

                    this:CreateItemPanel(WORKSPACE, {
                        TYPE = "SANDBOX_SENT",
                        ITEM = ITEM,
                        VALUE = ITEM.ClassName
                    })
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceWeapon(WORKSPACE)
    local this = self

    do -- Tree
        self:CreateWorkspaceTree(WORKSPACE)

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
        self:CreateWorkspaceLayout(WORKSPACE)

        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlLayout:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                for _, ITEM in pairs(item_list) do
                    this:CreateItemPanel(WORKSPACE, {
                        TYPE = "SANDBOX_WEAPON",
                        ITEM = ITEM,
                        VALUE = ITEM.ClassName
                    })
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceNPC(WORKSPACE)
    local this = self

    do -- Tree
        self:CreateWorkspaceTree(WORKSPACE)

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
        self:CreateWorkspaceLayout(WORKSPACE)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlLayout:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                for _, ITEM in pairs(item_list) do
                    this:CreateItemPanel(WORKSPACE, {
                        TYPE = "SANDBOX_NPC",
                        ITEM = ITEM,
                        VALUE = ITEM._KEY
                    })
                end
            end
        end
    end
end

function PANEL:LoadWorkspaceVehicle(WORKSPACE)
    local this = self

    do -- Tree
        self:CreateWorkspaceTree(WORKSPACE)

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
        self:CreateWorkspaceLayout(WORKSPACE)



        function WORKSPACE.pnlTree:OnNodePress(node_id)
            print("OnNodePress ", node_id)

            local item_list = WORKSPACE.itemsContent[node_id]

            WORKSPACE.pnlLayout:Clear()
            if item_list then
                print("Item amount: ", #item_list)

                for _, ITEM in pairs(item_list) do
                    this:CreateItemPanel(WORKSPACE, {
                        TYPE = "SANDBOX_VEHICLE",
                        ITEM = ITEM,
                        VALUE = ITEM._KEY
                    })
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