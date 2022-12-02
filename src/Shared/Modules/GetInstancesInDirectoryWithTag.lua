-- GetInstancesInDirectoryWithTag
-- Author(s): Jesse Appleton
-- Date: 02/08/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local t = require( Knit.Util.t )


-- Roblox Services
local CollectionService = game:GetService( "CollectionService" )

-- Variables

---------------------------------------------------------------------


local tGetInstancesInDirectoryWithTag = t.tuple( t.Instance, t.string, t.optional(t.boolean) )
local function GetInstancesInDirectoryWithTag( directory: Instance, tag: string, recursive: boolean? ): ( {} )
    assert( tGetInstancesInDirectoryWithTag(directory, tag, recursive) )
    local instances: {} = {}
    for _, instance: Instance in ipairs( CollectionService:GetTagged(tag) ) do
        if ( recursive and instance:IsDescendantOf(directory) ) or ( instance.Parent == directory ) then
            table.insert( instances, instance )
        end
    end
    return instances
end


return GetInstancesInDirectoryWithTag