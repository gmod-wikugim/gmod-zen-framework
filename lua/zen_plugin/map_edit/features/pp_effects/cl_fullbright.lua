module("zen", package.seeall)

---@class zen.map_edit.Feature.full_bright: zen.FEATURE_META
local FEATURE = feature.GetMeta("map_edit.full_bright")
FEATURE.name = "Full Bright"
FEATURE.description = "Full Bright link in mat_fullbright"

function FEATURE:OnInitialize()
    self.LightingModeChanged = false
end

function FEATURE:OnActivate()
    ihook.Listen("PreRender", self, self.PreRender)
    ihook.Listen("PostRender", self, self.HookDisappear)
    ihook.Listen("PreDrawHUD", self, self.HookDisappear)
end

function FEATURE:OnDeactivate()
    ihook.Remove("PreRender", self)
    ihook.Remove("PostRender", self)
    ihook.Remove("PreDrawHUD", self)
end

function FEATURE:HookDisappear()
	if self.LightingModeChanged then
		render.SetLightingMode( 0 )
		self.LightingModeChanged = false
	end
end

function FEATURE:PreRender()
    render.SetLightingMode( 1 )
    self.LightingModeChanged = true
end

feature.Register(FEATURE)