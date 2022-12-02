-- Data
-- Author(s): Jesse Appleton
-- Date: 01/31/2022

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local TableUtil = require( Knit.Util.TableUtil )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local Data = setmetatable( {}, {} )


-- Import all child modules into Data
for _, module in pairs( script:GetChildren() ) do
    if ( not module:IsA("ModuleScript") ) then return end
    assert( (not Data[module.Name]), string.format("%s.%s already exists!", script:GetFullName(), module.Name) )

    local requiredModule = require( module )
    assert( typeof(requiredModule) == "table", "Data expects modules to return a table, got " .. typeof(requiredModule) )

    Data[ module.Name ] = requiredModule
end


-- Make indexing nil data error
getmetatable( Data ).__index = function( self, index )
    error( string.format("%s is not a valid member of %s", index, script:GetFullName()) )
end


-- Freeze the table so nobody messes with it
--TableUtil.DeepFreeze( Data )


return Data