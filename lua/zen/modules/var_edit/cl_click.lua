local draw = zen.Import("ui.draw")

local color_hover = Color(255, 0, 0)
hook.Add("zen.worldclick.DrawEntityInfo", "zen.variable_edit", function(ent, pos, ang)
    if zen.nvars.mt_EntityButtons then
        local sc = pos:ToScreen()
        local x, y = sc.x, sc.y
        
        local mx, my = input.GetCursorPos()
        
        local tPositions = {}
        
        local minDistance = 99999
        local minID = 0
        
        for k, data in ipairs(zen.nvars.mt_EntityButtons) do
            y = y + 20
            tPositions[k] = {x, y}

            local distance = math.Distance(x, y, mx, my)
            if distance < 35 and distance < minDistance then
                minDistance = distance
                minID = k
            end
        end

        cam.Start2D()
            for k, v in ipairs(tPositions) do
                local data = zen.nvars.mt_EntityButtons[k]
                local x, y = v[1], v[2]
                
                local clr = minID == k and color_hover or color_white
                draw.Text(data.string, 8, x, y, clr, 1, 1, COLOR.BLACK)
            end
        cam.End2D()

        if minID == 0 then 
            zen.nvars.HoveredTButton = nil
            zen.nvars.HoveredTButtonEntity = nil
        else
            local tButton = zen.nvars.mt_EntityButtons[minID]
            zen.nvars.HoveredTButton = tButton
            zen.nvars.HoveredTButtonEntity = ent
        end
    else
        zen.nvars.HoveredTButton = nil
        zen.nvars.HoveredTButtonEntity = nil
    end
end)