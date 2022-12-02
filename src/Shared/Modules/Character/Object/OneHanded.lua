-- OneHanded
-- Author(s): Jesse Appleton
-- Date: 11/04/2022

--[[
    
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Janitor = require( Knit.Util.Janitor )
local Promise = require( Knit.Util.Promise )

-- Modules

-- Roblox Services

-- Variables

-- Objects

---------------------------------------------------------------------


local OneHanded = {}
OneHanded.__index = OneHanded


function OneHanded.new( instance ): ( {} )
    local self = setmetatable( {}, OneHanded )
    self._janitor = Janitor.new()

    self._Flags = {}
    
    self.Callback = {

    }

    print("Created OneHanded weapon!")
    self._instance = instance

    return self
end


function OneHanded:Destroy(): ()
    self._janitor:Destroy()
end


return OneHanded