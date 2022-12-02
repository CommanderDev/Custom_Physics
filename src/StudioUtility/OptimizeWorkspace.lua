-- Anchor everything that doesn't have an anchored part connected (animated objects)
-- Set CanTouch to false for everything

local partsToAnchor: {BasePart} = {}

local function NoAnchoredConnectedParts( part: BasePart ): ()
    for _, connectedPart: BasePart in pairs( part:GetConnectedParts(true) ) do
        if ( connectedPart.Anchored ) then
            return false
        end
    end
    return true
end

for _, directory: Instance in pairs( game:GetChildren() ) do
    pcall(function()
        for _, instance: BasePart in pairs( directory:GetDescendants() ) do
            if ( instance:IsA("BasePart") ) then
                instance.CanTouch = false

                if ( not instance.Anchored ) and ( NoAnchoredConnectedParts(instance) ) then
                    table.insert( partsToAnchor, instance )
                end
            end
        end
    end)
end

for _, part: BasePart in pairs( partsToAnchor ) do
    part.Anchored = true
end