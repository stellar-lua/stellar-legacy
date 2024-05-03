--[[
    Interaction.lua
    via Stellar
--]]

local Network = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local isServer = RunService:IsServer()
local TranslationTable = {}
local Stellar = shared.Stellar
local Promise = Stellar.Library("Promise")

function Network:GetEndpoint(name, class)
    if TranslationTable[name] then
        return TranslationTable[name]
    end
    local storageFolder = ReplicatedStorage:FindFirstChild("_NetworkingStorage")
    if not storageFolder and isServer then
        storageFolder = Instance.new("Folder")
        storageFolder.Parent = ReplicatedStorage
        storageFolder.Name = "_NetworkingStorage"
    end
    if storageFolder then
        local endpoint = storageFolder:FindFirstChild(name)
        if endpoint then
            if endpoint:IsA(class) then
                if not isServer then
                    TranslationTable[name] = endpoint
                    endpoint.Name = HttpService:GenerateGUID()
                end
                return endpoint
            end
            return false
        elseif isServer then
            local newEndpoint = Instance.new(class)
            newEndpoint.Name = name
            newEndpoint.Parent = storageFolder
            return newEndpoint
        else
            local startedAt = tick()
            local hasGivenWarning = false
            repeat
                task.wait()
                if tick() - startedAt > 15 and not hasGivenWarning then
                    warn(
                        ("[Network] Endpoint '%s' of class '%s' was not reserved on server, yielding..."):format(
                            name,
                            class
                        )
                    )
                    hasGivenWarning = true
                end
            until storageFolder:FindFirstChild(name)
            if hasGivenWarning then
                warn(("[Network] Endpoint yield for '%s' has resolved"):format(name))
            end
            local newEndpoint = storageFolder:FindFirstChild(name)
            if newEndpoint:IsA(class) then
                if not isServer then
                    TranslationTable[name] = newEndpoint
                    newEndpoint.Name = HttpService:GenerateGUID()
                end
                return newEndpoint
            end
            return false
        end
    else
        repeat
            task.wait()
        until storageFolder
        return Network:GetEndpoint(name, class)
    end
end

function Network:ObserveSignal(name, func)
    return Promise.try(function()
        return Network:GetEndpoint(name, "RemoteEvent")
    end):andThen(function(endpoint)
        assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
        Stellar.Verbose(
            ("[Network] Now observing endpoint '%s' on %s."):format(name, isServer and "server" or "client")
        )
        if isServer then
            return endpoint.OnServerEvent:Connect(function(player, ...)
                func(player, ...)
            end)
        else
            return endpoint.OnClientEvent:Connect(func)
        end
    end)
end

function Network:Signal(name, ...)
    local endpoint = Network:GetEndpoint(name, "RemoteEvent")
    assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
    if isServer then
        if typeof(name) == "Instance" and name:IsA("Player") then
            warn("Error: You probably meant to pass the endpoint name first, not the player being signaled.")
        end
        endpoint:FireClient(...)
    else
        endpoint:FireServer(...)
    end
end

function Network:SignalAsync(name, ...)
    return Promise.try(Network.Signal, Network, name, ...)
end

function Network:SignalAll(name, ...)
    local endpoint = Network:GetEndpoint(name, "RemoteEvent")
    assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
    if isServer then
        endpoint:FireAllClients(...)
    else
        warn("[Network] 'SignalAll' is intended for firing all clients, this cannot be used on the client.")
    end
end

function Network:OnInvoke(name: string, func: (player: Player, ...any) -> nil)
    local endpoint = Network:GetEndpoint(name, "RemoteFunction")
    assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
    if isServer then
        endpoint.OnServerInvoke = function(player, ...)
            return func(player, ...)
        end
    else
        warn("[Network] Using 'OnClientInvoke' is not advised or permitted.")
    end
end

function Network:Invoke(name, ...)
    local endpoint = Network:GetEndpoint(name, "RemoteFunction")
    assert(endpoint, ("[Network] Another endpoint with name %s exists of a different class."):format(name))
    if isServer then
        warn("[Network] Using 'InvokeClient' is not advised or permitted.")
    else
        local timer = tick()
        local result = nil
        local hasLogged = false
        local hasFinished = false
        local packed = {
            ...,
        }
        task.spawn(function()
            result = table.pack(endpoint:InvokeServer(unpack(packed)))
            hasFinished = true
        end)
        while not hasFinished do
            if tick() - timer > 10 and not hasLogged then
                warn(string.format("[Network::Danger] %s is taking a long time to return! Args:", name, ...))
                hasLogged = true
            end
            task.wait()
        end
        if hasLogged then
            warn(string.format("[Network::Undanger] %s has finished return. Took %s!", name, tick() - timer))
        end
        return table.unpack(result)
    end
end

function Network:InvokePromise(name, ...)
    local args = { ... }
    return Promise.new(function(resolve, reject)
        local success, result = pcall(Network.Invoke, Network, name, unpack(args))
        if success then
            resolve(result)
        else
            reject(result)
        end
    end)
end

function Network:Reserve(...)
    for _, data in pairs({
        ...,
    }) do
        Network:GetEndpoint(data[1], data[2])
        Stellar.Verbose(("[Network] Reserved endpoint '%s' with class %s"):format(data[1], data[2]))
    end
end

return Network
