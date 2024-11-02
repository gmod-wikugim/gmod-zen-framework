module("zen", package.seeall)

nt.mt_EntityVars = nt.mt_EntityVars or {}
local id, tChannel = nt.RegisterChannel("entity_var", nt.t_ChannelFlags.PUBLIC, {
    id = 10,
    priority = 10,
    types = {"uint16", "string_id", "any"},
    Init = function(self)
        self.tContent = self.tContent or {}
        self.iCounter = self.iCounter or 0
    end,
    OnWrite = function(self, target, ent_id, key, value)
        if SERVER then
            local tContent = self.tContent

            if not tContent[ent_id] then
                tContent[ent_id] = 0
                nt.mt_EntityVars[ent_id] = {}
                self.iCounter = self.iCounter + 1
            end
            local IsDelete = value == nil
            local tVars = nt.mt_EntityVars[ent_id]

            if tVars[key] and IsDelete then
                tContent[ent_id] = tContent[ent_id] - 1
            elseif tVars[key] == nil and not IsDelete then
                tContent[ent_id] = tContent[ent_id] + 1
            end

            nt.mt_EntityVars[ent_id][key] = value

            local ent = Entity(ent_id)
            if IsValid(ent) and nt.mt_EntityVars[ent_id] then
                nt.mt_EntityVars[ent] = nt.mt_EntityVars[ent_id]
            end
        end
    end,
    OnRead = function(self, target, ent_id, key, value)
        if CLIENT then
            nt.mt_EntityVars[ent_id] = nt.mt_EntityVars[ent_id] or {}
            nt.mt_EntityVars[ent_id][key] = value

            local ent = Entity(ent_id)
            if ent then
                nt.mt_EntityVars[ent] = nt.mt_EntityVars[ent_id]
            end
        end
    end,
    WritePull = function(self, target)
        local tContent = self.tContent

        net.WriteUInt(self.iCounter, 12)
        for ent_id, v in pairs(tContent) do
            net.WriteUInt(ent_id, 16)
            net.WriteUInt(tContent[ent_id], 12)
            local tVars = nt.mt_EntityVars[ent_id]
            for key, value in pairs(tVars) do
                nt.Write({"string_id", "any"}, {key, value})
            end
        end
    end,
    ReadPull = function(self, addResult)
        self.iCounter = net.ReadUInt(12)
        for k = 1, self.iCounter do
            local ent_id = net.ReadUInt(16)
            local iCounter = net.ReadUInt(12)
            for k = 1, iCounter do
                local k, v = nt.Read({"string_id", "any"})
                addResult(ent_id, k, v)
            end
        end
    end,
})
local tContent = tChannel.tContent


local function RemoveID(ent_id)
    if ent_id then
        nt.mt_EntityVars[ent_id] = nil
        local ent = Entity(ent_id)
        if ent then
            nt.mt_EntityVars[ent] = nil
        end


        if not tContent[ent_id] then return end
        tChannel.iCounter = tChannel.iCounter - 1
        tContent[ent_id] = nil
    end
end

if CLIENT then
    ihook.Listen("EntityRemoved", "zen.nt.entity_vars", function(ent, bFullUpdate)
        if !bFullUpdate then return end

        RemoveID(ent:EntIndex())
    end)
end

if CLIENT then
    ihook.Listen("NetworkEntityCreated", "zen.nt.entity_vars", function(ent)
        local index = ent:EntIndex()
        if nt.mt_EntityVars[index] then
            nt.mt_EntityVars[ent] = nt.mt_EntityVars[index]
        end
    end)
end

function META.ENTITY:zen_GetVar(key)
    if not nt.mt_EntityVars[self] then return end

    return nt.mt_EntityVars[self][key]
end

function META.ENTITY:zen_SetVar(key, value, target)
    if CLIENT then
        nt.mt_EntityVars[self] = nt.mt_EntityVars[self] or {}
        nt.mt_EntityVars[self][key] = value
    end
    if SERVER then
        nt.SendToChannel("entity_var", target, self:EntIndex(), key, value)
    end
end