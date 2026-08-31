-- BloodyBlox v0.5.10

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
local CoreGui = game:GetService("CoreGui")
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
    local watermarkGui = CoreGui:FindFirstChild("BloodyBloxWatermark")
    if watermarkGui then
        watermarkGui:Destroy()
    end

    watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "BloodyBloxWatermark"
    watermarkGui.DisplayOrder = 999
    watermarkGui.ResetOnSpawn = false
    watermarkGui.Parent = CoreGui

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
screenGui.Parent = CoreGui

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

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0, 150, 1, -50)
tabFrame.Position = UDim2.new(0, 5, 0, 45)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local tabList = Instance.new("UIListLayout")
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 5)
tabList.Parent = tabFrame

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
    toggle.Size = UDim2.new(0, 50, 0, 20)
    toggle.Position = UDim2.new(1, -60, 0.5, -10)
    toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = settings[settingKey] and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = toggleFrame

    local toggleButtonCorner = Instance.new("UICorner")
    toggleButtonCorner.CornerRadius = UDim.new(0, 4)
    toggleButtonCorner.Parent = toggle

    toggle.MouseButton1Click:Connect(function()
        settings[settingKey] = not settings[settingKey]
        toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        toggle.Text = settings[settingKey] and "ON" or "OFF"
        if callback then callback(settings[settingKey]) end
    end)

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
createDropdown(combatTab, "Anti-Aim Type", "antiAimType", {"Static", "Jitter", "Spin", "Random", "Desync", "FakeYaw", "FakeLag", "Freestanding", "ManualAA", "EdgeAA"})
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
createButton(analyzerTab, "Scan Remotes", function()
    addLog("Analyzer", "Scanning ReplicatedStorage remotes...")
    local count = 0
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            addLog("Analyzer", "Found: " .. v:GetFullName())
            count = count + 1
        end
    end
    addLog("Analyzer", "Total remotes: " .. count)
end)
createButton(analyzerTab, "Scan NPCs", function()
    addLog("Analyzer", "Scanning Workspace NPCs...")
    local count = 0
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local isPlayer = false
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character == v then
                    isPlayer = true
                    break
                end
            end
            if not isPlayer then
                addLog("Analyzer", "NPC: " .. v.Name .. " | HP: " .. v.Humanoid.Health)
                count = count + 1
            end
        end
    end
    addLog("Analyzer", "Total NPCs: " .. count)
end)
createButton(analyzerTab, "Monitor Weight Tool (HOLD W)", function()
    addLog("Analyzer", "Monitoring Weight tool - equip it and lift!")

    local weightTool = player.Backpack:FindFirstChild("Weight") or (character and character:FindFirstChild("Weight"))
    if not weightTool then
        addLog("Analyzer", "ERROR: Weight tool not found")
        return
    end

    if weightTool.Parent == player.Backpack then
        humanoid:EquipTool(weightTool)
        task.wait(0.5)
    end

    weightToolActivatedConnection = weightTool.Activated:Connect(function()
        addLog("Analyzer", "Weight tool Activated event fired!")
    end)

    addLog("Analyzer", "Hook installed - now CLICK/HOLD W and check logs")
    addLog("Analyzer", "Use 'Stop Monitoring' button to disconnect hook")
end)
createButton(analyzerTab, "Stop Monitoring", function()
    if weightToolActivatedConnection then
        weightToolActivatedConnection:Disconnect()
        weightToolActivatedConnection = nil
        addLog("Analyzer", "Weight tool monitoring stopped")
    else
        addLog("Analyzer", "No monitoring active")
    end
end)
createButton(analyzerTab, "Scan Rebirth Objects", function()
    addLog("Analyzer", "Scanning Workspace for rebirth objects...")
    local clickCount = 0
    local promptCount = 0

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent
            if parent and (string.find(parent.Name:lower(), "rebirth") or string.find(parent.Name:lower(), "prestige") or string.find(parent.Name:lower(), "reset")) then
                addLog("Analyzer", "ClickDetector found: " .. parent:GetFullName())
                clickCount = clickCount + 1
            end
        elseif obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and (string.find(parent.Name:lower(), "rebirth") or string.find(parent.Name:lower(), "prestige") or string.find(parent.Name:lower(), "reset")) then
                addLog("Analyzer", "ProximityPrompt found: " .. parent:GetFullName())
                promptCount = promptCount + 1
            end
        end
    end

    addLog("Analyzer", string.format("Total: %d ClickDetectors, %d ProximityPrompts", clickCount, promptCount))

    if clickCount == 0 and promptCount == 0 then
        addLog("Analyzer", "WARNING: No rebirth objects found - game likely uses RemoteEvent")
        addLog("Analyzer", "Enable Remote Spy and rebirth manually to capture the Remote")
    end
end)
createButton(analyzerTab, "Test Remote Spy Hook", function()
    addLog("Analyzer", "Testing Remote Spy hook with fake RemoteEvent...")

    local testRemote = Instance.new("RemoteEvent")
    testRemote.Name = "TestRemoteEvent"
    testRemote.Parent = ReplicatedStorage

    pcall(function()
        testRemote:FireServer("test_arg1", 123, true, {key = "value"})
    end)

    task.wait(0.5)
    addLog("Analyzer", "Test RemoteEvent fired - check logs for [RemoteSpy] entry")
    addLog("Analyzer", "If NO [RemoteSpy] entry appeared - hookfunction is blocked by anti-cheat")

    testRemote:Destroy()
end)
createButton(analyzerTab, "Scan Tools", function()
    addLog("Analyzer", "Scanning player tools...")
    local count = 0
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            addLog("Analyzer", "Tool: " .. tool.Name)
            count = count + 1
        end
    end
    if character then
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                addLog("Analyzer", "Equipped: " .. tool.Name)
                count = count + 1
            end
        end
    end
    addLog("Analyzer", "Total tools: " .. count)
end)
createButton(analyzerTab, "Dump Character Offsets", function()
    if not character then
        addLog("Analyzer", "Character unavailable")
        return
    end
    addLog("Analyzer", "Character: " .. character.Name)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            addLog("Analyzer", string.format("%s: CFrame(%s)", part.Name, tostring(part.CFrame)))
        end
    end
end)
createButton(analyzerTab, "Capture Weight/Durability/Rebirth/Combat", function()
    captureActive = true
    capturedRemotes = {}
    addLog("Analyzer", "Capture started - perform actions manually")
end)
createButton(analyzerTab, "Cancel Capture", function()
    captureActive = false
    addLog("Analyzer", "Capture cancelled")
end)
createButton(analyzerTab, "Run Last Capture", function()
    if #capturedRemotes == 0 then
        addLog("Analyzer", "No capture profile loaded")
        return
    end
    for _, remote in ipairs(capturedRemotes) do
        local remoteObj = game:GetService(remote.path or "ReplicatedStorage")
        for _, part in pairs(remote.name:split(".")) do
            remoteObj = remoteObj:FindFirstChild(part)
            if not remoteObj then break end
        end
        if remoteObj then
            if remote.method == "FireServer" then
                remoteObj:FireServer(unpack(remote.args or {}))
            elseif remote.method == "InvokeServer" then
                remoteObj:InvokeServer(unpack(remote.args or {}))
            end
            addLog("Analyzer", "Replayed: " .. remote.name)
        end
    end
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
createToggle(visualTab, "ESP Boxes", "espBoxes")
createToggle(visualTab, "ESP Names", "espNames")
createToggle(visualTab, "ESP Distance", "espDistance")
createToggle(visualTab, "ESP Health", "espHealth")
createToggle(visualTab, "ESP Tracers", "espTracers")
createToggle(visualTab, "ESP Team Check", "espTeamCheck")
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

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + (camera.CFrame.LookVector * settings.flySpeed * 10)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - (camera.CFrame.LookVector * settings.flySpeed * 10)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - (camera.CFrame.RightVector * settings.flySpeed * 10)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + (camera.CFrame.RightVector * settings.flySpeed * 10)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.new(0, settings.flySpeed * 10, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                direction = direction - Vector3.new(0, settings.flySpeed * 10, 0)
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
createSlider(playerTab, "Fly Speed", "flySpeed", 1, 10)
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

        local deleteButton = Instance.new("TextButton")
        deleteButton.Size = UDim2.new(0.25, 0, 0.8, 0)
        deleteButton.Position = UDim2.new(0.72, 0, 0.1, 0)
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
    local watermarkGui = CoreGui:FindFirstChild("BloodyBloxWatermark")
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
    local watermarkGui = CoreGui:FindFirstChild("BloodyBloxWatermark")
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
        if humanoid.FloorMaterial == Enum.Material.Air or humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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
    local currentVelocity = rootPart.Velocity
    local position = rootPart.Position

    local modes = {
        Static = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(speed * 10), 0) end,
        Jitter = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(speed * 10 * (math.random() > 0.5 and 1 or -1)), 0) end,
        Spin = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(tick() * speed * 50), 0) end,
        Random = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0) end,
        Desync = function() return CFrame.new(position) * CFrame.Angles(0, math.sin(tick() * speed) * math.pi, 0) end,
        FakeYaw = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(180), 0) end,
        FakeLag = function()
            if math.floor(tick() * 2) % 2 == 0 then
                return CFrame.new(position) * CFrame.Angles(0, math.rad(speed * 36), 0)
            end
            return rootPart.CFrame
        end,
        Freestanding = function() return CFrame.new(position) * CFrame.Angles(0, math.cos(tick() * speed) * math.pi, 0) end,
        ManualAA = function() return CFrame.new(position) * CFrame.Angles(0, math.rad(speed * 20), 0) end,
        EdgeAA = function() return CFrame.new(position) * CFrame.Angles(0, math.sin(tick() * speed * 2) * math.pi / 2, 0) end
    }

    local mode = modes[settings.antiAimType]
    if mode then
        rootPart.CFrame = mode()
        rootPart.Velocity = currentVelocity
    end
end)

connections.killAura = RunService.Heartbeat:Connect(function()
    if not settings.killAura or #cachedAttackRemotes == 0 then return end

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
                    for _, remote in pairs(cachedAttackRemotes) do
                        pcall(function()
                            remote:FireServer(v.Character.HumanoidRootPart)
                        end)
                    end
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
    if weightTool and weightTool:IsA("Tool") then
        if mouse1click then
            mouse1click()
            addLog("FastWeight", "Mouse1Click fired")
        elseif mouse1press then
            mouse1press()
            task.wait(0.001)
            mouse1release()
            addLog("FastWeight", "Mouse1Press/Release fired")
        else
            weightTool:Activate()
            addLog("FastWeight", "Tool:Activate() fallback")
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

connections.autoRebirth = RunService.Heartbeat:Connect(function()
    if not settings.autoRebirth then return end
    if tick() - lastAutoRebirthFire < 5 then return end

    local playerGui = player:WaitForChild("PlayerGui")

    for _, gui in pairs(playerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = gui.Text and gui.Text:lower() or ""
            local name = gui.Name:lower()

            if string.find(text, "rebirth") or string.find(text, "prestige") or string.find(name, "rebirth") or string.find(name, "prestige") then
                if gui.Visible and gui.Parent and gui.Parent.Visible then
                    if firesignal then
                        firesignal(gui.MouseButton1Click)
                        addLog("AutoRebirth", "Fired signal on: " .. (gui.Text or gui.Name))
                    else
                        gui.MouseButton1Click:Fire()
                        addLog("AutoRebirth", "Fired event on: " .. (gui.Text or gui.Name))
                    end
                    lastAutoRebirthFire = tick()
                    return
                end
            end
        end
    end

    lastAutoRebirthFire = tick()
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
    if not settings.walkWithDumbbell then return end
    if humanoid then
        humanoid.WalkSpeed = settings.walkSpeed
    end
end)

connections.fastStrafe = RunService.Heartbeat:Connect(function()
    if not settings.fastStrafe or not humanoid then return end

    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local camera = workspace.CurrentCamera
        local cameraCFrame = CFrame.new(rootPart.Position, rootPart.Position + Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z))
        rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
    end
end)

connections.antiRagdoll = RunService.Stepped:Connect(function()
    if not settings.antiRagdoll or not humanoid then return end
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
end)

connections.airStrafe = RunService.RenderStepped:Connect(function()
    if not settings.airStrafe or not humanoid then return end
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
            local strafeForce = direction.Unit * settings.airStrafeSpeed
            local newHorizontalVelocity = Vector3.new(
                currentVelocity.X + strafeForce.X,
                0,
                currentVelocity.Z + strafeForce.Z
            )

            local maxSpeed = settings.airStrafeSpeed
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
