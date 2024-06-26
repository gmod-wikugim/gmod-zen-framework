module("zen", package.seeall)

---@class zen.iperm.DB_Container: zen.sql.Container
iperm.DB = sql.GetContainer()
function iperm.DB:CreateTable()
    self:Query([[
        CREATE TABLE IF NOT EXISTS
            `zen_player_permissions`
        (
            `playerID` VARCHAR(50),
            `perm_name` VARCHAR(50),
            `allowed` BOOLEAN,
            `target_flags` INTEGER,
            `unique_flags` INTEGER,
            `extra` BLOB,
            UNIQUE(`playerID`, `perm_name`)
        )
    ]])
end

function iperm.DB:DropTable()
    self:Query([[
        DROP TABLE IF EXISTS
            `zen_player_permissions`
    ]])
end


---@param playerID string
---@param perm_name string
---@param allowed boolean
---@param target_flags? number
---@param unique_flags? number
---@param extra? table<string, string|number|boolean>
function iperm.DB:GivePermission(playerID, perm_name, allowed, target_flags, unique_flags, extra)
    target_flags = target_flags or 0
    unique_flags = unique_flags or 0
    extra = extra or {}

    assertStringNice(playerID, "playerID")
    assertStringNice(perm_name, "perm_name")
    assert(isbool(allowed), "allowed should be boolean")
    assertNumber(target_flags, "target_flags")
    assertNumber(unique_flags, "unique_flags")
    assertTable(extra, "extra")

    self:Query([[
        REPLACE INTO
            `zen_player_permissions`
        (
            `playerID`,
            `perm_name`,
            `allowed`,
            `target_flags`,
            `unique_flags`,
            `extra`
        )
        VALUES(
            ${auto:1},
            ${auto:2},
            ${auto:3},
            ${auto:4},
            ${auto:5},
            ${auto:6}
        )
    ]], playerID, perm_name, allowed, target_flags, unique_flags, extra)
end

---@class zen.iperm.perm_info
---@field allowed boolean
---@field extra table
---@field perm_name string
---@field target_flags number
---@field unique_flags number

---@param playerID string
---@return table<string, zen.iperm.perm_info>
function iperm.DB:LoadPlayerPermissions(playerID)
    assertStringNice(playerID, "playerID")

    ---@type table<string, zen.iperm.perm_info>
    local player_permissions = {}

    local sql_data = self:Query([[
        SELECT * FROM
            `zen_player_permissions`
        WHERE
            `playerID` IS ${auto:1}
    ]], playerID)

    if istable(sql_data) then
        ---@cast sql_data table

        for k, v in pairs(sql_data) do
            player_permissions[v.perm_name] = {
                perm_name = v.perm_name,
                allowed = tobool(v.allowed),
                target_flags = tonumber(v.target_flags) or 0,
                unique_flags = tonumber(v.unique_flags) or 0,
                extra = self:DecodeTable(v.extra)
            }
        end
    end

    iperm.SetPlayerPermissions(playerID, player_permissions)

    return player_permissions
end

---@param playerID string
---@param perm_name string
function iperm.DB:RemovePlayerPermission(playerID, perm_name)
    assertStringNice(playerID, "playerID")
    assertStringNice(perm_name, "perm_name")

    self:Query([[
        DELETE FROM
            `zen_player_permissions`
        WHERE
            `playerID` IS ${auto:1}
            AND
            `perm_name` IS ${auto:2}
    ]], playerID, perm_name)
end

iperm.DB:CreateTable()

---@param ply Player
ihook.Listen("PlayerInitialSpawn", "zen.permission", function(ply)
    if ply:IsBot() then return end

    local sid64 = util.GetPlayerSteamID64(ply)

    iperm.DB:LoadPlayerPermissions(ply:SteamID64())

    if _CFG.Admin_AuthorizationRequire == false and _CFG.Admins[sid64] then
        ply:zen_SetVar("auth", true)
    end
end)

iperm.RegisterPermission("GRAND", 0, "Allow to grand permission")

nt.Receive("iperm.UpdatePlayerPermission",
{"string", "string", "boolean"},
---@param who Player
---@param sid64 string
---@param perm_name string
---@param allowed boolean
function(who, sid64, perm_name, allowed)
    if !who:zen_HasPerm("GRAND") then return end

    iperm.DB:GivePermission(sid64, perm_name, allowed)
    iperm.DB:LoadPlayerPermissions(sid64)
end)