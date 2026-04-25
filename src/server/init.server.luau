local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Services = script:WaitForChild("Services")

local Knit = require(Packages.knit)

Knit.AddServicesDeep(Services)
Knit.Start():andThen(function()
	Knit.Loaded = true
end):catch(warn)
