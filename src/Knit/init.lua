export type Dictionary = {
	[string]: any
}

if game:GetService("RunService"):IsServer() then
	local KnitServer = require( script.KnitServer )

	-- Folder of environment specific modules (Server|Client > Modules)
	KnitServer.Modules = nil :: Folder
	-- Folder of shared modules (Shared > Modules)
	KnitServer.SharedModules = nil :: Folder
	-- Dictionary of custom Enums (Shared > Enums)
	KnitServer.Enums = nil :: Dictionary
	-- Dictionary of game data (Shared > Data)
	KnitServer.GameData = nil :: Dictionary

	return KnitServer
else
  local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer then
		KnitServer:Destroy()
	end

	local KnitClient = require( script.KnitClient )

	-- Folder of environment specific modules (Server|Client > Modules)
	KnitClient.Modules = nil :: Folder
	-- Folder of shared modules (Shared > Modules)
	KnitClient.SharedModules = nil :: Folder
	-- Dictionary of custom Enums (Shared > Enums)
	KnitClient.Enums = nil :: Dictionary
	-- Dictionary of game data (Shared > Data)
	KnitClient.GameData = nil :: Dictionary

	return KnitClient
end