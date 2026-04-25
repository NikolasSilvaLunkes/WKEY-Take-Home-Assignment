--[[
-- Enemy Service
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

--Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local EnemySpawnAreaClass = require(ServerScriptService.Server.Classes.EnemySpawnAreaClass)
local spawnAreasConfigs = require(ReplicatedStorage.Shared.spawnAreasConfigs)

-- Definitions
local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	Profiles = {},
	Client = {
		ChangeSpawnAreaInterval = Knit.CreateSignal(),
		ChangeSpawnAreaMaxEnemies = Knit.CreateSignal(),
		KillAll = Knit.CreateSignal(),
	},
	SpawnAreas = {},
	SpawnedEnemies = {},
})

function EnemyService:RegisterEnemy(enemyObject)
	local id = HttpService:GenerateGUID(false)
	enemyObject.Id = id
	self.SpawnedEnemies[id] = enemyObject
end

function EnemyService:UnregisterEnemy(enemyObject)
	self.SpawnedEnemies[enemyObject.Id] = nil
end

function EnemyService:KnitStart()
	for _, spawnAreaPart: Part in workspace.Ignore.SpawnAreas:GetChildren() do
		local spawnArea = EnemySpawnAreaClass.new(spawnAreaPart)
		local id = HttpService:GenerateGUID(false)
		spawnArea.Id = id
		self.SpawnAreas[id] = spawnArea
	end

	self.Client.ChangeSpawnAreaInterval:Connect(function(_player, configName, newInterval)
		local config = spawnAreasConfigs[configName]
		config.SpawnInterval = newInterval
	end)

	self.Client.ChangeSpawnAreaMaxEnemies:Connect(function(_player, configName, newMax)
		local config = spawnAreasConfigs[configName]
		config.MaxEnemies = newMax
	end)

	self.Client.KillAll:Connect(function(_)
		print("Recieved")
		for _, enemy in pairs(self.SpawnedEnemies) do
			enemy:Kill()
		end
	end)
end

return EnemyService
