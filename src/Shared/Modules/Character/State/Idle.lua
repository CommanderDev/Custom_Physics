-- Idle
-- Author(s): serverOptimist
-- Date: 03/29/2022

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


local Idle = {}
Idle.__index = Idle


-- Constructor and destructor
function Idle.new( character: table ): table
	local self = setmetatable( {}, Idle )
	-- Assign character
	self._character = character

	return self
end


function Idle:Destroy(): nil
	
end


-- State functions
function Idle:Start(): table
	return {
		Flag = {
			Ball = false,
		},
		Button = {
			Jump = "Jump",
		}
	}
end


function Idle:Actions(): nil
	-- Check moves
	if AbilityModule.Jump(self._character)  then
		return
	end
	-- Check to start running
	if self._character.Input.Cmd.AnalogueMag ~= 0 and self._character.Spd.X > -self._character.Parameters.Speed_Jog then
		self._character:SetState(require( script.Parent.Run ).new(self._character))
		return
	end

	-- Check to start braking
	if self._character:GetDotp() > 0.98 and self._character.Spd.X > self._character.Parameters.Speed_Jog then
		self._character:SetState(require( script.Parent.Brake ).new(self._character))
		return
	end
end


function Idle:Tick(): nil
	-- Perform movement
	MovementModule.TurnY(self._character, self._character.Input.Cmd.AnalogueTurn)
	MovementModule.Acceleration(self._character)
	MovementModule.TurnGravity(self._character)

	-- Play idle animation
	self._character:SetAnimation("IdleLoop", 1, false)

	-- Move with collision
	CollisionModule.TryMove(self._character, (self._character:GetDotp() > 0.3) or (math.abs(self._character.Spd.X) > 1.16))
	if not self._character.Flag.Grounded then
		-- Enter airborne state
		self._character:SetState(require( script.Parent.Fall ).new(self._character))
		MovementModule.AlignGravity(self._character)
		return
	end
end


return Idle