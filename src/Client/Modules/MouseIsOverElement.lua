-- MouseIsOverElement
-- Author(s): Jesse Appleton
-- Date: 12/07/2021

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Roblox Services
local UserInputService = game:GetService( "UserInputService" )

-- Variables

---------------------------------------------------------------------

local function MouseIsOverElement( element )
	assert( (typeof(element) == "Instance") and (element:IsA("GuiObject")), "First argument <element> must be a GuiObject!" )

	local myMouse = UserInputService:GetMouseLocation() - Vector2.new( 0, 36 )

	local minX,minY = element.AbsolutePosition.X, element.AbsolutePosition.Y
	local maxX,maxY = minX+element.AbsoluteSize.X, minY+element.AbsoluteSize.Y

	if ( (myMouse.X>=minX) and (myMouse.Y>=minY) ) then
		if ( (myMouse.X<=maxX) and (myMouse.Y<=maxY) ) then
			return true
		end
	end

	return false
end


return MouseIsOverElement