nt.mt_EntityVars = nt.mt_EntityVars or {}
local id, tChannel, tContent = nt.RegisterChannel("entity_var", nt.t_ChannelFlags.ENTITY_KEY_VALUE, {
    id = 10,
    priority = 10,
    types = {"uint16", "string_id", "any"},
    fSaving = function(tChannel, tContent, ent_id, key, value)
        if not tContent[ent_id] then
            tContent[ent_id] = 0
            nt.mt_EntityVars[ent_id] = {}
            tChannel.iCounter = tChannel.iCounter + 1
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
    end,
    fPostReader = function(tChannel, ent, key, value)
    end,
    fPullWriter = function(tChannel, tContent, ply)
        net.WriteUInt(tChannel.iCounter, 12)
        for ent_id, v in pairs(tContent) do
            net.WriteUInt(ent_id, 16)
            net.WriteUInt(tContent[ent_id], 12)
            local tVars = nt.mt_EntityVars[ent_id]
            for key, value in pairs(tVars) do
                nt.Write({"string_id", "any"}, {key, value})
            end
        end
    end,
    fPullReader = function(tChannel, tContent, tResult)
        tChannel.iCounter = net.ReadUInt(12)
        for k = 1, tChannel.iCounter do
            local ent_id = net.ReadUInt(16)
            local iCounter = net.ReadUInt(12)
            for k = 1, iCounter do
                local k, v = nt.Read({"string_id", "any"})
                table.insert(tResult, {ent_id, k, v })
            end
        end
    end,
})

nt.RegisterChannel("entity_removed")

if SERVER then
    hook.Add("EntityRemoved", "zen.nt.entity_vars", function(ent)
        local ent_id = ent:EntIndex()
        if not tContent[ent_id] then return end

        tChannel.iCounter = tChannel.iCounter - 1
        tContent[ent_id] = nil
        nt.mt_EntityVars[ent_id] = nil
        nt.mt_EntityVars[ent] = nil

        if SERVER then
            nt.Send("entity_removed", {"uint16"}, {ent_id})
        end
    end)
end

if CLIENT then
    nt.Receive("entity_removed", {"uint16"}, function(ent_id)
        if not tContent[ent_id] then return end

        tChannel.iCounter = tChannel.iCounter - 1
        tContent[ent_id] = nil
        nt.mt_EntityVars[ent_id] = nil
        nt.mt_EntityVars[Entity(ent_id)] = nil
    end)

    hook.Add("NetworkEntityCreated", "zen.nt.entity_vars", function(ent)
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
        nt.mt_EntityVars[self][key] = value
    end
    if SERVER then
        nt.SendToChannel("entity_var", target, self:EntIndex(), key, value)
    end
end