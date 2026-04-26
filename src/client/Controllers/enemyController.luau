--[[
-- Enemy Controller - custom client-side replication
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)

local EnemiesAssets: Folder = ReplicatedStorage.Assets.Enemies
local colorConfigs = require(ReplicatedStorage.Shared.colorConfigs)

-- Definitions
local EnemyController = Knit.CreateController({
	Name = "EnemyController",
})

-- [id] = { model: Model, humanoid: Humanoid, heightOffset: number }
local activeEnemies = {}
-- reverse map so a hit part can be traced back to an enemy id in O(1)
local modelToId = {}

function EnemyController:KnitStart()
	local remotes = ReplicatedStorage:WaitForChild("EnemyRemotes")

	-- Server spawned a new enemy: clone model, apply color + scale, track by id
	remotes:WaitForChild("EnemySpawned").OnClientEvent:Connect(function(id, enemyType, footPos, colorIndex, sizeScale)
		if activeEnemies[id] then
			return
		end

		local template = EnemiesAssets:FindFirstChild(enemyType)
		if not template then
			warn(`[EnemyController] Unknown enemy type: "{enemyType}"`)
			return
		end

		local model = template:Clone()

		-- Apply color config chosen by the server (same index = same colors on all clients)
		local configs = colorConfigs[enemyType]
		local config = configs and configs[colorIndex]
		if config then
			local function applyColor(partName, color)
				local part = model:FindFirstChild(partName)
				if part then
					part.Color = color
				end
			end
			applyColor("Head", config.Skin)
			applyColor("Left Arm", config.Skin)
			applyColor("Right Arm", config.Skin)
			applyColor("Torso", config.Shirt)
			applyColor("Left Leg", config.Pants)
			applyColor("Right Leg", config.Pants)
		end

		-- Scale before measuring so heightOffset reflects final size
		model:ScaleTo(sizeScale)

		local heightOffset = model:GetExtentsSize().Y / 2
		model:PivotTo(CFrame.new(footPos + Vector3.new(0, heightOffset, 0)))
		model.Parent = workspace.Ignore.Entities

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		activeEnemies[id] = { model = model, humanoid = humanoid, heightOffset = heightOffset }
		modelToId[model] = id
	end)

	-- Batch target update: server sends only the destinations that changed this tick
	remotes:WaitForChild("EnemyTargets").OnClientEvent:Connect(function(targets)
		for id, targetPos in pairs(targets) do
			local entry = activeEnemies[id]
			if not entry or not entry.model or not entry.model.Parent then
				continue
			end

			local humanoid = entry.humanoid
			if humanoid and humanoid.Health > 0 then
				humanoid:MoveTo(targetPos)
			end
		end
	end)

	-- Batch removal: server sends a list of ids to remove at once
	remotes:WaitForChild("EnemiesRemoved").OnClientEvent:Connect(function(ids)
		for _, id in ipairs(ids) do
			local entry = activeEnemies[id]
			if entry and entry.model then
				modelToId[entry.model] = nil
				entry.model:Destroy()
			end
			activeEnemies[id] = nil
		end
	end)

	-- Click detection: raycast from camera through mouse position, walk up to Model, look up id
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { workspace.Ignore.Entities }

	local printRemote = remotes:WaitForChild("PrintEnemyId")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local mousePos = UserInputService:GetMouseLocation()
		local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
		if not result then
			return
		end

		local model = result.Instance:FindFirstAncestorWhichIsA("Model")
		local id = model and modelToId[model]
		if not id then
			return
		end

		print(`[Client] Clicked enemy {id}`)
		printRemote:FireServer(id)
	end)

	-- All listeners are connected — request the current enemy snapshot from the server.
	-- Doing this last guarantees no EnemySpawned/EnemyTargets fires are missed.
	remotes:WaitForChild("RequestEnemies"):FireServer()
end

return EnemyController
