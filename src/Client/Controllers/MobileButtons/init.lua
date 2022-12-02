-- MobileButtons
-- Author(s): Jesse Appleton
-- Date: 02/14/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Signal = require( Knit.Util.Signal )

-- Modules
local CharacterController = Knit.GetController( "CharacterController" )
local MobileInputController = Knit.GetController( "MobileInputController" )

local Jump = require( script.Jump )
local Spin = require( script.Spin )
local Secondary = require( script.Secondary )
local Tertiary = require( script.Tertiary )


-- Roblox Services

-- Variables
local LocalPlayer = Knit.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild( "PlayerGui" )

-- Objects
local gui: ScreenGui = Instance.new( "ScreenGui" )
gui.Name = "MobileButtons"
gui.DisplayOrder = 0
gui.ResetOnSpawn = false
gui.Enabled = false

local jumpButton: ImageButton = Instance.new( "ImageButton" )
jumpButton.Name = "Jump"
jumpButton.AnchorPoint = Vector2.new( 1, 0.5 )
jumpButton.Image = ""
jumpButton.BackgroundTransparency = 1
jumpButton.AutoButtonColor = false
jumpButton.Parent = gui

local spinButton: ImageButton = jumpButton:Clone()
spinButton.Name = "Spin"
spinButton.ZIndex = 2
spinButton.Parent = gui

local secondaryButton: ImageButton = jumpButton:Clone()
secondaryButton.Name = "Secondary"
secondaryButton.ZIndex = 2
secondaryButton.Parent = gui

local tertiaryButton: ImageButton = jumpButton:Clone()
tertiaryButton.Name = "Tertiary"
tertiaryButton.ZIndex = 2
tertiaryButton.Parent = gui

gui.Parent = PlayerGui

---------------------------------------------------------------------

local MobileButtons = Knit.CreateController {
    Name = "MobileButtons";

    InputChanged = Signal.new();
}


function MobileButtons:KnitStart(): ()
    local function UpdateButtonSizes(): ()
        local sizeY: number = workspace.CurrentCamera.ViewportSize.Y
        if ( sizeY >= 600 ) then
            -- TABLET
            jumpButton.Size = UDim2.new( 0, 120, 0, 120 )
            jumpButton.Position = UDim2.new( 1, -50, 1, -135 )

            spinButton.Size = UDim2.new( 0, 80, 0, 80 )
            spinButton.Position = UDim2.new( 1, -175, 1, -115 )

            secondaryButton.Size = UDim2.new( 0, 80, 0, 80 )
            secondaryButton.Position = UDim2.new( 1, -150, 1, -215 )

            tertiaryButton.Size = UDim2.new( 0, 80, 0, 80 )
            tertiaryButton.Position = UDim2.new( 1, -50, 1, -240 )
        else
            -- PHONE
            jumpButton.Size = UDim2.new( 0, 80, 0, 80 )
            jumpButton.Position = UDim2.new( 1, -20, 1, -55 )

            spinButton.Size = UDim2.new( 0, 55, 0, 55 )
            spinButton.Position = UDim2.new( 1, -105, 1, -50 )

            secondaryButton.Size = UDim2.new( 0, 55, 0, 55 )
            secondaryButton.Position = UDim2.new( 1, -85, 1, -110 )

            tertiaryButton.Size = UDim2.new( 0, 55, 0, 55 )
            tertiaryButton.Position = UDim2.new( 1, -25, 1, -130 )
        end
    end
    workspace.CurrentCamera:GetPropertyChangedSignal( "ViewportSize" ):Connect( UpdateButtonSizes )
    UpdateButtonSizes()

    local updateCallbacks: {[string]: ()->()} = {
        Jump = Jump( jumpButton );
        Spin = Spin( spinButton );
        Secondary = Secondary( secondaryButton );
        Tertiary = Tertiary( tertiaryButton );
    }

    local function ResetButtons( character: {} ): ()
        -- Set initial states back to idle
        --TODO: We need a getter for this
        updateCallbacks.Jump( "Jump" )
        updateCallbacks.Spin( "SpinDash" )
        updateCallbacks.Secondary( nil )
        updateCallbacks.Tertiary( nil )
    end

    local function OnCharacterAdded( character: {} ): ()
        local function ProcessButtonChanged( buttonName: string, actionName: string? ): ()
            updateCallbacks[ buttonName ]( actionName )
        end
        ResetButtons()
        character.ButtonChanged:Connect( ProcessButtonChanged )
    end
    CharacterController.CharacterAdded:Connect( OnCharacterAdded )

    local function HandleButtonInput( button: ImageButton, buttonName: string ): ()
        local function ProcessInput( input: InputObject ): ()
            if ( input.UserInputState == Enum.UserInputState.Begin ) then
                self.InputChanged:Fire( buttonName, true )
            else
                self.InputChanged:Fire( buttonName, false )
            end
        end
        button.InputBegan:Connect( ProcessInput )
        button.InputEnded:Connect( ProcessInput )
    end
    task.spawn( HandleButtonInput, jumpButton, "TouchJump" )
    task.spawn( HandleButtonInput, spinButton, "TouchSpin" )
    task.spawn( HandleButtonInput, secondaryButton, "TouchSecondary" )
    task.spawn( HandleButtonInput, tertiaryButton, "TouchTertiary" )

    local character: {}? = CharacterController:GetCharacter()
    if ( character ) then
        task.spawn( OnCharacterAdded, character )
    end

    local function UpdateEnabled(): ()
        gui.Enabled = MobileInputController.Enabled
    end
    MobileInputController.EnabledChanged:Connect( UpdateEnabled )
    task.spawn( UpdateEnabled )
end


function MobileButtons:KnitInit(): ()
    
end


return MobileButtons