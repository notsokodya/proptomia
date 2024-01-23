util.AddNetworkString("proptomia_buddies")

local cooldown = setmetatable({}, {__mode = "kv"})
local actions = {
    [0] = function(ply, steamid) -- recieveing buddies
        if cooldown[steamid] and cooldown[steamid] > os.time() then return end
        local count = net.ReadUInt(10) -- yeah, go ahead, add more than 1024 people

        if count > 1024 then
            proptomia.LogWarn(ply, " sent more than 1024 buddies (???)")
            return
        end

        proptomia.buddies[steamid] = {}
        local active_buddies = 0

        for i = 1, count do
            local sid = net.ReadString()
            local phys, tool, prop = net.ReadBool(), net.ReadBool(), net.ReadBool()

            proptomia.buddies[steamid][sid] = {phys, tool, prop}

            local ply = proptomia.GetPlayerBySteamID(sid)
            if ply then
                active_buddies = active_buddies + 1
                net.Start("proptomia_buddies")
                    net.WriteUInt(0, 1) -- buddy change

                    net.WriteString(steamid)
                    net.WriteBool(phys)
                    net.WriteBool(tool)
                    net.WriteBool(prop)
                net.Send(ply)
            end
        end

        cooldown[steamid] = os.time() + 3
        proptomia.LogDebug(_, " sent " .. count .. " buddies total (" .. active_buddies .. " active buddies)")
    end,
    [1] = function(_, steamid) -- adding / changing buddy
        local sid = net.ReadString()
        local phys, tool, prop = net.ReadBool(), net.ReadBool(), net.ReadBool()

        if not proptomia.buddies[steamid] then
            proptomia.buddies[steamid] = {
                [sid] = {phys, tool, prop}
            }
        else
            proptomia.buddies[steamid][sid] = {phys, tool, prop}
        end
        
        local ply = proptomia.GetPlayerBySteamID(sid)
        if IsValid(ply) then
            net.Start("proptomia_buddies")
                net.WriteUInt(0, 1)

                net.WriteString(steamid)
                net.WriteBool(phys)
                net.WriteBool(tool)
                net.WriteBool(prop)
            net.Send(ply)
        end

        proptomia.LogDebug(_, " changed " .. sid .. " permissions (", phys, ", ", tool, ", ", prop, ")")
    end,
    [2] = function(_, steamid) -- removing buddy
        local sid = net.ReadString()
        
        if proptomia.buddies[steamid] then
            local ply = proptomia.GetPlayerBySteamID(sid)
            net.Start("proptomia_buddies")
                net.WriteUInt(1, 1)
                net.WriteString(steamid)
            net.Send(ply)

            proptomia.buddies[steamid][sid] = nil
            proptomia.LogDebug(_, " removed ", sid, " from buddies")
        end
    end
}

net.Receive("proptomia_buddies", function(_, ply)
    local steamid = ply:SteamID()
    local action = net.ReadUInt(2)

    if actions[action] then
        actions[action](ply, steamid)
    else
        proptomia.LogWarn(ply, " sent unvalid action")
    end
end)


proptomia.IsBuddy = function(who, ply)
    if proptomia.buddies[who] then
        return proptomia.buddies[who][ply] ~= nil
    end

    return false
end
proptomia.BuddyAction = function(who, ply, action)
    if proptomia.buddies[who] and proptomia.buddies[who][ply] then
        local permissions = proptomia.buddies[who][ply]
        if action then
            return permissions[action] or false
        else
            return permissions[1] or permissions[2] or permissions[3]
        end
    end
    return false
end