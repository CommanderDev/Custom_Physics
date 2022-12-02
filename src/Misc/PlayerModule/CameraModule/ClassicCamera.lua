--[[
	ClassicCamera - Classic Roblox camera control module
	2018 Camera Update - AllYourBlox

	Note: This module also handles camera control types Follow and Track, the
	latter of which is currently not distinguished from Classic
--]]

-- Local private variables and constants
local ZERO_VECTOR2 = Vector2.new(0,0)

local tweenAcceleration = math.rad(220) -- Radians/Second^2
local tweenSpeed = math.rad(0)          -- Radians/Second
local tweenMaxSpeed = math.rad(250)     -- Radians/Second
local TIME_BEFORE_AUTO_ROTATE = 2       -- Seconds, used when auto-aligning camera with vehicles

local INITIAL_CAMERA_ANGLE = CFrame.fromOrientation(math.rad(-15), 0, 0)
local ZOOM_SENSITIVITY_CURVATURE = 0.5
local FIRST_PERSON_DISTANCE_MIN = 0.5

--[[ Services ]]--
local VectorModule = require( game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("VectorModule") )

local PlayersService = game:GetService("Players")
local VRService = game:GetService("VRService")

local CameraInput = require(script.Parent:WaitForChild("CameraInput"))
local Util = require(script.Parent:WaitForChild("CameraUtils"))

--[[ The Module ]]--
local BaseCamera = require(script.Parent:WaitForChild("BaseCamera"))
local ClassicCamera = setmetatable({}, BaseCamera)
ClassicCamera.__index = ClassicCamera

function ClassicCamera.new()
	local self = setmetatable(BaseCamera.new(), ClassicCamera)

	self.isFollowCamera = false
	self.isCameraToggle = false
	self.lastUpdate = tick()
	self.cameraToggleSpring = Util.Spring.new(5, 0)

	self.cameraSlopeSpring = Util.Spring.new(1.5, 0)

	return self
end

function ClassicCamera:GetCameraToggleOffset(dt: number)
	if self.isCameraToggle then
		local zoom = self.currentSubjectDistance

		if CameraInput.getTogglePan() then
			self.cameraToggleSpring.goal = math.clamp(Util.map(zoom, 0.5, self.FIRST_PERSON_DISTANCE_THRESHOLD, 0, 1), 0, 1)
		else
			self.cameraToggleSpring.goal = 0
		end

		local distanceOffset: number = math.clamp(Util.map(zoom, 0.5, 64, 0, 1), 0, 1) + 1
		return Vector3.new(0, self.cameraToggleSpring:step(dt)*distanceOffset, 0)
	end

	return Vector3.new()
end

-- Movement mode standardized to Enum.ComputerCameraMovementMode values
function ClassicCamera:SetCameraMovementMode(cameraMovementMode: Enum.ComputerCameraMovementMode)
	BaseCamera.SetCameraMovementMode(self, cameraMovementMode)

	self.isFollowCamera = cameraMovementMode == Enum.ComputerCameraMovementMode.Follow
	self.isCameraToggle = cameraMovementMode == Enum.ComputerCameraMovementMode.CameraToggle
end

function ClassicCamera:Update()
	local now = tick()
	local timeDelta = now - self.lastUpdate
	if timeDelta <= 0 then
		return
	end

	local camera = workspace.CurrentCamera
	local newCameraCFrame = camera.CFrame
	local newCameraFocus = camera.Focus

	local overrideCameraLookVector = nil
	if self.resetCameraAngle then
		local rootPart: BasePart = self:GetHumanoidRootPart()
		if rootPart then
			overrideCameraLookVector = (rootPart.CFrame * INITIAL_CAMERA_ANGLE).lookVector
		else
			overrideCameraLookVector = INITIAL_CAMERA_ANGLE.lookVector
		end
		self.resetCameraAngle = false
	end

	local player = PlayersService.LocalPlayer
	local humanoid = self:GetHumanoid()
	local cameraSubject = camera.CameraSubject
	local isInVehicle = false--cameraSubject and cameraSubject:IsA("VehicleSeat")
	local isOnASkateboard = false--cameraSubject and cameraSubject:IsA("SkateboardPlatform")
	local isClimbing = false--humanoid and humanoid:GetState() == Enum.HumanoidStateType.Climbing

	if self.lastUpdate == nil or timeDelta > 1 then
		self.lastCameraTransform = nil
	end

	local rootLook = (humanoid ~= nil) and humanoid.RootPart or nil
	if rootLook ~= nil then
		rootLook = rootLook.CFrame.LookVector
	end
	
	local rotateInput = CameraInput.getRotation()

	self:StepZoom()

	local cameraHeight = self:GetCameraHeight()

	-- Reset tween speed if user is panning
	if CameraInput.getRotation() ~= Vector2.new() then
		tweenSpeed = 0
		self.lastUserPanCamera = tick()
	end

	local userRecentlyPannedCamera = now - self.lastUserPanCamera < TIME_BEFORE_AUTO_ROTATE
	local subjectPosition: Vector3 = self:GetSubjectPosition()

	if subjectPosition and player and camera then
		local zoom = self:GetCameraToSubjectDistance()
		if zoom < 0.5 then
			zoom = 0.5
		end

		local cameraSlope = nil
		if self:GetIsMouseLocked() and not self:IsInFirstPerson() then
			-- We need to use the right vector of the camera after rotation, not before
			local newLookCFrame: CFrame = self:CalculateNewLookCFrameFromArg(overrideCameraLookVector, rotateInput)

			local offset: Vector3 = self:GetMouseLockOffset()
			local cameraRelativeOffset: Vector3 = offset.X * newLookCFrame.rightVector + offset.Y * newLookCFrame.upVector + offset.Z * newLookCFrame.lookVector

			--offset can be NAN, NAN, NAN if newLookVector has only y component
			if Util.IsFiniteVector3(cameraRelativeOffset) then
				subjectPosition = subjectPosition + cameraRelativeOffset
			end
		else
			local userPanningTheCamera = CameraInput.getRotation() ~= Vector2.new()

			if not userPanningTheCamera and self.lastCameraTransform then

				local isInFirstPerson = self:IsInFirstPerson()

				if (isInVehicle or isOnASkateboard or (self.isFollowCamera and isClimbing)) and self.lastUpdate and humanoid and humanoid.Torso then
					if isInFirstPerson then
						if self.lastSubjectCFrame and (isInVehicle or isOnASkateboard) and cameraSubject:IsA("BasePart") then
							local y = -Util.GetAngleBetweenXZVectors(self.lastSubjectCFrame.lookVector, cameraSubject.CFrame.lookVector)
							if Util.IsFinite(y) then
								rotateInput = rotateInput + Vector2.new(y, 0)
							end
							tweenSpeed = 0
						end
					elseif not userRecentlyPannedCamera then
						local forwardVector = humanoid.Torso.CFrame.lookVector
						tweenSpeed = math.clamp(tweenSpeed + tweenAcceleration * timeDelta, 0, tweenMaxSpeed)

						local percent = math.clamp(tweenSpeed * timeDelta, 0, 1)
						if self:IsInFirstPerson() and not (self.isFollowCamera and self.isClimbing) then
							percent = 1
						end

						local y = Util.GetAngleBetweenXZVectors(forwardVector, self:GetCameraLookVector())
						if Util.IsFinite(y) and math.abs(y) > 0.0001 then
							rotateInput = rotateInput + Vector2.new(y * percent, 0)
						end
					end

				elseif self.isFollowCamera and (not (isInFirstPerson or userRecentlyPannedCamera) and not VRService.VREnabled) then
					-- Logic that was unique to the old FollowCamera module
					local lastVec = -(self.lastCameraTransform.p - subjectPosition)
					local moveVec
					if self.subjectDelta ~= nil then
						moveVec = self.subjectDelta / timeDelta
					else
						moveVec = Vector3.new()
					end

					local moveNum
					if rootLook ~= nil then
						moveNum = moveVec:Dot(rootLook)
					else
						moveNum = 0
					end

					local y = Util.GetAngleBetweenXZVectors(lastVec, self:GetCameraLookVector())
					y /= math.max(math.abs(moveNum) / 64, 1)

					-- This cutoff is to decide if the humanoid's angle of movement,
					-- relative to the camera's look vector, is enough that
					-- we want the camera to be following them. The point is to provide
					-- a sizable dead zone to allow more precise forward movements.
					local thetaCutoff = 0.4

					-- Check for NaNs
					if Util.IsFinite(y) and math.abs(y) > 0.0001 and math.abs(y) > thetaCutoff * timeDelta then
						rotateInput = rotateInput + Vector2.new(y, 0)
					end

					-- Get the slope vector
					if rootLook ~= nil then
						local slopeVector = rootLook
						local moveMag = moveVec.magnitude
						if moveMag > 24 then
							slopeVector = slopeVector:Lerp(moveVec.unit, math.min((moveMag - 24) / 24, 1))
						end

						-- Project vectors
						local curLook = self:GetCameraLookVector()
						local lookProject = VectorModule.PlaneProject(curLook, Vector3.new(0, 1, 0))
						if lookProject.magnitude ~= 0 then
							lookProject = lookProject.unit
						end

						local slopeProject = VectorModule.PlaneProject(slopeVector, Vector3.new(0, 1, 0))
						local side
						if slopeProject.magnitude ~= 0 then
							slopeProject = slopeProject.unit
							side = slopeProject:Cross(Vector3.new(0, 1, 0))
						else
							side = Vector3.new()
						end

						-- Get target angle
						local parallel = math.clamp(lookProject:Dot(side), -1, 1)
						local parallelInvert = math.cos(math.asin(parallel))
						local target = math.atan2(slopeVector.Y, math.sqrt(slopeVector.X * slopeVector.X + slopeVector.Z * slopeVector.Z)) * parallelInvert
						cameraSlope = math.clamp(target * 0.75 - math.rad(11), math.rad(-45), math.rad(38))
					end
				end
			end
		end

		-- Apply slope look
		local curLook = self:GetCameraLookVector()
		local curSlope = math.atan2(curLook.Y, math.sqrt(curLook.X * curLook.X + curLook.Z * curLook.Z))

		if cameraSlope ~= nil then
			self.cameraSlopeSpring.goal = cameraSlope
			self.cameraSlopeSpring:step(timeDelta)
			rotateInput = rotateInput + Vector2.new(0, -(self.cameraSlopeSpring.pos - curSlope))
		else
			self.cameraSlopeSpring.pos = curSlope
			self.cameraSlopeSpring.goal = curSlope
			self.cameraSlopeSpring.vel = 0
		end

		if not self.isFollowCamera then
			local VREnabled = VRService.VREnabled

			if VREnabled then
				newCameraFocus = self:GetVRFocus(subjectPosition, timeDelta)
			else
				newCameraFocus = CFrame.new(subjectPosition)
			end

			local cameraFocusP = newCameraFocus.p
			if VREnabled and not self:IsInFirstPerson() then
				local vecToSubject = (subjectPosition - camera.CFrame.p)
				local distToSubject = vecToSubject.magnitude

				local flaggedRotateInput = rotateInput

				-- Only move the camera if it exceeded a maximum distance to the subject in VR
				if distToSubject > zoom or flaggedRotateInput.x ~= 0 then
					local desiredDist = math.min(distToSubject, zoom)
					vecToSubject = self:CalculateNewLookVectorFromArg(nil, rotateInput) * desiredDist
					local newPos = cameraFocusP - vecToSubject
					local desiredLookDir = camera.CFrame.lookVector
					if flaggedRotateInput.x ~= 0 then
						desiredLookDir = vecToSubject
					end
					local lookAt = Vector3.new(newPos.x + desiredLookDir.x, newPos.y, newPos.z + desiredLookDir.z)

					newCameraCFrame = CFrame.new(newPos, lookAt) + Vector3.new(0, cameraHeight, 0)
				end
			else
				local newLookVector = self:CalculateNewLookVectorFromArg(overrideCameraLookVector, rotateInput)
				newCameraCFrame = CFrame.new(cameraFocusP - (zoom * newLookVector), cameraFocusP)
			end
		else -- is FollowCamera
			local newLookVector = self:CalculateNewLookVectorFromArg(overrideCameraLookVector, rotateInput)

			if VRService.VREnabled then
				newCameraFocus = self:GetVRFocus(subjectPosition, timeDelta)
			else
				newCameraFocus = CFrame.new(subjectPosition)
			end
			newCameraCFrame = CFrame.new(newCameraFocus.p - (zoom * newLookVector), newCameraFocus.p) + Vector3.new(0, cameraHeight, 0)
		end

		local toggleOffset = self:GetCameraToggleOffset(timeDelta)
		newCameraFocus = newCameraFocus + toggleOffset
		newCameraCFrame = newCameraCFrame + toggleOffset

		self.lastCameraTransform = newCameraCFrame
		self.lastCameraFocus = newCameraFocus
		if cameraSubject:IsA("BasePart") then
			self.lastSubjectCFrame = cameraSubject.CFrame
		else
			self.lastSubjectCFrame = nil
		end
		--self.lastSubjectPosition = subjectPosition
	end

	self.lastUpdate = now
	return newCameraCFrame, newCameraFocus
end

function ClassicCamera:EnterFirstPerson()
	self.inFirstPerson = true
	self:UpdateMouseBehavior()
end

function ClassicCamera:LeaveFirstPerson()
	self.inFirstPerson = false
	self:UpdateMouseBehavior()
end

return ClassicCamera
