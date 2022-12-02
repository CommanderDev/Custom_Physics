-- InventoryHelper
-- Author(s): Jesse Appleton
-- Date: 02/17/2022

--[[
    SERVER-ONLY
        FUNCTION    InventoryHelper.AddToInventory( inventory: {}, entry: {} ) -> ( boolean, {[string]: any} )
        FUNCTION    InventoryHelper.AddBatchToInventory( inventory: {}, batchData: {{}} ) -> ( boolean )
        FUNCTION    InventoryHelper.RemoveFromInventoryByName( inventory: {}, name: string, count: number? = 1 ) -> ( boolean, {string} )
        FUNCTION    InventoryHelper.RemoveBatchFromInventoryByGUID( inventory: {}, guids: {string} ) -> ( boolean, {string} )

    SHARED
        FUNCTION    InventoryHelper.GetUniqueInventoryEntryNames( inventory: {} ) -> ( {} )
        FUNCTION    InventoryHelper.CountInventoryEntries( inventory: {} ) -> ( number )
        FUNCTION    InventoryHelper.CountInventoryEntriesByName( inventory: {}, name: string ) -> ( number )
        FUNCTION    InventoryHelper.GetInventoryEntriesByName( inventory: {}, name: string, count: number? = 1 ) -> ( {} )
        FUNCTION    InventoryHelper.GetInventoryEntryByName( inventory: {}, name: string ) -> ( {}? )
        FUNCTION    InventoryHelper.GetInventoryEntryByGUID( inventory: {}, guid: string ) -> ( {}? )
        FUNCTION    InventoryHelper.GetLowestLevelEntry( inventory: {} ) -> ( {}? )
        FUNCTION    InventoryHelper.GetHighestLevelEntry( inventory: {} ) -> ( {}? )
        FUNCTION    InventoryHelper.GetInventoryEntriesByNameIgnoreGUID( inventory: {}, ignoreGUID: string, name: string, count: number? = 1 ) -> ( {} )
]]

---------------------------------------------------------------------


-- Types
type InventoryEntry = {
    GUID: string,
    Name: string,
    [string]: any
}


-- Constants
local IS_SERVER = game:GetService( "RunService" ):IsServer()

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )
local t = require( Knit.Util.t )
local CallbackQueue = require( Knit.Util.CallbackQueue )

-- Roblox Services
local HttpService = game:GetService( "HttpService" )

-- Variables
local EditQueue = CallbackQueue.new( 1 )

---------------------------------------------------------------------

local function SingleThreadedCallback( callback ): ( (...any)->(...any) )
    return function( ... )
        return EditQueue:AddAsync( callback, ... )
    end
end

local function ServerOnly()
    return IS_SERVER, "Attempted to use a server-only method!"
end


local function IsValidInventory()
    return t.values( t.keys(t.string) )
end


local InventoryHelper = {}


local tGetUniqueEntryNames = t.tuple( IsValidInventory )
function InventoryHelper.GetUniqueInventoryEntryNames( inventory: {InventoryEntry} ): ( {string} )
    assert( tGetUniqueEntryNames(inventory) )

    local uniqueNames: {string} = {}
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( not table.find(uniqueNames, data.Name) ) then
            table.insert( uniqueNames, data.Name )
        end
    end

    return uniqueNames
end


local tCountInventoryEntries = t.tuple( IsValidInventory )
function InventoryHelper.CountInventoryEntries( inventory: {InventoryEntry} ): ( number )
    assert( tCountInventoryEntries(inventory) )

    local count: number = 0
    for _ in pairs( inventory ) do
        count += 1
    end

    return count
end


local tCountInventoryEntriesWithFilter = t.tuple( IsValidInventory, t.callback )
function InventoryHelper.CountInventoryEntriesWithFilter( inventory: {InventoryEntry}, filter: (InventoryEntry)->(boolean) ): ( number )
    assert( tCountInventoryEntriesWithFilter(inventory, filter) )

    local count: number = 0
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( filter(data) ) then
            count += 1
        end
    end

    return count
end


local tCountInventoryEntriesByName = t.tuple( IsValidInventory, t.string )
function InventoryHelper.CountInventoryEntriesByName( inventory: {InventoryEntry}, name: string ): ( number )
    assert( tCountInventoryEntriesByName(inventory, name) )

    local count: number = 0
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( data.Name == name ) then
            count += 1
        end
    end

    return count
end


local tGetInventoryEntryByGUID = t.tuple( IsValidInventory, t.string )
function InventoryHelper.GetInventoryEntryByGUID( inventory: {InventoryEntry}, guid: string ): ( InventoryEntry? )
    assert( tGetInventoryEntryByGUID(inventory, guid) )

    for _, data: InventoryEntry in pairs( inventory ) do
        if ( data.GUID == guid ) then
            return data
        end
    end

    return nil
end


local tGetInventoryEntryByGUID = t.tuple( IsValidInventory, t.string )
function InventoryHelper.GetInventoryEntryByName( inventory: {InventoryEntry}, name: string ): ( InventoryEntry? )
    assert( tGetInventoryEntryByGUID(inventory, name) )

    for _, data: InventoryEntry in pairs( inventory ) do
        if ( data.Name == name ) then
            return data
        end
    end

    return nil
end


local tGetLowestLevelEntry = t.tuple( IsValidInventory )
function InventoryHelper.GetLowestLevelEntry( inventory: {InventoryEntry} ): ()
    assert( tGetLowestLevelEntry(inventory) )

    local selectedEntry, selectedLevel
    for _, entry: InventoryEntry in pairs( inventory ) do
        local entryLevel: number? = entry.Level
        if ( entryLevel ) and ( (not selectedEntry) or (selectedLevel > entryLevel) ) then
            selectedEntry, selectedLevel = entry, entryLevel
        end
    end

    return selectedEntry
end


local tGetHighestLevelEntry = t.tuple( IsValidInventory )
function InventoryHelper.GetHighestLevelEntry( inventory: {InventoryEntry} ): ()
    assert( tGetHighestLevelEntry(inventory) )

    local selectedEntry, selectedLevel
    for _, entry: InventoryEntry in pairs( inventory ) do
        local entryLevel: number? = entry.Level
        if ( entryLevel ) and ( (not selectedEntry) or (selectedLevel < entryLevel) ) then
            selectedEntry, selectedLevel = entry, entryLevel
        end
    end

    return selectedEntry
end


local tGetInventoryEntriesByName = t.tuple( IsValidInventory, t.string, t.string, t.optional(t.every(t.integer, t.numberPositive)) )
function InventoryHelper.GetInventoryEntriesByNameIgnoreGUID( inventory: {InventoryEntry}, ignoreGUID: string, name: string, count: number? ): ( {InventoryEntry} )
    assert( tGetInventoryEntriesByName(inventory, ignoreGUID, name, count) )

    count = count or 1

    local sortedEntries: {InventoryEntry} = {}
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( data.Name == name ) and ( data.GUID ~= ignoreGUID ) then
            table.insert( sortedEntries, data )
        end
    end

    table.sort(sortedEntries, function(a, b)
        return ( a.Level or 0 ) < ( b.Level or 0 )
    end)

    local foundEntries: {InventoryEntry} = {}
    for i = 1, math.min(count, #sortedEntries) do
        table.insert( foundEntries, sortedEntries[i] )
    end

    return foundEntries
end


local tGetInventoryEntriesByName = t.tuple( IsValidInventory, t.optional(t.every(t.integer, t.numberPositive)), t.callback )
function InventoryHelper.GetInventoryEntriesWithFilter( inventory: {InventoryEntry}, maxCount: number?, filter: (InventoryEntry)->(boolean) ): ( {InventoryEntry} )
    assert( tGetInventoryEntriesByName(inventory, maxCount, filter) )

    maxCount = maxCount or 1

    local sortedEntries: {InventoryEntry} = {}
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( filter(data) ) then
            table.insert( sortedEntries, data )
        end
    end

    table.sort(sortedEntries, function(a, b)
        return ( a.Level or 0 ) < ( b.Level or 0 )
    end)

    local foundEntries: {InventoryEntry} = {}
    for i = 1, math.min(maxCount, #sortedEntries) do
        table.insert( foundEntries, sortedEntries[i] )
    end

    return foundEntries
end


local tGetInventoryEntriesByName = t.tuple( IsValidInventory, t.string, t.optional(t.every(t.integer, t.numberPositive)) )
function InventoryHelper.GetInventoryEntriesByName( inventory: {InventoryEntry}, name: string, count: number? ): ( {InventoryEntry} )
    assert( tGetInventoryEntriesByName(inventory, name, count) )

    count = count or 1

    local sortedEntries: {InventoryEntry} = {}
    for _, data: InventoryEntry in pairs( inventory ) do
        if ( data.Name == name ) then
            table.insert( sortedEntries, data )
        end
    end

    table.sort(sortedEntries, function(a, b)
        return ( a.Level or 0 ) < ( b.Level or 0 )
    end)

    local foundEntries: {InventoryEntry} = {}
    for i = 1, math.min(count, #sortedEntries) do
        table.insert( foundEntries, sortedEntries[i] )
    end

    return foundEntries
end


local tAddToInventory = t.tuple( IsValidInventory, t.keys(t.string) )
function InventoryHelper.AddToInventory( inventory: {InventoryEntry}, data: InventoryEntry ): ( boolean, InventoryEntry )
    assert( ServerOnly() )
    assert( tAddToInventory(inventory, data) )

    if ( not data.GUID ) then
        data.GUID = HttpService:GenerateGUID( false )
    end

    inventory[ data.GUID ] = data

    return true, data
end
InventoryHelper.AddToInventory = SingleThreadedCallback( InventoryHelper.AddToInventory )


local tAddBatchToInventory = t.tuple( IsValidInventory, t.values(t.table) )
function InventoryHelper.AddBatchToInventory( inventory: {InventoryEntry}, dataBatch: {InventoryEntry} ): ( boolean )
    assert( ServerOnly() )
    assert( tAddBatchToInventory(inventory, dataBatch) )

    for _, data: InventoryEntry in pairs( dataBatch ) do
        if ( not data.GUID ) then
            data.GUID = HttpService:GenerateGUID( false )
        end
        inventory[ data.GUID ] = data
    end

    return true
end
InventoryHelper.AddBatchToInventory = SingleThreadedCallback( InventoryHelper.AddBatchToInventory )


local tRemoveFromInventoryByName = t.tuple( IsValidInventory, t.string, t.optional(t.every(t.numberPositive, t.integer)) )
function InventoryHelper.RemoveFromInventoryByName( inventory: {InventoryEntry}, name: string, count: number? ): ( boolean, {string} )
    assert( ServerOnly() )
    assert( tRemoveFromInventoryByName(inventory, name, count) )

    count = count or 1

    local entriesRemoved: {} = {}
    for index: string, data: InventoryEntry in pairs( inventory ) do
        if ( data.Name == name ) then
            table.insert( entriesRemoved, index )
            inventory[ index ] = nil

            count -= 1
            if ( count <= 0 ) then
                break
            end
        end
    end

    return ( #entriesRemoved > 0 ), entriesRemoved
end
InventoryHelper.RemoveFromInventoryByName = SingleThreadedCallback( InventoryHelper.RemoveFromInventoryByName )


local tRemoveFromInventoryByGUID = t.tuple( IsValidInventory, t.string )
function InventoryHelper.RemoveFromInventoryByGUID( inventory: {InventoryEntry}, guid: string ): ( boolean )
    assert( ServerOnly() )
    assert( tRemoveFromInventoryByGUID(inventory, guid) )

    local itemRemoved: boolean = false
    for index: string, data: InventoryEntry in pairs( inventory ) do
        if ( data.GUID == guid ) then
            itemRemoved = true
            inventory[ index ] = nil
            break
        end
    end

    return itemRemoved
end
InventoryHelper.RemoveFromInventoryByGUID = SingleThreadedCallback( InventoryHelper.RemoveFromInventoryByGUID )


local tRemoveBatchFromInventoryByGUID = t.tuple( IsValidInventory, t.values(t.string) )
function InventoryHelper.RemoveBatchFromInventoryByGUID( inventory: {InventoryEntry}, guids: {string} ): ( boolean, {string} )
    assert( ServerOnly() )
    assert( tRemoveBatchFromInventoryByGUID(inventory, guids) )

    local entriesRemoved: {string} = {}
    for _, guid: string in pairs( guids ) do
        for index: string, data: InventoryEntry in pairs( inventory ) do
            if ( data.GUID == guid ) then
                table.insert( entriesRemoved, index )
                inventory[ index ] = nil
                break
            end
        end
    end

    return ( #entriesRemoved > 0 ), entriesRemoved
end
InventoryHelper.RemoveBatchFromInventoryByGUID = SingleThreadedCallback( InventoryHelper.RemoveBatchFromInventoryByGUID )


return InventoryHelper