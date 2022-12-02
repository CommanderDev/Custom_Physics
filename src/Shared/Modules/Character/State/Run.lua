-- Run
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


local Run = {}
Run.__index = Run


-- Constructor and destructor
function Run.new( character: table, nocon ): table
	local self = setmetatable( {}, Run )

	-- Assign character
	self._character = character

	-- Set nocon timer
	self._nocon = nocon or 0

	return self
end


function Run:Destroy(): nil
	
end


-- State functions
function Run:Start(): table
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


function Run:Actions(): ()
	-- Disable input by nocon timer
	if self._nocon > 0 then
		self._character.Input.Cmd.AnalogueMag = 1
		self._character.Input.Cmd.AnalogueTurn = 0
		self._nocon -= 1
	end

	-- Check moves
	if AbilityModule.Jump(self._character) then
		return
	end

	-- Check to stop running
	if self._character.Input.Cmd.AnalogueMag ~= 0 then
		if self._character.Spd.X < -self._character.Parameters.Speed_Jog then
			self._character:SetState(require( script.Parent.Idle ).new(self._character))
			return
		end
	else
		if self._character.Spd.X < 0.05 then
			self._character:SetState(require( script.Parent.Idle ).new(self._character))
			return
		end
	end

	-- Check to start braking
	if self._nocon <= 0 and math.abs(self._character.Spd.X) > self._character.Parameters.Speed_Jog and math.abs(self._character.Input.Cmd.AnalogueTurn) >= math.rad(135) then
		self._character:SetState(require( script.Parent.Brake ).new(self._character))
		return
	end
end


function Run:Tick(): ()
	-- Perform movement
	MovementModule.Acceleration(self._character)

	-- Play run animation
	local anim
	if self._character._ball then 
		anim = "RunWithBall"
	else
		anim = "Run"
	end
	--[[if self._character.Spd.X >= (self._character.Parameters.Speed_Crash + 0.15) then
		anim = "Run"
	elseif self._character.Spd.X >= (self._character.Parameters.Speed_Rush - 0.1) then
		anim = "Jog"
	else
		anim = "Walk"
	end
	]]
	self._character:SetAnimation(anim, (0.85 + math.abs(self._character.Spd.X) * 0.4) * math.sign(self._character.Spd.X), false)

	-- Move with collision
	CollisionModule.TryMove(self._character, (self._character:GetDotp() > 0.3) or (math.abs(self._character.Spd.X) > 1.16))
	if not self._character.Flag.Grounded then
		-- Enter airborne state
		self._character:SetState(require( script.Parent.Fall ).new(self._character))
		MovementModule.AlignGravity(self._character)
		return
	end
end


return Run