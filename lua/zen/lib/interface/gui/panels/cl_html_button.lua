module("zen", package.seeall)


local PANEL = {}

function PANEL:Init()
    self:SetMouseInputEnabled(true)

    self.iBorderSize = 0
    self.pnlHTML = vgui.Create("DHTML", self)
    self.pnlHTML:SetMouseInputEnabled(false)
    self.pnlHTML:SetKeyboardInputEnabled(false)
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

    if self.pnlHTML then
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

            self.pnlHTML:SetPos(img_x, img_y)
            self.pnlHTML:SetSize(img_w, img_h)
        else
            self.pnlHTML:SetPos(bz/2, bz/2)
            self.pnlHTML:SetSize(w-bz, h-bz)
        end
    end
end

---@param size number
function PANEL:SetBorderSize(size)
    self.iBorderSize = size
    self:InvalidateLayout(true)
end


function PANEL:SetImage(text)
    -- self:SetHTML( [[<html> <body> <p><a> asset://garrysmod/"]] .. text .. [[" </a> </body></html>]] )
    self.pnlHTML:SetHTML(
        [[
            <style>
            body {
             margin: 0;
            }
            </style>
            <body>
            <div>
            <img src="asset://garrysmod/materials/]] .. text ..[["  height="100%" width="100%" ></img>
            </div>
            </body>
        ]]
    )
end

function PANEL:SetText(text)
    -- self:SetHTML( [[<html> <body> <p><a> asset://garrysmod/"]] .. text .. [[" </a> </body></html>]] )
    self.pnlHTML(
        [[
            <style>
            body {
             margin: 0;
            }
            </style>
            <body>
            <div>
            <img src="asset://garrysmod/]] .. text ..[["  height="100%" width="100%" ></img>
            </div>
            </body>
        ]]
    )
end


gui.RegisterStylePanel("html_button",
    PANEL,
    "EditablePanel",
    {
        -- mouse_input = false,
        center = "true"
    }
)
