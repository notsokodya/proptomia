local   surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_DrawText, player_GetCount, player_GetAll, vgui_Create, vgui_CreateFromTable, LocalPlayer =
        surface.SetFont, surface.SetTextColor, surface.SetTextPos, surface.GetTextSize, surface.DrawText, player.GetCount, player.GetAll, vgui.Create, vgui.CreateFromTable, LocalPlayer
proptomia.convars.displayOwner = CreateClientConVar("proptomia_hud", "1", true, false, "Displays owner of currently aimed entity")

local color_green, color_red, color_bg = Color(100, 255, 100), Color(255, 100, 100), Color(15, 15, 18, 140)
hook.Add("HUDPaint", "proptomia_display_owner", function()
    if not proptomia.convars.displayOwner:GetBool() then return end

    local me = LocalPlayer()
    local ent = me:GetEyeTrace().Entity
    if IsValid(ent) then
        local owner = ent:CPPIGetOwner()
        if IsValid(owner) then
            local w, h = ScrW(), ScrH()
            local text_color = proptomia.CanTouch(ent, me) and color_green or color_red
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
function PlayerPanel:Init()
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, 2)
    self:SetTall(16)

    self.Avatar = vgui_Create("AvatarImage", self)
    self.Avatar:Dock(LEFT)
    self.Avatar:SetSize(16, 16)
    self.Avatar:DockMargin(0, 0, 5, 0)

    self.PName = vgui_Create("DLabel", self)
    self.PName:SetTextColor(Color(0, 0, 0, 255))
    self.PName:Dock(LEFT)
    self.PName:DockMargin(0, 0, 5, 0)
    self.PName:SetText("Unknown")

    self.PSteamID = vgui_Create("DLabel", self)
    self.PSteamID:SetTextColor(Color(0, 0, 0, 255))
    self.PSteamID:Dock(FILL)
    self.PSteamID:DockMargin(0, 0, 5, 0)
    self.PSteamID:SetText("Unknown")

    self.SetBuddy = vgui_Create("DCheckBox", self)
    self.SetBuddy:Dock(RIGHT)
    self.SetBuddy.OnChange = function(self, val)
        local parent = self:GetParent()
        parent.IsBuddy = val
        if val then
            proptomia.AddBuddy(parent.SteamID, parent.Name)
        else
            proptomia.RemoveBuddy(parent.SteamID)
        end
    end
end
function PlayerPanel:SetPlayer(ply, name, steamid)
    self.Player = ply
    self.SteamID = ply and ply:SteamID() or steamid
    self.Name = ply and ply:Name() or name or steamid
    self.IsBuddy = proptomia.buddiesClient[self.SteamID] ~= nil

    self.Avatar:SetSteamID(util.SteamIDTo64(self.SteamID), 16)
    self.PName:SetText(self.Name)
    self.PSteamID:SetText(self.SteamID)
    self.SetBuddy:SetValue(self.IsBuddy)
end
function PlayerPanel:SetPanelReference(panel)
    self.ParentPanel = panel
end
local PlayerPanel = vgui.RegisterTable(PlayerPanel, "EditablePanel")

local function updateBuddiesList(panel, force)
    if not IsValid(panel) then return end
    local current = panel.PlayersScroll

    current:GetCanvas():Clear()

    if player_GetCount() - 1 <= 0 then
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
    if IsValid(proptomia.BuddiesPanel) then
        updateBuddiesList(proptomia.BuddiesPanel)
    end
end)