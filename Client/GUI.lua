if not Config.GUI.Enabled then return end

local DrawSprite, IsDisabledControlJustPressed, DisableControlAction = DrawSprite, IsDisabledControlJustPressed, DisableControlAction

local Sounds = { -- In case you wanna change out the sounds they are located here.
	["Close"] = {"TOGGLE_ON", "HUD_FRONTEND_DEFAULT_SOUNDSET"},
	["Open"] = {"NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET"},
	["Select"] = {"SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET"}
}
function SoundPlay(which)
	if not Config.GUI.Sound then return end
	local Sound = Sounds[which]
	PlaySoundFrontend(-1, Sound[1], Sound[2])
end

local DisabledControls = {1, 2, 18, 68, 69, 70, 91, 92, 24, 25, 14, 15, 16, 17}
local function DisableControl()
	for i = 1, #DisabledControls do DisableControlAction(1, DisabledControls[i], true) end
	DisablePlayerFiring(PlayerId(), true)	-- We wouldnt want the player punching by accident.
	ShowCursorThisFrame()
end

local function GetCursor() -- This might break for people with weird resolutions? Im really not sure.
	local sx, sy = GetActiveScreenResolution()
	local cx, cy = GetNuiCursorPosition()
	return (cx / sx) + 0.008, (cy / sy) + 0.027
end

local function Check(ped) -- We check if the player should be able to open the menu.
	if IsPedInAnyVehicle(ped) and not Config.GUI.AllowInCars then
		return false
	elseif IsPedSwimmingUnderWater(ped) then
		return false
	elseif IsPedRagdoll(ped) and not Config.GUI.AllowWhenRagdolled then
		return false
	elseif IsHudComponentActive(19) then -- If the weapon wheel is open, we close!
		return false
	end
	return true
end

local DefaultButton = {x = 0.0254, y = 0.0445}
local DefaultCircle = {x = 0.0345 / 1.2, y = 0.06 / 1.2}

-- Size tables are shared and read only, so a button press doesnt allocate new ones.
local WheelNormal  = {Sprite = DefaultButton}
local WheelPressed = {Sprite = {x = DefaultButton.x/1.1, y = DefaultButton.y/1.1}}
local ExtraNormal  = {Circle = DefaultCircle, Sprite = {x = DefaultButton.x/1.35, y = DefaultButton.y/1.35}}
local ExtraPressed = {Circle = DefaultCircle, Sprite = {x = DefaultButton.x/1.3/1.1, y = DefaultButton.y/1.3/1.1}}

local Buttons, ButtonList = {}, {}
local ExtraButtons, ExtraList = {}, {}
local InfoButtonRot = 0.0
local HitRadius2 = 0.025 * 0.025 -- Squared distances, no sqrt needed.
local InfoRadius2 = 0.015 * 0.015
local HoverColour, HoverWrap = {210, 210, 210}, {x = 0.1, y = 0.2}
local InfoLabel, WaitLabel
local Ready = false
MenuOpened = false

local function GenerateTheButtons() -- We generate the buttons here to save on a little bit of performance.
	local x, y, rx, ry = Config.GUI.Position.x, Config.GUI.Position.y, 0.1, 0.175
	for k, v in pairs(Config.Commands) do
		local i = v.Button
		local Angle = i * math.pi / 7
		local b = {
			Command = k,
			Desc = v.Desc or "",
			Size = WheelNormal,
			Sprite = v.Sprite,
			Key = FirstUpper(v.Sprite), -- Precomputed, this used to be a gsub per button per frame.
			Wheel = tostring(i),
			Text = v.Name,
			x = x + rx * math.cos(Angle), y = y + ry * math.sin(Angle),
			Rotation = 0.0
		}
		Buttons[i] = b
		ButtonList[#ButtonList + 1] = b
	end
	if Config.ExtrasEnabled then -- The extra buttons arent tied to the wheel, and can be moved with simple offsets.
		for k, v in pairs(Config.ExtraCommands) do
			if v.Enabled == nil or v.Enabled then
				local b = {
					Command = k,
					Desc = v.Desc or "",
					OffsetX = v.OffsetX, OffsetY = v.OffsetY,
					Size = ExtraNormal,
					Sprite = v.Sprite,
					Key = FirstUpper(v.Sprite),
					SpriteFunc = v.SpriteFunc,
					Text = v.Name,
					Rotate = v.Rotate,
					Rotation = 0.0
				}
				ExtraButtons[k] = b
				ExtraList[#ExtraList + 1] = b
			end
		end
	end
	InfoLabel, WaitLabel = Lang("Info"), Lang("PleaseWait")
end

local function PushedButton(button, extra, rotate, info) -- https://www.youtube.com/watch?v=v57i1Ze0jB8
	CreateThread(function()
		SoundPlay("Select")
		local Button
		if not info then Button = extra and ExtraButtons[button] or Buttons[button] end
		if rotate then
			for i = 1, 18 do
				if info then InfoButtonRot = -i*20.0 else Button.Rotation = -i*20.0 end
				Wait(1)
			end
			return
		end
		if not extra then
			Button.Size = WheelPressed Wait(100) Button.Size = WheelNormal
		else
			Button.Size = ExtraPressed Wait(100) Button.Size = ExtraNormal
		end
	end)
end

--[[
		This is the function that draws the GUI, im using native DrawSprites and Texts.
		Its not the most efficient thing ms wise, but it does the job pretty well, and i dont have to bother with NUI HTML stuff.
		It now only runs while the menu is actually open (see MenuLoop), and per frame it:
		 - reads the cursor once, instead of once per button (x3)
		 - checks the click control once, instead of once per button
		 - allocates no tables
		 - calls each SpriteFunc once instead of three times
]]--

local function DrawGUI()
	DisableControl() -- Disable control while GUI is active.
	local x, y = Config.GUI.Position.x, Config.GUI.Position.y
	local cx, cy = GetCursor()
	local Clicked = IsDisabledControlJustPressed(1, 24)
	local DebugClick = Config.Debug and IsDisabledControlJustPressed(1, 25)
	local OnCooldown = IsOnCooldown()
	local HoverText, HoverDesc

	for i = 1, #ButtonList do
		local b = ButtonList[i]
		local Alpha
		if LastEquipped[b.Key] then
			Alpha = 180
			DrawSprite("dp_wheel", b.Wheel, x, y, 0.4285, 0.7714, 0.0, 0, 100, 210, 220)
		else
			Alpha = 255
			DrawSprite("dp_wheel", b.Wheel, x, y, 0.4285, 0.7714, 0.0, 0, 0, 0, 255)
		end
		local Size = b.Size.Sprite
		DrawSprite("dp_clothing", b.Sprite, b.x, b.y, Size.x/0.68, Size.y/0.68, b.Rotation, 255, 255, 255, Alpha)
		local dx, dy = b.x + 0.005 - cx, b.y + 0.025 - cy
		if dx*dx + dy*dy < HitRadius2 then
			HoverText, HoverDesc = b.Text, b.Desc
			if Clicked and not OnCooldown then -- If the button is clicked we execute the command, just like if the player typed it in chat.
				if b.Sprite == "gloves" and LastEquipped["Shirt"] then
					Notify(Lang("NoShirtOn"))
				else
					PushedButton(i) ExecuteCommand(b.Command)
				end
			elseif DebugClick then
				DevTestVariants(FirstUpper(b.Sprite))
			end
		end
	end

	for i = 1, #ExtraList do
		local b = ExtraList[i]
		local Sprite = b.Sprite
		if b.SpriteFunc then Sprite = b.SpriteFunc() end
		if Sprite then
			local Alpha, r, g, bl
			if LastEquipped[b.Key] then Alpha, r, g, bl = 180, 0, 100, 210 else Alpha, r, g, bl = 255, 0, 0, 0 end
			local bx, by = x + b.OffsetX, y + b.OffsetY
			local Size = b.Size
			DrawSprite("dp_clothing", "circle", bx, by, Size.Circle.x/0.80, Size.Circle.y/0.80, 0.0, r, g, bl, Alpha)
			DrawSprite("dp_clothing", Sprite, bx, by, Size.Sprite.x/0.68, Size.Sprite.y/0.68, b.Rotation, 255, 255, 255, Alpha)
			local dx, dy = bx + 0.005 - cx, by + 0.025 - cy
			if dx*dx + dy*dy < HitRadius2 then
				HoverText, HoverDesc = b.Text, b.Desc
				if Clicked and not OnCooldown then
					PushedButton(b.Command, true, b.Rotate) ExecuteCommand(b.Command)
				elseif DebugClick then
					DevTestVariants(FirstUpper(b.Sprite))
				end
			end
		end
	end

	if HoverText then -- Name and description of whatever we are hovering.
		Text(x, y - 0.10, 0.3, HoverText, false, false, true)
		Text(x, y - 0.08, 0.22, HoverDesc, HoverColour, false, true, HoverWrap)
	end
	if OnCooldown then Text(x, y + 0.05, 0.28, WaitLabel, false, false, true) end -- Cooldown indicator.

	-- The info button in the middle.
	DrawSprite("dp_clothing", "circle", x, y, 0.0345/0.80, 0.06/0.80, 0.0, 0, 0, 0, 255)
	DrawSprite("dp_clothing", "info", x, y, 0.0234/0.68, 0.0425/0.68, InfoButtonRot, 255, 255, 255, 255)
	local dx, dy = x + 0.005 - cx, y + 0.025 - cy
	local d2 = dx*dx + dy*dy
	if d2 < InfoRadius2 then Text(x, y - 0.09, 0.3, InfoLabel, false, false, true) end
	if Clicked and d2 < HitRadius2 then
		PushedButton(nil, true, true, true)
		Notify(Lang("Information"))
		if Config.Debug then for k, v in pairs(LastEquipped) do log(k.." : "..json.encode(v)) end end
	end
end

-- The draw loop only exists while the menu is open. Idle cost of the whole GUI is now zero.
local LoopRunning = false
local function StartLoop()
	if LoopRunning then return end
	LoopRunning = true
	CreateThread(function()
		while MenuOpened do
			Wait(0)
			if not Check(PlayerPedId()) then MenuOpened = false SoundPlay("Close") break end
			DrawGUI()
		end
		LoopRunning = false
	end)
end

function SetMenu(state)
	state = state and true or false
	if state == MenuOpened then return end
	if state then
		if not Ready or not Check(PlayerPedId()) then return end
		MenuOpened = true
		SoundPlay("Open")
		SetCursorLocation(Config.GUI.Position.x, Config.GUI.Position.y)
		StartLoop()
	else
		MenuOpened = false
		SoundPlay("Close")
	end
end

local TextureDicts = {"dp_clothing", "dp_wheel"}
CreateThread(function()
	for _, v in ipairs(TextureDicts) do
		while not HasStreamedTextureDictLoaded(v) do RequestStreamedTextureDict(v, true) Wait(100) end
	end
	GenerateTheButtons()
	Ready = true
end)

-- Opening the menu. Keybinds registered through RegisterKeyMapping cost nothing while idle,
-- and players can rebind them in their GTA settings. Set Config.GUI.UseKeyMapping = false for the old polling behaviour.
local function KeyDown() if Config.GUI.Toggle then SetMenu(not MenuOpened) else SetMenu(true) end end
local function KeyUp() if not Config.GUI.Toggle then SetMenu(false) end end

if Config.GUI.UseKeyMapping ~= false then
	RegisterCommand("+dpclothingmenu", KeyDown, false)
	RegisterCommand("-dpclothingmenu", KeyUp, false)
	RegisterKeyMapping("+dpclothingmenu", "Clothing menu", "keyboard", Config.GUI.KeyName or "Y")
else
	CreateThread(function()
		local Key = Config.GUI.Key
		while true do
			Wait(0)
			if IsControlJustPressed(1, Key) then KeyDown() elseif IsControlJustReleased(1, Key) then KeyUp() end
		end
	end)
end

if Config.Debug then
	CreateThread(function() while true do Wait(0) DrawDev() end end)
end
