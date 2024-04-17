module("zen", package.seeall)

local PANEL = {}

function PANEL:Init()
    self.pnlButtonClose = gui.CreateStyled("buton", self)
    self.pnlButtonClose.DoClick = function()
        self:Remove()
    end

    self.buttonBGColor = self:zen_GetSkinColor("buttonBGColor")
end

---Setup text for button
---@param text string
function PANEL:SetText(text)
    self.s_Text = text
    self.s_Font = self:zen_GetSkinFont("buttonText")
    self.c_TextColor = self:zen_GetSkinColor("buttonText")
    self.c_TextBGColorBG = self:zen_GetSkinColor("buttonBGText")
end

function PANEL:Paint(w, h)
    draw.Box(0, 0, w, h, self.bgColor)

    if self.s_Text then
        draw.Text(self.s_text, self.s_Font, w/2, h/2, self.c_TextColor, 1, 1,  self.c_TextBGColorBG)
    end
end

gui.RegisterStylePanel("button", PANEL, "EditablePanel")