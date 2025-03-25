proptomia = proptomia or {
    props = {},
    buddies = {},
    convars = {},
    debug = false
}

local function concat(...)
    local tbl = {...}
    local str = ""

    for k, v in next, tbl do
        if isentity(v) then
            if v:IsPlayer() then
                str = str .. v:Name(true) .. "[" .. v:SteamID() .. "] "
            else
                if v:IsWorld() then
                    str = str .. "[World] "
                elseif not IsValid(v) then
                    str = str .. "[NULL ENTITY " .. v:EntIndex() .. "] "
                else
                    str = str .. "[" .. v:EntIndex() .. "][" .. v:GetClass() .. "] "
                end
            end
        else
            str = str .. tostring(v) .. " "
        end
    end

    return str .. "\n"
end

local color_gray, color_wblue, color_blue, color_yellow, color_red =
    Color(175, 175, 175), Color(150, 150, 255), Color(100, 100, 255), Color(255, 150, 100), Color(255, 100, 100)

function proptomia.LogInfo(...)
    local str = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_blue, " INFO  ", color_gray, "] ", color_white, str)
    if signalLogger then signalLogger.Info("proptomia", s) end
end

function proptomia.LogWarn(...)
    local str = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_yellow, " WARN  ", color_gray, "] ", color_white, str)
    if signalLogger then signalLogger.Warn("proptomia", s) end
end

function proptomia.LogError(...)
    local str = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_red, " ERROR ", color_gray, "] ", color_white, str)
    debug.Trace()

    if signalLogger then signalLogger.Error("proptomia", s) end
end

function proptomia.LogDebug(...)
    local str = concat(...)

    if proptomia.debug then
        MsgC(color_wblue, "Proptomia ", color_gray, "[", color_wblue, " DEBUG ", color_gray, "] ", color_white, str)
    end
    if signalLogger then signalLogger.Debug("proptomia", s) end
end

proptomia.LogInfo("Loading files...")

--include "sh_utils.lua"

if SERVER then
    -- AddCSLuaFile "sh_utils.lua"
    AddCSLuaFile "sh_cppi.lua"
    AddCSLuaFile "cl_ownership.lua"

    include "sv_ownership.lua"
end

include "sh_cppi.lua"

if CLIENT then
    include "cl_ownership.lua"
end

proptomia.LogInfo("Finished loading!")
hook.Run("ProptomiaInitialized")

-- TO-DO
-- [] make ownership
-- [] make protection
-- [] buddies
-- [] visuals
-- -- [] panel with owner's username
-- -- [] buddies panel
-- [] protection relationship (i don't want to touch other ppl props wah)
-- [] variations of visual ownership