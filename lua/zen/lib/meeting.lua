module("zen", package.seeall)

meeting = _GET("meeting")

---@type table<string, zen.Meeting>
meeting.mt_MettingMeta = meeting.mt_MettingMeta or {}

---@type table<string, zen.Meeting>
meeting.mt_MettingInitialized = meeting.mt_MettingInitialized or {}



---@alias zen.MeetingKickType
---| '"disconnect"'
---| '"kick"'
---| '"by_self"'
---| '"timeout"'
---| '"close"'

/*
    Meeting system for garry's mod.
    Allow you to start event/meeting where player can fun and play games.

    Mining system contain:
    Start() - Start the meeting
    Close() - Close the meeting
    PlayerJoin(ply)  - Called when player join the meeting
    PlayerLeave(ply) - Called when player leave the meeting

    Every call shoud call hook.Run

*/

---@class zen.Meeting
---@field id string
---@field package isMeeting boolean
---@field package isInfinity boolean
---@field package duration number|0
---@field package startTime number
---@field package endTime? number
---@field package players table<string, Player> SteamID/Player
---@field OnStart? fun()
---@field OnClose? fun()
---@field OnPlayerJoin? fun(self, ply: Player)
---@field OnPlayerLeave? fun(self, ply: Player, type: zen.MeetingKickType)
---@field OnThink? fun(self)
---@field OnInit? fun(self)

---@class zen.Meeting
meeting.META = meeting.META or {}

---@class zen.Meeting
local MEMETA = meeting.META
MEMETA.__index = MEMETA

-- Init the meeting
---@param id string
function MEMETA:Init(id)
    self.id = id
    self.isMeeting = false
    self.isInfinity = false
    self.duration = 0
    self.startTime = 0
    self.endTime = 0
    self.players = {}
    self.bInitialized = true
    self.player_data = {}
    self.player_timers = {}
    self.player_delays = {}

    if SERVER then
        self.RecipientFilter_players = RecipientFilter()
    end

    -- Call OnInit
    if self.OnInit then
        self:OnInit()
    end
end

-- Meta IsValid for hooks
---@package
---@return boolean
function MEMETA:IsValid()
    return self.isMeeting
end

-- Meta Is Player in meeting
---@param ply Player
---@return boolean
function MEMETA:IsPlayerInMeeting(ply)
    local userID = ply:UserID()

    return self.players[userID] ~= nil
end

-- SetPlayerData
---@param ply Player
---@param key string
---@param value any
function MEMETA:SetPlayerData(ply, key, value)
    local userID = ply:UserID()

    if not self.player_data[userID] then
        self.player_data[userID] = {}
    end

    self.player_data[userID][key] = value
end

-- GetPlayerData with default setup
---@param ply Player
---@param key string
---@param default any
---@return any
function MEMETA:GetPlayerData(ply, key, default)
    local userID = ply:UserID()

    if not self.player_data[userID] then
        self.player_data[userID] = {}
    end

    local value = self.player_data[userID][key]

    -- SetPlayerData to default is value if not exists, but default exists
    if not value and default then
        self:SetPlayerData(ply, key, default)
        return default
    end

    return value
end

-- InitPlayerData
---@param ply Player
function MEMETA:InitPlayerData(ply)
    local userID = ply:UserID()

    self.players[userID] = ply

    if not self.player_data[userID] then
        self.player_data[userID] = {}
    end

    if not self.player_timers[userID] then
        self.player_timers[userID] = {}
    end

    if not self.player_delays[userID] then
        self.player_delays[userID] = {}
    end

    self.RecipientFilter_players:AddPlayer(ply)
end

-- ClearPlayerData
---@param ply Player
function MEMETA:ClearPlayerData(ply)
    local userID = ply:UserID()

    self.players[userID] = nil
    self.player_data[userID] = nil
    self.player_delays[userID] = nil

    self.RecipientFilter_players:RemovePlayer(ply)

    -- Remove player times
    if self.player_timers[userID] then
        for id, time_end in pairs(self.player_timers[userID]) do
            if time_end <= CurTime() then continue end

            self:StopPlayerTimer(ply, id)
        end
        self.player_timers[userID] = nil
    end
end

-- Check delay for player
---@param ply Player
---@param id string
---@param delay number
---@param onTime fun(ply: Player)
---@return boolean
function MEMETA:PlayerDelay(ply, id, delay, onTime)
    local userID = ply:UserID()

    if not self.player_delays[userID] then
        self.player_delays[userID] = {}
    end

    if not self.player_delays[userID][id] then
        self.player_delays[userID][id] = CurTime()
        if onTime then onTime(ply) end
        return true
    end

    if CurTime() - self.player_delays[userID][id] >= delay then
        self.player_delays[userID][id] = CurTime()
        if onTime then onTime(ply) end
        return true
    end

    return false
end


-- Simple timer, with check is event isMeeting
---@param time number
---@param callback fun()
function MEMETA:SimpleTimer(time, callback)
    if not self.isMeeting then
        return
    end

    timer.Simple(time, function()
        if not self.isMeeting then
            return
        end

        callback()
    end)
end


-- PlayerTimer with check is event isMeeting and player IsValid
---@param ply Player
---@param time number
---@param callback fun(ply: Player)
function MEMETA:PlayerTimer(ply, time, callback)
    if not self.isMeeting then
        return
    end

    timer.Simple(time, function()
        if !IsValid(ply) then return end
        if !self.isMeeting then return end

        callback(ply)
    end)
end

--- GetPlayerTimerUniqueName
---@param ply Player
---@param id string
---@return string
function MEMETA:GetPlayerTimerUniqueName(ply, id)
    return "zen.meeting." .. self.id .. ".player_timer." .. ply:UserID() .. "." .. id
end

-- PlayerTimer with unique id with check is event isMeeting and player IsValid
---@param ply Player
---@param id string
---@param time number
---@param repeat_count? number|1
---@param callback fun(ply: Player)
function MEMETA:PlayerTimerUnique(ply, id, time, repeat_count, callback)
    if not self.isMeeting then
        return
    end

    repeat_count = repeat_count or 1

    local userID = ply:UserID()

    local timer_name = self:GetPlayerTimerUniqueName(ply, id)

    timer.Create(timer_name, time, repeat_count, function()
        if !IsValid(ply) then return end
        if !self.isMeeting then return end

        callback(ply)
    end)

    -- Add timer to self.player_timers
    if not self.player_timers[userID] then
        self.player_timers[userID] = {}
    end

    -- Add timer with timer end time
    self.player_timers[userID][id] = CurTime() + time
end

--- StopPlayerTimer with unique id
---@param ply Player
---@param id string
function MEMETA:StopPlayerTimer(ply, id)
    local timer_name = self:GetPlayerTimerUniqueName(ply, id)

    timer.Remove(timer_name)
end

-- Add/invite player to meeting
---@param ply Player
function MEMETA:AddPlayer(ply)
    if self:IsPlayerInMeeting(ply) then
        return
    end

    self:PlayerJoin(ply)
end

-- GetPlayers
---@return table<string, Player>
function MEMETA:GetPlayers()
    return self.players
end

-- Kick Player from meeting
---@param ply Player
---@param type? zen.MeetingKickType
function MEMETA:KickPlayer(ply, type)
    type = type or "kick"
    if not self:IsPlayerInMeeting(ply) then
        return
    end

    self:PlayerLeave(ply, type)

    -- Call the hook
    hook.Run("zen.OnPlayerKick", self, ply, type)
end

---@package
--- Init hooks
function MEMETA:InitHooks()
    -- Add think hooks
    hook.Add("Think", self, function()
        if self.isMeeting then
            if not self.isInfinity and CurTime() >= self.endTime then
                self:Close()
            end
        end

        if self.isMeeting then
            if self.OnThink then
                self:OnThink()
            end
        end
    end)

    -- Kick player from event if player disconnect
    hook.Add("PlayerDisconnected", self, function(ply)
        if self.isMeeting then
            self:KickPlayer(ply, "disconnect")
        end
    end)
end


---@package
-- Start the meeting
---@param duration? number|0 -- In munites, 0 for infinity
function MEMETA:Start(duration)
    self.isMeeting = true
    self.startTime = CurTime()

    -- Check infinity
    if duration == 0 then
        self.isInfinity = true
    else
        self.endTime = CurTime() + self.duration
    end

    self.players = {}

    --Check if exists
    if self.OnStart then
        self:OnStart()
    end

    self:InitHooks()

    -- Call the hook
    hook.Run("zen.OnMeetingStart", self)
end

---@package
-- Close the meeting
function MEMETA:Close()
    self.isMeeting = false
    self.endTime = CurTime()

    -- Check if exists
    if self.OnClose then
        self:OnClose()
    end

    -- Kick all player from event
    for _, ply in ipairs(self.players) do
        self:KickPlayer(ply, "close")
    end

    -- Call the hook
    hook.Run("zen.OnMeetingClose", self)
end


-- Send message to everyone in the meeting
function MEMETA:MessageAll(text)
    msg.ChatMessage(self.RecipientFilter_players, text)
end

-- Send notify to everyone in the meeting
function MEMETA:NotifyAll(text, notify_type, length)
    notify_type = notify_type or NOTIFY_HINT
    length = length or 5
    msg.Notify(self.RecipientFilter_players, text, notify_type, length)
end

-- Send message to player in the meeting
function MEMETA:MessagePlayer(ply, text)
    msg.ChatMessage(ply, text)
end

-- Send notify to player in the meeting
function MEMETA:NotifyPlayer(ply, text, notify_type, length)
    notify_type = notify_type or NOTIFY_HINT
    length = length or 5

    msg.Notify(ply, text, notify_type, length)
end


--- Called when player join the meeting
---@package
---@param ply Player
function MEMETA:PlayerJoin(ply)
    -- Insert Player to players
    local userID = ply:UserID()
    self.players[userID] = ply

    -- Call OnPlayerJoin
    if self.OnPlayerJoin then
        self:OnPlayerJoin(ply)
    end

    -- Call the hook
    hook.Run("zen.PlayerJoin", self, ply)
end

--- Called when player leave the meeting
---@package
---@param ply Player
---@param type zen.MeetingKickType
function MEMETA:PlayerLeave(ply, type)
    self:ClearPlayerData(ply)

    -- Call OnPlayerLeave
    if self.OnPlayerLeave then
        self:OnPlayerLeave(ply, type)
    end

    -- Call the hook
    hook.Run("zen.PlayerLeave", self, ply)
end


---@param uniqueID string
---@return zen.Meeting
function meeting.GetMeta(uniqueID)
    if !meeting.mt_MettingMeta[uniqueID] then
        meeting.mt_MettingMeta[uniqueID] = {}
    end

    local UNIQUE_META = meeting.mt_MettingMeta[uniqueID]
    UNIQUE_META.id = UNIQUE_META.id

    setmetatable(UNIQUE_META, meeting.META)

    return UNIQUE_META
end

---@param UNIQUE_META zen.Meeting
function meeting.Register(UNIQUE_META)

    --- Auto-Reactivate-For-Initialized
    if UNIQUE_META.id then
        local INITIALIZED = meeting.mt_MettingInitialized[UNIQUE_META.id]
        if INITIALIZED and INITIALIZED:IsActive() then
            INITIALIZED:Disable()

            table.Empty(INITIALIZED)
            table.Merge(INITIALIZED, UNIQUE_META, true)

            setmetatable(INITIALIZED, meeting.META)

            INITIALIZED:Enable()
        end
    end

end



---@param uniqueID string
---@return zen.Meeting
function meeting.GetInitialized(uniqueID)
    if !meeting.mt_MettingInitialized[uniqueID] then
        local UNIQUE_META = meeting.GetMeta(uniqueID)

        local LIVE = table.Copy(UNIQUE_META)

        setmetatable(LIVE, meeting.META)
        LIVE:Init(LIVE.id)
        meeting.mt_MettingInitialized[uniqueID] = LIVE
    end

    return meeting.mt_MettingInitialized[uniqueID]
end