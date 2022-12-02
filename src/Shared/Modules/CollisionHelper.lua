-- CollisionHelper
-- Author(s): Jesse Appleton
-- Date: 01/27/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local CollisionHelper = {}


-- Sphere to box collision
function CollisionHelper.DistPointAABB( point: Vector3, boundMin: Vector3, boundMax: Vector3 ): number
	-- Check if point is in box
	local size = boundMax - boundMin
	local off = point - boundMin

	if off.X < 0 or off.X > size.X or off.Y < 0 or off.Y > size.Y or off.Z < 0 or off.Z > size.Z then
		-- Outer check
		local sqDist = 0

		-- X axis check
		local v = point.X
		if v < boundMin.X then
			sqDist += (boundMin.X - v) * (boundMin.X - v)
		end
		if v > boundMax.X then
			sqDist += (v - boundMax.X) * (v - boundMax.X)
		end
		
		-- Y axis check
		local v = point.Y
		if v < boundMin.Y then
			sqDist += (boundMin.Y - v) * (boundMin.Y - v)
		end
		if v > boundMax.Y then
			sqDist += (v - boundMax.Y) * (v - boundMax.Y)
		end
		
		-- Z axis check
		local v = point.Z
		if v < boundMin.Z then
			sqDist += (boundMin.Z - v) * (boundMin.Z - v)
		end
		if v > boundMax.Z then
			sqDist += (v - boundMax.Z) * (v - boundMax.Z)
		end
		
		return math.sqrt(sqDist)
	else
		-- Inner check
		-- TODO: I want proper penetration code here
		return 0
	end
end


function CollisionHelper.TestSphereAABB( center: Vector3, radius: number, boundMin: Vector3, boundMax: Vector3 ): boolean
	local sqDist = CollisionHelper.DistPointAABB(center, boundMin, boundMax)
	return sqDist <= radius
end


function CollisionHelper.TestSphereBox( center: Vector3, radius: number, cframe: CFrame, size: Vector3 ): boolean
	local sqDist = CollisionHelper.DistPointAABB(cframe:inverse() * center, size * -0.5, size * 0.5)
	return sqDist <= radius
end


return CollisionHelper