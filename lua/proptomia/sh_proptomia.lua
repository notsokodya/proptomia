proptomia = proptomia or {
    props = {},
    buddies = {},
    convars = {},
    debug = false -- for debug logs and etc
}

local function concat(...)
    local tbl = {...}
    local str = ""

    for k, v in next, tbl do
        if isentity(v) then
            if v:IsPlayer() then
                str = str .. v:Name(true) .. "[" .. v:SteamID() .. "] "
            else
                str = str .. "[" .. v:EntIndex() .. "]" .. "[" .. v:GetClass() .. "]"
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
    local s = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_blue, " INFO  ", color_gray, "]\t", color_white, s)
    if signalLogger then signalLogger.Info("proptomia", s) end -- support for my logger :p
end
function proptomia.LogWarn(...)
    local s = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_yellow, " WARN  ", color_gray, "]\t", color_white, s)
    if signalLogger then signalLogger.Warn("proptomia", s) end
end
function proptomia.LogError(...)
    local s = concat(...)

    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_red, " ERROR ", color_gray, "]\t", color_white, s)
    debug.Trace()

    if signalLogger then signalLogger.Error("proptomia", s) end
end
function proptomia.LogDebug(...)
    local s = concat(...)

    if proptomia.debug then
        MsgC(color_wblue, "Proptomia ", color_gray, "[", color_wblue, " DEBUG ", color_gray, "]\t", color_white, s)
    end
    if signalLogger then signalLogger.Debug("proptomia", s) end
end

proptomia.LogInfo("Loading files...")

include "sh_utils.lua"

if SERVER then
    AddCSLuaFile "sh_utils.lua"
    AddCSLuaFile "sh_protection.lua"
    AddCSLuaFile "sh_cppi.lua"
    AddCSLuaFile "cl_buddies.lua"
    AddCSLuaFile "cl_owner.lua"
    AddCSLuaFile "cl_visuals.lua"

    include "sv_owner.lua"
    include "sv_cleanup.lua"
    include "sv_buddies.lua"
end

include "sh_protection.lua"
include "sh_cppi.lua"

if CLIENT then
    include "cl_owner.lua"
    include "cl_buddies.lua"
    include "cl_visuals.lua"
end


proptomia.LogInfo("Proptomia Initialized")
hook.Run("ProptomiaInitialized")