-- Input
-- Author(s): Jesse Appleton
-- Date: 01/06/2022

--[[
	
]]

---------------------------------------------------------------------

-- Constants

-- Knit
local Knit = require( game:GetService("ReplicatedStorage"):WaitForChild("Knit") )

local VectorModule = require( Knit.SharedModules.VectorModule )
local CFrameModule = require( Knit.SharedModules.CFrameModule )

-- Roblox Services

-- Variables

---------------------------------------------------------------------


local Input = {}
Input.__index = Input


-- Constructor and destructor
function Input.new(): table
	local self = setmetatable( {}, Input )

	-- Initialize internal input state
	self._moveVector = Vector2.new()
	self._buttons = {}

	self._lastUp = Vector3.new(0, 1, 0)

	-- Initialize command input state
	self.Cmd = {
		-- Analogue state
		AnalogueX = 0,
		AnalogueY = 0,

		AnalogueMag = 0,
		AnalogueTurn = 0,

		-- Button state
		ButtonHeld = {},
		ButtonPress = {}
	}

	return self
end


function Input:Destroy(): nil
	
end


-- Public functions
function Input:SetState(moveVector: Vector2, buttons: table): nil
	-- Use given move vector
	self._moveVector = moveVector

	-- Update buttons
	for i,v in pairs(buttons) do
		self._buttons[i] = v
	end
end


function Input:UpdateCommand( character: table ): nil
	-- Update command analogue
	self.Cmd.AnalogueX = self._moveVector.X
	self.Cmd.AnalogueY = self._moveVector.Y

	self.Cmd.AnalogueMag = self._moveVector.magnitude

	-- Calculate analogue turn if holding analogue
	if self.Cmd.AnalogueMag ~= 0 then
		-- Get character vectors
		local tgtUp = Vector3.new(0, 1, 0) -- TODO: implement a system to change this on certain geometry for better inputs

		local look = character.CFrame.LookVector
		local up = character.CFrame.UpVector

		-- Get camera angle, aligned to our target up vector
		local camLook = VectorModule.PlaneProject(workspace.CurrentCamera.CFrame.LookVector, tgtUp) -- TODO: derive from character state
		if camLook.magnitude ~= 0 then
			camLook = camLook.unit
		else
			camLook = look
		end

		-- Get move vector in world space, aligned to our target up vector
		local camMove = CFrame.fromAxisAngle(tgtUp, math.atan2(-self.Cmd.AnalogueX, self.Cmd.AnalogueY)) * camLook

		-- Update last up
		if self.lastUp == nil or tgtUp:Dot(up) >= -0.999 then
			self.lastUp = up
		end

		-- Get final rotation and move vector
		local finalRotation = CFrameModule.FromToRotation(tgtUp, self.lastUp)

		local finalMove = VectorModule.PlaneProject(finalRotation * camMove, up)
		if finalMove.magnitude ~= 0 then
			finalMove = finalMove.unit
		else
			finalMove = look
		end

		-- Get analogue turn
		self.Cmd.AnalogueTurn = VectorModule.SignedAngle(look, finalMove, up)
	else
		-- No analogue turn
		self.Cmd.AnalogueTurn = 0
	end

	-- Update command buttons
	for i,v in pairs(self._buttons) do
		self.Cmd.ButtonPress[i] = v and (self.Cmd.ButtonHeld[i] ~= true)
		self.Cmd.ButtonHeld[i] = v
	end
end


return Input