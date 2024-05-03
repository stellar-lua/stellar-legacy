--[[
    UserInterface.lua
    via Stellar
--]]

local UserInterface = {}
local Stellar = shared.Stellar

local Network = Stellar.Get("Network")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ClientUtility = Stellar.Get("ClientUtility")
local Signal = Stellar.Get("Signal")
local Player = Players.LocalPlayer

local coreGui = Player.PlayerGui:WaitForChild("CoreGui", 100)
local loadedModules, currentInterfaces = {}, {}
local objects = {}
local showSignalCache = {}
local hidSignalCache = {}

function UserInterface:_Import(obj)
    if not objects[obj] then
        objects[obj] = true
        local correspondingModule = script.InterfaceModules:FindFirstChild(obj.Name)

        if correspondingModule then
            local success, result = nil, nil
            local hasLogged = false
            local start = tick()

            task.spawn(function()
                success, result = pcall(require, correspondingModule)
            end)

            while success == nil do
                if tick() - start > 15 and not hasLogged then
                    warn(
                        string.format(
                            "[UI::Danger] Importing %s is taking a dangerous amount of time!",
                            correspondingModule.Name
                        )
                    )
                    hasLogged = true
                end
                task.wait()
            end

            if hasLogged then
                warn(
                    string.format(
                        "[UI::Undanger] %s has finished require. Took %s!",
                        correspondingModule.Name,
                        tick() - start
                    )
                )
            end

            if success then
                loadedModules[obj.Name] = result
                Stellar.Verbose(
                    ("[Stellar] [User Interface] Interface module '%s' has successfully loaded"):format(obj.Name)
                )

                if type(result) == "table" and result.Init then
                    local initSuccess, err = nil, nil
                    local hasWarned = false
                    local initStart = tick()

                    task.spawn(function()
                        initSuccess, err = pcall(result.Init, result)
                    end)

                    while initSuccess == nil do
                        if tick() - initStart > 15 and not hasWarned then
                            warn(
                                string.format(
                                    "[UI::Danger] %s is taking a long time to initialise!",
                                    correspondingModule.Name
                                )
                            )
                            hasWarned = true
                        end
                        task.wait()
                    end

                    if hasLogged then
                        warn(
                            string.format(
                                "[UI::Undanger] %s has finished initialising. Took %s!",
                                correspondingModule.Name,
                                tick() - initStart
                            )
                        )
                    end

                    if not initSuccess then
                        warn(("[Stellar] [User Interface] Module %s failed to load!\n%s"):format(obj.Name, err))
                    end
                end
            else
                warn("[UserInterface] Failed to require CoreGui module: " .. obj.Name)
            end
        end
    end
end

function UserInterface:Init()
    --StarterGui:SetCoreGuiEnabled("PlayerList", false)
    for _, frame in pairs(coreGui:GetChildren()) do
        local start = tick()
        UserInterface:_Import(frame)
        if tick() - start > 0.5 then
            warn(`[UserInterface] [Duration] {frame.Name} took {tick() - start} seconds!`)
        end
    end

    Network:ObserveSignal("UserInterface", function(request: string, target: string)
        if request == "Show" then
            UserInterface:Show(target)
        elseif request == "Hide" then
            UserInterface:Hide(target)
        end
    end)

    local function addXboxTags(element)
        local XboxAttribute = element:GetAttribute("Xbox")
        if XboxAttribute == true then
            CollectionService:AddTag(element, "XboxShow")
        elseif XboxAttribute == false then
            CollectionService:AddTag(element, "XboxHide")
        end
    end

    Player.PlayerGui.DescendantAdded:Connect(addXboxTags)
    for _, descendant in pairs(Player.PlayerGui:GetDescendants()) do
        addXboxTags(descendant)
    end

    CollectionService:GetInstanceAddedSignal("XboxShow"):Connect(function(element)
        element.Visible = ClientUtility.isUsingGamepad
    end)

    CollectionService:GetInstanceAddedSignal("XboxHide"):Connect(function(element)
        element.Visible = not ClientUtility.isUsingGamepad
    end)

    local function updateXboxElements(isUsingGamepad)
        for _, button in pairs(CollectionService:GetTagged("XboxShow")) do
            button.Visible = isUsingGamepad
        end
        for _, button in pairs(CollectionService:GetTagged("XboxHide")) do
            button.Visible = not isUsingGamepad
        end
    end

    ClientUtility.UsingGamepadChanged:Connect(updateXboxElements)
    updateXboxElements(ClientUtility.isUsingGamepad)
end

function UserInterface:GetFrame(name): Frame?
    return coreGui:FindFirstChild(name)
end

function UserInterface:IsVisible(name: string)
    if coreGui:FindFirstChild(name) then
        return coreGui:FindFirstChild(name).Visible
    end
    return false
end

function UserInterface:HideAll()
    coreGui.Enabled = false
end

function UserInterface:ShowAll()
    coreGui.Enabled = true
end

function UserInterface:Get(name, fromCache)
    if loadedModules[name] then
        return loadedModules[name]
    elseif not fromCache then
        local startWait = tick()
        print(("[UserInterface] Yielding for module '%s'."):format(name))
        repeat
            task.wait()
        until (tick() - startWait > 15) or loadedModules[name]

        if loadedModules[name] then
            return loadedModules[name]
        end
    end
end

function UserInterface:Show(name, main)
    local interface = UserInterface:GetFrame(name)

    if interface then
        local module = UserInterface:Get(name, true)

        if module and typeof(module) == "table" and module._StellarShow then
            task.spawn(function()
                local success, result = pcall(module._StellarShow)
                if not success then
                    warn("_StellarShow Failed!", result)
                end
            end)
        else
            interface.Visible = true
        end

        if main then
            for _, currentInterface in pairs(currentInterfaces) do
                if currentInterface ~= name then
                    UserInterface:Hide(currentInterface)
                end
            end
            if not table.find(currentInterfaces, name) then
                table.insert(currentInterfaces, name)
            end
        end

        if showSignalCache[name] then
            showSignalCache[name]:Fire()
        end
    end
end

function UserInterface:Hide(name)
    local interface = UserInterface:GetFrame(name)

    if interface then
        local module = UserInterface:Get(name, true)

        if module and typeof(module) == "table" and module._StellarHide then
            task.spawn(function()
                pcall(module._StellarHide)
            end)
        else
            interface.Visible = false
        end

        if table.find(currentInterfaces, name) then
            table.remove(currentInterfaces, table.find(currentInterfaces, name))
        end

        if hidSignalCache[name] then
            hidSignalCache[name]:Fire()
        end
    end
end

function UserInterface:IsMainOpen()
    return #currentInterfaces > 0
end

function UserInterface:GetInterfaceShownSignal(name)
    local frame = UserInterface:GetFrame(name)

    if frame then
        if showSignalCache[name] == nil then
            showSignalCache[name] = Signal.new("InterfaceShowSignal")
        end

        return showSignalCache[name]
    end
end

function UserInterface:GetInterfaceHiddenSignal(name)
    local frame = UserInterface:GetFrame(name)

    if frame then
        if hidSignalCache[name] == nil then
            hidSignalCache[name] = Signal.new("InterfaceHideSignal")
        end

        return hidSignalCache[name]
    end
end

return UserInterface
