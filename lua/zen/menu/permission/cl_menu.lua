module("zen", package.seeall)

local string_find = string.find




function iperm.CreatePlayerPermissionMenu(SteamID64)
    local FEATURES = {}

    local pnlFrame = gui.CreateStyled("frame", nil, "player_permissions", {
        size = {400, 500}
    })
    pnlFrame:SetTitle(SteamID64)

    if _CFG.Admins[SteamID64] then
        gui.Create("DLabel", pnlFrame, {
            "dock_top", text = "Player is absolute administrator!", content_align = 5, text_color = COLOR.GREEN,
            tall = 15, font = ui.ffont(8)
        })
        pnlFrame.PaintOver = function(self, w, h)
            local color = HSVToColor(  ( CurTime() * 100 ) % 360, 1, 1 )
            draw.BoxOutlined(2, 0, 0, w, h, color)
        end
    end

    local pnlPlayer = gui.Create("EditablePanel", pnlFrame, {
        "dock_top", tall = 30, margin = {5,5,5,5}
    })

    local pnlAvatar = gui.Create("AvatarImage", pnlPlayer, {
        "dock_left", wide = 30, input = false
    })
    pnlAvatar:SetSteamID(SteamID64, 32)

    local pnlName = gui.Create("DLabel", pnlPlayer, {
        "dock_fill", margin = {5,0,0,0}, font = ui.ffont(8)
    })
    pnlName:SetText(SteamID64)

    steamworks.RequestPlayerInfo(SteamID64, function(steam_name)
        pnlName:SetText(steam_name)
    end)


    local pnlList = gui.Create("DScrollPanel", pnlFrame, {
        "dock_fill"
    })


    FEATURES.CreatePermission = function(PERM)
        local color_out = COLOR.WHITE
        local pnlItem = gui.Create("EditablePanel", pnlList, {
            "dock_top", tall = 30, margin = {2,2,2,2}, cc = {
                Paint = function(self, w, h)
                    draw.BoxOutlined(1, 0,0,w,h,color_out)
                end
            }
        })

        gui.Create("DLabel", pnlItem, {
            "dock_left", margin = {5,0,0,0}, wide = 150, text = PERM.name, font = ui.ffont(8), text_color = color_white
        })

        local pnlCheckBox = gui.Create("DButton", pnlItem, {
            "dock_right", wide = 50, text = "|Loading|", text_color = COLOR.WHITE, cc = {
                colorBG = Color(255,255,255,10),
                Paint = function(self, w, h)
                    draw.Box(0,0,w,h,self.colorBG)
                end
            }
        })


        local bStatus = true
        local function SetValue(bActive)
            if bActive then
                pnlCheckBox:SetText("|--YES--|")
                color_out = COLOR.GREEN
            else
                pnlCheckBox:SetText("|--NO--|")
                color_out = COLOR.RED
            end
            bStatus = bActive
        end

        pnlCheckBox.DoClick = function()
            SetValue(!bStatus)
        end

        local bPermExists = iperm.PlayerHasPermission(SteamID64, PERM.name)
        SetValue(bPermExists)
    end


    for perm_name, PERM in pairs(iperm.mt_Permissions) do
        FEATURES.CreatePermission(PERM)
    end


end

icmd.Register("menu_permissions", function(QCMD, who, cmd, args, tags)
    local pnlFrame = gui.CreateStyled("frame", nil, "menu_permissions")
    pnlFrame:SetTitle("Permissions")

    local FEATURES = {}

    do
        local t_SearchPlayerTable = {}


        local pnlEntry = gui.CreateStyled("input_text", pnlFrame, nil, {
            tall = 30,
            "dock_top",
        })

        local pnlPlayers = gui.Create("DScrollPanel", pnlFrame, {
            "dock_fill"
        })

        pnlEntry:Setup({
            type = TYPE.STRING
        }, function(value)
            value = value or ""
            local search_text = string.lower(value)

            local t_Founded = {}

            for sid64, dat in pairs(t_SearchPlayerTable) do
                local bFounded = string_find(dat.text, search_text, 1, true)
                t_Founded[sid64] = true
                dat.panel:SetVisible(bFounded)
            end

            local sid64_value
            if util.IsSteamID(value) then
                sid64_value = util.SteamIDTo64(value)
            end

            if util.IsSteamID64(value) then
                sid64_value = value
            end

            if sid64_value and !t_Founded[sid64_value] then
                FEATURES.CreatePlayer(sid64_value)
            end


            pnlPlayers:InvalidateLayout(true)
        end)

        FEATURES.CreatePlayer = function(sid64, nick)
            local sid = util.SteamIDFrom64(sid64)
            local pnlPlayer = gui.Create("EditablePanel", pnlPlayers, {
                "dock_top", tall = 30, cursor = "hand", margin = {0,0,0,2}, cc = {
                    Paint = function(self, w, h)
                        if self:IsHovered() then
                            surface.SetDrawColor(255,255,255,10)
                            surface.DrawRect(0,0,w,h)
                        end
                    end,
                    OnMousePressed = function()
                        iperm.CreatePlayerPermissionMenu(sid64)
                    end
                }
            })

            local pnlAvatar = gui.Create("AvatarImage", pnlPlayer, {
                "dock_left", wide = 30, input = false
            })
            pnlAvatar:SetSteamID(sid64, 32)

            local pnlName = gui.Create("DLabel", pnlPlayer, {
                "dock_fill", margin = {5,0,0,0}, font = ui.ffont(8)
            })
            pnlName:SetText(sid64)

            local search_text = sid64 .. "/" .. sid

            if nick then
                search_text = search_text .. "/" .. tostring(nick)
                pnlName:SetText(nick)
            end


            t_SearchPlayerTable[sid64] = {
                text = util.StringLower(search_text),
                panel = pnlPlayer
            }

            if !nick then
                steamworks.RequestPlayerInfo(sid64, function(steam_name)
                    pnlName:SetText(steam_name)
                    t_SearchPlayerTable[sid64].text = util.StringLower(t_SearchPlayerTable[sid64].text .. "/" .. steam_name)
                end)
            end
        end

        for k, ply in player.Iterator() do
            FEATURES.CreatePlayer(ply:SteamID64(), ply:Nick())
        end

        pnlEntry.pnl_Value:SetPlaceholderText("Nick / SteamID / SteamID64")
    end


end, {}, {
    perm = "menu_permissions",
    help = "Hello World"
})