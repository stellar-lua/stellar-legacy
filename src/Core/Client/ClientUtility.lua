--[[
    ClientUtility.lua
    via Stellar
--]]

local ClientUtility = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ProximityPrompt = game:GetService("ProximityPromptService")
local Player = Players.LocalPlayer

local Stellar = shared.Stellar
local Network = Stellar.Get("Network")
local Signal = Stellar.Get("Signal")

function ClientUtility:GetLocalPlayerHeadShot(type, size)
    local content, isReady = Players:GetUserThumbnailAsync(
        Player.UserId,
        type or Enum.ThumbnailType.HeadShot,
        size or Enum.ThumbnailSize.Size420x420
    )

    if isReady then
        return content
    else
        return ""
    end
end

function ClientUtility:SetPrompts(state)
    ProximityPrompt.Enabled = state
end

function ClientUtility:SetCore(state)
    StarterGui:SetCoreGuiEnabled("Chat", state)
    StarterGui:SetCoreGuiEnabled("EmotesMenu", state)
    StarterGui:SetCoreGuiEnabled("Health", state)
end

function ClientUtility:IsMobile()
    return ClientUtility.isUsingTouch
end

function ClientUtility:IsXbox()
    return GuiService:IsTenFootInterface()
end

function ClientUtility:IsGamepad()
    return ClientUtility.isUsingGamepad
end

function ClientUtility:IsGamepadInput(UserInputType)
    -- could be Gamepad1, Gamepad2, ..., Gamepad8
    return UserInputType and string.sub(UserInputType.Name, 0, 7) == "Gamepad"
end

function ClientUtility:Init()
    ClientUtility.UsingGamepadChanged = Signal.new("UsingGamepadChanged")
    ClientUtility.UsingTouchChanged = Signal.new("UsingTouchChanged")

    ClientUtility.isUsingTouch = not UserInputService.KeyboardEnabled and UserInputService.TouchEnabled
    ClientUtility.lastUsedGamepad = Enum.UserInputType.Gamepad1
    ClientUtility.isUsingGamepad = ClientUtility:IsXbox()
        or ClientUtility:IsGamepadInput(UserInputService:GetLastInputType())

    UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
        local isNewInputTouch = lastInputType == Enum.UserInputType.Touch
        if ClientUtility.isUsingTouch ~= isNewInputTouch then
            ClientUtility.isUsingTouch = isNewInputTouch
            ClientUtility.UsingTouchChanged:Fire(isNewInputTouch)
        end

        local isNewInputGamepad = ClientUtility:IsGamepadInput(lastInputType)
        ClientUtility.lastUsedGamepad = lastInputType
        if ClientUtility.isUsingGamepad ~= isNewInputGamepad then
            ClientUtility.UsingGamepadChanged:Fire(isNewInputGamepad)
            ClientUtility.isUsingGamepad = isNewInputGamepad
        end
    end)

    if ClientUtility:IsXbox() then
        Network:Signal("RequestXbox")
    end
end

return ClientUtility
