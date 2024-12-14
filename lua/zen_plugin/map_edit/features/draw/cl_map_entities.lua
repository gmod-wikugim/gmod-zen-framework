module("zen", package.seeall)

---@class zen.map_edit.Feature.draw.map_entities: zen.FEATURE_META
local FEATURE = feature.GetMeta("map_edit.draw_map_entities")
FEATURE.name = "Draw Map Entities"
FEATURE.description = "Draw entity from .bsp file"

function FEATURE:OnInitialize()
    self.EntityList = map_reader.GetMapEntities()
end

function FEATURE:OnActivate()
    ihook.Listen("PreDrawTranslucentRenderables", self, self.PreDrawTranslucentRenderables)
    ihook.Listen("Render", self, self.Render)
end

function FEATURE:OnDeactivate()
    ihook.Remove("PreDrawTranslucentRenderables", self)
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

local mat_model = material.GetMaterialModelColored("models/wireframe", Color(100, 255, 255))
function FEATURE:PreDrawTranslucentRenderables()
    local viewOrigin = map_edit.GetViewOrigin()

    if self.EntityList then
        for classname, items in pairs(self.EntityList) do
            for k, ITEM in ipairs(items) do
                local pos = ITEM.origin
                local distance = DistToSqr(viewOrigin, pos)
                if distance > 1000000 then continue end

                local model = ITEM.model
                local ang = ITEM.angles
                local mins = ITEM.mins
                local maxs = ITEM.maxs



                render_DepthRange( 0, 0.01 )
                if model && #model > 5 then
                    ITEM.CSEnt = ITEM.CSEnt or ClientsideModel(model)

                    render_Model({
                        model = model,
                        pos = pos,
                        angle = ang
                    }, ITEM.CSEnt)
                    render_ModelMaterialOverride(mat_model)
                    DrawModel(ITEM.CSEnt)
                    render_ModelMaterialOverride()
                end
                if mins and maxs then
                    render_DrawWireframeBox(pos, ang, mins, maxs, COLOR_BLUE)
                end
                render_DepthRange( 0, 1 )
            end
        end
    end
end


draw3d_Text = draw3d.Text
function FEATURE:Render(rendermode, priority)

    if rendermode == RENDER_2D and priority == RENDER_POST then
        local viewOrigin = map_edit.GetViewOrigin()

        if self.EntityList then
            for classname, items in pairs(self.EntityList) do
                for k, ITEM in ipairs(items) do
                    local pos = ITEM.origin
                    local distance = DistToSqr(viewOrigin, pos)
                    if distance > 1000000 then continue end

                    local pos = pos

                    draw3d_Text(pos, ITEM.classname, "16:Roboto", 0, 0, COLOR_WHITE, 1, 1, COLOR_BLACK)
                end
            end
        end
    end
end


feature.Register(FEATURE)