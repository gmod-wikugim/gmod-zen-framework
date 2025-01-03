module("zen")

local file_Exists = file.Exists
local file_Size = file.Size

---Input entity name and receive path with default path exists
---@vararg string
local function GetValidImagePath(full_paths, single_words)

    local patches = {}

    local try_path = function(format, path)
        local path = string.format(format, path)
        table.insert(patches, path)
    end

    for _, v in pairs(full_paths) do
        if v == nil then continue end

        try_path("%s", v)
        try_path("%s.png", v)
        try_path("%s.vmt", v)
    end

    for _, v in pairs(single_words) do
        if v == nil then continue end

        try_path("materials/vgui/entities/%s.vmt", v)
        try_path("materials/vgui/entities/%s.png", v)

        try_path("materials/entities/%s.png", v)
        try_path("materials/entities/%s.vmt", v)
    end


    for _, path in ipairs(patches) do
        if file_Exists(path, "GAME") and file_Size(path, "GAME") > 0 then
            path = path:gsub("materials/", "")
            return path
        end
    end
end

---@class zen.panel.zspawn_item: zen.panel.zbutton
local PANEL = {}

function PANEL:Init()
    self:SetSize(200, 200)
end

function PANEL:PaintOnce(w, h)
    draw.Box(0,0,w,h,"191919")

    if self:IsHovered() then
        draw.BoxOutlined(1, 0, 0, w, h, "666666")
    else
        draw.BoxOutlined(1, 0, 0, w, h, "444444")
    end
end

function PANEL:DoClick()
    local ITEM = self.ITEM
    if !ITEM then return end

    if ITEM.TYPE == "SANDBOX_MODEL" then
        RunConsoleCommand("gm_spawn", ITEM.VALUE)
    elseif ITEM.TYPE == "SANDBOX_SENT" then
        RunConsoleCommand("gm_spawnsent", ITEM.VALUE)
    elseif ITEM.TYPE == "SANDBOX_WEAPON" then
        RunConsoleCommand("give", ITEM.VALUE)
    elseif ITEM.TYPE == "SANDBOX_VEHICLE" then
        RunConsoleCommand("gm_spawnvehicle", ITEM.VALUE)
    elseif ITEM.TYPE == "SANDBOX_NPC" then
        RunConsoleCommand("gmod_spawnnpc", ITEM.VALUE)
    end
end

function PANEL:SetItem(ITEM)
    self.ITEM = ITEM

    if IsValid(self.pnlSpawnInfo) then
        self.pnlSpawnInfo:Remove()
    end

    if ITEM.TYPE == "SANDBOX_MODEL" then
        self.pnlSpawnInfo = gui.Create("SpawnIcon", self, {dock_fill = true})
        if self.pnlSpawnInfo != nil and IsValid(self.pnlSpawnInfo) then
            self.pnlSpawnInfo:SetModel(Model(ITEM.VALUE))
            self.pnlSpawnInfo:SetMouseInputEnabled(false)
        end
    end

    if type(ITEM.ITEM) == "table" then
        self.pnlSpawnInfo = self:CreateItemSpawnIcon(ITEM.ITEM)
        if self.pnlSpawnInfo != nil and IsValid(self.pnlSpawnInfo) then
            self.pnlSpawnInfo:SetParent(self)
            self.pnlSpawnInfo:SetSize(200, 200)
            self.pnlSpawnInfo:Dock(FILL)
            self.pnlSpawnInfo:InvalidateParent(true)
            self.pnlSpawnInfo:SetMouseInputEnabled(false)
        end
    end

end

function PANEL:CreateItemSpawnIcon(ITEM)
    local path = GetValidImagePath({ITEM.IconOverride},{ITEM.ClassName, ITEM._KEY, ITEM.spawnname, ITEM.Spawnname, ITEM.Name, ITEM.name})

    local function SpawnPanel(classname, onSpawned)
        local pnlImage = vgui.Create(classname)
        if !IsValid(pnlImage) then return end

        local pnlFather = pnlImage:GetParent()


        timer.Simple(1, function()
            if !IsValid(pnlImage) then return end

            local pnlParent = pnlImage:GetParent()

            if pnlParent == nil or pnlParent == pnlFather or pnlParent == vgui.GetWorldPanel() or pnlParent == GetHUDPanel() then
                pnlImage:Remove()
                print("Panel was autoremove ", tostring(pnlImage), " don't parented!")
            end
        end)

        xpcall(onSpawned, function(...)
            pnlImage:Remove()
            error(...)
        end, pnlImage)

        return pnlImage
    end

    if path then
        local pnlImage = SpawnPanel("DImage", function(self)
            self:SetImage(path)
            self:SetMouseInputEnabled(false)
        end)

        return pnlImage
    end

    local SelModel
    if type(ITEM.WorldModel) == "string" and file.Exists(ITEM.WorldModel, "GAME") and !IsUselessModel(Model(ITEM.WorldModel)) then
        SelModel = ITEM.WorldModel
    elseif type(ITEM.Model) == "string" and file.Exists(ITEM.Model, "GAME") and !IsUselessModel(Model(ITEM.Model)) then
        SelModel = ITEM.Model
    end


    if SelModel then
        local pnlImage = SpawnPanel("SpawnIcon", function(self)
            self:SetModel(SelModel)
            self:SetMouseInputEnabled(false)
        end)

        return pnlImage
    end

end

vgui.Register("zspawn_item", PANEL, "zbutton")
