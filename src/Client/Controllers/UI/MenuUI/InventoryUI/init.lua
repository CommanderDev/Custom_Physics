type InventoryEntry = {
    GUID: string,
    Name: string,
}

--Knit
local Knit = require( game.ReplicatedStorage.Knit )

--Modules

local WeaponInventory = require( script.WeaponInventory )
--Variables

local InventoryUI = {
}
function InventoryUI.Setup( UI: {}, holder: Frame )
    WeaponInventory.Setup(UI, holder)
end

return InventoryUI