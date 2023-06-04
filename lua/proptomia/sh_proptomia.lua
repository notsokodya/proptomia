proptomia = proptomia or {
    props = {},
    buddies = {},
    convars = {_raw = {}}
}

local function concat(...)
    local tbl = {...}
    local str = ""

    for k, v in next, tbl do
        str = str .. tostring(v) .. " "
    end

    return str .. "\n"
end
local color_gray, color_wblue, color_blue, color_yellow, color_red =
    Color(175, 175, 175), Color(150, 150, 255), Color(100, 100, 255), Color(255, 255, 100), Color(255, 100, 100)
function proptomia.LogInfo(...)
    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_blue, " INFO ", color_gray, "]\t", color_white, concat(...))
end
function proptomia.LogWarn(...)
    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_yellow, " WARN ", color_gray, "]\t", color_white, concat(...))
end
function proptomia.LogError(...)
    MsgC(color_wblue, "Proptomia ", color_gray, "[", color_red, " ERROR ", color_gray, "]\t", color_white, concat(...))
    debug.Trace()
end

proptomia.convars._raw.enabled = CreateConVar("proptomia_enable", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable proptomia protection", "0", "1")
cvars.AddChangeCallback("proptomia_enable", function(_, _, value)
    proptomia.convar.enable = tonumber(value) ~= 0
end)

proptomia.LogInfo("Loading files...")


if SERVER then
    AddCSLuaFile "sh_buddies.lua"
    AddCSLuaFile "sh_protection.lua"
    AddCSLuaFile "sh_cppi.lua"
    AddCSLuaFile "cl_owner.lua"
    AddCSLuaFile "cl_visuals.lua"

    include "sv_owner.lua"
    include "sv_cleanup.lua"
end

include "sh_buddies.lua"
include "sh_protection.lua"
include "sh_cppi.lua"

if CLIENT then
    include "cl_owner.lua"
    include "cl_visuals.lua"
end


proptomia.LogInfo("Proptomia Initialized")
hook.Run("ProptomiaInitialized")