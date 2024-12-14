module("zen", package.seeall)

---@class zen.map_edit.Feature.draw.players: zen.FEATURE_META
local FEATURE = feature.GetMeta("map_edit.draw_players")
FEATURE.name = "Draw Players"
FEATURE.description = "Draw players on map"

function FEATURE:OnInitialize()
end

function FEATURE:OnActivate()
    ihook.Listen("Render", self, self.Render)
end

function FEATURE:OnDeactivate()
    ihook.Remove("Render", self)
end


local render_DepthRange = render.DepthRange
local ClientsideModel = ClientsideModel
local DistToSqr = META.VECTOR.DistToSqr
local render_Model = render.Model
local render_ModelMaterialOverride = render.ModelMaterialOverride
local render_DrawWireframeBox = render.DrawWireframeBox
local DrawModel = META.ENTITY.DrawModel

local COLOR_WHITE = COLOR.WHITE
local COLOR_BLACK = COLOR.BLACK
local COLOR_BLUE = COLOR.BLUE
local pairs = pairs
local ipairs = ipairs

local color_health = Color(255,0,0)
local color_health_bg = Color(255,100,100)

local color_armor = Color(0,0,255)
local color_armor_bg = Color(100,100,255)

local color_gray = Color(40, 40, 40, 100)


draw3d_Text = draw3d.Text
function FEATURE:Render(rendermode, priority)

    if rendermode == RENDER_2D and priority == RENDER_POST then
        local viewOrigin = map_edit.GetViewOrigin()

        ---@param ply Player
        for _, ply in player.Iterator() do
            local pos = ply:GetNetworkOrigin()

            local distance = DistToSqr(viewOrigin, pos)


            if distance < 1000000 then
                draw3d.Box(pos, -70, -50, 140, 120, color_gray)
                
                draw3d_Text(pos, team.GetName(ply:Team()), "16:Roboto", 0, 20, COLOR_WHITE, 1, 1, COLOR_BLACK)
                draw3d_Text(pos, ply:SteamID64(), "16:Roboto", 0, 40, COLOR_WHITE, 1, 1, COLOR_BLACK)

                local health_wide = math.Clamp((ply:Health()/ply:GetMaxHealth()),0,1) * 100
                draw3d.Box(pos, -50, -40, 100, 10, color_health_bg)
                draw3d.Box(pos, -50, -40, health_wide, 10, color_health)
                draw3d_Text(pos, ply:Health(), "16:Roboto", 0, -40+10/2, COLOR_WHITE, 1, 1, COLOR_BLACK)

                local armor_wide = math.Clamp((ply:Armor()/ply:GetMaxArmor()),0,1) * 100
                draw3d.Box(pos, -50, -25, 100, 10, color_armor_bg)
                draw3d.Box(pos, -50, -25, armor_wide, 10, color_armor)
                draw3d_Text(pos, ply:Armor(), "16:Roboto", 0, -25+10/2, COLOR_WHITE, 1, 1, COLOR_BLACK)
            end

            local text = ply:GetName()
            draw3d_Text(pos, text, "18:Roboto", 0, 0, COLOR_WHITE, 1, 1, COLOR_BLACK)
        end
    end
end


feature.Register(FEATURE)