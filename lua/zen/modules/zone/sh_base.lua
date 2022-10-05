local zone = zen.Init("zone")

zone.t_Zones = zone.t_Zones or {}
zone.t_ZonesBoxes = zone.t_ZonesBoxes or {}
zone.t_ZonesSphere = zone.t_ZonesSphere or {}
zone.t_EntitityClasses = zone.t_EntitityClasses or {}
zone.t_EntitityZones = zone.t_EntitityZones or {}

local zones = zone.t_Zones
local box_zones = zone.t_ZonesBoxes
local sphere_zones = zone.t_ZonesSphere
local zones_entities = zone.t_EntitityZones

local ent_classes = zone.t_EntitityClasses

local ents_FindInSphere = ents.FindInSphere
local ents_FindInBox = ents.FindInBox
local SysTime = SysTime
local GetClass = META.ENTITY.GetClass
local pairs = pairs
local GetSolid = META.ENTITY.GetSolid
local GetCollisionGroup = META.ENTITY.GetCollisionGroup
local SOLID_NONE = SOLID_NONE
local IsSolid = META.ENTITY.IsSolid
local SysTime = SysTime
local render_DrawSphere = render.DrawSphere
local render_DrawBox = render.DrawBox
local render_SetColorModulation = render.SetColorModulation
local render_SetColorMaterial = render.SetColorMaterial
local ErrorNoHaltWithStack = ErrorNoHaltWithStack

function zone.RemoveZone(uniqueID)
    local ZONE = zones[uniqueID]
    if ZONE then
        local entities = ZONE.entities

        for ent in pairs(entities) do
            zone.OnEntityExit(ZONE, uniqueID, ent)
        end

        if IsValid(ZONE.ent) then ZONE.ent:Remove() end

        ZONE = nil
        zone.t_ZonesBoxes[uniqueID] = nil
        zone.t_ZonesSphere[uniqueID] = nil
    end
end

function zone.InitEmpty(uniqueID)
    if zones[uniqueID] then zone.RemoveZone(uniqueID) end

    local ZONE = {
        uniqueID = uniqueID,
        entities = {},
        class_entities = {},
        class_counter = {},
        solid_entities = {},
        collision_entities = {},
        onJoin = function() end,
        onJoinSolid = function() end,
        onJoinCollision = function() end,
        onExit = function() end,
        onExitSolid = function() end,
        onExitCollision = function() end,
    }
    zone.t_Zones[uniqueID] = ZONE

    if CLIENT_DLL then
        ZONE.ent = ents.CreateClientside("base_anim")
    elseif SERVER then
        ZONE.ent = ents.Create("base_anim")
    end

    if IsValid(ZONE.ent) then
        ZONE.ent.zen_IsZone = true
        zones_entities[ZONE.ent] = uniqueID
    end

    return zone.t_Zones[uniqueID]
end

function zone.InitBox(uniqueID, vec_min, vec_max)
    local ZONE = zone.InitEmpty(uniqueID)
    ZONE.vec_min = vec_min
    ZONE.vec_max = vec_max
    ZONE.origin = (vec_min + vec_max)/2

    zone.t_ZonesBoxes[uniqueID] = ZONE
    zone.t_ZonesSphere[uniqueID] = nil

    return ZONE
end

function zone.InitSphere(uniqueID, origin, radius)
    local ZONE = zone.InitEmpty(uniqueID)
    ZONE.origin = origin
    ZONE.radius = radius

    zone.t_ZonesBoxes[uniqueID] = nil
    zone.t_ZonesSphere[uniqueID] = ZONE

    ZONE.vertices = util.GetIcoSphereVertex(radius, 2)

    if CLIENT then
        ZONE.Mesh = Mesh()
        ZONE.Mesh:BuildFromTriangles(ZONE.vertices)
    end

    if IsValid(ZONE.ent) then
        local ent = ZONE.ent
        ent:SetAngles(angle_zero)
        ent:SetPos(origin)

        if SERVER then
            ent:SetUseType(SIMPLE_USE)
        end
        if CLIENT then
            function ent:Draw()
            -- self:DrawModel()
            end
        end

        ent:SetNoDraw(true)

        ent:SetModel( "models/combine_helicopter/helicopter_bomb01.mdl" )
        ent:PhysicsInit(SOLID_VPHYSICS);

        ent:PhysicsInitConvex( ZONE.vertices )


        ent:SetMoveType(MOVETYPE_NONE)
        local phys = ent:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:SetMaterial("default_silent");
            phys:EnableMotion(false)
        end

		-- ent:SetCustomCollisionCheck(true);
		ent:EnableCustomCollisions(true);

        ent:Spawn()
        -- ent:Activate()
    end

    return ZONE
end

local RunSecure = ihook.RunSecure

function zone.OnEntityJoin(ZONE, uniqueID, ent)
    local ent_class = GetClass(ent)
    local ent_solid = GetSolid(ent)
    local ent_collision = GetCollisionGroup(ent)

    local class_entities = ZONE.class_entities
    local class_counter = ZONE.class_counter
    local solid_entities = ZONE.solid_entities
    local collision_entities = ZONE.collision_entities

    local zone_collision = ZONE.CollisionGroup

    if not class_entities[ent_class] then
        class_entities[ent_class] = {}
        class_counter[ent_class] = 0
    end
    class_entities[ent_class][ent] = SysTime()
    class_counter[ent_class] = class_counter[ent_class] + 1

    ent_classes[ent] = ent_class

    local isSolid
    if IsSolid(ent) then
        solid_entities[ent] = SysTime()
        isSolid = true
    end

    local isCollision
    if zone_collision == ent_collision then
        collision_entities[ent] = SysTime()
        isCollision = true
    end

    RunSecure('zen.zone.OnEntityJoin', ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityJoin.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityJoinClass', ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityJoinClass.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    if isSolid then
        RunSecure('zen.zone.OnEntityJoinSolid', ZONE, uniqueID, ent, ent_class)
        RunSecure('zen.zone.OnEntityJoinSolid.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    end
    if isCollision then
        RunSecure('zen.zone.OnEntityJoinCollision', ZONE, uniqueID, ent, ent_class)
        RunSecure('zen.zone.OnEntityJoinCollision.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    end

    xpcall(ZONE.onJoin, ErrorNoHaltWithStack, ZONE, ent, ent_class)
    xpcall(ZONE.onJoinSolid, ErrorNoHaltWithStack, ZONE, ent, ent_class)
    xpcall(ZONE.onJoinCollision, ErrorNoHaltWithStack, ZONE, ent, ent_class)
end

function zone.OnEntityExit(ZONE, uniqueID, ent)
    local ent_class = ent_classes[ent]
    ent_classes[ent] = nil

    local class_entities = ZONE.class_entities
    local class_counter = ZONE.class_counter
    local solid_entities = ZONE.solid_entities
    local collision_entities = ZONE.collision_entities

    class_entities[ent_class][ent] = nil
    class_counter[ent_class] = class_counter[ent_class] - 1

    local isSolid
    if solid_entities[ent] then
        solid_entities = nil
    end

    local isCollision
    if collision_entities[ent] then
        isCollision = true
    end


    RunSecure('zen.zone.OnEntityExit', ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityExit.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityExitClass', ZONE, uniqueID, ent, ent_class)
    RunSecure('zen.zone.OnEntityExitClass.' .. ent_class, ZONE, uniqueID, ent, ent_class)
    if isSolid then
        RunSecure('zen.zone.OnEntityExitSolid', ZONE, uniqueID, ent, ent_class)
        RunSecure('zen.zone.OnEntityExitSolid.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    end
    if isCollision then
        RunSecure('zen.zone.OnEntityJoinCollision', ZONE, uniqueID, ent, ent_class)
        RunSecure('zen.zone.OnEntityJoinCollision.' .. uniqueID, ZONE, uniqueID, ent, ent_class)
    end

    xpcall(ZONE.onExit, ErrorNoHaltWithStack, ZONE, ent, ent_class)
    xpcall(ZONE.onExitSolid, ErrorNoHaltWithStack, ZONE, ent, ent_class)
    xpcall(ZONE.onExitCollision, ErrorNoHaltWithStack, ZONE, ent, ent_class)
end

ihook.Handler("Think", "zen.Zones.Box", function()
    for k, ZONE in pairs(box_zones) do
        local zone_entities = ZONE.entities
        local uniqueID = ZONE.uniqueID

        local result = ents_FindInBox(ZONE.vec_min, ZONE.vec_max)

        local done = {}

        for k, ent in pairs(result) do
            done[ent] = true
            if zone_entities[ent] then continue end

            zone.OnEntityJoin(ZONE, uniqueID, ent)
            zone_entities[ent] = SysTime()
        end

        for ent in pairs(zone_entities) do
            if done[ent] then continue end

            zone.OnEntityExit(ZONE, uniqueID, ent)
            zone_entities[ent] = nil
        end
    end
end)

ihook.Handler("Think", "zen.Zones.Sphere", function()
    for k, ZONE in pairs(sphere_zones) do
        local zone_entities = ZONE.entities
        local uniqueID = ZONE.uniqueID

        local result = ents_FindInSphere(ZONE.origin, ZONE.radius)

        local done = {}

        for k, ent in pairs(result) do
            done[ent] = true
            if zone_entities[ent] then continue end

            zone.OnEntityJoin(ZONE, uniqueID, ent)
            zone_entities[ent] = SysTime()
        end

        for ent in pairs(zone_entities) do
            if done[ent] then continue end

            zone.OnEntityExit(ZONE, uniqueID, ent)
            zone_entities[ent] = nil
        end
    end
end)


if CLIENT then
    local color_white = Color(255,255,255,20)
    local angle_zero = angle_zero
    local render_DrawWireframeSphere = render.DrawWireframeSphere

    ihook.Listen("PostDrawTranslucentRenderables", "zen.zone.drawZones", function()
        render_SetColorModulation(1,1,1)
        render_SetColorMaterial()

        for k, ZONE in pairs(box_zones) do
            render_DrawBox(ZONE.origin, angle_zero, ZONE.vec_min, ZONE.vec_max, color_white)
        end
        for k, ZONE in pairs(sphere_zones) do
            render_DrawSphere(ZONE.origin, ZONE.radius, 21, 21, color_white)
            render_DrawSphere(ZONE.origin, -ZONE.radius, 21, 21, color_white)
            -- local origin = ZONE.origin
            -- for k, pos in pairs(ZONE.vertices) do
            --     render_DrawWireframeSphere(origin+pos, 1, 5, 5)
            -- end
        end
    end)
end
