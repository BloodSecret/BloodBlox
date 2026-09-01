-- BloodyBlox v0.5.11 (2026-09-01) - Teleport Rename, AntiAim Context Menu Fix, Config Load UI Fix

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

if _G.BloodyBloxLoaded then
    warn("[BloodyBlox] Already running")
    return
end
_G.BloodyBloxLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:WaitForChild("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local settings = {
    fastWeight = false,
    autoWeight = false,
    durabilityFarm = false,
    autoDurability = false,
    autoRebirth = false,
    badAuraFarm = false,
    badAuraInterval = 5,
    antiAim = false,
    antiAimSpeed = 5,
    antiAimType = "Jitter",
    killAura = false,
    killAuraRange = 20,
    fastHits = false,
    remoteSpy = false,
    walkWithDumbbell = false,
    walkSpeed = 16,
    fastStrafe = false,
    antiRagdoll = false,
    airStrafe = false,
    airStrafeSpeed = 30,
    espEnabled = false,
    espBoxes = true,
    espNames = true,
    espDistance = true,
    espHealth = true,
    espTracers = false,
    espTeamCheck = false,
    fullbright = false,
    fly = false,
    flySpeed = 5,
    noclip = false,
    infiniteJump = false,
    godMode = false,
    showWatermark = true,
    moveWatermark = false,
    menuScale = 1.0,
    configName = "default"
}

local connections = {}
local espObjects = {}
local teleportPoints = {}
local logs = {}
local maxLogs = 100
local originalLightingSettings = {}
local originalCanCollide = {}
local originalWalkSpeed = 16
local godModeActive = false
local remoteHookInstalled = false
local originalNamecall
local captureActive = false
local capturedRemotes = {}

local cachedWeightRemotes = {}
local cachedDurabilityRemotes = {}
local cachedRebirthRemotes = {}
local cachedAttackRemotes = {}
local cachedPlayers = {}
local lastPlayerCacheUpdate = 0

local lastFastWeightFire = 0
local lastDurabilityFire = 0
local lastKillAuraFire = {}
local lastBadAuraFire = 0
local lastAutoWeightAction = 0
local lastAutoDurabilityAction = 0
local lastAutoRebirthFire = 0

local weightToolActivatedConnection = nil
local durabilityToolActivatedConnection = nil

local goodAuraRanks = {
    "Ангел Защитник",
    "Пример для подражания",
    "Спаситель",
    "Авангард",
    "Защитник",
    "Миротворец",
    "Чемпион",
    "Мститель",
    "Герой",
    "Хранитель",
    "Принудитель",
    "Охранник",
    "Красивая",
    "Нейтральный",
    ""
}

local function addLog(category, message)
    local timestamp = os.date("%H:%M:%S")
    table.insert(logs, 1, string.format("[%s] [%s] %s", timestamp, category, message))
    if #logs > maxLogs then
        table.remove(logs, #logs)
    end
end

local function saveConfig(name)
    local config = HttpService:JSONEncode(settings)
    writefile("bloodyblox_" .. name .. ".json", config)
    addLog("Config", "Saved: " .. name)
end

local function loadConfig(name)
    if isfile("bloodyblox_" .. name .. ".json") then
        local config = HttpService:JSONDecode(readfile("bloodyblox_" .. name .. ".json"))
        for k, v in pairs(config) do
            if settings[k] ~= nil then
                settings[k] = v
            end
        end
        addLog("Config", "Loaded: " .. name)

        -- Apply loaded settings to UI (update all toggles/sliders)
        task.wait(0.1)
        for _, obj in pairs(screenGui:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Name == "ToggleButton" then
                local settingKey = obj:GetAttribute("SettingKey")
                if settingKey and settings[settingKey] ~= nil then
                    -- Update toggle button visual state
                    obj.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
                    obj.Text = settings[settingKey] and "ON" or "OFF"

                    -- Update indicator
                    local indicator = obj:FindFirstChild("Indicator")
                    if indicator then
                        indicator.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    end
                end
            elseif obj:IsA("TextBox") and obj.Name == "SliderInput" then
                local settingKey = obj:GetAttribute("SettingKey")
                if settingKey and settings[settingKey] ~= nil then
                    obj.Text = tostring(settings[settingKey])
                end
            end
        end

        return true
    end
    return false
end

local function deleteConfig(name)
    if isfile("bloodyblox_" .. name .. ".json") then
        delfile("bloodyblox_" .. name .. ".json")
        addLog("Config", "Deleted: " .. name)
    end
end

local function saveTeleportPoints()
    local data = HttpService:JSONEncode(teleportPoints)
    writefile("bloodyblox_teleports.json", data)
end

local function loadTeleportPoints()
    if isfile("bloodyblox_teleports.json") then
        teleportPoints = HttpService:JSONDecode(readfile("bloodyblox_teleports.json"))
        addLog("Teleport", "Loaded " .. #teleportPoints .. " points")
    end
end

local function cacheRemotes(keywords, cacheTable)
    table.clear(cacheTable)
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            for _, keyword in ipairs(keywords) do
                if string.find(name, keyword) then
                    table.insert(cacheTable, remote)
                    break
                end
            end
        end
    end
    addLog("Cache", "Cached " .. #cacheTable .. " remotes for " .. table.concat(keywords, "/"))
end

local function getPlayerAuraRank(targetPlayer)
    if not targetPlayer.Character then return nil end

    local head = targetPlayer.Character:FindFirstChild("Head")
    if not head then return nil end

    for _, gui in pairs(head:GetChildren()) do
        if gui:IsA("BillboardGui") then
            for _, label in pairs(gui:GetDescendants()) do
                if label:IsA("TextLabel") then
                    local text = label.Text
                    for _, rank in ipairs(goodAuraRanks) do
                        if rank ~= "" and string.find(text, rank) then
                            return rank
                        end
                    end
                    if text == "" or text == " " then
                        return ""
                    end
                end
            end
        end
    end

    return nil
end

local function createESP(target)
    if not target:IsA("Model") or not target:FindFirstChild("HumanoidRootPart") then return end

    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        healthBar = Drawing.new("Line"),
        healthBarBg = Drawing.new("Line"),
        tracer = Drawing.new("Line")
    }

    esp.box.Thickness = 2
    esp.box.Color = Color3.fromRGB(255, 0, 0)
    esp.box.Transparency = 1
    esp.box.Filled = false

    esp.name.Color = Color3.fromRGB(255, 255, 255)
    esp.name.Size = 16
    esp.name.Center = true
    esp.name.Outline = true

    esp.distance.Color = Color3.fromRGB(255, 255, 255)
    esp.distance.Size = 14
    esp.distance.Center = true
    esp.distance.Outline = true

    esp.healthBar.Thickness = 3
    esp.healthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.healthBarBg.Thickness = 3
    esp.healthBarBg.Color = Color3.fromRGB(50, 50, 50)

    esp.tracer.Thickness = 1
    esp.tracer.Color = Color3.fromRGB(255, 255, 255)
    esp.tracer.Transparency = 0.5

    espObjects[target] = esp
end

local function updateESP()
    if not settings.espEnabled then return end

    for target, esp in pairs(espObjects) do
        if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Humanoid") then
            local hrp = target.HumanoidRootPart
            local hum = target.Humanoid

            if settings.espTeamCheck then
                local targetPlayer = Players:GetPlayerFromCharacter(target)
                if targetPlayer and targetPlayer.Team == player.Team then
                    esp.box.Visible = false
                    esp.name.Visible = false
                    esp.distance.Visible = false
                    esp.healthBar.Visible = false
                    esp.healthBarBg.Visible = false
                    esp.tracer.Visible = false
                    continue
                end
            end

            local vector, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local headPos = workspace.CurrentCamera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, 2, 0)).Position)
                local legPos = workspace.CurrentCamera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -2.5, 0)).Position)

                local height = math.abs(headPos.Y - legPos.Y)
                local width = height * 0.5

                if settings.espBoxes then
                    esp.box.Size = Vector2.new(width, height)
                    esp.box.Position = Vector2.new(vector.X - width/2, vector.Y - height/2)
                    esp.box.Visible = true
                else
                    esp.box.Visible = false
                end

                if settings.espNames then
                    esp.name.Text = target.Name
                    esp.name.Position = Vector2.new(vector.X, headPos.Y - 20)
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end

                if settings.espDistance then
                    local distance = math.floor((rootPart.Position - hrp.Position).Magnitude)
                    esp.distance.Text = tostring(distance) .. "m"
                    esp.distance.Position = Vector2.new(vector.X, legPos.Y + 5)
                    esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end

                if settings.espHealth then
                    local healthPercent = hum.Health / hum.MaxHealth
                    esp.healthBarBg.From = Vector2.new(vector.X - width/2, legPos.Y + 15)
                    esp.healthBarBg.To = Vector2.new(vector.X + width/2, legPos.Y + 15)
                    esp.healthBarBg.Visible = true

                    esp.healthBar.From = Vector2.new(vector.X - width/2, legPos.Y + 15)
                    esp.healthBar.To = Vector2.new(vector.X - width/2 + (width * healthPercent), legPos.Y + 15)
                    esp.healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    esp.healthBar.Visible = true
                else
                    esp.healthBar.Visible = false
                    esp.healthBarBg.Visible = false
                end

                if settings.espTracers then
                    esp.tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    esp.tracer.To = Vector2.new(vector.X, vector.Y)
                    esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end
            else
                esp.box.Visible = false
                esp.name.Visible = false
                esp.distance.Visible = false
                esp.healthBar.Visible = false
                esp.healthBarBg.Visible = false
                esp.tracer.Visible = false
            end
        else
            esp.box.Visible = false
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
            esp.tracer.Visible = false
        end
    end
end

local function clearESP()
    for _, esp in pairs(espObjects) do
        esp.box:Remove()
        esp.name:Remove()
        esp.distance:Remove()
        esp.healthBar:Remove()
        esp.healthBarBg:Remove()
        esp.tracer:Remove()
    end
    espObjects = {}
end

local function setupESP()
    clearESP()

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            createESP(v.Character)
        end
    end

    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local isPlayer = false
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character == v then
                    isPlayer = true
                    break
                end
            end
            if not isPlayer then
                createESP(v)
            end
        end
    end

    connections.espUpdate = RunService.RenderStepped:Connect(updateESP)

    connections.playerAdded = Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(char)
            createESP(char)
        end)
    end)
end

local function installRemoteHook()
    if remoteHookInstalled then return end

    if hookmetamethod and getnamecallmethod then
        local wrapFunc = newcclosure or function(f) return f end

        originalNamecall = hookmetamethod(game, "__namecall", wrapFunc(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if settings.remoteSpy and (method == "FireServer" or method == "InvokeServer") then
                local remoteName = tostring(self)
                local argsStr = "NONE"
                if #args > 0 then
                    local argParts = {}
                    for i, arg in ipairs(args) do
                        local argType = typeof(arg)
                        local argValue = tostring(arg)
                        if argType == "table" then
                            pcall(function()
                                argValue = HttpService:JSONEncode(arg)
                            end)
                        end
                        table.insert(argParts, string.format("[%d]=%s (%s)", i, argValue, argType))
                    end
                    argsStr = table.concat(argParts, ", ")
                end

                addLog("RemoteSpy", string.format("%s | %s | Args: %s", remoteName, method, argsStr))

                if captureActive then
                    table.insert(capturedRemotes, {
                        name = remoteName,
                        method = method,
                        args = args,
                        timestamp = os.date("%H:%M:%S")
                    })
                end
            end

            return originalNamecall(self, ...)
        end))

        remoteHookInstalled = true
        addLog("RemoteSpy", "Hook installed (metamethod)")
        return
    end

    if hookfunction then
        addLog("RemoteSpy", "Trying hookfunction method (Xeno fallback)")

        local oldFireServer = Instance.new("RemoteEvent").FireServer
        local oldInvokeServer = Instance.new("RemoteFunction").InvokeServer

        local newFireServer = hookfunction(oldFireServer, function(self, ...)
            local args = {...}

            if settings.remoteSpy then
                local remoteName = tostring(self)
                local argsStr = "NONE"
                if #args > 0 then
                    local argParts = {}
                    for i, arg in ipairs(args) do
                        local argType = typeof(arg)
                        local argValue = tostring(arg)
                        if argType == "table" then
                            pcall(function()
                                argValue = HttpService:JSONEncode(arg)
                            end)
                        end
                        table.insert(argParts, string.format("[%d]=%s (%s)", i, argValue, argType))
                    end
                    argsStr = table.concat(argParts, ", ")
                end

                addLog("RemoteSpy", string.format("%s | FireServer | Args: %s", remoteName, argsStr))

                if captureActive then
                    table.insert(capturedRemotes, {
                        name = remoteName,
                        method = "FireServer",
                        args = args,
                        timestamp = os.date("%H:%M:%S")
                    })
                end
            end

            return oldFireServer(self, ...)
        end)

        remoteHookInstalled = true
        addLog("RemoteSpy", "Hook installed (hookfunction)")
        return
    end

    addLog("RemoteSpy", "ERROR: Exploit does not support hookmetamethod or hookfunction")
end

local function createWatermark()
    local watermarkGui = player:WaitForChild("PlayerGui"):FindFirstChild("BloodyBloxWatermark")
    if watermarkGui then
        watermarkGui:Destroy()
    end

    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "BloodyBloxWatermark"
    watermarkGui.DisplayOrder = 999
    watermarkGui.ResetOnSpawn = false
    watermarkGui.Parent = player:WaitForChild("PlayerGui")

    local watermark = Instance.new("Frame")
    watermark.Size = UDim2.new(0, 200, 0, 50)
    watermark.Position = UDim2.new(0.01, 0, 0.01, 0)
    watermark.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    watermark.BackgroundTransparency = 0.3
    watermark.BorderSizePixel = 0
    watermark.Parent = watermarkGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = watermark

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BloodyBlox Beta 0.0.3"
    title.TextColor3 = Color3.fromRGB(255, 50, 50)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = watermark

    local fps = Instance.new("TextLabel")
    fps.Size = UDim2.new(1, 0, 0.5, 0)
    fps.Position = UDim2.new(0, 0, 0.5, 0)
    fps.BackgroundTransparency = 1
    fps.Text = "FPS: 0"
    fps.TextColor3 = Color3.fromRGB(255, 255, 255)
    fps.TextSize = 14
    fps.Font = Enum.Font.Gotham
    fps.Parent = watermark

    task.spawn(function()
        local lastUpdate = tick()
        local frames = 0
        RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - lastUpdate >= 0.5 then
                local currentFPS = math.floor(frames / (tick() - lastUpdate))
                fps.Text = "FPS: " .. currentFPS
                frames = 0
                lastUpdate = tick()
            end
        end)
    end)

    local dragging = false
    local dragStart = nil
    local startPos = nil

    watermark.InputBegan:Connect(function(input)
        if settings.moveWatermark and input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = watermark.Position
        end
    end)

    watermark.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            watermark.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    watermark.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    watermarkGui.Enabled = settings.showWatermark
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloodyBloxUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "BloodyBlox Beta 0.0.3 | Muscle Legends"
title.TextColor3 = Color3.fromRGB(255, 50, 50)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0.5, -15)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

local dragging = false
local dragStart = nil
local startPos = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

topBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local tabFrame = Instance.new("ScrollingFrame")
tabFrame.Size = UDim2.new(0, 150, 1, -50)
tabFrame.Position = UDim2.new(0, 5, 0, 45)
tabFrame.BackgroundTransparency = 1
tabFrame.BorderSizePixel = 0
tabFrame.ScrollBarThickness = 4
tabFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
tabFrame.Parent = mainFrame

local tabList = Instance.new("UIListLayout")
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 5)
tabList.Parent = tabFrame

tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 10)
end)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -165, 1, -50)
contentFrame.Position = UDim2.new(0, 160, 0, 45)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
contentFrame.BackgroundTransparency = 0.3
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentFrame

local tabs = {}
local currentTab = nil

local function createTab(name)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, 0, 0, 35)
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.TextSize = 14
    tabButton.Font = Enum.Font.Gotham
    tabButton.Parent = tabFrame

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabButton

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -10, 1, -10)
    tabContent.Position = UDim2.new(0, 5, 0, 5)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 4
    tabContent.Visible = false
    tabContent.Parent = contentFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = tabContent

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    tabs[name] = {button = tabButton, content = tabContent}

    tabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(tabs) do
            tab.button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            tab.button.TextColor3 = Color3.fromRGB(200, 200, 200)
            tab.content.Visible = false
        end
        tabButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabContent.Visible = true
        currentTab = name
    end)

    return tabContent
end

local function createToggle(parent, text, settingKey, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -10, 0, 30)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local toggle = Instance.new("TextButton")
    toggle.Name = "ToggleButton"
    toggle.Size = UDim2.new(0, 50, 0, 20)
    toggle.Position = UDim2.new(1, -60, 0.5, -10)
    toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = settings[settingKey] and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = toggleFrame
    toggle:SetAttribute("SettingKey", settingKey)

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(1, 0, 1, 0)
    indicator.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    indicator.BackgroundTransparency = 0.7
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle

    local toggleButtonCorner = Instance.new("UICorner")
    toggleButtonCorner.CornerRadius = UDim.new(0, 4)
    toggleButtonCorner.Parent = toggle

    toggle.MouseButton1Click:Connect(function()
        settings[settingKey] = not settings[settingKey]
        toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        toggle.Text = settings[settingKey] and "ON" or "OFF"
        indicator.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        if callback then callback(settings[settingKey]) end
    end)

    -- Context Menu for Anti-Aim (Right Click)
    if settingKey == "antiAim" then
        local uis = game:GetService("UserInputService")

        toggle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local contextMenu = Instance.new("Frame")
            contextMenu.Size = UDim2.new(0, 200, 0, 150)
            contextMenu.Position = UDim2.new(0.5, -100, 0.5, -75)
            contextMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            contextMenu.BorderSizePixel = 2
            contextMenu.BorderColor3 = Color3.fromRGB(255, 50, 50)
            contextMenu.ZIndex = 999
            contextMenu.Parent = screenGui

            local contextCorner = Instance.new("UICorner")
            contextCorner.CornerRadius = UDim.new(0, 8)
            contextCorner.Parent = contextMenu

            local contextTitle = Instance.new("TextLabel")
            contextTitle.Size = UDim2.new(1, 0, 0, 30)
            contextTitle.BackgroundTransparency = 1
            contextTitle.Text = "Anti-Aim Settings"
            contextTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            contextTitle.TextSize = 16
            contextTitle.Font = Enum.Font.GothamBold
            contextTitle.Parent = contextMenu

            local speedLabel = Instance.new("TextLabel")
            speedLabel.Size = UDim2.new(1, -20, 0, 20)
            speedLabel.Position = UDim2.new(0, 10, 0, 40)
            speedLabel.BackgroundTransparency = 1
            speedLabel.Text = "Speed: " .. settings.antiAimSpeed
            speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            speedLabel.TextSize = 14
            speedLabel.Font = Enum.Font.Gotham
            speedLabel.TextXAlignment = Enum.TextXAlignment.Left
            speedLabel.Parent = contextMenu

            local speedSlider = Instance.new("TextBox")
            speedSlider.Size = UDim2.new(1, -20, 0, 25)
            speedSlider.Position = UDim2.new(0, 10, 0, 65)
            speedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            speedSlider.Text = tostring(settings.antiAimSpeed)
            speedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
            speedSlider.TextSize = 14
            speedSlider.Font = Enum.Font.Gotham
            speedSlider.ClearTextOnFocus = false
            speedSlider.Parent = contextMenu

            local speedCorner = Instance.new("UICorner")
            speedCorner.CornerRadius = UDim.new(0, 4)
            speedCorner.Parent = speedSlider

            speedSlider.FocusLost:Connect(function()
                local value = tonumber(speedSlider.Text) or 5
                value = math.clamp(value, 1, 10)
                settings.antiAimSpeed = value
                speedLabel.Text = "Speed: " .. value
                speedSlider.Text = tostring(value)
            end)

            local typeLabel = Instance.new("TextLabel")
            typeLabel.Size = UDim2.new(1, -20, 0, 20)
            typeLabel.Position = UDim2.new(0, 10, 0, 95)
            typeLabel.BackgroundTransparency = 1
            typeLabel.Text = "Type: " .. settings.antiAimType
            typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            typeLabel.TextSize = 14
            typeLabel.Font = Enum.Font.Gotham
            typeLabel.TextXAlignment = Enum.TextXAlignment.Left
            typeLabel.Parent = contextMenu

            local typeDropdown = Instance.new("TextButton")
            typeDropdown.Size = UDim2.new(1, -20, 0, 25)
            typeDropdown.Position = UDim2.new(0, 10, 0, 120)
            typeDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            typeDropdown.Text = settings.antiAimType .. " ▼"
            typeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
            typeDropdown.TextSize = 14
            typeDropdown.Font = Enum.Font.Gotham
            typeDropdown.Parent = contextMenu

            local typeCorner = Instance.new("UICorner")
            typeCorner.CornerRadius = UDim.new(0, 4)
            typeCorner.Parent = typeDropdown

            local types = {"Static", "Jitter", "Spin", "Random"}
            local currentIndex = 1
            for i, t in ipairs(types) do
                if t == settings.antiAimType then
                    currentIndex = i
                    break
                end
            end

            typeDropdown.MouseButton1Click:Connect(function()
                currentIndex = (currentIndex % #types) + 1
                settings.antiAimType = types[currentIndex]
                typeDropdown.Text = settings.antiAimType .. " ▼"
                typeLabel.Text = "Type: " .. settings.antiAimType
            end)

            local closeButton = Instance.new("TextButton")
            closeButton.Size = UDim2.new(0, 20, 0, 20)
            closeButton.Position = UDim2.new(1, -25, 0, 5)
            closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            closeButton.Text = "X"
            closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeButton.TextSize = 14
            closeButton.Font = Enum.Font.GothamBold
            closeButton.Parent = contextMenu

            local closeCorner = Instance.new("UICorner")
            closeCorner.CornerRadius = UDim.new(0, 4)
            closeCorner.Parent = closeButton

            closeButton.MouseButton1Click:Connect(function()
                contextMenu:Destroy()
            end)
            end -- closes if input.UserInputType == MouseButton2
        end) -- closes toggle.InputBegan:Connect
    end -- closes if settingKey == "antiAim"

    return toggleFrame
end

local function createSlider(parent, text, settingKey, min, max, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -10, 0, 50)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = parent

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. settings[settingKey]
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame

    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 6)
    sliderBar.Position = UDim2.new(0, 10, 0, 30)
    sliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = sliderFrame

    local sliderBarCorner = Instance.new("UICorner")
    sliderBarCorner.CornerRadius = UDim.new(0, 3)
    sliderBarCorner.Parent = sliderBar

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((settings[settingKey] - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 3)
    sliderFillCorner.Parent = sliderFill

    local dragging = false

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation().X
            local barPos = sliderBar.AbsolutePosition.X
            local barSize = sliderBar.AbsoluteSize.X
            local percent = math.clamp((mousePos - barPos) / barSize, 0, 1)
            local value = math.floor(min + (max - min) * percent)
            settings[settingKey] = value
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            label.Text = text .. ": " .. value
            if callback then callback(value) end
        end
    end)

    return sliderFrame
end

local function createDropdown(parent, text, settingKey, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -10, 0, 30)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Parent = parent

    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdownFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = dropdownFrame

    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0.45, 0, 0.8, 0)
    dropdown.Position = UDim2.new(0.52, 0, 0.1, 0)
    dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdown.BorderSizePixel = 0
    dropdown.Text = settings[settingKey]
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.TextSize = 12
    dropdown.Font = Enum.Font.Gotham
    dropdown.Parent = dropdownFrame

    local dropdownButtonCorner = Instance.new("UICorner")
    dropdownButtonCorner.CornerRadius = UDim.new(0, 4)
    dropdownButtonCorner.Parent = dropdown

    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 25)
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    optionsFrame.BorderSizePixel = 0
    optionsFrame.Visible = false
    optionsFrame.ZIndex = 10
    optionsFrame.Parent = dropdownFrame

    local optionsCorner = Instance.new("UICorner")
    optionsCorner.CornerRadius = UDim.new(0, 4)
    optionsCorner.Parent = optionsFrame

    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Padding = UDim.new(0, 2)
    optionsLayout.Parent = optionsFrame

    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 23)
        optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.TextSize = 12
        optionButton.Font = Enum.Font.Gotham
        optionButton.ZIndex = 11
        optionButton.Parent = optionsFrame

        optionButton.MouseButton1Click:Connect(function()
            settings[settingKey] = option
            dropdown.Text = option
            optionsFrame.Visible = false
            if callback then callback(option) end
        end)
    end

    dropdown.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible
    end)

    return dropdownFrame
end

local function createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

local function createTextBox(parent, text, settingKey, callback)
    local textboxFrame = Instance.new("Frame")
    textboxFrame.Size = UDim2.new(1, -10, 0, 60)
    textboxFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    textboxFrame.BorderSizePixel = 0
    textboxFrame.Parent = parent

    local textboxCorner = Instance.new("UICorner")
    textboxCorner.CornerRadius = UDim.new(0, 6)
    textboxCorner.Parent = textboxFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = textboxFrame

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, -20, 0, 25)
    textbox.Position = UDim2.new(0, 10, 0, 30)
    textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    textbox.BorderSizePixel = 0
    textbox.Text = tostring(settings[settingKey])
    textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textbox.TextSize = 14
    textbox.Font = Enum.Font.Gotham
    textbox.ClearTextOnFocus = false
    textbox.Parent = textboxFrame

    local textboxInputCorner = Instance.new("UICorner")
    textboxInputCorner.CornerRadius = UDim.new(0, 4)
    textboxInputCorner.Parent = textbox

    textbox.FocusLost:Connect(function()
        local value = tonumber(textbox.Text) or textbox.Text
        settings[settingKey] = value
        if callback then callback(value) end
    end)

    return textboxFrame
end

local farmTab = createTab("Farm")
createToggle(farmTab, "Fast Weight", "fastWeight")
createToggle(farmTab, "Auto Weight", "autoWeight")
createToggle(farmTab, "Durability Farm", "durabilityFarm")
createToggle(farmTab, "Auto Durability", "autoDurability")
createToggle(farmTab, "Auto Rebirth", "autoRebirth")

local combatTab = createTab("Combat")
createToggle(combatTab, "Anti-Aim", "antiAim")
createSlider(combatTab, "Anti-Aim Speed", "antiAimSpeed", 1, 10)
createDropdown(combatTab, "Anti-Aim Type", "antiAimType", {"Static", "Jitter", "Spin", "Random"})
createToggle(combatTab, "Kill Aura", "killAura", function(enabled)
    if enabled then
        cacheRemotes({"punch", "attack", "hit", "combat"}, cachedAttackRemotes)
    end
end)
createSlider(combatTab, "Kill Aura Range", "killAuraRange", 5, 50)
createToggle(combatTab, "Fast Hits", "fastHits")
createToggle(combatTab, "Bad Aura Farm", "badAuraFarm", function(enabled)
    if enabled then
        cacheRemotes({"punch", "attack", "hit", "combat"}, cachedAttackRemotes)
    end
end)
createSlider(combatTab, "Bad Aura Interval", "badAuraInterval", 1, 60)

local analyzerTab = createTab("Analyzer")
createToggle(analyzerTab, "Remote Spy", "remoteSpy", function(enabled)
    if enabled then
        installRemoteHook()
    end
end)
createButton(analyzerTab, "1. Full Remote Inventory", function()
    addLog("Analyzer", "=== REMOTE API INVENTORY ===")
    addLog("Analyzer", "Scanning client-accessible surfaces...")

    local remoteData = {}
    local locations = {
        {name = "ReplicatedStorage", container = ReplicatedStorage},
        {name = "Workspace", container = Workspace},
        {name = "PlayerGui", container = player:WaitForChild("PlayerGui")},
        {name = "Backpack", container = player.Backpack},
    }

    if character then
        table.insert(locations, {name = "Character", container = character})
    end

    for _, location in ipairs(locations) do
        local count = 0
        for _, obj in pairs(location.container:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local path = obj:GetFullName()
                local remoteType = obj:IsA("RemoteEvent") and "Event" or "Function"

                table.insert(remoteData, {
                    name = obj.Name,
                    path = path,
                    type = remoteType,
                    location = location.name
                })

                addLog("Analyzer", string.format("[%s] %s | Type: %s", location.name, path, remoteType))
                count = count + 1
            end
        end
        addLog("Analyzer", string.format("%s: %d remotes found", location.name, count))
    end

    _G.BloodyBloxRemoteInventory = remoteData
    addLog("Analyzer", string.format("=== TOTAL: %d remotes stored in _G.BloodyBloxRemoteInventory ===", #remoteData))
    addLog("Analyzer", "Use '2. Classify Remotes' to analyze findings")
end)
createButton(analyzerTab, "2. Classify Remotes", function()
    local inventory = _G.BloodyBloxRemoteInventory
    if not inventory or #inventory == 0 then
        addLog("Analyzer", "ERROR: No inventory found - run '1. Full Remote Inventory' first")
        return
    end

    addLog("Analyzer", "=== REMOTE CLASSIFICATION ===")

    local categories = {
        combat = {"punch", "hit", "attack", "damage", "kill", "fight", "combat"},
        weight = {"weight", "lift", "strength", "muscle"},
        durability = {"pushup", "situp", "handstand", "durability", "defense", "endurance"},
        rebirth = {"rebirth", "prestige", "reset", "ascend"},
        admin = {"admin", "mod", "kick", "ban", "teleport", "command"},
        stats = {"stat", "level", "xp", "exp", "point"},
        shop = {"buy", "purchase", "shop", "store", "sell"},
        social = {"friend", "chat", "message", "party", "trade"}
    }

    local classified = {}
    for category, keywords in pairs(categories) do
        classified[category] = {}
    end
    classified.unknown = {}

    for _, remote in ipairs(inventory) do
        local nameLower = remote.name:lower()
        local pathLower = remote.path:lower()
        local matched = false

        for category, keywords in pairs(categories) do
            for _, keyword in ipairs(keywords) do
                if string.find(nameLower, keyword) or string.find(pathLower, keyword) then
                    table.insert(classified[category], remote)
                    matched = true
                    break
                end
            end
            if matched then break end
        end

        if not matched then
            table.insert(classified.unknown, remote)
        end
    end

    for category, remotes in pairs(classified) do
        if #remotes > 0 then
            addLog("Analyzer", string.format("--- %s (%d) ---", category:upper(), #remotes))
            for _, remote in ipairs(remotes) do
                addLog("Analyzer", string.format("  %s [%s]", remote.name, remote.type))
            end
        end
    end

    _G.BloodyBloxClassified = classified
    addLog("Analyzer", "=== Classification complete - stored in _G.BloodyBloxClassified ===")
    addLog("Analyzer", "Use '3. Test Remote (Manual)' to analyze specific remotes")
end)
createButton(analyzerTab, "3. Manual Remote Test", function()
    addLog("Analyzer", "=== MANUAL REMOTE TESTING MODE ===")
    addLog("Analyzer", "Instructions:")
    addLog("Analyzer", "1. Play normally - lift weight, rebirth, attack")
    addLog("Analyzer", "2. Watch for Remote calls in console (if any bypass Byfron)")
    addLog("Analyzer", "3. Copy logs and analyze patterns")
    addLog("Analyzer", "")
    addLog("Analyzer", "Looking for:")
    addLog("Analyzer", "- Remotes called during actions")
    addLog("Analyzer", "- Expected parameters")
    addLog("Analyzer", "- Server validation behavior")
    addLog("Analyzer", "- Cooldown timings")
    addLog("Analyzer", "")
    addLog("Analyzer", "IMPORTANT: Cannot hook RemoteEvent.FireServer due to Byfron")
    addLog("Analyzer", "Alternative: manual observation + controlled testing")
end)

createButton(analyzerTab, "4. Controlled Fuzzing Test", function()
    local classified = _G.BloodyBloxClassified
    if not classified then
        addLog("Analyzer", "ERROR: No classification found - run steps 1-2 first")
        return
    end

    addLog("Analyzer", "=== CONTROLLED FUZZING ===")
    addLog("Analyzer", "WARNING: This will test Remotes with various payloads")
    addLog("Analyzer", "Limit: 5 requests per Remote to avoid rate limiting")

    local testPayloads = {
        {},                              -- no args
        {999},                          -- large number
        {true},                         -- boolean
        {"bypass"},                     -- string
        {player},                       -- player instance
        {nil, 999},                     -- nil + number
    }

    local testCategories = {"weight", "durability", "combat"}
    local testedCount = 0

    for _, category in ipairs(testCategories) do
        if classified[category] and #classified[category] > 0 then
            addLog("Analyzer", string.format("--- Testing %s remotes ---", category:upper()))

            for _, remote in ipairs(classified[category]) do
                if testedCount >= 15 then
                    addLog("Analyzer", "Test limit reached (15 remotes) - stopping")
                    return
                end

                local obj = game:GetService("ReplicatedStorage"):FindFirstChild(remote.name, true)
                if not obj then
                    obj = Workspace:FindFirstChild(remote.name, true)
                end

                if obj and obj:IsA("RemoteEvent") then
                    addLog("Analyzer", string.format("Testing: %s", remote.name))

                    for i, payload in ipairs(testPayloads) do
                        local success, err = pcall(function()
                            obj:FireServer(unpack(payload))
                        end)

                        if success then
                            addLog("Analyzer", string.format("  Payload %d: SENT", i))
                        else
                            addLog("Analyzer", string.format("  Payload %d: BLOCKED - %s", i, tostring(err)))
                        end

                        task.wait(0.2)
                    end

                    testedCount = testedCount + 1
                    task.wait(1)
                end
            end
        end
    end

    addLog("Analyzer", string.format("=== Fuzzing complete - tested %d remotes ===", testedCount))
    addLog("Analyzer", "Analyze logs for unexpected SUCCESS responses")
end)

createButton(analyzerTab, "5. Race Condition Test", function()
    local classified = _G.BloodyBloxClassified
    if not classified or not classified.weight or #classified.weight == 0 then
        addLog("Analyzer", "ERROR: No weight remotes found - run steps 1-2 first")
        return
    end

    addLog("Analyzer", "=== RACE CONDITION TEST ===")
    addLog("Analyzer", "Testing parallel requests for weight remotes...")

    local weightRemote = classified.weight[1]
    local obj = game:GetService("ReplicatedStorage"):FindFirstChild(weightRemote.name, true)

    if not obj then
        obj = Workspace:FindFirstChild(weightRemote.name, true)
    end

    if not obj or not obj:IsA("RemoteEvent") then
        addLog("Analyzer", "ERROR: Remote object not found or not accessible")
        return
    end

    addLog("Analyzer", string.format("Target: %s", weightRemote.name))
    addLog("Analyzer", "Spawning 10 parallel requests...")

    local startTime = tick()
    for i = 1, 10 do
        task.spawn(function()
            pcall(function()
                obj:FireServer()
            end)
            addLog("Analyzer", string.format("Request %d sent at %.3fs", i, tick() - startTime))
        end)
    end

    task.wait(2)
    addLog("Analyzer", "Race condition test complete")
    addLog("Analyzer", "If server processed multiple requests simultaneously - possible vulnerability")
    addLog("Analyzer", "Check game stats to see if Strength increased more than expected")
end)

createButton(analyzerTab, "6. State Desync Test", function()
    addLog("Analyzer", "=== STATE DESYNC TEST ===")
    addLog("Analyzer", "Testing Remote calls during abnormal states...")

    local classified = _G.BloodyBloxClassified
    if not classified then
        addLog("Analyzer", "ERROR: Run steps 1-2 first")
        return
    end

    local testRemote = nil
    if classified.weight and #classified.weight > 0 then
        testRemote = classified.weight[1]
    elseif classified.combat and #classified.combat > 0 then
        testRemote = classified.combat[1]
    end

    if not testRemote then
        addLog("Analyzer", "ERROR: No suitable remote found for testing")
        return
    end

    local obj = game:GetService("ReplicatedStorage"):FindFirstChild(testRemote.name, true)
    if not obj or not obj:IsA("RemoteEvent") then
        addLog("Analyzer", "ERROR: Remote not accessible")
        return
    end

    addLog("Analyzer", string.format("Target: %s", testRemote.name))

    -- Test 1: Call while Character is nil
    addLog("Analyzer", "Test 1: Calling with Character reference cleared...")
    local originalChar = character
    character = nil
    pcall(function()
        obj:FireServer()
    end)
    character = originalChar
    task.wait(0.5)

    -- Test 2: Call while Humanoid.Health = 0
    if humanoid then
        addLog("Analyzer", "Test 2: Calling while Humanoid.Health = 0...")
        local originalHealth = humanoid.Health
        humanoid.Health = 0
        task.wait(0.1)
        pcall(function()
            obj:FireServer()
        end)
        humanoid.Health = originalHealth
        task.wait(0.5)
    end

    -- Test 3: Call during rapid position change
    if rootPart then
        addLog("Analyzer", "Test 3: Calling during rapid teleport...")
        local originalPos = rootPart.CFrame
        rootPart.CFrame = originalPos + Vector3.new(0, 1000, 0)
        pcall(function()
            obj:FireServer()
        end)
        task.wait(0.1)
        rootPart.CFrame = originalPos
        task.wait(0.5)
    end

    addLog("Analyzer", "=== State desync test complete ===")
    addLog("Analyzer", "Check game state for unexpected results")
    addLog("Analyzer", "If any test triggered server action - possible vulnerability")
end)
createButton(analyzerTab, "Save Profile", function()
    if #capturedRemotes == 0 then
        addLog("Analyzer", "No remotes captured")
        return
    end
    local profile = HttpService:JSONEncode(capturedRemotes)
    writefile("bloodyblox_capture.json", profile)
    addLog("Analyzer", "Saved " .. #capturedRemotes .. " remotes")
    captureActive = false
end)

-- Specialized scans for AutoRebirth development
createButton(analyzerTab, "Scan Rebirth Triggers", function()
    addLog("Analyzer", "=== REBIRTH TRIGGER SCAN ===")

    local found = {}

    -- Scan ProximityPrompts
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local name = obj.Name:lower()
            local parent = obj.Parent and obj.Parent.Name or "unknown"
            if name:find("rebirth") or name:find("prestige") or name:find("reset") or parent:lower():find("rebirth") then
                table.insert(found, {type = "ProximityPrompt", path = obj:GetFullName(), name = obj.Name})
                addLog("Analyzer", "[ProximityPrompt] " .. obj:GetFullName())
            end
        end
    end

    -- Scan ClickDetectors
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent and obj.Parent.Name or "unknown"
            if parent:lower():find("rebirth") or parent:lower():find("prestige") then
                table.insert(found, {type = "ClickDetector", path = obj:GetFullName(), parent = parent})
                addLog("Analyzer", "[ClickDetector] " .. obj:GetFullName())
            end
        end
    end

    -- Scan RemoteEvents
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("rebirth") or name:find("prestige") then
                table.insert(found, {type = obj.ClassName, path = obj:GetFullName(), name = obj.Name})
                addLog("Analyzer", "[" .. obj.ClassName .. "] " .. obj:GetFullName())
            end
        end
    end

    _G.BloodyBloxRebirthTriggers = found
    addLog("Analyzer", string.format("=== FOUND %d REBIRTH TRIGGERS ===", #found))
    addLog("Analyzer", "Now: Turn ON Remote Spy, manually do rebirth, check Logs")
end)

createButton(analyzerTab, "Scan Attack Remotes", function()
    addLog("Analyzer", "=== ATTACK REMOTE SCAN ===")

    local found = {}
    local keywords = {"punch", "hit", "attack", "damage", "combat", "fight", "strike"}

    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            for _, keyword in ipairs(keywords) do
                if name:find(keyword) then
                    table.insert(found, {type = obj.ClassName, path = obj:GetFullName(), name = obj.Name})
                    addLog("Analyzer", "[" .. obj.ClassName .. "] " .. obj:GetFullName())
                    break
                end
            end
        end
    end

    _G.BloodyBloxAttackRemotes = found
    addLog("Analyzer", string.format("=== FOUND %d ATTACK REMOTES ===", #found))
    addLog("Analyzer", "Now: Turn ON Remote Spy, manually attack, check Logs")
end)

createButton(analyzerTab, "Scan Weight/Dura Remotes", function()
    addLog("Analyzer", "=== WEIGHT/DURABILITY REMOTE SCAN ===")

    local found = {weight = {}, durability = {}}

    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("weight") or name:find("lift") or name:find("strength") then
                table.insert(found.weight, {type = obj.ClassName, path = obj:GetFullName(), name = obj.Name})
                addLog("Analyzer", "[WEIGHT] " .. obj:GetFullName())
            end
            if name:find("durability") or name:find("defense") or name:find("endurance") then
                table.insert(found.durability, {type = obj.ClassName, path = obj:GetFullName(), name = obj.Name})
                addLog("Analyzer", "[DURA] " .. obj:GetFullName())
            end
        end
    end

    _G.BloodyBloxWeightDuraRemotes = found
    addLog("Analyzer", string.format("=== FOUND %d WEIGHT + %d DURA REMOTES ===", #found.weight, #found.durability))
    addLog("Analyzer", "Now: Turn ON Remote Spy, manually lift/train, check Logs")
end)

local miscTab = createTab("Misc")
createToggle(miscTab, "Walk With Dumbbell", "walkWithDumbbell")
createSlider(miscTab, "Walk Speed", "walkSpeed", 16, 100)
createToggle(miscTab, "Fast Strafe", "fastStrafe")
createToggle(miscTab, "Anti Ragdoll", "antiRagdoll")
createToggle(miscTab, "Air Strafe", "airStrafe")
createSlider(miscTab, "Air Strafe Speed", "airStrafeSpeed", 10, 100)

local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 0, 300)
playerListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
playerListFrame.BorderSizePixel = 0
playerListFrame.Parent = miscTab

local playerListCorner = Instance.new("UICorner")
playerListCorner.CornerRadius = UDim.new(0, 6)
playerListCorner.Parent = playerListFrame

local playerListTitle = Instance.new("TextLabel")
playerListTitle.Size = UDim2.new(1, 0, 0, 25)
playerListTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerListTitle.BorderSizePixel = 0
playerListTitle.Text = "Players on Server (Click to Kick)"
playerListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
playerListTitle.TextSize = 14
playerListTitle.Font = Enum.Font.GothamBold
playerListTitle.Parent = playerListFrame

local playerListContainer = Instance.new("ScrollingFrame")
playerListContainer.Size = UDim2.new(1, 0, 1, -25)
playerListContainer.Position = UDim2.new(0, 0, 0, 25)
playerListContainer.BackgroundTransparency = 1
playerListContainer.BorderSizePixel = 0
playerListContainer.ScrollBarThickness = 4
playerListContainer.Parent = playerListFrame

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Padding = UDim.new(0, 2)
playerListLayout.Parent = playerListContainer

local function refreshPlayerList()
    for _, child in pairs(playerListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local playerFrame = Instance.new("Frame")
            playerFrame.Size = UDim2.new(1, -10, 0, 30)
            playerFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            playerFrame.BorderSizePixel = 0
            playerFrame.Parent = playerListContainer

            local playerFrameCorner = Instance.new("UICorner")
            playerFrameCorner.CornerRadius = UDim.new(0, 4)
            playerFrameCorner.Parent = playerFrame

            local playerName = Instance.new("TextLabel")
            playerName.Size = UDim2.new(0.7, 0, 1, 0)
            playerName.Position = UDim2.new(0, 5, 0, 0)
            playerName.BackgroundTransparency = 1
            playerName.Text = targetPlayer.Name
            playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerName.TextSize = 14
            playerName.Font = Enum.Font.Gotham
            playerName.TextXAlignment = Enum.TextXAlignment.Left
            playerName.Parent = playerFrame

            local kickButton = Instance.new("TextButton")
            kickButton.Size = UDim2.new(0.25, 0, 0.8, 0)
            kickButton.Position = UDim2.new(0.72, 0, 0.1, 0)
            kickButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            kickButton.BorderSizePixel = 0
            kickButton.Text = "KICK"
            kickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            kickButton.TextSize = 12
            kickButton.Font = Enum.Font.GothamBold
            kickButton.Parent = playerFrame

            local kickCorner = Instance.new("UICorner")
            kickCorner.CornerRadius = UDim.new(0, 4)
            kickCorner.Parent = kickButton

            kickButton.MouseButton1Click:Connect(function()
                if targetPlayer and targetPlayer.Parent then
                    targetPlayer:Kick("Kicked by BloodyBlox")
                    addLog("PlayerKick", "Kicked: " .. targetPlayer.Name)
                    task.wait(0.5)
                    refreshPlayerList()
                end
            end)
        end
    end

    playerListContainer.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y + 10)
end

createButton(miscTab, "Refresh Player List", refreshPlayerList)
refreshPlayerList()

local visualTab = createTab("Visual")
createToggle(visualTab, "ESP", "espEnabled", function(enabled)
    if enabled then
        setupESP()
    else
        if connections.espUpdate then connections.espUpdate:Disconnect() end
        if connections.playerAdded then connections.playerAdded:Disconnect() end
        clearESP()
    end
end)
createToggle(visualTab, "Boxes", "espBoxes")
createToggle(visualTab, "Names", "espNames")
createToggle(visualTab, "Distance", "espDistance")
createToggle(visualTab, "Health", "espHealth")
createToggle(visualTab, "Tracers", "espTracers")
createToggle(visualTab, "Team Check", "espTeamCheck")
createToggle(visualTab, "Fullbright", "fullbright", function(enabled)
    if enabled then
        originalLightingSettings = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient
        }
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        for k, v in pairs(originalLightingSettings) do
            Lighting[k] = v
        end
    end
end)

local function getFlySpeed(sliderValue)
    -- x2 multiplier: 1→2, 10→20, 20→40, 50→100
    -- 1-10: +2 b/s (1→2, 10→20)
    -- 11-15: +4 b/s (11→24, 15→40)
    -- 16-19: +10 b/s (16→50, 19→80)
    -- 20: 100 b/s
    if sliderValue <= 10 then
        return sliderValue * 2
    elseif sliderValue <= 15 then
        return 20 + (sliderValue - 10) * 4
    elseif sliderValue <= 19 then
        return 40 + (sliderValue - 15) * 10
    else
        return 100
    end
end

local playerTab = createTab("Player")
createToggle(playerTab, "Fly", "fly", function(enabled)
    if enabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Parent = rootPart

        connections.flyLoop = RunService.RenderStepped:Connect(function()
            if not settings.fly then return end

            local camera = workspace.CurrentCamera
            local direction = Vector3.new(0, 0, 0)
            local actualSpeed = getFlySpeed(settings.flySpeed)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + (camera.CFrame.LookVector * actualSpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - (camera.CFrame.LookVector * actualSpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - (camera.CFrame.RightVector * actualSpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + (camera.CFrame.RightVector * actualSpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, actualSpeed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, actualSpeed, 0)
            end

            bodyVelocity.Velocity = direction
        end)
    else
        if connections.flyLoop then connections.flyLoop:Disconnect() end
        if rootPart:FindFirstChild("BodyVelocity") then
            rootPart:FindFirstChild("BodyVelocity"):Destroy()
        end
    end
end)
createSlider(playerTab, "Fly Speed", "flySpeed", 1, 20)
createToggle(playerTab, "Noclip", "noclip", function(enabled)
    if enabled then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCanCollide[part] = part.CanCollide
            end
        end
        connections.noclipLoop = RunService.Stepped:Connect(function()
            if not settings.noclip then return end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if connections.noclipLoop then connections.noclipLoop:Disconnect() end
        for part, value in pairs(originalCanCollide) do
            if part and part.Parent then
                part.CanCollide = value
            end
        end
        originalCanCollide = {}
    end
end)
createToggle(playerTab, "Infinite Jump", "infiniteJump")
createToggle(playerTab, "God Mode", "godMode", function(enabled)
    if enabled then
        godModeActive = true
        connections.godModeLoop = RunService.RenderStepped:Connect(function()
            if not godModeActive or not humanoid or humanoid.Health <= 0 then return end
            humanoid.Health = humanoid.MaxHealth
        end)

        connections.godModeDied = humanoid.Died:Connect(function()
            if godModeActive then
                task.wait(0.1)
                character = player.Character
                if character then
                    humanoid = character:WaitForChild("Humanoid")
                    rootPart = character:WaitForChild("HumanoidRootPart")
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)

        connections.godModeCharAdded = player.CharacterAdded:Connect(function(newChar)
            if godModeActive then
                character = newChar
                humanoid = newChar:WaitForChild("Humanoid")
                rootPart = newChar:WaitForChild("HumanoidRootPart")
                task.wait(0.1)
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    else
        godModeActive = false
        if connections.godModeLoop then connections.godModeLoop:Disconnect() end
        if connections.godModeDied then connections.godModeDied:Disconnect() end
        if connections.godModeCharAdded then connections.godModeCharAdded:Disconnect() end
    end
end)

local teleportTab = createTab("Teleport")
local teleportList = Instance.new("Frame")
teleportList.Size = UDim2.new(1, -10, 0, 300)
teleportList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
teleportList.BorderSizePixel = 0
teleportList.Parent = teleportTab

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 6)
teleportCorner.Parent = teleportList

local teleportListLayout = Instance.new("UIListLayout")
teleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportListLayout.Padding = UDim.new(0, 5)
teleportListLayout.Parent = teleportList

local function refreshTeleportList()
    for _, child in pairs(teleportList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for i, point in ipairs(teleportPoints) do
        local pointFrame = Instance.new("Frame")
        pointFrame.Size = UDim2.new(1, -10, 0, 30)
        pointFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        pointFrame.BorderSizePixel = 0
        pointFrame.Parent = teleportList

        local pointCorner = Instance.new("UICorner")
        pointCorner.CornerRadius = UDim.new(0, 4)
        pointCorner.Parent = pointFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = point.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = pointFrame

        local tpButton = Instance.new("TextButton")
        tpButton.Size = UDim2.new(0.25, 0, 0.8, 0)
        tpButton.Position = UDim2.new(0.45, 0, 0.1, 0)
        tpButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        tpButton.BorderSizePixel = 0
        tpButton.Text = "TP"
        tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpButton.TextSize = 12
        tpButton.Font = Enum.Font.GothamBold
        tpButton.Parent = pointFrame

        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 4)
        tpCorner.Parent = tpButton

        tpButton.MouseButton1Click:Connect(function()
            rootPart.CFrame = CFrame.new(point.position)
            addLog("Teleport", "Teleported to: " .. point.name)
        end)

        local renameButton = Instance.new("TextButton")
        renameButton.Size = UDim2.new(0.2, 0, 0.8, 0)
        renameButton.Position = UDim2.new(0.5, 0, 0.1, 0)
        renameButton.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
        renameButton.BorderSizePixel = 0
        renameButton.Text = "Rename"
        renameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        renameButton.TextSize = 11
        renameButton.Font = Enum.Font.GothamBold
        renameButton.Parent = pointFrame

        local renameCorner = Instance.new("UICorner")
        renameCorner.CornerRadius = UDim.new(0, 4)
        renameCorner.Parent = renameButton

        renameButton.MouseButton1Click:Connect(function()
            local renameFrame = Instance.new("Frame")
            renameFrame.Size = UDim2.new(0, 300, 0, 100)
            renameFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
            renameFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            renameFrame.BorderSizePixel = 2
            renameFrame.BorderColor3 = Color3.fromRGB(255, 150, 50)
            renameFrame.ZIndex = 999
            renameFrame.Parent = screenGui

            local renameFrameCorner = Instance.new("UICorner")
            renameFrameCorner.CornerRadius = UDim.new(0, 8)
            renameFrameCorner.Parent = renameFrame

            local renameTitle = Instance.new("TextLabel")
            renameTitle.Size = UDim2.new(1, 0, 0, 25)
            renameTitle.BackgroundTransparency = 1
            renameTitle.Text = "Rename Teleport Point"
            renameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            renameTitle.TextSize = 14
            renameTitle.Font = Enum.Font.GothamBold
            renameTitle.Parent = renameFrame

            local renameInput = Instance.new("TextBox")
            renameInput.Size = UDim2.new(0.9, 0, 0, 30)
            renameInput.Position = UDim2.new(0.05, 0, 0, 35)
            renameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            renameInput.Text = point.name
            renameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
            renameInput.TextSize = 14
            renameInput.Font = Enum.Font.Gotham
            renameInput.ClearTextOnFocus = true
            renameInput.Parent = renameFrame

            local renameInputCorner = Instance.new("UICorner")
            renameInputCorner.CornerRadius = UDim.new(0, 4)
            renameInputCorner.Parent = renameInput

            local confirmButton = Instance.new("TextButton")
            confirmButton.Size = UDim2.new(0.4, 0, 0, 25)
            confirmButton.Position = UDim2.new(0.05, 0, 0, 70)
            confirmButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            confirmButton.Text = "Confirm"
            confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirmButton.TextSize = 12
            confirmButton.Font = Enum.Font.GothamBold
            confirmButton.Parent = renameFrame

            local confirmCorner = Instance.new("UICorner")
            confirmCorner.CornerRadius = UDim.new(0, 4)
            confirmCorner.Parent = confirmButton

            confirmButton.MouseButton1Click:Connect(function()
                local newName = renameInput.Text
                if newName and newName ~= "" then
                    point.name = newName
                    saveTeleportPoints()
                    refreshTeleportList()
                    addLog("Teleport", "Renamed to: " .. newName)
                end
                renameFrame:Destroy()
            end)

            local cancelButton = Instance.new("TextButton")
            cancelButton.Size = UDim2.new(0.4, 0, 0, 25)
            cancelButton.Position = UDim2.new(0.55, 0, 0, 70)
            cancelButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            cancelButton.Text = "Cancel"
            cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            cancelButton.TextSize = 12
            cancelButton.Font = Enum.Font.GothamBold
            cancelButton.Parent = renameFrame

            local cancelCorner = Instance.new("UICorner")
            cancelCorner.CornerRadius = UDim.new(0, 4)
            cancelCorner.Parent = cancelButton

            cancelButton.MouseButton1Click:Connect(function()
                renameFrame:Destroy()
            end)
        end)

        -- Adjust positions for 3 buttons layout
        tpButton.Size = UDim2.new(0.18, 0, 0.8, 0)
        tpButton.Position = UDim2.new(0.42, 0, 0.1, 0)
        renameButton.Size = UDim2.new(0.18, 0, 0.8, 0)
        renameButton.Position = UDim2.new(0.62, 0, 0.1, 0)

        local deleteButton = Instance.new("TextButton")
        deleteButton.Size = UDim2.new(0.18, 0, 0.8, 0)
        deleteButton.Position = UDim2.new(0.82, 0, 0.1, 0)
        deleteButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        deleteButton.BorderSizePixel = 0
        deleteButton.Text = "Delete"
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteButton.TextSize = 12
        deleteButton.Font = Enum.Font.GothamBold
        deleteButton.Parent = pointFrame

        local deleteCorner = Instance.new("UICorner")
        deleteCorner.CornerRadius = UDim.new(0, 4)
        deleteCorner.Parent = deleteButton

        deleteButton.MouseButton1Click:Connect(function()
            table.remove(teleportPoints, i)
            saveTeleportPoints()
            refreshTeleportList()
            addLog("Teleport", "Deleted: " .. point.name)
        end)
    end
end

createButton(teleportTab, "Save Current Position", function()
    local name = "Point_" .. (#teleportPoints + 1)
    table.insert(teleportPoints, {name = name, position = rootPart.Position})
    saveTeleportPoints()
    refreshTeleportList()
    addLog("Teleport", "Saved: " .. name)
end)

refreshTeleportList()

local configTab = createTab("Config")
createTextBox(configTab, "Config Name", "configName")
createButton(configTab, "Save Config", function()
    local name = settings.configName or "default"
    saveConfig(name)
end)
createButton(configTab, "Load Config", function()
    local name = settings.configName or "default"
    if loadConfig(name) then
        addLog("Config", "Config loaded successfully")
    else
        addLog("Config", "Config not found")
    end
end)
createButton(configTab, "Delete Config", function()
    local name = settings.configName or "default"
    deleteConfig(name)
end)

local logsTab = createTab("Logs")
local logsContainer = Instance.new("Frame")
logsContainer.Size = UDim2.new(1, -10, 0, 350)
logsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
logsContainer.BorderSizePixel = 0
logsContainer.Parent = logsTab

local logsCorner = Instance.new("UICorner")
logsCorner.CornerRadius = UDim.new(0, 6)
logsCorner.Parent = logsContainer

local logsListLayout = Instance.new("UIListLayout")
logsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
logsListLayout.Padding = UDim.new(0, 2)
logsListLayout.Parent = logsContainer

local function refreshLogs()
    for _, child in pairs(logsContainer:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for i, log in ipairs(logs) do
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(1, -10, 0, 20)
        logLabel.BackgroundTransparency = 1
        logLabel.Text = log
        logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        logLabel.TextSize = 12
        logLabel.Font = Enum.Font.Code
        logLabel.TextXAlignment = Enum.TextXAlignment.Left
        logLabel.Parent = logsContainer
    end
end

createButton(logsTab, "Refresh", refreshLogs)
createButton(logsTab, "Copy All", function()
    local allLogs = table.concat(logs, "\n")
    setclipboard(allLogs)
    addLog("Logs", "Copied " .. #logs .. " logs to clipboard")
end)

local settingsTab = createTab("Settings")
createToggle(settingsTab, "Show Watermark", "showWatermark", function(enabled)
    local watermarkGui = player:WaitForChild("PlayerGui"):FindFirstChild("BloodyBloxWatermark")
    if watermarkGui then
        watermarkGui.Enabled = enabled
    end
end)
createToggle(settingsTab, "Move Watermark", "moveWatermark")
createTextBox(settingsTab, "Menu Scale (0.5-3.0)", "menuScale", function(value)
    local scale = tonumber(value)
    if scale and scale >= 0.5 and scale <= 3.0 then
        mainFrame.Size = UDim2.new(0, 700 * scale, 0, 500 * scale)
        mainFrame.Position = UDim2.new(0.5, -350 * scale, 0.5, -250 * scale)
    end
end)
createButton(settingsTab, "Disable All", function()
    for k, v in pairs(settings) do
        if type(v) == "boolean" and k ~= "showWatermark" then
            settings[k] = false
        end
    end
    for _, conn in pairs(connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    connections = {}
    clearESP()
    addLog("Settings", "All functions disabled")
end)
createButton(settingsTab, "EXIT", function()
    for _, conn in pairs(connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    clearESP()
    screenGui:Destroy()
    local watermarkGui = player:WaitForChild("PlayerGui"):FindFirstChild("BloodyBloxWatermark")
    if watermarkGui then
        watermarkGui:Destroy()
    end
    _G.BloodyBloxLoaded = nil
    addLog("Settings", "BloodyBlox unloaded")
end)

tabs["Farm"].button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
tabs["Farm"].button.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs["Farm"].content.Visible = true
currentTab = "Farm"

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        screenGui.Enabled = not screenGui.Enabled
    end

    if input.KeyCode == Enum.KeyCode.Space and settings.infiniteJump then
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
            -- Force jump by manipulating velocity
            if rootPart then
                local currentVel = rootPart.Velocity
                rootPart.Velocity = Vector3.new(currentVel.X, 50, currentVel.Z)
            end
        end
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    originalWalkSpeed = humanoid.WalkSpeed
end)

connections.antiAim = RunService.RenderStepped:Connect(function()
    if not settings.antiAim or not rootPart then return end

    local speed = settings.antiAimSpeed
    local currentCFrame = rootPart.CFrame
    local currentVelocity = rootPart.Velocity

    local modes = {
        Static = function() return currentCFrame * CFrame.Angles(0, math.rad(speed * 10), 0) end,
        Jitter = function() return currentCFrame * CFrame.Angles(0, math.rad(speed * 10 * (math.random() > 0.5 and 1 or -1)), 0) end,
        Spin = function() return currentCFrame * CFrame.Angles(0, math.rad(tick() * speed * 100), 0) end,
        Random = function() return currentCFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0) end
    }

    local mode = modes[settings.antiAimType]
    if mode then
        rootPart.CFrame = mode()
        rootPart.Velocity = currentVelocity
    end
end)

connections.killAura = RunService.Heartbeat:Connect(function()
    if not settings.killAura then return end

    -- Direct remote call (from logs: ReplicatedStorage.rEvents.guiDamageEvent)
    local damageRemote = ReplicatedStorage:FindFirstChild("rEvents")
        and ReplicatedStorage.rEvents:FindFirstChild("guiDamageEvent")

    if not damageRemote then return end

    if tick() - lastPlayerCacheUpdate > 1 then
        cachedPlayers = Players:GetPlayers()
        lastPlayerCacheUpdate = tick()
    end

    for _, v in pairs(cachedPlayers) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local targetId = tostring(v.UserId)
            if not lastKillAuraFire[targetId] or tick() - lastKillAuraFire[targetId] > 0.5 then
                local distance = (rootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                if distance < settings.killAuraRange then
                    pcall(function()
                        damageRemote:FireServer(v.Character.HumanoidRootPart)
                    end)
                    lastKillAuraFire[targetId] = tick()
                    break
                end
            end
        end
    end
end)

connections.fastWeight = RunService.Heartbeat:Connect(function()
    if not settings.fastWeight then return end
    if tick() - lastFastWeightFire < 0.01 then return end

    local weightTool = character and character:FindFirstChild("Weight")

    if not weightTool then
        local backpackWeight = player.Backpack:FindFirstChild("Weight")
        if backpackWeight then
            humanoid:EquipTool(backpackWeight)
            task.wait(0.05)
            weightTool = character:FindFirstChild("Weight")
        end
    end

    if weightTool and weightTool:IsA("Tool") then
        if mouse1click then
            mouse1click()
        elseif mouse1press then
            mouse1press()
            task.wait(0.001)
            mouse1release()
        else
            weightTool:Activate()
        end
    end

    lastFastWeightFire = tick()
end)

connections.autoWeight = RunService.Heartbeat:Connect(function()
    if not settings.autoWeight then return end
    if tick() - lastAutoWeightAction < 0.5 then return end

    local weightTool = player.Backpack:FindFirstChild("Weight")
    if not weightTool then
        weightTool = character and character:FindFirstChild("Weight")
    end

    if weightTool and weightTool:IsA("Tool") then
        if weightTool.Parent == player.Backpack then
            humanoid:EquipTool(weightTool)
            task.wait(0.1)
        end
        weightTool:Activate()
    end

    lastAutoWeightAction = tick()
end)

connections.durabilityFarm = RunService.Heartbeat:Connect(function()
    if not settings.durabilityFarm then return end
    if tick() - lastDurabilityFire < 0.05 then return end

    for _, toolName in ipairs({"Pushups", "Situps", "Handstands"}) do
        local tool = character and character:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            tool:Activate()
            lastDurabilityFire = tick()
            break
        end
    end
end)

connections.autoDurability = RunService.Heartbeat:Connect(function()
    if not settings.autoDurability then return end
    if tick() - lastAutoDurabilityAction < 0.5 then return end

    for _, toolName in ipairs({"Pushups", "Situps", "Handstands"}) do
        local tool = player.Backpack:FindFirstChild(toolName)
        if not tool then
            tool = character and character:FindFirstChild(toolName)
        end

        if tool and tool:IsA("Tool") then
            if tool.Parent == player.Backpack then
                humanoid:EquipTool(tool)
                task.wait(0.1)
            end
            tool:Activate()
            lastAutoDurabilityAction = tick()
            break
        end
    end
end)

connections.autoRebirth = task.spawn(function()
    while task.wait(5) do
        if not settings.autoRebirth then continue end

        -- Direct RemoteFunction call (from logs: ReplicatedStorage.rEvents.rebirthRemote)
        local rebirthRemote = ReplicatedStorage:FindFirstChild("rEvents")
            and ReplicatedStorage.rEvents:FindFirstChild("rebirthRemote")

        if rebirthRemote and rebirthRemote:IsA("RemoteFunction") then
            local success, result = pcall(function()
                return rebirthRemote:InvokeServer()
            end)

            if success then
                if result == true or result == nil then
                    addLog("AutoRebirth", "Rebirth successful")
                    task.wait(2)
                else
                    addLog("AutoRebirth", "Rebirth failed: " .. tostring(result))
                end
            else
                addLog("AutoRebirth", "Error: " .. tostring(result))
            end
        else
            addLog("AutoRebirth", "ERROR: rebirthRemote not found in ReplicatedStorage.rEvents")
            task.wait(10)
        end
    end
end)

connections.badAuraFarm = RunService.Heartbeat:Connect(function()
    if not settings.badAuraFarm then return end
    if tick() - lastBadAuraFire < settings.badAuraInterval then return end

    if tick() - lastPlayerCacheUpdate > 1 then
        cachedPlayers = Players:GetPlayers()
        lastPlayerCacheUpdate = tick()
    end

    for _, v in pairs(cachedPlayers) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local rank = getPlayerAuraRank(v)
            if rank then
                local hasGoodAura = false
                for _, goodRank in ipairs(goodAuraRanks) do
                    if rank == goodRank then
                        hasGoodAura = true
                        break
                    end
                end

                if hasGoodAura and (rootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude < 100 then
                    rootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.05)

                    local punchTool = character and character:FindFirstChild("Punch")
                    if punchTool and punchTool:IsA("Tool") then
                        punchTool:Activate()
                    end

                    lastBadAuraFire = tick()
                    addLog("BadAura", "Attacking: " .. v.Name .. " [" .. rank .. "]")
                    break
                end
            end
        end
    end
end)

connections.walkWithDumbbell = RunService.Heartbeat:Connect(function()
    if not settings.walkWithDumbbell or not humanoid then return end
    humanoid.WalkSpeed = 50
end)

-- Walk With Dumbbell jump support (задача #6)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space and settings.walkWithDumbbell and humanoid then
        if rootPart and humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
            local currentVel = rootPart.Velocity
            rootPart.Velocity = Vector3.new(currentVel.X, 50, currentVel.Z)
        end
    end
end)

connections.fastStrafe = RunService.Heartbeat:Connect(function()
    if not settings.fastStrafe or not humanoid or not rootPart then return end

    -- Remove movement inertia by zeroing horizontal velocity when not moving
    if humanoid.MoveDirection.Magnitude == 0 then
        local currentVel = rootPart.Velocity
        rootPart.Velocity = Vector3.new(0, currentVel.Y, 0)
    end
end)

connections.antiRagdoll = RunService.Stepped:Connect(function()
    if not settings.antiRagdoll or not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end)

connections.airStrafe = RunService.RenderStepped:Connect(function()
    if not settings.airStrafe or not humanoid or not rootPart then return end
    if humanoid.FloorMaterial == Enum.Material.Air then
        local camera = workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end

        if direction.Magnitude > 0 then
            local currentVelocity = rootPart.Velocity
            local strafeForce = direction.Unit * 2.5  -- Increased from ~1 to 2.5
            local newHorizontalVelocity = Vector3.new(
                currentVelocity.X + strafeForce.X,
                0,
                currentVelocity.Z + strafeForce.Z
            )

            local maxSpeed = 100  -- Increased from airStrafeSpeed (30) to 100
            if newHorizontalVelocity.Magnitude > maxSpeed then
                newHorizontalVelocity = newHorizontalVelocity.Unit * maxSpeed
            end

            rootPart.Velocity = Vector3.new(
                newHorizontalVelocity.X,
                currentVelocity.Y,
                newHorizontalVelocity.Z
            )
        end
    end
end)

player.Idled:Connect(function()
    VirtualUser:ClickButton2(Vector2.new())
end)

setfpscap(999)

loadTeleportPoints()
createWatermark()

addLog("System", "BloodyBlox Beta 0.0.3 loaded")
addLog("System", "Press INSERT to toggle menu")
addLog("System", "Tool.Activated hook method - test with Monitor Weight Tool button")
