--[[
    Interaction.lua
    via Stellar
--]]

local Interaction = {}
Interaction.__index = Interaction

local Stellar = shared.Stellar
local Maid = Stellar.Get("Maid")

function Interaction.new(part: Instance, actionText: string, duration: number, distance: number)
    assert(
        part:IsA("BasePart") or (part:IsA("Model") and part.PrimaryPart),
        "[Interaction] Arg1(Part) expected to be part/model."
    )
    assert(not actionText or type(actionText) == "string", "[Interaction] Arg2(actionText) expected to be string.")
    assert(not duration or type(duration) == "number", "[Interaction] Arg3(duration) expected to be number.")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Enabled = false
    prompt.Parent = part:IsA("BasePart") and part or part.PrimaryPart
    prompt.RequiresLineOfSight = false
    prompt.ActionText = actionText or "Interact"
    prompt.MaxActivationDistance = distance or 10
    prompt.HoldDuration = duration or 0

    local self = setmetatable({
        Part = part,
        Prompt = prompt,
        _Maid = Maid.new(),
    }, Interaction)

    return self
end

function Interaction:SetAction(text)
    self.Prompt.ActionText = text
end

function Interaction:ApplyConfig(actionText)
    assert(not actionText or type(actionText) == "string", "[Interaction] Arg1(actionText) expected to be string.")
    self.Prompt.ActionText = actionText or self.Prompt.ActionText
end

function Interaction:SetKeyboardActivation(enum)
    self.Prompt.KeyboardKeyCode = enum
end

function Interaction:Disable()
    self.Prompt.Enabled = false
end

function Interaction:Enable()
    self.Prompt.Enabled = true
end

function Interaction:SetDuration(duration)
    self.Prompt.HoldDuration = duration
end

function Interaction:Triggered(func: (triggeredBy: Player) -> nil)
    local conn = self.Prompt.Triggered:Connect(func)
    self._Maid:GiveTask(conn)
    return conn
end

function Interaction:HoldBegan(func)
    self._Maid:GiveTask(self.Prompt.PromptButtonHoldBegan:Connect(func))
end

function Interaction:HoldEnded(func)
    self._Maid:GiveTask(self.Prompt.PromptButtonHoldEnded:Connect(func))
end

function Interaction:Destroy()
    if not self.Destroyed then
        self.Prompt:Destroy()
        self._Maid:DoCleaning()
    end
end

return Interaction
