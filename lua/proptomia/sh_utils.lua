local cache = setmetatable({}, {__mode = "kv"})

function proptomia.GetPlayerBySteamID(steamid)
    return cache[steamid]
end

if SERVER then
    hook.Add("PlayerInitialSpawn", "proptomia_utils", function(ply)
        cache[ply:SteamID()] = ply -- we don't need disconnect hook, because garbage collector will do all shit for us :3
    end)
end

if CLIENT then
    gameevent.Listen("player_activate")

    hook.Add("player_activate", "proptomia_utils", function(d)
        timer.Simple(0, function() -- i hate this solution, but rubat doesn't give us proper clientside version of InitialPlayerSpawn :<
            local ply = Player(d.userid)

            if IsValid(ply) then
                cache[ply:SteamID()] = ply
            end
        end)
    end)
end

