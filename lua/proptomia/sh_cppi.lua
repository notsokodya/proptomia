local _cppi = CPPI

if _cppi and _cppi.GetName() ~= "Proptomia" then

end

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

CPPI = CPPI or {}

CPPI.CPPI_DEFER = "112116"
CPPI.CPPI_NOTIMPLEMENTED = "8480"

function CPPI:GetName()
    return "Proptomia"
end
function CPPI:GetVersion()
    return "1.2"
end
function CPPI:GetInterfaceVersion()
    return 1.3
end

function ENTITY:CPPIGetOwner()
    local ent_owner = proptomia.props[self:EntIndex()]

    if ent_owner then
        return IsValid(ent_owner.owner) and ent_owner.owner or nil, CPPI.CPPI_NOTIMPLEMENTED
    end
end

function ENTITY:CPPISetOwner(ply)
    if not IsValid(ply) and ply ~= nil then return false end

    if ply == nil then
        return proptomia.SetOwnerless(self)
    else
        return proptomia.SetOwner(self, ply)
    end

    return false
end