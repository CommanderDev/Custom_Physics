-- RotatedRegion
-- Author(s): Jesse Appleton

--[[
    EXAMPLE USAGE

    local newRegion = RotatedRegion.new( centerCFrame, regionSize )
    local partInRegion = newRegion:IsInRegion( part.Position )
]]

---------------------------------------------------------------------


-- Constants

-- Knit
local t = require( script.Parent.t )

-- Roblox Services
local Players = game:GetService("Players")

-- Variables

---------------------------------------------------------------------

local RotatedRegion = {}
RotatedRegion.__index = RotatedRegion


local tNewRegion = t.tuple( t.CFrame, t.Vector3 )
function RotatedRegion.new( centerCFrame: CFrame, size: Vector3 )
    assert( tNewRegion(centerCFrame, size) )

    local self = setmetatable( {}, RotatedRegion )
    self.SurfaceCountsAsCollision = true
    self.CFrame = centerCFrame
    self.Size = size
    self.Planes = {}

    for _, enum in next, Enum.NormalId:GetEnumItems() do
        local localNormal = Vector3.FromNormalId( enum )
        local worldNormal = self.CFrame:VectorToWorldSpace( localNormal )
        local distance = ( localNormal * self.Size/2 ).Magnitude
        local point = self.CFrame.Position + worldNormal * distance
        table.insert( self.Planes, {
            Normal = worldNormal;
            Point = point;
        } )
    end

    return self
end


local tVector3 = t.Vector3
function RotatedRegion:IsInRegion( vector3 )
    assert( tVector3(vector3) )

    for _, plane in next, ( self.Planes ) do
        local relativePosition = vector3 - plane.Point
        if ( self.SurfaceCountsAsCollision ) then
            if ( relativePosition:Dot(plane.Normal) >= 0 ) then
                return false
            end
        else
            if ( relativePosition:Dot(plane.Normal) > 0 ) then
                return false
            end
        end
    end

    return true, ( vector3 - self.CFrame.Position ).Magnitude
end


function RotatedRegion:GetPlayersInRegion()
    local players = {}
    for _, player in pairs( Players:GetPlayers() ) do
        local rootPart = player.Character and player.Character:FindFirstChild( "HumanoidRootPart" )
        if ( rootPart ) then
            if ( self:IsInRegion(rootPart.Position) ) then
                table.insert( players, player )
            end
        end
    end
    return players
end


function RotatedRegion:CountPlayersInRegion()
    return #( self:GetPlayersInRegion() )
end


return RotatedRegion