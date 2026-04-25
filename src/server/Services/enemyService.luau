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

-- Definitions
local EnemyService = Knit.CreateService({
	Name = "EnemyService",
	Profiles = {},
	Client = {},
	SpawnAreas = {},
	SpawnedEnemies = {},
})

EnemyService.SpawnArea = {}
EnemyService.SpawnArea.__index = EnemyService.SpawnArea

function EnemyService:RegisterEnemy(enemyObject)
	local id = HttpService:GenerateGUID(false)
	enemyObject.Id = id
	self.Enemies[id] = enemyObject
end

function EnemyService:KnitStart()
	for _, spawnAreaPart: Part in workspace.Ignore.SpawnAreas:GetChildren() do
		local spawnArea = EnemySpawnAreaClass.new(spawnAreaPart)
		local id = HttpService:GenerateGUID(false)
		spawnArea.Id = id
		self.SpawnAreas[id] = spawnArea
	end
end

return EnemyService
