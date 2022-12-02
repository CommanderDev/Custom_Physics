local Knit = require( game.ReplicatedStorage.Knit )

local InventoryHelper = require( Knit.Helpers.InventoryHelper )
local data = {
    -- CURRENCIES
    Copper = 0;
    Silver = 0;
    Gold = 0;
    --Progression Data
    Armor = {};
    Weapons = {};
    EquippedWeapon = nil;
    InventoryCapacity = 20;
    --Misc
    Achievements = {};
    DailyQuests = {};
    RewardBanks = {};

    -- Settings
    ClientSettings = {};

    -- CODES
    RedeemedCodes = {};

    -- RECEIPTS OF ROBUX PURCHASES
    RobuxReceipts = {}; -- List of developer product receipt ids to prevent double granting
    OwnedGamepasses = {}; -- List of GamepassIds which the player owns
    ProcessedGamepasses = {}; -- List of GamepassIds which have already been processed
}

InventoryHelper.AddToInventory(data.Weapons, {
    Name = "Broadsword"
})

local function GetPlayerDataTemplate()
    local formattedData = {}
    for key, value in pairs( data ) do
        if ( type(value) == "function" ) then
            formattedData[ key ] = value()
        else
            formattedData[ key ] = value
        end
    end
    return formattedData
end

return GetPlayerDataTemplate()