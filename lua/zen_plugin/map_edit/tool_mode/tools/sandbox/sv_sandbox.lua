module("zen", package.seeall)

tool.mt_PlayerToolsGuns = tool.mt_PlayerToolsGuns or {}
tool.mt_SandBoxToolGuns = tool.mt_SandBoxToolGuns or {}
local TOOL_GUNS = tool.mt_SandBoxToolGuns
local PLAYER_TOOLS_GUNS = tool.mt_PlayerToolsGuns



---@param ply Player
---@param tool_mode string
---@return Tool
function tool.GetPlayerSTOOL(ply, tool_mode)
    if !IsValid(PLAYER_TOOLS_GUNS[ply]) then
        local gmod_tool = ents.Create("gmod_tool")
        assert(IsValid(gmod_tool), "Failed to created")

        gmod_tool:Spawn()

        gmod_tool:SetPos(ply:GetPos())
        gmod_tool:SetCollisionGroup(COLLISION_GROUP_WORLD)
        gmod_tool:SetParent(ply)



        TOOL_GUNS[gmod_tool] = ply
        PLAYER_TOOLS_GUNS[ply] = gmod_tool
    end

    local gmod_tool =  PLAYER_TOOLS_GUNS[ply]


    gmod_tool.SWEP = gmod_tool
    gmod_tool.Owner = ply
    gmod_tool.Weapon = gmod_tool

    gmod_tool:SetOwner(ply)

    gmod_tool.Mode = tool_mode
    local STOOL = gmod_tool:GetToolObject()

    return STOOL
end

hook.Add( "PlayerCanPickupWeapon", "zen.map_edit.limited_gmod_tool", function( ply, weapon )
    if TOOL_GUNS[weapon] then return false end
end )
