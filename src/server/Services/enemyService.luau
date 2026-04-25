--[[
-- Enemy Service
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local EnemySpawnAreaClass = require(ServerScriptService.Server.Classes.EnemySpawnAreaClass)
local spawnAreasConfigs = require(ReplicatedStorage.Shared.spawnAreasConfigs)

local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	Client = {},
	SpawnAreas = {},
	SpawnedEnemies = {},
})

function EnemyService:RegisterEnemy(enemyObject)
	local id = HttpService:GenerateGUID(false)
	enemyObject.Id = id
	self.SpawnedEnemies[id] = enemyObject
	ReplicatedStorage.EnemyRemotes.EnemySpawned:FireAllClients(id, enemyObject.Type, enemyObject.Position)
end

function EnemyService:KillAllEnemies()
	for _, enemy in pairs(self.SpawnedEnemies) do
		enemy:Kill()
	end
end

function EnemyService:KnitInit()
	local folder = Instance.new("Folder")
	folder.Name = "EnemyRemotes"
	folder.Parent = ReplicatedStorage

	-- Client → Server
	local killAll = Instance.new("RemoteEvent")
	killAll.Name = "KillAll"
	killAll.Parent = folder

	local changeInterval = Instance.new("RemoteEvent")
	changeInterval.Name = "ChangeSpawnAreaInterval"
	changeInterval.Parent = folder

	local changeMaxEnemies = Instance.new("RemoteEvent")
	changeMaxEnemies.Name = "ChangeSpawnAreaMaxEnemies"
	changeMaxEnemies.Parent = folder

	-- Server → Client (custom replication)
	local enemySpawned = Instance.new("RemoteEvent")
	enemySpawned.Name = "EnemySpawned"
	enemySpawned.Parent = folder

	-- Only fires when an enemy's desired destination changes, not every tick
	local enemyTargets = Instance.new("RemoteEvent")
	enemyTargets.Name = "EnemyTargets"
	enemyTargets.Parent = folder

	local enemiesRemoved = Instance.new("RemoteEvent")
	enemiesRemoved.Name = "EnemiesRemoved"
	enemiesRemoved.Parent = folder
end

function EnemyService:KnitStart()
	for _, spawnAreaPart: Part in workspace.Ignore.SpawnAreas:GetChildren() do
		local spawnArea = EnemySpawnAreaClass.new(spawnAreaPart)
		self.SpawnAreas[spawnAreaPart.Name] = spawnArea
	end

	local remotes = ReplicatedStorage.EnemyRemotes

	-- Send all currently alive enemies to late-joining players
	Players.PlayerAdded:Connect(function(player)
		for id, enemy in pairs(self.SpawnedEnemies) do
			if enemy.IsAlive then
				remotes.EnemySpawned:FireClient(player, id, enemy.Type, enemy.Position)
				if enemy.TargetPosition then
					remotes.EnemyTargets:FireClient(player, { [id] = enemy.TargetPosition })
				end
			end
		end
	end)

	-- Client → Server signals
	remotes.ChangeSpawnAreaInterval.OnServerEvent:Connect(function(_, configName, newInterval)
		local config = spawnAreasConfigs[configName]
		if config then
			config.SpawnInterval = newInterval
		end
	end)

	remotes.ChangeSpawnAreaMaxEnemies.OnServerEvent:Connect(function(_, configName, newMax)
		local config = spawnAreasConfigs[configName]
		if config then
			config.MaxEnemies = newMax
		end
	end)

	remotes.KillAll.OnServerEvent:Connect(function(_)
		self:KillAllEnemies()
	end)

	-- Update loop: runs AI, sends target changes only, sweeps dead enemies
	task.spawn(function()
		local lastTick = tick()
		while true do
			task.wait(0.1)
			local now = tick()
			local dt = now - lastTick
			lastTick = now

			local changedTargets = {}
			local toRemove = {}

			for id, enemy in pairs(self.SpawnedEnemies) do
				if enemy.IsAlive then
					local targetChanged = enemy:Update(dt)
					if targetChanged and enemy.TargetPosition then
						changedTargets[id] = enemy.TargetPosition
					end
				else
					toRemove[#toRemove + 1] = id
				end
			end

			-- Only send a packet when at least one target changed
			if next(changedTargets) then
				remotes.EnemyTargets:FireAllClients(changedTargets)
			end

			-- Batch-remove dead enemies in one packet
			if #toRemove > 0 then
				for _, id in toRemove do
					local enemy = self.SpawnedEnemies[id]
					if enemy and enemy.SpawnArea then
						enemy.SpawnArea._enemyCount = math.max(0, enemy.SpawnArea._enemyCount - 1)
					end
					self.SpawnedEnemies[id] = nil
				end
				remotes.EnemiesRemoved:FireAllClients(toRemove)
			end
		end
	end)
end

return EnemyService
