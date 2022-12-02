-- Skinned
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


local Skinned = {}
Skinned.__index = Skinned


function Skinned.new( character: table ): table
	local self = setmetatable( {}, Skinned )

	-- Use given character
	self._character = character

	-- Get joints
	self._tiltRoot = self._character.Character:WaitForChild("HumanoidRootPart"):WaitForChild("Root")
	self._tiltRootCFrame = self._tiltRoot.CFrame
	self._tiltNeck = self._tiltRoot:WaitForChild("LowerTorso"):WaitForChild("UpperTorso"):WaitForChild("Neck")
	self._tiltNeckCFrame = self._tiltNeck.CFrame
	
	return self
end


function Skinned:Destroy(): nil

end


function Skinned:ApplyTilt( tilt: number ): nil
	-- Set joint rotation
	self._tiltRoot.CFrame = self._tiltRootCFrame * CFrame.new(math.sin(tilt) * 1.5, 0, 0) * CFrame.fromAxisAngle(Vector3.new(0, 0, 1), tilt * 1)
	self._tiltNeck.CFrame = self._tiltNeckCFrame * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), tilt * 1.5) * CFrame.fromAxisAngle(Vector3.new(0, 0, 1), tilt * 1)
end


return Skinned