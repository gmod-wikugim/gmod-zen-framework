local ui, gui = zen.Import("ui", "gui")

gui.RegisterStylePanel("func_save_pos", {
    iNextSave = CurTime(),
    iOwnerLastX = 0,
    iOwnerLastY = 0,
    Think = function(self)
        if self.zen_pnlSavePos and self.iNextSave < CurTime() then
            self.iNextSave = CurTime() + 0.1

            local x, y = self.zen_pnlSavePos:GetPos()
            x = math.floor(x)
            y = math.floor(y)

            if self.iOwnerLastX != x or self.iOwnerLastY != y then
                self.iOwnerLastX = x
                self.iOwnerLastY = y

                local cookie_value = table.concat({x, y}, " ")

                self:SetCookie("zen_LastPos", cookie_value)
            end
        end
    end,
    zen_PostInit = function(self)
        if not IsValid(self.zen_pnlSavePos) then error("self.zen_pnlSavePos not setuped for \"save posing\"") end
        local sPos = self:GetCookie("zen_LastPos")

        if sPos and sPos != "" then
            local pos = string.Split(sPos, " ")
            local x, y = pos[1], pos[2]
            x = tonumber(x)
            y = tonumber(y)
            if x and y then
                local w, h = self.zen_pnlSavePos:GetSize()
                x = math.Clamp(x, 0, ScrW()-w)
                y = math.Clamp(y, 0, ScrH()-h)
                self.zen_pnlSavePos:SetPos(x, y)
            end
        end
    end,
}, "EditablePanel", {
    key_input = false,
    mouse_input = false
}, {})