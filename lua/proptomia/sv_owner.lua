local net_Start, net_WriteUInt, net_WriteString, net_Broadcast, hook_Add, hook_Remove, hook_GetTable, timer_Simple, IsValid, isstring, table_Count, ents_GetAll =
      net.Start, net.WriteUInt, net.WriteString, net.Broadcast, hook.Add, hook.Remove, hook.GetTable, timer.Simple, IsValid, isstring, table.Count, ents.GetAll
util.AddNetworkString "proptomia_ownership"

proptomia.OwnershipQueue = {}
proptomia.OwnershipCount = {}

local ownership_update = function()
    if not table.IsEmpty(proptomia.OwnershipQueue) then
        net_Start "proptomia_ownership"
            net_WriteUInt(table_Count(proptomia.OwnershipQueue), 13)

            for k, v in next, proptomia.OwnershipQueue do
                net_WriteUInt(k, 13)
                net_WriteUInt(IsValid(v.Owner) and v.Owner:EntIndex() or 0, 13)
                net_WriteString(v.Name)
                net_WriteString(v.SteamID)
            end
        net_Broadcast()
    end

    proptomia.OwnershipQueue = {}
    hook_Remove("Think", "ProptomiaUpdate")
end
function proptomia.NetworkOwnership(entIndex)
    if not hook_GetTable().Think or not hook_GetTable().Think.ProptomiaUpdate then
        hook_Add("Think", "ProptomiaUpdate", ownership_update)
    end

    proptomia.OwnershipQueue[entIndex] = proptomia.props[entIndex]
end

function proptomia.GetOwner(ent)
	if not IsValid(ent) then
		return {
			Ent = ent,
			Owner = nil,
			SteamID = nil,
			Name = nil
		}
	end
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

    local current_owner = proptomia.GetOwner(ent)
    if current_owner and (current_owner.SteamID ~= "O" and current_owner.SteamID ~= ply:SteamID()) then
        proptomia.LogError("SetOwner", "Changing owner not supported: ", current_owner.SteamID or "nil", " -> ", ply or "ply", " for ", ent or "ent")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        Ent = ent,
        Owner = ply,
        SteamID = ply:SteamID(),
        Name = ply:Name()
    }
    proptomia.NetworkOwnership(entIndex)
    proptomia.OwnershipCount[ply:SteamID()] = proptomia.OwnershipCount[ply:SteamID()] and proptomia.OwnershipCount[ply:SteamID()] + 1 or 0

    return true
end
function proptomia.SetOwnerWorld(ent)
    if not ent then
        proptomia.LogError("SetOwnerWorld", " Missing entity")
        return false
    end

    local current_owner = proptomia.GetOwner(ent)
    if current_owner and (current_owner.SteamID ~= "O" and current_owner.SteamID ~= "W") then
        proptomia.LogError("SetOwnerWorld", "Changing owner not supported: ", current_owner.SteamID or "nil", " -> ", "world", " for ", ent or "ent")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        Ent = ent,
        Owner = game.GetWorld(),
        SteamID = "W",
        Name = "W"
    }
    proptomia.NetworkOwnership(entIndex)

    return true
end
function proptomia.UnsetOwner(ent)
    if not ent then
        proptomia.LogError("UnsetOwner", " Missing entity")
        return false
    end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = {
        Ent = ent,
        Owner = nil,
        SteamID = "O",
        Name = ""
    }
    proptomia.NetworkOwnership(entIndex)

    return true
end
function proptomia.RemoveOwner(ent)
    if not ent then
        proptomia.LogError("RemoveOwner", " Missing entity")
        return
    end

    local owner = proptomia.props[ent:EntIndex()]
    if owner then
        proptomia.OwnershipCount[owner.SteamID] = proptomia.OwnershipCount[owner.SteamID] and proptomia.OwnershipCount[owner.SteamID] - 1 or 0
    end

    proptomia.props[ent:EntIndex()] = nil
    -- proptomia.NetworkOwnership(entIndex) (?)
end

hook.Add("EntityRemoved", "proptomia_owner", proptomia.RemoveOwner)

function proptomia.SendOwnersTo(ply, except_player_props)
    local props = {}
    if except_player_props then
        local sid = ply:SteamID()
        for k, v in next, proptomia.props do
            if v.SteamID ~= sid then props[k] = v end
        end
    else
        props = proptomia.props
    end

    if table_Count(props) > 0 then
        net_Start "proptomia_ownership"
            net_WriteUInt(table_Count(props), 13)

            for k, v in next, props do -- rip network
                net_WriteUInt(k, 13)
                net_WriteUInt(IsValid(v.Owner) and v.Owner:EntIndex() or 0, 13)
                net_WriteString(v.Name)
                net_WriteString(v.SteamID)
            end
        net_Broadcast()
    end
end
local assign_info_format = "%s[%s] assigned %d entities"
function proptomia.PlayerInitialized(ply)
    local steamid = ply:SteamID()
    local count = 0

    for k, v in next, proptomia.props do
        if v.SteamID ~= steamid then continue end
        proptomia.SetOwner(v.Ent, ply)
        count = count + 1
    end

    if count > 0 then
        ply:ChatPrint("Assigned " .. count .. " props to you!")
        proptomia.OwnershipCount[steamid] = count
        proptomia.LogInfo(assign_info_format:format(ply:Name(), ply:SteamID(), count))
    end

    proptomia.buddies[steamid] = {}
    proptomia.SendOwnersTo(ply, true)
end

hook_Add("PlayerInitialSpawn", "proptomia_assign_props", function(ply)
    timer_Simple(2, function()
        if IsValid(ply) then
            proptomia.PlayerInitialized(ply)
        end
    end)
end)

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
    ["phys_lengthconstraint"] = true -- for some reason has same id as worldspawn
}
local function entSpawn(ply, ent, ent2)
    if isstring(ent) then ent = ent2 end
    if not IsValid(ent) then ent = ent2 end
    if IsValid(ent) and not ignore_list[ent:GetClass()] then
        proptomia.SetOwner(ent, ply)
    end
end
hook_Add("PlayerSpawnedProp", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedNPC", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedEffect", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedRagdoll", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedSENT", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedVehicle", "proptomia_ownership", entSpawn)
hook_Add("PlayerSpawnedSWEP", "proptomia_ownership", entSpawn)

if not proptomia.BackupFunctions then
    local PLAYER = FindMetaTable("Player")
    local Player_AddCount = PLAYER.AddCount

    local CurrentUndo
    local undo_Create = undo.Create
    local undo_AddEntity = undo.AddEntity
    local undo_SetPlayer = undo.SetPlayer
    local undo_Finish = undo.Finish

    local cleanup_Add = cleanup.Add

    function proptomia.BackupFunctions()
        FindMetaTable("Player").AddCount = Player_AddCount
        undo.Create = undo_Create
        undo.AddEntity = undo_AddEntity
        undo.SetPlayer = undo_SetPlayer
        undo.Finish = undo_Finish
        cleanup.Add = cleanup_Add
    end


    function PLAYER:AddCount(str, ent)
        entSpawn(self, ent)
        return Player_AddCount(self, str, ent)
    end

    function undo.Create(...)
        CurrentUndo = {ents = {}}
        return undo_Create(...)
    end
    function undo.AddEntity(ent)
        if CurrentUndo and IsValid(ent) then
            table.insert(CurrentUndo.ents, ent)
        end
        return undo_AddEntity(ent)
    end
    function undo.SetPlayer(ply)
        if CurrentUndo and IsValid(ply) then
            CurrentUndo.ply = ply
        end
        return undo_SetPlayer(ply)
    end
    function undo.Finish(...)
        if CurrentUndo and IsValid(CurrentUndo.ply) then
            local ply = CurrentUndo.ply
            for _, ent in next, CurrentUndo.ents do
                entSpawn(ply, ent)
            end
            CurrentUndo = nil
        end
        return undo_Finish(...)
    end

    function cleanup.Add(ply, type, ent, ...)
        if IsValid(ply) and IsValid(ent) then
            entSpawn(ply, ent)
        end

        return cleanup_Add(ply, type, ent, ...)
    end

end

hook_Add("OnEntityCreated", "proptomia_ownership", function(ent)
    if not IsValid(ent)
    or     ent:IsWorld()
    or     ent:IsWeapon()
    or     ent:CPPIGetOwner()
    then return end

    if ignore_list[ent:GetClass()] then return end

    local ply = ent:GetOwner()
    if IsValid(ply) and ply:IsPlayer() then
        entSpawn(ply, ent)
    else
        timer_Simple(.1, function()
            if not IsValid(ent) then return end
            if not IsValid(ent:CPPIGetOwner()) then
                if ent.GetOwner and ent:GetOwner() and ent:GetOwner():IsPlayer() then -- hacks
                    proptomia.SetOwner(ent, ent:GetOwner())
                elseif ent:GetInternalVariable("m_hOwner") or ent:GetSaveTable().m_hOwner then -- more hacks
                    local owner = ent:GetInternalVariable("m_hOwner") or ent:GetSaveTable().m_hOwner

                    if owner and owner:IsPlayer() then -- hacky hack
                        proptomia.SetOwner(ent, owner)
                    end
                else
                    proptomia.SetOwnerWorld(ent)
                end
            end
        end)
    end
end)



function proptomia.OnPropsCleanup()
    local count = 0
    for k, v in next, ents_GetAll() do
        if v:IsWorld() then continue end
        local owner = v:CPPIGetOwner()
        if owner and owner:IsWorld() then
            count = count + 1
        elseif not owner then
            proptomia.SetOwnerWorld(v)
            count = count + 1
        end
    end
    proptomia.OwnershipCount = {}

    proptomia.LogInfo("Total amount of world entities: " .. count)
end

local shouldset
hook_Add("PostCleanupMap", "proptomia_cleanup", function()
    proptomia.props = {}

    if not shouldset then
        shouldset = true
        timer_Simple(.5, function()
            proptomia.OnPropsCleanup()
            shouldset = nil
        end)
    end
end)