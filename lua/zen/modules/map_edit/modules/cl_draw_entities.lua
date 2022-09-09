local map_edit = zen.Init("map_edit")

local ui, draw, draw3d, draw3d2d = zen.Import("ui", "ui.draw", "ui.draw3d", "ui.draw3d2d")
local mat_user = Material("icon16/user_suit.png")
local mat_wireframe = Material("models/white_outline")

hook.Add("zen.map_edit.Render", "draw_entities", function(rendermode, priority, vw)
	if priority == RENDER_POST then

		if vw.IsDrawPlayers then
			for k, v in pairs(player.GetAll()) do
				local pos = v:EyePos()
				pos.z = pos.z + 15
				local w = draw3d2d.Text(pos, nil, 0.1, true, v:GetName(), 20, 0, 0, COLOR.WHITE, 1, 1, COLOR.BLACK)

				pos.z = pos.z + 5
				draw3d.Texture(pos, mat_user, -10, -10, 20, 20)
			end
		end

		local ent_list = ents.FindInSphere(vw.lastTrace.HitPos, 500)
		if ent_list then

			render.SetBlend(0.5)
			render.ModelMaterialOverride(mat_wireframe)
			for k, ent in pairs(ent_list) do
				draw3d2d.Text(ent:GetPos(), nil, 0.1, true, ent:GetClass(), 20, 0, 0, COLOR.WHITE, 1, 1, COLOR.BLACK)
				ent:DrawModel()
			end
			
			render.ModelMaterialOverride()
		end
	end
end)

hook.Add("zen.map_edit.GenerateGUI", "points", function(nav, pnlContext, vw)

    nav.items:zen_AddStyled("input_bool", {"dock_top", text = "Draw Players", cc = {
        OnChange = function(self, value)
            vw.IsDrawPlayers = value
        end
    }})

end)
