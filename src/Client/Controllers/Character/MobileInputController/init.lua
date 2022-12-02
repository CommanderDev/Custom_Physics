-- MobileInputController
-- Author(s): Jesse Appleton
-- Date: 01/18/2022

--[[
    MEMBER      MobileInputController.MoveVector: Vector2
    SIGNAL      MobileInputController.MoveVectorChanged     ->      moveVector: Vector2

    MEMBER      MobileInputController.Enabled: boolean
    SIGNAL      MobileInputController.EnabledChanged        ->      boolean
]]

---------------------------------------------------------------------


-- Constants
local ZERO_VECTOR2 = Vector2.new()
local ENUM_TO_TOUCH_MODULE = {
    [ Enum.TouchMovementMode.DynamicThumbstick ] = require( script.DynamicThumbstick );
    [ Enum.TouchMovementMode.Thumbstick ] = require( script.TouchThumbstick );
}

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Signal = require( Knit.Util.Signal )

-- Modules
local UIController = Knit.GetController( "UIController" )

-- Roblox Services
local UserInputService = game:GetService( "UserInputService" )
local UserGameSettings = UserSettings():GetService( "UserGameSettings" )

-- Variables
local LocalPlayer: Player = Knit.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer:WaitForChild( "PlayerGui" )

---------------------------------------------------------------------

local MobileInputController = Knit.CreateController {
    Name = "MobileInputController";

    MoveVector = Vector2.new();
    MoveVectorChanged = Signal.new();
    _moveVectorChangedConnection = nil;

    Controllers = {};
    ActiveController = nil;
    ActiveControllerChanged = Signal.new();
    ActiveControlModule = nil;

    Enabled = false;
    EnabledChanged = Signal.new();
}


function MobileInputController:GetDynamicThumbstickController(): ( {}? )
    return self.Controllers[ ENUM_TO_TOUCH_MODULE[Enum.TouchMovementMode.DynamicThumbstick] ]
end


function MobileInputController:_selectTouchModule(): ( {}?, boolean )
	if ( not UserInputService.TouchEnabled ) then
		return nil, false
    else
        local movementMode = UserGameSettings.TouchMovementMode
        return ENUM_TO_TOUCH_MODULE[ movementMode ] or ENUM_TO_TOUCH_MODULE[ Enum.TouchMovementMode.DynamicThumbstick ], true
    end
end


function MobileInputController:_updateTouchVisibility(): ()
    if ( self.touchGui ) then
        -- Ensure that mobile hud UI does not appear when we are still in the start menu
        local inStartMenu = not not Knit.LocalPlayer:GetAttribute( "StartMenuMode" )
        local inScreen: boolean = not not UIController.Screen
        self.touchGui.Enabled = ( not inStartMenu ) and ( not inScreen ) and ( not UserInputService.ModalEnabled )
    end
end


function MobileInputController:_switchToController( controlModule: {}? ): ()
    if ( not controlModule ) then
        if ( self.ActiveController ) then
            self.ActiveController:Enable( false )
        end

        self.ActiveController = nil
        self.ActiveControllerChanged:Fire()
        self.ActiveControlModule = nil
    else
        if ( not self.Controllers[controlModule] ) then
            self.Controllers[ controlModule ] = controlModule.new( Enum.ContextActionPriority.Default.Value )
        end

        if ( self.ActiveController ~= self.Controllers[controlModule] ) then
            if ( self.ActiveController ) then
                self.ActiveController:Enable( false )
            end

            self.ActiveController = self.Controllers[ controlModule ]
            self.ActiveControllerChanged:Fire( self.ActiveController )
            self.ActiveControlModule = controlModule
            self:_updateTouchVisibility()

            if ( self.ActiveController ) then
                self.ActiveController:Enable( true, self.touchControlFrame )
            end
        end
    end
end


function MobileInputController:_createTouchGuiContainer(): ()
    if ( self.touchGui ) then
        self.touchGui:Destroy()
    end

    -- Container for all touch device guis
	self.touchGui = Instance.new("ScreenGui")
	self.touchGui.Name = "TouchGui"
	self.touchGui.ResetOnSpawn = false
	self.touchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self:_updateTouchVisibility()

    local function OnEnabledChanged(): ()
        self:_updateTouchVisibility()

        local guiEnabled = self.touchGui.Enabled and ( not UIController.Screen )
        if ( self.Enabled ~= guiEnabled ) then
            self.touchGui.Parent = ( guiEnabled and PlayerGui ) or nil
            self.Enabled = guiEnabled
            self.EnabledChanged:Fire( guiEnabled )
        end
    end
    self.touchGui:GetPropertyChangedSignal( "Enabled" ):Connect( OnEnabledChanged )
    UIController.ScreenChanged:Connect( OnEnabledChanged )
    task.spawn( OnEnabledChanged )

	self.touchControlFrame = Instance.new("Frame")
	self.touchControlFrame.Name = "TouchControlFrame"
	self.touchControlFrame.Size = UDim2.new(1, 0, 1, 0)
	self.touchControlFrame.BackgroundTransparency = 1
	self.touchControlFrame.Parent = self.touchGui

	self.touchGui.Parent = PlayerGui
end


function MobileInputController:_onLastInputTypeChanged( lastInputType: Enum? ): ()
    if ( lastInputType == Enum.UserInputType.Touch ) or ( (not lastInputType) and UserInputService.TouchEnabled ) then
        self:_switchToController( self:_selectTouchModule() )
    else
        self:_switchToController()
    end
end


function MobileInputController:_onTouchMovementModeChanged(): ()
    local touchModule = self:_selectTouchModule()
    if ( touchModule ) then
        self:_switchToController( touchModule )
    end
end


function MobileInputController:KnitStart(): ()
    if ( UserInputService.TouchEnabled ) then
        self:_createTouchGuiContainer()

        UserInputService.LastInputTypeChanged:Connect(function( lastInputType: Enum? )
            self:_onLastInputTypeChanged( lastInputType )
        end)
        task.spawn( self._onLastInputTypeChanged, self, UserInputService:GetLastInputType() )
        UserInputService:GetPropertyChangedSignal( "ModalEnabled" ):Connect(function()
            self:_updateTouchVisibility()
        end)
        UserGameSettings:GetPropertyChangedSignal( "TouchMovementMode" ):Connect(function()
            self:_onTouchMovementModeChanged()
        end)
        LocalPlayer:GetPropertyChangedSignal( "DevTouchMovementMode" ):Connect(function()
            self:_onTouchMovementModeChanged()
        end)
        LocalPlayer:GetAttributeChangedSignal( "StartMenuMode" ):Connect(function()
            self:_updateTouchVisibility()
        end)

        local lastActiveController
        local function OnActiveControllerChanged( activeController: {}? ): ()
            if ( activeController == lastActiveController ) and ( self._moveVectorChangedConnection ) then
                return
            elseif ( self._moveVectorChangedConnection ) then
                self._moveVectorChangedConnection:Disconnect()
                self._moveVectorChangedConnection = nil
            end
            lastActiveController = activeController

            if ( activeController ) and ( activeController.MoveVectorChanged ) then
                self._moveVectorChangedConnection = activeController.MoveVectorChanged:Connect(function( moveVector )
                    moveVector = moveVector.Unit
                    -- Prevent NAN, NAN
                    if ( moveVector ~= moveVector ) then
                        moveVector = Vector3.new()
                    end
                    self.MoveVector = Vector2.new( moveVector.X, -moveVector.Z )
                    self.MoveVectorChanged:Fire( self.MoveVector )
                end)
            elseif ( self.MoveVector ~= ZERO_VECTOR2 ) then
                self.MoveVector = ZERO_VECTOR2
                self.MoveVectorChanged:Fire()
            end
        end
        self.ActiveControllerChanged:Connect( OnActiveControllerChanged )
        task.spawn( OnActiveControllerChanged, self.ActiveController )

        self.MoveVectorChanged:Connect(function( moveVector )
            --print( "Move Vector:", moveVector )
        end)
    end
end


function MobileInputController:KnitInit(): ()
    
end


return MobileInputController