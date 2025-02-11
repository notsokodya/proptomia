local   surface_SetDrawColor, surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_SetMaterial, surface_DrawText, surface_DrawTexturedRect, surface_DrawRect, vgui_Create, vgui_CreateFromTable, LocalPlayer, IsValid, player_GetCount, player_GetAll, team_GetColor =
        surface.SetDrawColor, surface.SetFont, surface.SetTextColor, surface.SetTextPos, surface.GetTextSize, surface.SetMaterial, surface.DrawText, surface.DrawTexturedRect, surface.DrawRect, vgui.Create, vgui.CreateFromTable, LocalPlayer, IsValid, player.GetCount, player.GetAll, team.GetColor

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
        if owner and owner.SteamID ~= "W" then
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
local icons_mark_mat, icons_cross_mat = Material("icon16/tick.png"), Material("icon16/cross.png")
local PlayerPanel = {}
function PlayerPanel:Init()
    self.Name = ""
    self.SteamID = ""
    self.Permissions = {false, false, false}

    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 2)
    self:DockPadding(5, 5, 5, 5)
    self:SetTall(32)
    self:SetMouseInputEnabled(true)

    local onMouseReleased = function(self, code) self:GetParent():OnMouseReleased(code) end

    self.Avatar = vgui_Create("AvatarImage", self)
    self.Avatar:Dock(LEFT)
    self.Avatar:DockMargin(0, 0, 5, 0)
    self.Avatar:SetSize(22, 32)

    self.Username = vgui_Create("EditablePanel", self)
    self.Username:Dock(FILL)
    self.Username.Paint = function(s, w, h)
        if self.name_color then
            surface_SetTextColor(self.name_color)
        else
            surface_SetTextColor(130, 130, 140, 255)
        end
        surface_SetFont("ChatFont")

        local text_width, text_height = surface_GetTextSize(self.Name)
        surface_SetTextPos(0, h / 2 - text_height / 2)

        surface_DrawText(self.Name)
    end

    self.Properties = vgui_Create("EditablePanel", self)
    self.Properties:Dock(RIGHT)
    self.Properties:DockMargin(2, 0, 2, 0)
    self.Properties:SetSize(22, 32)
    self.Properties.Paint = function(s, w, h)
        surface_SetDrawColor(color_white)
        surface_SetMaterial(self.Permissions[3] and icons_mark_mat or icons_cross_mat)
        surface_DrawTexturedRect(w * .15, h * .15, w * .75, h * .75)
    end

    self.Toolgun = vgui_Create("EditablePanel", self)
    self.Toolgun:Dock(RIGHT)
    self.Toolgun:DockMargin(2, 0, 2, 0)
    self.Toolgun:SetSize(22, 32)
    self.Toolgun.Paint = function(s, w, h)
        surface_SetDrawColor(color_white)
        surface_SetMaterial(self.Permissions[2] and icons_mark_mat or icons_cross_mat)
        surface_DrawTexturedRect(w * .15, h * .15, w * .75, h * .75)
    end

    self.Physgun = vgui_Create("EditablePanel", self)
    self.Physgun:Dock(RIGHT)
    self.Physgun:DockMargin(2, 0, 2, 0)
    self.Physgun:SetSize(22, 32)
    self.Physgun.Paint = function(s, w, h)
        surface_SetDrawColor(color_white)
        surface_SetMaterial(self.Permissions[1] and icons_mark_mat or icons_cross_mat)
        surface_DrawTexturedRect(w * .15, h * .15, w * .75, h * .75)
    end

    self.Avatar.OnMouseReleased = onMouseReleased
    self.Username.OnMouseReleased = onMouseReleased
    self.Properties.OnMouseReleased = onMouseReleased
    self.Toolgun.OnMouseReleased = onMouseReleased
    self.Physgun.OnMouseReleased = onMouseReleased
end
function PlayerPanel:Paint(w, h)
    if self:IsHovered() or self:IsChildHovered() then
        self:GetSkin().tex.MenuBG_Hover(0, 0, w, h)
    end
end

function PlayerPanel:SaveChanges()
    if self.SteamID == "" then return end

    local phys, tool, prop = self.Permissions[1], self.Permissions[2], self.Permissions[3]
    proptomia.ChangeBuddyPermission(self.SteamID, self.Name, phys, tool, prop)
end
function PlayerPanel:SetPlayer(steamid, name, name_color)
    self.SteamID = steamid
    local permissions = proptomia.clientBuddies[steamid]

    if permissions then
        if not name and permissions[1] ~= steamid then
            self.Name = permissions[1]
        end

        self.Permissions[1] = permissions[2]
        self.Permissions[2] = permissions[3]
        self.Permissions[3] = permissions[4]
    end

    if self.Name == "" then
        self.Name = name or steamid
    end

    if name_color then
        self.NameColor = name_color
    end

    self.Avatar:SetSteamID(util.SteamIDTo64(steamid), 32)
end

function PlayerPanel:OnMouseReleased(code)
    if code ~= MOUSE_LEFT and code ~= MOUSE_RIGHT then return end

    local player_panel = self
    local panel = DermaMenu()
    local permissions = self.Permissions

    local onMouseReleased = function(self, code)
        DButton.OnMouseReleased(self, code)
        if self.m_MenuClicking and code == MOUSE_LEFT then self.m_MenuClicking = false end
    end

    local physgun = panel:AddOption("Physgun")
    physgun:SetIcon(permissions[1] and icons_mark or icons_cross)
    function physgun:DoClick()
        permissions[1] = not permissions[1]
        self:SetIcon(permissions[1] and icons_mark or icons_cross)
        player_panel:SaveChanges()
    end

    local toolgun = panel:AddOption("Toolgun")
    toolgun:SetIcon(permissions[2] and icons_mark or icons_cross)
    function toolgun:DoClick()
        permissions[2] = not permissions[2]
        self:SetIcon(permissions[2] and icons_mark or icons_cross)
        player_panel:SaveChanges()
    end

    local properties = panel:AddOption("Properties")
    properties:SetIcon(permissions[3] and icons_mark or icons_cross)
    function properties:DoClick()
        permissions[3] = not permissions[3]
        self:SetIcon(permissions[3] and icons_mark or icons_cross)
        player_panel:SaveChanges()
    end

    physgun.OnMouseReleased = onMouseReleased
    toolgun.OnMouseReleased = onMouseReleased
    properties.OnMouseReleased = onMouseReleased

    panel:Open()
end

local PlayerPanel = vgui.RegisterTable(PlayerPanel, "EditablePanel")


local function proptomia_updateLists()
    if not IsValid(proptomia.PermissionsPanel) then return end

    local panel = proptomia.PermissionsPanel

    if IsValid(panel.CurrentPlayers) then
        local currentPlayers = panel.CurrentPlayers
        currentPlayers:GetCanvas():Clear()

        if player_GetCount() <= 1 then
            local text = vgui_Create("DLabel")
            text:Dock(TOP)
            text:DockPadding(5, 5, 5, 5)
            text:DockMargin(5, 0, 0, 0)
            text:SetFont("ChatFont")
            text:SetText("No one online :<")
            text:SetTextColor(color_white)

            currentPlayers:AddItem(text)
        else
            local lp = LocalPlayer()

            for k, v in next, player_GetAll() do
                if v == lp then continue end

                local player_panel = vgui_CreateFromTable(PlayerPanel)
                player_panel:SetPlayer(v:SteamID(), v:Name(), team_GetColor(v:Team()))

                currentPlayers:AddItem(player_panel)
            end
        end

        currentPlayers:Rebuild()
    end
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
        list:GetCanvas().Paint = function(self, w, h)
            surface_SetDrawColor(0, 0, 0, 75)
            surface_DrawRect(0, 0, w, h)
        end

        panel:AddItem(list)
        panel.CurrentPlayers = list

        if not IsValid(proptomia.PermissionsPanel) then proptomia.PermissionsPanel = panel end

        proptomia_updateLists()
    end)
end)
hook.Add("SpawnMenuOpen", "proptomia_update_buddies_list", function()
    if IsValid(proptomia.PermissionsPanel) and proptomia.PermissionsPanel:IsVisible()  then
        proptomia_updateLists()
    end
end)