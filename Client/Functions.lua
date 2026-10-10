Locale = {}
Keys = { -- Who doesnt love a big old table of keys.
    [","] = 82, ["-"] = 84, ["."] = 81, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161,
    ["8"] = 162, ["9"] = 163, ["="] = 83, ["["] = 39, ["]"] = 40, ["A"] = 34, ["B"] = 29, ["BACKSPACE"] = 177, ["C"] = 26, ["CAPS"] = 137,
    ["D"] = 9, ["DELETE"] = 178, ["UP"] = 172, ["DOWN"] = 173, ["E"] = 38, ["ENTER"] = 18, ["ESC"] = 322, ["F"] = 23, ["F1"] = 288, ["F10"] = 57, ["F2"] = 289,
    ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["G"] = 47, ["H"] = 74, ["HOME"] = 213, ["K"] = 311,
    ["L"] = 182, ["LEFT"] = 174, ["LEFTALT"] = 19, ["LEFTCTRL"] = 36, ["LEFTSHIFT"] = 21, ["M"] = 244, ["N"] = 249, ["N+"] = 96, ["N-"] = 97,
    ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118, ["NENTER"] = 201, ["P"] = 199, ["PAGEDOWN"] = 11,
    ["PAGEUP"] = 10, ["Q"] = 44, ["R"] = 45, ["RIGHT"] = 175, ["RIGHTCTRL"] = 70, ["S"] = 8, ["SPACE"] = 22, ["T"] = 245, ["TAB"] = 37,
    ["TOP"] = 27, ["U"] = 303, ["V"] = 0, ["W"] = 32, ["X"] = 73, ["Y"] = 246, ["Z"] = 20, ["~"] = 243,
}

function log(l) -- Just a simple logging thing, to easily log all kinds of stuff.
	if l == nil then print("nil") return end
	if not Config.Debug then return end
	if type(l) == "table" then print(json.encode(l)) elseif type(l) == "boolean" then print(l) else print(l.." | "..type(l)) end
end

function GetKey(str)
	return Keys[string.upper(str)] or false
end

-- Cooldown is just a timestamp now: no thread is spawned per toggle, and nothing polls.
local CooldownUntil = 0
function IncurCooldown(ms)
	CooldownUntil = GetGameTimer() + ms
end
function IsOnCooldown()
	return GetGameTimer() < CooldownUntil
end

function PairsKeys(t, f)
	local a = {}
	for n in pairs(t) do a[#a + 1] = n end
	table.sort(a, f)
	local i = 0
	return function()
		i = i + 1
		local key = a[i]
		if key == nil then return nil end
		return key, t[key]
	end
end

function Text(x, y, scale, text, colour, align, force, w)
	align = align or 0
	colour = colour or Config.GUI.TextColor
	SetTextFont(Config.GUI.TextFont)
	SetTextJustification(align)
	SetTextScale(scale, scale)
	SetTextColour(colour[1], colour[2], colour[3], 255)
	if Config.GUI.TextOutline then SetTextOutline() end
	if w then SetTextWrap(w.x, w.y) end
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
end

function FirstUpper(str)
	return (str:gsub("^%l", string.upper))
end

function Lang(what)
	local Dict = Locale[Config.Language] or Locale["en"] -- Unknown language in config? Fall back instead of erroring.
	return Dict[what] or Locale["en"][what] -- If we cant find a translation, use the english one.
end

function Notify(message) -- However you want your notifications to be shown, you can switch it up here.
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0, 1)
end

local MaleHash, FemaleHash = GetHashKey("mp_m_freemode_01"), GetHashKey("mp_f_freemode_01") -- Hashed once, not on every call.
function IsMpPed(ped)
	local CurrentModel = GetEntityModel(ped)
	if CurrentModel == MaleHash then return "Male" elseif CurrentModel == FemaleHash then return "Female" else return false end
end

-- Stubs so the events/dev tools dont error when the GUI is disabled. GUI.lua overrides these.
MenuOpened = false
function SoundPlay() end
function SetMenu() end

--[[
		Some events that might be useful for external use.
		You can trigger em with TriggerEvent("EventName").
]]--

--[[
		[dpc:EquipLast]
		This event will remove all saved clothes from the client.
		And put them back on the players model.
		You should use this in your own / other external scripts whenever the player :
		Enter a clothing store, enter a barber shop, and many other uses i maybe havent thought of.
		Otherwise they might for example "save" a hat, then go to a clothing store and change the hat, then when using /hat it puts on the hat they had before they paid for their new hat.
]]--
RegisterNetEvent('dpc:EquipLast', function()
	ResetClothing()
end)

--[[
		[dpc:ResetClothing]
		Same deal as above but instead of equipping the stuff, it just clears the lastequipped.
		Useful for when you change a players model.
]]--
RegisterNetEvent('dpc:ResetClothing', function()
	LastEquipped = {}
end)

--[[
		[dpc:ToggleMenu]
		Toggle the clothing menu off/on
]]--
RegisterNetEvent('dpc:ToggleMenu', function()
	SetMenu(not MenuOpened)
end)

--[[
		[dpc:Menu]
		Changes status of the clothing menu.
]]--
RegisterNetEvent('dpc:Menu', function(status)
	SetMenu(status)
end)
