--Knit
local Knit = require( game.ReplicatedStorage.Knit )
local Create = require( Knit.Util.Create )
local Signal = require( Knit.Util.Signal )
local CallbackQueue = require( Knit.Util.CallbackQueue )

--Modules 
local DataController = Knit.GetController("DataController")

local InventoryHelper = require( Knit.Helpers.InventoryHelper )

local ItemEntry = require( Knit.Modules.UI.ItemEntry )
local WeaponData = Knit.GameData.WeaponData
local ArmorData = Knit.GameData.ArmorData

--Variables 
local UpdateQueue = CallbackQueue.new( 5 )

local WeaponInventory = {
    Entries = {};
    SelectionChanged = Signal.new();
} 

function WeaponInventory._findOrCreateEntry( itemData: {} ): ()
    local itemName: string = itemData.Name
    local findEntry: {} = WeaponInventory.Entries[ itemName ]
    if ( findEntry ) then
        return findEntry
    end

    local newEntry: {} = ItemEntry.new( true )
    WeaponInventory.Entries[ itemName ] = newEntry
    newEntry:SetRarity( itemData.Rarity )
    newEntry.Button.Parent = WeaponInventory.Scroller

    -- Update selected data on click
    newEntry._janitor:Add(newEntry.Button.MouseButton1Click:Connect(function()
    end))

    return newEntry
end

function WeaponInventory.UpdateEntries( inventoryEntries: {InventoryEntry} ): ()
    local weapons: {InventoryEntry} = WeaponData.Weapons
    local equippedWeapon: string? = DataController:GetDataByName("EquippedWeapon")

    for _, inventoryData in pairs( inventoryEntries ) do
        local entryData: InventoryEntry? = InventoryHelper.GetInventoryEntryByName( inventoryEntries, inventoryData.Name)
        local entry: {} = WeaponInventory._findOrCreateEntry( inventoryData )
        
        if ( entryData ) then 
            entry.GUID = entryData.GUID
            entry.Data = entryData
        end

        entry._janitor:Add( entry.Button.MouseEnter:Connect(function()
            WeaponInventory.Tooltip.Show(entryData, "Weapon")
        end))

        entry._janitor:Add( entry.Button.MouseLeave:Connect(function()
            WeaponInventory.Tooltip.Hide()
        end))
        local weaponPrefab = Knit.Assets.Content.WeaponModels[ entryData.Name ]
        entry:SetViewportDisplay( weaponPrefab, CFrame.new(0,1.5,8), CFrame.Angles(0, math.rad(90), math.rad(-90)), false )
    end
end

function WeaponInventory.Setup( UI: {}, holder: Frame )
    WeaponInventory.Scroller  = Create( "ScrollingFrame", {
        Name = "InventoryScroller";
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Size = UDim2.new( 0.9, 0, 0.8, 0  );
        Position = UDim2.new(0.05, 0, 0.1, 0);
        CanvasSize = UDim2.new( 0, 0, 0, 0 );
        ScrollBarImageColor3 = Color3.new( 0, 0, 0 );
        AutomaticCanvasSize = Enum.AutomaticSize.Y;
        ScrollingDirection = Enum.ScrollingDirection.Y;
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar;
        ScrollBarThickness = 10;
        Parent = holder;
    })
    local gridLayout: UIGridLayout = Create( "UIGridLayout", {
        CellPadding = UDim2.new();
        CellSize = UDim2.new();
        FillDirection = Enum.FillDirection.Horizontal;
        HorizontalAlignment = Enum.HorizontalAlignment.Left;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = WeaponInventory.Scroller;
    })

    local uiPadding: UIPadding = Create( "UIPadding", {
        Parent = WeaponInventory.Scroller
    })

    local function UpdateScaling(): ()
        local sizeX: number = WeaponInventory.Scroller.AbsoluteCanvasSize.X
        local padding: number = math.round( sizeX * 0.01 )
        local sizeX: number = math.round( sizeX * 0.14 )
        local sizeY: number = math.round( sizeX * 0.7 )

        gridLayout.CellPadding = UDim2.new( 0, padding, 0, padding )
        gridLayout.CellSize = UDim2.new( 0, sizeX, 0, sizeY )

        uiPadding.PaddingBottom = UDim.new( 0, padding )
        uiPadding.PaddingTop = UDim.new( 0, padding )
        uiPadding.PaddingLeft = UDim.new( 0, padding )
        uiPadding.PaddingRight = UDim.new( 0, padding )
    end
    WeaponInventory.Scroller:GetPropertyChangedSignal( "AbsoluteSize" ):Connect( UpdateScaling )
    
    local function OnDataChanged(inventory): ()
        UpdateQueue:Add( WeaponInventory.UpdateEntries, inventory)
    end

    DataController:ObserveDataChanged("Weapons", OnDataChanged)
    local function OnSelectionChanged( newSelection: {}? )
        newSelection = newSelection or {}
        for _, entry in pairs( WeaponInventory.Entries ) do
            entry:SetSelected( entry.GUID == newSelection.GUID )
        end
    end

    WeaponInventory.SelectionChanged:Connect( OnSelectionChanged )
    task.spawn( OnSelectionChanged, WeaponInventory.Selection)
    WeaponInventory.Tooltip = UI.Tooltip
end

return WeaponInventory