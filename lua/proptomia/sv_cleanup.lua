local hook_Add, hook_Remove, hook_GetTable, table_insert, gameevent_Listen, timer_Simple, next =
      hook.Add, hook.Remove, hook.GetTable, table.insert, gameevent.Listen, timer.Simple, next

proptomia.convars.cleanup_timer = CreateConVar("proptomia_cleanup", "60", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Set seconds before disconnected player's props will be removed. Setting 0 or lower value disables cleanup.")

local cleanupEntity = {}
local function ThinkCleanup()
    local key, value = next(cleanupEntity)
    if not key then hook_Remove("Think", "proptomia_cleanup_props") return end

    if IsValid(value.ent) then
        if value.ent.Destruct then value.ent:Destruct() end
        if value.ent.OnRemove then value.ent:OnRemove() end
        value.ent:Remove()
    end
    cleanupEntity[key] = nil
    proptomia.props[value.id] = nil

    local isEmpty = next(cleanupEntity)
    if not isEmpty then
        hook_Remove("Think", "proptomia_cleanup_props")
    end
end
function proptomia.CleanupProps(steamid)
    local count = 0

    for k, v in next, proptomia.props do
        if v.SteamID ~= steamid then continue end

        table_insert(cleanupEntity, {
            id = k,
            ent = v.Ent
        })
        count = count + 1
    end

    proptomia.OwnershipCount[steamid] = nil
    if not hook_GetTable().Think.proptomia_cleanup_props then
        hook_Add("Think", "proptomia_cleanup_props", ThinkCleanup)
    end

    return count
end

local cleanupPlayers = {}
gameevent_Listen "player_disconnect"
gameevent_Listen "player_connect"

local cleanup_format = "Cleanuping %s[%s] props in %d seconds"
hook_Add("player_disconnect", "proptomia_cleanup_players", function(d)
    if proptomia.convars.cleanup_timer:GetInt() <= 0 then return end
    local steamid = d.networkid
    if not proptomia.OwnershipCount[steamid] or proptomia.OwnershipCount[steamid] <= 0 then return end

    cleanupPlayers[steamid] = true
    proptomia.LogInfo(cleanup_format:format(d.name, steamid, proptomia.convars.cleanup_timer:GetInt()))
    timer_Simple(proptomia.convars.cleanup_timer:GetInt(), function()
        if cleanupPlayers[steamid] then
            proptomia.CleanupProps(steamid)
            cleanupPlayers[steamid] = nil
        end
    end)
end)
hook_Add("player_connect", "proptomia_cleanup_clear_players", function(d)
    if proptomia.convars.cleanup_timer:GetInt() <= 0 then return end
    local steamid = d.networkid
    if cleanupPlayers[steamid] then
        cleanupPlayers[steamid] = nil
    end
end)


concommand.Add("proptomia_cleanup_disconnected", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    proptomia.LogInfo((IsValid(ply) and ply:Nick() or "Console") .. " removed all disconnected players' props")
    for k, v in next, cleanupPlayers do
        proptomia.CleanupProps(steamid)
        cleanupPlayers[k] = nil
    end
end, nil, "Remove all disconnected players' props (admin only)")