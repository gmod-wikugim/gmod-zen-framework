module("zen")

icon_generation = _GET("icon_generation")

local weapon_material = "models/debug/debugwhite"

local wireframe_mat = Material(weapon_material)

-- Generate PNG Data for a given entity class
---@overload fun(weapon_class: string, callback: fun(success: true, png_data: string))
---@overload fun(weapon_class: string, callback: fun(success: false, err: string))
function icon_generation.generateWeapon(weapon_class, callback)
    callback = callback or function(succ, data)
        if !succ then
            print("icon_generation.generateWeapon: Failed to generate icon for weapon class " .. tostring(weapon_class) .. ": " .. tostring(data))
        end
    end

    local SWEP = weapons.GetStored(weapon_class)
    if !SWEP then
        callback(false, "Weapon table not found for class " .. tostring(weapon_class))
        return
    end

    local WorldModel = SWEP.WorldModel
    if type(WorldModel) != "string" or WorldModel == "" then
        callback(false, "WorldModel not defined for weapon class " .. tostring(weapon_class))
        return
    end

    local CSEnt = ents.CreateClientProp(WorldModel)
    if !IsValid(CSEnt) then
        callback(false, "Failed to create clientside entity for model " .. tostring(WorldModel))
        return
    end

    icon_generation.LastCreatedEntity = CSEnt

    SafeRemoveEntityDelayed(CSEnt, 1)

    local phys = CSEnt:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    CSEnt:SetMaterial(weapon_material)
    CSEnt:DrawShadow(false)
    CSEnt:SetupBones()
    CSEnt:SetNoDraw(true)

    local _mins, _maxs = CSEnt:GetRenderBounds()
    local _middle = (_mins + _maxs) / 2

    local wep_origin = _middle
    local wep_angles = Angle(0,0,0)


    local size = 0
    for i = 1, 3 do
        size = math.max(size, math.abs(_mins[i]) + math.abs(_maxs[i]) + math.abs(_middle[i]))
    end

    size = math.max(size, 50)


    local cam_pos = wep_origin + Vector(0, size/1.5, 0)
    local cam_ang = (wep_origin - cam_pos):Angle()


    local CAM = {}
    CAM.type = "3D"
    CAM.fov = 70
    CAM.znear = 1
    CAM.zfar = 1000
    CAM.origin = cam_pos
    CAM.angles = cam_ang
    CAM.subrect = true

    CAM.x = 0
    CAM.y = 0
    CAM.w = 500
    CAM.h = 300

    CAM.aspect = CAM.w / CAM.h


    cam.Start(CAM)
        render.Clear(0,0,0, 0, true, true)

        render.SuppressEngineLighting( true )
        render.OverrideAlphaWriteEnable(true, true)
        render.SetWriteDepthToDestAlpha( false )

        render.ModelMaterialOverride(wireframe_mat)

        CSEnt:SetMaterial(weapon_material)
        CSEnt:DrawModel()
        CSEnt:FrameAdvance()


        local PNG = render.Capture({
            format = "png",
            quality = 100,
            x = 0,
            y = 0,
            w = CAM.w,
            h = CAM.h,
        })

        render.SuppressEngineLighting( false )
        render.OverrideAlphaWriteEnable(false, false)
        render.ModelMaterialOverride(nil)
        render.SetWriteDepthToDestAlpha(true)


        callback(true, PNG)
    cam.End()
end


---@param weapon_class string
---@param callback fun(mat: IMaterial?)
function icon_generation.CreateMaterialForWeapon(weapon_class, callback)
    local mat_path = "icon_generation/" .. weapon_class .. ".png"

    -- Check file exists then load it and file length less 1 day
    if file.Exists(mat_path, "DATA") and file.Time(mat_path, "DATA") > (os.time() - 86400) then
        callback( Material("data/" .. mat_path, "smooth") )
        return
    end



    icon_generation.generateWeapon(weapon_class, function(succ, data)
        if succ then
            -- CreateDir if it doesn't exist
            if file.IsDir("icon_generation", "DATA") != true then
                file.CreateDir("icon_generation")
            end


            file.Write(mat_path, data)

            if callback then
                callback( Material("data/" .. mat_path, "smooth") )
            end
        else
            print("Failed to generate icon for weapon class " .. tostring(weapon_class) .. ": " .. tostring(data))
            callback(nil)
        end
    end)
end