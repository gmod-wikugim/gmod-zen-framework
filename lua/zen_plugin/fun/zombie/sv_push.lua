module("zen", package.seeall)

---@param ply Player
---@return table<number, Entity>, Vector, Vector
local function FindEntityToPush(ply)
    local origin = ply:EyePos()
    local angles = ply:EyeAngles()
    local normal = angles:Forward()

    local distance = 100

    local radius = 70

    
    return ents.FindInCone(origin, normal, distance, math.cos(radius)), origin, normal
end

---@param ent Entity
---@param ply Player
local function FilterEntity(ent, ply)
    -- if ! IsValid(ent) then return end
    -- if ent == ply then return end
    -- if ent == game.GetWorld() then return end

    -- if ent:GetCollisionGroup() != COLLISION_GROUP_NONE then return end
    -- if !ent:IsSolid() then return end
    -- if ent:IsFlagSet(FL_KILLME) then return end
    -- if ent:GetNotDraw() then return end

    return true
end

local mt_PushAllowed = {
    ["prop_physics"] = true
}

---@param ply Player
---@param ent Entity
---@param origin Vector
---@param normal Veector
local function PushEntity(ply, ent, origin, normal)
    local ent_class = ent:GetClass()
    if !mt_PushAllowed[ent_class] then
        ent:EmitSound("npc/zombie/claw_strike1.wav")
        return
    end

    local physObj = ent:GetPhysicsObject()
    if IsValid(physObj) then
        if !physObj:IsMotionEnabled() then
            physObj:EnableMotion(true)
        end
    end

    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local power = 10000

    physObj:SetVelocity(normal * power)

    ent:EmitSound("npc/zombie/zombie_pound_door.wav")
end


---@param ply Player
function zfun_zombie.Push(ply)
    local Entity_List, origin, normal = FindEntityToPush(ply)

    ply:EmitSound("npc/zombie/zo_attack2.wav")

    anim.RestartGesture(ply, GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, true)

    -- ply:SetAnimation( PLAYER_ATTACK1 )

    for k, ent in pairs(Entity_List) do
        if !FilterEntity(ent, ply) then continue end
        
        PushEntity(ply, ent, origin, normal)
    end
end


