local COMBINE_DISTANCE: number = 30 -- What is the maximum distance for an orb to be considered in a consecutive line?

local CollectionService = game:GetService( "CollectionService" )

local startSpawner: BasePart = game.Selection:Get()[1]
local spawns: {BasePart} = {
    startSpawner;
}
local ignoreSpawners: {BasePart} = {}

local currentSpawner: BasePart = startSpawner
local function AddNextSpawn(): ( boolean )
    local nextNearest, nextDistance
    for _, spawner: BasePart in pairs( CollectionService:GetTagged("ChaosOrbSpawn") ) do
        if ( spawner:IsDescendantOf(workspace) ) and ( not table.find(spawns, spawner) ) then
            local orbSize: number = math.max( spawner.Size.X, spawner.Size.Z )
            if ( orbSize >= 5 ) then
                continue
            end
            local distance: number = ( currentSpawner.Position - spawner.Position ).Magnitude
            if ( distance <= COMBINE_DISTANCE ) and ( (not nextDistance) or (nextDistance > distance) ) then
                nextNearest, nextDistance = spawner, distance
            end
        end
    end

    if ( nextNearest ) then
        currentSpawner = nextNearest
        table.insert( spawns, nextNearest )
        return true
    end

    return false
end

repeat until ( not AddNextSpawn() )

local currentSpawner: BasePart = spawns[ 1 ]
for _, spawner in pairs( spawns ) do
    local spawnerPosition: Vector3 = ( spawner.CFrame * CFrame.new(0, -spawner.Size.Y/2, 0) ).Position
    local currentSpawnerPosition: Vector3 = ( currentSpawner.CFrame * CFrame.new(0, -currentSpawner.Size.Y/2, 0) ).Position
    local distance: number = ( spawnerPosition - currentSpawnerPosition ).Magnitude
    local newSpawner: BasePart = spawner:Clone()
    CollectionService:RemoveTag( newSpawner, "ChaosOrbSpawn" )
    CollectionService:AddTag( newSpawner, "ChaosOrbSpawnPlatform" )
    newSpawner.TopSurface = "Hinge"
    newSpawner.Size = Vector3.new( 5, 1, distance )
    newSpawner.CFrame = CFrame.new( currentSpawnerPosition, spawnerPosition ) * CFrame.new( 0, 0, -distance/2 )
    newSpawner.Parent = spawner.Parent

    currentSpawner = spawner
end

for _, spawner: BasePart in pairs( spawns ) do
    spawner:Destroy()
end