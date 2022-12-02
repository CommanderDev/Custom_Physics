-- CollisionService
-- Author(s): Jesse Appleton
-- Date: 11/04/2022

--[[
    
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Modules

-- Roblox Services
local CollectionService = game:GetService("CollectionService")
-- Variables

-- Objects

---------------------------------------------------------------------


local CollisionService = Knit.CreateService {
    Name = "CollisionService";
    Client = {
        
    };
}


function CollisionService:KnitStart(): ()
end


function CollisionService:KnitInit(): ()
    for _, object: BasePart | Folder | Model in pairs( workspace.Map.Collision:GetDescendants() ) do 
        if object:IsA("BasePart") or object:IsA("MeshPart") then 
            CollectionService:AddTag(object, "Collision")
        end
    end
end


return CollisionService