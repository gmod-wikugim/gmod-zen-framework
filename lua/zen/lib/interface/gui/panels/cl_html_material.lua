module("zen", package.seeall)


local PANEL = {}


function PANEL:Init()
    -- self:SetMouseInputEnabled(false)
    self.iBorderSize = 0
    self.pnlHTML = vgui.Create("DHTML", self)
end

function PANEL:PerformLayout(w, h)

    if self.pnlHTML then
        local bz = self.iBorderSize
        self.pnlHTML:SetPos(bz/2, bz/2)
        self.pnlHTML:SetSize(w-bz, h-bz)
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


gui.RegisterStylePanel("html_material",
    PANEL,
    "EditablePanel",
    {
        -- mouse_input = false,
        center = "true"
    }
)
