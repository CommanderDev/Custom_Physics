-- SpatialPartition
-- Author(s): Jesse Appleton
-- Date: 01/15/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

-- Modules
local NodeClass = require( script.Node )

---------------------------------------------------------------------


local SpatialPartition = {}
SpatialPartition.__index = SpatialPartition


-- Constructor and destructor
function SpatialPartition.new( size: number ): table
	local self = setmetatable( {}, SpatialPartition )

	-- Initialize nodes and partitioning table
	self._nodes = {}
	self._partition = {}
	self._debug = {}

	self._size = size

	return self
end


function SpatialPartition:Destroy(): nil
	-- Wipe partition table so we don't spend too long here
	self._partition = nil

	-- Destroy nodes
	for _,v in pairs(self._nodes) do
		v:Destroy()
	end
end


-- Public functions
function SpatialPartition:GetTagNode( tag ): table
	-- Return already existing node of given tag
	local node = self._nodes[tag]
	if node ~= nil then
		return node
	end

	-- Create and return new node with tag
	node = NodeClass.new(self, tag)
	self._nodes[tag] = node
	return node
end


function SpatialPartition:GetTagsInBounds( boundMin: Vector3, boundMax: Vector3 )
	-- Divide bounds
	boundMin = Vector3.new(math.floor(boundMin.X / self._size), math.floor(boundMin.Y / self._size), math.floor(boundMin.Z / self._size))
	boundMax = Vector3.new(math.floor(boundMax.X / self._size), math.floor(boundMax.Y / self._size), math.floor(boundMax.Z / self._size))

	-- Get nodes in bounds
	local nodes = {}
	local nodesUsed = {}

	for x = boundMin.X, boundMax.X do
		for y = boundMin.Y, boundMax.Y do
			for z = boundMin.Z, boundMax.Z do
				-- Check if partition exists at bounds
				local partition = self._partition[Vector3.new(x, y, z)]
				if partition ~= nil then
					-- Add nodes to result
					for i,_ in pairs(partition) do
						if nodesUsed[i] == nil then
							table.insert(nodes, i.Tag)
							nodesUsed[i] = true
						end
					end
				end
			end
		end
	end

	return nodes
end


-- Private functions
function SpatialPartition:_removeNode( node: table, boundMin, boundMax ): nil
	-- Don't run when partition table has been wiped
	if self._partition == nil then
		return
	end

	if boundMin ~= nil and boundMax ~= nil then
		-- Divide bounds
		boundMin = Vector3.new(math.floor(boundMin.X / self._size), math.floor(boundMin.Y / self._size), math.floor(boundMin.Z / self._size))
		boundMax = Vector3.new(math.floor(boundMax.X / self._size), math.floor(boundMax.Y / self._size), math.floor(boundMax.Z / self._size))

		-- Remove node from bounds
		for x = boundMin.X, boundMax.X do
			for y = boundMin.Y, boundMax.Y do
				for z = boundMin.Z, boundMax.Z do
					self:_removeNodePartition(node, Vector3.new(x, y, z))
				end
			end
		end
	end

	-- Remove node from table
	self._nodes[node.Tag] = nil
end


function SpatialPartition:_setNodeBounds( node: table, fromBoundMin, fromBoundMax, toBoundMin: Vector3, toBoundMax: Vector3)
	if fromBoundMin ~= nil and fromBoundMax ~= nil then --This case can be more optimal
		-- Divide bounds
		fromBoundMin = Vector3.new(math.floor(fromBoundMin.X / self._size), math.floor(fromBoundMin.Y / self._size), math.floor(fromBoundMin.Z / self._size))
		fromBoundMax = Vector3.new(math.floor(fromBoundMax.X / self._size), math.floor(fromBoundMax.Y / self._size), math.floor(fromBoundMax.Z / self._size))
		toBoundMin = Vector3.new(math.floor(toBoundMin.X / self._size), math.floor(toBoundMin.Y / self._size), math.floor(toBoundMin.Z / self._size))
		toBoundMax = Vector3.new(math.floor(toBoundMax.X / self._size), math.floor(toBoundMax.Y / self._size), math.floor(toBoundMax.Z / self._size))

		-- Check if bounds have changed
		if fromBoundMin == toBoundMin and fromBoundMax == toBoundMax then
			return
		end

		-- Remove node from bounds that aren't contained in new bounding box
		for x = fromBoundMin.X, fromBoundMax.X do
			for y = fromBoundMin.Y, fromBoundMax.Y do
				for z = fromBoundMin.Z, fromBoundMax.Z do
					-- Check if outside of new bounding box
					if x < toBoundMin.X or x > toBoundMax.X or y < toBoundMin.Y or y > toBoundMax.Y or z < toBoundMin.Z or z > toBoundMax.Z then
						self:_removeNodePartition(node, Vector3.new(x, y, z))
					end
				end
			end
		end

		-- Add node from bounds that weren't contained in previous bounding box
		for x = toBoundMin.X, toBoundMax.X do
			for y = toBoundMin.Y, toBoundMax.Y do
				for z = toBoundMin.Z, toBoundMax.Z do
					-- Check if outside old bounding box
					if x < fromBoundMin.X or x > fromBoundMax.X or y < fromBoundMin.Y or y > fromBoundMax.Y or z < fromBoundMin.Z or z > fromBoundMax.Z then
						self:_addNodePartition(node, Vector3.new(x, y, z))
					end
				end
			end
		end
	else
		-- Divide bounds
		toBoundMin = Vector3.new(math.floor(toBoundMin.X / self._size), math.floor(toBoundMin.Y / self._size), math.floor(toBoundMin.Z / self._size))
		toBoundMax = Vector3.new(math.floor(toBoundMax.X / self._size), math.floor(toBoundMax.Y / self._size), math.floor(toBoundMax.Z / self._size))

		-- Add node from bounds
		for x = toBoundMin.X, toBoundMax.X do
			for y = toBoundMin.Y, toBoundMax.Y do
				for z = toBoundMin.Z, toBoundMax.Z do
					self:_addNodePartition(node, Vector3.new(x, y, z))
				end
			end
		end
	end
end


function SpatialPartition:_incDebug( space: Vector3 )
	-- Get debug partition
	local partition = self._debug[space]
	if partition == nil then
		self._debug[space] = {part = nil, cnt = 0}
		partition = self._debug[space]
	end

	-- Increment debug partition
	partition.cnt += 1
	
	if partition.cnt == 1 and partition.part == nil then
		partition.part = Instance.new("Part")
		partition.part.Size = Vector3.new(self._size, self._size, self._size)
		partition.part.CFrame = CFrame.new((space.X + 0.5) * self._size, (space.Y + 0.5) * self._size, (space.Z + 0.5) * self._size)
		partition.part.Transparency = 0.8
		partition.part.Color = Color3.new(1, 0, 0)
		partition.part.Anchored = true
		partition.part.CanCollide = false
		partition.part.Parent = workspace
	end
end


function SpatialPartition:_decDebug( space: Vector3 )
	-- Get debug partition
	local partition = self._debug[space]
	if partition ~= nil then
		-- Decrement debug partition
		partition.cnt -= 1
		
		if partition.cnt == 0 and partition.part ~= nil then
			partition.part:Destroy()
			partition.part = nil
		end
	end
end


function SpatialPartition:_addNodePartition( node: table, space: Vector3 )
	-- Check if partition at space exists
	local partition = self._partition[space]
	if partition == nil then
		-- Make new partition at space
		self._partition[space] = {[node] = true}
	else
		-- Add node to partition
		partition[node] = true
	end
end


function SpatialPartition:_removeNodePartition( node: table, space: Vector3 )
	-- Check if partition at space exists
	local partition = self._partition[space]
	if partition ~= nil then
		-- Remove node from partition
		partition[node] = nil
	end
end


return SpatialPartition