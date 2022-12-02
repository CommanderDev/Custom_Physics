local t = require( script.Parent.t )

local tCreate = t.tuple( t.string, t.keys(t.string) )
local function Create( instanceName: string, properties: {[string]: any} )
    assert( tCreate(instanceName, properties) )

    local saveParent: Instance? = properties.Parent
    properties.Parent = nil

    local newInstance: Instance = Instance.new( instanceName )

    for propertyName: string, value: any in pairs( properties ) do
        newInstance[ propertyName ] = value
    end

    newInstance.Parent = saveParent

    return newInstance
end

return Create