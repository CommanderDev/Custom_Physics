local function Raycast( origin, direction, raycastParams )
    return workspace:Raycast( origin, direction, raycastParams ) or {
        Instance = nil;
        Position = origin + direction;
        Normal = -direction.Unit;
    }
end

return Raycast