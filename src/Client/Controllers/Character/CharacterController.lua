-- CharacterController
-- Author(s): Jesse Appleton
-- Date: 01/06/2022

--[[
	SIGNAL	CharacterController.CharacterAdded
	SIGNAL	CharacterController.CharacterTeleported

	FUNCTION	CharacterController:GetCharacter(): {}?
]]

---------------------------------------------------------------------


-- Constants
local TICK_HZ = 60 -- Physics calculation frequency

local NET_TICKS = 10 -- Network frequency
local NET_TIME = NET_TICKS / TICK_HZ

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Signal = require( Knit.Util.Signal )

-- Modules
local UIController = Knit.GetController( "UIController" )
local InputController = Knit.GetController( "InputController" )
local DataController = Knit.GetController( "DataController" )
local CharacterService = Knit.GetService( "CharacterService" )
local CharacterData = Knit.GameData.CharacterData
local CharacterHelper = require( Knit.SharedModules.Helpers.CharacterHelper )

-- Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService( "CollectionService" )

-- Variables
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local inStartMenu = false
local cameraPart = CollectionService:GetTagged("StarterCamera")[1]

-- Modules
local CharacterClass = require( Knit.SharedModules.Character )

---------------------------------------------------------------------

local CharacterController = Knit.CreateController {
	Name = "CharacterController";

	CharacterAdded = Signal.new();
	CharacterTeleported = Signal.new();
	StatsChanged = Signal.new();

	InputDisabled = false;
}


-- Helper Local Functions
local function CalculateStatsByLevel( level: number ): ( {} )
	local data: {} = CharacterHelper.GetStatsForLevel( level )

	local newStats = {
		Speed = data.Speed,
		Acceleration = data.Acceleration,
		Ground_DragStart = data.Drag,
		Power = data.Power,
		Stamina = data.Stamina,
		Level = data.Level,
		Rebirths = data.Rebirths
	}

	local speedPercent = false --Placeholder
	if ( speedPercent ) then
		speedPercent = math.clamp( speedPercent, 1, 100 ) / 100
		newStats.Speed = math.max( newStats.Speed*speedPercent, minData.Speed )
		newStats.Acceleration = math.max( newStats.Acceleration*speedPercent, minData.Acceleration )
		newStats.Ground_DragStart = math.max( newStats.Ground_DragStart*speedPercent, minData.Drag )
	end

	return newStats
end


function CharacterController:SetInputDisabled( disabled: boolean ): ()
	self.InputDisabled = not not disabled
end


function CharacterController:KnitStart(): ()
	local resetBindable: BindableEvent = Instance.new( "BindableEvent" )
	resetBindable.Event:Connect(function()
		self:TriggerDied()
	end)
	local function SetResetCallback(): ( boolean )
		return pcall(function()
			game:GetService( "StarterGui" ):SetCore( "ResetButtonCallback", resetBindable )
		end)
	end
	task.spawn(function()
		-- StarterGui isn't guaranteed to be ready to set core
		repeat until ( SetResetCallback() ) or ( not task.wait() )
	end)

	--New method of the server informing the CharacterController
	CharacterService.CharacterAdded:Connect(function( character: Model, characterName: string, spawnCFrame: CFrame )
		if ( CurrentCamera.CameraSubject ~= character.Humanoid ) then
			CurrentCamera.CameraSubject = character.Humanoid
		end

		character.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		print(spawnCFrame)
		self:_setCharacter( character, characterName, spawnCFrame )
	end)

	local function TeleportCharacter( targetCFrame: CFrame, resetState: boolean ? ): nil
		self:TeleportCharacter( targetCFrame, resetState )
	end
	CharacterService.TeleportCharacter:Connect( TeleportCharacter )

	local function StatSettingChanged(): ()
		if ( self._character ) then
			local newStats = CalculateStatsByLevel( DataController:GetDataByName("Level") )
			self._character:SetStats( newStats )
		end
	end
	LocalPlayer.CharacterRemoving:Connect(function( character: Model )
		self:_setCharacter( nil )
	end)

	-- Attach character updates to RenderStep
	RunService:BindToRenderStep("CharacterController", Enum.RenderPriority.Input.Value, function(dt)
		if self._character == nil or self._characterRender == nil then
			return
		end

		-- Get input state from controller
		if not ( inStartMenu ) then
			if ( InputController:IsGameFocused() ) then
				self._character.Input:SetState(InputController:GetMoveVector(), InputController:GetButtons())
			else
				-- No input
				self._character.Input:SetState(Vector3.new(), {})
			end
		end

		-- Update controller at TICK_HZ
		self._ticker += dt * TICK_HZ

		while self._ticker >= 1 do
			-- Tick character physics and render
			self._totalTicks += 1
			self._character:Tick( self._totalTicks )
			self._characterRender:Tick(self._character)

			--[[if ( Knit.IsStudio ) then
				local tester_gui = LocalPlayer.PlayerGui:FindFirstChild("ControllerValues")
				local cheat_check = (tester_gui.Enabled == true and tester_gui.ValueTable.Table.ScrollingFrame.Values.StatCheat.Value.TextBox) or "false"
				if tester_gui ~= nil and cheat_check.Text == "true" then
					-- Get stats
					local stats = {}
					for _,v in pairs(tester_gui.ValueTable.Table.ScrollingFrame.Values:GetChildren()) do
						if v:IsA("Frame") then
							if not (v.Name == 'StatCheat' ) then
								stats[v.Name] = tonumber(v.Value.TextBox.Text) or 0.1
							end
						end
					end

					-- Set controller stats
					self._character:SetStats(stats)
				end
			end]]

			-- Send network packets
			self._network.Ticks -= 1

			if self._network.Ticks <= 0 then
				-- Send network packet
				CharacterService.UpdateCharacterState:Fire({
					Character = LocalPlayer.Character;
					CFrame = self._characterRender.HumanoidRootPart.CFrame;
					IsRunning = self._character.Flag.Grounded and (not self._character.Flag.Ball);
				})

				-- Reset ticker
				self._network.Ticks = NET_TICKS
			end

			-- Decrement ticker until requested ticks have been completed
			self._ticker -= 1
		end

		-- Render character
		self._characterRender:Render(self._ticker)
	end)

	-- Attach to network event
	local tweenInfo = TweenInfo.new(NET_TIME, Enum.EasingStyle.Linear)

	CharacterService.UpdateCharacterState:Connect(function(character, cframe)
		local part = character.HumanoidRootPart

		local tween = TweenService:Create(part, tweenInfo, {CFrame = cframe})
		tween.Destroying:Connect(function()
			if self._network.Tweens[part] == tween then
				self._network.Tweens[part] = nil
			end
		end)

		local prevTween = self._network.Tweens[part]
		if prevTween ~= nil then
			prevTween:Cancel()
			tween:Play()
			self._network.Tweens[part] = tween
			prevTween:Destroy()
		else
			tween:Play()
			self._network.Tweens[part] = tween
		end
	end)
end


function CharacterController:KnitInit(): nil
	
end


function CharacterController:GetCharacter(): ( {}? )
	return self._character
end


function CharacterController:TriggerDied(): ()
	-- Pause the controller
	CharacterService.CharacterDied:Fire()
end


function CharacterController:TeleportCharacter( targetCFrame: CFrame, resetState: boolean? ): ()
	local character = self:GetCharacter()

	if ( character ~= nil ) then
		self:SetInputDisabled( true )

		character:SetState(require( character.States.Idle ).new(character) )
		character.CFrame = targetCFrame
		character:ClearDie()
		self.CharacterTeleported:Fire( targetCFrame )

		if ( resetState == true ) then
			character.Spd = {X = 0, Y = 0, Z = 0}
			character.Gravity = CharacterData.DefaultGravity
		end

		task.wait( 1 )
		inStartMenu = (Knit.LocalPlayer:GetAttribute("StartMenuMode") and true ) or false
		if not ( inStartMenu ) then
			local camera: Camera = workspace.CurrentCamera
			CurrentCamera.FieldOfView = 70
			camera.CameraType = "Custom"
			local cameraOffset: number = ( camera.CFrame.Position - camera.Focus.Position ).Magnitude

			camera.CFrame = self._characterRender.HumanoidRootPart.CFrame * CFrame.new( 0, cameraOffset, cameraOffset )
		else
			CurrentCamera.CameraType = "Scriptable"
			cameraPart = CollectionService:GetTagged("StarterCamera")[1]
			CurrentCamera.CFrame = cameraPart.CFrame
			CurrentCamera.FieldOfView = 50
		end
		self:SetInputDisabled( false )
	end
end


-- Private functions
function CharacterController:_setCharacter( character: Model, characterName: string, spawnCFrame: CFrame ): ()
	-- Destroy previous character
	if self._characterRender ~= nil then
		self._characterRender:Destroy()
		self._characterRender = nil
	end
	if self._character ~= nil then
		self._character:Destroy()
		self._character = nil
	end

	if character ~= nil then
		-- Initialize ticker
		self._ticker = 0
		self._totalTicks = 0

		--local characterData: {} = CharacterHelper.GetDataByName( characterName )

		local characterData: {} = CharacterHelper.GetDataByName( characterName )
		-- Create character render instance
		self._characterRender = require( Knit.Modules.CharacterRender ).new(
			character,
			characterData.Folder,
			require( Knit.Modules.CharacterRender[characterData.RigType] )
		)

		-- Disable humanoid processing
		local humanoid: Humanoid = self._characterRender.Humanoid
		local statesToEnable: {[Enum.HumanoidStateType]: boolean} = {
			[ Enum.HumanoidStateType.None ] = true;
			[ Enum.HumanoidStateType.Dead ] = true;
			[ Enum.HumanoidStateType.Physics ] = true;
		}
		for _, enum: Enum.HumanoidStateType in pairs( Enum.HumanoidStateType:GetEnumItems() ) do
			if ( not statesToEnable[enum] ) then
				humanoid:SetStateEnabled( enum, false )
			end
		end
		humanoid:ChangeState( Enum.HumanoidStateType.Physics )

		-- Create character instance
		self._character = CharacterClass.new( spawnCFrame )
		self.CharacterAdded:Fire( self._character )

		-- Initialize network state
		self._network = {
			Ticks = 0, -- Ticks left until send
			Tweens = {}, -- Currently running tweens
		}
	end
end


function CharacterController._netUpdate()

end


return CharacterController