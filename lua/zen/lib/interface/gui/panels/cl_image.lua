module("zen", package.seeall)


local PANEL = {}

function PANEL:Init()
    self:SetMouseInputEnabled(true)

    self.iBorderSize = 0
    self.pnlMaterial = vgui.Create("DImage", self)
    self.pnlMaterial:SetMouseInputEnabled(false)
    self.pnlMaterial:SetKeyboardInputEnabled(false)
end

function PANEL:DoClick()
end

function PANEL:DoRightClick()
end

function PANEL:OnMouseReleased(code)
    if code == MOUSE_LEFT then
        if self.DoClick then
            self:DoClick()
        end
    end

    if code == MOUSE_RIGHT then
        if self.DoRightClick then
            self:DoRightClick()
        end
    end
end

function PANEL:SetImageSize(w, h)
    self.bImageSizeChanged = true
    self.iImageWide = w
    self.iImageHeight = h
end

function PANEL:SetImagePosition(x, y)
    self.bImagePosChanged = true
    self.iImageX = x
    self.iImageY = y
end

function PANEL:PerformLayout(w, h)

    if self.pnlMaterial then
        local bz = self.iBorderSize
        if self.bImageSizeChanged then
            local img_w = self.iImageWide
            local img_h = self.iImageHeight

            local img_x, img_y
            if self.bImagePosChanged then
                img_x = self.iImageX
                img_y = self.iImageY
            else
                img_x = w/2 - img_w/2
                img_y = h/2 - img_h/2
            end

            self.pnlMaterial:SetPos(img_x, img_y)
            self.pnlMaterial:SetSize(img_w, img_h)
        else
            self.pnlMaterial:SetPos(bz/2, bz/2)
            self.pnlMaterial:SetSize(w-bz, h-bz)
        end
    end
end

---@param size number
function PANEL:SetBorderSize(size)
    self.iBorderSize = size
    self:InvalidateLayout(true)
end


---@param strMaterial string|IMaterial
function PANEL:SetImage(strMaterial)
    if type(strMaterial) == "IMaterial" then
        self.pnlMaterial:SetMaterial(strMaterial)
    elseif type(strMaterial) == "string" then
        self.pnlMaterial:SetImage(strMaterial)
    end
end

gui.RegisterStylePanel("image",
    PANEL,
    "EditablePanel",
    {
        -- mouse_input = false,
        -- center = "true"
    }
)