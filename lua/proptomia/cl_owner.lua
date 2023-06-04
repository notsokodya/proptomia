net.Receive("proptomia_ownership", function()
    local count = net.ReadUInt(13)

    for i = 1, count do
        local ent = net.ReadUInt(16)
        local owner = net.ReadUInt(16)
        local name = net.ReadString()
        local steamid = net.ReadString()

        local ownerEnt
        if owner == 0 then
            if steamid == "W" then
                ownerEnt = game.GetWorld()
            end
        else
            ownerEnt = Entity(owner)
        end

        proptomia.props[ent] = {
            Ent = Entity(ent),
            Owner = ownerEnt,
            Name = name,
            SteamID = steamid
        }
    end
end)

hook.Add("EntityRemoved", "proptomia_ownership", function(ent)
    local entIndex = ent:EntIndex()
    if proptomia.props[entIndex] then
        proptomia.props[entIndex] = nil
    end
end)

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