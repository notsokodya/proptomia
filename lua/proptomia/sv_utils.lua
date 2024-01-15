local cache = setmetatable({}, {__mode = "kv"})

function proptomia.GetPlayerBySteamID(steamid)
    return cache[steamid]
end

hook.Add("PlayerInitialSpawn", "proptomia_utils", function(ply)
    cache[ply:SteamID()] = ply -- we don't need disconnect hook, because garbage collector will do all shit for us :3
end)


