module("zen", package.seeall)


local ALLOW_CLASS = {
    ["prop_physics"] = true
}

local function TraceWall(ply, origin, origin_to)
    local tr = util.TraceLine{
        start = origin,
        endpos = origin_to,
        filter = ply,
    }

    local hit_pos = tr.HitPos

    local x, y = hit_pos.x, hit_pos.y

    if tr.HitWorld then return true, x, y end

    if IsValid(tr.Entity) then
        local class = tr.Entity:GetClass()
        if ALLOW_CLASS[class] then return true, x, y end
    end

    return false
end

local function CountTrue(...)
    local count = 0
    for k, boolean in ipairs({...}) do
        if boolean != true then continue end
        count = count + 1
    end

    return count
end

local function CheckAnySame(...)
    local same = {}
    for k, var in ipairs({...}) do
        if same[var] then return true end

        same[var] = true
    end

    return false
end

---@param ply Player
---@param mv CMoveData
---@param cmd CUserCmd
---@return table, Vector
local function IsWallNear(ply, mv, cmd)
    local origin = ply:GetPos()
    local obb_center = ply:OBBCenter()

    local angle = ply:GetAngles()
    local forward = angle:Forward()


    local start1 = origin + Vector(0, 0, 1)
    local bWall1, x1, y1 = TraceWall(ply, start1, start1 + forward * 100)

    local start2 = origin + obb_center
    local bWall2, x2, y2 = TraceWall(ply, start2, start2 + forward * 100)

    local start3 = origin + obb_center * 2 - Vector(0,0,1)
    local bWall3, x3, y3 = TraceWall(ply, start3, start3 + forward * 100)

    local balls = CountTrue(bWall1, bWall2, bWall3)

    if balls < 2 then return false end

    if !CheckAnySame(x1, x2, x3) and !CheckAnySame(y1, y2, y3) then return false end


    return true
end

---@param ply Player
---@param mv CMoveData
---@param cmd CUserCmd
---@return table, Vector
local function ClimpTrace(ply, mv, cmd)
    local origin = ply:GetPos()  + ply:OBBCenter()
    local angle = ply:GetAngles()
    local normal = angle:Forward()

    local eye_forward = ply:EyeAngles():Forward()

    local to_angle = Vector(normal)
    to_angle.y = eye_forward.y * 500
    to_angle.x = eye_forward.x * 500
    to_angle.z = eye_forward.z * 500

    local col_min, col_max = ply:GetCollisionBounds()

    local distance = 150
    local origin_to = origin + eye_forward * distance

    local radius = 5

    local vec_size = Vector(radius, radius, radius)

    return util.TraceHull{
        mins = col_min,
        maxs = col_max,
        start = origin,
        endpos = origin_to,
        filter = ply
    }, to_angle
end

local CLASS = player_mode.GetClass("zombie")

local get_data, set_data = player_data.AutoTable("zen.fun.zombie.move")

function CLASS:HookDisappear()
	if self.LightingModeChanged then
		render.SetLightingMode( 0 )
		self.LightingModeChanged = false
        -- render.SetShadowsDisabled(false)
	end
end

function CLASS:PreRender()
    render.SetLightingMode( 1 )
    -- render.SuppressEngineLighting(true)
    render.SetShadowColor(255, 0, 0)
    render.SetColorModulation(0.5, 0, 0)
    self.LightingModeChanged = true
    -- render.SetShadowsDisabled(true)
end

CLASS:HookOwner("PreRender", CLASS.PreRender)
CLASS:HookOwner("PostRender", CLASS.HookDisappear)
CLASS:HookOwner("PreDrawHUD", CLASS.HookDisappear)


CLASS:HookOwner("RenderScene", function (self, ...)
    -- print("10")
    -- render.SetLightingMode(0)
end)


function CLASS:StartCommand(ply, cmd)
    if ply:IsOnGround() then
        if cmd:KeyDown(IN_SPEED) and cmd:KeyDown(IN_JUMP) and self:PlayerCooldown(ply, "Jump", 2) then
            set_data(ply, "ShouldJump", true)
        end
    end
end

local color_red = Color(255, 0, 0, 20)
CLASS:HookOwner("HUDPaint", function (self, ...)
    local W, H = ScrW(), ScrH()

    draw.Box(0,0,W,H, color_red)
end)

CLASS:HookServer("GetFallDamage", function (self, ply)
    if self:IsTeamMate(ply) then return 0 end
end)

function CLASS:OnJoin(ply)
    if SERVER then
        ply:SetModel("models/player/zombie_fast.mdl")
        ply:EmitSound("npc/zombie/claw_strike1.wav")
    end
end

function CLASS:OnSpawn(ply)
    print("Zombie spawned", ply)
end

function CLASS:OnDeath(ply)
    print("Zombie death", ply)
end

function CLASS:SetupMove(ply, mv, cmd)
    local move_angles = mv:GetMoveAngles()
    local vel = mv:GetVelocity()

    if mv:KeyDown(IN_SPEED) and ply:IsOnGround() then
        local forward_speed = mv:GetForwardSpeed()
        if forward_speed > 0 then
            mv:SetVelocity(vel + move_angles:Forward() * 200)
        end
    end

    if mv:KeyDown(IN_SPEED) and mv:KeyDown(IN_FORWARD) then

        if IsWallNear(ply, mv, cmd) then
            local trace, normal = ClimpTrace(ply, mv, cmd)

            if trace.HitWorld then
                mv:SetVelocity(normal)
                set_data(ply, "Climbing", true)
            else
                set_data(ply, "Climbing", false)
            end
        else
            set_data(ply, "Climbing", false)
        end
    else
        set_data(ply, "Climbing", false)
    end
end

function CLASS:Move(ply, mv, cmd)

    if get_data(ply, "Jumped") and ply:IsOnGround() then
        set_data(ply, "Jumped", nil)
    end
end

function CLASS:FinishMove(ply, mv)

    if SERVER and get_data(ply, "ShouldJump") then
        set_data(ply, "ShouldJump", nil)

        local direct = ply:EyeAngles():Forward()
        -- direct.z = math.max(direct.z, 0.2)
        ply:SetPos(ply:GetPos() + Vector(0,0,15))
        ply:SetVelocity(direct * 1000)
        ply:EmitSound("npc/fast_zombie/fz_scream1.wav")

        set_data(ply, "Jumped", true)
    end

end

function CLASS:CalcView(ply, origin, angles, znear, zfar)
    if ply:GetViewEntity() != ply then return end

    local ply_pos = ply:GetPos()
    -- print("calcView")
    return {
        origin = ply_pos + Vector(0,0,50) + angles:Forward() * -70,
        drawviewer = true
    }
end

function CLASS:CalcMainActivity(ply, vel)
    local move_type = ply:GetMoveType()

    local speed = math.abs(vel:Length())

    if move_type == MOVETYPE_NOCLIP then
        return ACT_HL2MP_SWIM_MAGIC, -1
    elseif move_type == MOVETYPE_WALK then

        local ply_flying = ply:WaterLevel() <= 0 and !ply:IsOnGround()

        if get_data(ply, "Climbing") then
            return ACT_ZOMBIE_CLIMB_UP, -1
        end

        if ply_flying then
            local _, cycle = math.modf(CurTime() * 3)
            ply:SetCycle(cycle)
            return ACT_ZOMBIE_LEAPING, -1
        end



        if ply:WaterLevel() >= 2 then
            return ACT_HL2MP_SWIM_FIST, -1
        end

        if !ply:IsOnGround() then -- IN AIR
            return ACT_HL2MP_WALK_ZOMBIE_06, -1
        end

        if speed <= 0 then
            if ply:Crouching() then
                return ACT_HL2MP_IDLE_CROUCH_ZOMBIE, -1
            else
                return ACT_HL2MP_IDLE_ZOMBIE, -1
            end
        elseif speed < 200 then
            return ACT_HL2MP_WALK_ZOMBIE_06, -1
        else
            return ACT_HL2MP_RUN_ZOMBIE_FAST, -1
        end
    end

    return ACT_MP_STAND_IDLE, -1
end

player_mode.Register(CLASS)


-- /*
if SERVER then
    icmd.Register("be_zombie", function(QCMD, who)
        player_mode.SetMode(who, "zombie")

    end)
    icmd.Register("be_normal", function(QCMD, who)
        player_mode.SetMode(who, "default")

    end)
end
-- */