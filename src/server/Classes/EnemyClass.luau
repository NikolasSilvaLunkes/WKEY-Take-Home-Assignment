--[[
-- Class for enemy spawn areas
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies

-- Definitions

local Enemy = {}
Enemy.__index = Enemy

-- Helper functions

-- Methods

-- gets a position inside a spawn area

function Enemy:CreateEnemy() end

function Enemy.new(part: BasePart)
	if part:IsA("Part") then
		return setmetatable({
			Type = "rectangle",
			Position = part.Position,
			CFrame = part.CFrame,
			Size = part.Size,
		}, Enemy)
	end
	warn("[Class][Enemy spawn area] tried to create a spawn area without a part reference")
	return nil
end

return Enemy
