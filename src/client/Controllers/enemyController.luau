--[[
-- Enemy Controller - custom client-side replication
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)

local EnemiesAssets: Folder = ReplicatedStorage.Assets.Enemies

-- Definitions
local EnemyController = Knit.CreateController({
	Name = "EnemyController",
})

-- [id] = { model: Model, heightOffset: number }
local activeEnemies = {}

function EnemyController:KnitStart()
	local remotes = ReplicatedStorage:WaitForChild("EnemyRemotes")

	-- Server spawned a new enemy: clone model and track it by id
	remotes:WaitForChild("EnemySpawned").OnClientEvent:Connect(function(id, enemyType, footPos)
		if activeEnemies[id] then return end

		local template = EnemiesAssets:FindFirstChild(enemyType)
		if not template then
			warn(`[EnemyController] Unknown enemy type: "{enemyType}"`)
			return
		end

		local model = template:Clone()
		local heightOffset = model:GetExtentsSize().Y / 2
		model:PivotTo(CFrame.new(footPos + Vector3.new(0, heightOffset, 0)))
		model.Parent = workspace.Ignore.Entities

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		activeEnemies[id] = { model = model, humanoid = humanoid, heightOffset = heightOffset }
	end)

	-- Batch target update: server sends only the destinations that changed this tick
	remotes:WaitForChild("EnemyTargets").OnClientEvent:Connect(function(targets)
		for id, targetPos in pairs(targets) do
			local entry = activeEnemies[id]
			if not entry or not entry.model or not entry.model.Parent then continue end

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
				entry.model:Destroy()
			end
			activeEnemies[id] = nil
		end
	end)
end

return EnemyController
