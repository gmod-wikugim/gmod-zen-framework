FAKE_PLAYER_COUNTER = (FAKE_PLAYER_COUNTER or 0) + 1

local PLAYER = setmetatable({}, {
    __tostring = function(self)
        return "Player [" .. self.iUserID .. "][" .. self.sNick .. "]"
    end
})

local base_sid = "STEAM_0:1:111111111"
local base_sid64 = "76561191111111111"
local base_accid = "1111111111"

function PLAYER:_Init()
    local ply = player.CreateNextBot("Debug_Fake_Player")

    if !IsValid(ply) then error("Max Slots!") end

    local userID = ply:UserID()

    ply:Kick("fake_player_kick")

    self.bFakeID = FAKE_PLAYER_COUNTER

    do
        local changeID = tostring(self.bFakeID)
        local len = #changeID

        self.sSteamID = string.sub(base_sid, 1, #base_sid - len) .. changeID
        self.sSteamID64 = string.sub(base_sid, 1, #base_sid64 - len) .. changeID
        self.sAccountID = string.sub(base_sid, 1, #base_accid - len) .. changeID
    end

    self.sUserGroup = "user"
    self.iTeam = TEAM_DEFAULT or TEAM_CITIZEN or team.BestAutoJoinTeam()

    self.iUserID = userID
    self.sNick = "FakePlayer: #" .. self.iUserID
    self.sModel = "models/player/mossman.mdl"
    self.objColor = Color(255,255,255)
end

function PLAYER:_OnMessageGet(...)
    MsgC("[FAKE-PLAYER][GetMessage]")
    MsgC(...)
end


-- Player Stuff

function PLAYER:SteamID64() return self.sSteamID64 end
function PLAYER:SteamID() return self.sSteamID end
function PLAYER:UserID() return self.iUserID end
function PLAYER:AccountID() return self.sAccountID end

function PLAYER:IsBot() return false end
function PLAYER:IsAdmin() return false end
function PLAYER:IsSuperAdmin() return false end
function PLAYER:Ping() return 0 end

function PLAYER:ChatPrint(...) return self:_OnMessageGet(..., "\n") end
function PLAYER:PrintMessage(type, message) return self:_OnMessageGet(message, "\n") end

function PLAYER:GetUserGroup() return self.sUserGroup end
function PLAYER:SetUserGroup(group) self.sUserGroup = group end

function PLAYER:Team() return self.iTeam end
function PLAYER:SetTeam(team) self.iTeam = team end

function PLAYER:Nick() return self.sNick end
function PLAYER:Name() return self.sNick end
function PLAYER:GetName() return self.sNick end

-- Entity Stuff

function PLAYER:GetModel() return self.sModel end
function PLAYER:SetModel(mdl) self.sModel = mdl end

function PLAYER:GetColor() return self.objColor end
function PLAYER:SetColor(mdl) self.objColor = mdl end


PLAYER:_Init()

return PLAYER
