-- GetDefaultAvatarForPlayer
-- Author(s): Jesse Appleton
-- Date: 03/10/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local t = require( Knit.Util.t )

-- Modules
local CharacterService = Knit.GetService( "CharacterService" )

-- Roblox Services

-- Variables
local PlayerAvatars: Folder = Knit.Assets:WaitForChild( "PlayerAvatars" )

---------------------------------------------------------------------

local tPlayer = t.tuple( t.Player )
return function( player: Player ): ( Model )
    assert( tPlayer(player) )

    return PlayerAvatars:FindFirstChild( player.Name ) or CharacterService:GetDefaultAvatarForPlayer( player )
end