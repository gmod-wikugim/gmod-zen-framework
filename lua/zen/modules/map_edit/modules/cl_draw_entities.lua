local map_edit = zen.Init("map_edit")

local ui, draw, draw3d, draw3d2d = zen.Import("ui", "ui.draw", "ui.draw3d", "ui.draw3d2d")
local mat_user = Material("icon16/user_suit.png")
local mat_wireframe = Material("models/debug/debugwhite")
local mat_wireframe2 = Material("phoenix_storms/stripes")

ihook.Listen("zen.map_edit.Render", "draw_entities", function(rendermode, priority, vw)
	if priority == RENDER_POST then

		if vw.cfg_draw_player then
			for k, v in pairs(player.GetAll()) do
				local pos = v:EyePos()
				pos.z = pos.z + 15
				local w = draw3d2d.Text(pos, nil, 0.1, true, v:GetName(), 20, 0, 0, COLOR.WHITE, 1, 1, COLOR.BLACK)

				pos.z = pos.z + 5
				draw3d.Texture(pos, mat_user, -10, -10, 20, 20)
			end
		end

		if vw.cfg_draw_nearbly then
			local ent_list = ents.FindInSphere(vw.lastOrigin, 500)
			if ent_list then
				for k, ent in pairs(ent_list) do
					local pos = ent:GetPos()
					local ang  = ent:GetAngles()
					

					local model = ent:GetModel()
					if model and model != "" and util.IsValidModel(model) then
						render.SetBlend(0.2)
						render.ModelMaterialOverride(mat_wireframe)
						render.SetColorModulation(1,0,0)
						ent:DrawModel()

						local min, max = ent:GetModelBounds()
						render.DrawWireframeBox(pos, ang, min, max)


						render.ModelMaterialOverride()
						render.SetBlend(1)
					else
						render.DrawWireframeSphere(pos, 1, 5, 5)
					end

					draw3d2d.Text(pos, nil, 0.1, true, ent:GetClass(), 20, 0, 0, COLOR.WHITE, 1, 1, COLOR.BLACK)
				end
			end
		end
	end
end)

ihook.Listen("zen.map_edit.GenerateGUI", "points", function(nav, pnlContext, vw)

    nav.items:zen_AddStyled("input_bool", {"dock_top", text = "Draw Players", cc = {
        OnChange = function(self, value)
            vw.IsDrawPlayers = value
        end
    }})

end)
