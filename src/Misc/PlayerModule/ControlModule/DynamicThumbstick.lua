-- DynamicThumbstick
-- Author(s): Jesse Appleton
-- Date: 01/18/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local DynamicThumbstick = {}
DynamicThumbstick.__index = DynamicThumbstick


function DynamicThumbstick:GetInputObject()
    repeat until ( self.MobileInputController ) or ( not task.wait() )

    local dynamicThumbstick = self.MobileInputController:GetDynamicThumbstickController()
    if ( dynamicThumbstick ) then
        return dynamicThumbstick:GetInputObject()
    end
end


local function Start()
    repeat
        DynamicThumbstick.MobileInputController = Knit.GetController( "MobileInputController" )
    until ( DynamicThumbstick.MobileInputController ) or ( not task.wait() )
end
task.spawn( Start )


return DynamicThumbstick