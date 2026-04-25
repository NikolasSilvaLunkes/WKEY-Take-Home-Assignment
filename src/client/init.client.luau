local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Controllers = script:WaitForChild("Controllers")

local Knit = require(Packages.knit)

Knit.AddControllersDeep(Controllers)
Knit.Start({ ServicePromises = false })
	:andThen(function()
		Knit.Loaded = true
	end)
	:catch(warn)
