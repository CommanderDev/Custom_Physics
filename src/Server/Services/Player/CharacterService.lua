-- CharacterService
-- Author(s): Jesse Appleton
-- Date: 02/01/2022

--[[
    FUNCTION    CharacterService:GetPlayerRunningSpeedPercent( player: Player ) -> ( number )
    FUNCTION    CharacterService:GetPlayerSpeedPercent( player: Player ) -> ( number )
    FUNCTION    CharacterService:IsPlayerMovingForward( player: Player ) -> ( boolean, number )
    FUNCTION    CharacterService:IsPlayerMoving( player: Player ) -> ( boolean, number )
    FUNCTION    CharacterService:IsPlayerRunning( player: Player ) -> ( boolean, number )
    FUNCTION    CharacterService:PlayerOwnsCharacter( player: Player ) -> ( boolean )
    FUNCTION    CharacterService:SetSelectedCharacter( player: Player, characterName: string ) -> ()
    FUNCTION    CharacterService:GetSelectedCharacter( player: Player ) -> ( string? )
    FUNCTION    CharacterService:SpawnNewPlayerCharacter( player: Player, targetCFrame: CFrame? ) -> ()
    FUNCTION    CharacterService:RespawnPlayerCharacter( player: Player ) -> ()
    FUNCTION    CharacterService:AwardCharacterExperience( player: Player ) -> ()
    FUNCTION    CharacterService:GetPlayerCFrame( player: Player ) -> ( CFrame? )
    FUNCTION    CharacterService:TeleportCharacter( player: Player, targetCFrame: CFrame, resetState: boolean? ) -> ()
    FUNCTION    CharacterService:AnimateVFX( player: Player, setting: string ) -> ()
]]

---------------------------------------------------------------------

-- Types
type InventoryEntry = {
    GUID: string;
    Name: string;
    Level: string;
    Experience: string;
    [string]: any;
}

type CharacterState = {
    UpdateId: number?,
    LastUpdate: number?,
    CFrame: CFrame?,
    LastCFrame: CFrame?,
    Speed: number?,
    Direction: Vector3?,
    IsRunning: boolean?
}

-- Constants
local MAX_RUNNING_SPEED: number = 150 -- This number is used to calculate % of max speed for StepService
local MAX_SPEED: number = 150
local FORWARD_DOT_MAX: number = 0.925
local UP_VECTOR: Vector3 = Vector3.new( 0, 1, 0 )

-- Knit
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local RemoteSignal = require( Knit.Util.Remote.RemoteSignal )
local t = require( Knit.Util.t )
local Signal = require( Knit.Util.Signal )

-- Modules
local DataService = Knit.GetService( "DataService" )
local CharacterHelper = require( Knit.SharedModules.Helpers.CharacterHelper )
local InventoryHelper = require( Knit.SharedModules.Helpers.InventoryHelper )
local TeamHelper = require( Knit.Helpers.TeamHelper)
local CharacterData = Knit.GameData.CharacterData

-- Roblox Services
local Players = game:GetService("Players")
local CollectionService = game:GetService( "CollectionService" )
local HttpService = game:GetService( "HttpService" )
local RunService = game:GetService( "RunService" )
local Debris = game:GetService( "Debris" )
local TweenService = game:GetService("TweenService")

-- Variables
local avatarFolder: Folder = Instance.new( "Folder" )
avatarFolder.Name = "PlayerAvatars"
avatarFolder.Parent = Knit.Assets

---------------------------------------------------------------------


local function IsValidCharacterName( characterName: string ): ( boolean )
    return not not CharacterHelper.GetDataByName( characterName ), string.format( "A character named \"%s\" does not exist!", characterName )
end

local propertyToScale: {[string]: number} = {
    BodyTypeScale = 0;
    DepthScale = 1;
    HeadScale = 1;
    HeightScale = 1;
    ProportionScale = 1;
    WidthScale = 1;
}
local function ScaleHumanoidDescription( humanoidDescription: HumanoidDescription ): ()
    for property: string, scale: number in pairs( propertyToScale ) do
        humanoidDescription[ property ] = scale
    end
end

-- TEMP
for _, spawn in pairs( CollectionService:GetTagged("DebugSpawn") ) do
    if ( not RunService:IsStudio() ) then
        spawn.Transparency = 1
        spawn:ClearAllChildren()
    end
end


local CharacterService = Knit.CreateService {
    Name = "CharacterService";
    Client = {
        EquipCharacter = RemoteSignal.new();
        CharacterAdded = RemoteSignal.new();            -- Server fires this when a new character is placed in workspace ( player: Player, character: Model, characterData: {} )
        CharacterDataChanged = RemoteSignal.new();      -- Server fires this when character data is changed (upgrades/etc) ( player: Player, characterData: {} )
        RequestCharacterChange = RemoteSignal.new();    -- Client fires this when they want to change characters ( characterName: string )
        UpdateCharacterState = RemoteSignal.new();      -- Client fires this to update the character's state on the server (may need to make more than this for more specific networking)
        CharacterDied = RemoteSignal.new();             -- No longer looking at humanoid death, may be used for future VoidOut, simulated death
        CharacterTouchedTrigger = RemoteSignal.new();   -- Client fires CharacterService with self and touched trigger's tag
        TeleportCharacter = RemoteSignal.new();
        DebugStatUpdate = RemoteSignal.new();           -- Callable by Debug hud. Only works within Studio
        RequestUnlockCharacter = RemoteSignal.new();    -- Called by CharacterCard to unlock characters
        CharacterUnlocked = RemoteSignal.new();         -- Server fires this when a new character is unlocked ( player: Player, characterName: string )
        StartPlay = RemoteSignal.new();                 -- Forces StartScreenUI to disable start menu, should a player die or reset while on the start menu
    };

    PlayerCharacterAdded = Signal.new();

    _characterStates = {};
    _playersCompiled = {};
}


function CharacterService:SetDebugStats( player: Player, stats: {} ): ()
    if ( Knit.IsStudio ) then
        local profile: {} = DataService:GetPlayerDataAsync( player )
        if ( not profile ) then return false end

        for stat, value in pairs( stats ) do
            DataService:SetPlayerData( player, stat, value )
            warn("Successfully applied", stat, "to", player)
        end
    end
end


local tAnimateVFX = t.tuple( t.Player, t.string )
function CharacterService:AnimateVFX( player: Player, setting: string ): ()
    assert( tAnimateVFX( player, setting ) )
end


local tGetDefaultAvatarForPlayer = t.tuple( t.instanceIsA("Player"), t.instanceIsA("Player") )
function CharacterService.Client:GetDefaultAvatarForPlayer( player: Player, targetPlayer: Player ): ( Model )
    assert( tGetDefaultAvatarForPlayer(player, targetPlayer) )

    local findAvatar: Model? = avatarFolder:FindFirstChild( targetPlayer.Name )
    if ( findAvatar ) then
        return findAvatar
    end

    local humanoidDescription: HumanoidDescription = Players:GetHumanoidDescriptionFromUserId( math.max(1, targetPlayer.UserId) )
    ScaleHumanoidDescription( humanoidDescription )
    local newAvatar: Model = Players:CreateHumanoidModelFromDescription( humanoidDescription, Enum.HumanoidRigType.R15, Enum.AssetTypeVerification.Always )
    newAvatar.Name = targetPlayer.Name
    newAvatar.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    newAvatar:SetPrimaryPartCFrame( CFrame.new(0,0,0) )

    for _, instance: Instance in pairs( newAvatar:GetDescendants() ) do
        if ( instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") ) then
            instance:Destroy()
        end
    end

    newAvatar.Parent = avatarFolder

    Debris:AddItem( newAvatar, 60 )

    return newAvatar
end


local tCreateInventoryEntryFromName = t.tuple( IsValidCharacterName )
function CharacterService:_createInventoryEntryFromName( trailName: string ): ( InventoryEntry )
    assert( tCreateInventoryEntryFromName(trailName) )

    return {
        GUID = HttpService:GenerateGUID( false ),
        Name = trailName,
        Level = 1,
        Experience = 0
    }
end


local tPlayerOwnsCharacterGUID = t.tuple( t.instanceIsA("Player"), t.string )
function CharacterService:PlayerOwnsCharacterGUID( player: Player, characterGUID: string ): ( boolean )
    assert( tPlayerOwnsCharacterGUID(player, characterGUID) )

    local profile: {} = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return false end

    local inventory: {InventoryEntry} = profile.Data.Characters
    return ( not not InventoryHelper.GetInventoryEntryByGUID(inventory, characterGUID) )
end


local tPlayerOwnsCharacterName = t.tuple( t.instanceIsA("Player"), t.string )
function CharacterService:PlayerOwnsCharacter( player: Player, characterName: string ): ( boolean )
    assert( tPlayerOwnsCharacterName(player, characterName) )

    local profile: {} = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return false end

    local inventory: {InventoryEntry} = profile.Data.Characters
    return ( not not InventoryHelper.GetInventoryEntryByName(inventory, characterName) )
end


local tGivePlayerCharacter = t.tuple( t.instanceIsA("Player"), IsValidCharacterName )
function CharacterService:GivePlayerCharacter( player: Player, characterName: string ): ( boolean, {}? )
    assert( tGivePlayerCharacter(player, characterName) )

    if ( self:PlayerOwnsCharacter(player, characterName) ) then return true end

    local profile: {} = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return false end

    local inventory: {InventoryEntry} = profile.Data.Characters
    local addSuccess, addData = InventoryHelper.AddToInventory( inventory, self:_createInventoryEntryFromName(characterName) )
    if ( addSuccess ) then
        DataService:ReplicateTableIndex( player, "Characters", addData.GUID )
        if ( characterName ~= "default" ) then
            self.Client.CharacterUnlocked:Fire( player, characterName )
        end
    end

    return ( not not addSuccess ), addData
end


function CharacterService:_requestUnlockCharacter( player: Player, characterName: string ): ()
    assert( IsValidCharacterName(characterName) )

    local playerZone: string? = player:GetAttribute( "ZoneName" )
    local characterData: {} = CharacterHelper.GetDataByName( characterName )
    assert( playerZone == characterData.UnlockZone, string.format("%s is not in the correct zone to unlock %s", player.Name, characterName) )

    self:GivePlayerCharacter( player, characterName )
end


local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
raycastParams.FilterDescendantsInstances = {workspace.Map.Collision, workspace.Terrain}
raycastParams.IgnoreWater = false

local tSetEquippedCharacter = t.tuple( t.instanceIsA("Player"), t.string )
function CharacterService:SetEquippedCharacter( player: Player, characterGUID: string ): ()
    assert( tSetEquippedCharacter(player, characterGUID) )
    
    local result = workspace:Raycast(self:GetPlayerCFrame(player).Position, Vector3.new(0, -5, 0), raycastParams)
    if not result then 
        return
    end
    
    local profile: {} = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return false end

    local inventory: {InventoryEntry} = profile.Data.Characters
    if ( characterGUID ) and ( InventoryHelper.GetInventoryEntryByGUID(inventory, characterGUID) ) then
        DataService:SetPlayerData( player, "EquippedCharacter", characterGUID )
    else
        local defaultEntry: InventoryEntry = InventoryHelper.GetInventoryEntryByName( inventory, "default" )
        if ( defaultEntry ) then
            DataService:SetPlayerData( player, "EquippedCharacter", defaultEntry.GUID )
        end
    end


    local equippedCharacterData: {} = self:GetEquippedCharacterData( player )
    if (equippedCharacterData and (player:GetAttribute("EquippedCharacter") ~= equippedCharacterData.Name) ) then
        CharacterService:SpawnNewPlayerCharacter( player, self:GetPlayerCFrame(player), true )
    end
end


local tGetEquippedCharacter = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetEquippedCharacter( player: Player ): ( string? )
    assert( tGetEquippedCharacter(player) )

    local profile: {}? = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return end

    return profile.Data.EquippedCharacter
end


local tGetEquippedCharacterEntry = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetEquippedCharacterEntry( player: Player ): ( {}? )
    assert( tGetEquippedCharacterEntry(player) )

    local profile: {}? = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return end

    local inventory: {} = profile.Data.Characters
    local equippedGUID: string? = profile.Data.EquippedCharacter
    if ( equippedGUID ) then
        return InventoryHelper.GetInventoryEntryByGUID( inventory, equippedGUID )
    end
end


local tGetSelectedCharacter = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetEquippedCharacterData( player: Player ): ( {}? )
    assert( tGetSelectedCharacter(player) )

    local profile: {}? = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return end

    local inventory: {} = profile.Data.Characters
    local equippedGUID: string? = profile.Data.EquippedCharacter
    local equippedEntry: InventoryEntry = equippedGUID and InventoryHelper.GetInventoryEntryByGUID( inventory, equippedGUID )
    if ( equippedEntry ) then
        return CharacterHelper.GetDataByName( equippedEntry.Name )
    end
end


local tGetPlayerCFrame = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetPlayerCFrame( player: Player ): ( CFrame? )
    assert( tGetPlayerCFrame(player) )

    local characterState: CharacterState? = self._characterStates[ player ]
    if ( characterState ) then
        return characterState.CFrame
    end
end


local tGetPlayerSpeed = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetPlayerSpeed( player: Player ): ( number )
    assert( tGetPlayerSpeed(player) )

    local characterState: CharacterState? = self._characterStates[ player ]
    if ( characterState ) then
        return characterState.Speed or 0
    end
    return 0
end


local tGetPlayerRunningSpeedPercent = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetPlayerRunningSpeedPercent( player: Player ): ( number )
    assert( tGetPlayerRunningSpeedPercent(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        return ( characterState.IsRunning and math.clamp((characterState.Speed or 0)/MAX_RUNNING_SPEED, 0, 1) ) or 0
    end

    return 0
end


local tGetPlayerSpeedPercent = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetPlayerSpeedPercent( player: Player ): ( number )
    assert( tGetPlayerSpeedPercent(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        return math.clamp( (characterState.Speed or 0)/MAX_SPEED, 0, 1 )
    end

    return 0
end


local tGetPlayerForwardSpeedPercent = t.tuple( t.instanceIsA("Player") )
function CharacterService:GetPlayerForwardSpeedPercent( player: Player ): ( number )
    assert( tGetPlayerForwardSpeedPercent(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        local posUpDot: number = math.abs( characterState.Direction:Dot(UP_VECTOR) )
        return posUpDot < FORWARD_DOT_MAX and math.clamp( (characterState.Speed or 0)/MAX_SPEED, 0, 1 ) or 0
    end

    return 0
end


local tIsPlayerMovingForward = t.tuple( t.instanceIsA("Player") )
function CharacterService:IsPlayerMovingForward( player: Player ): ( boolean, number )
    assert( tIsPlayerMovingForward(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        local movementSpeed: number = characterState.Speed or 0
        local posUpDot: number = math.abs( characterState.Direction:Dot(UP_VECTOR) )
        return movementSpeed >= 1 and posUpDot < FORWARD_DOT_MAX, movementSpeed
    end

    return false
end


local tIsPlayerMoving = t.tuple( t.instanceIsA("Player") )
function CharacterService:IsPlayerMoving( player: Player ): ( boolean, number )
    assert( tIsPlayerMoving(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        local movementSpeed: number = characterState.Speed or 0
        return movementSpeed >= 1, movementSpeed
    end

    return false
end


local tIsPlayerRunning = t.tuple( t.instanceIsA("Player") )
function CharacterService:IsPlayerRunning( player: Player ): ( boolean, number )
    assert( tIsPlayerRunning(player) )

    local characterState: CharacterState = self._characterStates[ player ]
    if ( characterState ) then
        local movementSpeed: number = characterState.Speed or 0
        return ( characterState.IsRunning ) and movementSpeed >= 1, ( characterState.IsRunning ) and movementSpeed
    end

    return false
end


function CharacterService:_handleCharacterLevelUp( entryData: InventoryEntry )
    local requiredExperience: number = CharacterHelper.GetRequiredExperienceForCharacter( entryData.Name, entryData.Level )
    local maxLevel: number = CharacterData.MaxLevel

    if ( entryData.Level >= maxLevel ) then
        entryData.Level = maxLevel
        entryData.Experience = 0
    elseif ( entryData.Experience >= requiredExperience ) then
        entryData.Experience = math.max( math.floor(entryData.Experience - requiredExperience), 0 )
        entryData.Level += 1

        if ( entryData.Experience > 0 ) then
            self:_handleTrailLevelUp( entryData )
        end
    end
end


local tAwardTrailExperience = t.tuple( t.instanceIsA("Player"), t.every(t.integer, t.numberPositive) )
function CharacterService:AwardCharacterExperience( player: Player, experience: number ): ()
    assert( tAwardTrailExperience(player, experience) )

    local profile: {}? = DataService:GetPlayerDataAsync( player )
    if ( not profile ) then return end

    local equippedCharacter: string?  = profile.Data.EquippedCharacter
    local inventory: {InventoryEntry} = profile.Data.Characters

    local trailData: InventoryEntry = equippedCharacter and InventoryHelper.GetInventoryEntryByGUID( inventory, equippedCharacter )
    if ( trailData ) then
        trailData.Experience += experience
        self:_handleCharacterLevelUp( trailData )
        DataService:ReplicateTableIndex( player, "Characters", equippedCharacter )
    end
end


function CharacterService:_updateCharacterState( player: Player, data: {} ): ()
    local lastState: CharacterState|{} = self._characterStates[ player ] or {}

    local lastUpdate: number = lastState.LastUpdate or os.clock()
    local updateTimeDelta: number = os.clock() - lastUpdate
    local lastCFrame: CFrame = lastState.CFrame or data.CFrame
    local newCFrame: CFrame = data.CFrame
    local offset: Vector3 = ( newCFrame.Position - lastCFrame.Position )
    local speed: number = offset.Magnitude / updateTimeDelta
    -- Account for NAN results
    if ( speed ~= speed ) then
        speed = 0
    end
    local direction: Vector3 = offset.Unit
    -- Account for NAN results
    if ( direction ~= direction ) then
        direction = Vector3.new( 0, 0, 0 )
    end

    self._characterStates[ player ] = {
        UpdateId = ( data.UpdateId or 0 ) + 1;
        LastUpdate = os.clock();
        CFrame = newCFrame;
        LastCFrame = lastCFrame;
        Speed = speed;
        Direction = direction;
        IsRunning = not not data.IsRunning;
    }
end


function CharacterService:_recieveCharacterUpdate( player: Player, data: {} ): ()
    debug.profilebegin( "ReceiveCharacterUpdate" )
    if ( data.CFrame ) and ( player.Character == data.Character ) then
        self._playersCompiled[ player ] = player
        self:_updateCharacterState( player, data )

        local playerCharacter: Model = player.Character
        local playerCFrame: CFrame = data.CFrame
        for compiledPlayer: Player in pairs( self._playersCompiled ) do
            if ( player ~= compiledPlayer ) then
                self.Client.UpdateCharacterState:Fire( compiledPlayer, playerCharacter, playerCFrame )
            end
        end
    end
    debug.profileend()
end


local tTeleportCharacter = t.tuple( t.instanceIsA("Player"), t.CFrame, t.optional(t.boolean) )
function CharacterService:TeleportCharacter( player: Player, targetCFrame: CFrame, resetState: boolean? ): ()
    assert( tTeleportCharacter(player, targetCFrame, resetState) )

    if ( player.Character and player.Character.PrimaryPart ) then
        self.Client.TeleportCharacter:Fire( player, targetCFrame, resetState )
    else
        self:SpawnNewPlayerCharacter( player, targetCFrame )
    end
end


-- Reset player back to spawn
local tResetPlayerCharacter = t.tuple( t.instanceIsA("Player") )
function CharacterService:ResetPlayerCharacter( player: Player ): ()
    assert( tResetPlayerCharacter(player) )

    if ( player:GetAttribute("ObbyStarted") ) then
        player:SetAttribute( "ObbyStarted", os.clock() )
    end

    -- Check to see if this is a new player mistakenly dieing while on the startscreen
    local startMenuMode = ( player and player:GetAttribute("StartMenuMode") )
    if ( startMenuMode ) then
        player:SetAttribute("StartMenuMode", false)
        player:SetAttribute("ScreenName", "")
        self.Client.StartPlay:Fire( player, true )
    end

    --return self:TeleportCharacter( player, ZoneService:GetPlayerSpawnCFrame(player), true )
end


-- Create new character for player

local tSpawnNewPlayerCharacter = t.tuple( t.instanceIsA("Player"), t.optional(t.CFrame) )

function CharacterService:SpawnNewPlayerCharacter( player: Player, originCFrame: CFrame? ): ( boolean )
    assert( tSpawnNewPlayerCharacter(player, originCFrame) )
    print(originCFrame)
    local spawnCFrame: CFrame = originCFrame or TeamHelper.GetPlayerSpawnLocation(player);
    originCFrame = spawnCFrame
    -- Do this first to make sure old updates coming in are invalidated
    if ( player.Character ~= nil ) and ( player.Character.Parent ) then
        player.Character:Destroy()
    end
    player.Character = nil

    self:_updateCharacterState( player, {
        CFrame = spawnCFrame;
    })

    local equippedCharacterData: {} = self:GetEquippedCharacterData( player ) or CharacterHelper.GetDataByName( "default" )
    player:SetAttribute( "EquippedCharacter", equippedCharacterData.Name )

    local function GetRig(): ( Model )
        local rig: Model = equippedCharacterData.Folder.Rig
        if ( equippedCharacterData.Name == "default" ) then
            local success, createdRig = pcall(function()
                local humanoidDescription: HumanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(math.max(1, player.UserId))
                return game.Players:CreateHumanoidModelFromDescription( humanoidDescription, Enum.HumanoidRigType.R15, Enum.AssetTypeVerification.Always )
            end)
            if ( success ) then
                return createdRig
            end
        end
        return rig:Clone()
    end

    local newRig: Model = GetRig()
    newRig:SetAttribute("CanInput", false)
    local rigDescendants: {} = newRig:GetDescendants()
    local rigDefaultTransparency: {} = {}
    for index: number, basepart: BasePart in next, rigDescendants do 
        if ( basepart:IsA("BasePart") ) then
            rigDefaultTransparency[basepart] = basepart.Transparency
        end
    end

    local function SetRigTransparency(newTransparency: number): ()
        for index, basepart in next, rigDescendants do 
            if ( basepart:IsA("BasePart") and basepart.Name ~= "HumanoidRootPart" ) then
                basepart.Transparency = if newTransparency == "default" then rigDefaultTransparency[basepart] else newTransparency
            end
        end
    end
    SetRigTransparency(0)
    newRig.Name = player.Name

    -- If the player left the game before the rig could be created (GetHumanoidDescriptionFromUserId yields)
    if ( not player:IsDescendantOf(game) ) then
        newRig:Destroy()
        return
    end

    -- Set character right away so it's removed by the engine if they leave
    player.Character = newRig

    local humanoid: Humanoid = newRig.Humanoid
    newRig.Humanoid.DisplayName = player.DisplayName
    newRig.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject
    newRig.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.PlatformStand = true

    -- Setup rig
    for _, part: BasePart in pairs( newRig:GetDescendants() ) do
        if( part:IsA("BasePart") ) then
            part.CanCollide = false
            part.CanQuery = true
            part.CanTouch = false
            part.Anchored = false
        end
    end

    -- Make sure the root is the only thing anchored
    newRig.HumanoidRootPart.Anchored = true

    -- Clean up injected scripts by Roblox
    for _, instance: Instance in pairs( newRig:GetDescendants() ) do
        if ( instance:IsA("LocalScript") or instance:IsA("ModuleScript") or instance:IsA("Script") ) then
            pcall(function()
                instance:Destroy()
            end)
        end
    end

    -- Disable humanoid processing
    local statesToEnable: {[Enum.HumanoidStateType]: boolean} = {
        [ Enum.HumanoidStateType.None ] = true;
        [ Enum.HumanoidStateType.Dead ] = true;
        [ Enum.HumanoidStateType.Physics ] = true;
    }
    for _, enum: Enum.HumanoidStateType in pairs( Enum.HumanoidStateType:GetEnumItems() ) do
        if ( not statesToEnable[enum] ) then
            humanoid:SetStateEnabled( enum, false )
        end
    end
    humanoid:ChangeState( Enum.HumanoidStateType.Physics )

    newRig.Humanoid.Died:Connect(function()
        if ( newRig:IsDescendantOf(workspace) ) then
            self:SpawnNewPlayerCharacter( player )
        end
    end)
    newRig.Parent = workspace
    self.PlayerCharacterAdded:Fire( player, player.Character, originCFrame )
    CharacterService.Client.CharacterAdded:Fire( player, player.Character, equippedCharacterData.Name, originCFrame )
end


function CharacterService:KnitStart(): ()
    local function OnPlayerAdded( player: Player ): ()
        player:SetAttribute("StartMenuMode", true)
        player:SetAttribute("ScreenName", "Start Screen")
        if not player:IsInGroup( Knit.GameData.GroupData.GroupId) then 
            TeamHelper.SetPlayerTeam(player, "Foreigner")
        else
            TeamHelper.SetPlayerTeam(player, "Westerosi")
        end
        CharacterService:SpawnNewPlayerCharacter( player )

        local function OnCharacterAdded( character: Model ): ()
            if ( character ) then
                character.Archivable = true
                CollectionService:AddTag( character, "PlayerCharacter" )
            end
        end
        player.CharacterAdded:Connect( OnCharacterAdded )
        if ( player.Character ) then
            task.spawn( OnCharacterAdded, player.Character )
        end
    end
    Players.PlayerAdded:Connect( OnPlayerAdded )
    for _, player in pairs( Players:GetPlayers() ) do
        task.spawn( OnPlayerAdded, player )
    end

    local function OnPlayerRemoving( player: Player ): ()
        self._characterStates[ player ] = nil
        self._playersCompiled[ player ] = nil

        local playerAvatar: Model? = avatarFolder:FindFirstChild( player.Name )
        if ( playerAvatar ) then
            playerAvatar:Destroy()
        end
    end
    Players.PlayerRemoving:Connect( OnPlayerRemoving )

    --For when our remote event fires for a character update
    self.Client.RequestCharacterChange:Connect(function( player: Player, request: string )
        player:SetAttribute( "EquippedCharacter", nil )
        CharacterService:SetEquippedCharacter( player, request )
    end)

    self.Client.DebugStatUpdate:Connect(function( ... )
        CharacterService:SetDebugStats( ... )
    end)

    -- Recieve Character Updates
    self.Client.UpdateCharacterState:Connect(function( ... )
        self:_recieveCharacterUpdate( ... )
    end)

    self.Client.CharacterDied:Connect(function( player: Instance )
        self:ResetPlayerCharacter( player )
    end)

    self.Client.EquipCharacter:Connect(function( player: Player, ... )
        if ( (tick() - (player:GetAttribute("LastCharacterChange") or 0)) <= 3 ) then
            return
        end

        player:SetAttribute( "LastCharacterChange", tick() )
        self:SetEquippedCharacter( player, ... )
    end)

    self.Client.RequestUnlockCharacter:Connect(function( ... )
        self:_requestUnlockCharacter( ... )
    end)
end


function CharacterService:KnitInit(): nil
    
end


return CharacterService