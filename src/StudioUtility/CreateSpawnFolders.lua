local CollectionService = game:GetService( "CollectionService" )

local spawnerFolder: Folder = Instance.new( "Folder" )
spawnerFolder.Name = "Spawners"
spawnerFolder.Parent = workspace

local zones = { "Green Hill", "Lost Valley", "Emerald Hill", "Snow Valley" }
for _, zoneName in pairs( zones ) do
    local zoneFolder: Folder = Instance.new( "Folder" )
    zoneFolder.Name = zoneName
    zoneFolder.Parent = spawnerFolder

    local orbFolder: Folder = Instance.new( "Folder" )
    orbFolder.Name = "Orbs"
    orbFolder.Parent = zoneFolder

    local ringFolder: Folder = Instance.new( "Folder" )
    ringFolder.Name = "Rings"
    ringFolder.Parent = zoneFolder

    local hoopFolder: Folder = Instance.new( "Folder" )
    hoopFolder.Name = "Hoops"
    hoopFolder.Parent = zoneFolder

    for _, spawner in pairs( CollectionService:GetTagged("RingSpawn") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( spawner:GetAttribute("ZoneName") == zoneName) then
            spawner.Parent = ringFolder
        end
    end

    for _, spawner in pairs( CollectionService:GetTagged("ChaosOrbSpawnPlatform") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( spawner:GetAttribute("ZoneName") == zoneName) then
            spawner.Parent = orbFolder
        end
    end

    for _, spawner in pairs( CollectionService:GetTagged("ChaosOrbSpawn") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( spawner:GetAttribute("ZoneName") == zoneName) then
            spawner.Parent = orbFolder
        end
    end

    for _, spawner in pairs( CollectionService:GetTagged("ExperienceHoopSpawn") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( spawner:GetAttribute("ZoneName") == zoneName) then
            spawner.Parent = hoopFolder
        end
    end
end

local zones = { "Green Hill", "Lost Valley", "Emerald Hill", "Snow Valley" }
for _, zoneName in pairs( zones ) do
    local count = 0
    for _, spawner in pairs( game:GetService("CollectionService"):GetTagged("RingSpawn") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( spawner:GetAttribute("ZoneName") == zoneName) then
            count += 1
        end
    end
    print( zoneName, count )
end