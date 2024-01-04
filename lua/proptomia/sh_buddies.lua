if SERVER then
    util.AddNetworkString("proptomia_buddies")

    local cooldown = setmetatable({}, {__mode = "kv"})
    net.Receive("proptomia_buddies", function(_, ply)
        local steamid = ply:SteamID()
        local action = net.ReadUInt(2)
        if cooldown[steamid] and cooldown[steamid] > RealTime() then return end
        if not proptomia.buddies[steamid] then proptomia.buddies[steamid] = {} end

        if action == 0 then
            local count = net.ReadUInt(12)

            local buddies = {}
            for i = 1, count do
                local steamid = net.ReadString()
                local buddyAccess = {net.ReadBool(), net.ReadBool(), net.ReadBool()}
                buddies[steamid] = buddyAccess
            end
            proptomia[steamid] = buddies

            for k, v in next, player.GetAll() do
                local ply_sid = v:SteamID()
                if proptomia.buddies[steamid][ply_sid] then
                    net.Start("proptomia_buddies")
                        net.WriteUInt(0, 1)
                        net.WriteString(steamid)
                        for i = 1, 3 do
                            local access = proptomia.buddies[steamid][ply_sid][i]
                            net.WriteBool(access or false)
                        end
                    net.Send(v)
                end
                local ply_buddy = proptomia.buddies[ply_sid][steamid]
                if ply_buddy then
                    net.Start("proptomia_buddies")
                        net.WriteUInt(0, 1)
                        net.WriteString(ply_sid)
                        net.WriteBool(ply_buddy[1])
                        net.WriteBool(ply_buddy[2])
                        net.WriteBool(ply_buddy[3])
                    net.Send(ply)
                end
            end

            cooldown[steamid] = RealTime() + 3
        elseif action == 1 then
            local count = net.ReadUInt(12)

            local buddies = {}
            for i = 1, count do
                local ply_steamid = net.ReadString()
                local buddyAccess = {net.ReadBool(), net.ReadBool(), net.ReadBool()}
                proptomia.buddies[steamid][ply_steamid] = buddyAccess
                buddies[ply_steamid] = buddyAccess
            end

            for k, v in next, player.GetAll() do
                local access = buddies[v:SteamID()]
                if access then
                    net.Start("proptomia_buddies")
                        net.WriteUInt(0, 1)
                        net.WriteString(steamid)
                        net.WriteBool(access[1])
                        net.WriteBool(access[2])
                        net.WriteBool(access[3])
                    net.Send(v)
                end
            end
        elseif action == 2 then
            local count = net.ReadUInt(12)

            local steamids = {}
            for i = 1, count do
                local ply_steamid = net.ReadString()
                proptomia.buddies[steamid][ply_steamid] = nil
                steamids[ply_steamid] = true
            end

            local active_players = {}
            for k, v in next, player.GetAll() do
                if steamids[v:SteamID()] then
                    table.insert(active_players, v)
                end
            end

            net.Start("proptomia_buddies")
                net.WriteUInt(1, 1)
                net.WriteString(steamid)
            net.Send(active_players)
        end
    end)
end

proptomia.IsBuddy = function(who, ply)
    if proptomia.buddies[who] then
        return proptomia.buddies[who][ply] ~= nil
    end

    return false
end
proptomia.BuddyAction = function(who, ply, action)
    if proptomia.buddies[who] then
        local access = proptomia.buddies[who][ply]
        if access then
            if action then
                return access[action] or false
            else
                return access[1] or access[2] or access[3]
            end
        end
    end

    return false
end 

if CLIENT then
    proptomia.buddiesClient = {}
    sql.Query("CREATE TABLE IF NOT EXISTS proptomia_buddies (SteamID TEXT, Name TEXT, PhysGun BIT, ToolGun BIT, Properties BIT)")
    hook.Add("InitPostEntity", "proptomia_send_buddies", function()
        local steamid = LocalPlayer():SteamID()
        local buddies = sql.Query("SELECT * FROM proptomia_buddies")

        proptomia.buddies[steamid] = {}
        if buddies and not table.IsEmpty(buddies) then
            net.Start("proptomia_buddies")
                net.WriteUInt(0, 2)
                net.WriteUInt(#buddies, 12)
                for k, v in next, buddies do
                    local friendSteamID = v.SteamID
                    local phys, tool, prop = v.PhysGun == 1, v.ToolGun == 1, v.Properties == 1
                    proptomia.buddies[steamid][friendSteamID] = {phys, tool, prop}
                    proptomia.buddiesClient[friendSteamID] = {name = v.Name, phys = phys, tool = tool, prop = prop}
                    net.WriteString(friendSteamID)
                    net.WriteBool(phys)
                    net.WriteBool(tool)
                    net.WriteBool(prop)
                end
            net.SendToServer()

            for _, ply in next, player.GetAll() do
                local ply_steamid = ply:SteamID()
                if ply_steamid ~= steamid and proptomia.IsBuddy(steamid, ply_steamid) then
                    sql.Query("UPDATE proptomia_buddies SET Name = " .. sql.SQLStr(ply:Name(true)) .. " WHERE SteamID = " .. sql.SQLStr(ply_steamid) .. ";")
                end
            end
        end
    end)

    net.Receive("proptomia_buddies", function()
        local action = net.ReadUInt(1)
        local steamid = net.ReadString()
        print(action)
        if action == 0 then
            local lp_steamid = LocalPlayer():SteamID()
            local phys, tool, prop = net.ReadBool(), net.ReadBool(), net.ReadBool()
            local _phys, _tool, _prop = phys, tool, prop
            if proptomia.buddies[steamid] and proptomia.buddies[steamid][lp_steamid] then
                local access = proptomia.buddies[steamid][lp_steamid]
                _phys, _tool, _prop = access[1], access[2], access[3]
            end
            proptomia.buddies[steamid] = {}
            proptomia.buddies[steamid][lp_steamid] = {phys, tool, prop}
            hook.Run("BuddyAccessChanged", steamid, phys, tool, prop, _phys, _tool, _prop)
        else
            proptomia.buddies[steamid] = nil
            hook.Run("BuddyAccessChanged", steamid, false, false, false, false, false, false)
        end
    end)

    local changes = {add = {}, remove = {}}
    local function SendChanges()
        hook.Remove("Think", "proptomia_buddies_change") 

        local a_count = table.Count(changes.add)
        local r_count = table.Count(changes.remove)

        if a_count > 0 then
            net.Start("proptomia_buddies")
                net.WriteUInt(1, 2)
                net.WriteUInt(a_count, 12)
                for k, v in next, changes.add do
                    net.WriteString(v[1])
                    net.WriteBool(v[2])
                    net.WriteBool(v[3])
                    net.WriteBool(v[4])
                end
            net.SendToServer()
        end
        if r_count > 0 then
            net.Start("proptomia_buddies")
                net.WriteUInt(2, 2)
                net.WriteUInt(r_count, 12)
                for k, v in next, changes.remove do
                    net.WriteString(v)
                end
            net.SendToServer()
        end

        changes = {add = {}, remove = {}}
    end

    local add_format = "INSERT INTO proptomia_buddies (SteamID, Name, PhysGun, ToolGun, Properties) VALUES(%s, %s, %d, %d, %d);"
    local edit_format = "UPDATE proptomia_buddies SET PhysGun = %d, ToolGun = %d, Properties = %d WHERE SteamID = %s;"
    function proptomia.AddBuddy(steamid, name, phys, tool, prop)
        if not phys and not tool and not prop then return proptomia.RemoveBuddy(steamid) end
        phys = phys and 1 or 0
        tool = tool and 1 or 0
        prop = prop and 1 or 0
        local exist = sql.Query("SELECT * FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
        if exist then
            sql.Query(edit_format:format(phys, tool, prop, sql.SQLStr(steamid)))
        else
            sql.Query(add_format:format(sql.SQLStr(steamid), sql.SQLStr(name or steamid), phys, tool, prop))
        end

        phys = phys == 1
        tool = tool == 1
        prop = prop == 1
        table.insert(changes.add, {steamid, phys, tool, prop})
        local lsteamid = LocalPlayer():SteamID()
        if not proptomia.buddies[lsteamid] then proptomia.buddies[lsteamid] = {} end
        proptomia.buddies[lsteamid][steamid] = {phys, tool, prop}
        proptomia.buddiesClient[steamid] = {name = name or steamid, phys = phys, tool = tool, prop = prop}

        if not hook.GetTable().Think.proptomia_buddies_change then hook.Add("Think", "proptomia_buddies_change", SendChanges) end
        return true
    end
    function proptomia.RemoveBuddy(steamid)
        local exist = sql.Query("SELECT * FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
        if exist then
            sql.Query("DELETE FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
            table.insert(changes.remove, steamid)

            local lsteamid = LocalPlayer():SteamID()
            if not proptomia.buddies[lsteamid] then proptomia.buddies[lsteamid] = {} end
            proptomia.buddies[lsteamid][steamid] = nil
            proptomia.buddiesClient[steamid] = nil
            
            if not hook.GetTable().Think.proptomia_buddies_change then hook.Add("Think", "proptomia_buddies_change", SendChanges) end
            return true
        else
            return false
        end
    end
end