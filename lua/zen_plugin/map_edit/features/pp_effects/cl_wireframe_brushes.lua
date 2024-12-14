module("zen", package.seeall)

---@class zen.map_edit.Feature.wireframe_brushes: zen.FEATURE_META
local FEATURE = feature.GetMeta("map_edit.wireframe_brushes")
FEATURE.name = "Brushes Wireframe"
FEATURE.description = "Draw materials for map brushes"


local function import_hammer_table(source_string)
    local new_table = {}
    for key, value in string.gmatch(source_string, '"([^"]+)" "([^"]+)"') do
        new_table[key] = value

    end
    return new_table
end

local iTrim = 30
local function nice_len(name)
    local len = utf8.len(name)
    local left = math.max(0, iTrim - len)

    return name .. string.rep(".", left)
end

function FEATURE:OnInitialize()
    self.BrushViewChanged = false

    
end

function FEATURE:OnActivate()
    -- ihook.Listen("RenderScene", self, self.Pre)

    ihook.Listen("RenderScene", self, self.Pre)
end

function FEATURE:OnDeactivate()
    -- ihook.Remove("RenderScene", self)

    ihook.Remove("RenderScene", self)
end


function FEATURE:Post()
    render.ModelMaterialOverride()
    render.BrushMaterialOverride()
    -- render.SuppressEngineLighting(false)
end


local mat_model = material.GetMaterialModelColored("models/wireframe", Color(100, 100, 255))
local mat_brush = material.GetMaterialModelColored("models/wireframe", Color(255, 0, 255))
local mat_world = material.GetMaterialModelColored("models/wireframe", Color(100, 100, 100))

function FEATURE:Pre(isDrawingDepth, isDrawSkybox, isDraw3DSkybox)


    -- if isDraw3DSkybox then
        render.MaterialOverride(mat_brush)
        render.ModelMaterialOverride(mat_model)
        render.BrushMaterialOverride(mat_brush)
        render.WorldMaterialOverride(mat_world)
    -- end
    -- render.SetAmbientLight(0,0,0)

    -- render.OverrideDepthEnable(true, false)

    -- return true
    -- render.SuppressEngineLighting(true)
end


feature.Register(FEATURE)