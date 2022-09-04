local ui, gui = zen.Import("ui", "gui")


local func_InitBase = function(self)
    self.pnl_Key = self:zen_AddStyled("text", {"dock_left"})
    self.pnl_Value = self:zen_AddStyled("text", {"dock_right", "input"})
    self.pnl_Value:MouseCapture(true)

    self.pnl_Value.Think = function()
        if not self.ChangeMode then return end


        local x, y = self.pnl_Value:LocalCursorPos()
        local w, h = self.pnl_Value:GetSize()

        local key_focus = vgui.GetKeyboardFocus()

        local isHasFocus
        local children = self.pnl_Value:GetChildren()

        for k, cpnl in pairs(children) do
            if cpnl == key_focus then
                isHasFocus = true
                break
            end
        end


        if isHasFocus or  (x > 0 and y > 0 and x < w and y < h) then
            if self.pnl_Change:GetAlpha() < 255 then
                self.pnl_Change:SetAlpha(255)
                self.pnl_Change:SetKeyboardInputEnabled(true)
                self.pnl_Change:SetMouseInputEnabled(true)
                self:ChangeMode()
            end
        else
            if self.pnl_Change:GetAlpha() > 1 then
                self.pnl_Change:SetAlpha(1)
            end
        end
    end
end

local func_get_valueString = function(value, value_type, old_value)
    if value == nil then return old_value end

    value = util.TYPEToString(value, value_type)
    if value == nil then return old_value end

    return value
end

local func_def_input_PerformLayout = function(self, w, h)
    if self.pnl_Key and self.pnl_Value then
        self.pnl_Key:SetWide(w/2 - 10)
        self.pnl_Value:SetWide(w/2 - 10)
    end
end

local fun_def_input_SetText = function(self, value)
    self.pnl_Key:SetText(value)
end

-- Text Input
gui.RegisterStylePanel("input_text", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DTextEntry", {"dock_fill"})
    end,
    ChangeMode = function(self)
        local value = self.pnl_Value.Result
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change:SetVisible(true)
        self.pnl_Change.OnEnter = function()
            local value = self.pnl_Change:GetValue()
            if value != nil then self:SetValue(value) end
            self.pnl_Change:SetVisible(true)
        end
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(tostring(value))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

-- Bool Input
gui.RegisterStylePanel("input_bool", {
    Init = function(self)
        func_InitBase(self)
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(value and "true" or "false")
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_bool"}, {})

-- Number Input
gui.RegisterStylePanel("input_number", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DTextEntry", {"dock_fill"})
        self.pnl_Change:SetNumeric(true)
    end,
    ChangeMode = function(self)
        local value = self.pnl_Value.Result
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change.OnEnter = function() 
            local value = util.StringToTYPE(self.pnl_Change:GetValue(), TYPE.NUMBER )
            if value != nil then self:SetValue(value) end
        end
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(tostring(value))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_number"}, {})

-- Arg Input
gui.RegisterStylePanel("input_arg", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DComboBox", {"dock_fill"})
    end,
    AddChoice = function(self, ...)
        self.pnl_Change:AddChoice(...)
    end,
    ChangeMode = function(self)
        local value = self.pnl_Value.Result
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change.OnSelect = function(_, name, value)
            local value = value or name
            if value != nil then self:SetValue(value) end
        end
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(tostring(value))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_arg"}, {})

-- Vector Input
gui.RegisterStylePanel("input_vector", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DTextEntry", {"dock_fill"})
    end,
    ChangeMode = function(self)
        local value = func_get_valueString(self.pnl_Value.Result, TYPE.VECTOR, self.pnl_Value.Result)
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change.OnEnter = function()
            local value = util.StringToTYPE(self.pnl_Change:GetValue(), TYPE.VECTOR )
            if value != nil then self:SetValue(value) end
        end
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(util.TYPEToString(value, TYPE.VECTOR))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

-- Color Input
gui.RegisterStylePanel("input_color", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DTextEntry", {"dock_fill"})
    end,
    ChangeMode = function(self)
        local value = func_get_valueString(self.pnl_Value.Result, TYPE.COLOR, self.pnl_Value.Result)
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change.OnEnter = function()
            local value = util.StringToTYPE(self.pnl_Change:GetValue(), TYPE.COLOR )
            if value != nil then self:SetValue( value ) end
        end
    end,
    SetValue = function(self, value)
        self.pnl_Value.Result = value
        self.pnl_Value:SetText(util.TYPEToString(value, TYPE.COLOR))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

-- Entity Input
gui.RegisterStylePanel("input_entity", {
    Init = function(self)
        func_InitBase(self)
        self.pnl_Change = self.pnl_Value:zen_Add("DTextEntry", {"dock_fill"})
    end,
    ChangeMode = function(self)
        local value = self.pnl_Value.Result
        if isentity(value) then value = tostring(value:EntIndex()) end
        if value != nil then self.pnl_Change:SetValue(value) end
        self.pnl_Change.OnEnter = function()
            local ent_id = tonumber(self.pnl_Change:GetValue())
            if ent_id != nil then
                local ent = Entity(ent_id)
                if IsValid(ent) then
                    self:SetValue(ent)
                else
                    self:SetValue(nil)
                end
            end
        end
    end,
    SetValue = function(self, value) 
        self.pnl_Value.Result = value 
        self.pnl_Value:SetText(tostring(value))
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}}, {})