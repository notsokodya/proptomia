function proptomia.CanTouch(ent, ply)
    if not IsValid(ent)
    or not IsValid(ply)
    or not ply:IsPlayer()
    or not proptomia.convars.enable
    then return end

    local owner = proptomia.GetOwner(ent)
    if not owner then return end

    local owner_SteamID, ply_SteamID = owner.SteamID, ply:SteamID()
    if owner_SteamID ~= "O" and owner_SteamID ~= ply_SteamID and not proptomia.AreBuddies(owner_SteamID, ply_SteamID) then
        return ply:IsAdmin()
    end

    return true
end

function proptomia.CanPhysgunPickup(ply, ent)
    return proptomia.CanTouch(ent, ply)
end
function proptomia.CanPhysgunReload(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    return proptomia.CanTouch(ply:GetEyeTrace().Entity, ply)
end
function proptomia.CanPhysgunFreeze(wep, obj, ent, ply)
    if proptomia.CanTouch(ent, ply) == false then return false end
end
function proptomia.CanTool(ply, tr, mode, tool, bt)
    local ent = tr.Entity
    if not IsValid(ent)
    or not IsValid(ply)
    or not ply:IsPlayer()
    or not proptomia.convars.enable
    then return end

    if ent:IsPlayer() then return false end

    tool = tool or {}

    if proptomia.CanTouch(ent, ply) then
        if tool.Objects then
            for k, v in next, tool.Objects do
                local tent = v.Ent
                if IsValid(tent) then
                    if proptomia.CanTouch(tent, ply) == false then
                        return false
                    end
                end
            end
        end

        if mode == "remover" and bt == 2 and SERVER then
            for k, v in next, constraint.GetAllConstrainedEntities(ent) or {} do
                if proptomia.CanTouch(ent, ply) == false then
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
    if proptomia.CanTouch(ent, ply) == false then return false end
end
 
hook.Add("PhysgunPickup", "proptomia_protection", proptomia.CanPhysgunPickup)
hook.Add("OnPhysgunReload", "proptomia_protection", proptomia.CanPhysgunReload)
hook.Add("OnPhysgunFreeze", "proptomia_protection", proptomia.CanPhysgunFreeze)
hook.Add("CanTool", "proptomia_protection", proptomia.CanTool)
hook.Add("CanProperty", "proptomia_protection", proptomia.CanProperty)