module("zen", package.seeall)

zen.nvars.mt_EntityButtons = {}

function zen.nvars.OpenMenu(ent)
    local vars = zen.nvars.FetchEntityData(ent)

    if vars.iCounter == 0 then return end

    local pnl = vgui.Create("zen.properties")
    pnl:SetPos(input.GetCursorPos())
    pnl:SetSize(300, 500)

    pnl:SetupData(ent, vars)
end


ihook.Listen("zen.worldclick.onHoverEntity", "zen.nvars", function(ent, tr)
    zen.nvars.mt_EntityButtons= nil
    nt.Send("nvars.get_buttons", {"entity"}, {ent})
end)

ihook.Listen("zen.worldclick.onPressEntity", "zen.nvars", function(ent, code, tr)
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

nt.Receive("nvars.get_buttons", {"entity", "table"}, function(_, ent, tButtons)
    zen.nvars.mt_EntityButtons = tButtons
end)