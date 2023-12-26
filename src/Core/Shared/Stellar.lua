--[[
    Stellar.lua
]]

--- @class Stellar
--- Game framework

local Stellar = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isStudio = RunService:IsStudio()
local assets, loadedAssets = {}, {}
local loadingConnections, loaded = {}, false
local initModules = {}
local packageLocations =
    { ReplicatedStorage.Packages, RunService:IsServer() and game:GetService("ServerStorage").Packages }

local ENABLE_TIME_DEBUG = false and isStudio
local VERBOSE_LOGGING = true and isStudio
local VERBOSE_WARNING = true and isStudio

function Stellar.Verbose(...)
    if VERBOSE_LOGGING then
        print(...)
    end
end

function Stellar.VerboseWarn(...)
    if VERBOSE_WARNING then
        warn(...)
    end
end

Stellar._LogQueue = {}

function Stellar._Import(module)
    if module:IsA("ModuleScript") then
        local result = nil
        local start = tick()
        local hasLogged = false

        task.spawn(function()
            result = table.pack(pcall(require, module))
        end)

        while result == nil do
            if tick() - start > 15 and not hasLogged then
                warn(string.format("[Stellar::Danger] %s is taking a long time to require!", module.Name))
                hasLogged = true
            end
            task.wait()
        end

        if hasLogged then
            warn(string.format("[Stellar::Undanger] %s has finished require. Took %s!", module.Name, tick() - start))
        end

        return table.unpack(result)
    end
end

function Stellar.Load(module)
    if module ~= script then
        assets[module.Name] = module
    end
end

function Stellar:_GetTitle()
    return isStudio and ("[Stellar] [%s]"):format(RunService:IsServer() and "Server" or "Client") or "[Stellar]"
end

function Stellar.BulkLoad(...)
    local function recurseAsset(asset)
        if asset:IsA("ModuleScript") then
            Stellar.Load(asset)
        else
            for _, v in pairs(asset:GetChildren()) do
                recurseAsset(v)
            end
        end
    end

    for _, directory in pairs({ ... }) do
        if directory then
            assert(
                directory:IsA("Folder"),
                ("%s Cannot bulk load from '%s' as it is not a folder."):format(Stellar:_GetTitle(), directory.Name)
            )
            print(("%s Loading modules in directory '%s'"):format(Stellar:_GetTitle(), directory.Name))

            recurseAsset(directory)
        end
    end
end

function Stellar:_TryInit(name, result)
    if type(result) == "table" and result.Init and not initModules[name] then
        initModules[name] = true

        local ok, state = nil, nil
        local hasWarned = false
        local start = tick()

        task.spawn(function()
            ok, state = pcall(result.Init, result)
        end)

        while ok == nil do
            if tick() - start > 15 and not hasWarned then
                warn(string.format("[Stellar::Danger] %s is taking a long time to initialise!", name))
                hasWarned = true
            end
            task.wait()
        end

        if hasWarned then
            warn(string.format("[Stellar::Undanger] %s has finished initialising. Took %s!", name, tick() - start))
        end

        if not ok then
            warn((("%s Init method for service '%s' failed due to:\n%s"):format(Stellar:_GetTitle(), name, state)))
            table.insert(Stellar._LogQueue, {
                errorMessage = ("%s Init method for service '%s' failed due to:\n%s"):format(
                    Stellar:_GetTitle(),
                    name,
                    state
                ),
                errorScriptName = name,
                errorStackTrace = name,
            })
        end
    end
end

function Stellar.Library(name)
    -- does not need to recursively search, so no need for passing it to BulkLoad
    for _, packageLocation in packageLocations do
        local module = packageLocation:FindFirstChild(name)

        if module then
            local success, result = Stellar._Import(module)

            if not success then
                warn(`{Stellar:_GetTitle()} Failed to import library '{name}': {result}`)
                return nil
            end

            return result
        end
    end

    warn(("%s Failed to find library '%s'"):format(Stellar:_GetTitle(), name))
    return nil
end

--- @param name string
--- @param dontInit boolean
--- Load a file with Stellar
function Stellar.Get(name, dontInit)
    if loadedAssets[name] then
        if not dontInit then
            local start = tick()
            Stellar:_TryInit(name, loadedAssets[name])
            if ENABLE_TIME_DEBUG and tick() - start > 0.1 then
                warn(`[Stellar] [Init] {name} took {tick() - start} seconds!`)
            end
        end

        return loadedAssets[name]
    end
    if not assets[name] then
        local yieldTime = tick()
        warn(("%s Yielding for unimported module '%s'"):format(Stellar:_GetTitle(), name))
        repeat
            task.wait()
        until assets[name] or tick() >= yieldTime + 5
    end
    if assets[name] then
        local start = tick()
        local success, result = Stellar._Import(assets[name])
        if ENABLE_TIME_DEBUG and tick() - start > 0.1 then
            warn(`[Stellar] [Require] {name} took {tick() - start} seconds!`)
        end

        if success then
            loadedAssets[name] = result
            Stellar.Verbose(
                ("%s Successfully imported '%s' for the first time, cached. Init method %s."):format(
                    Stellar:_GetTitle(),
                    name,
                    (type(result) == "table" and result.Init) and "found" or "not found"
                )
            )

            if not dontInit then
                Stellar:_TryInit(name, result)
            end

            return result
        else
            assets[name] = nil
            warn(("%s Failed to import module '%s': %s"):format(Stellar:_GetTitle(), name, result))
            table.insert(Stellar._LogQueue, {
                errorMessage = ("%s Failed to import module '%s': %s"):format(Stellar:_GetTitle(), name, result),
                errorScriptName = name,
                errorStackTrace = name,
            })
        end
    else
        warn(("%s Module '%s' exceed yield threshhold, request ignored."):format(Stellar:_GetTitle(), name))
    end
end

function Stellar.BulkGet(...)
    local modules, raw = {}, { ... }

    for _, module in pairs(raw) do
        local start = tick()
        modules[module] = Stellar.Get(module)
        if tick() - start > 0.5 then
            warn(`[Stellar] [Duration] {module} took {tick() - start} seconds!`)
        end
    end

    return modules
end

function Stellar.MarkAsLoaded()
    if not loaded then
        for _, func in pairs(loadingConnections) do
            task.spawn(func)
        end
        loaded = true
        print("[Stellar] Client marked as loaded!")
    end
end

function Stellar.OnLoadingCompletion(func)
    if loaded then
        task.spawn(func)
    else
        table.insert(loadingConnections, func)
    end
end

return Stellar
