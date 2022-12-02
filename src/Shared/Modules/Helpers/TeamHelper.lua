local Knit = require( game.ReplicatedStorage.Knit )
local t = require( Knit.Util.t )

local spawns = workspace.Map.Spawns

local TeamHelper = {} 

local RandomTeam = Random.new()
function TeamHelper.GetPlayerSpawnLocation(player: Player)
    local playerTeamColor: BrickColor = player.Team.TeamColor
    local potentialSpawns: ({ SpawnLocation }) = {}
    for index, spawn in pairs( spawns:GetChildren() ) do 
        if spawn.TeamColor == playerTeamColor then 
            table.insert(potentialSpawns, spawn)
        end
    end
    local spawn: number = RandomTeam:NextInteger(1, #potentialSpawns)
    return potentialSpawns[ spawn ].CFrame + Vector3.new(0,2,0)
end

local tSetPlayerTeam = t.tuple(t.instanceIsA("Player"), t.string)
function TeamHelper.SetPlayerTeam(player: Player, teamName: string)
    assert( tSetPlayerTeam(player, teamName) )
    local team = game.Teams:FindFirstChild(teamName)
    player.Team = team
end

return TeamHelper