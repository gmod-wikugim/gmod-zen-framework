module("zen", package.seeall)

feature = _GET("feature")

---@package
---@type table<string, zen.FEATURE_META>
feature.mt_FeaturesMetas = feature.mt_FeaturesMetas or {}

---@package
---@type table<string, zen.FEATURE>
feature.mt_FeaturesInitialized = feature.mt_FeaturesInitialized or {}

---@class zen.FEATURE
---@field public uniqueID string
---@field public name string
---@field public description string
---@field public Enable fun(self, ...)
---@field public Disable fun(self, ...)
---@field public IsActive fun(self): boolean

---@class zen.FEATURE_META
---@field uniqueID string
---@field package _Initialize fun(self)
---@field package Enable fun(self, ...)
---@field package Disable fun(self, ...)
---@field OnInitialize fun(self)
---@field OnActivate fun(self, ...)
---@field OnDeactivate fun(self, ...)
---@field IsActive fun(self): boolean
---@field package pb_Activated boolean
---@field package pb_Initialized boolean
---@field package pb_Valid boolean

local FEATURE_META = {}

function FEATURE_META:_Initialize()
    if self.pb_Initialized then return end

    if self.OnInitialize then self:OnInitialize() end
    self.pb_Initialized = true
end

---@vararg any
function FEATURE_META:Enable(...)
    if self.pb_Activated then return end

    self.pb_Valid = true
    if self.OnActivate then self:OnActivate() end
    self.pb_Activated = true
end

function FEATURE_META:IsActive()
    return self.pb_Activated
end

function FEATURE_META:IsValid()
    return self.pb_Valid
end

---@vararg any
function FEATURE_META:Disable(...)
    if self.pb_Activated != true then return end

    if self.OnDeactivate then self:OnDeactivate() end
    self.pb_Valid = false
    self.pb_Activated = false
end

FEATURE_META.__index = FEATURE_META


---@param uniqueID string
---@return zen.FEATURE_META
function feature.GetMeta(uniqueID)
    if !feature.mt_FeaturesMetas[uniqueID] then
        feature.mt_FeaturesMetas[uniqueID] = {}
    end

    ---@class zen.FEATURE_META
    local FEATURE = feature.mt_FeaturesMetas[uniqueID]
    FEATURE.uniqueID = uniqueID
    FEATURE.name = FEATURE.name or FEATURE.uniqueID
    FEATURE.description = FEATURE.description or (FEATURE.name .. " feature")

    setmetatable(FEATURE, FEATURE_META)

    return FEATURE
end

---@param FEATURE zen.FEATURE_META
function feature.Register(FEATURE)

    --- Auto-Reactivate-For-Initialized
    if FEATURE.uniqueID then
        local INITIALIZED = feature.mt_FeaturesInitialized[FEATURE.uniqueID]
        if INITIALIZED and INITIALIZED:IsActive() then
            INITIALIZED:Disable()

            table.Empty(INITIALIZED)
            table.Merge(INITIALIZED, FEATURE, true)

            setmetatable(INITIALIZED, FEATURE_META)

            INITIALIZED:Enable()
        end
    end

end



---@param uniqueID string
---@return zen.FEATURE
function feature.GetInitialized(uniqueID)
    if !feature.mt_FeaturesInitialized[uniqueID] then
        local META = feature.GetMeta(uniqueID)

        local LIVE = table.Copy(META)

        local FEATURE = setmetatable(LIVE, FEATURE_META)
        FEATURE:_Initialize()
        feature.mt_FeaturesInitialized[uniqueID] = FEATURE
    end

    return feature.mt_FeaturesInitialized[uniqueID]
end

---@return table<number, string>
function feature.GetList()
    return table.GetKeys(feature.mt_FeaturesMetas)
end


---@param uniqueID string
---@param ... any
function feature.Activate(uniqueID, ...)
    local FEATURE_LIVE = feature.GetInitialized(uniqueID)

    FEATURE_LIVE:Enable(...)
end

---@param uniqueID string
function feature.IsActive(uniqueID)
    local FEATURE_LIVE = feature.GetInitialized(uniqueID)

    return FEATURE_LIVE:IsActive()
end

---@param uniqueID string
---@param ... any
function feature.Deactivate(uniqueID, ...)
    local FEATURE_LIVE = feature.GetInitialized(uniqueID)

    FEATURE_LIVE:Disable(...)
end




---------------------------
-------- DANGEROUS --------
---------------------------

--- Auto-Update-Meta-For-Initialized

for k, INITIALIZED in pairs(feature.mt_FeaturesInitialized) do
    setmetatable(INITIALIZED, FEATURE_META)
end