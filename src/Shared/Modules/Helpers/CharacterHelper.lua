-- CharacterHelper
-- Author(s): Jesse Appleton
-- Date: 03/03/2022

--[[
    FUNCTION    CharacterHelper.GetStatsForLevel( level: number ) -> {}
    FUNCTION    CharacterHelper.GetDataByName( characterName: string ) -> {}?
    FUNCTION    CharacterHelper.GetEvolutionDataByName( characterName: string ) -> ( {[string]: any}? )
    FUNCTION    CharacterHelper.GetRequiredExperienceForTrail( characterName: string, trailLevel: number ) -> ( number )
    FUNCTION    CharacterHelper.GetCharacterStatsFromEntry( inventoryEntry: {} ) -> ( {} )
    FUNCTION    CharacterHelper.GetPowerRangeForLevel( level: number ) -> ( NumberRange )
    FUNCTION    CharacterHelper.GetSpeedRangeForLevel( level: number ) -> ( NumberRange )
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local t = require( Knit.Util.t )

-- Modules

-- Roblox Services

-- Variables
local CharacterData: {} = Knit.GameData.CharacterData
local CharacterStatData: {} = CharacterData.StatData

---------------------------------------------------------------------

local CharacterHelper = {}


local function CharacterExistsForName( name: string ): ( boolean, string )
    local characterData: {}? = CharacterHelper.GetDataByName( name )
    return ( not not characterData ), "Missing character data for \"" .. tostring(name) .. "\"!"
end


local tGetDataByName = t.tuple( t.string )
function CharacterHelper.GetDataByName( characterName: string ): ( {}? )
    assert( tGetDataByName(characterName) )

    for _, data in pairs( CharacterData.Characters ) do
        if ( data.Name == characterName ) then
            return data
        end
    end

    warn( "CharacterHelper: Couldn't find character data for \"" .. characterName .. "\"!" )
end


local tGetHeadshotViewportInfo = t.tuple( CharacterExistsForName )
function CharacterHelper.GetHeadshotViewportInfo( characterName: string ): ( {} )
    assert( tGetHeadshotViewportInfo(characterName) )

    local characterData: {} = CharacterHelper.GetDataByName( characterName )

    local displayRig: Model = characterData.Folder.Rig

    local cameraOffset: Vector3 = displayRig:GetAttribute( "HeadshotCameraOffset" ) or Vector3.new()
    local objectOffset: Vector3 = displayRig:GetAttribute( "HeadshotOffset" ) or Vector3.new()
    local objectRotation: Vector3 = displayRig:GetAttribute( "HeadshotRotation" ) or Vector3.new()

    return {
        Prefab = displayRig;
        CameraOffset = CFrame.new( cameraOffset );
        ObjectOffset = CFrame.Angles( math.rad(objectRotation.X), math.rad(objectRotation.Y), math.rad(objectRotation.Z) ) * CFrame.new( objectOffset );
        Animation = characterData.Folder.Animations.Pose;
    }
end

return CharacterHelper