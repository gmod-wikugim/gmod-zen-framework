local map_edit = zen.Init("map_edit")
map_edit.quickmenu = map_edit.quickmenu or {}
local qcm = map_edit.quickmenu

local draw_NoTexture = draw.NoTexture

local draw = zen.Import("ui.draw")

local lp = LocalPlayer
local cos = math.cos
local sin = math.sin
local pi = math.pi
local blur = Material("pp/blurscreen")
local tex = surface.GetTextureID("VGUI/white.vmt")

qcm.radial_menu = {}
qcm.radial_menu.is_opened = false

local founded_entity
local dist = 100
local _, fontHeight = ui.GetTextSize("W", 11)

local function IsPly(ent)
	return ent:IsPlayer()
end

local buttons_cfg = {
	{
		name = "Представится",
		onclick = function()
			RunConsoleCommand("qcm", "introduce-himself")
		end,
		check_ent = IsPly
	},
	{
		name = "Дать денег",
		onclick = function()
			Derma_StringRequest("Передать деньги", "Сколько денег вы хотите передать?", "", function(text)
				RunConsoleCommand("qcm", "givemoney", tonumber(text))
			end)
		end,
		check_ent = IsPly
	},

	{
		name = "Открыть",
		onclick = function(ent)
            print("Open", ent)
		end,
		-- check = function(ent) return qcm.properties.has_access(lp(), ent) end,
		check_ent = function(ent) return util.IsDoor(ent) end,
	},
}

local current_menu = {}

local prevSelected, prevSelectedVertex
local function getSelected()
	local mx, my = gui.MousePos()
	local sw, sh = ScrW(), ScrH()
	local total = #current_menu
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
    if not qcm.radial_menu.is_opened then return end

	local ent = founded_entity

	local sw, sh = ScrW(), ScrH()
	local total = #current_menu
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

	for k, v in pairs(current_menu) do
		local ment = buttons_cfg[v]

		local can_use = true

		if ment.check and not ment.check(ent) then
			can_use = false
		end

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

		draw.Text(ment.name, 13, sx + r * 0.6 * x, sy + r * 0.6 * y - fontHeight / 2, textCol, 1)
	end
end)

hook.Add("zen.worldclick.nopanel.onPress", "zen.map_edit.quickmenu", function(code, tr)
	if qcm.radial_menu.is_opened then
		local selected = getSelected()

		if selected and selected > 0 and current_menu[selected] and code == MOUSE_LEFT then
			if buttons_cfg[current_menu[selected]].check and not buttons_cfg[current_menu[selected]].check(founded_entity) then
				qcm.radial_menu.Close()
				return
			end

			buttons_cfg[current_menu[selected]].onclick(founded_entity)
		end

		qcm.radial_menu.Close()
	end
end)

function qcm.radial_menu.Open()
	qcm.radial_menu.is_opened = true
	gui.EnableScreenClicker(true)
	prevSelected = nil
end

function qcm.radial_menu.Close()
	founded_entity = nil
	current_menu = {}
	qcm.radial_menu.is_opened = false
	r = 0
	gui.EnableScreenClicker(false)
end

hook.Add("zen.map_edit.OnButtonPress", "quickmenu", function(ply, but, bind, vw)
	if IsValid(vw.hoverEntity) then
		if bind == IN_USE then

            local founded = false
            for k,v in pairs(buttons_cfg) do
                if v.check_ent(vw.hoverEntity) then
                    founded = true
                    table.insert(current_menu, k)
                end
            end

            if not founded then return end

            founded_entity = vw.hoverEntity
            qcm.radial_menu.Open()
            vw.IsRadialMenuOpen = true
		end
	end
end)

hook.Add("zen.map_edit.OnButtonUnPress", "quickmenu", function(ply, but, bind, vw)
    if bind == IN_USE then
        if qcm.radial_menu.is_opened then
            qcm.radial_menu.Close()
            vw.IsRadialMenuOpen = false
        end
    end
end)