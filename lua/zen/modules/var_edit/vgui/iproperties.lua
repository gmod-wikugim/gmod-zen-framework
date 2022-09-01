local PANEL = {}

function PANEL:Init()
    self:SetSize(300, 500)
    self:SetSizable(true)
    self:SetSkin("Default")
end

function PANEL:SetupData(ent, vars)
    self:SetTitle(ent:GetClass())

    if IsValid(self.pnlList) then self.pnlList:Remove() end
    self.pnlList = self:Add("DScrollPanel")
    self.pnlList:Dock(FILL)
    self.pnlList:InvalidateParent(true)
    self.pnlList:SetSize(self:GetSize())
    self.pnlList:SetMouseInputEnabled(true)
    self.pnlList:SetKeyboardInputEnabled(true)

    self.eEntity = ent
    self.tVars = vars

    local wide = self.pnlList:GetWide() - 25

    local nvars = vars.NVars
    if next(nvars) then
        for name, dat in pairs(nvars) do
            local pnlHandler = self.pnlList:Add("EditablePanel")
            pnlHandler:SetTall(20)
            pnlHandler:Dock(TOP)
            pnlHandler:InvalidateParent(true)
            pnlHandler:SetMouseInputEnabled(true)
            pnlHandler:SetKeyboardInputEnabled(true)


            pnlHandler.pnlName = pnlHandler:Add("DLabel")
            pnlHandler.pnlName:SetText(name)
            pnlHandler.pnlName:SetWide(wide/2)
            pnlHandler.pnlName:Dock(LEFT)
            pnlHandler.pnlName:InvalidateParent(true)

            local typen = dat.type

            pnlHandler.pnlValueHandler = pnlHandler:Add("EditablePanel")
            pnlHandler.pnlValueHandler:SetWide(wide/2)
            pnlHandler.pnlValueHandler:Dock(RIGHT)
            pnlHandler.pnlValueHandler:InvalidateParent(true)

            if typen == TYPE.BOOL then
                pnlHandler.pnlValue = pnlHandler.pnlValueHandler:Add("DComboBox")
                pnlHandler.pnlValue:Dock(FILL)
                pnlHandler.pnlValue:InvalidateParent(true)
                -- pnlHandler.pnlValue:SetTextColor(Color(0,0,0))

                pnlHandler.pnlValue:AddChoice("true", true)
                pnlHandler.pnlValue:AddChoice("false", false)
                pnlHandler.pnlValue:ChooseOption(tostring(dat.value))


                pnlHandler.pnlValue.OnSelect = function( self, index, value )
                    local new_value = util.StringToTYPE(value, typen)
                    if new_value then
                        self:SetValue(value)
                        nt.Send("nvars.edit", {"entity", "uint8", "string", "any", "uint12", "boolean"}, {ent, zen.nvars.TYPE_NVARS, name, new_value, typen, false})
                    else
                        self:SetValue(tostring(dat.value))
                    end
                end
            else
                pnlHandler.pnlValue = pnlHandler.pnlValueHandler:Add("DTextEntry")
                pnlHandler.pnlValue:Dock(FILL)
                pnlHandler.pnlValue:InvalidateParent(true)
                local numeric = typen == TYPE.NUMBER or typen == TYPE.COLOR
                pnlHandler.pnlValue:SetNumeric(numeric)
                pnlHandler.pnlValue:SetValue(tostring(dat.value))
                pnlHandler.pnlValue:SetMouseInputEnabled(true)
                pnlHandler.pnlValue:SetKeyboardInputEnabled(true)
                pnlHandler.pnlValue.OnEnter = function(self)
                    local value = self:GetValue()

                    local new_value = util.StringToTYPE(value, typen)
                    if new_value then
                        self:SetValue(new_value)
                        nt.Send("nvars.edit", {"entity", "uint8", "string", "any", "uint12", "boolean"}, {ent, zen.nvars.TYPE_NVARS, name, new_value, typen, false})
                    else
                        self:SetValue(tostring(dat.value))
                    end
                end
            end
        end
    end
end

vgui.Register("zen.properties", PANEL, "DFrame")