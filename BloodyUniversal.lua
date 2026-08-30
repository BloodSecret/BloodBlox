-- BloodyBlox Universal v1.0.0
-- Cross-game exploit framework (client-side only)
-- Author: BloodSecret
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

local BloodyUniversal = {}
BloodyUniversal.Version = "1.0.0"
BloodyUniversal.Enabled = {}
BloodyUniversal.Connections = {}
BloodyUniversal.UI = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Utility Functions
local function Log(message, category)
    category = category or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s][%s] %s", timestamp, category, message)

    if not BloodyUniversal.Logs then
        BloodyUniversal.Logs = {}
    end

    table.insert(BloodyUniversal.Logs, 1, entry)

    if #BloodyUniversal.Logs > 30 then
        table.remove(BloodyUniversal.Logs, 31)
    end

    warn("[BloodyUniversal] " .. entry)
end

local function SafeCleanup()
    Log("Начало SafeCleanup", "CLEANUP")

    -- Disconnect all connections
    for name, connection in pairs(BloodyUniversal.Connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
            Log("Отключено: " .. name, "CLEANUP")
        end
    end
    BloodyUniversal.Connections = {}

    -- Disable all features
    for feature, _ in pairs(BloodyUniversal.Enabled) do
        BloodyUniversal.Enabled[feature] = false
    end

    -- Restore character state
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        -- Restore WalkSpeed
        if humanoid then
            humanoid.WalkSpeed = 16
        end

        -- Remove BodyVelocity
        if hrp then
            local bodyVel = hrp:FindFirstChild("BloodyFly")
            if bodyVel then
                bodyVel:Destroy()
            end
        end

        -- Restore CanCollide
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end

        -- Remove WalkOnWater platform
        local platform = workspace:FindFirstChild("BloodyWaterPlatform")
        if platform then
            platform:Destroy()
        end
    end

    -- Restore Lighting
    Lighting.Brightness = 1
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

    -- Clear ESP
    for _, drawing in ipairs(BloodyUniversal.ESPDrawings or {}) do
        if drawing then
            drawing:Remove()
        end
    end
    BloodyUniversal.ESPDrawings = {}

    Log("SafeCleanup завершён", "CLEANUP")
end

-- Anti-AFK
local function SetupAntiAFK()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:ClickButton2(Vector2.new())
        Log("Anti-AFK triggered", "AFK")
    end)
end

-- FPS Unlock
setfpscap(999)
Log("FPS unlocked (999)", "INIT")

-- Player Modifiers
function BloodyUniversal.ToggleFly(enabled, speed)
    BloodyUniversal.Enabled.Fly = enabled
    speed = speed or 5

    if enabled then
        local character = LocalPlayer.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local bodyVel = hrp:FindFirstChild("BloodyFly") or Instance.new("BodyVelocity")
        bodyVel.Name = "BloodyFly"
        bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = hrp

        BloodyUniversal.Connections.FlyLoop = RunService.Heartbeat:Connect(function()
            if not BloodyUniversal.Enabled.Fly then return end

            local char = LocalPlayer.Character
            if not char then return end

            local root = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid then return end

            local velocity = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                velocity = velocity + Camera.CFrame.LookVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                velocity = velocity - Camera.CFrame.LookVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                velocity = velocity - Camera.CFrame.RightVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                velocity = velocity + Camera.CFrame.RightVector * speed
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, speed, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                velocity = velocity - Vector3.new(0, speed, 0)
            end

            local bv = root:FindFirstChild("BloodyFly")
            if bv then
                bv.Velocity = velocity * 50
            end

            humanoid.PlatformStand = true
        end)

        Log("Fly включён (скорость: " .. speed .. ")", "PLAYER")
    else
        if BloodyUniversal.Connections.FlyLoop then
            BloodyUniversal.Connections.FlyLoop:Disconnect()
            BloodyUniversal.Connections.FlyLoop = nil
        end

        local character = LocalPlayer.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if hrp then
                local bodyVel = hrp:FindFirstChild("BloodyFly")
                if bodyVel then
                    bodyVel:Destroy()
                end
            end

            if humanoid then
                humanoid.PlatformStand = false
            end
        end

        Log("Fly отключён", "PLAYER")
    end
end

function BloodyUniversal.ToggleNoclip(enabled)
    BloodyUniversal.Enabled.Noclip = enabled

    if enabled then
        BloodyUniversal.Connections.NoclipLoop = RunService.Stepped:Connect(function()
            if not BloodyUniversal.Enabled.Noclip then return end

            local character = LocalPlayer.Character
            if not character then return end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)

        Log("Noclip включён", "PLAYER")
    else
        if BloodyUniversal.Connections.NoclipLoop then
            BloodyUniversal.Connections.NoclipLoop:Disconnect()
            BloodyUniversal.Connections.NoclipLoop = nil
        end

        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end

        Log("Noclip отключён", "PLAYER")
    end
end

function BloodyUniversal.ToggleWalkOnWater(enabled)
    BloodyUniversal.Enabled.WalkOnWater = enabled

    if enabled then
        local platform = Instance.new("Part")
        platform.Name = "BloodyWaterPlatform"
        platform.Size = Vector3.new(10, 1, 10)
        platform.Transparency = 0.5
        platform.CanCollide = true
        platform.Anchored = true
        platform.Color = Color3.fromRGB(0, 150, 255)
        platform.Parent = workspace

        BloodyUniversal.Connections.WaterLoop = RunService.Heartbeat:Connect(function()
            if not BloodyUniversal.Enabled.WalkOnWater then return end

            local character = LocalPlayer.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local plat = workspace:FindFirstChild("BloodyWaterPlatform")
            if plat then
                local waterLevel = workspace.Terrain:WorldToCell(hrp.Position).Y * 4
                plat.Position = Vector3.new(hrp.Position.X, waterLevel - 3, hrp.Position.Z)
            end
        end)

        Log("Walk On Water включён", "PLAYER")
    else
        if BloodyUniversal.Connections.WaterLoop then
            BloodyUniversal.Connections.WaterLoop:Disconnect()
            BloodyUniversal.Connections.WaterLoop = nil
        end

        local platform = workspace:FindFirstChild("BloodyWaterPlatform")
        if platform then
            platform:Destroy()
        end

        Log("Walk On Water отключён", "PLAYER")
    end
end

function BloodyUniversal.ToggleSpeed(enabled, speed)
    BloodyUniversal.Enabled.Speed = enabled
    speed = speed or 50

    if enabled then
        local character = LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        humanoid.WalkSpeed = speed

        BloodyUniversal.Connections.SpeedLoop = RunService.Heartbeat:Connect(function()
            if not BloodyUniversal.Enabled.Speed then return end

            local char = LocalPlayer.Character
            if not char then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= speed then
                hum.WalkSpeed = speed
            end
        end)

        Log("Speed включён (" .. speed .. ")", "PLAYER")
    else
        if BloodyUniversal.Connections.SpeedLoop then
            BloodyUniversal.Connections.SpeedLoop:Disconnect()
            BloodyUniversal.Connections.SpeedLoop = nil
        end

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end

        Log("Speed отключён", "PLAYER")
    end
end

-- Visual
BloodyUniversal.ESPSettings = {
    Enabled = false,
    Boxes = true,
    Names = true,
    Distance = true,
    HealthBars = true,
    Tracers = false,
    TeamCheck = false
}

BloodyUniversal.ESPDrawings = {}

function BloodyUniversal.ToggleESP(enabled)
    BloodyUniversal.ESPSettings.Enabled = enabled

    if enabled then
        BloodyUniversal.Connections.ESPLoop = RunService.RenderStepped:Connect(function()
            if not BloodyUniversal.ESPSettings.Enabled then return end

            -- Clear old drawings
            for _, drawing in ipairs(BloodyUniversal.ESPDrawings) do
                drawing:Remove()
            end
            BloodyUniversal.ESPDrawings = {}

            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end

                if BloodyUniversal.ESPSettings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end

                local character = player.Character
                if not character then continue end

                local hrp = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not hrp or not humanoid then continue end

                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    -- Box
                    if BloodyUniversal.ESPSettings.Boxes then
                        local box = Drawing.new("Square")
                        box.Visible = true
                        box.Color = Color3.new(1, 1, 1)
                        box.Thickness = 2
                        box.Transparency = 1
                        box.Filled = false

                        local headPos = character:FindFirstChild("Head") and character.Head.Position or hrp.Position
                        local legPos = hrp.Position - Vector3.new(0, 3, 0)

                        local topVector = Camera:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
                        local bottomVector = Camera:WorldToViewportPoint(legPos)

                        local height = math.abs(topVector.Y - bottomVector.Y)
                        local width = height / 2

                        box.Size = Vector2.new(width, height)
                        box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)

                        table.insert(BloodyUniversal.ESPDrawings, box)
                    end

                    -- Name
                    if BloodyUniversal.ESPSettings.Names then
                        local nameText = Drawing.new("Text")
                        nameText.Visible = true
                        nameText.Color = Color3.new(1, 1, 1)
                        nameText.Text = player.Name
                        nameText.Size = 16
                        nameText.Center = true
                        nameText.Outline = true
                        nameText.Position = Vector2.new(vector.X, vector.Y - 30)

                        table.insert(BloodyUniversal.ESPDrawings, nameText)
                    end

                    -- Distance
                    if BloodyUniversal.ESPSettings.Distance then
                        local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        local distText = Drawing.new("Text")
                        distText.Visible = true
                        distText.Color = Color3.new(1, 1, 1)
                        distText.Text = string.format("[%.0f studs]", distance)
                        distText.Size = 14
                        distText.Center = true
                        distText.Outline = true
                        distText.Position = Vector2.new(vector.X, vector.Y + 30)

                        table.insert(BloodyUniversal.ESPDrawings, distText)
                    end

                    -- Health Bar
                    if BloodyUniversal.ESPSettings.HealthBars then
                        local healthPct = humanoid.Health / humanoid.MaxHealth

                        local healthBarBg = Drawing.new("Square")
                        healthBarBg.Visible = true
                        healthBarBg.Color = Color3.new(0, 0, 0)
                        healthBarBg.Thickness = 1
                        healthBarBg.Transparency = 0.5
                        healthBarBg.Filled = true
                        healthBarBg.Size = Vector2.new(50, 6)
                        healthBarBg.Position = Vector2.new(vector.X - 25, vector.Y + 15)

                        local healthBarFg = Drawing.new("Square")
                        healthBarFg.Visible = true
                        healthBarFg.Color = Color3.fromRGB(0, 255, 0)
                        healthBarFg.Thickness = 1
                        healthBarFg.Transparency = 1
                        healthBarFg.Filled = true
                        healthBarFg.Size = Vector2.new(50 * healthPct, 6)
                        healthBarFg.Position = Vector2.new(vector.X - 25, vector.Y + 15)

                        table.insert(BloodyUniversal.ESPDrawings, healthBarBg)
                        table.insert(BloodyUniversal.ESPDrawings, healthBarFg)
                    end

                    -- Tracers
                    if BloodyUniversal.ESPSettings.Tracers then
                        local tracer = Drawing.new("Line")
                        tracer.Visible = true
                        tracer.Color = Color3.new(1, 1, 1)
                        tracer.Thickness = 1
                        tracer.Transparency = 1
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(vector.X, vector.Y)

                        table.insert(BloodyUniversal.ESPDrawings, tracer)
                    end
                end
            end
        end)

        Log("ESP включён", "VISUAL")
    else
        if BloodyUniversal.Connections.ESPLoop then
            BloodyUniversal.Connections.ESPLoop:Disconnect()
            BloodyUniversal.Connections.ESPLoop = nil
        end

        for _, drawing in ipairs(BloodyUniversal.ESPDrawings) do
            drawing:Remove()
        end
        BloodyUniversal.ESPDrawings = {}

        Log("ESP отключён", "VISUAL")
    end
end

function BloodyUniversal.ToggleFullbright(enabled)
    BloodyUniversal.Enabled.Fullbright = enabled

    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)

        Log("Fullbright включён", "VISUAL")
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

        Log("Fullbright отключён", "VISUAL")
    end
end

-- Combat
function BloodyUniversal.ToggleAntiAim(enabled)
    BloodyUniversal.Enabled.AntiAim = enabled

    if enabled then
        BloodyUniversal.Connections.AntiAimLoop = RunService.RenderStepped:Connect(function()
            if not BloodyUniversal.Enabled.AntiAim then return end

            local character = LocalPlayer.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)
        end)

        Log("Anti-Aim включён", "COMBAT")
    else
        if BloodyUniversal.Connections.AntiAimLoop then
            BloodyUniversal.Connections.AntiAimLoop:Disconnect()
            BloodyUniversal.Connections.AntiAimLoop = nil
        end

        Log("Anti-Aim отключён", "COMBAT")
    end
end

-- Config System
BloodyUniversal.ConfigPath = "BloodyUniversal_Configs/"

function BloodyUniversal.SaveConfig(configName)
    local config = {
        Version = BloodyUniversal.Version,
        Enabled = BloodyUniversal.Enabled,
        ESPSettings = BloodyUniversal.ESPSettings
    }

    local success, err = pcall(function()
        local json = game:GetService("HttpService"):JSONEncode(config)
        writefile(BloodyUniversal.ConfigPath .. configName .. ".json", json)
    end)

    if success then
        Log("Конфиг сохранён: " .. configName, "CONFIG")
        return true
    else
        Log("Ошибка сохранения: " .. tostring(err), "CONFIG")
        return false
    end
end

function BloodyUniversal.LoadConfig(configName)
    local success, result = pcall(function()
        local json = readfile(BloodyUniversal.ConfigPath .. configName .. ".json")
        return game:GetService("HttpService"):JSONDecode(json)
    end)

    if success then
        BloodyUniversal.Enabled = result.Enabled or {}
        BloodyUniversal.ESPSettings = result.ESPSettings or BloodyUniversal.ESPSettings

        Log("Конфиг загружен: " .. configName, "CONFIG")
        return true
    else
        Log("Ошибка загрузки: " .. tostring(result), "CONFIG")
        return false
    end
end

-- UI System
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BloodyUniversalUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Check for background image
    local bgImagePath = "C:\\Roblox\\background.png"
    local hasCustomBg = isfile and isfile(bgImagePath)

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.25
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Background image (if exists)
    if hasCustomBg then
        local bgImage = Instance.new("ImageLabel")
        bgImage.Name = "BackgroundImage"
        bgImage.Size = UDim2.new(1, 0, 1, 0)
        bgImage.Position = UDim2.new(0, 0, 0, 0)
        bgImage.BackgroundTransparency = 1
        bgImage.Image = getcustomasset(bgImagePath)
        bgImage.ImageTransparency = 0.7
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 1
        bgImage.Parent = mainFrame
    end

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BloodyBlox Universal v" .. BloodyUniversal.Version
    title.TextColor3 = Color3.fromRGB(255, 50, 50)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = header

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 3
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        Log("UI скрыто", "UI")
    end)

    -- Tab container
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -20, 1, -60)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 6
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.ZIndex = 2
    tabContainer.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer

    -- Auto-resize canvas
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 10)
    end)

    BloodyUniversal.UI.ScreenGui = screenGui
    BloodyUniversal.UI.MainFrame = mainFrame
    BloodyUniversal.UI.TabContainer = tabContainer

    return screenGui
end

local function CreateToggle(parent, text, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -10, 0, 35)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    toggleFrame.BackgroundTransparency = 0.4
    toggleFrame.BorderSizePixel = 0
    toggleFrame.ZIndex = 3
    toggleFrame.Parent = parent

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = toggleFrame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 25)
    button.Position = UDim2.new(1, -70, 0.5, -12.5)
    button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button.Text = "OFF"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 4
    button.Parent = toggleFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    local enabled = false
    button.MouseButton1Click:Connect(function()
        enabled = not enabled

        if enabled then
            button.Text = "ON"
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            button.Text = "OFF"
            button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end

        if callback then
            callback(enabled)
        end
    end)

    return toggleFrame, button
end

local function CreateSlider(parent, text, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -10, 0, 50)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    sliderFrame.BackgroundTransparency = 0.4
    sliderFrame.BorderSizePixel = 0
    sliderFrame.ZIndex = 3
    sliderFrame.Parent = parent

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = sliderFrame

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.9, 0, 0, 8)
    slider.Position = UDim2.new(0.05, 0, 1, -15)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    slider.BorderSizePixel = 0
    slider.ZIndex = 4
    slider.Parent = sliderFrame

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = slider

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 5
    sliderFill.Parent = slider

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill

    local dragging = false
    local currentValue = default

    local function updateSlider(input)
        local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(min + (max - min) * relativeX)

        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        label.Text = text .. ": " .. currentValue

        if callback then
            callback(currentValue)
        end
    end

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)

    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    return sliderFrame
end

local function CreateButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.ZIndex = 3
    button.Parent = parent

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return button
end

local function CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 0)
    section.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    section.BackgroundTransparency = 0.3
    section.BorderSizePixel = 0
    section.ZIndex = 2
    section.Parent = parent

    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 8)
    sectionCorner.Parent = section

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 3
    titleLabel.Parent = section

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -40)
    contentFrame.Position = UDim2.new(0, 10, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 3
    contentFrame.Parent = section

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        section.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y + 45)
    end)

    return section, contentFrame
end

-- Build UI
local function BuildUI()
    local gui = CreateUI()
    local container = BloodyUniversal.UI.TabContainer

    -- Player Section
    local playerSection, playerContent = CreateSection(container, "🏃 Player")

    local flySpeed = 5
    local _, flyToggle = CreateToggle(playerContent, "Fly", function(enabled)
        BloodyUniversal.ToggleFly(enabled, flySpeed)
    end)

    CreateSlider(playerContent, "Fly Speed", 1, 10, 5, function(value)
        flySpeed = value
        if BloodyUniversal.Enabled.Fly then
            BloodyUniversal.ToggleFly(true, flySpeed)
        end
    end)

    CreateToggle(playerContent, "Noclip", function(enabled)
        BloodyUniversal.ToggleNoclip(enabled)
    end)

    CreateToggle(playerContent, "Walk On Water", function(enabled)
        BloodyUniversal.ToggleWalkOnWater(enabled)
    end)

    local walkSpeed = 50
    local _, speedToggle = CreateToggle(playerContent, "Speed", function(enabled)
        BloodyUniversal.ToggleSpeed(enabled, walkSpeed)
    end)

    CreateSlider(playerContent, "Walk Speed", 16, 200, 50, function(value)
        walkSpeed = value
        if BloodyUniversal.Enabled.Speed then
            BloodyUniversal.ToggleSpeed(true, walkSpeed)
        end
    end)

    -- Visual Section
    local visualSection, visualContent = CreateSection(container, "👁️ Visual")

    CreateToggle(visualContent, "ESP", function(enabled)
        BloodyUniversal.ToggleESP(enabled)
    end)

    CreateToggle(visualContent, "ESP - Boxes", function(enabled)
        BloodyUniversal.ESPSettings.Boxes = enabled
    end)

    CreateToggle(visualContent, "ESP - Names", function(enabled)
        BloodyUniversal.ESPSettings.Names = enabled
    end)

    CreateToggle(visualContent, "ESP - Distance", function(enabled)
        BloodyUniversal.ESPSettings.Distance = enabled
    end)

    CreateToggle(visualContent, "ESP - Health Bars", function(enabled)
        BloodyUniversal.ESPSettings.HealthBars = enabled
    end)

    CreateToggle(visualContent, "ESP - Tracers", function(enabled)
        BloodyUniversal.ESPSettings.Tracers = enabled
    end)

    CreateToggle(visualContent, "ESP - Team Check", function(enabled)
        BloodyUniversal.ESPSettings.TeamCheck = enabled
    end)

    CreateToggle(visualContent, "Fullbright", function(enabled)
        BloodyUniversal.ToggleFullbright(enabled)
    end)

    -- Combat Section
    local combatSection, combatContent = CreateSection(container, "⚔️ Combat")

    CreateToggle(combatContent, "Anti-Aim", function(enabled)
        BloodyUniversal.ToggleAntiAim(enabled)
    end)

    -- Logs Section
    local logsSection, logsContent = CreateSection(container, "📋 Logs")

    local logsDisplay = Instance.new("ScrollingFrame")
    logsDisplay.Size = UDim2.new(1, -10, 0, 200)
    logsDisplay.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    logsDisplay.BackgroundTransparency = 0.5
    logsDisplay.BorderSizePixel = 0
    logsDisplay.ScrollBarThickness = 6
    logsDisplay.CanvasSize = UDim2.new(0, 0, 0, 0)
    logsDisplay.ZIndex = 4
    logsDisplay.Parent = logsContent

    local logsCorner = Instance.new("UICorner")
    logsCorner.CornerRadius = UDim.new(0, 6)
    logsCorner.Parent = logsDisplay

    local logsLayout = Instance.new("UIListLayout")
    logsLayout.Padding = UDim.new(0, 2)
    logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logsLayout.Parent = logsDisplay

    local function RefreshLogs()
        for _, child in ipairs(logsDisplay:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        for _, logEntry in ipairs(BloodyUniversal.Logs or {}) do
            local logLabel = Instance.new("TextLabel")
            logLabel.Size = UDim2.new(1, -10, 0, 20)
            logLabel.BackgroundTransparency = 1
            logLabel.Text = logEntry
            logLabel.TextColor3 = Color3.new(1, 1, 1)
            logLabel.TextSize = 12
            logLabel.Font = Enum.Font.Code
            logLabel.TextXAlignment = Enum.TextXAlignment.Left
            logLabel.TextWrapped = true
            logLabel.ZIndex = 5
            logLabel.Parent = logsDisplay
        end

        logsDisplay.CanvasSize = UDim2.new(0, 0, 0, logsLayout.AbsoluteContentSize.Y + 10)
    end

    CreateButton(logsContent, "Refresh", RefreshLogs)

    CreateButton(logsContent, "Copy All", function()
        local allLogs = table.concat(BloodyUniversal.Logs or {}, "\n")
        setclipboard(allLogs)
        Log("Логи скопированы в буфер обмена", "LOGS")
    end)

    -- Settings Section
    local settingsSection, settingsContent = CreateSection(container, "⚙️ Settings")

    CreateButton(settingsContent, "Disable All", function()
        for feature, enabled in pairs(BloodyUniversal.Enabled) do
            if enabled then
                if feature == "Fly" then
                    BloodyUniversal.ToggleFly(false)
                elseif feature == "Noclip" then
                    BloodyUniversal.ToggleNoclip(false)
                elseif feature == "WalkOnWater" then
                    BloodyUniversal.ToggleWalkOnWater(false)
                elseif feature == "Speed" then
                    BloodyUniversal.ToggleSpeed(false)
                elseif feature == "Fullbright" then
                    BloodyUniversal.ToggleFullbright(false)
                elseif feature == "AntiAim" then
                    BloodyUniversal.ToggleAntiAim(false)
                end
            end
        end

        BloodyUniversal.ToggleESP(false)

        Log("Все функции отключены", "SETTINGS")
    end)

    CreateButton(settingsContent, "SAFE EXIT", function()
        SafeCleanup()

        if gui then
            gui:Destroy()
        end

        Log("Safe exit выполнен — UI уничтожено", "SETTINGS")
    end)

    gui.Parent = game:GetService("CoreGui")

    Log("UI создан успешно", "INIT")
end

-- Toggle UI visibility
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        local gui = game:GetService("CoreGui"):FindFirstChild("BloodyUniversalUI")
        if gui then
            local mainFrame = gui:FindFirstChild("MainFrame")
            if mainFrame then
                mainFrame.Visible = not mainFrame.Visible
                Log("UI переключено: " .. tostring(mainFrame.Visible), "UI")
            end
        end
    end
end)

-- Initialize
SetupAntiAFK()
BuildUI()

Log("BloodyBlox Universal v" .. BloodyUniversal.Version .. " загружен", "INIT")
Log("Insert — открыть/закрыть меню", "INIT")
Log("Универсальный чит (только клиентские функции)", "INIT")

return BloodyUniversal
