module("zen", package.seeall)

local SHEET = {}
SHEET.id = "entity"
SHEET.Name = "Entity"
SHEET.Icon = "icon16/bricks.png"
SHEET.renderID = 1

function SHEET:Init()
    self.tTreeNode_Panels = {}
    self.tSearchItems = {}
    self.tSearchItems_UniqueChecker = {}
end

function SHEET:AddSearchItem(SearchSource, ITEM)
    if self.tSearchItems_UniqueChecker[SearchSource] then return end
    self.tSearchItems_UniqueChecker[SearchSource] = true

    table.insert(self.tSearchItems, {
        SearchSource = SearchSource,
        ITEM = ITEM,
    })
end

function SHEET:SearchFunction(sSearchString)
    local hook_search_id = "zen.map_edit.SpawnMenu.Sheet." .. self.id

    local pnlNode, pnlScrollList, pnlLayoutSearch = self:GetNodePanels("Search")

    -- AddNodeItem

    pnlLayoutSearch:Clear()
    pnlNode:DoClick()

    if sSearchString == "" or sSearchString == nil then
        timer.Remove(hook_search_id)
        return
    end

    local searchTerm = string.lower(sSearchString)
    local search = string.find

    local step = 1000
    local last = 1
    local max = #self.tSearchItems
    timer.Remove(hook_search_id)
    timer.Create(hook_search_id, 0.1, 0, function()
        local next_end = math.min(last + step, max)
        for k = last, next_end do
            local searchData = self.tSearchItems[k]
            local SearchSource = searchData.SearchSource
            local ITEM = searchData.ITEM
            if search(SearchSource, searchTerm, 1, true) then
                self:AddNodeItem("Search", ITEM, true)
                pnlScrollList:InvalidateLayout(true)
                pnlLayoutSearch:InvalidateLayout(true)
            end
        end
        last = last + step
        if last >= max then
            timer.Remove(hook_search_id)
            return
        end
    end)
end

function SHEET:CreateTreeSearch(pnlParent)
    local LastSearchTerm
    self.pnlTreeSearch = gui.CreateStyled("input_text", pnlParent, {"dock_top", tall = 20})
    self.pnlTreeSearch:Setup(
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

            if self.SearchFunction then
                self:SearchFunction(val)
            end

            LastSearchTerm = val
            return true
        end
    )
end

function SHEET:CreateTree()
    self.pnlLeft = gui.Create("EditablePanel", self.pnlSheetMain, {"dock_left", wide = 200})
    self.pnlTree = gui.Create("DTree", self.pnlLeft, {"dock_fill", "-paint"})

    self:CreateTreeSearch(self.pnlLeft)
end

function SHEET:CreateContent()
    self.pnlContent = gui.Create("EditablePanel", self.pnlSheetMain, {"dock_fill"})
end

function SHEET:GetNodePanels(Name)
    assert(self.tTreeNode_Panels[Name], "No node panels")

    return unpack(self.tTreeNode_Panels[Name])
end

function SHEET:SetActiveNode(Name)
    local activeNode = self:GetActiveNode()
    if activeNode then -- Hide the active node
        local pnlNode, pnlScrollList, pnlLayout = self:GetNodePanels(activeNode)
        pnlScrollList:SetVisible(false)
    end

    do -- Show the new node
        local pnlNode, pnlScrollList, pnlLayout = self:GetNodePanels(Name)
        pnlScrollList:SetVisible(true)
    end

    self.pnlActiveNode = Name
end

function SHEET:GetActiveNode()
    return self.pnlActiveNode
end

function SHEET:CreateTreeNode(pnlParent, Name, Icon)
    assert(IsValid(self.pnlTree), "No tree panel")
    assert(IsValid(self.pnlContent), "No content panel")

    -- assert(self.tTreeNode_Panels[Name], "Node already exists")

    pnlParent = pnlParent or self.pnlTree
    local pnlNode = pnlParent:AddNode(Name, Icon)
    pnlNode:SetExpanded(true)

    local pnlScrollList = gui.Create("DScrollPanel", self.pnlContent, {"dock_fill", visible = false})

    local pnlLayout = gui.Create("DIconLayout", pnlScrollList, {"dock_fill"})
    pnlLayout:SetSpaceY( 5 )
    pnlLayout:SetSpaceX( 5 )
    pnlLayout:InvalidateParent(true)

    pnlNode.DoClick = function()
        self:SetActiveNode(Name)
    end

    self.tTreeNode_Panels[Name] = {pnlNode, pnlScrollList, pnlLayout}
    return pnlNode, pnlScrollList, pnlLayout
end

function SHEET:AddNodeItem(nodeName, ITEM, bNoSearch)
    assert(isstring(nodeName), "nodeName is not a string")
    assert(istable(ITEM), "ITEM is not a table")
    assert(isstring(ITEM.SearchSource), "ITEM.SearchSource is not a string")

    local pnlNode, pnlScrollList, pnlLayout = self:GetNodePanels(nodeName)

    local pnlItem = self:CreateItemPanel(pnlLayout, ITEM)

    if !bNoSearch then
        self:AddSearchItem(ITEM.SearchSource, ITEM)
    end
end

function SHEET:Create(pnlSheetMain)
    self.pnlSheetMain = pnlSheetMain

    self:CreateTree()
    self:CreateContent()

    self:CreateTreeNode(self.pnlTree, "Search", "icon16/bin.png")

    self:LoadContentItems()
end

function SHEET:ReadList()
    local done_spawnlist = {}

    local scripted_list = scripted_ents.GetList()

    for k, v in pairs(scripted_list) do
        local ENT = v.t

        local Category = ENT.Category or "Others"

        if !done_spawnlist[Category] then
            done_spawnlist[Category] = {}
        end

        local tCategoryItems = done_spawnlist[Category]

        local ITEM = {}

        ITEM.ENT = ENT
        ITEM.Class = ENT.ClassNameOverride or ENT.ClassName
        ITEM.Name = ENT.PrintName or ITEM.Class
        ITEM.Category = Category
        ITEM.AdminOnly = ENT.AdminOnly
        ITEM.Spawnable = ENT.Spawnable
        ITEM.Icon      = ENT.IconOverride

        ITEM.SearchSource = (ITEM.Name or "").. (ITEM.Class or "")


        tCategoryItems[ITEM.Class] = ITEM
    end

    local list_SpawnableEntities = list and list.Get("SpawnableEntities")
    if list_SpawnableEntities then
        for Class, data in pairs(list_SpawnableEntities) do

            local Category = data.Category or "Others"

            if !done_spawnlist[Category] then
                done_spawnlist[Category] = {}
            end

            local tCategoryItems = done_spawnlist[Category]

            local ITEM = {}
            ITEM.Class = Class or data.Class or data.ClassName
            ITEM.Name = data.PrintName or data.ClassNameOverride or data.Class or data.Name or data.SpawnName
            ITEM.Category = Category
            ITEM.Spawnable = true
            ITEM.SearchSource = (ITEM.Name or "").. (ITEM.Class or "")


            tCategoryItems[ITEM.Class] = ITEM
        end
    end

    return done_spawnlist
end

function SHEET:OnItemDoClick(ITEM)
    local class = ITEM.Class
    local pos = map_edit.GetViewHitPosNoCursor()
    local ang = Angle(0,0,0)

    nt.Send("map_edit.SpawnEntity", {"string", "vector", "angle"}, {class, pos, ang})
end

function SHEET:CreateItemPanel(pnlLayout, ITEM)
    assert(istable(ITEM), "ITEM is not a table")
    assert(isstring(ITEM.Class), "ITEM.Class is not a string")

    local ENT = ITEM.ENT

    local ENT_Material

    if !ENT_Material and ENT and ENT.IconOverride then
        local mat = Material(ENT.IconOverride)
        if mat and !mat:IsError() then
            ENT_Material = mat
        end
    end

    if !ENT_Material and ITEM.Class then
        local mat_path = "entities/" .. ITEM.Class .. ".png"
        local mat = Material(mat_path)
        if mat and !mat:IsError() then
            ENT_Material = mat
        end
    end

    local WorldModel = ENT and ENT.Model

    local pnlItem = pnlLayout:Add("EditablePanel")
    pnlItem:SetSize(150, 150)

    local pnlItem_Info = pnlItem:Add("EditablePanel")
    pnlItem_Info:SetMouseInputEnabled(false)
    pnlItem_Info:SetSize(150, 150)
    pnlItem_Info:Center()

    local pnlItem_Clickable = pnlItem:Add("DLabel")
    pnlItem_Clickable:SetText("")
    pnlItem_Clickable:SetMouseInputEnabled(true)
    pnlItem_Clickable:SetSize(150, 150)
    pnlItem_Clickable:SetCursor("hand")
    pnlItem_Clickable:Center()
    pnlItem_Clickable.DoClick = function()
        self:OnItemDoClick(ITEM)
    end

    local pnlItem_Icon

    if ENT_Material then
        pnlItem_Icon = pnlItem_Info:Add("DImage")
        pnlItem_Icon:SetSize(150, 150)
        pnlItem_Icon:Center()
        pnlItem_Icon:SetMaterial(ENT_Material)
    elseif WorldModel then
        pnlItem_Icon = pnlItem_Info:Add("SpawnIcon")
        pnlItem_Icon:SetSize(150, 150)
        pnlItem_Icon:Center()
        pnlItem_Icon:SetModel(WorldModel)
    end

    local pnlText = gui.Create("DLabel", pnlItem_Info, {"dock_bottom"})
    pnlText:SetText(ITEM.Name or "Unknown #12")
    pnlText:SetContentAlignment(5)
    pnlText:SetTextColor(COLOR.BLACK)

end

function SHEET:LoadContentItems()
    local nodeSpawn, listSpawn, layoutSpawn = self:CreateTreeNode(self.pnlTree, "Spawnlist", "icon16/brick.png")


    -- local ParentIDs = {}
    for Category, Items in pairs(self:ReadList()) do

        self:CreateTreeNode(self.pnlTree, Category)

        for Class, ITEM in pairs(Items) do
            self:AddNodeItem(Category, ITEM)
        end
    end

end

map_edit.RegisterSheet(SHEET)