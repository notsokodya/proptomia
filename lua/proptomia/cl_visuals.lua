local   surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_DrawText, player_GetCount, player_GetAll, vgui_Create, vgui_CreateFromTable, LocalPlayer =
        surface.SetFont, surface.SetTextColor, surface.SetTextPos, surface.GetTextSize, surface.DrawText, player.GetCount, player.GetAll, vgui.Create, vgui.CreateFromTable, LocalPlayer

----------------- HUD -----------------

proptomia.convars.displayOwner = CreateClientConVar("proptomia_display_owner", "1", true, false, "Toggle displaying entity's owner")

local color_green, color_red, color_bg = Color(100, 255, 100), Color(255, 100, 100), Color(15, 15, 18, 140)
local actions = {
    weapon_physgun = 1,
    gmod_tool = 2
}

hook.Add("HUDPaint", "proptomia_display_owner", function()
    if not proptomia.convars.displayOwner:GetBool() 
    or not proptomia.convars.protection:GetBool()
    then return end

    local me = LocalPlayer()
    local ent = me:GetEyeTrace().Entity

    if IsValid(ent) then
        local wep = me:GetActiveWeapon()
        local wep_class = IsValid(wep) and wep:GetClass() or ""
        local action = actions[wep_class]

        local owner = proptomia.GetOwner(ent)
        if IsValid(owner) then
            local w, h = ScrW(), ScrH()
            local text_color = proptomia.CanTouch(ent, me, action) and color_green or color_red
            local text = owner.Name

            surface_SetFont("ChatFont")
            local text_w, text_h = surface_GetTextSize(text)
            local x, y = w - 10 - text_w, h * .5 - text_h * .5

            surface.SetDrawColor(color_bg)
            surface.DrawRect(x - 2.5, y - 1, text_w + 5, text_h + 2)

            surface_SetTextColor(text_color)
            surface_SetTextPos(x, y)
            surface_DrawText(text)
        end
    end
end)

----------------- Notifications -----------------

proptomia.convars.notifications = CreateClientConVar("proptomia_notifications", "1", true, false, "Show notifications when someone adds / removes permission for you")

local notification_permission_change = "%s %s %s permissions"
local notification_removed = "%s revoked all permissions from you"
local permission_type = {"physgun", "toolgun", "properties"}
hook.Add("ProptomiaPermissionChange", "proptomia_notifications", function(action, steamid, phys, tool, prop)
    if not proptomia.convars.notifications:GetBool() then return end
    local ply = proptomia.GetPlayerBySteamID(steamid)
    local name = IsValid(ply) and ply:Name() or steamid

    if action then
        local what, which = nil, ""
        local new = {phys, tool, prop}
        local old = proptomia.buddies[steamid]

        if old == nil then
            what = "gave"
            for i = 1, 3 do
                if new[i] then
                    which = permission_type[i]
                    break
                end
            end
        else
            for i = 1, 3 do
                if new[i] == old[i] then continue end

                which = permission_type[i]
                if new[i] and not old[i] then
                    what = "gave"
                else
                    what = "took"
                end
                break
            end
        end

        if not what then return end

        notification.AddLegacy(notification_permission_change:format(name, what, which), NOTIFY_HINT, 5)
        surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
    else
        notification.AddLegacy(notification_removed:format(name), NOTIFY_ERROR, 5)
        surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
    end
end)

----------------- Permissions Panel -----------------

local icons_mark, icons_cross = "icon16/tick.png", "icon16/cross.png"
local PlayerPanel = {}
function PlayerPanel:Init()
    self.Name = "unknown"
    self.SteamID = ""
    self.Permissions = {false, false, false}
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 2)
    self:DockPadding(5, 5, 5, 5)
    self:SetTall(32)
    self:SetMouseInputEnabled(true)

    self.Avatar = vgui_Create("", self)
    self.Avatar:Dock(LEFT)
    self.Avatar:SetSize(32, 32)
end
function PlayerPanel:SaveChanges()
    
end

hook.Add("AddToolMenuCategories", "proptomia_menu_category", function()
    spawnmenu.AddToolCategory("Utilities", "Proptomia", "Proptomia")
end)
hook.Add("PopulateToolMenu", "proptomia_menu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Proptomia", "General", "General", "", "", function(panel)
        panel:Clear()
        panel:SetName("Proptomia > General")
        
        local txt = panel:Help("[ General settings ]")
        txt:Dock(TOP)
        txt:SetContentAlignment(TEXT_ALIGN_CENTER)
        txt:SetFont("DermaDefaultBold")

        panel:CheckBox("Toggle displaying entity's owner", "proptomia_display_owner")
        txt = panel:ControlHelp("Display username of aimed entity's owner")
        txt:Dock(TOP)

        panel:CheckBox("Toggle notifications", "proptomia_notifications")
        txt = panel:ControlHelp("When someone change your permissions to touch their entity, you get notification about that")
        txt:Dock(TOP)
    end)
    spawnmenu.AddToolMenuOption("Utilities", "Proptomia", "Permissions", "Permissions", "", "", function(panel)
        panel:Clear()
        panel:SetName("Proptomia > Permissions")
        
        local txt = panel:Help("[ Permissions settings ]")
        txt:Dock(TOP)
        txt:SetContentAlignment(TEXT_ALIGN_CENTER)
        txt:SetFont("DermaDefaultBold")

        local list = vgui_Create("DScrollPanel")
        list:SetTall(256)
        list:Dock(FILL)
        list:DockMargin(2, 5, 2, 5)
        panel:AddItem(list)
        panel.ScrollPanel = list

        -- update
        if not IsValid(proptomia.PermissionsPanel) then proptomia.PermissionsPanel = panel end
    end)
end)
hook.Add("SpawnMenuOpen", "proptomia_update_buddies_list", function()
    if IsValid(proptomia.PermissionsPanel) and proptomia.PermissionsPanel:IsVisible()  then
        -- update
    end
end)