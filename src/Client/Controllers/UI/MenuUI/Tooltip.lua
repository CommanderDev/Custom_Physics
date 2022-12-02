---@diagnostic disable: redundant-parameter
--Knit 
local Knit = require( game.ReplicatedStorage.Knit )
local Create = require( Knit.Util.Create )

local WeaponHelper = require( Knit.Helpers.WeaponHelper )

local Tooltip = {
    isVisible = false;
}

function Tooltip._findOrCreateTip( index: number ): TextLabel
    
    local label: TextLabel = Tooltip.Frame:FindFirstChild(index) or Create("TextLabel", {
        Name = index;
        BackgroundTransparency = 1;
        TextSize = 20;
        TextColor3 = Color3.new(1,1,1);
        TextStrokeColor3 = Color3.fromRGB(125);
        TextStrokeTransparency = 0.5;
        TextScaled = true; 
        Font = Enum.Font.FredokaOne;
        LayoutOrder = index;
        Parent = Tooltip.Frame;
    })

    return label
end

function Tooltip.Update()
    Tooltip.Frame.Visible = ( not not Tooltip.isVisible )
end

function Tooltip.Show(entryData: {} ): ()
    local dataParsed: number = 0
    local weaponData = WeaponHelper.GetDataByName(entryData.Name)
    Tooltip.TipName.Text = "Name: "..weaponData.Name
    for name: string, value: string | number in pairs( weaponData ) do 
        if name == "GUID" or name == "Name" then continue end
        dataParsed += 1
        local label = Tooltip._findOrCreateTip(dataParsed)
        label.Text = name..": "..value
    end

    Tooltip.isVisible = true
    Tooltip.Update()
end

function Tooltip.Hide(): ()
    Tooltip.isVisible = false
    Tooltip.Update()
end

function Tooltip.Setup()
    Tooltip.Frame = Create("Frame", {
        Name = "Tooltip";
        Size = UDim2.new(0.1, 0, 0.1, 0);
        SizeConstraint = Enum.SizeConstraint.RelativeXX;
        Visible = Tooltip.isVisible;
        Parent = Knit.MainUI;
    });
    Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(170)),
            ColorSequenceKeypoint.new(0.929, Color3.fromRGB(121)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(57))
        };
        Parent = Tooltip.Frame
    })
    Create("UIGridLayout", {
        CellSize = UDim2.new(1, 0, 0.15, 0);
        CellPadding = UDim2.new(0, 0, 0.05, 0);
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Tooltip.Frame;
    })

    Tooltip.TipName = Create("TextLabel", {
        Name = "TipName";
        BackgroundTransparency = 1;
        TextSize = 20;
        TextColor3 = Color3.new(1,1,1);
        TextStrokeColor3 = Color3.fromRGB(125);
        TextStrokeTransparency = 0.5;
        TextScaled = true; 
        Font = Enum.Font.FredokaOne;
        LayoutOrder = 0;
        Parent = Tooltip.Frame;
    })
end


return Tooltip