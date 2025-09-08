module("zen")

icon_generation = _GET("icon_generation")

local weapon_material = "models/debug/debugwhite"

local wireframe_mat = Material(weapon_material)

-- Generate PNG Data for a given entity class
---@overload fun(weapon_class: string, callback: fun(success: true, png_data: string))
---@overload fun(weapon_class: string, callback: fun(success: false, err: string))
function icon_generation.generateWeapon(weapon_class, callback, GenerationSettings)
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

    local render_id = "icon_generation_rt_" .. weapon_class
    hook.Add("PostRender", render_id, function()
        if gui.IsGameUIVisible() then return end

        hook.Remove("PostRender", render_id)

        GenerationSettings = GenerationSettings or {}

        local CSEnt

        if GenerationSettings.CSEnt then
            CSEnt = GenerationSettings.CSEnt
        else
            CSEnt = ents.CreateClientProp(WorldModel)
            if IsValid(CSEnt) then
                SafeRemoveEntityDelayed(CSEnt, 5)

                local phys = CSEnt:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                end

                -- CSEnt:SetPos(VectorRand(-10000, 10000))
                -- CSEnt:SetAngles(AngleRand(-360, 360))

                CSEnt:DrawShadow(false)
                CSEnt:SetupBones()
                CSEnt:SetNoDraw(true)
            end
        end

        if !IsValid(CSEnt) then
            callback(false, "Failed to create clientside entity for model " .. tostring(WorldModel))
            return
        end

        GenerationSettings.fov = GenerationSettings.fov or 70

        local _mins, _maxs = CSEnt:GetRenderBounds()
        local _middle = (_mins + _maxs) / 2

        local wep_origin = CSEnt:GetPos()
        local wep_angles = CSEnt:GetAngles()

        local size = 0
        for i = 1, 3 do
            size = math.max(size, math.abs(_mins[i]) + math.abs(_maxs[i]) + math.abs(_middle[i]))
        end

        size = math.max(size, 50)


        local cam_pos = wep_origin + wep_angles:Right() * -50

        if GenerationSettings.OffsetRight then
            cam_pos = cam_pos + wep_angles:Right() * GenerationSettings.OffsetRight
        end
        if GenerationSettings.OffsetUp then
            cam_pos = cam_pos + wep_angles:Up() * GenerationSettings.OffsetUp
        end
        if GenerationSettings.OffsetForward then
            cam_pos = cam_pos + wep_angles:Forward() * GenerationSettings.OffsetForward
        end

        -- Get cam_ang from cam_pos and wep_origin and wep_angles to look at wep_origin with correct up vector
        local cam_ang = Angle(wep_angles)
        cam_ang:RotateAroundAxis(cam_ang:Up(), -90)

        local CAM = {}
        CAM.type = "3D"
        CAM.fov = GenerationSettings.fov
        CAM.znear = 1
        CAM.zfar = 1000
        CAM.origin = cam_pos
        CAM.angles = cam_ang
        CAM.subrect = false

        CAM.x = 0
        CAM.y = 0
        CAM.w = 500
        CAM.h = 300

        CAM.aspect = CAM.w / CAM.h


        local texture = GetRenderTargetEx("icon_generation_rt_",
            CAM.w, CAM.h,
            RT_SIZE_NO_CHANGE, -- Just no touch anything
            MATERIAL_RT_DEPTH_SHARED, -- Alpha use multiply alpha object. If any bags then change to --> MATERIAL_RT_DEPTH_SEPARATE --> MATERIAL_RT_DEPTH_ONLY
            1 + 256, -- Best Combo to enable high-equility screenshot
            0, -- Dont tested
            IMAGE_FORMAT_RGBA16161616 -- Allow use more colors in game. Default game colors is restricted!
        )

        render.PushRenderTarget(texture)
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


            cam.End()
        render.PopRenderTarget()

        if !PNG then
            callback(false, "Failed to capture render for weapon class " .. tostring(weapon_class))
        else
            callback(true, PNG)
        end

    end)

end

---@param weapon_class string
---@param callback fun(mat: IMaterial?)
function icon_generation.CreateMaterialForWeapon(weapon_class, callback, GenerationSettings, RefreshIcon)
    local mat_path = "icon_generation/" .. weapon_class .. ".png"

    -- Check file exists then load it and file length less 1 day
    if !RefreshIcon and file.Exists(mat_path, "DATA") and file.Time(mat_path, "DATA") > (os.time() - 86400) then
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
                local mat = Material("data/" .. mat_path, "smooth")
                mat:Recompute()
                RunConsoleCommand("mat_reloadtexture", mat:GetName("$basetexture"))
                callback( mat )
            end
        else
            print("Failed to generate icon for weapon class " .. tostring(weapon_class) .. ": " .. tostring(data))
            callback(nil)
        end
    end, GenerationSettings)
end

hook.Run("icon_generation_loaded")