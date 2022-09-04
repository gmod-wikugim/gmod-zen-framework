local map_edit = zen.Init("map_edit")

local gui, ui, draw, draw3d, draw3d2d = zen.Import("gui", "ui", "ui.draw", "ui.draw3d", "ui.draw3d2d")
local GetVectorString, GetAngleString = zen.Import("map_edit.GetVectorString", "map_edit.GetVectorString")

local MODE_DEFAULT = map_edit.RegisterMode("Default")

local clr_white_alpha = Color(255,255,255,100)
hook.Add("zen.map_edit.Render", "paticle_viewer", function(rendermode, priority, vw)
end)

hook.Add("zen.map_edit.OnModeChange", "paticle_viewer", function(vw, old, new)
end)


hook.Add("zen.map_edit.OnButtonPress", "paticle_viewer", function(ply, but, bind, vw)
end)

local DispatchEffects = {"ImpactGauss", "EjectBrass_12Gauge", "ImpactJeep", "AR2Tracer", "GunshipImpact", "BloodImpact", "ShotgunShellEject", "PhyscannonImpact", "WheelDust", "VortDispel", "StriderMuzzleFlash", "Impact", "AirboatMuzzleFlash", "RifleShellEject", "AirboatGunTracer", "ParticleEffectStop", "CommandPointer", "GlassImpact", "GunshipTracer", "Explosion", "AR2Impact", "Sparkle", "GunshipMuzzleFlash", "WaterSurfaceExplosion", "AntlionGib", "waterripple", "ThumperDust", "gunshotsplash", "bloodspray", "Tracer", "AirboatGunHeavyTracer", "RPGShotDown", "AirboatGunImpact", "StunstickImpact", "ParticleTracer", "TeslaHitboxes", "AR2Explosion", "cball_bounce", "HudBloodSplat", "HelicopterTracer", "HelicopterImpact", "ShakeRopes", "GaussTracer", "CrossbowLoad", "HunterMuzzleFlash", "BoltImpact", "TracerSound", "StriderTracer", "EjectBrass_9mm", "HunterDamage", "ManhackSparks", "watersplash", "TeslaZap", "MuzzleFlash", "ShellEject", "StriderBlood", "ParticleEffect", "Smoke", "ImpactGunship", "ChopperMuzzleFlash", "cball_explode", "MyEffectName", "HunterTracer", "HelicopterMegaBomb", "RagdollImpact"}

local function loadFolder(path, tResult, parent_path)
	local files, folders = file.Find(path .. "/*", parent_path)
	for k, v in pairs(files) do
		table.insert(tResult, path .. "/" .. v)
	end
	
	for k, v in pairs(folders) do
		loadFolder(path .. "/" .. v, tResult)
	end
end

local function getFull(path, parent_path)
	local tResult = {}

	loadFolder(path, tResult, parent_path)

	return tResult
end


map_edit.t_ParticleViewers = {}
function map_edit.CreateParticleViewer(pnlContext, vw)
    if not vw.t_ParticleViewers then vw.t_ParticleViewers = {} end

    local particle_id = newproxy()

    vw.t_ParticleViewers[particle_id] = {}
    local tViewer = vw.t_ParticleViewers[particle_id]

    tViewer.EffectData = EffectData()


    local nav = gui.SuperCreate({
        {{
            {"main", "frame"};
            {parent = pnlContext, popup = gui.proxySkip, size = {300, 500}};
            {};
            {
                {"content", "content"};
                {};
                {};
                {
                    {
                        {"items", "list"};
                        {};
                        {};
                        {
                            {{"eff_name", "input_arg"}, {"dock_top", tall = 25, text = "Start"}};
                            {{"var_start", "input_vector"}, {"dock_top", tall = 25, text = "Start"}};
                            {{"var_origin", "input_vector"}, {"dock_top", tall = 25, text = "Origin"}};
                            {{"var_normal", "input_vector"}, {"dock_top", tall = 25, text = "Normal"}};
                            {{"var_magnitude", "input_number"}, {"dock_top", tall = 25, text = "Magnitude"}};
                            {{"var_radius", "input_number"}, {"dock_top", tall = 25, text = "Radius"}};
                            {{"var_scale", "input_number"}, {"dock_top", tall = 25, text = "Scale"}};
                            {{"var_entity", "input_entity"}, {"dock_top", tall = 25, text = "Entity"}};
                        };
                    };
                    {{"particle_id", "text"}, {"dock_top"}};
                    {{"but_emit", "button"}, {"dock_bottom", text = "Emit"}}
                }
            }
        }}
    })

    local tParticles = getFull("particles", "GAME")
	local tEffects = getFull("effect", "LUA")

    if DispatchEffects then
        for k, v in pairs(DispatchEffects) do
            nav.eff_name:AddChoice(v)
        end
    end

    if tParticles then
        for k, v in pairs(tParticles) do
            nav.eff_name:AddChoice(v, v)
        end
    end
    if tEffects then
        for k, v in pairs(tEffects) do
            nav.eff_name:AddChoice(v, v)
        end
    end

    tViewer.nav = nav

    nav.main.OnRemove = function()
        vw.t_ParticleViewers[particle_id] = nil
    end

    nav.but_emit.DoClick = function()
        tViewer.EffectData:SetStart(nav.var_start:GetValue())
        tViewer.EffectData:SetOrigin(nav.var_origin:GetValue())
        tViewer.EffectData:SetNormal(nav.var_normal:GetValue())
        tViewer.EffectData:SetMagnitude(nav.var_magnitude:GetValue())
        tViewer.EffectData:SetRadius(nav.var_radius:GetValue())
        tViewer.EffectData:SetScale(nav.var_scale:GetValue())
        tViewer.EffectData:SetEntity(nav.var_entity:GetValue())

        local effect_name = nav.eff_name:GetValue()
        
        -- effect_name = string.gsub(effect_name, "particles/", "")
        effect_name = string.gsub(effect_name, ".pcf", "")
        
        util.Effect(effect_name, tViewer.EffectData)
    end

end


hook.Add("zen.map_edit.GenerateGUI", "paticle_viewer", function(nav, pnlContext, vw)
    nav.items:zen_AddStyled("button", {"dock_top", text = "Create Particle Viewer", cc = {
        DoClick = function()
            map_edit.CreateParticleViewer(pnlContext, vw)
        end
    }})
end)