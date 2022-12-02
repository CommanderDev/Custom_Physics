-- DeepReplicate
-- Author(s): Jesse Appleton
-- Date: 01/12/2022

--[[
    Deep replicates object in it's entirety, or just it's children

    Function DeepReplicate( instance: Instance, parent: Instance, delayBuffer: number, keepOnlyChildren: boolean ): nil
    instance being cloned, parent cloning into, how many clones before pause, preserve parent object or not
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Roblox Services
local CollectionService = game:GetService( "CollectionService" )

-- Variables
local ObjectModelTable: {} = {}
local PrimaryPartModelTable: {} = {}
---------------------------------------------------------------------

local DeepReplicate = {}


local function DeepReplicateHelper( instance: Instance, parent: Instance, delayBuffer: number?, keepOnlyChildren: boolean?, additionalTags: {}? ): nil
    additionalTags = additionalTags or {}
    if not ( instance:IsA("PackageLink") ) then
        if ( instance:IsA("Folder") ) then
            local workspaceFolder: Instance = workspace:FindFirstChild( instance.Name, true )
            if ( workspaceFolder ) then
                for _, child in pairs( instance:GetChildren() ) do
                    DeepReplicateHelper( child, workspaceFolder, delayBuffer, keepOnlyChildren, additionalTags )
                end
            end
        else
        
            local newInstance: Instance = instance:Clone()
            local oldTags: {}? = CollectionService:GetTags( newInstance )
            for _, oldTag in pairs ( oldTags ) do
                local foundAdditionalTag: {}|boolean = table.find( additionalTags, oldTag ) or false
                if ( foundAdditionalTag ) then
                    table.remove( oldTags, foundAdditionalTag )
                end
            end

            --After purging, do any tags still exist?
            if ( #oldTags >= 1 ) then
                local newObjectTable: {[Instance]: {}} = {}
                newObjectTable[ newInstance ] = oldTags
                table.insert(ObjectModelTable, newObjectTable )
            end

            --Does this have a primary part?
            local newPrimaryPart: Instance|boolean = false
            if ( instance:IsA("Model") ) then
               newPrimaryPart = instance.PrimaryPart or false
            end

            if ( newPrimaryPart ) then
                local newPrimaryPartTable: {[Instance]: string} = {}
                newPrimaryPartTable[ newInstance ] = newPrimaryPart.Name
                table.insert(PrimaryPartModelTable, newPrimaryPartTable)
            end

            for _, tag in pairs( oldTags ) do
                CollectionService:RemoveTag( newInstance, tag )
            end

            newInstance:ClearAllChildren()
            newInstance.Parent = parent

            for _, tag in pairs( additionalTags ) do
                CollectionService:AddTag( newInstance, tag )
            end

            for _, child in pairs( instance:GetChildren() ) do
                DeepReplicateHelper( child, newInstance )
            end
        end
    end
end


function DeepReplicate( instance: Instance, parent: Instance, delayBuffer: number?, keepOnlyChildren: boolean?, additionalTags: {}? ): nil
    local childrenCloneId: number = 0
    ObjectModelTable = {}
    PrimaryPartModelTable = {}

    if ( keepOnlyChildren ) then
        local instanceChildren: {}? = instance:GetChildren()

        for child = 1, #instanceChildren do
            childrenCloneId += 1
            if ( (childrenCloneId%delayBuffer) == 0 ) then
                task.wait()
                childrenCloneId = 0
            end
            DeepReplicateHelper( instanceChildren[child], parent, delayBuffer, keepOnlyChildren, additionalTags )

        end
    else
        DeepReplicateHelper( instance, parent, delayBuffer, keepOnlyChildren, additionalTags )
    end

    if ( #PrimaryPartModelTable >= 1 ) then
        for index = 1, #PrimaryPartModelTable do
            for clonedObject, primaryPart in pairs( PrimaryPartModelTable[ index ] ) do
                local findPrimaryPart: Instance|boolean = clonedObject:FindFirstChild( primaryPart, true ) or false
                if ( findPrimaryPart ) then
                    clonedObject.PrimaryPart = clonedObject:FindFirstChild( primaryPart, true )
                end
            end
        end
    end

    if ( #ObjectModelTable >= 1 ) then
        for index = 1, #ObjectModelTable do
            for clonedObject, tags in pairs( ObjectModelTable[ index ] ) do
                for _, tag in pairs( tags ) do
                    CollectionService:AddTag( clonedObject, tag )
                end
            end
        end
    end

    ObjectModelTable = {}
    PrimaryPartModelTable = {}
end

return DeepReplicate
