for _, model: Model in pairs( game.Selection:Get() ) do
    local modelCFrame, modelSize = model:GetBoundingBox()

    local boundingBox: BasePart = Instance.new( "Part" )
    boundingBox.Transparency = 1
    boundingBox.Anchored = false
    boundingBox.Name = "Base"
    boundingBox.CanCollide = false
    boundingBox.CanTouch = false
    boundingBox.Size = modelSize
    boundingBox.CFrame = modelCFrame
    boundingBox.Parent = model

    model.PrimaryPart = boundingBox

    for _, part in pairs( model:GetChildren() ) do
        if ( part ~= boundingBox ) and ( part:IsA("BasePart") ) then
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Anchored = false

            local weldConstraint: WeldConstraint = Instance.new( "WeldConstraint" )
            weldConstraint.Part0 = boundingBox
            weldConstraint.Part1 = part
            weldConstraint.Parent = boundingBox

            if ( part:IsA("MeshPart") ) then
                part.CollisionFidelity = Enum.CollisionFidelity.Box
                part.RenderFidelity = Enum.RenderFidelity.Performance
            end
        end
    end
end