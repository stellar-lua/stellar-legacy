--[[
    Button.lua
    via Stellar
--]]

local Button = {}
Button.__index = Button
local Stellar = shared.Stellar

local Maid = Stellar.Get("Maid")
local SoundFX = shared.Stellar.Get("SoundFX")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local InterfaceUtility = Stellar.Get("InterfaceUtility")
local ClientUtility = Stellar.Get("ClientUtility")
local Signal = Stellar.Get("Signal")

local Mouse = Players.LocalPlayer:GetMouse()
local ButtonClickEffect = game.ReplicatedStorage.Assets.ButtonEffect
local ButtonClickEffectParent = Players.LocalPlayer.PlayerGui.CoreGui:FindFirstChild("_ButtonEffect")

function Button.new(instance, clickEffect, callBackDelay, ignoreHover)
    local cooldown = false
    assert(
        instance:IsA("ImageButton") or instance:IsA("TextButton"),
        ("[Button] Instance passed must be a button, a '%s' was passed."):format(instance.ClassName)
    )

    local self = setmetatable({
        instance = instance,
        originalSize = instance.Size,
        shouldShowEffect = not instance:FindFirstAncestorOfClass("SurfaceGui"),
        callBackDelay = callBackDelay or 0,
        maid = Maid.new(),
        XboxButton = nil,
        callBacks = {
            clicks = {},
            mouseEnters = {},
            mouseLeaves = {},
        },
    }, Button)
    --//alias
    self.Instance = instance
    self.Clicked = Signal.new("ButtonClicked")

    local function Clicked()
        self.Clicked:Fire()

        if self.shouldShowEffect then
            local effect = ButtonClickEffect:Clone()
            effect.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
            effect.Size = UDim2.fromOffset(0, 0)
            effect.Parent = ButtonClickEffectParent

            TweenService:Create(effect, TweenInfo.new(0.2), {
                Size = UDim2.fromOffset(60, 60),
                ImageTransparency = 1,
            }):Play()

            task.delay(0.25, function()
                effect:Destroy()
            end)
        end

        if Players.LocalPlayer:GetAttribute("DeathScreen") then
            return
        end

        if not cooldown then
            cooldown = true
            if clickEffect then
                self:ClickEffect()
            end
            SoundFX:Play(
                "ButtonClick",
                --[[part]]
                nil,
                --[[duration]]
                nil,
                --[[dupe]]
                nil,
                --[[ignoreIfNotLoaded]]
                true
            )
            task.delay(callBackDelay, function()
                for _, callback in pairs(self.callBacks.clicks) do
                    local success, err = pcall(callback)

                    if not success and err then
                        warn(
                            ("[Button] Callback failed for button " .. self.Instance.Name .. " with error:\n%s"):format(
                                err
                            )
                        )
                    end
                end
            end)
            task.wait(0.4)
            cooldown = false
        end
    end

    self.maid:GiveTask(instance.MouseButton1Down:Connect(Clicked))

    self.maid:GiveTask(instance.MouseEnter:Connect(function()
        if ignoreHover then
            return
        end
        SoundFX:Play("Hover")
        for _, callback in pairs(self.callBacks.mouseEnters) do
            local success, possibleError = pcall(callback)
            if not success then
                warn("[Button Fail]", possibleError)
            end
        end
    end))

    self.maid:GiveTask(instance.MouseLeave:Connect(function()
        for _, callback in pairs(self.callBacks.mouseLeaves) do
            local success, possibleError = pcall(callback)
            if not success then
                warn("[Button Fail]", possibleError)
            end
        end
    end))

    self.maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if
            ClientUtility:IsGamepadInput(input.UserInputType)
            and self.XboxButton == input.KeyCode
            and (not gameProcessed or input.KeyCode == Enum.KeyCode.ButtonA)
            and InterfaceUtility:IsVisible(instance)
        then
            Clicked()
        end
    end))

    return self
end

function Button:ClickEffect()
    self.instance:TweenSize(
        UDim2.fromScale(self.originalSize.X.Scale / 1.8, self.originalSize.Y.Scale / 1.8),
        "Out",
        "Quad",
        0.15
    )
    delay(0.25, function()
        if self.instance and self.instance.Parent then
            self.instance:TweenSize(self.originalSize, "Out", "Quad", 0.15)
        end
    end)
end

function Button:SetXboxButton(enum)
    if typeof(enum) == "EnumItem" then
        self.Instance.Selectable = false
        self.XboxButton = enum
    end
end

function Button:OnClick(callback)
    table.insert(self.callBacks.clicks, callback)
end

function Button:MouseHovered(callback)
    table.insert(self.callBacks.mouseEnters, callback)
end

function Button:MouseLeft(callback)
    table.insert(self.callBacks.mouseLeaves, callback)
end

function Button:WaitClick()
    self.Clicked:Wait()
end

function Button:Destroy()
    -- when the client is disconnecting, self and self.maid may sometimes be nil.
    -- not quite sure why that happens, but this fixes the issue.
    if self and self.maid then
        self.maid:DoCleaning()
    end
end

return Button
