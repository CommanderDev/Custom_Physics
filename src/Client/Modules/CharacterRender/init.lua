-- CharacterRender
-- Author(s): Jesse Appleton
-- Date: 01/08/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants
local ANIM_TIES = {
	["Walk"] = {["Walk"] = true, ["Jog"] = true, ["Run"] = true},
	["Jog"]  = {["Walk"] = true, ["Jog"] = true, ["Run"] = true},
	["Run"]  = {["Walk"] = true, ["Jog"] = true, ["Run"] = true},
}

local ANIM_TILT = {
	["Walk"] = 0.2,
	["Jog"] = 0.8,
	["Run"] = 1,

	["Jump"] = 1,
	["Fall"] = 1
}

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local CharacterRender = {}
CharacterRender.__index = CharacterRender


-- Constructor and destructor
function CharacterRender.new( character: Model, assets: Folder, rig: table ): table
	print("Created new character render!")
	local self = setmetatable( {}, CharacterRender )
	self._janitor = Janitor.new()

	-- Get character objects
	self.Character = character
	print(character)
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")
	self.HumanoidRootPart.Anchored = true

	-- Get tick CFrames
	self._fromCFrame = self.HumanoidRootPart.CFrame
	self._toCFrame = self._fromCFrame

	-- Load sounds
	self._sound = {
		Play = {},
		Stop = {}
	}

	local function RegisterSounds( ... )
		local result = {}
		for _,k in pairs({...}) do
			for _,v in ipairs(k:GetChildren()) do
				if v:IsA("Sound") then
					result[v.Name] = v
				end
			end
		end
		return result
	end

	self._sounds = RegisterSounds(Knit.Assets.General.Sounds, assets.Sounds)
	self._soundOrigins = {}

	-- Load animations
	self._animations = {}
	self._animation = nil

	self._animationTracks = {}

	for _,v in ipairs(assets.Animations:GetChildren()) do
		-- Load animation onto humanoid and push to animation table
		local animation = self.Humanoid:LoadAnimation(v)
		self._janitor:Add(animation)
		self._animations[v.Name] = animation

		-- Connect footsteps
		local function OnStep()
			-- Play step sound
			if animation.WeightCurrent >= 0.5 then
				table.insert(self._sound.Play, {
					Origin = self.HumanoidRootPart,
					Name = "Walk"..tostring(math.random(1, 5)),
					Volume = math.abs(animation.Speed * 0.65) ^ 0.5,
					Pitch = 1
				})
			end
		end

		self._janitor:Add(animation:GetMarkerReachedSignal("LStep"):Connect(OnStep))
		self._janitor:Add(animation:GetMarkerReachedSignal("RStep"):Connect(OnStep))
	end

	-- Load rig system
	self._rig = rig.new(self)
	self._tilt = 0

	-- Find effects
	local jumpEffect = self.HumanoidRootPart:FindFirstChild("JumpEffect")
	if jumpEffect ~= nil then
		self._jumpEffect = jumpEffect:GetChildren()
	else
		self._jumpEffect = {}
	end

	return self
end


function CharacterRender:Destroy(): nil
	self._janitor:Destroy()
end


-- Public functions
function CharacterRender:Tick( character: table ): nil
	-- Set tick CFrames
	self._fromCFrame = self._toCFrame
	self._toCFrame = character.CFrame * CFrame.new(0, self:_getHipHeight(), 0)

	-- Smooth rotation
	local fromRotate = self._fromCFrame - self._fromCFrame.p
	local toRotate = self._toCFrame - self._toCFrame.p
	self._toCFrame = fromRotate:Lerp(toRotate, 0.2) + self._toCFrame.p

	-- Change playing animation
	if character.Animation.New ~= nil then
		-- Play new tracks
		if ANIM_TIES[character.Animation.New] ~= nil then
			-- Check if playing a new tie
			if self._animation == nil or ANIM_TIES[character.Animation.New][self._animation] == nil then
				-- Stop previous tracks
				for _,v in pairs(self._animationTracks) do
					v:Stop()
				end

				-- Play new tracks
				self._animationTracks = {}
				for i,_ in pairs(ANIM_TIES[character.Animation.New]) do
					local track = self._animations[i]
					if track ~= nil then
						track:Play()
						self._animationTracks[i] = track
					end
				end
			end

			-- Set playing track
			self._animation = character.Animation.New
		else
			-- Stop previous tracks
			for _,v in pairs(self._animationTracks) do
				v:Stop()
			end

			-- Play new track
			self._animation = character.Animation.New

			local track = self._animations[self._animation]
			if track ~= nil then
				track:Play()
				self._animationTracks = {[self._animation] = track}
			end
		end

		-- Change animation weights
		for i,v in pairs(self._animationTracks) do
			v:AdjustWeight((i == self._animation) and 1 or 0.001)
		end
	end

	-- Change animation speeds
	for i,v in pairs(self._animationTracks) do
		v:AdjustSpeed(character.Animation.Speed)
	end

	-- Interpolate dynamic tilt
	local tgtTilt = (character.Animation.Turn / math.pi) * (ANIM_TILT[self._animation] or 0)
	tgtTilt = (math.abs(tgtTilt) ^ 0.5) * math.sign(tgtTilt)

	self._tilt += (tgtTilt - self._tilt) * 0.2

	-- Update sounds
	local function GetOrigin( origin )
		-- Get origin as instance
		if origin == nil then
			origin = workspace.CurrentCamera
		elseif origin == character then
			origin = self.HumanoidRootPart
		end

		-- Create origin table if didn't exist
		if self._soundOrigins[origin] == nil then
			self._soundOrigins[origin] = {}
		end
		return origin
	end

	local function SoundPlay(v)
		-- Get origin and base sound
		local origin = GetOrigin(v.Origin)
		local soundOrigin = self._soundOrigins[origin]

		local baseSound = self._sounds[v.Name]
		if baseSound == nil then
			return
		end

		-- Get or create sound in origin
		local sound = soundOrigin[v.Name]
		if sound == nil then
			sound = baseSound:Clone()
			sound.Parent = origin
			soundOrigin[v.Name] = sound
			self._janitor:Add(sound)
		end

		-- Set sound parameters then play
		sound.Volume = baseSound.Volume * v.Volume
		sound.PlaybackSpeed = baseSound.Pitch * v.Pitch
		sound:Play()
	end

	local function SoundStop(v)
		-- Get origin
		local origin = GetOrigin(v.Origin)
		local soundOrigin = self._soundOrigins[origin]

		-- Get sound in origin and stop
		local sound = soundOrigin[v.Name]
		if sound ~= nil then
			sound:Stop()
		end
	end

	for _,v in ipairs(character.Sound.Play) do
		SoundPlay(v)
	end
	for i,v in ipairs(self._sound.Play) do
		SoundPlay(v)
		self._sound.Play[i] = nil
	end

	for _,v in ipairs(character.Sound.Stop) do
		SoundStop(v)
	end
	for i,v in ipairs(self._sound.Stop) do
		SoundStop(v)
		self._sound.Stop[i] = nil
	end

	-- Update effects
	self._jumpEffectActive = (self._animation == "Roll") or (self._animation == "SpindashCharge")
end


function CharacterRender:Render( alpha: number ): nil
	-- Get tick CFrames
	local fromCFrame = self._fromCFrame
	local toCFrame = self._toCFrame

	-- Move character to interpolated CFrame
	self.HumanoidRootPart.CFrame = fromCFrame:Lerp(toCFrame, alpha)
	--self.Character.RightUpperArm.Orientation = Vector3.new(0,90,0)
	-- Apply dynamic tilt to rig
	self._rig:ApplyTilt(self._tilt)

	-- Update effects
	for _,v in ipairs(self._jumpEffect) do
		v.Enabled = self._jumpEffectActive
	end
end


-- Private functions
function CharacterRender:_getHipHeight(): nil
	-- This is the Y that has to be added to align the character with the floor
	return self.Humanoid.HipHeight + (self.HumanoidRootPart.Size.Y * 0.5)
end


return CharacterRender