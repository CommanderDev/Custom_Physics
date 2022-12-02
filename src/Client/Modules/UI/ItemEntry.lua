-- ItemEntry
-- Author(s): Jesse Appleton
-- Date: 11/05/2022

--[[
    
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )
local Promise = require( Knit.Util.Promise )
local Create = require( Knit.Util.Create )

-- Modules
local ViewportManager = require( Knit.SharedModules.ViewportManager )

-- Roblox Services

-- Variables

-- Objects
local template: ImageButton = Create( "ImageButton", {
    Name = "template";
    BackgroundColor3 = Color3.fromRGB( 75, 75, 75 );
    BackgroundTransparency = 0.3;
    Image = "";
    AutoButtonColor = false;
} )

local viewportFrame: ViewportFrame = Create( "ViewportFrame", {
    Ambient = Color3.fromRGB( 255, 255, 255 );
    LightColor = Color3.fromRGB( 255, 255, 255 );
    LightDirection = Vector3.new( -1, -1, 1 );
    BackgroundTransparency = 1;
    Size = UDim2.new( 1, 0, 1, 0 );
    AnchorPoint = Vector2.new( 0.5, 0.5 );
    Position = UDim2.new( 0.5, 0, 0.5, 0 );
    Visible = false;
    Parent = template
} )

local viewportUICorner: UICorner = Create( "UICorner", {
    CornerRadius = UDim.new( 0.15, 0 );
    Parent = viewportFrame;
} )

---------------------------------------------------------------------


local ItemEntry = {}
ItemEntry.__index = ItemEntry


function ItemEntry.new( isButton: boolean? ): ( {} )
    local self = setmetatable( {}, ItemEntry )
    self._janitor = Janitor.new()

    local button = template:Clone()

    self.Button = button
    self._janitor:Add(self.Button)

    local viewportFrame: ViewportFrame = button.ViewportFrame

    self.Viewport = viewportFrame

    self.SelectedAmbient = Color3.fromRGB( 255, 255, 255 )
    self.DefaultAmbient = Color3.fromRGB( 150, 150, 150 )
    self.DisabledAmbient = Color3.fromRGB( 0, 0, 0 )

    self.SelectedLight = Color3.fromRGB( 255, 255, 255 )
    self.DefaultLight = Color3.fromRGB( 255, 255, 255 )
    self.DisabledLight = Color3.fromRGB( 0, 0, 0 )

    self:SetSelected(false)
    return self
end

function ItemEntry:UpdateVisual(): ()
    self.Button.BackgroundColor3 = ( self.Selected and Color3.fromRGB(225,225,225) ) or ( (not self.Enabled) and Color3.fromRGB(100, 100, 100) ) or template.BackgroundColor3
    self.Viewport.Ambient = ( (not self.Enabled) and self.DisabledAmbient ) or ( self.Selected and self.SelectedAmbient ) or self.DefaultAmbient
    self.Viewport.LightColor = ( (not self.Enabled) and self.DisabledLight ) or ( self.Selected and self.SelectedLight ) or self.DefaultLight
end


function ItemEntry:SetRarity( rarityString: string ): ()
    --[[local colorSequence: ColorSequence = RarityToColorSequence[ rarityString ] or RarityToColorSequence[ "Common" ]
    self.ButtonGradient.Color = colorSequence
    self.StrokeGradient.Color = colorSequence
    ]]
end

function ItemEntry:SetViewportDisplay( ... ): ()
    if ( not self.ViewportManager ) then
        self.ViewportManager = ViewportManager.new( self.Viewport, {FOV=30} )
        self._janitor:Add( self.ViewportManager )
    end

    self.Viewport.Visible = true

    return self.ViewportManager:SetDisplay( ... )
end

function ItemEntry:SetSelected( bool: boolean ): ()
    self.Selected = bool
    self:UpdateVisual()
end


function ItemEntry:Destroy(): ()
    self._janitor:Destroy()
end


return ItemEntry