local KeyCombinations = {}
local KeyCombinationsMass = {}
local KeyPressed = {}

function input.SetupCombination(name, ...)
	KeyCombinations[name] = {}
	for k, v in pairs({...}) do
		KeyCombinations[name][v] = true
	end
	KeyCombinationsMass[name] = 0
end

function input.IsCombinationActive(name)
	return KeyCombinationsMass[name] and KeyCombinationsMass[name] > 0
end

function input.IsKeyPressed(but)
    return KeyPressed[but]
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
	local BIND = BindList[BUTTON_IN]
	if not BIND then return end
	local CHAR = input.LookupBinding(BIND)
	local BUTTON_ID = input.GetKeyCode(CHAR)

	return input.IsKeyPressed(BUTTON_ID) or input.IsKeyDown(BUTTON_ID)
end

ihook.Listen("PlayerButtonUp", "fast_console_phrase", function(ply, but)
	if KeyPressed[but] then
		KeyPressed[but] = nil
		for name, keys in pairs(KeyCombinations) do
			if keys[but] then
				KeyCombinationsMass[name] = math.max(0, KeyCombinationsMass[name] - 1)
			end
		end
		ihook.Run("PlayerButtonUnPress", ply, but)
	end

	if ihook.Run("PlayerButtonUp.SupperessNext") then return true end
end, HOOK_HIGH)

ihook.Listen("PlayerButtonDown", "fast_console_phrase", function(ply, but)
	if !KeyPressed[but] then
		KeyPressed[but] = true

		for name, keys in pairs(KeyCombinations) do
			if keys[but] then
				KeyCombinationsMass[name] = KeyCombinationsMass[name] + 1
			end
		end
		ihook.Run("PlayerButtonPress", ply, but)
	end

	if ihook.Run("PlayerButtonDown.SupperessNext") then return true end
end, HOOK_HIGH)

input.SetupCombination("Modificator", KEY_LCONTROL, KEY_RCONTROL, KEY_LSHIFT, KEY_RSHIFT)