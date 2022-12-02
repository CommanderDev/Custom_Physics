-- InputController
-- Author(s): Jesse Appleton
-- Date: 01/06/2022

--[[
	
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Modules
local MobileButtons = Knit.GetController( "MobileButtons" )

-- Roblox Services
local UserInputService = game:GetService("UserInputService")

-- Variables

---------------------------------------------------------------------

local InputController = Knit.CreateController { Name = "InputController" }


function InputController:KnitStart(): nil
	-- Input state
	self._gamepadMoveVector = Vector2.new()
	self._inputDigital = {}

	-- Connect to touch UI
	local function OnInputChanged( inputName: string, state: boolean ): ()
		self._inputDigital[ inputName ] = state
	end
	MobileButtons.InputChanged:Connect( OnInputChanged )

	-- Connect to input events
	local function InputEvent(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			-- Digital input state
			if input.UserInputState == Enum.UserInputState.Begin then
				self._inputDigital[input.KeyCode] = true
			elseif input.UserInputState == Enum.UserInputState.End then
				self._inputDigital[input.KeyCode] = false
			end
		elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
			if input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if gameProcessed then
					self._gamepadMoveVector = Vector2.new()
					return
				end
				-- Left thumbstick move vector
				self._gamepadMoveVector = self:_applyDeadzone(Vector2.new(input.Position.X, input.Position.Y), 0.2)
			elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
				-- TODO: Camera controls?
			else
				if ( gameProcessed ) then
					self._inputDigital[ input.KeyCode ] = false
					return
				end
				-- Digital input state
				if input.UserInputState == Enum.UserInputState.Begin then
					self._inputDigital[input.KeyCode] = true
				elseif input.UserInputState == Enum.UserInputState.End then
					self._inputDigital[input.KeyCode] = false
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(InputEvent)
	UserInputService.InputChanged:Connect(InputEvent)
	UserInputService.InputEnded:Connect(InputEvent)
end


function InputController:KnitInit(): nil
	self.MobileInputController = Knit.GetController( "MobileInputController" )
end


-- Public functions
function InputController:IsGameFocused(): boolean
	if UserInputService:GetFocusedTextBox() ~= nil then
		return false
	end
	return true
end


function InputController:GetMoveVector(): Vector2
	-- Get keyboard move vector
	local keyboardMoveVector = Vector2.new()

	if self._inputDigital[Enum.KeyCode.W] or self._inputDigital[Enum.KeyCode.Up] then
		keyboardMoveVector += Vector2.new(0, 1)
	end
	if self._inputDigital[Enum.KeyCode.A] or self._inputDigital[Enum.KeyCode.Left] then
		keyboardMoveVector -= Vector2.new(1, 0)
	end
	if self._inputDigital[Enum.KeyCode.S] or self._inputDigital[Enum.KeyCode.Down] then
		keyboardMoveVector -= Vector2.new(0, 1)
	end
	if self._inputDigital[Enum.KeyCode.D] or self._inputDigital[Enum.KeyCode.Right] then
		keyboardMoveVector += Vector2.new(1, 0)
	end

	if keyboardMoveVector.magnitude > 1 then
		keyboardMoveVector = keyboardMoveVector.unit
	end
	-- Return final move vector
	return keyboardMoveVector + self._gamepadMoveVector + self.MobileInputController.MoveVector
end


function InputController:GetButtons(): table
	-- TODO: this is messy
	return {
		Jump = (self._inputDigital[Enum.KeyCode.Space] or self._inputDigital[Enum.KeyCode.ButtonA] or self._inputDigital["TouchJump"]) and true or false,
	}
end

-- Private functions
function InputController:_applyDeadzone( vector: Vector2, zone: number ): Vector2
	if math.abs(vector.Magnitude) < zone then
		return Vector2.new()
	elseif vector.Magnitude > 1 then
		return vector.Unit
	else
		return vector.Unit * ((vector.magnitude - zone) / (1 - zone))
	end
end

return InputController