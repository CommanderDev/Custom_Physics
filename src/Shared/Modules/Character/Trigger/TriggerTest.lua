-- TriggerTest
-- Author(s): Jesse Appleton
-- Date: 02/02/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local TriggerTest = {}
TriggerTest.__index = TriggerTest


-- Callbacks
local function CharacterTouched( self: table ): nil
	warn("CONTACT!")
	self.Callback.CharacterTouched = nil
end

-- Constructor and destructor
function TriggerTest.new( character: table, trigger: Part ): table
	local self = setmetatable( {}, TriggerTest )

	-- Use given character and trigger
	self._character = character
	self._trigger = trigger

	-- Set callback
	self.Callback = {
		CharacterTouched = CharacterTouched
	}

	return self
end


function TriggerTest:Destroy(): nil

end


return TriggerTest