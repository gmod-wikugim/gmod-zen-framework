module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "move"
TOOL.Name = "Move"
TOOL.Icon = "zen/map_edit/open_with.png"
TOOL.Description = "Move Entity"


function TOOL:EnableHooks()
    ihook.Handler("map_edit.MouseMove", "map_edit.tool.move.RotateEntity", function(add_x, add_y)
        if !self.bAngleRotaing then return end
        self:OnMouseMove(add_x, add_y)

        return true
    end)
end

function TOOL:DisableHooks()
    ihook.Remove("map_edit.MouseMove", "map_edit.tool.move.RotateEntity")
end


local step = 1
local round_degress = 25
local degrees = 25
local function round_path(input, degrees)
    return math.Round( input / degrees ) * degrees
end


local function create_fraction(delay, last_time)
    local new_time = round_path(CurTime(), delay)

    return new_time != last_time, new_time
end


local LerpTime = 0.1
local lastfrac, _last_time, lerp_start, time_offset, lerp_end, sum_x, sum_y
function TOOL:OnMouseMove(add_x, add_y)
    local viewAngeles = map_edit.GetViewAngles()
    local viewRight = viewAngeles:Right()
    local viewForward = viewAngeles:Up()

    local vNewAngle = Angle(self.vNewAngle)

    vNewAngle:RotateAroundAxis(viewRight, -add_y)
    vNewAngle:RotateAroundAxis(viewForward, add_x)

    vNewAngle:Normalize()

    self.vNewAngle = LerpAngle(0.1, self.vNewAngle, vNewAngle)

end

function TOOL:Think(rendermode, priority, vw)
    local bGrabbingActive = IsValid(self.eGrabbedEntity)
    if bGrabbingActive then
        if !self.bAngleRotaing then
            self.vNewPosition = map_edit.GetHoverOrigin()
        end

        self:CallServerAction{
            action = "update_pos",
            pos = self.vNewPosition,
            ang = self.vNewAngle
        }
    end
end

function TOOL:Reload()
end

function TOOL:GrabEntity()
    local ent = map_edit.GetHoverEntity()
    if !IsValid(ent) then return end

    self.eGrabbedEntity = ent

    self:CallServerAction{
        action = "grab",
        ent = ent
    }

    self.vGrabOffset = self.eGrabbedEntity:GetPos() - map_edit.GetHoverOrigin()
    self.iLastMoveType = self.iLastMoveType or ent:GetMoveType()
    self.iLastSolid = self.iLastSolid or ent:GetSolid()
    ent:SetMoveType(MOVETYPE_CUSTOM)
    ent:SetSolid(SOLID_NONE)

    self.vStartPos = self.eGrabbedEntity:GetPos()
    self.aStartAngle = self.eGrabbedEntity:GetAngles()

    self.vNewAngle = self.aStartAngle
    self.vNewPosition = map_edit.GetHoverOrigin()
end

function TOOL:UnGrabEntity()
    if !self.eGrabbedEntity then return end
    if !IsValid(self.eGrabbedEntity) then return end

    local ent = self.eGrabbedEntity
    local movetype = self.iLastMoveType
    local solid = self.iLastSolid

    self.vGrabOffset = nil
    self.eGrabbedEntity = nil
    self.iLastMoveType = nil
    self.iLastSolid = nil

    self:CallServerAction{
        action = "ungrab",
        solid = solid,
        movetype = movetype
    }
end

function TOOL:ResetAngle()
    self.vNewAngle = Angle(0,0,0)
end

function TOOL:OnButtonPress(but, in_key, bind_name, vw)
    if bind_name == "+attack" then
        self:GrabEntity()
    end

    if IsValid(self.eGrabbedEntity) then
        if bind_name == "+use" then
            self.bAngleRotaing = true
        end

        if self.bAngleRotaing and bind_name == "+speed" then
            self.bAngleRotaingRound = true
        end
    end
end

function TOOL:OnButtonUnPress(but, in_key, bind_name, vw)
    if bind_name == "+attack" then
        self:UnGrabEntity()
    end

    if bind_name == "+reload" then
        self:ResetAngle()
    end

    if bind_name == "+use" then
        self.bAngleRotaing = false
        self.bAngleRotaingRound = false
    end

    if self.bAngleRotaing and bind_name == "+speed" then
        self.bAngleRotaingRound = false
    end

end

tool.Register(TOOL)