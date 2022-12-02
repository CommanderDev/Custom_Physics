-- Trigger
-- Author(s): Jesse Appleton
-- Date: 02/02/2022

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


local Trigger = {}
Trigger.__index = Trigger


-- Constructor and destructor
function Trigger.new( character: table ): table
	local self = setmetatable( {}, Trigger )
	self._janitor = Janitor.new()

	-- Use given character
	self._character = character

	-- Create spatial partition
	self._partition = SpatialPartitionClass.new(32)
	self._janitor:Add(self._partition)

	-- Initialize trigger registry and classes
	self._triggers = {}
	self._addTriggers = {}

	for _,v in ipairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			-- Require class module
			local triggerClass = require(v)

			-- Look for triggers that already exist
			for _,k in ipairs(CollectionService:GetTagged(v.Name)) do
				-- Push to trigger add queue if descendant of map triggers
				if k:IsDescendantOf(workspace.Map.Triggers) then
					table.insert(self._addTriggers, {TriggerClass = triggerClass, Trigger = k})
				end
			end

			-- Attach to new triggers
			self._janitor:Add(CollectionService:GetInstanceAddedSignal(v.Name):Connect(function(k)
				-- Push to trigger add queue if descendant of map triggers
				if k:IsDescendantOf(workspace.Map.Triggers) then
					table.insert(self._addTriggers, {TriggerClass = triggerClass, Trigger = k})
				end
			end))

			-- Attach to removing triggers
			self._janitor:Add(CollectionService:GetInstanceRemovedSignal(v.Name):Connect(function(k)
				-- Remove from trigger table
				local trigger = self._triggers[k]
				if trigger ~= nil then
					self:RemoveHitbox(trigger)
					self._janitor:Remove(trigger)
					self._triggers[k] = nil
				end
			end))
		end
	end

	return self
end


function Trigger:Destroy(): nil
	self._janitor:Destroy()
end


-- Public functions
function Trigger:CheckTouch(): nil
	-- Flush new triggers
	self:_flushNew()

	-- Get triggers in partition
	local center = self._character:GetCenter()
	local radius = self._character.Parameters.Collision_Radius * self._character.Parameters.Scale

	local triggers = self._partition:GetTagsInBounds(center, center)

	-- Do precise checks
	local trigs = {}
	for _,v in ipairs(triggers) do
		if v.Callback.CharacterTouched ~= nil then
			local dist = CollisionHelper.DistPointAABB(v.Hitbox.CFrame:inverse() * center, v.Hitbox.Size * -0.5, v.Hitbox.Size * 0.5)
			if dist < radius then
				table.insert(trigs, {Trigger = v, Dist = dist})
			end
		end
	end

	-- Sort and trigger
	table.sort(trigs, function(a, b) return a.Dist < b.Dist end)

	for _,v in ipairs(trigs) do
		v.Trigger.Callback.CharacterTouched(v.Trigger)
	end
end


-- Common Trigger functions
function Trigger:SetHitbox( trigger: table, cframe: CFrame, size: Vector3 ): nil
	-- Set hitbox in partition and trigger
	self._partition:GetTagNode(trigger):SetBox(cframe, size)
	if trigger.Hitbox == nil then
		trigger.Hitbox = { CFrame = cframe, Size = size }
	else
		trigger.Hitbox.CFrame = cframe
		trigger.Hitbox.Size = size
	end
end


function Trigger:RemoveHitbox( trigger: table ): nil
	self._partition:GetTagNode(trigger):Destroy()
end


-- Private functions
function Trigger:_flushNew(): nil
	-- Construct triggers from add queue
	local result = {}

	for i,v in ipairs(self._addTriggers) do
		-- Remove already existing trigger
		local trigger = self._triggers[v.Trigger]
		if trigger ~= nil then
			self._janitor:Remove(trigger)
			self._triggers[v.Trigger] = nil
		end

		-- Construct trigger
		local trigger = v.TriggerClass.new(self._character, v.Trigger)
		self._janitor:Add(trigger)
		table.insert(result, trigger)

		self:SetHitbox(trigger, v.Trigger.CFrame, v.Trigger.Size)

		-- Push to trigger list and pop trigger add from queue
		self._triggers[v.Trigger] = trigger
		self._addTriggers[i] = nil
	end

	return result
end


return Trigger