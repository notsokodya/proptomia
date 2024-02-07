proptomia.clientBuddies = {}

local actions = {
    [0] = function() -- player changed permissions
        local steamid = net.ReadString()
        local phys, tool, prop = net.ReadBool(), net.ReadBool(), net.ReadBool()

        hook.Run("ProptomiaPermissionChange", true, steamid, phys, tool, prop)
        proptomia.buddies[steamid] = {phys, tool, prop}
    end,
    [1] = function() -- player removed you
        local steamid = net.ReadString()
        hook.Run("ProptomiaPermissionChange", false, steamid)
        proptomia.buddies[steamid] = nil
    end
}
net.Receive("proptomia_buddies", function()
    local action = net.ReadUInt(1)

    if actions[action] then
        actions[action]()
    else
        proptomia.LogWarn("server sent unvalid action (probably drunk)")
    end
end)


do -- migration (i will delete this at 21.02.2024)
    local migrating_keys = sql.Query("PRAGMA table_info('proptomia_buddies');")
    if migrating_keys and migrating_keys[1] and migrating_keys[1].name == "SteamID" then
        proptomia.LogDebug("Migration started")
        proptomia.LogWarn("Old table schema detected! Migrating to new one..")

        local values = sql.Query("SELECT * FROM proptomia_buddies;")

        proptomia.LogDebug("Dropping old table")
        sql.Query("DROP TABLE proptomia_buddies")
        sql.Query("CREATE TABLE IF NOT EXISTS proptomia_buddies (steamid TEXT, name TEXT, physgun BIT, toolgun BIT, properties BIT);")

        if values then
            proptomia.LogDebug("Buddies existed in old table, migrating them...")
            local insert_query = "INSERT INTO proptomia_buddies (steamid, name, physgun, toolgun, properties) VALUES(%s, %s, %d, %d, %d);"
            local debug_format = "%s [%s] (%d, %d, %d)"
            for k, v in next, values do
                proptomia.LogDebug(debug_format:format(v.Name, v.SteamID, v.PhysGun, v.ToolGun, v.Properties))
                sql.Query(insert_query:format(
                    sql.SQLStr(v.SteamID),
                    sql.SQLStr(v.Name),
                    v.PhysGun,
                    v.ToolGun,
                    v.Properties
                ))
            end
        end

        proptomia.LogDebug("Migration done")
        proptomia.LogWarn("Migration is done!")
    end
end


sql.Query("CREATE TABLE IF NOT EXISTS proptomia_buddies (steamid TEXT, name TEXT, physgun BIT, toolgun BIT, properties BIT);")

hook.Add("InitPostEntity", "proptomia_buddies", function()
    local steamid = LocalPlayer():SteamID()
    local buddies = sql.Query("SELECT * FROM proptomia_buddies")

    if buddies and not table.IsEmpty(buddies) then
        net.Start("proptomia_buddies")
            net.WriteUInt(0, 2)

            local count = #buddies
            net.WriteUInt(count, 10)

            for i = 1, count do
                local v = buddies[i]
                local phys, tool, prop = v.physgun == 1, v.toolgun == 1, v.properties == 1

                net.WriteString(v.steamid)
                net.WriteBool(phys)
                net.WriteBool(tool)
                net.WriteBool(prop)

                proptomia.clientBuddies[v.steamid] = {v.name, phys, tool, prop}
            end
        net.SendToServer()

        for k, v in next, player.GetAll() do
            local sid = v:SteamID()

            if sid ~= steamid and proptomia.IsMyBuddy(sid) then
                sql.Query("UPDATE proptomia_buddies SET name = " .. sql.SQLStr( v:Name(true) ) .. " WHERE steamid = " .. sql.SQLStr(sid) .. ":")
            end
        end
    end
end)

local insert_query = "INSERT INTO proptomia_buddies (steamid, name, physgun, toolgun, properties) VALUES(%s, %s, %d, %d, %d);"
local update_query = "UPDATE proptomia_buddies SET physgun = %d, toolgun = %d, properties = %d WHERE steamid = %s;"
local remove_query = "DELETE FROM proptomia_buddies WHERE SteamID = %s"
function proptomia.ChangeBuddyPermission(steamid, name, phys, tool, prop)
    if not (phys or tool or prop) then
        proptomia.clientBuddies[steamid] = nil
        sql.Query(remove_query:format(sql.SQLStr(steamid)))

        net.Start("proptomia_buddies")
            net.WriteUInt(2, 2)
            net.WriteString(steamid)
        net.SendToServer()

        return
    end

    proptomia.clientBuddies[steamid] = {name or steamid, phys, tool, prop}
    
    local sql_row_exists = sql.Query("SELECT * FROM proptomia_buddies WHERE steamid = " .. sql.SQLStr(steamid))
    if sql_row_exists then
        sql.Query(update_query:format(
            phys and 1 or 0,
            tool and 1 or 0,
            prop and 1 or 0,
            sql.SQLStr(steamid)
        ))
    else
        sql.Query(insert_query:format(
            sql.SQLStr(steamid),
            sql.SQLStr(name or steamid),
            phys and 1 or 0,
            tool and 1 or 0,
            prop and 1 or 0
        ))
    end

    net.Start("proptomia_buddies")
        net.WriteUInt(1, 2)

        net.WriteString(steamid)
        net.WriteBool(phys)
        net.WriteBool(tool)
        net.WriteBool(prop)
    net.SendToServer()
end


function proptomia.IsMyBuddy(who)
    return proptomia.clientBuddies[who] ~= nil
end
function proptomia.IsBuddy(who)
    return proptomia.buddies[who] ~= nil
end
function proptomia.BuddyAction(who, _, action)
    if proptomia.buddies[who] then
        local permissions = proptomia.buddies[who]
        if action then
            return permissions[action] or false
        else
            return permissions[1] or permissions[2] or permissions[3]
        end
    end
    return false
end