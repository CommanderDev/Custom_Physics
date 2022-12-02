local startTime = os.clock()

local ReplicatedStorage = game:GetService( "ReplicatedStorage" )

local Knit = require( ReplicatedStorage:WaitForChild("Knit"))

Knit.LocalPlayer = game:GetService( "Players" ).LocalPlayer
Knit.PlayerGui = Knit.LocalPlayer:WaitForChild( "PlayerGui" )
Knit.MainUI = Knit.PlayerGui:WaitForChild("Main")

local Component = require( Knit.Util.Component )

-- EXPOSE ASSETS FOLDERS
Knit.Assets = ReplicatedStorage.Assets

-- EXPOSE CLIENT MODULES
Knit.Modules = script.Parent.Modules

-- EXPOSE SHARED DATA
Knit.Enums = require( ReplicatedStorage.Shared.Enums )
Knit.GameData = require( ReplicatedStorage.Shared.Data )

-- EXPOSE SHARED MODULES
Knit.SharedModules = ReplicatedStorage.Shared.Modules
Knit.SharedData = ReplicatedStorage.Shared.Data
Knit.Helpers = ReplicatedStorage.Shared.Modules.Helpers

-- ENVIRONMENT SWITCHES
Knit.IsStudio = game:GetService( "RunService" ):IsStudio()
Knit.IsClient = game:GetService( "RunService" ):IsClient()
Knit.IsServer = game:GetService( "RunService" ):IsServer()

-- DISABLE HURT FLASH IN COREGUI
local StarterGui = game:GetService("StarterGui")
pcall(function()
    StarterGui:SetCoreGuiEnabled( Enum.CoreGuiType.Health, false )
    StarterGui:SetCoreGuiEnabled( Enum.CoreGuiType.Backpack, false )
end)

-- ADD CONTROLLERS
local Controllers = script.Parent.Controllers
Knit.AddControllers( Controllers )
Knit.AddControllers( Controllers.Character )
Knit.AddControllers( Controllers.Player )
Knit.AddControllers( Controllers.UI )
Knit.AddControllers( Controllers.World )
Knit.AddControllers( Controllers.Game )
-- START
Knit:Start():andThen(function()
    Component.Auto( script.Parent.Components )
    print( string.format("Client Successfully Compiled! [%s ms]", math.round((os.clock()-startTime)/1000)) )
end):catch(error )