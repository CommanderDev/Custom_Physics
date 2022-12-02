-- Character
-- Author(s): serverOptimist
-- Date: 03/29/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )
local Signal = require( Knit.Util.Signal )
local TableUtil = require( Knit.Util.TableUtil )
local CharacterHelper = require( Knit.SharedModules.Helpers.CharacterHelper )

-- Modules
local CharacterData = Knit.GameData.CharacterData
local TeamHelper = require( Knit.Helpers.TeamHelper )
-- Roblox Services

-- Variables

-- Modules

local ObjectModule = require( script.Object )
local TriggerModule = require( script.Trigger )
local InputModule = require( script.Input )

---------------------------------------------------------------------


local Character = {}
Character.__index = Character


-- Constructor and destructor
function Character.new( spawnCFrame ): table
	local self = setmetatable( {}, Character )
	self._janitor = Janitor.new()

	spawnCFrame = spawnCFrame
	self.States = script.State

	self.Stats = {
		Speed = 2,
		Acceleration = 100,
		Power = 1.5;
		Ground_DragStart = 0.4,
	}


	self.Flag = {
		Grounded = true,
	}
	self:SetParameters()

	-- Create sub-modules

	self.Object = ObjectModule.new(self)
	self._janitor:Add(self.Object)

	self.Trigger = TriggerModule.new(self)
	self._janitor:Add(self.Trigger)

	self.Input = InputModule.new()
	self._janitor:Add(self.Input)

	-- Initialize character position and speeds
	self.CFrame = spawnCFrame
	self.Spd = {X = 0, Y = 0, Z = 0}
	self.Gravity = CharacterData.DefaultGravity

	-- Initialize animation state
	self.Animation = {
		Current = nil,
		New = nil,
		Speed = 1,
		Turn = 0
	}

	-- Initialize sound state
	self.Sound = {
		Play = {},
		Stop = {}
	}

	-- Initialize misc states
	self.Reticle = { Object = nil, Position = nil }

	-- Initialize signals
	self.ReticleUpdate = Signal.new()
	self._janitor:Add( self.ReticleUpdate )

	self.ButtonChanged = Signal.new()
	self._janitor:Add( self.ButtonChanged )

	for index: number, state: ModuleScript in pairs(script.State:GetChildren()) do 
		require(state)._name = state.Name
	end
	-- Initial state
	self:SetState(require( self.States.Idle ).new(self) )

	return self
end


function Character:Destroy(): nil
	-- Clean up members
	self._janitor:Destroy()
end


-- Rotation functions
function Character:GetDotp(): number
	return -self.CFrame.UpVector:Dot(self.Gravity)
end


-- Coordinate system functions
function Character:GetCenter(): Vector3
	return self.CFrame * Vector3.new(0, self.Parameters.Collision_Height * self.Parameters.Scale, 0)
end


function Character:GetCenterCFrame(): ( CFrame )
	return self.CFrame * CFrame.new( 0, self.Parameters.Collision_Height * self.Parameters.Scale, 0 )
end


function Character:FromSpeed(speed: table): Vector3
	-- Return speed in correct coordinate space (Global Roblox)
	return (self.CFrame - self.CFrame.p) * Vector3.new(speed.Z, speed.Y, -speed.X)
end


function Character:ToSpeed(speed: Vector3): table
	-- Return speed in correct coordinate space (Local Sonic)
	local speed_vec = ((self.CFrame - self.CFrame.p):inverse()) * speed
	return {
		X = -speed_vec.Z,
		Y =  speed_vec.Y,
		Z =  speed_vec.X
	}
end


-- State functions
function Character:SetState( state: table ): nil
	-- Destroy previous state
	if self._state ~= nil then
		self._janitor:Remove(self._state)
		self._state = nil
	end
	-- Use given state
	self._state = state
	self._janitor:Add(self._state)

	-- Start state
	local stateStart = self._state:Start()

	self.Flag.Ball = stateStart.Flag.Ball or false

	self.ButtonChanged:Fire("Jump",      stateStart.Button.Jump)
	self.ButtonChanged:Fire("Secondary", stateStart.Button.Secondary)
	self.ButtonChanged:Fire("Tertiary",  stateStart.Button.Tertiary)
end


function Character:SetParameters(): nil
	self.Parameters = TableUtil.Copy( CharacterData.DefaultParameters )

	-- Get stat curves
	local function Curve(x, t)
		local y = 0.5 + math.log(1 + x * 0.069) * 1
		if x < 15 then
			y *= t + (x / 15) * (1 - t)
		end
		return y
	end
	local curve_speed = Curve(self.Stats.Speed, 0.2)
	local curve_acceleration = Curve(self.Stats.Acceleration, 0.5)
	--print(curve_drag)

	-- Apply stat modifications
	self.Parameters.Ground_Acceleration *= curve_acceleration
	self.Parameters.Air_AccelerationUp *= curve_acceleration
	self.Parameters.Air_AccelerationDown *= curve_acceleration --= 0.058

	--self.Parameters.Ground_DragStart = curve_drag
	self.Parameters.Ground_DragStart = self.Stats.Ground_DragStart

	self.Parameters.Ground_Drag_X /= curve_speed / curve_acceleration
	--self.Parameters.Air_Drag_X = -0.013

	self.Parameters.Jump_Speed *= self.Stats.Power
end



function Character:UseStamina( num: number ): boolean
	if self.Stamina >= num then
		self.Stamina -= num
		return true
	end
	return false
end


function Character:HasStamina( num: number ): boolean
	if ( self.Stamina >= num ) then
		return true
	end
	return false
end


-- Interaction functions
function Character:ObjectBounce(): nil
	if self._state.ObjectBounce then
		-- State override
		self._state:ObjectBounce()
	else
		-- Bounce off object
		if not self.Flag.Grounded then
			self.Spd.Y = math.max(self.Spd.Y * -1, 2.5)
		end
	end
end


function Character:Die(): nil
	-- Trigger death
	if not self.Flag.Dead then
		local CharacterController = Knit.GetController( "CharacterController" )
		if CharacterController ~= nil then
			task.spawn(function()
				CharacterController:TriggerDied()
			end)
		end
		self.Flag.Dead = true
	end
end


function Character:Hurt(position: Vector3, source: string): nil
	-- Just immediately die for now
	self:Die()
end


-- Animation functions
function Character:SetAnimation( name: string, speed: number, force: boolean): ()
	-- Change animation state
	if force or self.Animation.Current ~= name then
		self.Animation.Current = name
		self.Animation.New = name
	end
	self.Animation.Speed = speed
end

-- Sound functions
function Character:PlaySound( origin, name: string, volume: number, pitch: number ): ()
	-- Push sound to sound play queue
	table.insert(self.Sound.Play, {Origin = origin, Name = name, Volume = volume, Pitch = pitch})
end

function Character:StopSound( origin, name: string )
	-- Push sound to sound stop queue
	table.insert(self.Sound.Stop, {Origin = origin, Name = name})
end

-- Public functions
function Character:Tick( totalTicks: number, dt: number ): ()
	-- Reset misc states
	self.Reticle.Object = nil
	self.Reticle.Position = nil

	-- Early update objects
	self.Object:EarlyUpdate()

	-- Update input command
	self.Input:UpdateCommand(self)

	-- Update animation state
	self.Animation.New = nil

	-- Update sound state
	for i,_ in ipairs(self.Sound.Play) do
		self.Sound.Play[i] = nil
	end
	for i,_ in ipairs(self.Sound.Stop) do
		self.Sound.Stop[i] = nil
	end

	-- Update parameters state
	self:SetParameters()

	-- Tick state
	self._state:Actions(dt)
	self._state:Tick(dt)

	self.Animation.Turn = self.Input.Cmd.AnalogueTurn -- Done here so that certain actions (braking) don't look off

	-- Update objects
	self.Object:Update(dt)
	self.Object:CheckTouch(dt)

	-- Start/Stop objects every 5 ticks
	if ( (totalTicks % 5) == 0 ) then
		self.Object:CheckStartStop()
	end

	-- Check for trigger contact
	self.Trigger:CheckTouch()

	-- Fire misc signals
	self.ReticleUpdate:Fire(self.Reticle.Object, self.Reticle.Position)
end


return Character