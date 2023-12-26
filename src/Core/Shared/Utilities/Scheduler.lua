--[[
    Scheduler.lua
    via Stellar
--]]

--- @class Scheduler
--- Schedule tasks to be run in specified intervals
local Scheduler = {}
Scheduler.__index = Scheduler

local Stellar = shared.Stellar
local RunService = game:GetService("RunService")
local Maid = Stellar.Get("Maid")
local Signal = Stellar.Get("Signal")

--- Create a new Scheduler object
--- @param loopTime number
--- @return Scheduler
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

--- Begin running tasks
function Scheduler:Start()
    self._Maid:GiveTask(RunService.Heartbeat:Connect(function()
        if tick() - self._Elapsed > self.LoopTime then
            self._Elapsed = tick()
            self._Signal:Fire()
        end
    end))
end

--- Add a task to the Scheduler
--- @param func function
--- @return RBXScriptConnection
function Scheduler:Tick(func)
    return self._Signal:Connect(func)
end

--- Destory and disable the Scheduler
--- @return nil
function Scheduler:Destroy()
    self._Maid:DoCleaning()
end

return Scheduler
