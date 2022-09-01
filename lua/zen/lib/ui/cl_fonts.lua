local ui = zen.Init("ui")

ui.t_FontList = ui.t_FontList or {}
ui.t_FastFontList = ui.t_FastFontList or {}
ui.t_FontData = ui.t_FontData or {}

-- ```
-- ui.font("Hud Main", 10, "Roboto", {symbol = true})
-- ui.font("Hud Main NoSize", nil, "Roboto", {size = 10}) --> font without auto-size
-- ui.font("Hud Main NoSize NiceFont", nil, nil, {size = 10, font = "Digital-7 Mono"}) --> font without auto-size and with nice font
-- ui.font("Hud Main NoSize NiceFont", nil, "Digital-7 Mono", {size = 10})
--  ```
---@param font_unique_id any
---@param size number
---@param font_base? any
---@param font_data? table
---@param noCheck? boolean
---@return string font_unique_id
function ui.font(font_unique_id, size, font_base, font_data, noCheck)
	if not noCheck then
		if ui.t_FontList[font_unique_id] then return ui.t_FontList[font_unique_id] end
		if ui.t_FastFontList[font_unique_id] then return ui.t_FastFontList[font_unique_id] end
	end

	size = size
	font_base = ui.t_FontList[font_base] or font_base or "Roboto"
	font_data = font_data or {}

	local font_table_base = ui.t_FontData[font_base]
	if font_table_base then
		local new_font_data = {}
		table.Merge(new_font_data, font_table_base)
		table.Merge(new_font_data, font_data)
		font_data = new_font_data
	end

	assert(isnumber(size) or (istable(font_data) and isnumber(font_data.size)), "size or font_data.size not is number")

	local data = {
		font = font_data.font or font_base,
		extended = font_data.expected or false,
		size = (size and size * ( ScrH() / 350.0 ) or font_data.size),
		weight = font_data.weight or 300,
		blursize = font_data.blursize or 0,
		scanlines = font_data.scanlines or 0,
		antialias = font_data.antialias or true,
		underline = font_data.underline or false,
		italic = font_data.italic or false,
		strikeout = font_data.strikeout or false,
		symbol = font_data.symbol or false,
		rotary = font_data.rotary or false,
		shadow = font_data.shadow or false,
		additive = font_data.additive or false,
		outline = font_data.outline or false,
	}

	surface.CreateFont(font_unique_id, data)
	ui.t_FontData[font_unique_id] = data

	ui.t_FontList[font_unique_id] = font_unique_id
	return ui.t_FontList[font_unique_id]
end


-- ```
-- ui.CreateFont("MainHUD", 10, "Roboto", {})
-- ui.CreateFont("MainHUD_Italic", nil, "MainHUD", {italic = true})
-- ```
---@param font_unique_id any
---@param size number
---@param font_base? any
---@param font_data? table
---@return string font_unique_id
function ui.CreateFont(font_unique_id, size, font_base, font_data)
	return ui.font(font_unique_id, size, font_base, font_data, true)
end

-- ```
-- ui.ffont(8) --> return Roboto with size 8
-- ui.ffont("8:Roboto") --> return Roboto with size 8
-- ui.ffont("10:Marlett") --> return Marlett with size 10
-- ui.ffont("11:Digital-7 Mono") --> return Digital-7 Mono with size 11
--  ```
---@param font_fast string|number
---@return string font_name
function ui.ffont(font_fast)
	if ui.t_FontList[font_fast] then return ui.t_FontList[font_fast] end
	if ui.t_FastFontList[font_fast] then return ui.t_FastFontList[font_fast] end

	local font,size
	if isnumber(font_fast) then
		font = "Roboto"
		size = font_fast
	elseif isstring(font_fast) then
		local prepare_name = font_fast
		sizen, fontn = string.match(prepare_name, "(.*):(.*)")
		if sizen and fontn then
			size = tonumber(sizen) or 10
			font = fontn
		else
			size = size or 10
			font = font or prepare_name
		end
	else
		eror("noFonts")
	end

	local font_name = "zen.ui.ffonts." .. font_fast .. "|" .. size .. ":" .. font

	ui.font(font_name, size, font)
	ui.t_FastFontList[font_fast] = font_name

	return font_name
end