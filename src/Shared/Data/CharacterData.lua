local Characters = game:GetService( "ReplicatedStorage" ):WaitForChild( "Assets" ):WaitForChild( "Content" ):WaitForChild( "Characters" )

return {
    DefaultParameters = {
        -- Scaling
        Scale = 4.55 / 10, -- Scale from units to Roblox studs

        -- Ground parameters
        Ground_Acceleration = 0.05,  -- Acceleration when moving
        Ground_Deceleration = -0.06, -- Deceleration when not moving
        Ground_Brake = -0.18,        -- Deceleration when braking

        Ground_DragStart = 3,   -- Speed the character can easily accelerate up to
        Ground_Drag_X = -0.008, -- Forwards air drag
        Ground_Drag_Z = -0.6,   -- Sideways air drag

        -- Speed parameters, these don't control how you expect them to
        Speed_Jog = 0,
        Speed_Run = 0,
        Speed_Rush = 0,
        Speed_Crash = 0,
        Speed_Dash = 0,

        -- Air parameters
        Air_AccelerationUp = 0.001,   -- Acceleration when moving upwards
        Air_AccelerationDown = -0.001, -- Acceleration when moving downwards
        Air_Brake = -0.17,            -- Deceleration when braking

        Air_Drag_X = -0.013, -- Forwards air drag
        Air_Drag_Y = -0.01,  -- Vertical air drag
        Air_Drag_Z = -0.4,   -- Sideways air drag

        -- Jumping parameters
        Jump_Speed = 1,      -- Speed applied when jumping
        Jump_HangForce = 0, -- Force applied to hang while holding jump
        Jump_HangTime = 30,     -- Time hang force is active

        -- General parameters
        Gravity = 0.08, -- Acceleration due to gravity

        -- Collision parameters
        Collision_Width = 3,  -- Horizontal radius of character
        Collision_Height = 6, -- Vertical radius of character
        Collision_Radius = 4.25, -- Object collision radius of character

        Collision_Clip = 2, -- Height character can clip down from when above ground
    };
    DefaultGravity = Vector3.new( 0, -1, 0 );
    Characters = {
        {
            Name = "default";
            Rarity = "Common";
            Folder = Characters:WaitForChild("RBXAvatar");
            RigType = "Motor6D"
        }
    };
}