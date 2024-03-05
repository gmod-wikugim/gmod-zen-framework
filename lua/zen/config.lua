module("zen", package.seeall)

-- List of admins: SteamID64 [String] = Value [boolean]
icfg.Admins = {
    ["76561198272243731"] = true -- Addon creator: -243 King
}

-- Request autorization before use admin access
icfg.Admin_AuthorizationRequire = false