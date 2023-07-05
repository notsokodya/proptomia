local   surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_DrawText, player_GetCount, player_GetAll, vgui_Create, vgui_CreateFromTable, LocalPlayer =
        surface.SetFont, surface.SetTextColor, surface.SetTextPos, surface.GetTextSize, surface.DrawText, player.GetCount, player.GetAll, vgui.Create, vgui.CreateFromTable, LocalPlayer
proptomia.convars.displayOwner = CreateClientConVar("proptomia_display_owner", "1", true, false, "Toggle displaying aimed entity owner name")

local color_green, color_red, color_bg = Color(100, 255, 100), Color(255, 100, 100), Color(15, 15, 18, 140)
local actions = {
    weapon_physgun = 1,
    gmod_tool = 2
}
hook.Add("HUDPaint", "proptomia_display_owner", function()
    if not proptomia.convars.displayOwner:GetBool() then return end

    local me = LocalPlayer()
    local ent = me:GetEyeTrace().Entity
    if IsValid(ent) then
        local wep = me:GetActiveWeapon()
        local wep_class = IsValid(wep) and wep:GetClass() or ""
        local action = actions[wep_class]

        local owner = ent:CPPIGetOwner()
        if IsValid(owner) then
            local w, h = ScrW(), ScrH()
            local text_color = proptomia.CanTouch(ent, me, action) and color_green or color_red
            local text = owner:Name()

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





local PlayerPanel = {}
local icon_access, icon_noaccess = "icon16/tick.png", "icon16/cross.png"
function PlayerPanel:Init()
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 2)
    self:DockPadding(5, 5, 5, 5)
    self:SetTall(25)
    self:SetMouseInputEnabled(true)

    self.Avatar = vgui_Create("AvatarImage", self)
    self.Avatar:Dock(LEFT)
    self.Avatar:SetSize(16, 16)
    self.Avatar:DockMargin(0, 0, 5, 0)
    self.Avatar.OnMouseReleased = function(self, code) self:GetParent():OnMouseReleased(code) end

    self.PName = vgui_Create("DLabel", self)
    self.PName:SetTextColor(Color(0, 0, 0, 255))
    self.PName:Dock(LEFT)
    self.PName:DockMargin(0, 0, 5, 0)
    self.PName:SetText("Unknown")

    self.BuddyProperties = vgui_Create("DImage", self)
    self.BuddyProperties:SetMouseInputEnabled(true)
    self.BuddyProperties:SetImage("icon16/brick.png")
    self.BuddyProperties:SetTooltip("Using properties menu")
    self.BuddyProperties:SetTooltipDelay(0.2)
    self.BuddyProperties:Dock(RIGHT)
    self.BuddyProperties:SetSize(16, 16)
    self.BuddyProperties:DockMargin(1, 0, 5, 0)
    self.BuddyProperties.OnMouseReleased = function(self, code) self:GetParent():OnMouseReleased(code) end

    self.BuddyToolgun = vgui_Create("DImage", self)
    self.BuddyToolgun:SetMouseInputEnabled(true)
    self.BuddyToolgun:SetImage("icon16/brick.png")
    self.BuddyToolgun:SetTooltip("Toolgun use")
    self.BuddyToolgun:SetTooltipDelay(0.2)
    self.BuddyToolgun:Dock(RIGHT)
    self.BuddyToolgun:SetSize(16, 16)
    self.BuddyToolgun:DockMargin(1, 0, 1, 0)
    self.BuddyToolgun.OnMouseReleased = function(self, code) self:GetParent():OnMouseReleased(code) end

    self.BuddyPhysgun = vgui_Create("DImage", self)
    self.BuddyPhysgun:SetMouseInputEnabled(true)
    self.BuddyPhysgun:SetImage("icon16/brick.png")
    self.BuddyPhysgun:SetTooltip("Physgun touching")
    self.BuddyPhysgun:SetTooltipDelay(0.2)
    self.BuddyPhysgun:Dock(RIGHT)
    self.BuddyPhysgun:SetSize(16, 16)
    self.BuddyPhysgun:DockMargin(0, 0, 1, 0)
    self.BuddyPhysgun.OnMouseReleased = function(self, code) self:GetParent():OnMouseReleased(code) end
end
function PlayerPanel:Paint(w, h)
    if self:IsHovered() or self:IsChildHovered() then
        self:GetSkin().tex.MenuBG_Hover(0, 0, w, h)
    end
end
function PlayerPanel:OnMouseReleased(code)
    if code ~= MOUSE_LEFT and code ~= MOUSE_RIGHT then return end
    local access = self.BuddyAccess
    local panel = DermaMenu()
    local base = self

    local physButton = panel:AddOption("Physgun")
    physButton.BuddyChecked = access.phys
    physButton:SetIcon(access.phys and icon_access or icon_noaccess)
    function physButton:OnMouseReleased(code)
        DButton.OnMouseReleased(self, code)
        if self.m_MenuClicking and code == MOUSE_LEFT then self.m_MenuClicking = false end
    end
    function physButton:DoClick()
        self.BuddyChecked = not self.BuddyChecked
        access.phys = self.BuddyChecked
        physButton:SetIcon(access.phys and icon_access or icon_noaccess)
        base:UpdateAccess()
    end

    local toolButton = panel:AddOption("Toolgun")
    toolButton.BuddyChecked = access.tool
    toolButton:SetIcon(access.tool and icon_access or icon_noaccess)
    function toolButton:OnMouseReleased(code)
        DButton.OnMouseReleased(self, code)
        if self.m_MenuClicking and code == MOUSE_LEFT then self.m_MenuClicking = false end
    end
    function toolButton:DoClick()
        self.BuddyChecked = not self.BuddyChecked
        access.tool = self.BuddyChecked
        toolButton:SetIcon(access.tool and icon_access or icon_noaccess)
        base:UpdateAccess()
    end

    local propButton = panel:AddOption("Properties")
    propButton.BuddyChecked = access.prop
    propButton:SetIcon(access.prop and icon_access or icon_noaccess)
    function propButton:OnMouseReleased(code)
        DButton.OnMouseReleased(self, code)
        if self.m_MenuClicking and code == MOUSE_LEFT then self.m_MenuClicking = false end
    end
    function propButton:DoClick()
        self.BuddyChecked = not self.BuddyChecked
        access.prop = self.BuddyChecked
        propButton:SetIcon(access.prop and icon_access or icon_noaccess)
        base:UpdateAccess()
    end

    panel:Open()
end
function PlayerPanel:UpdateAccess()
    if self.BuddyAccess then
        self.BuddyPhysgun:SetImage(self.BuddyAccess.phys and icon_access or icon_noaccess)
        self.BuddyToolgun:SetImage(self.BuddyAccess.tool and icon_access or icon_noaccess)
        self.BuddyProperties:SetImage(self.BuddyAccess.prop and icon_access or icon_noaccess)
        proptomia.AddBuddy(self.SteamID, self.Name, self.BuddyAccess.phys, self.BuddyAccess.tool, self.BuddyAccess.prop)
    end
end
function PlayerPanel:SetPlayer(ply, name, steamid)
    name = ply and ply:Name() or name or steamid
    steamid = ply and ply:SteamID() or steamid

    local buddyAccess = proptomia.buddiesClient[steamid]

    self.Player = ply
    self.SteamID = steamid
    self.Name = name
    self.BuddyAccess = buddyAccess and {phys = buddyAccess.phys, tool = buddyAccess.tool, prop = buddyAccess.prop} or {phys = false, tool = false, prop = false}

    self.Avatar:SetSteamID(util.SteamIDTo64(self.SteamID), 16)
    self.PName:SetText(self.Name)
    self.BuddyPhysgun:SetImage(self.BuddyAccess.phys and icon_access or icon_noaccess)
    self.BuddyToolgun:SetImage(self.BuddyAccess.tool and icon_access or icon_noaccess)
    self.BuddyProperties:SetImage(self.BuddyAccess.prop and icon_access or icon_noaccess)
end
function PlayerPanel:SetPanelReference(panel)
    self.ParentPanel = panel
end
local PlayerPanel = vgui.RegisterTable(PlayerPanel, "EditablePanel")

local function updateBuddiesList(panel, force)
    if not IsValid(panel) then return end
    local current = panel.PlayersScroll

    current:GetCanvas():Clear()

    if player_GetCount() <= 1 then
        local text = vgui_Create("DLabel")
        text:Dock(TOP)
        text:SetText("Currently no players on server :(")
        text:SetFont("DermaDefaultBold")
        current:AddItem(text)
    else
        local lp = LocalPlayer()
        for k, v in next, player_GetAll() do
            if v == lp then continue end
            local pnl = vgui_CreateFromTable(PlayerPanel)
            pnl:SetPlayer(v)
            pnl:SetPanelReference(panel)
            current:AddItem(pnl)
        end
    end
    current:Rebuild()
end

hook.Add("AddToolMenuCategories", "proptomia_menu_category", function()
    spawnmenu.AddToolCategory("Utilities", "Proptomia", "Proptomia")
end)
hook.Add("PopulateToolMenu", "proptomia_menu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Proptomia", "Buddies", "Buddies", "", "", function(panel)
        panel:Clear()
        panel:SetName("Proptomia > Buddies")
        
        local txt = panel:Help("[ Buddies Menu ]")
        txt:Dock(TOP)
        txt:SetContentAlignment(TEXT_ALIGN_CENTER)
        txt:SetFont("DermaDefaultBold")

        local txt = panel:Help("Here you can allow other players touch your props")

        local list = vgui_Create("DScrollPanel")
        list:SetTall(256)
        list:Dock(FILL)
        list:DockMargin(2, 5, 2, 5)
        panel:AddItem(list)
        panel.PlayersScroll = list

        updateBuddiesList(panel)
        if not IsValid(proptomia.BuddiesPanel) then proptomia.BuddiesPanel = panel end
    end)
end)
hook.Add("SpawnMenuOpen", "proptomia_update_buddies_list", function()
    if IsValid(proptomia.BuddiesPanel) and proptomia.BuddiesPanel:IsVisible()  then
        updateBuddiesList(proptomia.BuddiesPanel)
    end
end)