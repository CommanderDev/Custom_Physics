-- CFrameModule
-- Author(s): Jesse Appleton
-- Date: 01/08/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

local VectorModule = require( Knit.SharedModules.VectorModule )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local CFrameModule = {}

function CFrameModule.FromToRotation( from: Vector3, to: Vector3 ): CFrame
	-- Get our axis and angle
	local axis = from:Cross(to)
	local angle = VectorModule.Angle(from, to)
	
	-- Create CFrame from axis and angle
	if angle <= -math.pi then
		return CFrame.fromAxisAngle(Vector3.new(0, 0, 1), math.pi)
	elseif axis.magnitude ~= 0 then
		return CFrame.fromAxisAngle(axis, angle)
	else
		return CFrame.new()
	end
end

return CFrameModule