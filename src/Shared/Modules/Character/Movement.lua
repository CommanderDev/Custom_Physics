-- Movement
-- Author(s): serverOptimist
-- Date: 03/29/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

-- Modules
local CFrameModule = require( Knit.SharedModules.CFrameModule )

---------------------------------------------------------------------

local Movement = {}


-- Movement functions
function Movement.SetCFrame( self: table, cframe : CFrame, inertia: number ): nil
	-- Get speed before turn
	local prvSpd = self:FromSpeed(self.Spd)

	-- Apply rotation
	self.CFrame = cframe

	-- Apply inertia
	local rotSpd = self:ToSpeed(prvSpd)
	local invertia = 1 - inertia

	self.Spd.X = (self.Spd.X * invertia) + (rotSpd.X * inertia)
	self.Spd.Y = (self.Spd.Y * invertia) + (rotSpd.Y * inertia)
	self.Spd.Z = (self.Spd.Z * invertia) + (rotSpd.Z * inertia)
end

function Movement.SetCFrameCenter( self: table, cframe : CFrame, inertia: number ): nil
	Movement.SetCFrame(self, cframe + (self:FromSpeed({X = 0, Y = self.Parameters.Collision_Height, Z = 0}) * self.Parameters.Scale), inertia)
	Movement.SetCFrame(self, self.CFrame - self:FromSpeed({X = 0, Y = self.Parameters.Collision_Height, Z = 0}) * self.Parameters.Scale, 0)
end


function Movement.AlignGravity( self:table ): nil
	-- Rotate to gravity
	local nextRotation = CFrameModule.FromToRotation(self.CFrame.UpVector, -self.Gravity) * (self.CFrame - self.CFrame.p)
	Movement.SetCFrameCenter(self, nextRotation + self.CFrame.p, 1)
end


-- Turning functions
function Movement.Turn( self: table, turn: number, inertia: number ): nil
	-- Apply turn on Y axis
	Movement.SetCFrame(self, self.CFrame * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), turn), inertia)
end


function Movement.TurnY( self: table, turn: number ): nil
	--Get max turn
	local maxTurn = math.abs(turn)

	if maxTurn <= math.rad(45) then
		if maxTurn <= math.rad(22.5) then
			maxTurn /= 8
		else
			maxTurn /= 4
		end
	else
		maxTurn = math.rad(11.25)
	end

	--Get inertia
	local inertia
	if self.Flag.Grounded then
		if self:GetDotp() <= 0.4 then
			inertia = 0.5
		else
			inertia = 0.01
		end
	else
		inertia = 0.65
	end

	-- Perform turn
	Movement.Turn(self, math.clamp(turn, -maxTurn, maxTurn), inertia)
end


function Movement.TurnYQ( self: table, turn: number ): nil
	-- Perform turn
	Movement.Turn(self, math.clamp(turn, -math.rad(45), math.rad(45)), 1)
end


function Movement.TurnYS( self: table, turn: number ): nil
	-- Get max turn
	local maxTurn = math.rad(1.40625)
	if self.Spd.X > self.Parameters.Speed_Dash then
		maxTurn = math.max(maxTurn - (math.sqrt(((self.Spd.X - self.Parameters.Speed_Dash) * 0.0625)) * maxTurn), 0)
	end

	--Get inertia
	local inertia
	if self:GetDotp() <= 0.4 then
		inertia = 0.5
	else
		inertia = 0.01
	end

	-- Perform turn
	Movement.Turn(self, math.clamp(turn, -math.rad(1.40625), math.rad(1.40625)), inertia)
end


function Movement.TurnGravity( self: table ): nil
	local globalSpd = self:FromSpeed(self.Spd)

	if globalSpd.magnitude <= self.Parameters.Speed_Jog or (globalSpd.unit):Dot(self.Gravity.unit) >= -0.86 then
		local localGravity = self:ToSpeed(self.Gravity.unit)

		if localGravity.Y <= 0 and localGravity.Y > -0.73 then
			--Get turn
			local turn = -math.atan2(localGravity.Z, localGravity.X)
			if self.CFrame.LookVector:Dot(self.Gravity) < 0 then
				turn = -turn
			end

			--Get max turn
			if localGravity.Z < 0 then
				localGravity.Z = -localGravity.Z
			end

			local maxTurn
			if self.Flag.Ball then
				maxTurn = localGravity.Z * math.rad(16.875)
			else
				maxTurn = localGravity.Z * math.rad(8.4375)
			end

			--Turn
			Movement.Turn(self, math.clamp(turn, -maxTurn, maxTurn), 0)
		end
	end
end


-- Acceleration functions
function Movement.GetDecel( spd: number, dec: number ): nil
	if spd > 0 then
		return -math.min(spd, -dec)
	elseif spd < 0 then
		return math.min(-spd, -dec)
	end
	return 0
end


function Movement.Acceleration( self: table ): nil
	-- Get gravity force
	local acc = self:ToSpeed(self.Gravity * self.Parameters.Gravity)
	local dotp = self:GetDotp()

	-- Amplify gravity
	local speedRight = self.CFrame.UpVector:Cross(self:FromSpeed(self.Spd))

	local mul = 1
	if dotp > 0.625 then
		mul = 0.4
	elseif dotp > 0.45 then
		mul = 0.5
	end
	acc.X *= mul

	if dotp < 0.875 then
		if dotp >= 0.1 or math.abs(speedRight.Y) <= 0.6 or self.Spd.X < 1.16 then
			if dotp >= -0.4 or self.Spd.X <= 1.16 then
				if dotp < -0.3 and self.Spd.X > 1.16 then
					-- acc.Y += self.Parameters.Gravity * -0.8
				elseif dotp < -0.1 and self.Spd.X > 1.16 then
					-- acc.Y += self.Parameters.Gravity * -0.4
				elseif dotp < 0.5 and math.abs(self.Spd.X) < self.Parameters.Speed_Run then
					acc.X *= 4.225
					acc.Z *= 4.225
				elseif dotp >= 0.7 or math.abs(self.Spd.X) > self.Parameters.Speed_Run then
					if dotp >= 0.87 or math.abs(self.Spd.X) >= self.Parameters.Speed_Jog then
						acc.X *= 0.9
					else
						acc.X *= 0.85
						acc.Z *= 1.4
					end
				else
					acc.Z *= 2
				end
			else
				-- acc.Y += self.Parameters.Gravity * -5
			end
		else
			acc.Y = -self.Parameters.Gravity
		end
	else
		acc.Y = -self.Parameters.Gravity
	end

	-- X air drag
	if self.Spd.X <= self.Parameters.Ground_DragStart or dotp <= 0.96 then
		if self.Spd.X > self.Parameters.Ground_DragStart then
			acc.X += (self.Spd.X - self.Parameters.Ground_DragStart) * self.Parameters.Ground_Drag_X
		elseif self.Spd.X < 0 then
			acc.X += self.Spd.X * self.Parameters.Ground_Drag_X
		end
	else
		acc.X += (self.Spd.X - self.Parameters.Ground_DragStart) * (self.Parameters.Ground_Drag_X * 1.7)
	end

	-- YZ air drag
	self.Spd.Y += self.Spd.Y * self.Parameters.Air_Drag_Y
	self.Spd.Z += self.Spd.Z * self.Parameters.Ground_Drag_Z

	-- Movement
	local moveAccel

	if self.Input.Cmd.AnalogueMag ~= 0 then
		-- Get acceleration
		if self.Spd.X >= self.Parameters.Ground_DragStart then
			-- Use lower acceleration if above max speed
			if dotp >= 0 then
				moveAccel = self.Parameters.Ground_Acceleration * self.Input.Cmd.AnalogueMag * 0.3 --0.4
			else
				moveAccel = self.Parameters.Ground_Acceleration * self.Input.Cmd.AnalogueMag
			end
		else
			-- Get acceleration
			moveAccel = self.Parameters.Ground_Acceleration * self.Input.Cmd.AnalogueMag
		end

		-- Turning
		local diffAngle = math.abs(self.Input.Cmd.AnalogueTurn)

		if math.abs(self.Spd.X) < 0.001 and diffAngle > math.rad(22.5) then
			moveAccel = 0
			Movement.TurnYQ(self, self.Input.Cmd.AnalogueTurn)
		else
			if self.Spd.X < (self.Parameters.Speed_Jog + self.Parameters.Speed_Run) * 0.5 or diffAngle <= math.rad(22.5) then
				if self.Spd.X < self.Parameters.Speed_Jog or diffAngle >= math.rad(22.5) then
					if self.Spd.X < self.Parameters.Speed_Dash or not self.Flag.Grounded then
						-- Turning at low speed or in air
						if self.Spd.X >= self.Parameters.Speed_Jog and self.Spd.X <= self.Parameters.Speed_Rush and diffAngle > math.rad(45) then
							moveAccel *= 0.8
						end
						Movement.TurnY(self, self.Input.Cmd.AnalogueTurn)
					else
						-- Turning at high speed
						Movement.TurnYS(self, self.Input.Cmd.AnalogueTurn)
					end
				else
					-- Slightly turning at high speed
					Movement.TurnYS(self, self.Input.Cmd.AnalogueTurn)
				end
			else
				-- Sharply turning at high speed
				moveAccel = self.Parameters.Ground_Deceleration
				Movement.TurnY(self, self.Input.Cmd.AnalogueTurn)
			end
		end
	else
		-- Get deceleration towards 0
		if dotp > 0.98 then
			moveAccel = Movement.GetDecel(self.Spd.X + acc.X, self.Parameters.Ground_Deceleration)
		else
			moveAccel = Movement.GetDecel(self.Spd.X + acc.X, -self.Parameters.Ground_Acceleration)
		end
	end

	-- Friction
	acc.Z += Movement.GetDecel(self.Spd.Z + acc.Z, self.Parameters.Ground_Deceleration)

	-- Apply acceleration
	self.Spd.X += acc.X + moveAccel
	self.Spd.Y += acc.Y
	self.Spd.Z += acc.Z
	--print(self.Spd.X)
end


function Movement.Brake( self: table ): nil
	-- Get gravity force
	local acc = self:ToSpeed(self.Gravity * self.Parameters.Gravity)

	-- Air drag
	self.Spd.X += self.Spd.X * self.Parameters.Ground_Drag_X
	self.Spd.Y += self.Spd.Y * self.Parameters.Air_Drag_Y
	self.Spd.Z += self.Spd.Z * self.Parameters.Ground_Drag_Z

	-- Friction
	acc.X += Movement.GetDecel(self.Spd.X + acc.X, self.Parameters.Ground_Brake)
	acc.Z += Movement.GetDecel(self.Spd.Z + acc.Z, self.Parameters.Ground_Deceleration)

	-- Apply acceleration
	self.Spd.X += acc.X
	self.Spd.Y += acc.Y
	self.Spd.Z += acc.Z
end


function Movement.AirAcceleration( self: table ): nil
	-- Get gravity force
	local acc = self:ToSpeed(self.Gravity * self.Parameters.Gravity)

	-- Air drag
	self.Spd.X += self.Spd.X * self.Parameters.Air_Drag_X
	self.Spd.Y += self.Spd.Y * self.Parameters.Air_Drag_Y
	self.Spd.Z += self.Spd.Z * self.Parameters.Air_Drag_Z

	-- Movement
	local accel
	if self.Spd.X < -self.Parameters.Speed_Run and math.abs(self.Input.Cmd.AnalogueTurn) >= math.rad(135) then
		-- Turn to correct movement
		Movement.Turn(self, self.Input.Cmd.AnalogueTurn, 1)
		accel = 0
	elseif self.Spd.X <= self.Parameters.Speed_Run or math.abs(self.Input.Cmd.AnalogueTurn) <= math.rad(135) then
		-- Accelerate forwards
		if math.abs(self.Input.Cmd.AnalogueTurn) <= math.rad(22.5) then
			-- Accelerate faster moving down than moving up
			if self.Spd.Y >= 0 then
				accel = self.Parameters.Air_AccelerationUp * self.Input.Cmd.AnalogueMag
			else
				accel = self.Parameters.Air_AccelerationDown * self.Input.Cmd.AnalogueMag
			end
		else
			-- Don't accelerate when sharply turning
			accel = 0
		end

		-- Turn
		Movement.TurnY(self, self.Input.Cmd.AnalogueTurn)
	else
		-- Air braking
		accel = self.Parameters.Air_Brake * self.Input.Cmd.AnalogueMag
		self.Input.Cmd.AnalogueTurn = 0
	end

	-- Apply acceleration
	self.Spd.X += acc.X + accel
	self.Spd.Y += acc.Y
	self.Spd.Z += acc.Z
end

return Movement