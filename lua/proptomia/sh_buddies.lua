if SERVER then
    util.AddNetworkString("proptomia_buddies")

    local cooldown = setmetatable({}, {__mode = "kv"})
    net.Receive("proptomia_buddies", function(_, ply)
        local steamid = ply:SteamID()
        local cmd = net.ReadUInt(2)
        if cooldown[steamid] and cooldown[steamid] > RealTime() then return end

        if cmd == 0 then -- list buddies
            local count = net.ReadUInt(12)

            local buddies = {}
            for i = 1, count do
                local steamid = net.ReadString()
                buddies[steamid] = true
            end
            proptomia.buddies[steamid] = buddies

            local active_players = {}
            for k, v in next, player.GetAll() do
                if proptomia.buddies[steamid][v:SteamID()] then
                    table.insert(active_players)
                end
            end

            net.Start("proptomia_buddies")
                net.WriteUInt(0, 1)
                net.WriteString(steamid)
            net.Send(active_players)

            cooldown[steamid] = RealTime() + 2 -- 2 seconds (no shit sherlock)
            return
        elseif cmd == 1 then -- add buddies
            local count = net.ReadUInt(12)

            local steamids = {}
            for i = 1, count do
                local ply_steamid = net.ReadString()
                if not proptomia.buddies[steamid] then proptomia.buddies[steamid] = {} end
                proptomia.buddies[steamid][ply_steamid] = true
                steamids[ply_steamid] = true
            end

            local active_players = {}
            for k, v in next, player.GetAll() do
                if steamids[v:SteamID()] then
                    table.insert(active_players, v)
                end
            end

            net.Start("proptomia_buddies")
                net.WriteUInt(0, 1)
                net.WriteString(steamid)
            net.Send(active_players)
        elseif cmd == 2 then -- remove buddies
            local count = net.ReadUInt(12)

            local steamids = {}
            for i = 1, count do
                local ply_steamid = net.ReadString()
                if not proptomia.buddies[steamid] then proptomia.buddies[steamid] = {} end
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
        cooldown[steamid] = RealTime() + 1
    end)

    hook.Add("PlayerInitialSpawn", "proptomia_buddyList", function(ply)
        proptomia.buddies[ply:SteamID()] = {} -- initializing buddies list for player
    end)
end

proptomia.IsBuddy = function(target_steamid, ply_steamid)
    if proptomia.buddies[target_steamid] then
        return proptomia.buddies[target_steamid][ply_steamid]
    else
        return false
    end
end

if CLIENT then
    proptomia.buddiesClient = {}
    sql.Query("CREATE TABLE IF NOT EXISTS proptomia_buddies (SteamID TEXT, Name TEXT)")
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
                    proptomia.buddies[steamid][friendSteamID] = true
                    proptomia.buddiesClient[friendSteamID] = v.Name
                    net.WriteString(friendSteamID)
                end
            net.SendToServer()
        end

        for _, ply in next, player.GetAll() do
            local ply_steamid = ply:SteamID()
            if ply_steamid ~= steamid and proptomia.IsBuddy(steamid, ply_steamid) then
                sql.Query("UPDATE proptomia_buddies SET Name = " .. sql.SQLStr(ply:Name(true)) .. " WHERE SteamID = " .. sql.SQLStr(ply_steamid) .. ";")
            end
        end
    end)
    net.Receive("proptomia_buddies", function()
        local action = net.ReadUInt(1)
        local steamid = net.ReadString()
        if action == 0 then
            proptomia.buddies[steamid] = {}
            proptomia.buddies[steamid][LocalPlayer():SteamID()] = true
        else
            proptomia.buddies[steamid] = nil
        end
    end)

    local buddies_change = {a = {}, r = {}}
    local function SendChanges()
        hook.Remove("Think", "proptomia_buddies_change") 

        local a_count = table.Count(buddies_change.a)
        local r_count = table.Count(buddies_change.r)

        if a_count > 0 then
            net.Start("proptomia_buddies")
                net.WriteUInt(1, 2)
                net.WriteUInt(a_count, 12)
                for k, v in next, buddies_change.a do
                    net.WriteString(v)
                end
            net.SendToServer()
        end
        if r_count > 0 then
            net.Start("proptomia_buddies")
                net.WriteUInt(2, 2)
                net.WriteUInt(r_count, 12)
                for k, v in next, buddies_change.r do
                    net.WriteString(v)
                end
            net.SendToServer()
        end

        buddies_change = {a = {}, r = {}}
    end
    function proptomia.AddBuddy(steamid, name)
        local exist = sql.Query("SELECT * FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
        if exist then
            sql.Query("UPDATE proptomia_buddies SET Name = " .. sql.SQLStr(name) .. " WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
        else
            sql.Query("INSERT INTO proptomia_buddies (SteamID, Name) VALUES(" .. sql.SQLStr(steamid) .. ", " .. sql.SQLStr(name or steamid) .. ");")
        end
        table.insert(buddies_change.a, steamid)
        if not hook.GetTable().Think.proptomia_buddies_change then hook.Add("Think", "proptomia_buddies_change", SendChanges) end
        return true
    end
    function proptomia.RemoveBuddy(steamid)
        local exist = sql.Query("SELECT * FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
        if exist then
            sql.Query("DELETE FROM proptomia_buddies WHERE SteamID = " .. sql.SQLStr(steamid) .. ";")
            table.insert(buddies_change.r, steamid)
            if not hook.GetTable().Think.proptomia_buddies_change then hook.Add("Think", "proptomia_buddies_change", SendChanges) end
            return true
        else
            return false
        end
    end
end