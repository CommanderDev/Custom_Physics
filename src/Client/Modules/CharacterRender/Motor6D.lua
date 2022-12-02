-- Motor6D
-- Author(s): Jesse Appleton
-- Date: 01/31/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local Motor6D = {}
Motor6D.__index = Motor6D


function Motor6D.new( character: table ): table
	local self = setmetatable( {}, Motor6D )

	-- Use given character
	self._character = character

	-- Get joints
	self._tiltRoot = self._character.Character:WaitForChild("LowerTorso"):WaitForChild("Root")
	self._tiltRootC1 = self._tiltRoot.C1
	self._tiltNeck = self._character.Character:WaitForChild("Head"):WaitForChild("Neck")
	self._tiltNeckC1 = self._tiltNeck.C1

	return self
end


function Motor6D:Destroy(): nil

end


function Motor6D:ApplyTilt( tilt: number ): nil
	-- Set joint rotation
	self._tiltRoot.C1 = self._tiltRootC1 * CFrame.fromAxisAngle(Vector3.new(0, 0, 1), tilt * -1)
	self._tiltNeck.C1 = self._tiltNeckC1 * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), tilt * -1.5) * CFrame.fromAxisAngle(Vector3.new(0, 0, 1), tilt * 1)
end


return Motor6D