module("zen", package.seeall)

---@class zen.panel.ztree_node: zen.panel.zpanelbase
local PANEL = {}

function PANEL:Init()
    self:DockMargin(8,0,0,0)
    self.pnlButton = gui.Create("zbutton", self, {})
    self.pnlButton:SetFont("14:DejaVu Sans")
    self.pnlButton:SDock(TOP, 30)

    self.pnlButton.pnlText = gui.Create("zbutton", self.pnlButton, {})
    self.pnlButton.pnlText:SDock(RIGHT, 30)
    self.pnlButton.pnlText:SetText("")
    self.pnlButton.pnlText:SetVisible(false)

    self.pnlButton.pnlText.DoClick = function(this)
        if self.bExpand then
            self:Collapse()
        else
            self:Expand()
        end

        print("OnClick")
    end

    self.pnlNodes = gui.Create("zpanelbase", self, {})
    self.pnlNodes:SetAutoReSizeToChildrenHeight(true)
    self.pnlNodes:SDock(FILL)

    self.t_Nodes = {}
end

function PANEL:SetText(text)
    self.pnlButton:SetText(text)
end

function PANEL:Collapse()
    self.bExpand = false
    self:SizeTo(-1, self.pnlButton:GetTall(), 0.3)

    if self.bExtendable then
        self.pnlButton.pnlText:SetText("+")
    end
end

function PANEL:OnNodePress(node_id)
end

function PANEL:Expand()
    self.bExpand = true
    local _, ch = self:ChildrenSize()
    self:SizeTo(-1, ch, 0.3)

    if self.bExtendable then
        self.pnlButton.pnlText:SetText("-")
    end
end

function PANEL:SetExtendable(bBool)
    self.bExtendable = bBool

    if self.bExtendable then
        if self.bExpand then
            self.pnlButton.pnlText:SetText("-")
        else
            self.pnlButton.pnlText:SetText("+")
        end
    else
        self.pnlButton.pnlText:SetText("")
    end

    self.pnlButton.pnlText:SetVisible(bBool)
end

---@return zen.panel.ztree_node
function PANEL:GetNode(node_id)
    return self.t_Nodes[node_id]
end

function PANEL:IsNodeExists(node_id)
    return self.t_Nodes[node_id] != nil
end

---@return zen.panel.ztree_node, zen.panel.ztree_node
function PANEL:AddNode(node_id, parent_node_id, bForceCreateParent)
    local parent = self.pnlNodes

    if parent_node_id then
        parent = self.t_Nodes[parent_node_id]

        if !IsValid(parent) then
            if bForceCreateParent then
                local pnlParentNode = self:AddNode(parent_node_id)
                parent = pnlParentNode
            else
                ErrorNoHaltWithStack(parent_node_id, " dont exists")
                parent = self
            end
        end

        parent:SetExtendable(true)
    end

    local pnlNode = gui.Create("ztree_node", parent)
    pnlNode:SDock(TOP, 30)
    pnlNode:SetText(node_id)
    -- pnlNode:Expand()

    pnlNode.pnlButton.DoClick = function()
        self:OnNodePress(node_id)
    end

    if parent_node_id == nil or parent == self.pnlNodes then
        pnlNode:DockMargin(0,0,0,0)
    end

    self.t_Nodes[node_id] = pnlNode

    ---@cast parent zen.panel.ztree_node

    return pnlNode, parent
end

vgui.Register("ztree_node", PANEL, "zpanelbase")
