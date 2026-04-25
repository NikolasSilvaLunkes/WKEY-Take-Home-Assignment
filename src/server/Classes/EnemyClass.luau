--[[
-- Class for enemy spawn areas
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local EnemiesAssets: Folder = ReplicatedStorage.Assets.Enemies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)

-- Definitions

local Enemy = {}
Enemy.__index = Enemy

local ATTACK_RANGE = 2
local ATTACK_COOLDOWN = 1
local BEHAVIOR_TICK = 0.1

-- Helper functions

-- Methods

function Enemy:GetNearestPlayerInArea()
	local spawnArea = self.SpawnArea
	local halfSize = spawnArea.Size / 2
	local nearest, nearestDist = nil, math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local localPos = spawnArea.CFrame:PointToObjectSpace(root.Position)
		if math.abs(localPos.X) > halfSize.X or math.abs(localPos.Z) > halfSize.Z then continue end

		local dist = (root.Position - self.Model:GetPivot().Position).Magnitude
		if dist < nearestDist then
			nearest, nearestDist = player, dist
		end
	end

	return nearest, nearestDist
end

function Enemy:Attack(target)
	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid:TakeDamage(10)
end

function Enemy:StartBehaviorLoop()
	local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn(`[EnemyClass] "{self.Type}" model has no Humanoid — behavior not started`)
		return
	end

	local lastAttack = 0

	task.spawn(function()
		while self.Model and self.Model.Parent and humanoid.Health > 0 do
			local target, dist = self:GetNearestPlayerInArea()

			if target then
				local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if root then
					humanoid:MoveTo(root.Position)

					if dist <= ATTACK_RANGE and tick() - lastAttack >= ATTACK_COOLDOWN then
						lastAttack = tick()
						self:Attack(target)
					end
				end
			end

			task.wait(BEHAVIOR_TICK)
		end
	end)
end

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
	enemy:StartBehaviorLoop()
	return enemy
end

return Enemy
