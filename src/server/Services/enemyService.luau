--[[
-- Enemy Service
    
   ```
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local EnemySpawnAreaClass = require(ServerScriptService.Server.Classes.EnemySpawnAreaClass)

-- Definitions
local EnemyService = Knit.CreateService({
	Name = "NPCSpawnAreaService",
	Profiles = {},
	Client = {},
	SpawnAreas = {},
	SpawnedNpcs = {},
})

EnemyService.SpawnArea = {}
EnemyService.SpawnArea.__index = EnemyService.SpawnArea

function EnemyService:KnitStart()
	for _, spawnArea: Part in workspace.Ignore.SpawnAreas:GetChildren() do
		EnemySpawnAreaClass.new(spawnArea)
	end
end

return EnemyService
