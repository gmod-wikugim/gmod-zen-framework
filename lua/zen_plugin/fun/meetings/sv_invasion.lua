module("zen", package.seeall)

/*
    Invasion game event.

    Player start sick.
    If player sick, he will infect other players.
    If player sick to long, he will become zombie

    If player sick, but not become zombie, medic can heal him.

    When player respawn, he will not become human, he be zombie.
*/

---@class zen.fun.Invasion: zen.Meeting
local MEETING = meeting.GetMeta("invasion")


--- Becoming zombie
---@param ply Player
function MEETING:BecomeZombie(ply)
    -- Some stuff
    -- Emit sneez_become_zombie
    ply:EmitSound("zen_fun/sneez/sneez_become_zombie.mp3")

    self:SetPlayerData(ply, "becoming_zombie", true)

    self:PlayerTimerUnique(ply, "becoming_zombie", 16, 1, function(ply)
        self:SetPlayerData(ply, "becoming_zombie", false)
        self:SetPlayerData(ply, "is_zombie", false)

        self:NotifyPlayer(ply, "You have become a zombie!", NOTIFY_ERROR, 5)

        // TODO: SetPlayerClass infected
    end)
end


--- Try to infect player
---@param ply Player
function MEETING:TryInfectPlayer(ply)
    -- Give 40% change to infect player
    if math.random(1, 100) <= 40 then
        self:AddPlayer(ply)
        self:StartSicking(ply)
    end
end

--- Player sneeze
---@param ply Player
function MEETING:Sneeze(ply)
    -- EmitSneeze sound

    -- Random 1-2 sneeze sound
    ply:EmitSound("zen_fun/sneez/sneez" .. math.random(1, 2) .. ".mp3")

    -- Search nearby players
    local nearbyPlayers = ents.FindInSphere(ply:GetPos(), 300)
    for _, v in ipairs(nearbyPlayers) do
        if v:IsPlayer() then
            -- Infect player
            self:TryInfectPlayer(v)
        end
    end
end

--- OnThink meeting player only sneeze every 30 seconds
function MEETING:OnThink()
    for _, ply in pairs(self:GetPlayers()) do
        if self:GetPlayerData(ply, "is_sick") then
            -- Use PlayerDelay
            self:PlayerDelay(ply, "sneeze", 30, function(ply)
                self:Sneeze(ply)
            end)
        end
    end
end

-- Start sicking
---@param ply Player
function MEETING:StartSicking(ply)
    self:SetPlayerData(ply, "is_sick", true)

    self:NotifyPlayer(ply, "You have been sicked!", NOTIFY_ERROR, 5)
end

-- Heal player
---@param ply Player
function MEETING:HealPlayer(ply)
    self:NotifyPlayer(ply, "You have been healed!", NOTIFY_GENERIC, 5)
end


function MEETING:OnPlayerJoin(ply)
    self:NotifyPlayer(ply, "You have joined the invasion meeting!", NOTIFY_GENERIC, 5)
end

function MEETING:OnPlayerLeave(ply, type)
    if type == "disconnect" then
        self:NotifyPlayer(ply, "You have been disconnected from the invasion meeting!", NOTIFY_ERROR, 5)
    end

    if type == "kick" then
        self:NotifyPlayer(ply, "You have been kicked from the invasion meeting!", NOTIFY_ERROR, 5)
    end

    if type == "by_self" then
        self:NotifyPlayer(ply, "You have left the invasion meeting!", NOTIFY_GENERIC, 5)
    end

    if type == "timeout" then
        self:NotifyPlayer(ply, "You have been timed out from the invasion meeting!", NOTIFY_ERROR, 5)
    end

    if type == "close" then
        self:NotifyPlayer(ply, "The invasion meeting has been closed!", NOTIFY_GENERIC, 5)
    end
end

meeting.Register(MEETING)

concommand.Add("start_sick", function(ply)

    local invasion = meeting.GetInitialized("invasion")
    ---@cast invasion zen.fun.Invasion

    if !invasion:IsPlayerInMeeting(ply) then
        invasion:AddPlayer(ply)
    end

    invasion:StartSicking(ply)
end)