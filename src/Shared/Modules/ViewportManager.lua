-- ViewportManager
-- Author(s): Jesse Appleton
-- Date: 03/08/2022

--[[
    FUNCTION    ViewportFrame.new( viewportFrame: ViewportFrame, config: {}? ) -> ( {} )
    FUNCTION    ViewportFrame:SetDisplay( display: Model|BasePart, relativeCameraOffset: CFrame?, objectOffsetCFrame? ) -> ( Model|BasePart? )
    FUNCTION    ViewportFrame:GetDisplay() -> ( Model|BasePart? )
]]

---------------------------------------------------------------------

-- Constants
local DEFAULTS = {
    FOV = 70;
    Center = true;
}

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )
local Promise = require( Knit.Util.Promise )
local t = require( Knit.Util.t )

-- Modules

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local ViewportManager = {}
ViewportManager.__index = ViewportManager


local tNew = t.tuple( t.instanceIsA("ViewportFrame"), t.optional(t.keys(t.string)) )
function ViewportManager.new( viewportFrame: ViewportFrame, config: {}? ): ( {} )
    assert( tNew(viewportFrame, config) )

    local self = setmetatable( {}, ViewportManager )
    self._janitor = Janitor.new()

    self.ViewportFrame = viewportFrame
    self.DisplayObject = nil
    self.RelativeCameraCFrame = CFrame.new()

    self.Config = setmetatable( config or {}, {__index = DEFAULTS} )

    self:_Setup()

    return self
end


function ViewportManager:_Setup(): ()
    -- CLEAR OBJECTS
    local allowedClasses: {} = {
        "UICorner";
        "UIStroke";
    }
    for _, object: Instance in pairs( self.ViewportFrame:GetDescendants() ) do
        if ( not table.find(allowedClasses, object.ClassName) ) then
            object:Destroy()
        end
    end

    local camera: Camera = Instance.new( "Camera" )
    camera.FieldOfView = self.Config.FOV
    camera.Parent = self.ViewportFrame
    self.ViewportFrame.CurrentCamera = camera
    self.Camera = camera
    self._janitor:Add( camera )

    local worldModel: WorldModel = Instance.new( "WorldModel" )
    worldModel.Parent = self.ViewportFrame
    self.WorldModel = worldModel
    self._janitor:Add( worldModel )
end


function ViewportManager:Clear(): ()
    if ( self.DisplayObject ) then
        self._janitor:Remove( self.DisplayObject )
        self.DisplayObject:Destroy()
    end
    self.RelativeCameraCFrame = CFrame.new()
end


function ViewportManager:GetDisplay(): ( Instance? )
    return self.DisplayObject
end


function ViewportManager:Redraw(): ()
    if ( self.DisplayPrefab ) then
        self:SetDisplay( self.DisplayPrefab, self.RelativeCameraCFrame, self.ObjectOffsetCFrame )
    end
end


local tSetDisplay = t.tuple( t.optional(t.some(t.instanceIsA("Model"), t.instanceIsA("BasePart"))), t.optional(t.CFrame), t.optional(t.CFrame), t.optional(t.boolean) )
function ViewportManager:SetDisplay( newDisplay: Model|BasePart?, relativeCameraCFrame: CFrame?, objectOffsetCFrame: CFrame?, autoCenter: boolean? ): ( Model|BasePart? )
    assert( tSetDisplay(newDisplay, relativeCameraCFrame, objectOffsetCFrame) )

    self:Clear()

    if ( not newDisplay ) then
        return
    end

    local display: Model|BasePart = newDisplay:Clone()
    self._janitor:Add( display )

    self.DisplayPrefab = newDisplay
    self.DisplayObject = display
    self.RelativeCameraCFrame = relativeCameraCFrame or CFrame.new()
    self.ObjectOffsetCFrame = objectOffsetCFrame or CFrame.new()

    if ( not autoCenter ) then
        if ( display:IsA("BasePart") ) then
            display.CFrame = CFrame.new()
        else
            display:SetPrimaryPartCFrame( CFrame.new() )
        end

        local targetPart: BasePart = if ( display:IsA("Model") ) then display.PrimaryPart or display:FindFirstAncestorWhichIsA("BasePart") else display
        if ( targetPart ) then
            local newCFrame: CFrame = targetPart.CFrame * self.RelativeCameraCFrame
            self.Camera.CFrame = CFrame.new( newCFrame.Position, targetPart.Position + Vector3.new(0, newCFrame.Position.Y, 0) )
        end

        -- OFFSET AFTER CAMERA IS SET
        if ( display:IsA("BasePart") ) then
            display.CFrame = self.ObjectOffsetCFrame
        else
            display:SetPrimaryPartCFrame( self.ObjectOffsetCFrame )
        end
    else
        if ( display:IsA("BasePart") ) then
            display.CFrame = self.ObjectOffsetCFrame
        else
            display:SetPrimaryPartCFrame( self.ObjectOffsetCFrame )
        end

        local displayCFrame, displaySize: CFrame, Vector3
        if ( display:IsA("Model") ) then
            displayCFrame, displaySize = display:GetBoundingBox()
        else
            displaySize = display.Size
            displayCFrame = display.CFrame
        end
		local displayScale: number = displaySize.Magnitude * 1

        local newCameraCFrame: CFrame = CFrame.new()
            * CFrame.Angles( math.rad(0), math.rad(180), 0 )
            * CFrame.new( 0, 0, displayScale / (2 * math.tan(math.rad(self.Camera.FieldOfView) / 2)) )

        self.Camera.CFrame = newCameraCFrame
    end

    display.Parent = self.WorldModel

    return display
end


function ViewportManager:Destroy(): ()
    self._janitor:Destroy()
end


return ViewportManager