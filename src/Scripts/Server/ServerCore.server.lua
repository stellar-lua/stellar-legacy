--[[
    ServerCore.server.lua
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Stellar = require(ReplicatedStorage.SharedModules.Stellar)
local RegisteredPlayers = {}
shared.Stellar = Stellar
shared.ServerAge = tick()

Stellar.BulkLoad(ServerStorage.ServerModules, ReplicatedStorage.SharedModules)

Stellar.BulkGet(
    "SoundFX"
    -- Continue importing your server-side code here
)

-- --- --

local SignalProvider = Stellar.Get("SignalProvider")
local PlayerRegistered = SignalProvider:Get("PlayerRegistered")

local function RegisterPlayer(player: Player)
    if not RegisteredPlayers[player] then
        player:LoadCharacter()
        RegisteredPlayers[player] = true
        PlayerRegistered:Fire(player)
    end
end

Players.PlayerAdded:Connect(RegisterPlayer)
for _, player in pairs(Players:GetPlayers()) do
    RegisterPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    if RegisteredPlayers[player] then
        RegisteredPlayers[player] = nil
    end
end)

Stellar.MarkAsLoaded()
print(string.format("[ServerCore] Loading Duration: %f seconds!", tick() - shared.ServerAge))
