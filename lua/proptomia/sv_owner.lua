util.AddNetworkString "proptomia_ownership"

proptomia.OwnershipQueue = {}

local ownership_update = function()
    if not table.IsEmpty(proptomia.OwnershipQueue) then
        net.Start "proptomia_ownership"
            net.WriteUInt(#proptomia.OwnershipQueue, 13)

            for k, v in next, proptomia.OwnershipQueue do
                net.WriteUInt(k, 16)
                net.WriteUInt(IsValid(v.Owner) and v.Owner:EntIndex() or 0, 16)
                net.WriteString(v.Name)
                net.WriteString(v.SteamID)
            end
        net.Broadcast()
    end

    proptomia.OwnershipQueue = {}
    hook.Remove("Think", "ProptomiaUpdate")
end
function proptomia.NetworkOwnership(entIndex)
    if not hook.GetTable().Think.ProptomiaUpdate then
        hook.Add("Think", "ProptomiaUpdate", ownership_update)
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
        proptomia.LogError("SetOwner", " Bad player entity")
        return false
    end

    local current_owner = proptomia.GetOwner(ent)
    if current_owner and (current_owner.SteamID ~= "O" and current_owner.SteamID ~= ply:SteamID()) then
        proptomia.LogError("SetOwner", "Changing owner not supported: ", current_owner or "nil", " -> ", ply or "ply", " for ", ent or "ent")
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
        return false
    end

    proptomia.props[ent:EntIndex()] = nil
    -- proptomia.NetworkOwnership(entIndex) (?)

    return true
end

hook.Add("EntityRemoved", "proptomia_owner", proptomia.RemoveOwner)


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
    end

    -- send owners somehow
end

hook.Add("PlayerInitialSpawn", "proptomia_assign_props", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            proptomia.PlayerInitialized(ply)
        end 
    end)
end)


local function entSpawn(ply, ent, ent2)
    if isstring(ent) then ent = ent2 end
    if not IsValid(ent) then ent = ent2 end
    if IsValid(ent) then
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
        return undo_Entity(ent)
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

hook.Add("OnEntityCreated", "proptomia_ownership", function(ent)
    if not IsValid(ent)
    or     ent:IsWeapon()
    or     ent:CPPIGetOwner()
    then return end

    if ent:GetClass() == "predicted_viewmodel" then return end

    local ply = ent:GetOwner()
    if IsValid(ply) and ply:IsPlayer() then
        entSpawn(ply, ent)
    else
        timer.Simple(.1, function()
            if not IsValid(ent) then return end
            if not IsValid(ent:CPPIGetOwner()) then
                proptomia.SetOwnerWorld(ent)
            end
        end)
    end
end)



function proptomia.OnPropsCleanup()
    local count = 0
    for k, v in next, ents.GetAll() do
        local owner = v:CPPIGetOwner()
        if owner and owner:IsWorld() then
            count = count + 1
        elseif not owner then  
            proptomia.SetOwnerWorld(v)
            count = count + 1
        end
    end

    proptomia.LogInfo("Total amount of world entities: " .. count)
end

local shouldset
hook.Add("PostCleanupMap", "proptomia_cleanup", function()
    proptomia.props = {}
    shouldset = true

    if not shouldset then
        timer.Simple(.5, function()
            proptomia.OnPropsCleanup()
            shouldset = nil
        end)
    end
end)