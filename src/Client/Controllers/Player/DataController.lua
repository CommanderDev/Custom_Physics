-- DataController
-- Author(s): Jesse Appleton
-- Date: 12/06/2021

--[[
    FUNCTION    DataController:GetDataByName( name: string ) -> ( any? )
    FUNCTION    DataController:GetDataChangedSignal( name: string, createIfNoExists: boolean ) -> ( Signal? )
    FUNCTION    DataController:ObserveDataChanged( name: string, callback: ()->() ) -> ( Connection )
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local Signal = require( Knit.Util.Signal )
local Promise = require( Knit.Util.Promise )
local t = require( Knit.Util.t )
local DataService = Knit.GetService( "DataService" )

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local DataController = Knit.CreateController {
    Name = "DataController";
    Data = {};
    ChangedSignals = {};
    Initialized = false;
    InitializationComplete = Signal.new();
}


function DataController:WaitForInitialization(): ()
    return self.Initialized or self.InitializationComplete:Wait()
end


local tGetDataByName = t.tuple( t.string )
function DataController:GetDataByName( name: string ): ( any? )
    assert( tGetDataByName(name) )
    self:WaitForInitialization()
    return self.Data[ name ]
end


local tGetDataChangedSignal = t.tuple( t.string, t.optional(t.boolean) )
function DataController:GetDataChangedSignal( name: string, createIfNoExists: boolean? ): ( table )
    assert( tGetDataChangedSignal(name, createIfNoExists) )
    if ( not createIfNoExists ) then
        self:WaitForInitialization()
    end

    local findSignal = self.ChangedSignals[ name ]
    if ( findSignal ) then
        return findSignal
    elseif ( createIfNoExists ) then 
        local newSignal = Signal.new()
        self.ChangedSignals[ name ] = newSignal
        return newSignal
    else
        return error( "No data changed signal found for \"" .. tostring(name) .. "\"!" )
    end
end


local tObserveDataChanged = t.tuple( t.string, t.callback )
function DataController:ObserveDataChanged( name: string, callback: ()->() ): ()
    assert( tObserveDataChanged(name, callback) )
    local dataChangedSignal = self:GetDataChangedSignal( name )
    local function Update( ... )
        callback( ... )
    end
    Update( self:GetDataByName(name) )
    return dataChangedSignal:Connect( Update )
end


function DataController:_recieveDataUpdate( name: string, value: any? ): ( any? )
    local changedSignal = self:GetDataChangedSignal( name, true )
    --print( "Recieved data update for", name, "| Value:", value )
    self.Data[ name ] = value
    changedSignal:Fire( value )
end


function DataController:_recieveTableIndexUpdate( name: string, index: string, value: any? ): ()
    local changedSignal = self:GetDataChangedSignal( name, true )
    local findTable: {} = self:GetDataByName( name )
    if ( typeof(findTable) == "table" ) then
        findTable[ index ] = value
        changedSignal:Fire( findTable )
    end
end


function DataController:KnitStart(): ()
    local dataPromise = Promise.new(function( resolve, reject )
        local function GetData()
            return pcall(function()
                return DataService:GetPlayerData()
            end)
        end

        local success, data
        repeat
            success, data = GetData()
        until ( success and data ) or ( not task.wait(1) )

        resolve( data )
    end):andThen(function( data )
        for name, value in pairs( data ) do
            task.spawn( self._recieveDataUpdate, self, name, value )
        end

        self.Initialized = true
        self.InitializationComplete:Fire()
    end):catch(warn )
end


function DataController:KnitInit(): nil
    DataService.ReplicateData:Connect(function( ... )
        self:_recieveDataUpdate( ... )
    end)

    DataService.ReplicateTableIndex:Connect(function( ... )
        self:_recieveTableIndexUpdate( ... )
    end)
end


return DataController