-- VectorModule
-- Author(s): Jesse Appleton
-- Date: 01/08/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local VectorModule = {}


function VectorModule.PlaneProject( point: Vector3, nor: Vector3 ): Vector3
	local ptpd = (nor.unit):Dot(point)
	return point - ((nor.unit) * ptpd), ptpd
end


function VectorModule.Angle( from: Vector3, to: Vector3 )
	local dot = (from.unit):Dot(to.unit)
	if dot >= 1 then
		return 0
	elseif dot <= -1 then
		return -math.pi
	end

	return math.acos(dot)
end


function VectorModule.SignedAngle( from: Vector3, to: Vector3, up: Vector3 ): Vector3
	local right = (up.unit):Cross(from).unit
	local rdot = math.sign(right:Dot(to.unit))
	if rdot == 0 then
		rdot = 1
	end

	local dot = (from.unit):Dot(to.unit)
	if dot >= 1 then
		return 0
	elseif dot <= -1 then
		return -math.pi * rdot
	end

	return math.acos(dot) * rdot
end


return VectorModule