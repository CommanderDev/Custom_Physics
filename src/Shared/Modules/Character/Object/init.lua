-- Object
-- Author(s): Jesse Appleton
-- Date: 01/24/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )

-- Roblox Services
local CollectionService = game:GetService("CollectionService")

-- Variables

-- Modules
local CollisionHelper = require( Knit.SharedModules.CollisionHelper )
local SpatialPartitionClass = require( Knit.SharedModules.SpatialPartition )

---------------------------------------------------------------------


local Object = {}
Object.__index = Object


-- Constructor and destructor
function Object.new( character: table ): table
	local self = setmetatable( {}, Object )
	self._janitor = Janitor.new()

	-- Use given character
	self._character = character

	-- Create spatial partition
	self._partition = SpatialPartitionClass.new(32)
	self._janitor:Add(self._partition)

	-- Initialize object registry and classes
	self._objects = {}
	self._addObjects = {}

	for _,v in ipairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			-- Require class module
			local objectClass = require(v)

			-- Look for objects that already exist
			for _,k in ipairs(CollectionService:GetTagged(v.Name)) do
				-- Push to object add queue if descendant of map objects
				if ( k:IsDescendantOf(workspace) ) then
					self._addObjects[ k ] = {ObjectClass = objectClass, Object = k}
				end
			end

			-- Attach to new objects
			self._janitor:Add(CollectionService:GetInstanceAddedSignal(v.Name):Connect(function(k)
				-- Push to object add queue if descendant of map objects
				if ( k:IsDescendantOf(workspace) ) then
					self._addObjects[ k ] = {ObjectClass = objectClass, Object = k}
				end
			end))

			-- Attach to removing objects
			self._janitor:Add(CollectionService:GetInstanceRemovedSignal(v.Name):Connect(function(k)
				-- Remove from object table
				self._addObjects[ k ] = nil
				local object = self._objects[k]
				if object ~= nil then
					self:RemoveHitbox(object)
					self._janitor:Remove(object)
					self._objects[k] = nil
				end
			end))
		end
	end

	return self
end


function Object:Destroy(): nil
	self._janitor:Destroy()
end

-- Public functions
function Object:EarlyUpdate(): nil
	-- Flush objects
	self:_flushNew()

	-- Update objects
	for _,v in pairs(self._objects) do
		if v.Callback.EarlyUpdate ~= nil then
			v.Callback.EarlyUpdate(v)
		end
	end
end


function Object:Update(): nil
	-- Flush objects
	self:_flushNew()

	-- Update objects
	for _,v in pairs(self._objects) do
		if v.Callback.Update ~= nil then
			v.Callback.Update(v)
		end
	end
end

function Object:CheckStartStop(): ()
	local nearObjects = self:GetObjectsInSphere( workspace.CurrentCamera.CFrame.Position, 250, function( object: table ): ( boolean )
		return not not object.Callback.Start
	end)
	-- Start / Stop Objects
	for _, object: {} in pairs( self._objects ) do
		if ( nearObjects[object] ) then
			if ( not object._isStarted ) then
				object._isStarted = true
				object.Callback.Start( object )
			end
		elseif ( object._isStarted ) and ( object.Callback.Stop ) then
			object._isStarted = false
			object.Callback.Stop( object )
		end
	end
end


function Object:CheckTouch(): nil
	-- Get objects in player sphere
	local center = self._character:GetCenter()
	local radius = self._character.Parameters.Collision_Radius * self._character.Parameters.Scale

	local touchedObjects = self:GetObjectsInSphere(center, radius, function( object: table ): boolean
		return object.Callback.CharacterTouched ~= nil
	end)

	-- Call touched callbacks
	for _,v in pairs(touchedObjects) do
		v.Callback.CharacterTouched(v)
	end
end


function Object:GetObjectsInBounds( boundMin: Vector3, boundMax: Vector3, filter ): ( {[number]: {}} )
	-- Get objects in partition
	local objects = self._partition:GetTagsInBounds(boundMin, boundMax)

	if filter ~= nil then
		-- Filter objects
		local result = {}
		for _,v in ipairs(objects) do
			if filter(v) then
				table.insert(result, v)
			end
		end
		return result
	else
		-- Return all objects
		return objects
	end
end


function Object:GetObjectsInSphere( center: Vector3, radius: number, filter ): ( {[{}]: {}} )
	-- Get objects in sphere bounds
	local objects = self:GetObjectsInBounds(center - Vector3.new(radius, radius, radius), center + Vector3.new(radius, radius, radius), filter)

	-- Do precise checks
	local objs = {}
	for _,v in ipairs(objects) do
		local dist = CollisionHelper.DistPointAABB(v.Hitbox.CFrame:inverse() * center, v.Hitbox.Size * -0.5, v.Hitbox.Size * 0.5)
		if dist < radius then
			table.insert(objs, {Object = v, Dist = dist})
		end
	end

	-- Sort to result
	table.sort(objs, function(a, b) return a.Dist < b.Dist end)

	-- I use this for starting/stopping objects quickly in the update method
	-- I couldn't even load my benchmark using table.find(nearObjects, object) but doing nearObjects[object] was infinitely more performant
	-- In my benchmarks the difference between ipairs and pairs was negligible even in extreme cases
	local result = {}
	for i,v in ipairs(objs) do
		result[ v.Object ] = v.Object
	end

	return result
end


-- Common object functions
function Object:SetHitbox( object: table, cframe: CFrame, size: Vector3 ): nil
	-- Set hitbox in partition and object
	self._partition:GetTagNode(object):SetBox(cframe, size)
	if object.Hitbox == nil then
		object.Hitbox = { CFrame = cframe, Size = size }
	else
		object.Hitbox.CFrame = cframe
		object.Hitbox.Size = size
	end
end


function Object:RemoveHitbox( object: table ): nil
	self._partition:GetTagNode(object):Destroy()
end


-- Private functions
function Object:_flushNew(): nil
	-- Construct objects from add queue
	local result = {}

	for i: Instance, v: {} in pairs( self._addObjects ) do
		-- Construct object
		local object = v.ObjectClass.new(self._character, v.Object)
		if ( object ) then
			-- Remove already existing object
			local existingObject = self._objects[v.Object]
			if existingObject ~= nil then
				self._janitor:Remove(existingObject)
				self._objects[v.Object] = nil
			end

			self._janitor:Add(object)
			table.insert(result, object)

			-- Push to object list and pop object add from queue
			self._objects[v.Object] = object
			self._addObjects[i] = nil
		end
	end

	return result
end


return Object