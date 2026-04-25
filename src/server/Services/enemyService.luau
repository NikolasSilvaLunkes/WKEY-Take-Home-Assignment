local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Entities = workspace.Ignore.Entities

local Knit = require(Packages.Knit)

local EnemyService = Knit.CreateService({
	Name = "NPCSpawnAreaService",
	Profiles = {},
	Client = {},
	SpawnAreas = {},
	SpawnedNpcs = {},
})

EnemyService.SpawnArea = {}
EnemyService.SpawnArea.__index = EnemyService.SpawnArea

function EnemyService:KnitStart() end

return EnemyService
