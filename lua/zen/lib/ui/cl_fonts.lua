do return end
ui_fonts = ui_fonts or {}
function ui_font(name, data, not_save)
	if ui_fonts[name] then return ui_fonts[name] end
	local font,size
	if isnumber(name) then
		font = "Roboto"
		size = name
	elseif isstring(name) then
		local prepare_name = name
		sizen, fontn = string.match(prepare_name, "(.*):(.*)")
		if sizen and fontn then
			size = tonumber(sizen) or 10
			font = fontn
		elseif not data then
			ui_fonts[name] = name
			return ui_fonts[name]
		else
			size = size or 10
			font = font or prepare_name
		end
	end

	local new_font_name = "ui_font." .. size .. "." .. font
	if data and data.font then new_font_name = name end

	ui_fonts[name] = new_font_name

	local font_data = {
		font = font,
		extended = false,
		size = size * ( ScrH() / 350.0 ),
		weight = 300,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	}

	if data then
		if not_save then
			font_data = data
		else
			table.Merge(font_data, data)
		end
	end

	if add then
		table.Merge(font_data, add)
	end

	surface.CreateFont(ui_fonts[name], font_data)
	return ui_fonts[name]
end

--Example
ui_font(8) -- Just Roboto with 8 size
ui_font("8:Roboto") -- Same like ui_font(8)


hook.Add("HUDPaint", "TestFonts", function()
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont(ui_font(31))
    surface.SetTextPos(100, 100)
    surface.DrawText("Testing")
end)