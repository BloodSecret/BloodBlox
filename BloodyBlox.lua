--[[
    BloodyBlox v4.1.0 SIMPLE - Muscle Legends
    ПРЯМОЙ ПОДХОД - БЕЗ ХУКОВ
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

print("[BloodyBlox] v4.1.0 SIMPLE - Starting...")

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- ============ SIMPLE GOD MODE ============

local godModeActive = false
local godModeConnection = nil

local function EnableGodMode()
    print("[BloodyBlox] God Mode: Enabling SIMPLE approach...")
    godModeActive = true

    -- Постоянное восстановление HP каждый кадр
    godModeConnection = RunService.Heartbeat:Connect(function()
        if not godModeActive then
            if godModeConnection then
                godModeConnection:Disconnect()
            end
            return
        end

        local char = Player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                -- Просто держим HP на максимуме
                hum.Health = hum.MaxHealth
            end
        end
    end)

    print("[BloodyBlox] God Mode: Active - Health constantly restored")
end

local function DisableGodMode()
    godModeActive = false
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    print("[BloodyBlox] God Mode: Disabled")
end

-- ============ SIMPLE ONE SHOT ============

local oneShotActive = false
local oneShotConnection = nil

local function EnableOneShot()
    print("[BloodyBlox] One Shot: Enabling SIMPLE approach...")
    oneShotActive = true

    -- Ищем все возможные stats и ставим на максимум
    local function MaxAllOffensiveStats()
        -- Проверяем leaderstats
        local leaderstats = Player:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in pairs(leaderstats:GetChildren()) do
                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                    local name = stat.Name:lower()
                    if name:find("strength") or name:find("power") or name:find("muscle") or
                       name:find("force") or name:find("damage") or name:find("punch") then
                        stat.Value = 999000000000000
                        print("[BloodyBlox] One Shot: Set " .. stat.Name .. " = 999T")
                    end
                end
            end
        end

        -- Проверяем PlayerStats
        local playerStats = Player:FindFirstChild("PlayerStats") or Player:FindFirstChild("Stats")
        if playerStats then
            for _, stat in pairs(playerStats:GetChildren()) do
                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                    local name = stat.Name:lower()
                    if name:find("strength") or name:find("power") or name:find("muscle") or
                       name:find("force") or name:find("damage") or name:find("punch") then
                        stat.Value = 999000000000000
                        print("[BloodyBlox] One Shot: Set " .. stat.Name .. " = 999T")
                    end
                end
            end
        end

        -- Проверяем Character stats
        local char = Player.Character
        if char then
            for _, stat in pairs(char:GetDescendants()) do
                if stat:IsA("NumberValue") or stat:IsA("IntValue") then
                    local name = stat.Name:lower()
                    if name:find("strength") or name:find("power") or name:find("muscle") or
                       name:find("force") or name:find("damage") or name:find("punch") then
                        stat.Value = 999000000000000
                        print("[BloodyBlox] One Shot: Set " .. stat.Name .. " = 999T")
                    end
                end
            end
        end
    end

    -- Устанавливаем сразу
    MaxAllOffensiveStats()

    -- Держим на максимуме каждый кадр
    oneShotConnection = RunService.Heartbeat:Connect(function()
        if not oneShotActive then
            if oneShotConnection then
                oneShotConnection:Disconnect()
            end
            return
        end
        MaxAllOffensiveStats()
    end)

    print("[BloodyBlox] One Shot: Active - All offensive stats maxed to 999T")
end

local function DisableOneShot()
    oneShotActive = false
    if oneShotConnection then
        oneShotConnection:Disconnect()
        oneShotConnection = nil
    end
    print("[BloodyBlox] One Shot: Disabled")
end

-- ============ SIMPLE UI ============

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloodyBloxSimple"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
Title.Text = "BLOODYBLOX SIMPLE v4.1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- God Mode Button
local GodModeBtn = Instance.new("TextButton")
GodModeBtn.Size = UDim2.new(0, 260, 0, 40)
GodModeBtn.Position = UDim2.new(0, 20, 0, 60)
GodModeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
GodModeBtn.Text = "God Mode: OFF"
GodModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GodModeBtn.Font = Enum.Font.Gotham
GodModeBtn.TextSize = 12
GodModeBtn.Parent = MainFrame

local GodModeCorner = Instance.new("UICorner")
GodModeCorner.CornerRadius = UDim.new(0, 6)
GodModeCorner.Parent = GodModeBtn

GodModeBtn.MouseButton1Click:Connect(function()
    if godModeActive then
        DisableGodMode()
        GodModeBtn.Text = "God Mode: OFF"
        GodModeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    else
        EnableGodMode()
        GodModeBtn.Text = "God Mode: ON"
        GodModeBtn.BackgroundColor3 = Color3.fromRGB(0, 139, 0)
    end
end)

-- One Shot Button
local OneShotBtn = Instance.new("TextButton")
OneShotBtn.Size = UDim2.new(0, 260, 0, 40)
OneShotBtn.Position = UDim2.new(0, 20, 0, 110)
OneShotBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
OneShotBtn.Text = "One Shot (999T): OFF"
OneShotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OneShotBtn.Font = Enum.Font.Gotham
OneShotBtn.TextSize = 12
OneShotBtn.Parent = MainFrame

local OneShotCorner = Instance.new("UICorner")
OneShotCorner.CornerRadius = UDim.new(0, 6)
OneShotCorner.Parent = OneShotBtn

OneShotBtn.MouseButton1Click:Connect(function()
    if oneShotActive then
        DisableOneShot()
        OneShotBtn.Text = "One Shot (999T): OFF"
        OneShotBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    else
        EnableOneShot()
        OneShotBtn.Text = "One Shot (999T): ON"
        OneShotBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 260, 0, 30)
CloseBtn.Position = UDim2.new(0, 20, 0, 160)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CloseBtn.Text = "Close"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.TextSize = 11
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    DisableGodMode()
    DisableOneShot()
    ScreenGui:Destroy()
    print("[BloodyBlox] Closed")
end)

print("[BloodyBlox] ========================================")
print("[BloodyBlox] v4.1.0 SIMPLE LOADED")
print("[BloodyBlox] God Mode: Constantly restores Health")
print("[BloodyBlox] One Shot: Max all offensive stats to 999T")
print("[BloodyBlox] ========================================")
print("[BloodyBlox] ТЕСТ: Включи оба, проверь:")
print("[BloodyBlox] 1. Тебя не могут убить?")
print("[BloodyBlox] 2. Ты убиваешь с одного удара?")
print("[BloodyBlox] 3. Смотри в F9 консоль что пишет скрипт")
print("[BloodyBlox] ========================================")
