-- InventoryUI
-- Author(s): Jesse Appleton
-- Date: 11/05/2022

--[[
    
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

-- Modules
local InventoryUI = require( script.InventoryUI )
local Tooltip = require( script.Tooltip )

-- Roblox Services

-- Variables

-- Objects
local InventoryFrame = Knit.MainUI:WaitForChild("InventoryFrame")

---------------------------------------------------------------------

local MenuUI = Knit.CreateController { Name = "MenuUI" }


function MenuUI:KnitStart(): ()
    self.Tooltip = Tooltip
    InventoryUI.Setup(self, InventoryFrame)
    Tooltip.Setup(self)
end


function MenuUI:KnitInit(): ()
    
end


return MenuUI