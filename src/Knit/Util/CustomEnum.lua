-- CustomEnum
-- Author(s): Jesse Appleton
-- Date: 01/31/2022

--[[
    
]]

---------------------------------------------------------------------

-- Modules
local Symbol = require( script.Parent.Symbol )
local t = require( script.Parent.t )

-- Constants
local NAME_SYMBOL = Symbol.new( "Name" )
local LIST_SYMBOL = Symbol.new( "List" )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local CustomEnum = {}
CustomEnum.__index = CustomEnum


local tNew = t.tuple( t.string, t.values(t.string) )
function CustomEnum.new( enumName: string, enumList: {string} ): ()
    assert( tNew(enumName, enumList) )

    local self = setmetatable( {}, CustomEnum )
    self[ NAME_SYMBOL ] = enumName
    self[ LIST_SYMBOL ] = {}

    getmetatable( self ).__tostring = (function(self) return string.format("CustomEnum<%s>: " .. table.concat(self[LIST_SYMBOL], ", "), self[NAME_SYMBOL]) end)

    getmetatable( self ).__index = (function( self, index )
        local getFromBase = CustomEnum[ index ]
        if ( getFromBase ) then
            return getFromBase
        end
        error( string.format("%s is not a valid member of CustomEnum \"%s\"", index, self[NAME_SYMBOL]) )
    end)

    for _, enumValue in pairs( enumList ) do
        assert( type(enumValue) == "string", "Enum name must be a string" )
        table.insert( self[LIST_SYMBOL], enumValue )
        self[ enumValue ] = enumValue
    end

    table.freeze( self[LIST_SYMBOL] )
    table.freeze( self )

    return self
end


function CustomEnum:GetName(): ( string )
    return self[ NAME_SYMBOL ]
end


function CustomEnum:GetEnumItems(): ( {[number]: string} )
    return self[ LIST_SYMBOL ]
end


return CustomEnum