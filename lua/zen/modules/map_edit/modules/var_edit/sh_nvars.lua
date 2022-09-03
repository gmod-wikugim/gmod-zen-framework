iperm.RegisterPermission("zen.variable_edit.nvars", iperm.flags.NO_TARGET, "Access to edit entity nvars!")

izen.nvars = izen.nvars or {}
zen.nvars = izen.nvars

zen.nvars.TYPE_NVARS = 1
zen.nvars.TYPE_NWVARS = 2
zen.nvars.TYPE_SETVARS = 3
zen.nvars.TYPE_FUNC = 4
zen.nvars.TYPE_VARIABLE = 5

zen.nvars.ents_base = {}
zen.nvars.ents_base["player"] = {"Health", "Armor", "MaxHealth", "MaxArmor", "Name", "Model"}

function zen.nvars.FetchEntityData(ent)
    local tResult = {}

    tResult.iCounter = 0
    local nvars = ent.GetNetworkVars and ent:GetNetworkVars() or {}
    tResult.NVars = {}
    if nvars then
        for k, v in pairs(nvars) do
            tResult.iCounter = tResult.iCounter + 1
            tResult.NVars[k] = {
                value = v,
                type = typen(v),
            }
        end
    end

    local nwvars = ent.GetNetworkVars and ent:GetNetworkVars() or {}
    tResult.NWVars = {}
    if nwvars then
        for k, v in pairs(nwvars) do
            tResult.iCounter = tResult.iCounter + 1
            tResult.NWVars[k] = {
                value = v,
                type = typen(v),
            }
        end
    end


    local ent_table = ent.GetTable and ent:GetTable() or {}
    tResult.Internal_SetValues = {}
    if ent_table then
        for k, v in pairs(ent_table) do
            if not isstring(k) then continue end
            if not isfunction(v) then continue end

            if k:sub(1, 3) != "Set" then continue end

            tResult.iCounter = tResult.iCounter + 1

            local var = k:sub(4)
            if tResult.NVars[var] or tResult.NWVars[var] then continue end
            local tDebug = debug.getupvalues(v)

            local args = {}
            for k, v in pairs(tDebug) do
                table.insert(args, k)
            end

            tResult.Internal_SetValues[var] = {
                value = v,
                type = typen(n),
                args =  table.concat(args, ","),
            }
        end
    end

    return tResult
end