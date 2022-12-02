--[=[
	-- CLIENT --
		-- VARIABLES --
			ViewportFrameController.Zoom = Float
			ViewportFrameController.FOV = Float
			
		---------------
		
		-- METHODS --
			ViewportFrameController.new( viewportFrame[, config][, scrollingEnabled][, yRotationEnabled][, xRotationEnabled] )
				ViewportFrameController:SetDisplay( [ targetObject ][, originCFrame] )
				ViewportFrameController:SetRotationY( rotationY )
				ViewportFrameController:SetRotationZ( rotationZ )
				ViewportFrameController:SetZoom( zoom )
				ViewportFrameController:SetFOV( fov )
				ViewportFrameController:Reset( instant )
				ViewportFrameController:Update()
				ViewportFrameController:Destroy()
		-------------
	------------
--]=]


-- CONSTANT VARIABLES --
local DEFAULT_RESET_TWEEN_TIME = 1;
local ZOOM_SPEED = 0.05; -- How fast does the model zoom in/out?

local DEFAULT_FOV = 15;
local DEFAULT_ZOOM = 1; -- This feels counter-intuitive, the camera is closer to the display object the lower that this is, minimum 0.

local ORIGIN_CFRAME = CFrame.new();
local FOV_LIMITS = NumberRange.new( 1, 120 );

local TEMPLATE_CAMERA = Instance.new( "Camera" );
	TEMPLATE_CAMERA.FieldOfView = DEFAULT_FOV;
	
local OBJECT_CACHE = {}; -- Objects which have already been created
------------------------

-- ROBLOX SERVICES --
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local TweenService = game:GetService( "TweenService" );
local CollectionService = game:GetService( "CollectionService" )
---------------------


local ViewportFrameController = {
	Debug = false;
};
	ViewportFrameController.__index = ViewportFrameController;
	
	
	-- CONSTRUCTOR --
		function ViewportFrameController.new( viewportFrame, config, scrollingEnabled, yRotationEnabled, xRotationEnabled )
			assert( (viewportFrame and (viewportFrame:IsA("ViewportFrame"))), "Invalid first argument, expected a ViewportFrame <VIEWPORTFRAME>!" );
			assert( (config==nil) or (typeof(config)=="table"), "Invalid second argument, expected table or nil <CONFIG>!" );
			
			local config = config or {};
			
			local self = {};
				setmetatable( self, ViewportFrameController );
			
			-- SET VARIABLES --
				self.Connections = {};
				
				self.Zoom = tonumber(config.Zoom) or DEFAULT_ZOOM;
					self.DefaultZoom = self.Zoom;
				self.FOV = tonumber(config.FOV) or DEFAULT_FOV;
					self.DefaultFOV = self.FOV;
				
				self.ScrollingEnabled = ( not not scrollingEnabled );
				self.RotationYEnabled = ( not not yRotationEnabled );
				self.RotationXEnabled = ( not not xRotationEnabled );
				
				self.AutoRotateEnabled = ( not not config.AutoRotateEnabled );
					self.AutoRotateSpeed = ( tonumber(config.AutoRotateSpeed) ) or 1;
				
				self.ResetTweenTime = tonumber(config.ResetTweenTime) or DEFAULT_RESET_TWEEN_TIME;
				self.RotationY = tonumber(config.RotationY) or 0;
					self.DefaultRotationY = self.RotationY;
				self.RotationX = tonumber(config.RotationX) or 0;
					self.DefaultRotationX = self.RotationX;
			
				self.Object = viewportFrame;
				
				self.Display = nil;
					self.DisplayOrigin = nil;
					self.DisplaySize = nil;
					
				self.ActionId = 0;
			-------------------
			
			-- SETUP --					
				-- CONTROL ZOOM --
					if ( self.ScrollingEnabled ) then
						local function GetRelativeZoomSpeed()
							local displaySize = ( self.DisplaySize and self.DisplaySize.Magnitude ) or 1;
						end
						
						self:AddConnection( viewportFrame.MouseWheelForward:Connect(function()
							self.ActionId = self.ActionId + 1;

							self.Zoom = math.max( (self.Zoom - (ZOOM_SPEED*GetRelativeZoomSpeed())), 1 );
							
							self:SetZoom( self.Zoom );
						end) );
						
						self:AddConnection( viewportFrame.MouseWheelBackward:Connect(function()
							self.Zoom = ( self.Zoom + ZOOM_SPEED );
							
							self:SetZoom( self.Zoom );
						end) );
					end
				------------------
				
				-- CONTROL ROTATION --	
					if ( self.RotationYEnabled ) or ( self.RotationXEnabled ) then
						-- We need to create a button, since only buttons have the mouse behavior required
						local viewportButton = self:Create( "TextButton", {
							Name = "InteractionButton";
							Size = UDim2.new( 1, 0, 1, 0 );
							Position = UDim2.new( 0, 0, 0, 0 );
							ZIndex = viewportFrame.ZIndex + 1;
							BackgroundTransparency = 1;
							AutoButtonColor = false;
							TextTransparency = 1;
							Text = "";
							Parent = viewportFrame;
						} );
							self.ViewportButton = viewportButton;
					
						local function BeginDrag()
							local myId = self.ActionId + 1;
								self.ActionId = myId;
								
							local mouseStartLocation = UserInputService:GetMouseLocation();
							
							local saveRotationY = self.RotationY;
							local saveRotationX = self.RotationX;
							
							local rotationYEnabled = self.RotationYEnabled;
							local rotationXEnabled = self.RotationXEnabled;
							
							local function DragIsActive()
								return
									( not self.Destroyed ) -- The object hasn't been destroyed
										and
									( self.ActionId == myId ) -- A new drag hasn't begun
										and
									( UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) ) -- The button is still being held down
										and
									( RunService.Heartbeat:wait() )
							end
									
							while ( DragIsActive() ) do	
								local mouseLocation = UserInputService:GetMouseLocation();
								local deltaX, deltaY = (mouseLocation.X-mouseStartLocation.X), (mouseLocation.Y-mouseStartLocation.Y);
								
								if ( rotationYEnabled ) then
									self.RotationY = ( saveRotationY + deltaX ) % 360;
								end
								
								if ( rotationXEnabled ) then
									self.RotationX = ( saveRotationX - deltaY ) % 360;
								end
								
								self:Update();
							end
						end
							self:AddConnection( viewportButton.MouseButton2Down:Connect(BeginDrag) );
					end
				----------------------
				
				-- Control Auto Rotation --
					self:AddConnection(RunService.Heartbeat:Connect(function()
						debug.profilebegin( "ViewportRotationUpdate" )
						if ( self.AutoRotateEnabled ) then
							self:SetRotationY( (self.RotationY + self.AutoRotateSpeed) % 360 );
						end
						debug.profileend()
					end));
				---------------------------
					
				-- Destroy controller when viewportFrame is destroyed.
					self:AddConnection( viewportFrame.AncestryChanged:Connect(function()
						if ( not viewportFrame ) or ( not viewportFrame.Parent ) then
							self:Destroy();
						end
					end) );
			-----------		
			
			return self;
		end
	-----------------
	
	
	-- METHODS --
		function ViewportFrameController:Create( instance, properties )
			local newInstance = Instance.new( instance )
			local saveParent = properties.Parent
			properties.Parent = nil
			for property, value in pairs( properties ) do
				newInstance[ property ] = value
			end
			newInstance.Parent = saveParent
			return newInstance
		end

		function ViewportFrameController:AddConnection( connection )
			table.insert( self.Connections, connection );
		end
			function ViewportFrameController:ClearConnections()
				for _, connection in pairs( self.Connections ) do
					pcall(function()
						connection:Disconnect();
					end);
				end
				
				self.Connections = {};
			end
			
		function ViewportFrameController:SetRotationY( newRotationY )
			assert( tonumber(newRotationY), "Invalid first argument, expected a number <ROTATION Y>!" );
			self.ActionId = self.ActionId + 1;
			
			self.RotationY = newRotationY;
			self:Update();
		end
		
		function ViewportFrameController:SetRotationX( newRotationX )
			assert( tonumber(newRotationX), "Invalid first argument, expected a number <ROTATION X>!" );
			self.ActionId = self.ActionId + 1;
			
			self.RotationX = newRotationX;
			self:Update();
		end
		
		function ViewportFrameController:SetZoom( newZoom )
			assert( tonumber(newZoom), "Invalid first argument, expected a number <ZOOM>!" );
			self.ActionId = self.ActionId + 1;
			
			self.Zoom = newZoom;
			self:Update();
		end
		
		function ViewportFrameController:SetFOV( newFOV )
			assert( tonumber(newFOV), "Invalid first argument, expected a number <FOV>!" );
			
			self.FOV = math.clamp( newFOV, FOV_LIMITS.Min, FOV_LIMITS.Max );
			self:Update();
		end
		
		function ViewportFrameController:Reset( instant )
			spawn(function()
				local myId = self.ActionId + 1;
					self.ActionId = myId;
					
				if ( instant ) then
					self.RotationX = self.DefaultRotationX;
					self.RotationY = self.DefaultRotationY;
					self.Zoom = self.DefaultZoom;
					
					self:Update();
					
					return;
				end
				
				local tweenInfo = TweenInfo.new(
					self.ResetTweenTime, -- Tween Time
					Enum.EasingStyle.Back, -- Easing Style
					Enum.EasingDirection.Out -- Easing Direction
				);
								
				local rotationXStart = self.RotationX;
				local rotationXTarget = self.DefaultRotationX;
					if ( (rotationXTarget - rotationXStart) < -180 ) then
						rotationXTarget = rotationXTarget + 360;
					end
					
				local rotationYStart = self.RotationY;
				local rotationYTarget = self.DefaultRotationY;
					if ( (rotationYTarget - rotationYStart) < -180 ) then
						rotationYTarget = rotationYTarget + 360;
					end
				
				local startVector = Vector3.new( rotationXStart, rotationYStart, self.Zoom );
				local targetVector = Vector3.new( rotationXTarget, rotationYTarget, self.DefaultZoom );
				
				local simulatedValue = self:Create( "Vector3Value", {
					Value = startVector;
				} );
					simulatedValue:GetPropertyChangedSignal("Value"):Connect(function()
						if ( myId == self.ActionId ) then
							local newValue = simulatedValue.Value;
								self.RotationX = newValue.X;
								self.RotationY = newValue.Y;
								self.Zoom = newValue.Z;
								
							self:Update();
						end
					end);
				
				local newTween = TweenService:Create( simulatedValue, tweenInfo, {Value = targetVector} );
					newTween:Play();
					
					delay(tweenInfo.Time, (function()
						simulatedValue:Destroy();
						newTween:Destroy();
					end));
			end);
		end
		
		-- This method clears all unimportant objects from the ViewportFrame
		function ViewportFrameController:ClearChildren()
			for _, object in pairs ( self.Object:GetChildren() ) do
				if ( object ~= self.Object.CurrentCamera ) and ( object ~= self.ViewportButton ) and ( not object:IsA("UICorner") ) then
					object:Destroy();
				end
			end
		end
		
		function ViewportFrameController:Clear()
			self.Display = nil;
			self.DisplayOrigin = nil;
			self.DisplaySize = nil;
			
			self:ClearChildren();
		end
	
		function ViewportFrameController:SetDisplay( targetObject, originCFrame )
			assert( (targetObject==nil) or (targetObject:IsA("BasePart") or targetObject:IsA("Model")), "Invalid first argument, expected a BasePart or Model <TARGET OBJECT>!" );
			
			-- Passed in nil, clear the ViewportFrame
			if ( not targetObject ) then
				return self:Clear();
			end
			
			-- Find or Create the Template Model
				local templateModel = self:GetTemplateModel( targetObject, originCFrame );
			
			-- Destroy Old Viewport Objects
				self:ClearChildren();
				
			-- Create the New Display
				local newModel = templateModel:Clone();
					self.Display = newModel;
					self.DisplayOrigin = newModel.PrimaryPart.CFrame;
					self.DisplaySize = newModel.PrimaryPart.Size;
					
					newModel.Parent = self.Object;
					
			-- Update the ViewportFrameController
				self:Update();
		end
	
		-- ViewportFrameController:GetTemplateModel( object[, originCFrame] );
			-- originCFrame is useful for complex objects that need to be positioned based on, for example, how it would weld to a player's hand
		function ViewportFrameController:GetTemplateModel( object, originCFrame )
			assert( (originCFrame==nil) or (typeof(originCFrame)=="CFrame"), "Invalid second argument, expected a CFrame or nil <ORIGIN CFRAME>!" );
			
			local cachedObject = OBJECT_CACHE[ object ];
				if ( cachedObject ) then
					return cachedObject;
				end
			
			-- Clone the original object so we don't tamper with it
			local newObject = object:Clone();
				newObject.Name = "display";
			
			-- Prepare the model from the passed object
			local newModel = newObject;
				if ( newObject:IsA("BasePart") ) then
					newModel = self:Create( "Model", {
						Name = newObject.Name;
						Parent = script;
					} );
						newObject.Parent = newModel;
		
					newModel.PrimaryPart = newObject;
				elseif ( newObject:IsA("Model") and (not newObject.PrimaryPart) ) then
					newModel = newObject;
					
					newObject.PrimaryPart = newObject:FindFirstChildWhichIsA( "BasePart", true );
					
					if ( newObject.PrimaryPart == nil ) then
						newObject:Destroy(); -- Not today, memory leaks!
						
						assert( newObject and newObject.PrimaryPart, "Invalid first argument, passed a Model with no PrimaryPart and no BasePart descendants <OBJECT>!" );
					end
				end
			
				newModel:SetPrimaryPartCFrame( originCFrame or CFrame.new() );

			for _, tag in pairs( CollectionService:GetTags(newModel) ) do
				CollectionService:RemoveTag( newModel, tag )
			end
				
			-- -- Cleanse the new model of un-necessary objects in ViewportFrames
			-- local allowedClasses = {
			-- 	"BasePart"; "Decal"; "Folder"; "Model"; "SpecialMesh"; "BlockMesh";
			-- 	"Attachment"; "ParticleEmitter"; "Trail"; "Beam"; "ForceField"; -- These do NOT currently show up in ViewportFrames (as of 04/26/2019) but I added them just in case
			-- };
			-- 	local function IsAllowed( object )
			-- 		for _, allowedClass in pairs( allowedClasses ) do
			-- 			if ( object:IsA(allowedClass) ) then
			-- 				return true;
			-- 			end
			-- 		end
			-- 	end
			
			-- for _, object in pairs( newModel:GetDescendants() ) do
			-- 	if ( not IsAllowed(object) ) then
			-- 		object:Destroy();
			-- 	end
			-- end
				
			-- Get original CFrame and Size
			local modelCFrame, modelSize = newModel:GetBoundingBox();
				
			-- Get the offset from ORIGIN_CFRAME, this is to ensure the model is centered on the screen	
			local primaryPartOffset = ( newModel.PrimaryPart.CFrame - newModel.PrimaryPart.CFrame.p ) * modelCFrame:toObjectSpace( newModel.PrimaryPart.CFrame );
				newModel:SetPrimaryPartCFrame( ORIGIN_CFRAME * primaryPartOffset );
				
			-- Get new CFrame and Size after offsetting
			local modelCFrame, modelSize = newModel:GetBoundingBox();
				
			-- Create a bounding box with a constant UpVector, set it as primary part
			local boundingBoxPart = Instance.new( "Part" );
				boundingBoxPart.Name = "BoundingBox";
				boundingBoxPart.Transparency = 1;
				boundingBoxPart.Size = modelSize;
				boundingBoxPart.CFrame = modelCFrame;
				boundingBoxPart.Parent = newModel;
				
				newModel.PrimaryPart = boundingBoxPart;
				
			OBJECT_CACHE[ object ] = newModel;
				
			return newModel;
		end
		
		function ViewportFrameController:GetCamera()
			local viewportFrame = self.Object;
				local currentCamera = viewportFrame.CurrentCamera;
			
			if ( not currentCamera ) then
				local newCamera = viewportFrame:FindFirstChildWhichIsA( "Camera", true ) or TEMPLATE_CAMERA:Clone();
					newCamera.Name = "camera";
					newCamera.Parent = viewportFrame;
					
				viewportFrame.CurrentCamera = newCamera;
				
				return newCamera;
			end
			
			return currentCamera;
		end
		
		function ViewportFrameController:UpdateDisplayRotation()
			local displayModel = self.Display;
				local displayOrigin = self.DisplayOrigin;
			
			if ( displayModel and displayModel.PrimaryPart and displayOrigin ) then
				displayModel:SetPrimaryPartCFrame(
					CFrame.Angles( math.rad(self.RotationX), math.rad(self.RotationY), 0 ) -- World Axis Rotation
					* ( displayOrigin - displayOrigin.Position ) -- Translate locally
					+ displayOrigin.Position -- Add position back
				);
			end
		end
		
		function ViewportFrameController:Update()
			local viewportFrame = self.Object;
			local viewportCamera = self:GetCamera();
			local displayModel = self.Display;
				
			if ( viewportFrame and viewportCamera and displayModel and displayModel.PrimaryPart ) then
				self:UpdateDisplayRotation();
				
				local modelCFrame, modelSize = displayModel:GetBoundingBox();
				local modelScale = modelSize.Magnitude * self.Zoom;
				
				local newCameraCFrame = ORIGIN_CFRAME
					* CFrame.Angles( math.rad(0), math.rad(180), 0 )
					* CFrame.new( 0, 0, modelScale / (2 * math.tan(math.rad(self.FOV) / 2)) );
					
					newCameraCFrame = CFrame.new( newCameraCFrame.p, ORIGIN_CFRAME.p );
									
				viewportCamera.FieldOfView = self.FOV;		
				viewportCamera.CFrame = newCameraCFrame;
			elseif ( self.Debug ) then
				warn(
					"Failed to update ViewportFrameController:", self.Object:GetFullName(),
						"[Object: " .. tostring(not not viewportFrame) ..  "]",
						"[Camera: " .. tostring(not not viewportCamera) ..  "]",
						"[Display: " .. tostring(not not displayModel) ..  "]"
				);
			end
		end
		
		function ViewportFrameController:Destroy()
			self.Destroyed = true;
			
			self:ClearConnections();
			
			-- other stufF?
		end
	-------------

return ViewportFrameController;