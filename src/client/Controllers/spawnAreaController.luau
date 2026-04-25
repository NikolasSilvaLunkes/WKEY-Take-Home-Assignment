--!nonstrict
--!nolint MixedTable
--[[
-- SpawnArea Controller
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local vide = require(Packages.vide)
local source = vide.source
local create = vide.create
local mount = vide.mount

local spawnAreasConfigs = require(ReplicatedStorage.Shared.spawnAreasConfigs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Definitions
local SpawnAreaController = Knit.CreateController({
	Name = "SpawnAreaController",
})

local CONFIG_NAME = "Zombie"

-- RemoteEvents are fetched once here so UI callbacks can fire them directly
local remotes = ReplicatedStorage:WaitForChild("EnemyRemotes")
local killAllRemote = remotes:WaitForChild("KillAll")
local changeIntervalRemote = remotes:WaitForChild("ChangeSpawnAreaInterval")
local changeMaxEnemiesRemote = remotes:WaitForChild("ChangeSpawnAreaMaxEnemies")

-- ============================================================
-- UI
-- ============================================================

local function NumberRow(label: string, initialValue: number, onSubmit: (number) -> ())
	local currentVal = source(initialValue)

	local textbox: TextBox
	textbox = create("TextBox")({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.42, 0.85),
		Text = tostring(initialValue),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		ClearTextOnFocus = false,
		FocusLost = function(_: boolean)
			local num = tonumber(textbox.Text)
			if num and num > 0 then
				currentVal(num)
				onSubmit(num)
			else
				textbox.Text = tostring(currentVal())
			end
		end,
	})

	textbox:GetPropertyChangedSignal("Text"):Connect(function()
		local filtered = textbox.Text:gsub("[^%d%.]", "")
		if filtered ~= textbox.Text then
			textbox.Text = filtered
		end
	end)

	return create("Frame")({
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,

		create("TextLabel")({
			Size = UDim2.fromScale(0.55, 1),
			Text = label,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),

		textbox,
	})
end

local function SpawnAreaPanel()
	local config = spawnAreasConfigs[CONFIG_NAME]

	return create("ScreenGui")({
		Name = "SpawnAreaGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,

		create("Frame")({
			Name = "Panel",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(230, 153),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,

			create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			create("UIListLayout")({
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("TextLabel")({
				LayoutOrder = 0,
				Size = UDim2.new(1, 0, 0, 16),
				Text = `Spawn Config — {CONFIG_NAME}`,
				TextColor3 = Color3.fromRGB(255, 200, 60),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			NumberRow("Interval (s)", config and config.SpawnInterval or 1, function(v)
				changeIntervalRemote:FireServer(CONFIG_NAME, v)
			end),

			NumberRow("Max Enemies", config and config.MaxEnemies or 20, function(v)
				changeMaxEnemiesRemote:FireServer(CONFIG_NAME, v)
			end),

			create("TextButton")({
				Size = UDim2.new(1, 0, 0, 26),
				Text = "Kill All",
				BackgroundColor3 = Color3.fromRGB(180, 40, 40),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				BorderSizePixel = 0,
				Activated = function()
					killAllRemote:FireServer()
				end,
				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

-- ============================================================
-- Controller
-- ============================================================

function SpawnAreaController:KnitStart()
	mount(SpawnAreaPanel, playerGui)
end

return SpawnAreaController
