local iconsole, icmd = zen.Init("console", "command")
local ui = zen.Import("ui", "command")

iconsole.INPUT_MODE = false
iconsole.phrase = ""
iconsole.DrawFont = ui.ffont(6)
iconsole.DrawFont_UnderLine = ui.font("iconsole.underline",6,nil,{underline = true})

local concat = table.concat
local format = string.format
local sub = string.sub

local _I = function(data) return concat(data, "") end
iconsole.InitEntry = function()
	if IsValid(iconsole.dentry) then iconsole.dentry:Remove() end
	iconsole.dentry = vgui.Create("DTextEntry")
	iconsole.dentry:ParentToHUD()

	iconsole.dentry:MakePopup()
	iconsole.dentry:SetMouseInputEnabled(false)
	iconsole.dentry:SetAlpha(0)

	iconsole.dentry.AllowInput = function(self, char)
		iconsole.AddChar(char)
		return true
	end
end

iconsole.UpdateAutoComplete = function()
	local help, fullHelp, tAutoComplete = icmd.GetAutoComplete(iconsole.phrase)

	iconsole.auto_complete_help = help
	iconsole.auto_complete_fullHelp = fullHelp
	iconsole.auto_complete_tAutoComplete = tAutoComplete
end

iconsole.SetPhrase = function(str)
	local len = utf8.len(str)

	if len > 100 then
		str = utf8.sub(str, 1, 100)
	end

    iconsole.phrase = str
end

iconsole.SetPhrase_ByAutoComplete = function(str)
	iconsole.SetPhrase(str)
end

iconsole.AddChar = function(char)
	if utf8.len(iconsole.phrase) >= 100 or char == nil or char == "" then return end
	iconsole.SetPhrase(iconsole.phrase .. char)
end

local KeyStart = KEY_SEMICOLON
local KeyDefault = KEY_D
local KeyServer = KEY_V
local KeyClient = KEY_C

local IS_EPOE=	2^0
local IS_ERROR=	2^1
local IS_PRINT=	2^2
local IS_MSG=   2^3

local IS_MSGN=	2^4
local IS_SEQ=		2^5
local IS_CERROR=	2^6
local IS_MSGC=	2^7

local FlagsWithNewLine = {
	[IS_ERROR] = true,
	[IS_PRINT] = true,
	[IS_MSGN] = true,
	[IS_CERROR] = true,
	[IS_EPOE] = true,
}

local COLOR_INPUT_NEXT = Color(100,100,100,100)
local COLOR_ARG = Color(125,255,125, 100)

function iconsole.AddColorToText(text, color)
	if color == nil then return text end
	local color_start = _I{"<color=",color.r,",",color.g,",",color.b,",",color.a,">"}
	local color_end = "</color>"
	return _I{color_start,text,color_end}
end

local function to_arg(text) return iconsole.AddColorToText(tostring(text), COLOR_ARG) end

iconsole.ServerConsoleLog = iconsole.ServerConsoleLog or ""
function iconsole.AddConsoleLog(flags, ...)
	local args = {...}
	if flags and bit.band(flags, IS_ERROR) == IS_ERROR then
		table.insert(args, 1, COLOR.R)
	end

	local AddText = ""

	local isColorAdded = false
	for k, v in pairs(args) do
		if IsColor(v) then
			local text_add = _I{"<color=",v.r,",",v.g,",",v.b,",",v.a,">"}
			AddText = AddText .. text_add
			isColorAdded = true
		elseif isstring(v) then
			if util.IsSteamID64(v) or util.IsSteamID(v) then
				local nick = util.GetPlayerNick(v)
				if nick then
					local text_add = to_arg(nick)
					AddText = AddText .. to_arg(v) .. "(" .. text_add .. ")"
				end
			else
				AddText = AddText .. v
			end
		elseif isentity(v) then
			if IsValid(v) and v:IsPlayer() then
				local nick = util.GetPlayerNick(v) or v:Nick()
				AddText = AddText .. to_arg(nick)
			else
				AddText = AddText .. tostring(v)
			end
		elseif isnumber(v) then
			local text_add = to_arg(v)
			AddText = AddText .. text_add
		elseif isvector(v) then
			local text_add = _{math.floor(v.x),",",math.floor(v.y),",",math.floor(v.z)}
			AddText = AddText .. text_add
		elseif isangle(v) then
			local text_add = _{math.floor(v.p or v[1] or v.pitch),",",math.floor(v.y or v[2] or v.yaw ),",",math.floor(v.r or v[3] or v.roll)}
			AddText = AddText .. text_add
		elseif isbool(v) then
			local text_add = to_arg(v)
			AddText = AddText .. text_add
		end
	end

	if isColorAdded then
		AddText = AddText .. "</color>"
	end

	flags = flags or IS_MSGN

	if not flags or FlagsWithNewLine[flags] then
		-- str = string.gsub(str, "\n", "")
		-- str = string.gsub(str, "\r", "")
		AddText = AddText .. "\n"
	end

	AddText = iconsole.AddColorToText(AddText, clr)

	iconsole.ServerConsoleLog = iconsole.ServerConsoleLog .. AddText
end

local last_console_log
local last_result
function iconsole.GetConsoleLog(Wide)
	if last_console_log == iconsole.ServerConsoleLog then return last_result end

	last_console_log = iconsole.ServerConsoleLog

	local console_obj = markup.Parse("<font=" .. iconsole.DrawFont .. ">" .. iconsole.ServerConsoleLog .. "</font>", Wide)

	local blocks = console_obj.blocks
	local block_count = #blocks


	local max_lines = 15
	local new_lines = 0
	local block_select = block_count
	for i = block_count, 1, -1 do
		local block = blocks[i]

		if block.offset.x == 0 then
			new_lines = new_lines + 1
		end

		block_select = i

		if new_lines > max_lines then break end
	end

	local source = ""

	for i = block_select, block_count do
		local block = blocks[i]

		local add_text = block.text

		if not add_text then continue end

		if source != "" and block.offset.x == 0 then
			source = source .. "\n"
		end

		source = source .. add_text
		source = iconsole.AddColorToText(source, block.colour)
	end
	last_result = source

	return last_result
end

local IsDown = input.IsButtonDown

ihook.Listen("PlayerButtonPress", "fast_console_phrase", function(ply, but, in_key, bind, char)
	if not iconsole.INPUT_MODE then
		if (IsDown(KEY_LCONTROL) and IsDown(KEY_LALT) and but == KeyStart) or bind == "zen_console" then
			iconsole.INPUT_MODE = true
			iconsole.SetPhrase("")
			iconsole.InitEntry()
			iconsole.UpdateAutoComplete()
		end

		return
	end

	if IsDown(KEY_LCONTROL) and but == KEY_C then goto stop end
	if but == KEY_ESCAPE then goto stop end

	if IsDown(KEY_LCONTROL) then
		if but == KEY_BACKSPACE then
			local args = string.Split(iconsole.phrase, " ")
			local lastargs = #args
			if lastargs > 0 then table.remove(args, lastargs) end

            iconsole.SetPhrase(table.concat(args, " "))
			goto next
		end
	else
		if but == KEY_BACKSPACE then
			local lenght = utf8.len(iconsole.phrase)
			local new_lenght = math.max(0, lenght-1)
            iconsole.SetPhrase(utf8.sub(iconsole.phrase, 0, new_lenght))
			goto next
		end
	end

	if IsDown(KEY_LCONTROL) and but == KEY_L then
		iconsole.ServerConsoleLog = ""
	end

	if but == KEY_ENTER then
		ihook.Run("OnFastConsoleCommand", iconsole.phrase)
		iconsole.SetPhrase("")
		goto next
	end


	do
		local is_numpad = but >= KEY_PAD_0 and but <= KEY_PAD_9


		local help = iconsole.auto_complete_help
		local fullHelp = iconsole.auto_complete_fullHelp
		local tAutoComplete = iconsole.auto_complete_tAutoComplete

		local t_Select = tAutoComplete.select
		local activeText = tAutoComplete.activeText or ""



		if is_numpad and t_Select and #t_Select > 0 then
			local num = tonumber(char)
			if num then
				local tSelectItem = t_Select[num]
				if tSelectItem then

					local add_tex = #activeText == " " and "" or " "
					local new_string = sub(iconsole.phrase, 1, #iconsole.phrase - #activeText-1) .. add_tex .. tSelectItem.value .. " "
					iconsole.SetPhrase_ByAutoComplete(new_string)
					goto next
				end
			end
		end
	end


	do
		local dentry_no_works = not (IsValid(iconsole.dentry) and iconsole.dentry:HasFocus() and iconsole.dentry:IsEditing())
		if dentry_no_works then
			iconsole.AddChar(char)
			goto next
		end
	end



	goto next
	::stop::
	iconsole.INPUT_MODE = false
    if IsValid(iconsole.dentry) then
	    iconsole.dentry:Remove()
    end
	iconsole.SetPhrase("")
	do return end
	::next::

	iconsole.UpdateAutoComplete()
end)

ihook.Listen("DrawOverlay", "fast_console_phrase", function()
	if not iconsole.INPUT_MODE then return end
	local w, h = ScrW(), ScrH()
	local SX, SY = 100, 100
	local Wide = w - SX*2

	local text = ""

	local IA = function(dat)
		text = _I{text, table.concat(dat)}
	end
    local IAN = function(dat)
		text = _I{text, table.concat(dat), "\n"}
	end

	IA{"<font=" .. iconsole.DrawFont .. ">"}

	IAN{"============================================================================================================================="}

	IAN{"DataTime: " .. os.date("%X - %x", os.time())}
	IAN{"CurTime: " .. math.floor(CurTime())}
	IAN{"SysTime: " .. math.floor(SysTime())}


	IAN{}

	IAN{"Welcome to debug console"}
	IAN{"ENTER - To Apply"}
	IAN{"CTRL + C or ESC - To Exit"}

	local alpha = math.floor(math.abs(math.sin(CurTime() * 5) * 50))

	IAN{}

	IAN{"--- Console ---"}

	do
		text = text .. (iconsole.GetConsoleLog(Wide) or "")
    end

	if text[#text] != "\n" then
		IAN{}
	end

	IA{":",iconsole.phrase}

	if alpha > 25 then
		IA{"<colour=255,255,255," .. alpha .. ">" .. "|" .. "</colour>"}
	else
		IA{" "}
	end

	local inputHelp = iconsole.auto_complete_help
	local fullHelp = iconsole.auto_complete_fullHelp
	local tAutoComplete = iconsole.auto_complete_tAutoComplete


	IA{iconsole.AddColorToText(inputHelp or "", COLOR_INPUT_NEXT)}
	if fullHelp and fullHelp != "" then
		IAN{}
		IAN{"--------------------------"}
		IA{fullHelp}
	end
	IA{""}

	local object = markup.Parse(text, Wide)
	local x, y = object:Size()


	surface.SetDrawColor(iclr.main.r, iclr.main.g, iclr.main.b, 200)
	surface.DrawRect(0,0,w,h)

	surface.SetDrawColor(0, 125, 0, 255)
	surface.DrawRect(SX-10,SY-10,x+20,y+20)

	surface.SetDrawColor(45, 45, 45, 255)
	surface.DrawRect(SX-5,SY-5,x+10,y+10)

	object:Draw(SX,SY)
end)

nt.Receive("zen.console.console_status", {"player", "bool"}, function(_, ply, bool)
	ply.zen_bConsoleStatus = bool
end)

local clr_def = Color(125,255,125)

ihook.Listen("PostDrawOpaqueRenderables", "npc_info", function()
	for k, ply in pairs(ents.FindByClass("player")) do
		if ply == LocalPlayer() then continue end
		if not ply.zen_bConsoleStatus then continue end

		local min, max = ply:GetModelBounds()
		local pos = ply:GetPos()
		pos.z = pos.z + max.z * 1.2


		--local ang = Angle(CurTime()%10,CurTime()%10,CurTime()%10)
		local ang = (ply:GetPos() - LocalPlayer():EyePos()):Angle()
		ang.p = 0
		ang.r = 90
		ang.y = ang.y - 90

		local sc = pos:ToScreen()
		local x, y = sc.x, sc.y

		cam.Start3D2D(pos, ang, 0.2)
			--ui.Box(-50,-50,50,50,clr.white)
			draw.SimpleText("In Console", "DebugOverlay", 0, 0, clr_def, 1,1)
		cam.End3D2D()
	end
end)

nt.Receive("zen.console.message", {"array:any"}, function(_, args)
    iconsole.AddConsoleLog(IS_MSGN, unpack(args))
end)

if epoe then
	ihook.Listen(epoe.TagHuman, "zen.console_log", function(msg, flags, color)
		iconsole.AddConsoleLog(flags, color, msg)
	end)
end