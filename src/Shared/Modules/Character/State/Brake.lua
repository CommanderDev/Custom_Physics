-- Brake
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
local AbilityModule = require( script.Parent.Parent.Ability )
local MovementModule = require( script.Parent.Parent.Movement )
local CollisionModule = require( script.Parent.Parent.Collision )

---------------------------------------------------------------------


local Brake = {}
Brake.__index = Brake


-- Constructor and destructor
function Brake.new( character: table ): table
	local self = setmetatable( {}, Brake )

	-- Assign character
	self._character = character

	return self
end


function Brake:Destroy(): nil

end


-- State functions
function Brake:Start(): table
	return {
		Flag = {
			Ball = false,
		},
		Button = {
			Jump = "Jump",
			Spin = "SpinDash",
		}
	}
end


function Brake:Actions(): nil
	-- Check moves
	if AbilityModule.Jump(self._character) then
		return
	end

	-- Check to stop braking
	if self._character.Input.Cmd.AnalogueMag ~= 0 and math.abs(self._character.Input.Cmd.AnalogueTurn) < math.rad(135) then
		self._character:SetState(require( script.Parent.Run ).new(self._character))
		return
	end
	if self._character.Spd.X < 0.05 then
		MovementModule.Turn(self._character, self._character.Input.Cmd.AnalogueTurn, 0)
		self._character.Spd.X = math.abs(self._character.Spd.X)
		self._character:SetState(require( script.Parent.Idle ).new(self._character))
		return
	end
end


function Brake:Tick(): nil
	-- Perform movement
	MovementModule.Brake(self._character)

	-- Play brake animation
	self._character:SetAnimation("BrakeStop", 1, false)

	-- Move with collision
	CollisionModule.TryMove(self._character, (self._character:GetDotp() > 0.3) or (math.abs(self._character.Spd.X) > 1.16))
	if not self._character.Flag.Grounded then
		-- Enter airborne state
		self._character:SetState(require( script.Parent.Fall ).new(self._character))
		MovementModule.AlignGravity(self._character)
		return
	end
end


return Brake