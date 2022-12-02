local Knit = require( game.ReplicatedStorage.Knit )
local t = require( Knit.Util.t )

local WeaponData = Knit.GameData.WeaponData

local WeaponHelper = {}

function WeaponHelper.GetDataByName( weaponName: string ): {}?
    for _, data in pairs( WeaponData.Weapons ) do 
        if data.Name == weaponName then 
            return data
        end
    end

    warn(weaponName, "Not found in weapon data")
end

return WeaponHelper