input.KeyPressedCounter = input.KeyPressedCounter or {}
local KeyPressed = {}
local BindPressed = {}
local KeyINPressed = {}
local input_IsButtonDown = input.IsButtonDown
local input_IsKeyDown = input.IsKeyDown
local input_IsMouseDown = input.IsMouseDown
local input_WasKeyTyped = input.WasKeyTyped
local input_WasKeyPressed = input.WasKeyPressed
local input_GetKeyName = input.GetKeyName
local input_LookupBinding = input.LookupBinding
local input_LookupKeyBinding = input.LookupKeyBinding
local input_IsShiftDown = input.IsShiftDown
local LocalPlayer = LocalPlayer

local gui_IsGameUIVisible = gui.IsGameUIVisible
local vgui_CursorVisible = vgui.CursorVisible
local vgui_GetKeyboardFocus = vgui.GetKeyboardFocus
local IsValid = IsValid
local HasFocus = META.PANEL.HasFocus

local math_min = math.min
local math_max = math.max

local KeyPressed_GameUI = {}
local KeyPressed_Cursor = {}
local KeyPressed_VGUI_Input = {}
local KeyPressed_Normal = {}
local KeyPressed_Chars = {}
local LastKeysPhrase = ""
local LastPressed_Button
local LastPressed_KeyIN
local LastPressed_KeyBind

local LastReleased_Button
local LastReleased_KeyIN
local LastReleased_KeyBind

local len = utf8.len
local sub = utf8.sub

local concat = table.concat

function input.LastPressedButton() return LastPressed_Button end
function input.LastPressedKeyIN() return LastPressed_KeyIN end
function input.LastPressedKeyBind() return LastPressed_KeyBind end

function input.LastReleasedButton() return LastReleased_Button end
function input.LastReleasedKeyIN() return LastReleased_KeyIN end
function input.LastReleasedKeyBind() return LastReleased_KeyBind end

function input.GetPressedButtons()
	return table.Copy(KeyPressed)
end

function input.IsKeyPressed(but)
    return KeyPressed[but]
end

function input.GetLastPhrase()
	return LastKeysPhrase
end

function input.ClearLastPhrase()
	LastKeysPhrase = ""
end

function input.IsLastPhrase(str)
	return sub(LastKeysPhrase, -len(str)) == str
end

local BindList = {}
BindList[IN_ATTACK] = "+attack"
BindList[IN_JUMP] = "+jump"
BindList[IN_DUCK] = "+duck"
BindList[IN_FORWARD] = "+forward"
BindList[IN_BACK] = "+back"
BindList[IN_USE] = "+use"
BindList[IN_LEFT] = "+left"
BindList[IN_RIGHT] = "+right"
BindList[IN_MOVELEFT] = "+moveleft"
BindList[IN_MOVERIGHT] = "+moveright"
BindList[IN_ATTACK2] = "+attack2"
BindList[IN_RELOAD] = "+reload"
BindList[IN_ALT1] = "+alt1"
BindList[IN_ALT2] = "+alt2"
BindList[IN_SCORE] = "+showscores"
BindList[IN_SPEED] = "+speed"
BindList[IN_WALK] = "+walk"
BindList[IN_ZOOM] = "+zoom"
BindList[IN_GRENADE1] = "+grenade1"
BindList[IN_GRENADE2] = "+grenade2"
for k, v in pairs(BindList) do
	BindList[v] = k
end

function input.IsPressedBind(bind_string)
	return BindPressed[bind_string]
end

function input.IsPressedIN(key_in)
	return KeyINPressed[key_in]
end

function input.GetButtonIN(BUTTON_ID)
	local bind = input.LookupKeyBinding(BUTTON_ID)
	if bind and BindList[bind] then
		return BindList[bind]
	else
		return -1
	end
end

function input.IsButtonIN(BUTTON_ID, BUTTON_IN)
	return input.GetButtonIN(BUTTON_ID) == BUTTON_IN
end

function input.IsButtonPressedIN(BUTTON_IN)
	if KeyINPressed[BUTTON_IN] then return true end
	local BIND = BindList[BUTTON_IN]
	if not BIND then return end
	local CHAR = input.LookupBinding(BIND)
	local BUTTON_ID = input.GetKeyCode(CHAR)

	return input.IsKeyPressed(BUTTON_ID) or input.IsKeyDown(BUTTON_ID)
end

local KEY_SINGLE_REPLACER = {
	[KEY_SPACE] = " ",
	[KEY_PAD_0] = "0",
	[KEY_PAD_1] = "1",
	[KEY_PAD_2] = "2",
	[KEY_PAD_3] = "3",
	[KEY_PAD_4] = "4",
	[KEY_PAD_5] = "5",
	[KEY_PAD_6] = "6",
	[KEY_PAD_7] = "7",
	[KEY_PAD_8] = "8",
	[KEY_PAD_9] = "9",
	[KEY_PAD_DIVIDE] = "/",
	[KEY_PAD_MULTIPLY] = "*",
	[KEY_PAD_MINUS] = "-",
	[KEY_PAD_PLUS] = "+",
	[KEY_PAD_DECIMAL] = ".",
	[KEY_SEMICOLON] = ":",
}

function input.GetButtonChar(but)
	local char = KEY_SINGLE_REPLACER[but] or input.GetKeyName(but)
	if isstring(char) and len(char) == 1 then
		if input_IsShiftDown() then
			char = util.StringUpper(char)
		end

		return char
	end
end


local function playerButtonUp(ply, but)
	if !KeyPressed[but] then return end
	ply = ply or LocalPlayer()

	KeyPressed[but] = nil
	local bind_name = input.LookupKeyBinding(but)
	if bind_name then
		BindPressed[bind_name] = nil
	end
	local in_key = input.GetButtonIN(but)
	if KeyINPressed then
		KeyINPressed[in_key] = nil
	end

	LastReleased_Button = but
	LastReleased_KeyIN = in_key
	LastReleased_KeyBind = bind_name

	local char = KeyPressed_Chars[but]
	if char then
		KeyPressed_Chars[but] = nil
		ihook.Run("PlayerButtonUnPress.char", ply, but, in_key, bind_name, char)
	end

	if KeyPressed_GameUI[but] then
		KeyPressed_GameUI[but] = true
		ihook.Run("PlayerButtonUnPress.gameui", ply, but, in_key, bind_name, char)
	end

	if KeyPressed_Cursor[but] then
		KeyPressed_Cursor[but] = nil
		ihook.Run("PlayerButtonUnPress.cursor", ply, but, in_key, bind_name, char)
	end

	if KeyPressed_VGUI_Input[but] then
		KeyPressed_VGUI_Input[but] = nil
		ihook.Run("PlayerButtonUnPress.vgui_input", ply, but, in_key, bind_name, char)
	end

	if KeyPressed_Normal[but] then
		KeyPressed_Normal[but] = true
		ihook.Run("PlayerButtonUnPress.normal", ply, but, in_key, bind_name, char)
	end

	ihook.Run("PlayerButtonUnPress", ply, but, in_key, bind_name, char)
end

local function playerButtonDown(ply, but)
	if KeyPressed[but] then return end
	ply = ply or LocalPlayer()

	input.KeyPressedCounter[but] = (input.KeyPressedCounter[but] or 0) + 1

	KeyPressed[but] = true

	local bind_name = input_LookupKeyBinding(but)
	if bind_name then
		BindPressed[bind_name] = true
	end

	local in_key = input.GetButtonIN(but)
	if KeyINPressed then
		KeyINPressed[in_key] = true
	end

	LastPressed_Button = but
	LastPressed_KeyIN = in_key
	LastPressed_KeyBind = bind_name

	local char = input.GetButtonChar(but)
	if char then
		local new_phrase = concat({LastKeysPhrase, char})
		local ph_len = len(new_phrase)

		local start = math_max(ph_len - 255, 1)

		LastKeysPhrase = sub(new_phrase, start, ph_len)
		KeyPressed_Chars[but] = true

		ihook.Run("PlayerButtonPress.char", ply, but, in_key, bind_name, char)
	end

	local gameui_enabled = gui_IsGameUIVisible()
	if gameui_enabled then
		KeyPressed_GameUI[but] = true
		ihook.Run("PlayerButtonPress.gameui", ply, but, in_key, bind_name, char)
	end

	local isCursorVisible = vgui_CursorVisible()
	if isCursorVisible then
		KeyPressed_Cursor[but] = true
		ihook.Run("PlayerButtonPress.cursor", ply, but, in_key, bind_name, char)
	end

	local vgui_text_input = vgui_GetKeyboardFocus()
	local vgui_input = IsValid(vgui_text_input) and HasFocus(vgui_text_input)
	if vgui_input then
		KeyPressed_VGUI_Input[but] = true
		ihook.Run("PlayerButtonPress.vgui_input", ply, but, in_key, bind_name, char)
	end

	if gameui_enabled != true and isCursorVisible != true and vgui_input != true then
		KeyPressed_Normal[but] = true
		ihook.Run("PlayerButtonPress.normal", ply, but, in_key, bind_name, char)
	end

	ihook.Run("PlayerButtonPress", ply, but, in_key, bind_name, char)
end


ihook.Handler('Think', "TestKeyPress", function()
	for key = KEY_FIRST, MOUSE_5 do
		if input_IsButtonDown(key) then
			if not KeyPressed[key] then
				playerButtonDown(nil, key)
			end
		else
			if KeyPressed[key] then
				playerButtonUp(nil, key)
			end
		end
	end
end)

local Allowed = {
	[MOUSE_WHEEL_DOWN] = true,
	[MOUSE_WHEEL_UP] = true,
}

ihook.Handler("PlayerButtonUp", "fast_console_phrase", function(ply, but)
	if Allowed[but] then
		playerButtonDown(ply, but)
	end

	if ihook.Run("PlayerButtonUp.SupperessNext") then return true end
end, HOOK_HIGH)

ihook.Handler("PlayerButtonDown", "fast_console_phrase", function(ply, but)
	if Allowed[but] then
		playerButtonUp(ply, but)
	end

	if ihook.Run("PlayerButtonDown.SupperessNext") then return true end
end, HOOK_HIGH)