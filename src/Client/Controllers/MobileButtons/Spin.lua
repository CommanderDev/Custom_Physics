-- Jump
-- Author(s): Jesse Appleton
-- Date: 02/14/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants
local ACTION_NAME_TO_IMAGE = {
    SpinDash = "rbxassetid://8826533011";
}

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Modules

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local function UpdateButton( button: ImageButton ): ( (string?)->() )
    local function Process( actionName: string? ): ()
        local findImage: string? = ACTION_NAME_TO_IMAGE[ actionName ]
        if ( findImage ) then
            button.Image = findImage
            button.Visible = true
        else
            button.Image = ""
            button.Visible = false
        end
    end
    return Process
end


return UpdateButton