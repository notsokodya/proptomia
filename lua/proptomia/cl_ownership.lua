net.Receive("proptomia_ownership", function()
    local count = net.ReadUInt(13)

    for i = 1, count do
        local entIndex = net.ReadUInt(13)
        local ownerIndex = net.ReadUInt(13)
        local steamID = net.ReadString()
        local name = net.ReadString()

        local ent = Entity(entIndex)

        local ownerEnt
        if steamID == "W" then
            ownerEnt = game.GetWorld()
        elseif ownerIndex ~= 0 then
            ownerEnt = Entity(ownerIndex)
        end

        proptomia.props[entIndex] = {
            entity = ent,
            owner = ownerEnt,
            steamID = steamID,
            name = name
        }
    end
end)

hook.Add("EntityRemoved", "proptomia_ownership", function(ent, fullUpdate)
    if fullUpdate then return end

    local entIndex = ent:EntIndex()
    proptomia.props[entIndex] = nil
end)

function proptomia.GetOwner(ent)
    return proptomia.props[ent:EntIndex()]
end