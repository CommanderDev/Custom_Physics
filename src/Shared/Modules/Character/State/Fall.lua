-- Fall
-- Author(s): Jesse Appleton
-- Date: 01/11/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

-- Modules
local MovementModule = require( script.Parent.Parent.Movement )
local CollisionModule = require( script.Parent.Parent.Collision )

---------------------------------------------------------------------


local Fall = {}
Fall.__index = Fall


-- Constructor and destructor
function Fall.new( character: table ): table
	local self = setmetatable( {}, Fall )

	-- Assign character
	self._character = character

	return self
end


function Fall:Destroy(): nil
	
end


-- State functions
function Fall:Start(): table
	return {
		Flag = {
			Ball = false,
		},
		Button = {}
	}
end


function Fall:Actions(): nil
	
end


function Fall:Tick(): nil
	-- Perform movement
	MovementModule.AirAcceleration(self._character)

	-- Play fall animation
	--self._character:SetAnimation("Fall", 1, false)

	-- Move with collision
	CollisionModule.TryMove(self._character, true)
	if self._character.Flag.Grounded then
		-- Play landing sound and enter grounded state
		self._character:PlaySound(self._character, "Land", 1, 1)
		self._character:SetState(require( script.Parent.Run ).new(self._character))
		return
	end

	-- Align to gravity
	MovementModule.AlignGravity(self._character)
end


return Fall