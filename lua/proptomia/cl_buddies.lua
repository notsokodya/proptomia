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

sql.Query("CREATE TABLE IF NOT EXISTS proptomia_buddies (steamid TEXT, name TEXT, physgun BIT, toolgun BIT, properties BIT);")

local insert_query = "INSERT INTO proptomia_buddies (steamid, name, physgun, toolgun, properties) VALUES(%s, %s, %d, %d, %d);"
local update_query = "UPDATE proptomia_buddies SET physgun = %d, toolgun = %d, properties = %d WHERE steamid = %s;"
local remove_query = "DELETE FROM proptomia_buddies WHERE steamid = %s;"
local remove_by_name_query = "DELETE FROM proptomia_buddies WHERE name = %s;"

hook.Add("InitPostEntity", "proptomia_buddies", function()
    local steamid = LocalPlayer():SteamID()
    local buddies = sql.Query("SELECT * FROM proptomia_buddies")

    -- check if table ok
    for k, row in next, buddies do
        if not row.steamid and row.name then
            proptomia.LogError("Buddies has damaged row, removing it -> ", k, row.name)
            sql.Query(remove_by_name_query:format(row.name))
            table.remove(buddies, k)
        elseif not row.steamid and not row.name then
            proptomia.LogError("Buddies has damaged row -> ", k)
            table.remove(buddies, k)
        end
    end

    if buddies and not table.IsEmpty(buddies) then
        net.Start("proptomia_buddies")
            net.WriteUInt(0, 2)

            local count = #buddies
            net.WriteUInt(count, 10)

            for i = 1, count do
                local v = buddies[i]
                local phys, tool, prop = v.physgun == 1, v.toolgun == 1, v.properties == 1
                if v.steamid == nil then
                    proptomia.LogError("Buddies Row is still damaged somehow (???)")
                    continue
                end

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

function proptomia.ChangeBuddyPermission(steamid, name, phys, tool, prop)
    if not steamid then return end

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