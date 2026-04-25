local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Physics = game:GetService("PhysicsService")

local Packages = ReplicatedStorage.Packages
local Entities = workspace.Ignore.Entities

local Knit = require(Packages.Knit)
local BeastsData = ReplicatedStorage.Modules.BeastDatas
local BeastDataCache = {}
for _, BeastData in pairs(BeastsData:GetDescendants()) do
	if not BeastData:IsA("ModuleScript") then
		continue
	end
	BeastDataCache[BeastData.Name] = require(BeastData)
end

local AREAS_FOLDER = game.Workspace.Map.NpcSpawnAreas

local IS_DEV_MODE = ReplicatedStorage:WaitForChild("ServerSettings"):WaitForChild("DEV_MODE").Value

local NPCSpawnAreaService = Knit.CreateService({
	Name = "NPCSpawnAreaService",
	Profiles = {},
	Client = {},
	SpawnAreas = {},
})

NPCSpawnAreaService.SpawnArea = {}
NPCSpawnAreaService.SpawnArea.__index = NPCSpawnAreaService.SpawnArea

function NPCSpawnAreaService:KnitStart()
	task.wait(1)
	self.Blueprints = self:AddAllAreas()
end

return NPCSpawnAreaService
