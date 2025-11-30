module("zen")

---@class zen.icon_generation
icon_generation = _GET("icon_generation")


local PANEL = FindMetaTable("Panel") --[[@class Panel]]

local TEXTURE = FindMetaTable("ITexture") --[[@class ITexture]]
local TEXTURE_GetName = TEXTURE.GetName

local format = string.format
local GetRenderTargetEx = GetRenderTargetEx

local render_PushRenderTarget = render.PushRenderTarget
local render_PopRenderTarget = render.PopRenderTarget

local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local render_Clear = render.Clear
local render_ClearDepth = render.ClearDepth

local render_SetWriteDepthToDestAlpha = render.SetWriteDepthToDestAlpha

local render_OverrideBlend = render.OverrideBlend

local BLENDFUNC_MIN = BLENDFUNC_MIN
local BLENDFUNC_ADD = BLENDFUNC_ADD
local BLEND_SRC_COLOR = BLEND_SRC_COLOR
local BLEND_SRC_ALPHA = BLEND_SRC_ALPHA

local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect

local TEXTURE_PATTERN = "icon_generation/%s_%d_%d_%d_%d_%d_%d_%d"
local TEXTURE_MATERIAL_PATTERN = "materials/%s"

local TEXTURE_FLAGS = bit.bor(4, 8, 16, 32, 512, 8192, 32768)
local IMAGE_FORMAT = bit.bor(IMAGE_FORMAT_RGBA8888)

local SIZE_MODE = RT_SIZE_NO_CHANGE
local DEPTH_MODE = MATERIAL_RT_DEPTH_SEPARATE
local TEXTURE_FLAGS = TEXTURE_FLAGS
local RT_FLAGS = 0

local function GetTextureRT(textureID, width, height, size_mode, depth_mode, texture_flags, rt_flags, image_format)

    local full_textureID = format(TEXTURE_PATTERN, textureID, width, height, size_mode or SIZE_MODE, depth_mode or DEPTH_MODE, texture_flags or TEXTURE_FLAGS, rt_flags or RT_FLAGS, image_format or IMAGE_FORMAT)

    local texture = GetRenderTargetEx(full_textureID,
        width, height,
        SIZE_MODE,
        DEPTH_MODE,
        TEXTURE_FLAGS,
        RT_FLAGS,
        IMAGE_FORMAT
    )

    return texture, full_textureID
end


local function GetTextureMaterial(textureID, width, height, size_mode, depth_mode, texture_flags, rt_flags, image_format)
    local texture, full_textureID = GetTextureRT(textureID, width, height, size_mode, depth_mode, texture_flags, rt_flags, image_format)

    local MaterialName = format(TEXTURE_MATERIAL_PATTERN, full_textureID)

    local MAT_FROM_TEXTURE = CreateMaterial(MaterialName, "UnlitGeneric", {
        ["$basetexture"] = TEXTURE_GetName(texture),
        ["$ignorez"] = "1",
        ["$translucent"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
    })

    return texture, MAT_FROM_TEXTURE
end



---@class zen.icon_generation.GenerationSettings
---@field CSEnt CSEnt?
---@field id string? Unique identifier for the icon generation settings
---@field model string?
---@field bodygroups string?
---@field skin number?
---@field fov number?
---@field AddFOV number?
---@field OffsetRight number?
---@field OffsetUp number?
---@field OffsetForward number?
---@field RotateRight number?
---@field RotateUp number?
---@field RotateForward number?
---@field bThisDebug boolean?
---@field bThisSetup boolean?
---@field LifeTime number? Time in seconds before the generated icon is considered stale and needs regeneration
---@field CamaraPosition Vector?
---@field CamaraAngles Angle?
---@field width number?
---@field height number?
---@field lookAt Vector?
---@field PreDrawModel fun(CSEnt: CSEnt, cam_pos: Vector, cam_ang: Angle)?
---@field PostDrawModel fun(CSEnt: CSEnt, cam_pos: Vector, cam_ang: Angle)?

-- Generate PNG Data for a given entity class
---@overload fun(GenerationSettings: zen.icon_generation.GenerationSettings, callback: fun(succ: true, renderTexture: ITexture, renderMaterial: IMaterial))
---@overload fun(GenerationSettings: zen.icon_generation.GenerationSettings, callback: fun(succ: false, errMsg: string))
function icon_generation.GenerateTexture(GenerationSettings, callback)
    callback = callback or function(succ, data)
        if !succ then
            print("icon_generation.generateWeapon: Failed to generate icon " .. tostring(data))
        end
    end

    -- Check CSEnt or model defined
    if !GenerationSettings.CSEnt and (type(GenerationSettings.model) != "string" or GenerationSettings.model == "") then
        callback(false, "Either CSEnt or model must be defined in GenerationSettings")
        return
    end

    -- Default values
    GenerationSettings.id = GenerationSettings.id or "default"
    GenerationSettings.width = GenerationSettings.width or 512
    GenerationSettings.height = GenerationSettings.height or 512

    local CSEnt = GenerationSettings.CSEnt

    if CSEnt == nil then
        CSEnt = ents.CreateClientProp(GenerationSettings.model)

        if IsValid(CSEnt) then
            SafeRemoveEntityDelayed(CSEnt, 10)

            local phys = CSEnt:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end

            -- CSEnt:SetPos(Vector(0,0,0))
            -- CSEnt:SetAngles(AngleRand(-360, 360))

            CSEnt:DrawShadow(false)
            CSEnt:SetupBones()
            CSEnt:SetNoDraw(true)

            if GenerationSettings.bodygroups then
                CSEnt:SetBodygroups(GenerationSettings.bodygroups)
            end

            if GenerationSettings.skin then
                CSEnt:SetSkin(GenerationSettings.skin)
            end

        else
            callback(false, "Failed to create clientside entity for model " .. tostring(GenerationSettings.model))
            return
        end
    end

    GenerationSettings.fov = GenerationSettings.fov or 70

    if GenerationSettings.AddFOV then
        GenerationSettings.fov = GenerationSettings.fov - GenerationSettings.AddFOV
    end

    local DEBUG = GenerationSettings.bThisDebug == true
    local SETUP = GenerationSettings.bThisSetup == true
    local DEBUG_OR_SETUP = DEBUG or SETUP

    local UniqueID = string.format("%p_%s", CSEnt, GenerationSettings.id)


    local RenderTexture, RenderMaterial = GetTextureMaterial(UniqueID, GenerationSettings.width, GenerationSettings.height)

    render_PushRenderTarget(RenderTexture)
        render_Clear(0,0,0,0)
        render_ClearDepth(true)

        if !IsValid(CSEnt) then
            callback(false, "Failed to create clientside entity")
            return
        end

        local _mins, _maxs = CSEnt:GetRenderBounds()
        local _middle = (_mins + _maxs) / 2

        local entity_origin = CSEnt:GetPos()
        local entity_angles = CSEnt:GetAngles()

        local size = 0
        for i = 1, 3 do
            size = math.max(size, math.abs(_mins[i]) + math.abs(_maxs[i]) + math.abs(_middle[i]))
        end

        size = math.max(size, 50)

        local DefaultRotate = Angle(entity_angles)

        if GenerationSettings.RotateRight then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Right(), GenerationSettings.RotateRight)
        end
        if GenerationSettings.RotateUp then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Up(), GenerationSettings.RotateUp)
        end
        if GenerationSettings.RotateForward then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Forward(), GenerationSettings.RotateForward)
        end

        local custom_middle_position = Vector(entity_origin)
        if GenerationSettings.OffsetRight then
            custom_middle_position = custom_middle_position + entity_angles:Right() * GenerationSettings.OffsetRight
        end
        if GenerationSettings.OffsetUp then
            custom_middle_position = custom_middle_position + entity_angles:Up() * GenerationSettings.OffsetUp
        end
        if GenerationSettings.OffsetForward then
            custom_middle_position = custom_middle_position + entity_angles:Forward() * GenerationSettings.OffsetForward
        end

        local cam_pos = (custom_middle_position) + DefaultRotate:Right() * 50

        local cam_ang = (custom_middle_position - cam_pos):AngleEx(entity_angles:Up())

        if GenerationSettings.CamaraPosition then
            cam_pos = GenerationSettings.CamaraPosition
        end

        if GenerationSettings.CamaraAngles then
            cam_ang = GenerationSettings.CamaraAngles
        elseif GenerationSettings.lookAt then
            cam_ang = (GenerationSettings.lookAt - cam_pos):Angle()
        end

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
        CAM.w = GenerationSettings.width
        CAM.h = GenerationSettings.height

        CAM.aspect = CAM.w / CAM.h


        cam.Start(CAM)

            render.SuppressEngineLighting( true )
            render.OverrideAlphaWriteEnable(true, true)
            render.SetWriteDepthToDestAlpha( false )

            if GenerationSettings.PreDrawModel then
                GenerationSettings.PreDrawModel(CSEnt, cam_pos, cam_ang)
            end

            CSEnt:DrawModel()
            CSEnt:FrameAdvance()

            if GenerationSettings.PostDrawModel then
                GenerationSettings.PostDrawModel(CSEnt, cam_pos, cam_ang)
            end

            if SETUP then
                render.SetColorMaterial()
                render.DrawSphere(custom_middle_position, 2, 20, 20, Color(0,255,0,200))
                render.DrawWireframeSphere(custom_middle_position, 5, 20, 20, Color(255,0,0,200))
            end

            render.SuppressEngineLighting( false )
            render.OverrideAlphaWriteEnable(false, false)
            render.SetWriteDepthToDestAlpha(true)

        cam.End()

    render_PopRenderTarget()

    callback(true, RenderTexture, RenderMaterial)


    /*
    hook.Add("PostRender", render_id, function()
        if gui.IsGameUIVisible() then return end

        if !GenerationSettings.bThisDebug then
            hook.Remove("PostRender", render_id)
        end

        if !IsValid(CSEnt) then
            hook.Remove("PostRender", render_id)
            callback(false, "Failed to create clientside entity for model " .. tostring(WorldModel))
            return
        end

        local _mins, _maxs = CSEnt:GetRenderBounds()
        local _middle = (_mins + _maxs) / 2

        local entity_origin = CSEnt:GetPos()
        local entity_angles = CSEnt:GetAngles()

        local size = 0
        for i = 1, 3 do
            size = math.max(size, math.abs(_mins[i]) + math.abs(_maxs[i]) + math.abs(_middle[i]))
        end

        size = math.max(size, 50)

        local DefaultRotate = Angle(entity_angles)

        if GenerationSettings.RotateRight then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Right(), GenerationSettings.RotateRight)
        end
        if GenerationSettings.RotateUp then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Up(), GenerationSettings.RotateUp)
        end
        if GenerationSettings.RotateForward then
            DefaultRotate:RotateAroundAxis(DefaultRotate:Forward(), GenerationSettings.RotateForward)
        end

        local custom_middle_position = Vector(entity_origin)
        if GenerationSettings.OffsetRight then
            custom_middle_position = custom_middle_position + entity_angles:Right() * GenerationSettings.OffsetRight
        end
        if GenerationSettings.OffsetUp then
            custom_middle_position = custom_middle_position + entity_angles:Up() * GenerationSettings.OffsetUp
        end
        if GenerationSettings.OffsetForward then
            custom_middle_position = custom_middle_position + entity_angles:Forward() * GenerationSettings.OffsetForward
        end

        local cam_pos = (custom_middle_position) + DefaultRotate:Right() * 50

        local cam_ang = (custom_middle_position - cam_pos):AngleEx(entity_angles:Up())

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

        local DEBUG = GenerationSettings.bThisDebug == true
        local SETUP = GenerationSettings.bThisSetup == true
        local DEBUG_OR_SETUP = DEBUG or SETUP


        if DEBUG then
            cam.Start3D()
        else
            render.PushRenderTarget(texture)
            cam.Start(CAM)
            render.Clear(0,0,0, 0, true, true)
        end
                render.SuppressEngineLighting( true )
                render.OverrideAlphaWriteEnable(true, true)
                render.SetWriteDepthToDestAlpha( false )

                render.ModelMaterialOverride(wireframe_mat)



                CSEnt:SetMaterial(weapon_material)
                CSEnt:DrawModel()
                CSEnt:FrameAdvance()

                if DEBUG_OR_SETUP then
                    render.DrawWireframeSphere(custom_middle_position, 2, 20, 20, Color(0,255,0,100), true)
                    render.DrawWireframeSphere(custom_middle_position, 5, 20, 20, Color(255,0,0,100), true)
                end


                if DEBUG then
                    render.DrawWireframeSphere(cam_pos, 5, 4, 4, color_white, true)
                    render.DrawLine(cam_pos, custom_middle_position)

                    -- Draw Cam Angles
                    render.DrawLine(cam_pos, cam_pos + cam_ang:Forward() * 20, Color(255,0,0))
                    render.DrawLine(cam_pos, cam_pos + cam_ang:Right() * 20, Color(0,255,0))
                    render.DrawLine(cam_pos, cam_pos + cam_ang:Up() * 20, Color(0,0,255))
                end

                local PNG
                if !DEBUG then
                    PNG = render.Capture({
                        format = "png",
                        quality = 100,
                        x = 0,
                        y = 0,
                        w = CAM.w,
                        h = CAM.h,
                    })
                end

                render.SuppressEngineLighting( false )
                render.OverrideAlphaWriteEnable(false, false)
                render.ModelMaterialOverride(nil)
                render.SetWriteDepthToDestAlpha(true)
            if DEBUG then
                cam.End()
            else
                cam.End()
                render.PopRenderTarget()
            end

        if !PNG then
            callback(false, "Failed to capture render for weapon class " .. tostring(weapon_class))
        else
            callback(true, PNG)
        end

    end)
    */

end

---@param weapon_class string
---@param callback fun(mat: IMaterial?)
function icon_generation.CreateMaterialForWeapon(weapon_class, callback, GenerationSettings, RefreshIcon)
    local mat_path = "icon_generation/" .. weapon_class .. ".png"

    GenerationSettings = GenerationSettings or {}

    if RefreshIcon then
        GenerationSettings.LifeTime = -1
    end

    icon_generation.generateWeapon(weapon_class, function(succ, mat)
        if succ then
            callback( mat )
        else
            print("Failed to generate icon for weapon class " .. tostring(weapon_class))
            callback(nil)
        end
    end, GenerationSettings)
end

-- Concommand to test icon generation, with drawing result
concommand.Add("zen_test_icon_generation", function()
    local Frame = vgui.Create("DFrame")
    Frame:SetSize(600, 600)
    Frame:Center()
    Frame:MakePopup()

    local IconPanel = vgui.Create("DPanel", Frame)
    IconPanel:Dock(FILL)
    IconPanel.Paint = nil


    icon_generation.GenerateTexture({
        model = "models/props_c17/display_cooler01a.mdl",
        fov = 90,
        OffsetForward = 40,
        OffsetUp = 0,
        OffsetRight = 40,
        bThisDebug = true,
    }, function (succ, renderTexture, renderMaterial)
        if succ then
            IconPanel.Paint = function(self, w, h)
                surface_SetDrawColor(255, 255, 255, 255)
                surface_SetMaterial(renderMaterial)
                surface_DrawTexturedRect(0, 0, w, h)
            end
        else
            print("Failed to generate icon: " .. tostring(renderTexture))
        end
    end)

    local IconPanel2 = vgui.Create("DPanel", Frame)
    IconPanel2:Dock(FILL)
    IconPanel2.Paint = nil

    icon_generation.GenerateTexture({
        model = "models/weapons/w_pistol.mdl",
        fov = 90,
        OffsetForward = 20,
        OffsetUp = 0,
        OffsetRight = 0,
        bThisDebug = true,
    }, function (succ, renderTexture, renderMaterial)
        if succ then
            IconPanel2.Paint = function(self, w, h)
                surface_SetDrawColor(255, 255, 255, 255)
                surface_SetMaterial(renderMaterial)
                surface_DrawTexturedRect(0, 0, w, h)
            end
        else
            print("Failed to generate icon: " .. tostring(renderTexture))
        end
    end)


    local IconPanel3 = vgui.Create("DPanel", Frame)
    IconPanel3:Dock(FILL)
    IconPanel3.Paint = nil

    icon_generation.GenerateTexture({
        model = "models/props_interiors/VendingMachineSoda01a.mdl",
        fov = 90,
        OffsetForward = 0,
        OffsetUp = 0,
        OffsetRight = 90,
        bThisDebug = true,
    }, function (succ, renderTexture, renderMaterial)
        if succ then
            IconPanel3.Paint = function(self, w, h)
                surface_SetDrawColor(255, 255, 255, 255)
                surface_SetMaterial(renderMaterial)
                surface_DrawTexturedRect(0, 0, w, h)
            end
        else
            print("Failed to generate icon: " .. tostring(renderTexture))
        end
    end)


end)

hook.Run("icon_generation_loaded")