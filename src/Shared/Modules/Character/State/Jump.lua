-- Jump
-- Author(s): serverOptimist
-- Date: 03/29/2022

--[[
	
]]

---------------------------------------------------------------------

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services
local UserInputService = game:GetService("UserInputService")
-- Variables

-- Modules
local AbilityModule = require( script.Parent.Parent.Ability )
local MovementModule = require( script.Parent.Parent.Movement )
local CollisionModule = require( script.Parent.Parent.Collision )

---------------------------------------------------------------------


local Jump = {}
Jump.__index = Jump


-- Constructor and destructor
function Jump.new( character: table, jumped: boolean ): table
	local self = setmetatable( {}, Jump )

	-- Assign character
	self._character = character

	if jumped then
		self._character.StaminaRegen = true

		-- Play jump animation and give hang time
		self._jumpHang = self._character.Parameters.Jump_HangTime
		self._jumpAnim = 20
		self._fallAnim = 10

		-- Play jump sound
	else
		-- Continue roll animation and don't give hang time
		self._jumpHang = 0
		self._jumpAnim = -math.huge
		self._fallAnim = math.huge
	end

	return self
end


function Jump:Destroy(): ()
	
end


-- State functions
function Jump:Start(): table
	-- Set animation speed
	self._jumpSpeed = math.abs(self._character.Spd.X)
	return {
		Flag = {
		},
		Button = {

		}
	}
end


function Jump:Actions(): ()
end


function Jump:Tick(): ()
	-- Perform movement

	MovementModule.AirAcceleration(self._character)

	-- Play jump animation
	if self._fallAnim > 0 then
		if self._jumpAnim > 0 then
			self._character:SetAnimation("Jump", 1, false)
			self._jumpAnim -= 1
		else
			if self._jumpAnim == 0 then
				self._jumpAnim -= 1
			end

			if self._character.Spd.Y < 0 then
				self._fallAnim -= 1
			end
		end
	else
		self._character:SetAnimation("Fall", 1, false)
	end

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

return Jump