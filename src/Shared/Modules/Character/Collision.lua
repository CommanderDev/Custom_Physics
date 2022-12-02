-- Collision
-- Author(s): serverOptimist
-- Date: 03/29/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

local DebugUtility = require( Knit.Util.DebugUtility )

-- Roblox Services
local CollectionService = game:GetService("CollectionService")

-- Variables

-- Modules
local VectorModule = require( Knit.SharedModules.VectorModule )
local CFrameModule = require( Knit.SharedModules.CFrameModule )

local MovementModule = require( script.Parent.Movement )

---------------------------------------------------------------------

local Collision = {}


-- Collision functions
function Collision.TryMove( self: table, touchFloor: boolean ): nil
	-- Move alongside standing platform
	if self.Flag.Grounded and self.Platform ~= nil and self.PlatformLastCFrame ~= nil then
		local nextCFrame = self.Platform.CFrame * (self.PlatformLastCFrame:inverse() * self.CFrame)
		self.PlatformInertia = nextCFrame.p - self.CFrame.p
		MovementModule.SetCFrame(self, nextCFrame, 0)
	end
	self.Platform = nil

	-- Remember previous CFrame
	local prevCFrame = self.CFrame

	-- Wall rays
	local wallDirs = {
		{X =  1, Z =  0},
		{X = -1, Z =  0},
		{X =  0, Z =  1},
		{X =  0, Z = -1},
	}

	local wallHeights = {
		self.Parameters.Collision_Height * 0.85,
		self.Parameters.Collision_Height * 1.25,
		self.Parameters.Collision_Height * 1.75,
	}

	-- Wall collision
	for j,k in ipairs(wallDirs) do
		local clips = {}
		for i,v in ipairs(wallHeights) do
			Collision._wallray(self, clips, v, k.X, k.Z, (j == 1 and i == 1) and self.Flag.Grounded)
		end
		Collision._wallResolve(self, clips)
	end
	MovementModule.SetCFrame(self, self.CFrame + self:FromSpeed({X = self.Spd.X, Y = 0, Z = self.Spd.Z}) * self.Parameters.Scale, 0)

	-- Vertical collision
	do
		local from = {X = 0, Y = self.Parameters.Collision_Height + math.min(self.Spd.Y, 0), Z = 0}
		local direct = {X = 0, Y = self.Parameters.Collision_Height * 2, Z = 0}
		local directExt = {X = 0, Y = (self.Parameters.Collision_Height) + math.max(self.Spd.Y, 0), Z = 0}
		local cast = Collision.Loccast(self, from, directExt)

		if cast ~= nil then
			-- Clip out
			MovementModule.SetCFrame(self, (self.CFrame - self.CFrame.p) + cast.Position - self:FromSpeed(direct) * self.Parameters.Scale, 0)
			Collision._killSpeed(self, cast.Normal)
		end
	end

	do
		local clip = self.Flag.Grounded and self.Parameters.Collision_Clip or 0

		local from = {X = 0, Y = self.Parameters.Collision_Height + math.max(self.Spd.Y, 0), Z = 0}
		local direct = {X = 0, Y = -self.Parameters.Collision_Height - clip + math.min(self.Spd.Y, 0), Z = 0}
		local cast = Collision.Loccast(self, from, direct)

		if cast ~= nil then
			if cast.Instance:GetAttribute("NoFloor") ~= true and cast.Instance.Parent:GetAttribute("NoFloor") ~= true and cast.Normal:Dot(self.CFrame.UpVector) >= 0.5 and (self.Flag.Grounded or self:FromSpeed(self.Spd):Dot(cast.Normal) <= 0) and touchFloor then
				-- Align with floor
				local nextRotation = CFrameModule.FromToRotation(self.CFrame.UpVector, cast.Normal) * (self.CFrame - self.CFrame.p)
				MovementModule.SetCFrame(self, nextRotation + cast.Position, self.Flag.Grounded and 0 or 1)
				self.Spd.Y = 0

				-- Set platform
				self.Platform = cast.Instance
				self.PlatformLastCFrame = cast.Instance.CFrame

				-- Set grounded
				self.Flag.Grounded = true
			else
				-- Clip out
				MovementModule.SetCFrame(self, (self.CFrame - self.CFrame.p) + cast.Position, 0)
				Collision._killSpeed(self, cast.Normal)

				-- Set ungrounded
				self.Flag.Grounded = false
			end
		else
			-- Set ungrounded
			self.Flag.Grounded = false
		end
	end

	MovementModule.SetCFrame(self, self.CFrame + self:FromSpeed({X = 0, Y = self.Spd.Y, Z = 0}) * self.Parameters.Scale, 0)

	-- Check if our collisions thus far have moved us through any walls
	local tgtCFrame = self.CFrame

	do
		local from = prevCFrame * (Vector3.new(0, self.Parameters.Collision_Height, 0) * self.Parameters.Scale)
		local to = tgtCFrame * (Vector3.new(0, self.Parameters.Collision_Height, 0) * self.Parameters.Scale)
		local upOff = tgtCFrame.UpVector * (self.Parameters.Collision_Height * self.Parameters.Scale)

		local dir = to - from

		if dir.magnitude ~= 0 then
			local cast = Collision.Raycast(from, dir)

			if cast ~= nil then
				-- Keep us from going through this collision
				tgtCFrame = (tgtCFrame - tgtCFrame.p) + (cast.Position - (dir.unit * (self.Parameters.Collision_Width * self.Parameters.Scale)) - upOff)
				Collision._killSpeed(self, cast.Normal)
			end
		end
	end

	-- Use target CFrame
	MovementModule.SetCFrame(self, tgtCFrame, 0)

	-- Release inertia if no longer on a platform
	if self.Platform == nil and self.PlatformInertia ~= nil then
		local apply = self:ToSpeed(self.PlatformInertia / self.Parameters.Scale)
		self.Spd.X += apply.X
		self.Spd.Y += apply.Y
		self.Spd.Z += apply.Z
		self.PlatformInertia = nil
	end
end


function Collision.Move( self: table ): nil
	-- Don't perform any collision
	MovementModule.SetCFrame(self, self.CFrame + (self:FromSpeed(self.Spd) * self.Parameters.Scale), 0)
end


-- Get whitelist
local whitelist = CollectionService:GetTagged("Collision")
table.insert(whitelist, workspace.Terrain)

-- Build parameters
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = whitelist
raycastParams.IgnoreWater = true

CollectionService:GetInstanceAddedSignal("Collision"):Connect(function(object)
	--table.insert(whitelist, object)
	table.insert(raycastParams.FilterDescendantsInstances, object)
	--raycastParams.FilterDescendantsInstances = whitelist
end)
function Collision.Raycast( from: Vector3, direct: Vector3 ): RaycastResult
	-- Perform raycast
	return workspace:Raycast(from, direct, raycastParams)
end


function Collision.Loccast( self: table, from: table, direct: table ): RaycastResult
	-- Convert to world space
	local worldFrom = self.CFrame.p + (self:FromSpeed(from) * self.Parameters.Scale)
	local worldDirect = self:FromSpeed(direct) * self.Parameters.Scale

	-- Perform raycast
	return Collision.Raycast(worldFrom, worldDirect)
end


-- Private functions
function Collision._killSpeed( self: table, normal: Vector3 ): nil
	-- Check if we're moving towards normal
	local worldSpd = self:FromSpeed(self.Spd)
	if worldSpd:Dot(normal) < 0 then
		self.Spd = self:ToSpeed(VectorModule.PlaneProject(worldSpd, normal))
	end
end


function Collision._checkAttach( self: table, dir: Vector3, nor: Vector3 ): nil
	local dDot = dir.unit:Dot(nor)
	local sDot = self:FromSpeed(self.Spd):Dot(nor)
	local uDot = self.CFrame.UpVector:Dot(nor)
	return (dDot < -0.35 and sDot < -1.16 and uDot > 0.5)
end


function Collision._wallray( self: table, clips: table, oy: number, dx: number, dz: number, attach: boolean ): nil
	-- Construct ray
	local locFrom = {
		X = 0,
		Y = oy,
		Z = 0,
	}
	local locDirect = {
		X = (dx * self.Parameters.Collision_Width),
		Y = 0,
		Z = (dz * self.Parameters.Collision_Width)
	}
	local locDirectExt = {
		X = locDirect.X + (math.max(self.Spd.X * dx, 0) * math.sign(dx)),
		Y = 0,
		Z = locDirect.Z + (math.max(self.Spd.Z * dz, 0) * math.sign(dz))
	}

	local from = self:FromSpeed(locFrom) * self.Parameters.Scale
	local direct = self:FromSpeed(locDirect) * self.Parameters.Scale
	local directExt = self:FromSpeed(locDirectExt) * self.Parameters.Scale

	-- Perform raycast
	local cast = Collision.Raycast(self.CFrame.p + from, directExt)
	if cast ~= nil then
		if attach and Collision._checkAttach(self, direct, cast.Normal) then
			-- Rotate to meet wall
			local nextRotation = CFrameModule.FromToRotation(self.CFrame.UpVector, cast.Normal) * (self.CFrame - self.CFrame.p)
			MovementModule.SetCFrame(self, nextRotation + cast.Position, self.Flag.Grounded and 0 or 1)
		else
			-- Project normal if on the ground
			local prjNormal
			if self.Flag.Grounded then
				prjNormal = VectorModule.PlaneProject(cast.Normal, self.CFrame.UpVector)
				if prjNormal.magnitude ~= 0 then
					prjNormal = prjNormal.unit
				else
					prjNormal = -direct.unit
				end
			else
				prjNormal = cast.Normal
			end

			-- Push clip to list
			table.insert(clips, {
				From = self.CFrame.p + from,
				Direct = direct.unit,
				Resolve = cast.Position - direct - from,
				Normal = prjNormal
			})
		end
	end
end


function Collision._wallResolve( self: table, clips: table ): ()
	-- Find shortest clip
	local selClip = nil
	local selClipLength = math.huge

	for _,v in ipairs(clips) do
		local length = v.Direct:Dot(v.Resolve - v.From)
		if length < selClipLength then
			selClip = v
			selClipLength = length
		end
	end

	-- Resolve clip
	if selClip ~= nil then
		MovementModule.SetCFrame(self, (self.CFrame - self.CFrame.p) + selClip.Resolve, 0)
		local lspdy = self.Spd.Y
		Collision._killSpeed(self, selClip.Normal)
		self.Spd.Y = math.min(self.Spd.Y, lspdy)
	end
end


return Collision