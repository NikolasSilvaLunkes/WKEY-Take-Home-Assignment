--[[
-- Enemy Class - server-side logic only, no visual model
-- Tracks two positions:
--   Position      = probable current position (used for attack range / area checks)
--   TargetPosition = desired destination sent to clients so their Humanoid can MoveTo it
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local colorConfigs = require(ReplicatedStorage.Shared.colorConfigs)

local Enemy = {}
Enemy.__index = Enemy

local ATTACK_RANGE = 3
local ATTACK_COOLDOWN = 1
local WALK_SPEED = 8

function Enemy:GetNearestPlayer()
	local spawnArea = self.SpawnArea
	local halfSize = spawnArea.Size / 2
	local nearest, nearestDist = nil, math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local localPos = spawnArea.CFrame:PointToObjectSpace(root.Position)
		if math.abs(localPos.X) > halfSize.X or math.abs(localPos.Z) > halfSize.Z then
			continue
		end

		local dist = (Vector3.new(root.Position.X, self.Position.Y, root.Position.Z) - self.Position).Magnitude
		if dist < nearestDist then
			nearest, nearestDist = player, dist
		end
	end

	return nearest, nearestDist
end

-- Returns true when TargetPosition changed and should be sent to clients
function Enemy:Update(dt)
	if not self.IsAlive then return false end

	local target, _ = self:GetNearestPlayer()
	local prevTarget = self.TargetPosition
	local targetChanged = false

	if target then
		local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local flatTarget = Vector3.new(root.Position.X, self.Position.Y, root.Position.Z)

			-- Update target; flag changed if player moved more than 1 stud
			if not prevTarget or (flatTarget - prevTarget).Magnitude > 1 then
				self.TargetPosition = flatTarget
				targetChanged = true
			end

			-- Attack check against probable position
			if (flatTarget - self.Position).Magnitude <= ATTACK_RANGE then
				if tick() - self._lastAttack >= ATTACK_COOLDOWN then
					self._lastAttack = tick()
					local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:TakeDamage(10)
					end
				end
			end
		end
	else
		-- Pick a new wander destination when the timer fires or when we arrived
		local atTarget = self.TargetPosition and
			(Vector3.new(self.TargetPosition.X, self.Position.Y, self.TargetPosition.Z) - self.Position).Magnitude < 1

		if atTarget or (tick() - self._lastWander >= self._wanderDelay) then
			self._lastWander = tick()
			self._wanderDelay = math.random(3, 12)
			local pos = self.SpawnArea:GetRandomPositionWithin()
			if pos then
				self.TargetPosition = pos
				targetChanged = true
			end
		end
	end

	-- Advance probable position toward target so server-side logic stays accurate
	if self.TargetPosition then
		local dir = Vector3.new(
			self.TargetPosition.X - self.Position.X,
			0,
			self.TargetPosition.Z - self.Position.Z
		)
		local dist = dir.Magnitude
		if dist > 0.1 then
			self.Position += dir.Unit * math.min(WALK_SPEED * dt, dist)
		end
	end

	return targetChanged
end

function Enemy:Kill()
	self.IsAlive = false
end

function Enemy.new(params: { EnemyType: string, Position: Vector3, SpawnArea: {} })
	local enemyType = params.EnemyType
	if not enemyType or typeof(enemyType) ~= "string" then
		warn(not enemyType and "[EnemyClass] No enemyType defined!" or "[EnemyClass] enemyType must be a string")
		return nil
	end

	local configs = colorConfigs[enemyType]
	local colorIndex = configs and math.random(1, #configs) or 1
	local sizeScale = 0.85 + math.random() * 0.35 -- 0.85 – 1.20

	local self = setmetatable({
		Type = enemyType,
		Position = params.Position,
		TargetPosition = nil,
		IsAlive = true,
		SpawnArea = params.SpawnArea,
		ColorIndex = colorIndex,
		SizeScale = sizeScale,
		_lastAttack = 0,
		_lastWander = 0,
		_wanderDelay = math.random(3, 12),
	}, Enemy)

	Knit.GetService("EnemyService"):RegisterEnemy(self)
	return self
end

return Enemy
