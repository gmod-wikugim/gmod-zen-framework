module("zen", package.seeall)

local SHEET = {}
SHEET.id = "props"
SHEET.Name = "Props"
SHEET.Icon = "icon16/brick.png"
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

function SHEET:OnItemDoClick(ITEM)
    local model = ITEM.model
    local pos = map_edit.GetViewHitPosNoCursor()
    local ang = Angle(0,0,0)

    nt.Send("map_edit.SpawnProp", {"string", "vector", "angle"}, {model, pos, ang})
end

function SHEET:CreateItemPanel(pnlLayout, ITEM)
    assert(istable(ITEM), "ITEM is not a table")
    assert(isstring(ITEM.model), "ITEM.model is not a string")

    local model = ITEM.model

    local new_spawnicon = pnlLayout:Add("SpawnIcon")
    new_spawnicon:SetSize(50, 50)
    new_spawnicon:SetModel(model)
    new_spawnicon.DoClick = function()
        self:OnItemDoClick(ITEM)
    end
end

function SHEET:LoadContentItems()
    local nodeSpawn, listSpawn, layoutSpawn = self:CreateTreeNode(self.pnlTree, "Spawnlist", "icon16/brick.png")


    local ParentIDs = {}
    for name, data in pairs(self:ReadList()) do
        local icon = data.icon or "icon16/page.png"
        local contents = data.contents
        local parentID = tonumber(data.parentid)
        local ID = tonumber(data.id)

        local parent = nodeSpawn

        if parentID and parentID > 0 and ParentIDs[parentID] then
            parent = ParentIDs[parentID]
        end

        local newNode, newList, newLayout = self:CreateTreeNode(parent, name, icon)

        if ID then
            newNode:SetZPos(ID)
        end

        if parentID and ID and parentID == 0 then
            ParentIDs[ID] = newNode
        end


        if istable(contents) and next(contents) then
            for id, mdl_data in pairs(contents) do
                if !mdl_data.model then continue end

                local ITEM = {}
                ITEM.model = mdl_data.model
                ITEM.SearchSource = mdl_data.model

                self:AddNodeItem(name, ITEM)
                -- self:CreateItemPanel(newLayout, ITEM)
            end
        end
    end

end

map_edit.RegisterSheet(SHEET)