local map_edit = zen.Init("map_edit")

local ui, draw, draw3d, draw3d2d = zen.Import("ui", "ui.draw", "ui.draw3d", "ui.draw3d2d")
local GetVectorString, GetAngleString = zen.Import("map_edit.GetVectorString", "map_edit.GetVectorString")

local MODE_DEFAULT = map_edit.RegisterMode("Default")
local MODE_EDIT_POINT = map_edit.RegisterMode("Edit Points")

local clr_white_alpha = Color(255,255,255,100)
ihook.Listen("zen.map_edit.Render", "points", function(rendermode, priority, vw)
    if rendermode == RENDER_3D and priority == RENDER_POST then
		local y = 0
		y = y - 5
		draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "v", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

		y = y - 35
		draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, GetVectorString(vw.lastTrace.HitPos), 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

		local ent = vw.lastTrace.Entity

		if IsValid(ent) then

			y = y - 35
			draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, tostring(ent:GetClass()), 20, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

			local name = ent.GetName and ent:GetName()

			if name then
				y = y - 35
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, tostring(ent:GetName()), 20, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
			end
		end

		if vw.mode == MODE_EDIT_POINT then
			y = y - 50
			if vw.edit_point then
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "---- MODE: Point Edit (" .. vw.edit_point .. ") ----", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
			else
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "---- MODE: Point Edit ----", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
			end

			if vw.edit_point then
				y = y - 40
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Setup New Point", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_ATTACK", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, COLOR.BLUE)
			else
				y = y - 40
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Add Point", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_ATTACK", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, COLOR.BLUE)
			end

			if vw.edit_point then
				y = y - 40
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Cancel Editing ", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
				draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_ATTACK2/IN_USE", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, COLOR.BLUE)
			else
				if vw.nearPositionID then
					y = y - 40
					local add_text = vw.nearPositionID and "(" .. vw.nearPositionID .. ")" or "(unknown)"
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Delete Near Position " .. add_text, 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_ATTACK2", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, COLOR.BLUE)

					y = y - 40
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Edit Point " .. add_text, 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_USE", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, COLOR.BLUE)

					local clr = input.IsButtonPressedIN(IN_WALK) and COLOR_BLUE or COLOR_WHITE

					y = y - 40
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "Start With Point " .. add_text, 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
					draw3d2d.Text(vw.lastTrace.HitPos, nil, 0.1, true, "IN_WALK + IN_USE", "map_edit.Button", 0, y-15, COLOR.WHITE, 1, 1, clr)
				end
			end
		end
	end




	if rendermode == RENDER_3D and priority == RENDER_POST then
		local tDistance = {}

		local minDistance
		for k, pos in pairs(vw.t_Positions) do
			local distance = math.floor(pos:DistToSqr(vw.hoverOrigin))
			if distance < 10000 then
				tDistance[distance] = k

				if not minDistance then
					minDistance = distance
				else
					minDistance = math.min(minDistance, distance)
				end
			end
		end

		vw.nearPositionID = tDistance[minDistance]
		vw.nearPosition = vw.t_Positions[vw.nearPositionID]

		for k, pos in pairs(vw.t_Positions) do

			if vw.edit_point == k then
				pos = vw.hoverOrigin
			end

			local y = 0
			y = y - 5
			draw3d2d.Text(pos, nil, 0.1, true, "v", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

			y = y - 35
			draw3d2d.Text(pos, nil, 0.1, true, GetVectorString(pos), 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

			y = y - 35
			draw3d2d.Text(pos, nil, 0.1, true, k, 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

			if vw.nearPositionID == k then
				y = y - 35
				draw3d2d.Text(pos, nil, 0.1, true, "NearPoint", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLUE)


				if vw.mode == MODE_EDIT_POINT then
					local middle = (pos + vw.hoverOrigin)*0.5

					render.DrawLine(pos, vw.hoverOrigin, COLOR.BLUE, true)
				end
			end



			local next_k = next(vw.t_Positions, k)
			next_k = next_k or 1
			nextpos = vw.t_Positions[next_k]

			if vw.edit_point and vw.edit_point == next_k then
				nextpos = vw.hoverOrigin
			end

			render.DrawLine(pos, nextpos, COLOR.WHITE, true)
		end
	end

	if vw.mode == MODE_EDIT_POINT and vw.edit_point == nil then
		local iPoints = #vw.t_Positions

		if input.IsButtonPressedIN(IN_WALK) then
			local hitNormal = vw.lastTrace.HitNormal
			local hitAngle = hitNormal:Angle()
			local up = hitAngle:Up()
			local down = -up
			local right = hitAngle:Right()
			local left = -right

			local trace_up = util.TraceLine({start = vw.hoverOrigin, endpos = vw.hoverOrigin + up*100})
			local trace_down = util.TraceLine({start = vw.hoverOrigin, endpos = vw.hoverOrigin + down*100})
			local trace_right = util.TraceLine({start = vw.hoverOrigin, endpos = vw.hoverOrigin + right*100})
			local trace_left = util.TraceLine({start = vw.hoverOrigin, endpos = vw.hoverOrigin + left*100})

			local trace_up_back = util.TraceLine({start = trace_up.HitPos - hitNormal, endpos = trace_up.StartPos - hitNormal})
			local trace_down_back = util.TraceLine({start = trace_down.HitPos - hitNormal, endpos = trace_down.StartPos - hitNormal})
			local trace_right_back = util.TraceLine({start = trace_right.HitPos - hitNormal, endpos = trace_right.StartPos - hitNormal})
			local trace_left_back = util.TraceLine({start = trace_left.HitPos - hitNormal, endpos = trace_left.StartPos - hitNormal})

			if rendermode == RENDER_2D then
				draw3d.Line(vw.hoverOrigin, vw.hoverOrigin + up * 2, clr_white_alpha)
				draw3d.Line(vw.hoverOrigin, vw.hoverOrigin + down * 2, clr_white_alpha)
				draw3d.Line(vw.hoverOrigin, vw.hoverOrigin + right * 2, clr_white_alpha)
				draw3d.Line(vw.hoverOrigin, vw.hoverOrigin + left * 2, clr_white_alpha)


				local up_hitpos = (trace_up.Hit) and (trace_up.HitPos) or (trace_up_back.Hit and trace_up_back.HitPos != trace_up_back.StartPos and trace_up_back.HitPos + hitNormal or nil)
				local down_hitpos = (trace_down.Hit) and (trace_down.HitPos) or (trace_down_back.Hit and trace_down_back.HitPos != trace_down_back.StartPos and trace_down_back.HitPos + hitNormal or nil)
				local right_hitpos = (trace_right.Hit) and (trace_right.HitPos) or (trace_right_back.Hit and trace_right_back.HitPos != trace_right_back.StartPos and trace_right_back.HitPos + hitNormal or nil)
				local left_hitpos = (trace_left.Hit) and (trace_left.HitPos) or (trace_left_back.Hit and trace_left_back.HitPos != trace_left_back.StartPos and trace_left_back.HitPos + hitNormal or nil)


				if up_hitpos then
					draw3d.Line(vw.hoverOrigin, up_hitpos, clr_white_alpha)
				end

				if down_hitpos then
					draw3d.Line(vw.hoverOrigin, down_hitpos, clr_white_alpha)
				end

				if right_hitpos then
					draw3d.Line(vw.hoverOrigin, right_hitpos, clr_white_alpha)
				end

				if left_hitpos then
					draw3d.Line(vw.hoverOrigin, left_hitpos, clr_white_alpha)
				end


				vw.hoverPosition8 = up_hitpos
				vw.hoverPosition2 = down_hitpos
				vw.hoverPosition6 = left_hitpos
				vw.hoverPosition4 = right_hitpos
			end
		end
		

		if iPoints == 1 then
			local firstPos = vw.t_Positions[1]
			local firstDir = (vw.hoverOrigin - firstPos):Angle():Forward()

			local add = math.min(firstPos:Distance(vw.hoverOrigin) or 10, 10)

			if rendermode == RENDER_2D then
				draw3d.Line(vw.hoverOrigin, firstPos, clr_white_alpha)

				draw3d.Line(vw.hoverOrigin, vw.hoverOrigin + firstDir * -add, COLOR.WHITE)
				draw3d.Line(firstPos, firstPos + firstDir * add, COLOR.WHITE)
			end
		elseif iPoints > 1 then
			local firstPos = vw.t_Positions[1]
			local lastPos = vw.t_Positions[iPoints]

			local add_first = math.min(firstPos:Distance(vw.hoverOrigin) or 10, 20)
			local add_last = math.min(lastPos:Distance(vw.hoverOrigin) or 10, 20)


			local firstAng = (vw.hoverOrigin - firstPos):Angle()
			local lastAng = (vw.hoverOrigin - lastPos):Angle()

			local firstDir = firstAng:Forward()
			local lastDir =  lastAng:Forward()

			local firstMinPos = vw.hoverOrigin + firstDir * -add_first
			local lastMinPos = vw.hoverOrigin + lastDir * -add_last

			if rendermode == RENDER_2D then
				draw3d.Line(vw.hoverOrigin, firstPos, clr_white_alpha)
				draw3d.Line(vw.hoverOrigin, lastPos, clr_white_alpha)

				draw3d.Line(vw.hoverOrigin, firstMinPos, COLOR.RED)
				draw3d.Line(vw.hoverOrigin, lastMinPos, COLOR.BLUE)

				draw3d.Line(firstPos, firstPos + firstDir * add_first, COLOR.RED)
				draw3d.Line(lastPos, lastPos + lastDir * add_last, COLOR.BLUE)
			end
			if rendermode == RENDER_3D then
				local mid = (firstMinPos + lastMinPos)*0.5
				local new_ang = firstAng - lastAng

				draw3d2d.Text((firstMinPos + Vector(2,2,2)), nil, 0.1, true, GetAngleString(firstAng), 8, 0, 0, COLOR.RED, 1, 1, COLOR.BLACK)
				draw3d2d.Text((lastMinPos + Vector(-2,-2,-2)), nil, 0.1, true, GetAngleString(lastAng), 8, 0, 0, COLOR.BLUE, 1, 1, COLOR.BLACK)

				local tbl = {}

				if new_ang.p != 0 then
					table.insert(tbl, math.Round(math.abs(new_ang.p), 2))
				end

				if new_ang.y != 0 then
					table.insert(tbl, math.Round(math.abs(new_ang.y), 2))
				end

				if new_ang.r != 0 then
					table.insert(tbl, math.Round(math.abs(new_ang.r), 2))
				end

				local ang_str = table.concat(tbl, " ")
				draw3d2d.Text(mid, nil, 0.1, true, ang_str, 8, 0, 0, COLOR.WHITE, 1, 1, COLOR.BLACK)
			end
		end
	end
end)

ihook.Listen("zen.map_edit.OnModeChange", "points", function(vw, old, new)
    if old == MODE_EDIT_POINT then
        vw.edit_point = nil
    end
end)


ihook.Listen("zen.map_edit.OnButtonPress", "points", function(ply, but, in_key, bind_name, vw)
    if vw.mode != MODE_EDIT_POINT then return end


    if in_key == IN_ATTACK then
        if vw.edit_point then
            vw.t_Positions[vw.edit_point] = vw.hoverOrigin
            vw.edit_point = nil
        else
            table.insert(vw.t_Positions, vw.hoverOrigin)
        end
    elseif in_key == IN_ATTACK2 then
        if vw.edit_point then
            vw.edit_point = nil
        else
            if vw.nearPositionID then
                table.remove(vw.t_Positions, vw.nearPositionID)
            end
        end
    elseif in_key == IN_USE then
        if input.IsButtonPressedIN(IN_WALK) then
            if vw.nearPositionID then
                local newTable = {}

                for k = vw.nearPositionID + 1, #vw.t_Positions do
                    local pos = vw.t_Positions[k]
                    table.insert(newTable, pos)
                end

                for k = 1, vw.nearPositionID - 1 do
                    local pos = vw.t_Positions[k]
                    table.insert(newTable, pos)
                end

                table.insert(newTable, vw.nearPosition)

                vw.t_Positions = newTable
            end
        else
            if vw.edit_point then
                vw.edit_point = nil
            else
                if vw.nearPositionID then
                    vw.edit_point = vw.nearPositionID
                end
            end
        end
    end


    if but == KEY_PAD_4 and vw.hoverPosition4 then
        vw.angles = (vw.hoverPosition4 - vw.lastOrigin):Angle()
        vw.hoverOrigin = vw.hoverPosition4
    elseif but == KEY_PAD_6 and vw.hoverPosition6 then
        vw.angles = (vw.hoverPosition6 - vw.lastOrigin):Angle()
        vw.hoverOrigin = vw.hoverPosition6
    elseif but == KEY_PAD_8 and vw.hoverPosition8 then
        vw.angles = (vw.hoverPosition8 - vw.lastOrigin):Angle()
        vw.hoverOrigin = vw.hoverPosition8
    elseif but == KEY_PAD_2 and vw.hoverPosition2 then
        vw.angles = (vw.hoverPosition2 - vw.lastOrigin):Angle()
        vw.hoverOrigin = vw.hoverPosition2
    end
end)


ihook.Listen("zen.map_edit.GenerateGUI", "points", function(nav, pnlContext, vw)
    nav.items:zen_AddStyled("button", {"dock_top", text = "MODE: Edit", cc = {
        DoClick = function()
			map_edit.SetMode(MODE_EDIT_POINT)
        end
    }})
end)