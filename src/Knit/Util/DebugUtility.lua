-- DebugUtility
-- Author(s): Evaera, Reformatted by Jesse Appleton
-- Date: 01/01/2022

--[[
    -- Arrow Debuggers
        DebugUtility.DrawArrowBetweenPoints( name: string, to: Vector3, from: Vector3[, config: table?] ) -> Creates an arrow between from and to
        DebugUtility.DrawArrowAtPoint( name: string, point: Vector3[, config: table] ) -> Creates an arrow facing upwards at point
        DebugUtility.DrawArrowFromCFrame( name: string, cframe: CFrame[, config: table?] ) - > Create an arrow at the CFrame's position facing the CFrame's LookVector
        DebugUtility.DrawArrowBetweenParts( name: string, instanceA: Instance, instanceB: Instance[, config: table?] ) -> Create an arrow between two parts or attachments
        DebugUtility.DrawArrowFromPart( name: string, part: BasePart[, config: table?] ) -> Creates an arrow representing the part's CFrame

        Arrow Configurations (sent in config dictionary)
            Color: Color3 // The color of the arrow (default random)
            Scale: number // The scale of the arrow (default 1)
			AlwaysOnTop: boolean // Does this arrow draw on top?
]]

---------------------------------------------------------------------

-- Modules
local t = require( script.Parent.t )

-- Constants

-- Roblox Services

-- Variables

---------------------------------------------------------------------

local DebugUtility = {}


-- Returns a dictionary with Shaft, Point and Container
function DebugUtility._getArrowFromName( name: string ): ( table )
	local container = workspace:FindFirstChild( "DebugArrows" ) or Instance.new( "Folder" )
	if ( container.Parent == nil ) then
		container.Name = "DebugArrows"
		container.Parent = workspace
	end

	local randomColor = BrickColor.Random().Color

	local shaft = container:FindFirstChild( name .. "_shaft" ) or Instance.new( "CylinderHandleAdornment" );
	if ( shaft.Parent == nil ) then
		shaft.Name = name .. "_shaft"
		shaft.Color3 = randomColor
		shaft.Radius = 0.15
		shaft.Adornee = workspace.Terrain
		shaft.Transparency = 0
		shaft.Radius = 1
		shaft.Transparency = 0
		shaft.AlwaysOnTop = true
		shaft.ZIndex = 1
	end

	local point = container:FindFirstChild( name .. "_point" ) or Instance.new( "ConeHandleAdornment" );
	if ( point.Parent == nil ) then
		point.Name = name .. "_point"
		point.Color3 = randomColor
		point.Radius = 0.5
		point.Transparency = 0
		point.Adornee = workspace.Terrain
		point.Height = 1
		point.AlwaysOnTop = true
		point.ZIndex = 1
	end

	return {
		Shaft = shaft;
		Point = point;
		Container = container;
	}
end


local tDrawArrowBetweenPoints = t.tuple( t.string, t.Vector3, t.Vector3, t.optional(t.table) )
function DebugUtility.DrawArrowBetweenPoints( name: string, from: Vector3, to: Vector3, config: table? ): ()
	assert( tDrawArrowBetweenPoints(name, from, to) )

	config = config or {}

	local arrow: table = DebugUtility._getArrowFromName( name )

	local color = config.Color or arrow.Shaft.Color3
	local scale = config.Scale or 1

	local shaft: CylinderHandleAdornment = arrow.Shaft
	shaft.Color3 = color
	shaft.AlwaysOnTop = if ( config.AlwaysOnTop ~= nil ) then config.AlwaysOnTop else true
	shaft.Radius = 0.15 * scale
	shaft.ZIndex = 5 - math.ceil( scale )
	shaft.CFrame = CFrame.lookAt(
		((from + to)/2) - ((to - from).Unit * 1),
		to
	)
	shaft.Height = ( from - to ).Magnitude - 2

	local pointScale = ( scale == 1 and 1 ) or scale * 1.4
	local point: LineHandleAdornment = arrow.Point
	point.Color3 = color
	point.AlwaysOnTop = if ( config.AlwaysOnTop ~= nil ) then config.AlwaysOnTop else true
	point.Radius = 0.5 * pointScale
	point.Height = 2 * pointScale
	point.ZIndex = 5 - math.ceil( pointScale )
	point.CFrame = CFrame.lookAt( (CFrame.lookAt(to, from) * CFrame.new(0, 0, -2.5 - ((scale-1)/2))).Position, to )

	shaft.Parent = arrow.Container
	point.Parent = arrow.Container
end


local tDrawArrowAtPoint = t.tuple( t.string, t.Vector3, t.optional(t.table) )
function DebugUtility.DrawArrowAtPoint( name: string, point: Vector3, config: table? ): ()
	assert( tDrawArrowAtPoint(name, point, config) )

	return DebugUtility.DrawArrowBetweenPoints( name, point, point + Vector3.new(0,5,0), config )
end


local tDrawArrowFromCFrame = t.tuple( t.string, t.CFrame, t.optional(t.table) )
function DebugUtility.DrawArrowFromCFrame( name: string, cframe: CFrame, config: table? ): ()
	assert( tDrawArrowFromCFrame(name, cframe, config) )

	return DebugUtility.DrawArrowBetweenPoints( name, cframe.Position, cframe.Position + (cframe.LookVector*5), config )
end


local tDrawArrowFromPart = t.tuple( t.string, t.instanceIsA("BasePart"), t.optional(t.table) )
function DebugUtility.DrawArrowFromPart( name: string, part: BasePart, config: table? ): ()
	assert( tDrawArrowFromPart(name, part, config) )

	return DebugUtility.DrawArrowFromCFrame( name, part.CFrame, config )
end


local tDrawArrowBetweenParts = t.tuple( t.string, t.union(t.instanceIsA("BasePart"), t.instanceIsA("Attachment")), t.union(t.instanceIsA("BasePart"), t.instanceIsA("Attachment")), t.optional(t.table) )
function DebugUtility.DrawArrowBetweenParts( name: string, instanceA: Instance, instanceB: Instance, config: table? ): ()
	assert( tDrawArrowBetweenParts(name, instanceA, instanceB, config) )

	local positionA = ( instanceA:IsA("BasePart") and instanceA.Position ) or instanceA.WorldPosition
	local positionB = ( instanceB:IsA("BasePart") and instanceB.Position ) or instanceB.WorldPosition

	return DebugUtility.DrawArrowBetweenPoints( name, positionA, positionB, config )
end


return DebugUtility