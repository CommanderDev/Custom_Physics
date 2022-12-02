-- Ability
-- Author(s): Jesse Appleton
-- Date: 03/09/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

-- Modules
local CharacterData = require( Knit.SharedData.CharacterData )
local CollisionModule = require( script.Parent.Collision )

---------------------------------------------------------------------

local Ability = {}


-- Ability functions
function Ability.Jump( self: table ): boolean
	if self.Input.Cmd.ButtonPress.Jump then
		self.Flag.Grounded = false
		self:SetState(require( script.Parent.State.Jump ).new(self, true))
		self.Spd.X *= 0.9
		self.Spd.Y = self.Parameters.Jump_Speed
		return true
	end
	return false
end

return Ability
