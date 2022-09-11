local ui, gui, draw = zen.Import("ui", "gui", "ui.draw")


local color_disable = Color(100,100,100,255)
local color_focus = Color(150,255,150,255)
local color_nofocus = Color(150,150,150,200)
local color_bg = Color(80,80,80,255)
local color_text = Color(255,255,255)

local color_bg_succ = Color(80,125,80, 255)
local color_bg_err = Color(125,80,80, 255)


local color_requirement = Color(255,255,125)
local color_error = Color(255, 0, 0)
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

        if iType == TYPE.NUMBER then
            AddInfo{"number", 10, 0, 0, Color(255, 255, 255)}

            if tInfo.min then
                AddInfo{"-min: " .. tInfo.min, 8, 0, 0, color_requirement}
            end
            if tInfo.max then
                AddInfo{"-max: " .. tInfo.max, 8, 0, 0, color_requirement}
            end
        end
        if iType == TYPE.STRING then
            AddInfo{"string", 10, 0, 0, Color(255, 255, 255)}
        end
        if iType == TYPE.VECTOR then
            AddInfo{"vector", 10, 0, 0, Color(255, 255, 255)}
        end
        if iType == TYPE.BOOLEAN then
            AddInfo{"boolean", 10, 0, 0, Color(255, 255, 255)}
        end
        if iType == TYPE.ENTITY then
            AddInfo{"entityid", 10, 0, 0, Color(255, 255, 255)}
        end
        if iType == TYPE.PLAYER then
            AddInfo{"player", 10, 0, 0, Color(255, 255, 255)}
        end

        if tInfo.optional then
            AddInfo{"-optional", 8, 0, 0, color_requirement}
        elseif value == nil or value == "" or value == " " then
            AddInfo{"can't be empty", 8, 0, 0, color_error}
        end

        self.anySucessValue =  nil
        if value == nil or value == "" or value == " " then
            self.clr_bg = color_bg
        else
            if iType == TYPE.ENTITY then
                local ent_id = tonumber(value)
                if not ent_id then
                    AddInfo{"Should be number", 6, 0, 0, COLOR.R}
                else
                    new_value = Entity(ent_id)
                end
            end

            if iType == TYPE.PLAYER then
                local ply = util.GetPlayerEntity(value)
                if not ply then
                    ply = util.FindPlayerEntity(value)
                end

                new_value = ply
            end


            if new_value != nil then
                if iType == TYPE.NUMBER then
                    if tInfo.min and new_value < tInfo.min then
                        AddInfo{"min limit: " .. tInfo.min, 8, 0, 0, COLOR.R}
                    end
                    if tInfo.max and new_value > tInfo.max then
                        AddInfo{"max limit: " .. tInfo.max, 8, 0, 0, COLOR.R}
                    end
                end
            end

            if new_value != nil then
                self.clr_bg = color_bg_succ
                AddInfo{": " .. tostring(new_value), 10, 0, 0, COLOR.G, 0}
                self.anySucessValue = new_value
            else
                self.clr_bg = color_bg_err
                AddInfo{"-error-", 6, 0, 0, COLOR.R}
                if iType == TYPE.NUMBER or iType == TYPE.ENTITY then
                    local others = string.gsub(value, "%d", "")
                    AddInfo{"Incorrent symbols: " .. tostring(others), 6}
                end
            end
        end

        self:zen_SetHelpTextArray(tsArray)
    end,
    OnEnter = function(self)
        if self.ChangeInputValue then
            self:ChangeInputValue(self.anySucessValue)
        end
    end,
    Paint = function(self, w, h)
        if ( self.m_bBackground ) then

            if ( self:GetDisabled() ) then
                draw.Box(0,0,w,h,self.clr_bg)
                draw.BoxOutlined(1,0,0,w,h,color_disable)
            elseif ( self:HasFocus() ) then
                draw.Box(0,0,w,h,self.clr_bg)
                draw.BoxOutlined(1,0,0,w,h,color_focus)
            else
                draw.Box(0,0,w,h,self.clr_bg)
                draw.BoxOutlined(1,0,0,w,h,color_nofocus)
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
}, "DTextEntry", {"input", min_size = {25, 25}}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

-- Bool Input
gui.RegisterStylePanel("input_bool", {
    Init = function(self)
        func_InitBase(self, TYPE.BOOL)
    end,
    GetValue = function(self) return self.pnl_Value.Result end,
    PerformLayout = func_def_input_PerformLayout,
    SetText = fun_def_input_SetText,
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_bool"}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_number"}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}, text = "zen.input_arg"}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

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
}, "EditablePanel", {"input", min_size = {25, 25}}, {})

gui.RegisterStylePanel("input_player", {
    Setup = function(self, tInfo, UpdateVar)
        if IsValid(self.pnl_Value) then return end
        self.pnl_Value = self:zen_AddStyled("input_entry", {"dock_fill"})
        self.pnl_Value:Setup(tInfo)

        self.pnl_Value.ChangeInputValue = function(self, new_value)
            UpdateVar(new_value)
        end
    end,
}, "EditablePanel", {"input", min_size = {25, 25}}, {})



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
    Setup = function(self, data)
        self.pnlList:Clear()
        local wide = self.pnlList:GetWide()
        for k, v in pairs(data) do
            local Name = v.name
            local iType = v.type

            local sStyleName = supported_input_panel_styles[iType]
            assert(sStyleName, "Style not exists for type: ", iType)

            local pnlHandler = self.pnlList:zen_AddStyled("base", {"dock_top", tall = 30, "input"})
            
            local pnlKey = pnlHandler:zen_AddStyled("text", {"dock_left", wide = wide/2-5, "input", text = Name})
            local pnlValue = pnlHandler:zen_AddStyled("base", {"dock_right", wide = wide/2-5, "input"})

            local pnlChange = pnlHandler:zen_AddStyled(sStyleName, {"dock_fill", "input"})
            pnlChange:Setup(v)
        end
    end,
    PerformLayout = function(self, w, h)


    end
}, "EditablePanel", {"input", "dock_fill"}, {})