--[[
-- Class for enemy spawn areas
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependencies
local spawnAreasConfigs = require(ReplicatedStorage.Shared.spawnAreasConfigs)
local EnemyClass = require(ServerScriptService.Server.Classes.EnemyClass)

-- Definitions

local EnemySpawnArea = {}
EnemySpawnArea.__index = EnemySpawnArea

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { workspace.Ignore }

-- Helper functions

-- Methods

-- gets a position inside a spawn area
function EnemySpawnArea:CalculateRandomPositionWithin(): Vector3
	-- Generate random position in local space
	local localX = math.random() * self.Size.X - self.Size.X / 2
	local localY = self.Size.Y / 2 + self.Position.Y
	local localZ = math.random() * self.Size.Z - self.Size.Z / 2
	local localOffset = Vector3.new(localX, localY, localZ)
	-- Transform to world space using CFrame
	return (self.CFrame * CFrame.new(localOffset)).Position
end

function EnemySpawnArea:RaycastPositionWithin(position: Vector3): Vector3?
	local origin = position + Vector3.new(0, self.Size.Y, 0)
	local direction = Vector3.new(0, -(self.Size.Y * 2 + 20), 0)

	local result = workspace:Raycast(origin, direction, params)
	return result and result.Position or nil
end

function EnemySpawnArea:GetRandomPositionWithin(): Vector3?
	local randomPosition = self:CalculateRandomPositionWithin()
	local selectedPosition = self:RaycastPositionWithin(randomPosition)
	return selectedPosition
end

local function selectWeightedEnemy(enemies)
	local totalWeight = 0
	for _, data in enemies do
		totalWeight += data.Weight
	end
	local roll = math.random() * totalWeight
	local cumulative = 0
	for name, data in enemies do
		cumulative += data.Weight
		if roll <= cumulative then
			return name
		end
	end
end

function EnemySpawnArea:SpawnRandomEnemy(config)
	local position = self:GetRandomPositionWithin()
	if not position then
		warn(`[EnemySpawnArea] Raycast found no ground in spawn area at {self.Position}`)
		return
	end

	if not config.Enemies or not next(config.Enemies) then
		warn(`[EnemySpawnArea] Config for "{self._name}" has no enemies defined`)
		return
	end

	local enemyName = selectWeightedEnemy(config.Enemies)
	if not enemyName then
		warn(`[EnemySpawnArea] Weighted selection failed for "{self._name}" — check enemy weights`)
		return
	end

	local Enemy = EnemyClass.new({
		EnemyType = enemyName,
		CFrame = CFrame.new(position),
		SpawnArea = self,
	})
	self._enemyCount += 1
end

function EnemySpawnArea.new(part: BasePart)
	if not part:IsA("Part") then
		warn("[Class][Enemy spawn area] tried to create a spawn area without a part reference")
		return nil
	end

	local self = setmetatable({
		Type = "rectangle",
		Position = part.Position,
		CFrame = part.CFrame,
		Size = part.Size,
		_name = part.Name,
		_enemyCount = 0,
	}, EnemySpawnArea)

	task.spawn(function()
		local lastConfig = spawnAreasConfigs[part.Name]
		local spawnThread = nil

		local function startSpawnLoop(config)
			if spawnThread then
				task.cancel(spawnThread)
			end
			spawnThread = task.spawn(function()
				while true do
					task.wait(config.SpawnInterval)
					if self._enemyCount < config.MaxEnemies then
						self:SpawnRandomEnemy(config)
					end
				end
			end)
		end

		if lastConfig then
			startSpawnLoop(lastConfig)
		else
			warn(`[EnemySpawnArea] No config found for spawn area "{part.Name}" — not spawning`)
		end

		while part and part.Parent do
			task.wait(1)
			local config = spawnAreasConfigs[part.Name]
			if config ~= lastConfig then
				lastConfig = config
				if config then
					startSpawnLoop(config)
				else
					warn(`[EnemySpawnArea] Config for "{part.Name}" was removed — stopping spawner`)
					if spawnThread then
						task.cancel(spawnThread)
						spawnThread = nil
					end
				end
			end
		end
	end)

	return self
end

return EnemySpawnArea
