zen.nvars.mt_EntityButtons = {}

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


function zen.nvars.OpenMenu(ent)
    local vars = zen.nvars.FetchEntityData(ent)

    if vars.iCounter == 0 then return end

    local pnl = vgui.Create("zen.properties")
    pnl:SetPos(input.GetCursorPos())
    pnl:SetSize(300, 500)
    pnl:MakePopup()

    pnl:SetupData(ent, vars)
end


hook.Add("zen.worldclick.onHoverEntity", "zen.nvars", function(ent, tr)
    zen.nvars.mt_EntityButtons= nil
    nt.Send("nvars.get_buttons", {"entity"}, {ent})
end)

hook.Add("zen.worldclick.onPressEntity", "zen.nvars", function(ent, code, tr)
    if code == MOUSE_LEFT then
        local tButton = zen.nvars.HoveredTButton
        if tButton.id then
            nt.Send("nvars.run_command", {"entity", "int12", "next", "any"}, {ent, tButton.id, tButton.mode != nil and true or false, tButton.mode})
            return
        end
    end

    if code == MOUSE_RIGHT then
	    zen.nvars.OpenMenu(ent)
    end
end)

nt.Receive("nvars.get_buttons", {"entity", "table"}, function(ent, tButtons)
    zen.nvars.mt_EntityButtons = tButtons
end)