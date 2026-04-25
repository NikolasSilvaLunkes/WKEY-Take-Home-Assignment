local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Services = script:WaitForChild("Services")

local Knit = require(Packages.knit)

local RequiredWorkspaceFolders = {
	["Ignore"] = {
		"Entities",
		"SpawnAreas",
	},
}

local RequiredAssets = {
	["Enemies"] = {
		"Zombie",
	},
}

local function checkAssets(parent, structure)
	for folderName, value in structure do
		local name = type(folderName) == "string" and folderName or value
		local child = parent:FindFirstChild(name)
		if not child then
			warn(`[Assets] Missing asset: {parent:GetFullName()}.{name}`)
		elseif type(folderName) == "string" and type(value) == "table" then
			checkAssets(child, value)
		end
	end
end

local function createFolders(parent, structure)
	for folderName, value in structure do
		local name = type(folderName) == "string" and folderName or value
		local folder = parent:FindFirstChild(name)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = name
			folder.Parent = parent
		end
		if type(folderName) == "string" and type(value) == "table" then
			createFolders(folder, value)
		end
	end
end

local function createZombieSpawnArea()
	local spawnAreas = workspace.Ignore:WaitForChild("SpawnAreas")
	if spawnAreas:FindFirstChild("Zombie") then
		return
	end

	local part = Instance.new("Part")
	part.Name = "Zombie"
	part.Size = Vector3.new(50, 50, 50)
	part.CFrame = CFrame.new(2.775, 13.075, 31.475)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 0.9
	part.Parent = spawnAreas
end

createFolders(workspace, RequiredWorkspaceFolders)
createZombieSpawnArea()
checkAssets(ReplicatedStorage:WaitForChild("Assets"), RequiredAssets)

Knit.AddServicesDeep(Services)
Knit.Start()
	:andThen(function()
		Knit.Loaded = true
	end)
	:catch(warn)
