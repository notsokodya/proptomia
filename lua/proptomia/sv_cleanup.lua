local hook_Add, hook_Remove, hook_GetTable, table_insert, gameevent_Listen, timer_Simple, next =
      hook.Add, hook.Remove, hook.GetTable, table.insert, gameevent.Listen, timer.Simple, next

proptomia.convars.cleanup_timer = CreateConVar("proptomia_cleanup", "60", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Time before cleanup player's props")

local cleanupEntity = {}
local function ThinkCleanup()
    local key, value = next(cleanupEntityList)
    
    if IsValid(value.ent) then
        value.ent:Remove()
    end
    cleanupEntityList[key] = nil
    proptomia.props[value.id] = nil
    
    local isEmpty = next(cleanupEntityList)
    if not isEmpty then
        hook_Remove("Think", "proptomia_cleanup_props")
    end
end
function proptomia.CleanupProps(steamid)
    local count = 0

    for k, v in next, proptomia.props do
        if v.SteamID ~= steamid then continue end

        table_insert({
            id = k,
            ent = v.Ent
        })
        count = count + 1
    end

    if not hook_GetTable().Think.proptomia_cleanup_props then
        hook_Add("Think", "proptomia_cleanup_props", ThinkCleanup)
    end

    return count
end

local cleanupPlayers = {}
gameevent_Listen "player_disconnect"
gameevent_Listen "player_connect"

hook_Add("player_disconnect", "proptomia_cleanup_players", function(d)
    if not proptomia.convars.cleanup_time:GetInt() <= 0 then return end
    local steamid = d.networkid
    cleanupPlayers[steamid] = true
    timer_Simple(proptomia.convars.cleanupTime, function()
        if cleanupPlayers[steamid] then
            proptomia.CleanupProps(steamid)
        end
    end)
end)
hook_Add("player_connect", "proptomia_cleanup_clear_players", function(d)
    if not proptomia.convars.cleanup_time:GetInt() <= 0 then return end
    local steamid = d.networkid
    if cleanupPlayers[steamid] then
        cleanupPlayers[steamid] = nil
    end
end)