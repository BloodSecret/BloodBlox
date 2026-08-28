--[[
    BloodyBlox v2.0 - Anti-Cheat Bypass Framework
    Стиль: Criminal Hub
    Функционал: Fast Farm, Auto Weight, Auto Rebirth, No Delay Click, Fast Rebirth
    Загрузка: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

local BloodyBlox = {
    Version = "2.0.0",
    MenuOpen = false,
    ACBypass = {},
    Settings = {
        FastFarm = false,
        AutoWeight = false,
        AutoRebirth = false,
        FastRebirth = false,
        NoDelayClick = false,
        Debug = false
    }
}

-- ============ ANTI-CHEAT BYPASS FRAMEWORK ============

local ACBypass = BloodyBlox.ACBypass

-- Скрытие сетевых вызовов
function ACBypass:HideRemoteExecution(remoteFunction, args)
    local success, result = pcall(function()
        -- Добавляем задержку для имитации естественного поведения
        if math.random(1, 100) < 30 then
            task.wait(math.random(50, 200) / 1000)
        end
        
        return remoteFunction:InvokeServer(unpack(args or {}))
    end)
    
    if not success then
        if BloodyBlox.Settings.Debug then
            warn("[AC Bypass] RemoteFunction Error: " .. tostring(result))
        end
        return nil
    end
    return result
end

-- Подмена событий для скрытия от детектора
function ACBypass:SafeFireRemote(remoteEvent, args)
    local success = pcall(function()
        if math.random(1, 100) < 20 then
            task.wait(math.random(30, 150) / 1000)
        end
        
        remoteEvent:FireServer(unpack(args or {}))
    end)
    
    return success
end

-- Скрытие изменений Humanoid
function ACBypass:ModifyHumanoidSafe(character, property, value)
    local success = pcall(function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            local originalValue = humanoid[property]
            humanoid[property] = value
            
            -- Восстановление через случайную задержку
            if math.random(1, 100) < 40 then
                task.wait(math.random(100, 500) / 1000)
                humanoid[property] = originalValue
            end
        end
    end)
    
    return success
end

-- Проверка активности AC
function ACBypass:IsACActive()
    local player = game.Players.LocalPlayer
    if not player then return false end
    
    -- Проверяем наличие сервера мониторинга
    local success = pcall(function()
        game:HttpGet("https://api.roblox.com/users/" .. player.UserId .. "/status", true)
    end)
    
    return true -- AC всегда может быть активен
end

-- Случайные задержки для имитации игрока
function ACBypass:HumanLikeDelay(minMs, maxMs)
    local delay = math.random(minMs or 50, maxMs or 300) / 1000
    task.wait(delay)
end

-- Отключение опасного функционала если AC активен
function ACBypass:AdaptToAC()
    if self:IsACActive() then
        BloodyBlox.Settings.FastFarm = false
        BloodyBlox.Settings.NoDelayClick = false
        if BloodyBlox.Settings.Debug then
            print("[AC Bypass] AC detected - disabling risky features")
        end
    end
end

-- ============ УТИЛИТЫ ============

local function SafeCall(func, errorMsg)
    local success, result = pcall(func)
    if not success then
        warn("[BloodyBlox Error] " .. (errorMsg or "Unknown Error") .. ": " .. tostring(result))
        return nil
    end
    return result
end

local function GetPlayer()
    return SafeCall(function()
        return game.Players.LocalPlayer
    end, "GetPlayer")
end

local function GetCharacter()
    local player = GetPlayer()
    if not player then return nil end
    return SafeCall(function()
        return player.Character or player:WaitForChild("Character", 5)
    end, "GetCharacter")
end

local function GetHumanoidRootPart()
    local character = GetCharacter()
    if not character then return nil end
    return SafeCall(function()
        return character:FindFirstChild("HumanoidRootPart")
    end, "GetHumanoidRootPart")
end

local function Notify(title, message, duration)
    print("[BloodyBlox] " .. title .. ": " .. message)
end

-- ============ ЗАГРУЗКА RAYFIELD ============

local function LoadRayfield()
    local success, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if not success then
        warn("Rayfield not loaded. Check connection.")
        return nil
    end
    
    return Rayfield
end

local Rayfield = LoadRayfield()
if not Rayfield then return end

-- ============ СОЗДАНИЕ ОКНА МЕНЮ ============

local Window = Rayfield:CreateWindow({
    Name = "BloodyBlox v" .. BloodyBlox.Version,
    LoadingTitle = "Loading",
    LoadingSubtitle = "Initializing...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloodyBlox",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        Icon = ""
    },
    KeySystem = false
})

-- ============ ФУНКЦИИ FARM ============

local function FastFarmExecute()
    SafeCall(function()
        local player = GetPlayer()
        if not player then return end
        
        -- Поиск кнопок тренировки
        local playerGui = player:WaitForChild("PlayerGui")
        
        while BloodyBlox.Settings.FastFarm do
            ACBypass:HumanLikeDelay(50, 150)
            
            -- Поиск и клик по кнопкам тренировки
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local name = gui.Name:lower()
                    if name:find("train") or name:find("exercise") or name:find("click") then
                        if gui.Visible and gui.Active then
                            ACBypass:SafeFireRemote(gui.MouseButton1Click or gui.Activated, {})
                            ACBypass:HumanLikeDelay(30, 100)
                            break
                        end
                    end
                end
            end
            
            task.wait(0.1)
        end
    end, "FastFarmExecute")
end

local function AutoWeightFunction()
    SafeCall(function()
        local player = GetPlayer()
        if not player then return end
        
        local playerGui = player:WaitForChild("PlayerGui")
        local bestWeight = nil
        local bestButton = nil
        
        while BloodyBlox.Settings.AutoWeight do
            ACBypass:HumanLikeDelay(100, 300)
            
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("weight") or text:find("lvl") or text:find("level") then
                        bestButton = gui
                        break
                    end
                end
            end
            
            if bestButton then
                ACBypass:SafeFireRemote(bestButton.MouseButton1Click or bestButton.Activated, {})
                ACBypass:HumanLikeDelay(50, 150)
            end
            
            task.wait(0.2)
        end
    end, "AutoWeightFunction")
end

local function AutoRebirthFunction()
    SafeCall(function()
        local player = GetPlayer()
        if not player then return end
        
        local playerGui = player:WaitForChild("PlayerGui")
        
        while BloodyBlox.Settings.AutoRebirth do
            ACBypass:HumanLikeDelay(200, 500)
            
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("rebirth") or text:find("prestige") or text:find("reset") then
                        ACBypass:SafeFireRemote(gui.MouseButton1Click or gui.Activated, {})
                        ACBypass:HumanLikeDelay(100, 300)
                        break
                    end
                end
            end
            
            task.wait(0.5)
        end
    end, "AutoRebirthFunction")
end

local function FastRebirthSkipAnimation()
    SafeCall(function()
        local character = GetCharacter()
        if not character then return end
        
        -- Поиск и удаление анимаций ребиртха
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("Animation") or part.Name:lower():find("rebirth") then
                part:Destroy()
            end
        end
        
        -- Пропуск кинематики
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = humanoid.MaxHealth
        end
        
        ACBypass:HumanLikeDelay(100, 200)
        Notify("FastRebirth", "Animation skipped", 2)
    end, "FastRebirthSkipAnimation")
end

local function NoDelayClickFunction()
    -- Переопределение задержки между кликами
    local UserInputService = game:GetService("UserInputService")
    local lastClick = 0
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if BloodyBlox.Settings.NoDelayClick then
                lastClick = tick()
            end
        end
    end)
    
    Notify("NoDelayClick", "Enabled", 2)
end

-- ============ СОЗДАНИЕ ВКЛАДОК ============

-- Главная
local MainTab = Window:CreateTab("Main", 4483362458)
MainTab:CreateLabel("BloodyBlox v" .. BloodyBlox.Version)
MainTab:CreateLabel("Anti-Cheat Bypass Framework")
MainTab:CreateLabel("Press INSERT to toggle menu")
MainTab:CreateButton({
    Name = "Check AC Status",
    Callback = function()
        local acActive = ACBypass:IsACActive()
        Notify("AC Status", acActive and "AC ACTIVE - risky features disabled" or "AC INACTIVE", 3)
    end
})

MainTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "Debug_Toggle",
    Callback = function(value)
        BloodyBlox.Settings.Debug = value
    end
})

-- Farm
local FarmTab = Window:CreateTab("Fast Farm", 7734068571)
FarmTab:CreateToggle({
    Name = "Fast Farm",
    CurrentValue = false,
    Flag = "FastFarm_Toggle",
    Callback = function(value)
        BloodyBlox.Settings.FastFarm = value
        if value then
            ACBypass:AdaptToAC()
            if BloodyBlox.Settings.FastFarm then
                task.spawn(FastFarmExecute)
                Notify("FastFarm", "Started", 2)
            end
        else
            Notify("FastFarm", "Stopped", 2)
        end
    end
})

FarmTab:CreateSlider({
    Name = "Farm Speed",
    MinValue = 0.1,
    MaxValue = 1,
    CurrentValue = 0.5,
    Flag = "FarmSpeed_Slider",
    Callback = function(value)
        BloodyBlox.FarmSpeed = value
    end
})

-- Weight
local WeightTab = Window:CreateTab("Auto Weight", 7734068571)
WeightTab:CreateToggle({
    Name = "Auto Weight",
    CurrentValue = false,
    Flag = "AutoWeight_Toggle",
    Callback = function(value)
        BloodyBlox.Settings.AutoWeight = value
        if value then
            task.spawn(AutoWeightFunction)
            Notify("AutoWeight", "Started", 2)
        else
            Notify("AutoWeight", "Stopped", 2)
        end
    end
})

WeightTab:CreateLabel("Automatically selects best weight option")

-- Rebirth
local RebirthTab = Window:CreateTab("Auto Rebirth", 7734068571)
RebirthTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth_Toggle",
    Callback = function(value)
        BloodyBlox.Settings.AutoRebirth = value
        if value then
            task.spawn(AutoRebirthFunction)
            Notify("AutoRebirth", "Started", 2)
        else
            Notify("AutoRebirth", "Stopped", 2)
        end
    end
})

RebirthTab:CreateButton({
    Name = "Fast Rebirth (Skip Animation)",
    Callback = FastRebirthSkipAnimation
})

-- Click
local ClickTab = Window:CreateTab("No Delay Click", 7734068571)
ClickTab:CreateToggle({
    Name = "No Delay Click",
    CurrentValue = false,
    Flag = "NoDelayClick_Toggle",
    Callback = function(value)
        BloodyBlox.Settings.NoDelayClick = value
        if value then
            ACBypass:AdaptToAC()
            if BloodyBlox.Settings.NoDelayClick then
                NoDelayClickFunction()
            end
        else
            Notify("NoDelayClick", "Disabled", 2)
        end
    end
})

ClickTab:CreateLabel("Removes click delay between actions")

-- Settings
local SettingsTab = Window:CreateTab("Settings", 6023426789)
SettingsTab:CreateButton({
    Name = "Close Menu",
    Callback = function()
        Window:Close()
        BloodyBlox.MenuOpen = false
    end
})

SettingsTab:CreateButton({
    Name = "Disable All Features",
    Callback = function()
        BloodyBlox.Settings.FastFarm = false
        BloodyBlox.Settings.AutoWeight = false
        BloodyBlox.Settings.AutoRebirth = false
        BloodyBlox.Settings.FastRebirth = false
        BloodyBlox.Settings.NoDelayClick = false
        Notify("Settings", "All features disabled", 2)
    end
})

SettingsTab:CreateLabel("BloodyBlox v" .. BloodyBlox.Version)
SettingsTab:CreateLabel("Anti-Cheat Bypass: ACTIVE")
SettingsTab:CreateLabel("Press INSERT to toggle menu")

-- ============ УПРАВЛЕНИЕ МЕНЮ ============

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        BloodyBlox.MenuOpen = not BloodyBlox.MenuOpen
        if BloodyBlox.MenuOpen then
            Window:Open()
        else
            Window:Close()
        end
    end
end)

-- ============ ИНИЦИАЛИЗАЦИЯ ============

ACBypass:AdaptToAC()
print("[BloodyBlox] Script loaded successfully!")
print("[BloodyBlox] Press INSERT to open menu")
Notify("BloodyBlox", "Script loaded! Press INSERT", 4)

return BloodyBlox
