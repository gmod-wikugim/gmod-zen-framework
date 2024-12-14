module("zen", package.seeall)

---@class zen.map_edit.Feature.wireframe_entities: zen.FEATURE_META
local FEATURE = feature.GetMeta("map_edit.wireframe_entities")
FEATURE.name = "Entities Wireframe"
FEATURE.description = "Draw materials for models"

function FEATURE:OnInitialize()
    self.BrushViewChanged = false

    -- print("BrushView")
end

function FEATURE:OnActivate()
    ihook.Listen("PreDrawOpaqueRenderables", self, self.PreDrawOpaqueRenderables)
    ihook.Listen("PostDrawOpaqueRenderables", self, self.PostDrawOpaqueRenderables)
end

function FEATURE:OnDeactivate()
    ihook.Remove("PreDrawOpaqueRenderables", self)
    ihook.Remove("PostDrawOpaqueRenderables", self)

    -- ihook.Remove("PostRender", self)
    -- ihook.Remove("PreDrawHUD", self)
end

--- 



function FEATURE:PostDrawOpaqueRenderables()
    surface.SetDrawColor(0, 0, 0, 0)
    -- render.OverrideColorWriteEnable(false)
    render.ModelMaterialOverride()
    render.SetColorModulation(1, 1, 1, 1)
end


local mat_view = material.GetMaterialModelColored("models/wireframe", Color(100, 100, 255))

function FEATURE:PreDrawOpaqueRenderables()

    surface.SetDrawColor(255, 0, 0, 255)
    -- render.OverrideColorWriteEnable(true, true)
    render.ModelMaterialOverride(mat_view)
    render.SetColorModulation(1, 0, 0, 1)
end

feature.Register(FEATURE)