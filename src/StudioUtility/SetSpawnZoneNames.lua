-- Set "ZoneName" attribute to nearest spawn

local CollectionService = game:GetService( "CollectionService" )

local nameToSpawnPosition: {[string]: Vector3} = {}
for _, spawn: BasePart in pairs( CollectionService:GetTagged("Spawn") ) do
    spawn.Transparency = 0
    spawn.BrickColor = BrickColor.random()
    if ( spawn:IsDescendantOf(workspace) ) and ( spawn:GetAttribute("ZoneSpawn") == true ) then
        nameToSpawnPosition[ spawn:GetAttribute("ZoneName") ] = {
            Name = spawn:GetAttribute( "ZoneName" );
            Position = spawn.Position;
            Color = spawn.Color;
        }
    end
end

local partTags = {
    "ChaosOrbSpawnPlatform";
    "RingSpawn";
    "ChaosOrbSpawn";
    "ExperienceHoopSpawn";
}

for _, tag: string in pairs( partTags ) do
    for _, part: BasePart in pairs( CollectionService:GetTagged(tag) ) do
        if ( not part:IsDescendantOf(workspace) ) then
            continue
        end
        local nearestData: {}, nearestDistance: number
        for spawnName: string, data: {} in pairs( nameToSpawnPosition ) do
            local distance: number = ( part.Position - data.Position ).Magnitude
            if ( not nearestData ) or ( nearestDistance > distance ) then
                nearestData, nearestDistance = data, distance
            end
        end

        if ( nearestData ) then
            if ( not part:GetAttribute("HoopExperience") ) then
                part.Color = nearestData.Color
            end
            part:SetAttribute( "ZoneName", nearestData.Name )
        end
    end
end