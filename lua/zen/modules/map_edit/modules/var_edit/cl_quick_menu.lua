zen.nvars = zen.nvars or {}
local nvars = zen.nvars

local draw_NoTexture = draw.NoTexture

local draw = zen.Import("ui.draw")

local lp = LocalPlayer
local cos = math.cos
local sin = math.sin
local pi = math.pi
local blur = Material("pp/blurscreen")
local tex = surface.GetTextureID("VGUI/white.vmt")

nvars.radial_menu = {}
nvars.radial_menu.is_opened = false

local founded_entity
local _, fontHeight = ui.GetTextSize("W", 11)


nvars.mt_EntityButtons = {}

local prevSelected, prevSelectedVertex
local function getSelected()
	local mx, my = gui.MousePos()
	local sw, sh = ScrW(), ScrH()
	local total = #nvars.mt_EntityButtons
	local w = math.min(sw * 0.45, sh * 0.45)
	local sx, sy = sw / 2, sh / 2
	local x2, y2 = mx - sx, my - sy
	local ang = 0
	local dis = math.sqrt(x2 ^ 2 + y2 ^ 2)

	if dis / w <= 1 then
		if y2 <= 0 and x2 <= 0 then
			ang = math.acos(x2 / dis)
		elseif x2 > 0 and y2 <= 0 then
			ang = -math.asin(y2 / dis)
		elseif x2 <= 0 and y2 > 0 then
			ang = math.asin(y2 / dis) + pi
		else
			ang = pi * 2 - math.acos(x2 / dis)
		end

		return math.floor((1 - (ang - pi / 2 - pi / total) / (pi * 2) % 1) * total) + 1
	end
end

local r = 0
hook.Add("zen.map_edit.Render", "quickmenu", function(rendermode, priority, vw)
    if rendermode != RENDER_2D or priority != RENDER_POST then return end
    if not nvars.radial_menu.is_opened then return end

	local ent = founded_entity

	local sw, sh = ScrW(), ScrH()
	local total = #nvars.mt_EntityButtons
	local w = math.min(sw * 0.4, sh * 0.4)
	local h = w
	r = Lerp(0.1, r, w)
	local sx, sy = sw / 2, sh / 2
	local selected = getSelected() or -1
	local circleVertex = {}

	local max = 50

	for i = 0, max do
		local vx, vy = cos((pi * 2) * i / max), sin((pi * 2) * i / max)

		table.insert(circleVertex, {
			x = sx + r * 1 * vx,
			y = sy + r * 1 * vy
		})
	end

	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(255)
	render.SetStencilTestMask(255)
	render.SetStencilReferenceValue(1)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	surface.SetDrawColor(0, 0, 0, 1)
	surface.SetTexture(tex)
	surface.DrawPoly(circleVertex)
	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetMaterial(blur)
	local steps = 3
	local multiplier = 6

	for i = 1, steps do
		blur:SetFloat("$blur", (i / steps) * (multiplier or 6))
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		render.DrawScreenQuad()
	end

	surface.SetDrawColor(20, 20, 20, 180)
	draw_NoTexture()
	surface.DrawRect(0, 0, ScrW(), ScrH())
	render.SetStencilEnable(false)

	local add = pi * 1.5 + pi / total
	local add2 = pi * 1.5 - pi / total


	for k, v in pairs(nvars.mt_EntityButtons) do
		local can_use = true

		local x, y = cos((k - 1) / total * pi * 2 + pi * 1.5), sin((k - 1) / total * pi * 2 + pi * 1.5)
		local lx, ly = cos((k - 1) / total * pi * 2 + add), sin((k - 1) / total * pi * 2 + add)
		local textCol = Color(255, 255, 255)

		if not can_use then
			textCol = Color(100, 100, 100)
		end

		if selected == k then
			local vertexes = prevSelectedVertex

			if prevSelected ~= selected then
				prevSelected = selected
				vertexes = {}
				prevSelectedVertex = vertexes
				local lx2, ly2 = cos((k - 1) / total * pi * 2 + add2), sin((k - 1) / total * pi * 2 + add2)

				table.insert(vertexes, {
					x = sx,
					y = sy
				})

				table.insert(vertexes, {
					x = sx + w * 1 * lx2,
					y = sy + h * 1 * ly2
				})

				local max = math.floor(50 / total)
				for i = 0, max do
					local addv = (add - add2) * i / max + add2
					local vx, vy = cos((k - 1) / total * pi * 2 + addv), sin((k - 1) / total * pi * 2 + addv)

					table.insert(vertexes, {
						x = sx + w * 1 * vx,
						y = sy + h * 1 * vy
					})
				end

				table.insert(vertexes, {
					x = sx + w * 1 * lx,
					y = sy + h * 1 * ly
				})
			end

			if can_use then
				surface.SetTexture(tex)
				surface.SetDrawColor(125, 125, 255, 100)
				surface.DrawPoly(vertexes)
			end
		end

		draw.Text(v.string, 13, sx + r * 0.6 * x, sy + r * 0.6 * y - fontHeight / 2, textCol, 1)
	end
end)

hook.Add("zen.worldclick.nopanel.onPress", "zen.map_edit.quickmenu", function(code, tr)
	if nvars.radial_menu.is_opened then
		local selected = getSelected()

		if selected and selected > 0 and code == MOUSE_LEFT then
			local tButton = nvars.mt_EntityButtons[selected]

			nt.Send("nvars.run_command", {"entity", "int12", "next", "any"}, {founded_entity, tButton.id, tButton.mode != nil and true or false, tButton.mode})
		end

		nvars.radial_menu.Close()
	end
end)

function nvars.radial_menu.Open()
	nvars.radial_menu.is_opened = true
	gui.EnableScreenClicker(true)
	prevSelected = nil
end

function nvars.radial_menu.Close()
	founded_entity = nil
	nvars.mt_EntityButtons = {}
	nvars.radial_menu.is_opened = false
	r = 0
	gui.EnableScreenClicker(false)
end

hook.Add("zen.map_edit.OnButtonPress", "quickmenu", function(ply, but, bind, vw)
	if IsValid(vw.hoverEntity) then
		if bind == IN_USE then
			nvars.mt_EntityButtons = {}
			nt.Send("nvars.get_buttons", {"entity"}, {vw.hoverEntity})

            founded_entity = vw.hoverEntity
            nvars.radial_menu.Open()
            vw.IsRadialMenuOpen = true
		end
	end
end)

nt.Receive("nvars.get_buttons", {"entity", "table"}, function(ent, tButtons)
    nvars.mt_EntityButtons = tButtons
end)

hook.Add("zen.map_edit.OnButtonUnPress", "quickmenu", function(ply, but, bind, vw)
    if bind == IN_USE then
        if nvars.radial_menu.is_opened then
            nvars.radial_menu.Close()
            vw.IsRadialMenuOpen = false
        end
    end
end)