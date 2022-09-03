zen.nvars = zen.nvars or {}
local nvars = zen.nvars
local draw = zen.Import("ui.draw")

local cos = math.cos
local sin = math.sin
local pi = math.pi
local blur = Material("pp/sub")

nvars.radial_menu = {}
nvars.radial_menu.is_opened = false

local _, fontHeight = ui.GetTextSize("W", 11)


nvars.mt_EntityButtons = {}

local clr_circle = Color(100,100,100,150)
local clr_active = Color(255,100,100,100)
local clr_selected = Color(125, 125, 255, 100)
local clr_selected_red = Color(255, 125, 125, 150)

local sw, sh = ScrW(), ScrH()
nvars.circles = {}
nvars.circles[1] ={
	type = "nvars",
	x = sw*0.1,
	y = sh*0.60,
	max_r = math.min(sw*0.1, sh*0.1)
}
nvars.circles[2] ={
	type = "ent_command",
	x = sw*0.1,
	y = sh*0.85,
	color = Color(125, 100, 100, 100),
	max_r = math.min(sw*0.13, sh*0.13),
	content = {
		{
			text = "Remove",
			color = COLOR.RED,
			hover_color = clr_selected_red,
			value = "remove"
		},
		{
			text = "Use",
			color = color_white,
			value = "freeze"
		},
		{
			text = "(Un)Freeze",
			color = color_white,
			value = "unfreeze"
		},
		{
			text = "(Un)Motion",
			color = color_white,
			value = "motion_disable"
		},
	},
}
nvars.circles[3] ={
	type = "edit_vars",
	x = sw*0.9,
	y = sh*0.85,
	text = "Change",
	color = Color(100, 100, 100, 100),
	max_r = math.min(sw*0.13, sh*0.13),
	content = {
		{
			text = "Origin",
			value = "change_pos"
		},
		{
			text = "Angle",
			value = "change_ang"
		},
		{
			text = "Velocity",
			value = "change_velocity"
		},
	},
}
nvars.circles[4] ={
	type = "edit_modes",
	x = sw*0.9,
	y = sh*0.55,
	text = "Change",
	color = Color(100, 100, 100, 100),
	max_r = math.min(sw*0.13, sh*0.13),
	content = {
		{
			text = "Physics",
			value = "change_pos"
		},
		{
			text = "Bones",
			value = "change_ang"
		},
		{
			text = "Variables",
			value = "change_velocity"
		},
	},
}
nvars.circles[5] ={
	type = "edit_modes",
	x = sw*0.95,
	y = sh*0.095,
	text = "info",
	font_size = 6,
	color = Color(255, 255, 255, 40),
	max_r = math.min(sw*0.08, sh*0.08),
	content = {
		{
			text = "This",
			value = "change_pos"
		},
		{
			text = "Parent",
			value = "change_ang"
		},
		{
			text = "All",
			value = "change_velocity"
		},
	},
}

local function cursorInCircle(x, y, r)
	local mx, my = input.GetCursorPos()

	return math.Distance(x, y, mx, my) < r
end

local function getCircleSelected(x, y, r, sep)
	local mx, my = input.GetCursorPos()
	local x2, y2 = mx - x, my - y

	local ang = 0
	local dis = math.sqrt(x2 ^ 2 + y2 ^ 2)

	if dis / r <= 1 then
		if y2 <= 0 and x2 <= 0 then
			ang = math.acos(x2 / dis)
		elseif x2 > 0 and y2 <= 0 then
			ang = -math.asin(y2 / dis)
		elseif x2 <= 0 and y2 > 0 then
			ang = math.asin(y2 / dis) + pi
		else
			ang = pi * 2 - math.acos(x2 / dis)
		end

		return math.floor((1 - (ang - pi / 2 - pi / sep) / (pi * 2) % 1) * sep) + 1
	end
	return -1
end

local function getCircleItemPos(sx, sy, r, sep, item_id)
	local x, y = cos((item_id - 1) / sep * pi * 2 + pi * 1.5), sin((item_id - 1) / sep * pi * 2 + pi * 1.5)

	return sx + r * 0.6 * x, sy + r * 0.6 * y - fontHeight / 2
end

local function getCircleDrawPolySelected(sx, sy, r, sep, item_id, saveTbl)
	local add = pi * 1.5 + pi / sep
	local add2 = pi * 1.5 - pi / sep

	local lx, ly = cos((item_id - 1) / sep * pi * 2 + add), sin((item_id - 1) / sep * pi * 2 + add)

	local vertexes = saveTbl.prevSelectedVertex

	if saveTbl.prevSelected ~= item_id then
		saveTbl.prevSelected = item_id
		vertexes = {}
		saveTbl.prevSelectedVertex = vertexes
		local lx2, ly2 = cos((item_id - 1) / sep * pi * 2 + add2), sin((item_id - 1) / sep * pi * 2 + add2)

		table.insert(vertexes, {
			x = sx,
			y = sy
		})

		table.insert(vertexes, {
			x = sx + r * 1 * lx2,
			y = sy + r * 1 * ly2
		})

		local max = math.floor(50 / sep)
		for i = 0, max do
			local addv = (add - add2) * i / max + add2
			local vx, vy = cos((item_id - 1) / sep * pi * 2 + addv), sin((item_id - 1) / sep * pi * 2 + addv)

			table.insert(vertexes, {
				x = sx + r * 1 * vx,
				y = sy + r * 1 * vy
			})
		end

		table.insert(vertexes, {
			x = sx + r * 1 * lx,
			y = sy + r * 1 * ly
		})
	end

	return vertexes
end


hook.Add("zen.map_edit.Render", "quickmenu", function(rendermode, priority, vw)
    if rendermode != RENDER_2D or priority != RENDER_POST then return end
    if not nvars.radial_menu.is_opened then return end

	for id, v in pairs(nvars.circles) do
		local x, y, r = v.x, v.y, v.max_r
		local tContent = v.content

		if not tContent then

			continue
		end

		local total = #tContent

		draw.Circle(x, y, r, 50, v.color or clr_circle)

		local selID = getCircleSelected(x, y, r, total)


		if selID > 0 then
			local dat = tContent[selID]
			local poly = getCircleDrawPolySelected(x, y, r, total, selID, v)
			v.SelectID = selID
			v.SelectValue = dat.value

			local clr = dat.hover_color or clr_selected

			draw.Circle(x, y, 20, 50, clr)
			draw.DrawPoly(poly, clr)
		else
			v.SelectID = nil
			v.SelectValue = nil
		end

		for k = 1, total do
			local dat = tContent[k]

			local tx, ty = getCircleItemPos(x, y, r, total, k)

			draw.Text(dat.text or "unknown", v.font_size or 8, tx, ty, dat.color or color_white, 1, nil, COLOR_BLACK)
		end

		if total == 0 then
			draw.Text("Empty", 10, x, y, color_white, 1, 1)
		elseif v.text then
			draw.Text(v.text, 6, x, y, COLOR.WHITE, 1, 1, COLOR.BLUE)
		end
	end
end)

hook.Add("zen.worldclick.nopanel.onPress", "zen.map_edit.quickmenu", function(code, tr)
	if code != MOUSE_LEFT then return end
	if not nvars.radial_menu.is_opened then return end

	for k, v in pairs(nvars.circles) do
		local selID = v.SelectID
		local selValue = v.SelectValue

		if v.type == "nvars" then
			local id, mode = selValue, v.value_mode

			nt.Send("nvars.run_command", {"entity", "int12", "next", "any"}, {nvars.hoverEntity, id, mode != nil and true or false, mode})
		end
	end

	nvars.radial_menu.Close()
end)

function nvars.radial_menu.Open()
	nvars.radial_menu.is_opened = true
	gui.EnableScreenClicker(true)
end

function nvars.radial_menu.Close()
	nvars.radial_menu.is_opened = false
	gui.EnableScreenClicker(false)
end

hook.Add("zen.map_edit.OnButtonPress", "quickmenu", function(ply, but, bind, vw)
	if bind != IN_USE then return end
	if not IsValid(vw.hoverEntity) then return end

	nvars.circles.content = {}
	nt.Send("nvars.get_buttons", {"entity"}, {vw.hoverEntity})

	nvars.hoverEntity = vw.hoverEntity
	nvars.radial_menu.Open()
end)

nt.Receive("nvars.get_buttons", {"entity", "table"}, function(ent, tButtons)
	nvars.circles[1].content = {}
	local tContent = nvars.circles[1].content
    for k, v in pairs(tButtons) do
		table.insert(tContent, {
			text = v.string,
			value = v.id,
			value_mode = v.mode,
		})
	end
end)

hook.Add("zen.map_edit.OnButtonUnPress", "quickmenu", function(ply, but, bind, vw)
    if bind != IN_USE then return end

	if nvars.radial_menu.is_opened then
		nvars.radial_menu.Close()
	end
end)