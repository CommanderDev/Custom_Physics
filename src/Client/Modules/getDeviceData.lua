local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local GUI = Instance.new("ScreenGui",game.Players.LocalPlayer.PlayerGui)

local function getDeviceType(): ()

	if GuiService:IsTenFootInterface() then
		return "Console"
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return "Mobile"
	else
		return "Desktop"
	end
end

local function getTimestamp(): ()
	return os.time()
end

local function getTimezone(): ()
	return os.date("%z", os.time())
end

local function getLanguage(): ()
	return LocalizationService.RobloxLocaleId
end

local function getScreenSize(): ()
	return {
		width = GUI.AbsoluteSize.X,
		height = GUI.AbsoluteSize.Y
	}
end

return function (): {}
	return {
		device_type = getDeviceType(),
		timestamp = getTimestamp(),
		timezone = getTimezone(),
		language = getLanguage(),
		screen = getScreenSize()
	}
end
