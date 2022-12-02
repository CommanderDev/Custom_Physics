-- SendNotification
-- Author(s): Jesse Appleton
-- Date: 03/24/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services
local StarterGui: StarterGui = game:GetService( "StarterGui" )

-- Variables


-- Objects

---------------------------------------------------------------------

local function SendNotification( title: string, text: string, duration: number? )
    StarterGui:SetCore( "SendNotification", {
        Title = title;
        Text = text;
        Duration = tonumber(duration) or 5;
    })
end

return SendNotification