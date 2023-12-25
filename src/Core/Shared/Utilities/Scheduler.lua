--[[
    Scheduler.lua
    via Stellar
--]]

local Scheduler = {}
Scheduler.__index = Scheduler

local Stellar = shared.Stellar
local RunService = game:GetService("RunService")
local Maid = Stellar.Get("Maid")
local Signal = Stellar.Get("Signal")

function Scheduler.new(loopTime)
    local self = setmetatable({
        LoopTime = loopTime,
        _Signal = Signal.new("SchedulerSignal"),
        _Elapsed = 0,
        _Maid = Maid.new(),
    }, Scheduler)

    self._Maid:GiveTask(self._Signal)

    return self
end

function Scheduler:Start()
    self._Maid:GiveTask(RunService.Heartbeat:Connect(function()
        if tick() - self._Elapsed > self.LoopTime then
            self._Elapsed = tick()
            self._Signal:Fire()
        end
    end))
end

function Scheduler:Tick(func)
    return self._Signal:Connect(func)
end

function Scheduler:Destroy()
    self._Maid:DoCleaning()
end

return Scheduler
