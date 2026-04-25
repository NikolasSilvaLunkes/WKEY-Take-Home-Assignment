--[[
-- Enemy Service
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
	Client = {},
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

function EnemyService:KillAllEnemies()
	for _, enemy in pairs(self.SpawnedEnemies) do
		enemy:Kill()
	end
end

function EnemyService:KnitInit()
	local folder = Instance.new("Folder")
	folder.Name = "EnemyRemotes"
	folder.Parent = ReplicatedStorage

	local killAll = Instance.new("RemoteEvent")
	killAll.Name = "KillAll"
	killAll.Parent = folder

	local changeInterval = Instance.new("RemoteEvent")
	changeInterval.Name = "ChangeSpawnAreaInterval"
	changeInterval.Parent = folder

	local changeMaxEnemies = Instance.new("RemoteEvent")
	changeMaxEnemies.Name = "ChangeSpawnAreaMaxEnemies"
	changeMaxEnemies.Parent = folder
end

function EnemyService:KnitStart()
	for _, spawnAreaPart: Part in workspace.Ignore.SpawnAreas:GetChildren() do
		local spawnArea = EnemySpawnAreaClass.new(spawnAreaPart)
		local id = HttpService:GenerateGUID(false)
		spawnArea.Id = id
		self.SpawnAreas[id] = spawnArea
	end

	local remotes = ReplicatedStorage.EnemyRemotes

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
		print("Kill")
		self:KillAllEnemies()
	end)
end

return EnemyService
