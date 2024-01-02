proptomia.convars.protection = CreateConVar("proptomia_protection", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Toggle prop protection", 0, 1)

function proptomia.CanTouch(ent, ply, action)
    if not IsValid(ent)
    or not IsValid(ply)
    or not ply:IsPlayer()
    or not proptomia.convars.protection:GetBool()
    then return end

    local owner = proptomia.GetOwner(ent)
    if not owner then return end

    local owner_SteamID, ply_SteamID = owner.SteamID, ply:SteamID()
    if owner_SteamID ~= "O" and owner_SteamID ~= ply_SteamID and not proptomia.BuddyAction(owner_SteamID, ply_SteamID, action) then
        return ply:IsAdmin()
    end

    return true
end

function proptomia.CanPhysgunPickup(ply, ent)
    return proptomia.CanTouch(ent, ply, 1)
end

function proptomia.CanPhysgunReload(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if proptomia.CanTouch(ply:GetEyeTrace().Entity, ply, 1) == false then return false end
end
function proptomia.CanPlayerUnfreeze(ply, ent, physobj)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if proptomia.CanTouch(ent, ply, 1) == false then return false end
end

function proptomia.CanPhysgunFreeze(wep, obj, ent, ply)
    if proptomia.CanTouch(ent, ply, 1) == false then return false end
end
function proptomia.CanTool(ply, tr, mode, tool, bt)
    local ent = tr.Entity
    if not IsValid(ent)
    or not IsValid(ply)
    or not ply:IsPlayer()
    or not proptomia.convars.protection:GetBool()
    then return end

    if ent:IsPlayer() then return false end

    tool = tool or {}

    if proptomia.CanTouch(ent, ply, 2) then
        if tool.Objects then
            for k, v in next, tool.Objects do
                local tent = v.Ent
                if IsValid(tent) then
                    print(tent, proptomia.CanTouch(tent, ply, 2))
                    if proptomia.CanTouch(tent, ply, 2) == false then
                        return false
                    end
                end
            end
        end

        if mode == "remover" and bt == 2 and SERVER then
            for k, v in next, constraint.GetAllConstrainedEntities(ent) or {} do
                if proptomia.CanTouch(ent, ply, 2) == false then
                    return false
                end
            end
        end
    else
        return false
    end

    return true
end

function proptomia.CanProperty(ply, property, ent)
    if proptomia.CanTouch(ent, ply, 3) == false then return false end
end
 
hook.Add("PhysgunPickup", "proptomia_protection", proptomia.CanPhysgunPickup)
hook.Add("OnPhysgunReload", "proptomia_protection", proptomia.CanPhysgunReload)
hook.Add("CanPlayerUnfreeze", "proptomia_protection", proptomia.CanPlayerUnfreeze)
hook.Add("OnPhysgunFreeze", "proptomia_protection", proptomia.CanPhysgunFreeze)
hook.Add("CanTool", "proptomia_protection", proptomia.CanTool)
hook.Add("CanProperty", "proptomia_protection", proptomia.CanProperty)