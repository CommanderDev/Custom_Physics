-- WeaponService
-- Author(s): Jesse Appleton
-- Date: 11/05/2022

--[[
    
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Modules

-- Roblox Services

-- Variables

-- Objects
local Weapons = Knit.Assets.Content.Weapons

---------------------------------------------------------------------


local WeaponService = Knit.CreateService {
    Name = "WeaponService";
    Client = {
        
    };
}


function WeaponService:KnitStart(): ()
    local weaponsModelFolder: Folder = Instance.new("Folder")
    weaponsModelFolder.Name = "WeaponModels"

    for _, weapon in pairs( Weapons:GetChildren() ) do 
        local model = Instance.new("Model")
        model.Name = weapon.Name
        for _, part in pairs( weapon:GetChildren() ) do 
            part:Clone().Parent = model
        end
        model.PrimaryPart = model.Handle
        model.Parent = weaponsModelFolder
    end
    weaponsModelFolder.Parent = Knit.Assets.Content
end


function WeaponService:KnitInit(): ()
    
end


return WeaponService