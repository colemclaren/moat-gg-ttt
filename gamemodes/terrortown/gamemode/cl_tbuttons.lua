--- Display of and interaction with ttt_traitor_button
local surface = surface
local pairs = pairs
local math = math
local abs = math.abs
TBHUD = TBHUD or {}
TBHUD.storedbuttons = TBHUD.storedbuttons or {}
TBHUD.storedbuttons_count = TBHUD.storedbuttons_count or 0
TBHUD.buttons = {}
TBHUD.buttons_count = 0
TBHUD.focus_ent = nil
TBHUD.focus_stick = 0

function TBHUD:Clear()
    self.buttons = {}
    self.buttons_count = 0
    self.focus_ent = nil
    self.focus_stick = 0
end

function TBHUD:CacheEnts()
	self.buttons = {}
	self.buttons_count = 0

	if (not IsValid(LocalPlayer()) or not LocalPlayer():IsActiveTraitor()) then return end
	for i = 1, TBHUD.storedbuttons_count do
		local ent = Entity(TBHUD.storedbuttons[i])
		if (not IsValid(ent)) then continue end

		self.buttons_count = self.buttons_count + 1
		self.buttons[self.buttons_count] = ent
	end
end

function TBHUD:PlayerIsFocused()
    return IsValid(LocalPlayer()) and LocalPlayer():IsActiveTraitor() and IsValid(self.focus_ent)
end

function TBHUD:UseFocused()
    if IsValid(self.focus_ent) and self.focus_stick >= CurTime() then
        RunConsoleCommand("ttt_use_tbutton", tostring(self.focus_ent:EntIndex()))
        self.focus_ent = nil

        return true
    else
        return false
    end
end

local confirm_sound = Sound("buttons/button24.wav")

function TBHUD.ReceiveUseConfirm()
    surface.PlaySound(confirm_sound)
    TBHUD:CacheEnts()
end

net.Receive("TTT_ConfirmUseTButton", TBHUD.ReceiveUseConfirm)


local tbut_normal = surface.GetTextureID("vgui/ttt/tbut_hand_line")
local tbut_focus = surface.GetTextureID("vgui/ttt/tbut_hand_filled")
local size = 32
local mid = size / 2
local focus_range = 25
local use_key = Key("+use", "USE")
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

function TBHUD:Draw(client)
    if (self.buttons_count == 0) then return end
    surface.SetTexture(tbut_normal)
    -- we're doing slowish distance computation here, so lots of probably
    -- ineffective micro-optimization
    local plypos = client:GetPos()
    local midscreen_x = ScrW() / 2
    local midscreen_y = ScrH() / 2
    local pos, scrpos, d
    local focus_ent = nil
    local focus_d, focus_scrpos_x, focus_scrpos_y = 0, midscreen_x, midscreen_y

    -- draw icon on HUD for every button within range
	for i = 1, self.buttons_count do
		local but = self.buttons[i]
        if (not IsValid(but) or not but.IsUsable) then continue end
        pos = but:GetPos()
        scrpos = pos:ToScreen()
        if (IsOffScreen(scrpos) or not but:IsUsable()) then continue end
        d = pos - plypos
        d = d:Dot(d) / (but:GetUsableRange() ^ 2)
        -- draw if this button is within range, with alpha based on distance
        if d > 1 then continue end
        surface.SetDrawColor(255, 255, 255, 200 * (1 - d))
        surface.DrawTexturedRect(scrpos.x - mid, scrpos.y - mid, size, size)
        if d < focus_d then continue end
        local x = abs(scrpos.x - midscreen_x)
        local y = abs(scrpos.y - midscreen_y)

        if (x < focus_range and y < focus_range and x < focus_scrpos_x and y < focus_scrpos_y and (self.focus_stick < CurTime() or but == self.focus_ent)) then
            focus_ent = but
        end
    end

    -- draw extra graphics and information for button when it's in-focus
    if (not IsValid(focus_ent)) then return end
    self.focus_ent = focus_ent
    self.focus_stick = CurTime() + 0.1
    scrpos = focus_ent:GetPos():ToScreen()
    -- redraw in-focus version of icon
    surface.SetTexture(tbut_focus)
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawTexturedRect(scrpos.x - mid, scrpos.y - mid, size, size)
    -- description
    surface.SetTextColor(255, 50, 50, 255)
    surface.SetFont("TabLarge")
    local x = scrpos.x + 16 + 10
    local y = scrpos.y - 16 - 3
    surface.SetTextPos(x, y)
    surface.DrawText(focus_ent:GetDescription())
    y = y + 12
    surface.SetTextPos(x, y)

    if focus_ent:GetDelay() < 0 then
        surface.DrawText(GetTranslation("tbut_single"))
    elseif focus_ent:GetDelay() == 0 then
        surface.DrawText(GetTranslation("tbut_reuse"))
    else
        surface.DrawText(GetPTranslation("tbut_retime", {
            num = focus_ent:GetDelay()
        }))
    end

    y = y + 12
    surface.SetTextPos(x, y)

    surface.DrawText(GetPTranslation("tbut_help", {
        key = use_key
    }))
end

function TBHUD.AddButton()
	local indx = net.ReadUInt(16)
	if (not indx) then return end
	TBHUD.storedbuttons_count = TBHUD.storedbuttons_count + 1
	TBHUD.storedbuttons[TBHUD.storedbuttons_count] = indx
end
net.Receive("TTT_TraitorButton", TBHUD.AddButton)
net.Receive("TTT_TraitorButtons", function()
	local n = net.ReadUInt(16)
	if (not n) then return end
	TBHUD.storedbuttons = {}
	TBHUD.storedbuttons_count = 0

	for i = 1, n do TBHUD.AddButton() end
end)