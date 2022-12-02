-- Node
-- Author(s): Jesse Appleton
-- Date: 01/24/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local Node = {}
Node.__index = Node


function Node.new( partition: table, tag ): table
	local self = setmetatable( {}, Node )

	-- Use given partition and tag
	self.Tag = tag
	self._partition = partition

	self._boundMin = nil
	self._boundMax = nil

	return self
end


function Node:Destroy(): nil
	-- Remove from partitioning
	self._partition:_removeNode(self, self._boundMin, self._boundMax)
end


function Node:SetBox( cframe: CFrame, size: Vector3 )
	-- Get box corners
	local posCFrame = cframe.p
	local rotCFrame = cframe - cframe.p

	local size2 = size * 0.5

	local corner1 = rotCFrame * Vector3.new(-size2.X, -size2.Y, -size2.Z)
	local corner2 = rotCFrame * Vector3.new( size2.X, -size2.Y, -size2.Z)
	local corner3 = rotCFrame * Vector3.new(-size2.X,  size2.Y, -size2.Z)
	local corner4 = rotCFrame * Vector3.new(-size2.X, -size2.Y,  size2.Z)

	local maxX = math.max(math.abs(corner1.X), math.abs(corner2.X), math.abs(corner3.X), math.abs(corner4.X))
	local maxY = math.max(math.abs(corner1.Y), math.abs(corner2.Y), math.abs(corner3.Y), math.abs(corner4.Y))
	local maxZ = math.max(math.abs(corner1.Z), math.abs(corner2.Z), math.abs(corner3.Z), math.abs(corner4.Z))

	-- Update bounding box
	local boundMin = Vector3.new(posCFrame.X - maxX, posCFrame.Y - maxY, posCFrame.Z - maxZ)
	local boundMax = Vector3.new(posCFrame.X + maxX, posCFrame.Y + maxY, posCFrame.Z + maxZ)
	
	self._partition:_setNodeBounds(self, self._boundMin, self._boundMax, boundMin, boundMax)
	self._boundMin = boundMin
	self._boundMax = boundMax
end


return Node