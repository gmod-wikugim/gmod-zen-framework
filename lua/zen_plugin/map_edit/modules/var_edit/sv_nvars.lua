module("zen", package.seeall)

nt.RegisterChannel("nvars.edit")
nt.RegisterChannel("nvars.get_buttons")
nt.RegisterChannel("nvars.run_command")
nt.RegisterChannel("nvars.run_command.extra")


local nwvars = {
    [TYPE.ANGLE] = META.ENTITY.SetNWAngle,
    [TYPE.BOOL] = META.ENTITY.SetNWBool,
    [TYPE.ENTITY] = META.ENTITY.SetNWEntity,
    [TYPE.NUMBER] = META.ENTITY.SetNWFloat,
    [TYPE.STRING] = META.ENTITY.SetNWString,
    [TYPE.VECTOR] = META.ENTITY.SetNWVector,
}

nt.Receive("nvars.edit", {"entity", "uint8", "string", "any", "uint12", "boolean"}, function(ply, ent, iType, key, anyValue, iValueType, bUnpack)
    if not ply:zen_HasPerm("zen.variable_edit.nvars") then return end

    -- print(ply, ent, iType, key, anyValue, iValueType, bUnpack)

    if iType == zen.nvars.TYPE_NVARS or iType == zen.nvars.TYPE_SETVARS then
        local func = ent["Set" .. key]
        if func then
            if bUnpack then
                func(ent, unpack(anyValue))
            else
                func(ent, anyValue)
            end
        end
    elseif iType == zen.nvars.TYPE_NWVARS then
        local func = nwvars[iValueType]
        if func then
            if bUnpack then
                func(ent, unpack(anyValue))
            else
                func(ent, anyValue)
            end
        end
    elseif iType == zen.nvars.TYPE_FUNC then
        local func = ent[key]
        if func then
            if bUnpack then
                func(ent, unpack(anyValue))
            else
                func(ent, anyValue)
            end
        end
    elseif iType == zen.nvars.TYPE_VARIABLE then
        ent[key] = anyValue
    end
end)

zen.nvars.mt_ClassAlias = zen.nvars.mt_ClassAlias or {}
zen.nvars.mt_ClassAlias["func_door_rotating"] = "door"
zen.nvars.mt_ClassAlias["prop_door_rotating"] = "door"
zen.nvars.mt_ClassAlias["func_movelinear"]    = "door"
zen.nvars.mt_ClassAlias["func_door"]          = "door"
zen.nvars.mt_ClassAlias["door"]          = "door"

zen.nvars.mt_EntityButtons = zen.nvars.mt_EntityButtons or {}
zen.nvars.mt_EntityButtonsByIDS = zen.nvars.mt_EntityButtonsByIDS or {}
function zen.nvars.RegisterButton(data)
    assertFunction(data.func)
    assert(isfunction(data.fCheck) or data.fCheck == nil, "data.fCheck should be func|nil")
    assert(isfunction(data.fGetMode) or data.fGetMode == nil, "data.fCheck should be func|nil")
    assertStringNice(data.name, "data.name")
    assertStringNice(data.class, "data.class")
    assertNumber(data.id, "data.id")

    
    zen.nvars.mt_EntityButtons[data.class] = zen.nvars.mt_EntityButtons[data.class] or {}
    zen.nvars.mt_EntityButtons[data.class][data.name] = data

    zen.nvars.mt_EntityButtonsByIDS[data.id] = data
end

function zen.nvars.GetEntityButtons(ent)
    local class = ent:GetClass()
    class = zen.nvars.mt_ClassAlias[class] or class
    return zen.nvars.mt_EntityButtons[class]
end

function zen.nvars.GetAvailableButtons(ent)
    local tButtons = zen.nvars.GetEntityButtons(ent)
    local tResult = {}

    if tButtons then
        for _, data in pairs(tButtons) do
            if data.fCheck and data.fCheck(data, ent) == false then continue end
            local mode, buttonName
            if data.fGetMode then
                mode, buttonName = data.fGetMode(data, ent)
            end
            buttonName = buttonName or data.name
            table.insert(tResult, {
                id = data.id,
                string = buttonName,
                mode = mode
            })
        end
    end

    return tResult
end

function zen.nvars.StartCommand(ent, button_id, mode)
    local tButton = zen.nvars.mt_EntityButtonsByIDS[button_id]
    if not tButton then return false, "button id don't exists" end

    if tButton.fCheck then
        local res, com = tButton.fCheck(tButton, ent)
        if res == false then return false, com or "data.fCheck blocked" end
    end

    return tButton.func(tButton, ent, mode)
end

nt.Receive("nvars.run_command", {"entity", "int12", "next", "any"}, function(ply, ent, id, isMode, mode)
    if not ply:zen_HasPerm("zen.variable_edit.nvars") then return end

    zen.nvars.StartCommand(ent, id, mode)
end)

nt.Receive("nvars.get_buttons", {"entity"}, function(ply, ent)
    if not ply:zen_HasPerm("zen.variable_edit.nvars") then return end
    if not IsValid(ent) then return end

    local tResult = zen.nvars.GetAvailableButtons(ent)

    nt.Send("nvars.get_buttons", {"entity", "table"}, {ent, tResult}, ply)
end)

zen.nvars.RegisterButton{
    id = 1,
    name = "Doors Open/Close",
    class = "door",
    fGetMode = function(self, ent)
        local isOpened = util.IsDoorOpened(ent)
        return isOpened, isOpened and "Close" or "Open"
    end,
    func = function(self, ent, isOpened)
        local speed = ent:GetInternalVariable("m_flSpeed")
        local isLocked = util.IsDoorLocked(ent)

        ent.m_flBaseSpeed = ent.m_flBaseSpeed or speed
        ent:Fire("SetSpeed", "1000")

        if isOpened then
            ent:Fire("Unlock")
            ent:Fire("Toggle")
            ent:Fire("Lock")
        else
            ent:Fire("Unlock")
            ent:Fire("Toggle")
        end

        timer.Simple(1, function()
            if not IsValid(ent) then return end
            ent:Fire("SetSpeed", ent.m_flBaseSpeed)
        end)
    end
}

zen.nvars.RegisterButton{
    id = 3,
    name = "Player Respawn",
    class = "prop_ragdoll",
    fCheck = function(self, ent)
        return ent.IsCorpse and IsValid(ent.owner) and not ent.owner:Alive()
    end,
    fGetMode = function(self, ent)
        return nil, "Respawn " .. ent.owner:GetName()
    end,
    func = function(self, ent)
        local pos = ent:GetPos()
        local ply = ent.owner
        ply:Spawn()
        timer.Simple(0, function()
            ply:SetPos(pos)
        end)
        ent:Remove()
    end
}

zen.nvars.RegisterButton{
    id = 4,
    name = "Fading Doors Open",
    class = "prop_physics",
    fCheck = function(self, ent)
        return ent.FadingDoor and true or false
    end,
    fGetMode = function(self, ent)
        return ent.Faded and true or false, ent.Faded and "Fade" or "UnFade"
    end,
    func = function(self, ent, isFaden)
        if isFaden then
            ent:UnFade()
        else
            ent:Fade()
        end

        timer.Simple(3, function()
            if not IsValid(ent) then return end

            if isFaden then
                ent:Fade()
            else
                ent:UnFade()
            end
        end)
    end
}

local models_list = {
    ["models/props_junk/popcan01a.mdl"] = {
        Name = "Water"
    }
}


zen.nvars.RegisterButton{
    id = 5,
    name = "Refill",
    class = "item_healthcharger",
    func = function(self, ent)
        ent:SetKeyValue("m_iJuice", "999999")
    end
}



nt.RegisterStringNumbers("remove")
nt.RegisterStringNumbers("freeze")
nt.RegisterStringNumbers("motion")
nt.RegisterStringNumbers("dissolve")
nt.RegisterStringNumbers("edit.pos")
nt.RegisterStringNumbers("edit.angle")
nt.RegisterStringNumbers("edit.velocity")

nt.RegisterStringNumbers("edit.physics")
nt.RegisterStringNumbers("edit.bones")
nt.RegisterStringNumbers("edit.variables")

nt.RegisterStringNumbers("info.this")
nt.RegisterStringNumbers("info.parent")
nt.RegisterStringNumbers("info.all")

zen.nvars.commands = {}
zen.nvars.commands["remove"] = function(ply, ent, mode)
    ent:Remove()
end
zen.nvars.commands["dissolve"] = function(ply, ent, mode)
    local name = "disolve_" .. SysTime()

    META.ENTITY.SetName(ent, name)
    
    
    local desolver = ents.Create("env_entity_dissolver")
    desolver:SetKeyValue( "dissolvetype", 3 )
    desolver:Spawn()
    desolver:Activate()
    desolver:Fire("Dissolve", name)
end

nt.Receive("nvars.run_command.extra", {"entity", "string_id", "any"}, function(ply, ent, command, mode)
    if not ply:zen_HasPerm("zen.variable_edit.nvars") then return end

    print(ply, ent, command)

    local fCommand = zen.nvars.commands[command]
    assertFunction(fCommand, "fCommand")

    fCommand(ply, ent, mode)
end)