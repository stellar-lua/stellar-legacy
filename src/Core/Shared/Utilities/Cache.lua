--[[
    Cache.lua
    via Stellar
]]

local Cache = {}
Cache.__index = Cache

local Stellar = shared.Stellar
local RunService = game:GetService("RunService")

local Maid = Stellar.Get("Maid")
local Signal = Stellar.Get("Signal")

function SafeSetData(func)
    local success, result = pcall(func)

    if success then
        return result
    end
end

function Cache.new(expiryTime, fetchFunction)
    local self = setmetatable({
        _Maid = Maid.new(),
        FetchFunction = fetchFunction,
        Data = SafeSetData(fetchFunction),
        ExpiryTime = expiryTime,
        Updated = Signal.new(),
        LastExpiry = tick(),
        Suspended = false,
    }, Cache)

    self._Maid:GiveTask(self.Updated)
    self.Updated:Fire(self.Data)

    self._Maid:GiveTask(RunService.Heartbeat:Connect(function()
        if tick() - self.LastExpiry >= self.ExpiryTime and not self.Suspended then
            self.LastExpiry = tick()
            self.Data = SafeSetData(self.FetchFunction)
            self.Updated:Fire(self.Data)
        end
    end))

    return self
end

function Cache:Suspend()
    self.Suspended = true
end

function Cache:Resume()
    self.Suspended = false
end

function Cache:Fetch()
    if self.Data then
        return self.Data
    end

    if self.Suspended then
        return
    end

    self.LastExpiry = tick()
    self.Data = SafeSetData(self.FetchFunction)
    self.Updated:Fire(self.Data)
    return self.Data
end

function Cache:FetchImmediately()
    if self.Suspended then
        if self.Data then
            return self.Data
        end
        return
    end

    self.LastExpiry = tick()
    self.Data = SafeSetData(self.FetchFunction)
    self.Updated:Fire(self.Data)
    return self.Data
end

function Cache:Destroy()
    self._Maid:Destroy()
end

return Cache
