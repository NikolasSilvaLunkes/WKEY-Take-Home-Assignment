--[[
-- Class for enemy spawn areas
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local EnemiesAssets: Folder = ReplicatedStorage.Assets.Enemies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)

-- Definitions

local Enemy = {}
Enemy.__index = Enemy

-- Helper functions

-- Methods

-- gets a position inside a spawn area

function Enemy.new(params: { EnemyType: string, CFrame: CFrame, SpawnArea: {} })
	local enemyType = params.EnemyType
	if not enemyType or typeof(enemyType) ~= "string" then
		if not enemyType then
			warn("[EnemyClass] No enemyType defined! returning nil")
		else
			warn("[EnemyClass] Wrong enemyType type! should be a string, returning nil")
		end
		return nil
	end
	local enemyModel = EnemiesAssets:FindFirstChild(enemyType):Clone()
	enemyModel:PivotTo(params.CFrame + Vector3.new(0, enemyModel:GetExtentsSize().Y / 2, 0))
	enemyModel.Parent = workspace.Ignore.Entities
	local enemy = setmetatable({
		Type = enemyType,
		Model = enemyModel,
		SpawnArea = params.SpawnArea,
	}, Enemy)
	Knit.GetService("EnemyService"):RegisterEnemy(enemy)
	return enemy
end

return Enemy
