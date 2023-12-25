--[[
    SignalProvider.lua
    via Stellar
--]]

local Stellar = shared.Stellar
local Signal = Stellar.Library("Signal")

local SignalProvider = {}
local Signals = {}

--// Returns the signal or creates a new one
function SignalProvider:Get(name)
    local signal = (Signals[name] or self:_Register(name))

    return signal
end

--// Removes a signal from memory
function SignalProvider:Remove(name)
    if Signals[name] == nil then
        return warn(string.format("Signal with name %s has not been registered!", name))
    end

    Signals[name]:Destroy()
    Signals[name] = nil
    return nil
end

--// Creates a new signal, and caches it in memory
function SignalProvider:_Register(name)
    if Signals[name] then
        return warn(string.format("Signal with name %s has already been registered!", name))
    end

    local signal = Signal.new()

    Signals[name] = signal

    return signal
end

return SignalProvider
