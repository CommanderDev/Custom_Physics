local startTime = os.clock()

local ServerStorage = game:GetService( "ServerStorage" )
local ReplicatedStorage = game:GetService( "ReplicatedStorage" )

local Knit = require( ReplicatedStorage.Knit )
local Component = require( Knit.Util.Component )

-- EXPOSE ASSET FOLDERS
Knit.Assets = ReplicatedStorage.Assets
Knit.ServerAssets = ServerStorage.Assets
Knit.ServerStorage = ServerStorage

-- EXPOSE SERVER MODULES
Knit.Modules = script.Parent.Modules
-- EXPOSE SHARED DATA
Knit.Enums = require( ReplicatedStorage.Shared.Enums )
Knit.GameData = require( ReplicatedStorage.Shared.Data )

-- EXPOSE SHARED MODULES
Knit.SharedModules = ReplicatedStorage.Shared.Modules
Knit.SharedData = ReplicatedStorage.Shared.Data
Knit.SharedComponents = ReplicatedStorage.Shared.Components
Knit.Helpers = ReplicatedStorage.Shared.Modules.Helpers
-- ENVIRONMENT SWITCHES
Knit.IsStudio = game:GetService( "RunService" ):IsStudio()
Knit.IsClient = game:GetService( "RunService" ):IsClient()
Knit.IsServer = game:GetService( "RunService" ):IsServer()

-- ADD SERVICES
local Services = script.Parent.Services
Knit.AddServices( Services )
Knit.AddServices( Services.Monetization )
Knit.AddServices( Services.Player )
Knit.AddServices( Services.World )
Knit.AddServices( Services.Game )

Knit:Start():andThen(function()
    Component.Auto( script.Parent.Components )

    print( string.format("Server Successfully Compiled! [%s ms]", math.round((os.clock()-startTime)*1000)) )
end):catch(error )