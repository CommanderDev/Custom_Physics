-- Enums
-- Author(s): Jesse Appleton
-- Date: 01/31/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local CustomEnum = require( Knit.Util.CustomEnum )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local Enums = setmetatable( {}, {} )


-- Import all child modules into Enums
for _, module in pairs( script:GetChildren() ) do
    if ( not module:IsA("ModuleScript") ) then return end
    assert( (not Enums[module.Name]), string.format("%s.%s already exists!", script:GetFullName(), module.Name) )

    local requiredModule = require( module )
    assert( typeof(requiredModule)  == "table", "Enums expects modules to return a table, got" .. type(requiredModule) )

    Enums[ module.Name ] = CustomEnum.new( module.Name, requiredModule )
end


-- Make indexing nil enums error
getmetatable( Enums ).__index = function( self, index )
    error( string.format("%s is not a valid member of %s", index, script:GetFullName()) )
end


-- Freeze the table so nobody messes with it
table.freeze( Enums )


return Enums