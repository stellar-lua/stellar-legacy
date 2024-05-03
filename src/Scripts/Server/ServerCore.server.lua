--[[
    ServerCore.server.lua
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
shared.Stellar = Stellar
shared.ServerAge = tick()

Stellar.BulkLoad(ServerStorage.ServerModules, ReplicatedStorage.SharedModules)
Stellar.BulkGet(
    "SoundFX"
)

Stellar.Get("Network"):Reserve(
    { "UserInterface", "RemoteEvent" }
)

Stellar.MarkAsLoaded()
print(string.format("[ServerCore] Loading Duration: %f seconds!", tick() - shared.ServerAge))
