--[[
-- Class for enemy spawn areas
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies

-- Definitions

local EnemySpawnArea = {}
EnemySpawnArea.__index = EnemySpawnArea

-- Helper functions

-- Methods

-- gets a position inside a spawn area
function EnemySpawnArea:CalculateRandomPositionWithin(): Vector3
	-- Generate random position in local space
	local localX = math.random() * self.Size.X - self.Size.X / 2
	local localY = self.Size.Y / 2 + self.Position.Y
	local localZ = math.random() * self.Size.Z - self.Size.Z / 2
	local localOffset = Vector3.new(localX, 0, localZ)
	-- Transform to world space using CFrame
	return (self.CFrame * CFrame.new(localOffset)).Position
end

function EnemySpawnArea:RaycastPositionWithin(position: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace.Ignore.Entities }

	local origin = position + Vector3.new(0, self.Size.Y, 0)
	local direction = Vector3.new(0, -(self.Size.Y + 10), 0)

	local result = workspace:Raycast(origin, direction, params)
	return result and result.Position or nil
end

function EnemySpawnArea:GetRandomPositionWithin(minModelDistanceRadius): Vector3?
	local randomPosition = self:CalculateRandomPositionWithin()
	local selectedPosition = self:RaycastPositionWithin(randomPosition)
	return selectedPosition
end

function EnemySpawnArea.new(part: BasePart)
	if part:IsA("Part") then
		return setmetatable({
			Type = "rectangle",
			Position = part.Position,
			CFrame = part.CFrame,
			Size = part.Size,
		}, EnemySpawnArea)
	end
	warn("[Class][Enemy spawn area] tried to create a spawn area without a part reference")
	return nil
end

return EnemySpawnArea
