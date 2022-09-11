local ui, gui, draw = zen.Import("ui", "gui", "ui.draw")


local color_disable = Color(100,100,100,255)
local color_focus = Color(150,255,150,255)
local color_nofocus = Color(150,150,150,200)
local color_bg = Color(80,80,80,255)
local color_bg2 = Color(70,70,70,255)

local color_text = Color(255,255,255)

local color_bg_succ = Color(80,125,80, 255)
local color_bg_err = Color(125,80,80, 255)


local color_requirement = Color(255,255,125)
local color_error = Color(255, 0, 0)
local color_result = Color(125,255,125)

local function ValueToString(value, iType)
    if util.mt_convertableType[iType] then
        return util.TYPEToString(value, iType)
    end

    if iType == TYPE.ENTITY then
        return value:EntIndex()
    end

    if iType == TYPE.PLAYER then
        return value:UserID()
    end
end


local function GetNewValue(value, iType)
    if util.mt_convertableType[iType] then
        return util.StringToTYPE(value, iType)
    end

    if iType == TYPE.ENTITY then
        local ent_id = tonumber(value)
        if not ent_id then return end
        return Entity(ent_id)
    end

    if iType == TYPE.PLAYER then
        local ply = util.GetPlayerEntity(value)
        if not ply then
            ply = util.FindPlayerEntity(value)
        end

        return ply
    end
end

local numeric_itypes = {
    [TYPE.ENTITY] = true,
    [TYPE.NUMBER] = true,
}

local function CheckValue(value, tInfo)
    local new_value
    local iType = tInfo.type
    local tRequirement, tErrors = {}, {}

    local addRequirement = function(text) table.insert(tRequirement, text) end
    local addError = function(text) table.insert(tErrors, text) end

    local isEmpty = value == nil or value == "" or value == " "


    if not tInfo.optional then addRequirement("required") end
    if tInfo.min then addRequirement("min: " .. tInfo.min) end
    if tInfo.max then addRequirement("max: " .. tInfo.max) end


    if isEmpty then goto result end
    new_value = GetNewValue(value, iType)


    if new_value == nil then addError("can't be converted") end


    do
        local isNeedNumberCheck = tInfo.numeric or numeric_itypes[iType]

        if isNeedNumberCheck then
            local value_num = tonumber(value)

            if value_num then
                if tInfo.min and value_num < tInfo.min then addError("number min is: " .. tInfo.min) end
                if tInfo.max and value_num > tInfo.max then addError("number max is: " .. tInfo.max) end
            else
                local others = string.gsub(value, "%d", "")

                local incorrent = "'" .. table.concat(string.Split(others, ""), "', '") .. "'"
                addError("incorrent symbols: " .. tostring(incorrent))
            end
        end
    end

    ::result::

    if new_value == nil and not tInfo.optional then
        addError("result should exists")
    end

    return new_value, tRequirement, tErrors
end


gui.RegisterStylePanel("input_entry", {
    Init = function(self)
        self.clr_bg = color_bg
        self.iType = TYPE.STRING
        self:SetFont(ui.ffont(6))
        self:CheckValue()
    end,
    Setup = function(self, tInfo)
        self.tInfo = tInfo
        self:SetType(tInfo.type)

        if tInfo.default then
            local new_value = ValueToString(tInfo.default, tInfo.type)
            if new_value != nil then
                self:SetValue(new_value)
                self:CheckValue()
            end
        end
    end,
    SetType = function(self, type)
        self.iType = type
        self:CheckValue()
    end,
    OnChange = function(self, value)
        self:CheckValue()
    end,
    CheckValue = function(self)
        local value = self:GetValue()
        local new_value

        if util.mt_convertableType[self.iType] then
            new_value = util.StringToTYPE(value, self.iType)
        end

        local tsArray = {}
        local function AddInfo(data) table.insert(tsArray, data) end

        local iType = self.iType
        local tInfo = self.tInfo or {}

        local new_value, tRequirement, tErrors = CheckValue(value, tInfo)

        local TYPE_NAME = TYPE[iType]
        AddInfo{TYPE_NAME, 10}

        local hasRequiremnts = not table.IsEmpty(tRequirement)
        local hasErrors = not table.IsEmpty(tErrors)

        if hasRequiremnts then
            AddInfo{"Requirement:", 8, 0, 0, color_requirement, nil, nil, COLOR.BLACK}
            for k, v in pairs(tRequirement) do
                AddInfo{"- " .. v, 7, 0, 0, color_requirement, nil, nil, COLOR.BLACK}
            end
        end

        if hasErrors then
            AddInfo{"Errors:", 8, 0, 0, color_error, nil, nil, COLOR.BLACK}
            for k, v in pairs(tErrors) do
                AddInfo{"- " .. v, 7, 0, 0, color_error, nil, nil, COLOR.BLACK}
            end
        else
            AddInfo{": " .. tostring(new_value), 8, 0, 0, color_result, nil, nil, COLOR.BLACK}
        end


        self.clr_bg = hasErrors and color_bg_err or color_bg_succ

        if hasErrors then
            self.anySucessValue = nil
        else
            self.anySucessValue = new_value
        end

        self:zen_SetHelpTextArray(tsArray)
    end,
    OnEnter = function(self)
        if self.ChangeInputValue then
            self:ChangeInputValue(self.anySucessValue)
        end
    end,
    OnLoseFocus = function(self)
        self:OnEnter()
    end,
    Paint = function(self, w, h)
        if ( self.m_bBackground ) then

            if ( self:HasFocus() ) then
                draw.Box(0,0,w,h,self.clr_bg)
            end
        end
    
        -- Hack on a hack, but this produces the most close appearance to what it will actually look if text was actually there
        if ( self.GetPlaceholderText && self.GetPlaceholderColor && self:GetPlaceholderText() && self:GetPlaceholderText():Trim() != "" && self:GetPlaceholderColor() && ( !self:GetText() || self:GetText() == "" ) ) then
    
            local oldText = self:GetText()
    
            local str = self:GetPlaceholderText()
            if ( str:StartWith( "#" ) ) then str = str:sub( 2 ) end
            str = language.GetPhrase( str )
    
            self:SetText( str )
            self:DrawTextEntryText( self:GetPlaceholderColor(), self:GetHighlightColor(), self:GetCursorColor() )
            self:SetText( oldText )
    
            return
        end
    
        self:DrawTextEntryText( color_text, self:GetHighlightColor(), color_text )

        if self.sHelpText and self.sHelpText != "" and (self:IsHovered() or self:HasFocus()) then
            local aw, ah = ui.GetTextSize(self.sHelpText, 6)

            local bx, by = w/2-aw/2, h+1

            draw.Box(bx,by,aw,ah,self.clr_bg)

            local tx, ty = bx + aw/2, by + ah/2

            draw.Text(self.sHelpText, 6, tx, ty, color_text, 1, 1, COLOR.BLACK)
        end
    end,
}, "DTextEntry", {"input"}, {})

-- Text Input
gui.RegisterStylePanel("input_text", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input"}, {})

-- Bool Input
gui.RegisterStylePanel("input_bool", {
    Init = function(self)
        func_InitBase(self, TYPE.BOOL)
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", text = "zen.input_bool"}, {})

-- Number Input
gui.RegisterStylePanel("input_number", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input", text = "zen.input_number"}, {})

-- Arg Input
gui.RegisterStylePanel("input_arg", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input", text = "zen.input_arg"}, {})

-- Vector Input
gui.RegisterStylePanel("input_vector", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input"}, {})

-- Color Input
gui.RegisterStylePanel("input_color", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input"}, {})

-- Entity Input
gui.RegisterStylePanel("input_entity", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input"}, {})

gui.RegisterStylePanel("input_player", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input"}, {})



local supported_input_panel_styles = {
    [TYPE.NUMBER] = "input_number",
    [TYPE.VECTOR] = "input_vector",
    [TYPE.ENTITY] = "input_entity",
    [TYPE.PLAYER] = "input_player",
    [TYPE.STRING] = "input_text",
    [TYPE.BOOL] = "input_bool",
}



gui.RegisterStylePanel("mass_input", {
    Init = function(self)
        self.pnlList = self:zen_AddStyled("list", {"dock_fill", "input"})
    end,
    Setup = function(self, data, onChanged)
        local wide = self.pnlList:GetWide()
        local tValues = {}
        for k, v in pairs(data) do
            local Name = v.name
            local iType = v.type

            local sStyleName = supported_input_panel_styles[iType]
            assert(sStyleName, "Style not exists for type: ", iType)

            local pnlHandler = self.pnlList:zen_AddStyled("base", {"dock_top", tall = 15, "input"})
            pnlHandler:DockPadding(0,0,0,0)
            pnlHandler.Paint = function(self, w, h)
                if k % 2 == 0 then
                    draw.Box(0,0,w,h,color_bg)
                else
                    draw.Box(0,0,w,h,color_bg2)
                end
            end
            
            pnlHandler.pnlKey = pnlHandler:zen_AddStyled("text", {"dock_left", font = ui.ffont(6), wide = wide/2-5, "input", content_align = 4, text = " " .. Name})
            pnlHandler.pnlValue = pnlHandler:zen_AddStyled("base", {"dock_right", wide = wide/2-5, "input"})

            pnlHandler.pnlChange = pnlHandler.pnlValue:zen_AddStyled(sStyleName, {"dock_fill", "input"})
            pnlHandler.pnlChange:Setup(v, function(new_value)
                tValues[Name] = new_value
                if onChanged then onChanged(Name, new_value) end
            end)
        end

        return tValues
    end,
    PerformLayout = function(self, w, h)
        if self.pnlList then
            local children = self.pnlList:GetCanvas():GetChildren()
            for k, pnl in pairs(children) do
                pnl.pnlKey:SetWide(w/2-5)
                pnl.pnlValue:SetWide(w/2-5)
            end
        end
    end
}, "EditablePanel", {"input"}, {})