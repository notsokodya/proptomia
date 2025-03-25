util.AddNetworkString "proptomia_ownership"

local network_queue = {}

local function ownership_network()
    if not table.IsEmpty(network_queue) then
        net.Start "proptomia_ownership"
            net.WriteUInt(table.Count(network_queue), 13)

            for k, v in next, network_queue do
                net.WriteUInt(k, 13)
                net.WriteUInt(IsValid(v.owner) and v.owner:EntIndex() or 0, 13)
                net.WriteString(v.steamID)
                net.WriteString(v.name)
            end
        net.Broadcast()
    end

    network_queue = {}
    hook.Remove("Think", "proptomia_ownership_network")
end

function proptomia.NetworkOwnership(entIndex)
    network_queue[entIndex] = proptomia.props[entIndex]

    local hooks = hook.GetTable()
    if not hooks.Think or not hooks.Think.proptomia_ownership_network then
        hook.Add("Think", "proptomia_ownership_network", ownership_network)
    end
end


function proptomia.GetOwner(ent)
    return proptomia.props[ent:EntIndex()]
end
function proptomia.SetOwner(ent, ply)
    if not ent then
        proptomia.LogError("SetOwner", " Missing entity")
        return false
    end
    if not ply then
        proptomia.LogError("SetOwner", " Missing player")
        return false
    end
    if not IsValid(ply) or not ply:IsPlayer() then
        proptomia.LogError("SetOwner", " Bad player entity: ", ply)
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        entity = ent,
        owner = ply,
        steamID = ply:SteamID(),
        name = ply:Name()
    }
    proptomia.NetworkOwnership(entIndex)

    proptomia.LogDebug("Ownership | assigned", ent, "to", ply)

    return true
end
function proptomia.SetOwnerWorld(ent)
    if not ent then
        proptomia.LogError("SetOwnerWorld", " Missing entity")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        entity = ent,
        owner = game.GetWorld(),
        steamID = "W",
        name = "W"
    }
    proptomia.NetworkOwnership(entIndex)

    proptomia.LogDebug("Ownership | assigned", ent, "to The World")

    return true
end
function proptomia.SetOwnerless(ent)
    if not ent then
        proptomia.LogError("SetOwnerless", " Missing entity")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        entity = ent,
        owner = nil,
        steamID = "O",
        name = "O"
    }
    proptomia.NetworkOwnership(entIndex)

    proptomia.LogDebug("Ownership | assigned", ent, "to nobody")

    return true
end
function proptomia.RemoveOwner(ent)
    if not ent then
        proptomia.LogError("RemoveOwner", " Missing entity")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = nil

    proptomia.LogDebug("Ownership | removed", ent, "from list")

    return true
end

hook.Add("EntityRemoved", "proptomia_ownership", proptomia.RemoveOwner)

local ignore_list = {
    ["predicted_viewmodel"] = true,
    ["player_manager"] = true,
    ["phys_bone_follower"] = true,
    ["bodyqueue"] = true,
    ["gmod_hands"] = true,
    ["bodyque"] = true,
    ["beam"] = true,
    ["physgun_beam"] = true,
    ["player_pickup"] = true,
    ["env_sprite"] = true,
    ["env_sporeexplosion"] = true,
    ["env_spritetrail"] = true,
    ["env_rockettrail"] = true,
    ["worldspawn"] = true,
    ["phys_lengthconstraint"] = true
}

local function entSpawn(ply, ent, ent2)
    if isstring(ent) then ent = ent2 end
    if not IsValid(ent) then ent = ent2 end

    if IsValid(ent) and not ignore_list[ent:GetClass()] and not IsValid(ent:CPPIGetOwner()) then
        proptomia.SetOwner(ent, ply)
    end
end

hook.Add("PlayerSpawnedProp", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedNPC", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedEffect", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedRagdoll", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedSENT", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedVehicle", "proptomia_ownership", entSpawn)
hook.Add("PlayerSpawnedSWEP", "proptomia_ownership", entSpawn)

hook.Add("OnEntityCreated", "proptomia_ownership", function(ent)
    if not IsValid(ent)
    or     ent:IsWorld()
    or     ent:IsWeapon()
    or     ent:CPPIGetOwner()
    or     ignore_list[ent:GetClass()]
    then return end

    local ply = ent:GetOwner()
    if IsValid(ply) and ply:IsPlayer() then
        proptomia.SetOwner(ent, ply:GetOwner())
    else
        timer.Simple(.1, function()
            if not IsValid(ent) then return end
            if not IsValid(ent:CPPIGetOwner()) then
                if ent.GetOwner and ent:GetOwner() and ent:GetOwner():IsPlayer() then
                    proptomia.SetOwner(ent, ent:GetOwner())
                elseif ent:GetInternalVariable("m_hOwner") or ent:GetSaveTable().m_hOwner then
                    local owner = ent:GetInternalVariable("m_hOwner") or ent:GetSaveTable().m_hOwner

                    if owner and owner:IsPlayer() then
                        proptomia.SetOwner(ent, ply)
                    end
                else
                    proptomia.SetOwnerless(ent)
                end
            end
        end)
    end
end)

if not proptomia.RestoreBackupFunctions then
    local PLAYER = FindMetaTable("Player")

    local Player_AddCount = PLAYER.AddCount

    local currentUndo
    local currentUndo_player
    local undo_Create = undo.Create
    local undo_AddEntity = undo.AddEntity
    local undo_SetPlayer = undo.SetPlayer
    local undo_Finish = undo.Finish

    local cleanup_Add = cleanup.Add

    function proptomia.RestoreBackupFunctions()
        FindMetaTable("Player").AddCount = Player_AddCount
        undo.Create = undo_Create
        undo.AddEntity = undo_AddEntity
        undo.SetPlayer = undo_SetPlayer
        undo.Finish = undo_Finish

        proptomia.LoadBackupFunctions = nil
        proptomia.LogDebug("Ownership | Restored original functions")
    end

    function PLAYER:AddCount(str, ent)
        entSpawn(self, ent)
        return Player_AddCount(self, str, ent)
    end

    function undo.Create(...)
        currentUndo = {}
        return undo_Create(...)
    end
    function undo.AddEntity(ent)
        if currentUndo and IsValid(ent) then
            table.insert(currentUndo, ent)
        end

        return undo_AddEntity(ent)
    end
    function undo.SetPlayer(ply)
        if currentUndo and IsValid(ply) then
            currentUndo_player = ply
        end

        return undo_SetPlayer(ply)
    end
    function undo.Finish(...)
        if currentUndo and IsValid(currentUndo_player) then
            for _, ent in next, currentUndo do
                entSpawn(currentUndo_player, ent)
            end

            currentUndo_player = nil
            currentUndo = nil
        end

        return undo_Finish(...)
    end

    function cleanup.Add(ply, type, ent, ...)
        if IsValid(ent) and IsValid(ply) and ply:IsPlayer() then
            entSpawn(ply, ent)
        end

        return cleanup_Add(ply, type, ent, ...)
    end
end

function proptomia.OnPropsCleanup()
    local count = 0

    for k, ent in next, ents.GetAll() do
        if ent:IsWorld() then continue end

        local owner = ent:CPPIGetOwner()
        if owner and owner:IsWorld() then
            count = count + 1
        elseif not owner then
            proptomia.SetOwnerWorld(ent)
            count = count + 1
        end
    end

    proptomia.LogInfo("Total world entities: ", count)
end

hook.Add("PostCleanupMap", "proptomia_cleanup", function()
    proptomia.props = {}

    if not shouldset then
        shouldset = true
        timer.Simple(.5, function()
            proptomia.OnPropsCleanup()
            shouldset = nil
        end)
    end
end)