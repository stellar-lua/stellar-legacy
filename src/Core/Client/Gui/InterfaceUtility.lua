--[[
    InterfaceUtility.lua
    via Stellar
--]]

local Utility = { Cache = {} }

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function SetData(Data, Transparency)
    local SoftData = {}

    for n, _ in next, Data do
        SoftData[n] = Transparency
    end

    return SoftData
end

function Utility:TweenTransparency(Object, Transparency, TweenTime, IsBackground, Callback)
    if IsBackground or not self.Cache[Object] then
        local Cache = {}
        if Object.ClassName:match("Image") then
            Cache.ImageTransparency = Object.ImageTransparency
        end
        if Object.ClassName:match("Text") and not Object:IsA("UITextSizeConstraint") then
            Cache.TextTransparency = Object.TextTransparency
        end
        if IsBackground or Object:IsA("GuiObject") and Object.BackgroundTransparency ~= 1 then
            Cache.BackgroundTransparency = Object.BackgroundTransparency
        end
        if Object:IsA("ScrollingFrame") then
            Cache.ScrollBarImageTransparency = Object.ScrollBarImageTransparency
        end
        if Object:IsA("UIStroke") then
            Cache.Transparency = Object.Transparency
        end
        if Cache ~= {} then
            self.Cache[Object] = Cache
        end
    end

    local Cache = self.Cache[Object]
    if Cache then
        local Tween = TweenService:Create(
            Object,
            TweenInfo.new((TweenTime or 0.2), Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
            Transparency ~= "Show" and SetData(Cache, Transparency) or Cache
        )
        Tween:Play()
        if typeof(Callback) == "function" then
            Tween.Completed:Connect(Callback)
        end
    end
end

function Utility:RecurseTransparency(ObjectRoot, Transparency, TweenTime)
    self:TweenTransparency(ObjectRoot, Transparency, TweenTime)

    for _, Object in pairs(ObjectRoot:GetChildren()) do
        self:RecurseTransparency(Object, Transparency, TweenTime)
    end
end

function Utility:SlowTopLevelTransparency(ObjectRoot, Transparency, TweenTime)
    for _, Object in pairs(ObjectRoot:GetChildren()) do
        self:TweenTransparency(Object, Transparency, TweenTime)
        wait(0.05)
    end
end

function Utility:RecurseSlowTopLevelTransparency(ObjectRoot, Transparency, TweenTime)
    self:TweenTransparency(ObjectRoot, Transparency, TweenTime)
    for _, Object in pairs(ObjectRoot:GetChildren()) do
        self:RecurseTransparency(Object, Transparency, TweenTime)
        wait(0.05)
    end
end

function Utility:Blur(value, time, state)
    if state == "Show" then
        Lighting:WaitForChild("MenuBlur").Enabled = true
    end
    TweenService:Create(
        Lighting:WaitForChild("MenuBlur"),
        TweenInfo.new(time or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = value }
    ):Play()
    if state == "Hide" then
        wait(time)
        Lighting:WaitForChild("MenuBlur").Enabled = false
    end
end

function Utility:MouseEntered(buttons, func)
    for _, button in pairs(buttons) do
        if button:IsA("ImageButton") or button:IsA("TextButton") then
            button.MouseEnter:Connect(function()
                local success, possibleError = pcall(func, button)
                if not success then
                    warn("[Utility:MouseLeft]", possibleError)
                end
            end)
        end
    end
end

function Utility:MouseLeft(buttons, func)
    for _, button in pairs(buttons) do
        if button:IsA("ImageButton") or button:IsA("TextButton") then
            button.MouseLeave:Connect(function()
                local success, possibleError = pcall(func, button)
                if not success then
                    warn("[Utility:MouseLeft]", possibleError)
                end
            end)
        end
    end
end

function Utility:_AncestorsVisible(object, depth)
    local parent = object.parent
    if parent:IsA("ScreenGui") and parent.Enabled then
        return true
    elseif parent:IsA("GuiBase2d") and parent.Visible then
        return Utility:_AncestorsVisible(parent, depth + 1)
    else
        return false
    end
end

function Utility:IsVisible(object)
    if object:IsDescendantOf(Player.PlayerGui) and object:IsA("GuiBase2d") then
        if object:IsA("ScreenGui") and object.Enabled then
            return true
        elseif object.Visible then
            local viewSize = workspace.CurrentCamera.ViewportSize
            local absPosition = object.AbsolutePosition + (object.AbsoluteSize * object.AnchorPoint)
            if
                0 < absPosition.X
                and absPosition.X < viewSize.X
                and 0 < absPosition.Y
                and absPosition.Y < viewSize.Y
            then
                return Utility:_AncestorsVisible(object, 1)
            end
        end
    end
    return false
end

return Utility
