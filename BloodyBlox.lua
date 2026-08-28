--[[
    BloodyBlox - Roblox Universal Script
    Меню: Rayfield
    Управление: Insert (открыть/закрыть)
    Тип: Внешний скрипт для инжектора
]]

local BloodyBlox = {}
BloodyBlox.Version = "1.0.0"
BloodyBlox.MenuOpen = false
BloodyBlox.SelectedTab = "Главная"

-- ============ ЗАГРУЗКА RAYFIELD ============

local function LoadRayfield()
    local success, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    
    if not success then
        warn("Rayfield не загружен. Проверьте подключение.")
        return nil
    end
    
    return Rayfield
end

-- ============ ИНИЦИАЛИЗАЦИЯ ============

local Rayfield = LoadRayfield()
if not Rayfield then return end

local Window = Rayfield:CreateWindow({
    Name = "BloodyBlox v" .. BloodyBlox.Version,
    LoadingTitle = "Инициализация",
    LoadingSubtitle = "Подготовка к работе...",
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

-- ============ ТАБЛИЦЫ ФУНКЦИЙ ============

local VisualSettings = {
    ESPEnabled = false,
    BoxESP = false,
    NameESP = false,
    DistanceESP = false,
    HealthbarESP = false,
    Chams = false,
    FOVCircle = false
}

local FarmSettings = {
    AutoFarm = false,
    AutoCollect = false,
    FastHarvest = false,
    MultiCollect = false,
    FarmRange = 50
}

local PlayerSettings = {
    InfiniteJump = false,
    SpeedBoost = false,
    NoClip = false,
    SpeedMultiplier = 1.5,
    JumpPower = 50
}

local TeleportLocations = {
    {name = "Спаун", x = 0, y = 10, z = 0},
    {name = "Центр карты", x = 50, y = 10, z = 50},
    {name = "Вверх", x = 0, y = 100, z = 0}
}

local MiscSettings = {
    ChatNotification = true,
    DebugMode = false,
    AutoRejoin = false
}

-- ============ УТИЛИТЫ И ПОМОЩНИКИ ============

local function SafeCall(func, errorMsg)
    local success, result = pcall(func)
    if not success then
        warn("[BloodyBlox Error] " .. (errorMsg or "Неизвестная ошибка") .. ": " .. tostring(result))
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
    local Player = GetPlayer()
    if not Player then return nil end
    return SafeCall(function()
        return Player.Character
    end, "GetCharacter")
end

local function GetHumanoidRootPart()
    local Character = GetCharacter()
    if not Character then return nil end
    return SafeCall(function()
        return Character:FindFirstChild("HumanoidRootPart")
    end, "GetHumanoidRootPart")
end

local function Notify(title, message, duration)
    Rayfield:Notify({
        Title = title or "BloodyBlox",
        Content = message or "Уведомление",
        Duration = duration or 3,
        Image = ""
    })
end

-- ============ ФУНКЦИИ VISUAL ============

local function EnableESP()
    if VisualSettings.ESPEnabled then
        Notify("Visual", "ESP уже активирован")
        return
    end
    
    SafeCall(function()
        VisualSettings.ESPEnabled = true
        Notify("Visual", "ESP активирован", 2)
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= GetPlayer() then
                local character = player.Character
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        -- Базовая реализация ESP (можно расширить)
                    end
                end
            end
        end
    end, "EnableESP")
end

local function DisableESP()
    VisualSettings.ESPEnabled = false
    Notify("Visual", "ESP отключен", 2)
end

local function ToggleChams()
    SafeCall(function()
        VisualSettings.Chams = not VisualSettings.Chams
        Notify("Visual", "Chams: " .. (VisualSettings.Chams and "ВКЛ" or "ВЫКЛ"), 2)
    end, "ToggleChams")
end

local function ToggleFOVCircle()
    SafeCall(function()
        VisualSettings.FOVCircle = not VisualSettings.FOVCircle
        Notify("Visual", "FOV Circle: " .. (VisualSettings.FOVCircle and "ВКЛ" or "ВЫКЛ"), 2)
    end, "ToggleFOVCircle")
end

-- ============ ФУНКЦИИ FARM ============

local function StartAutoFarm()
    if FarmSettings.AutoFarm then
        Notify("Farm", "AutoFarm уже работает")
        return
    end
    
    SafeCall(function()
        FarmSettings.AutoFarm = true
        Notify("Farm", "AutoFarm запущен", 2)
        
        while FarmSettings.AutoFarm do
            local Character = GetCharacter()
            if not Character then break end
            
            -- Базовая логика фарма
            wait(1)
        end
    end, "StartAutoFarm")
end

local function StopAutoFarm()
    FarmSettings.AutoFarm = false
    Notify("Farm", "AutoFarm остановлен", 2)
end

local function CollectNearby()
    SafeCall(function()
        local HRP = GetHumanoidRootPart()
        if not HRP then return end
        
        local range = FarmSettings.FarmRange
        local collected = 0
        
        for _, item in pairs(workspace:FindPartByCFrame(HRP.CFrame) or {}) do
            if item and (item.Name:lower():find("ore") or item.Name:lower():find("item")) then
                if (item.Position - HRP.Position).Magnitude <= range then
                    item:Destroy()
                    collected = collected + 1
                end
            end
        end
        
        Notify("Farm", "Собрано предметов: " .. collected, 2)
    end, "CollectNearby")
end

-- ============ ФУНКЦИИ PLAYER ============

local function EnableInfiniteJump()
    if PlayerSettings.InfiniteJump then
        Notify("Player", "Infinite Jump уже активирован")
        return
    end
    
    SafeCall(function()
        PlayerSettings.InfiniteJump = true
        Notify("Player", "Infinite Jump включен", 2)
        
        local UserInputService = game:GetService("UserInputService")
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.Space and PlayerSettings.InfiniteJump then
                local Character = GetCharacter()
                if Character then
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if Humanoid then
                        Humanoid:Jump()
                    end
                end
            end
        end)
    end, "EnableInfiniteJump")
end

local function ToggleSpeedBoost()
    SafeCall(function()
        PlayerSettings.SpeedBoost = not PlayerSettings.SpeedBoost
        local Character = GetCharacter()
        if not Character then return end
        
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then
            if PlayerSettings.SpeedBoost then
                Humanoid.WalkSpeed = Humanoid.WalkSpeed * PlayerSettings.SpeedMultiplier
                Notify("Player", "Speed Boost включен", 2)
            else
                Humanoid.WalkSpeed = 16 -- Стандартная скорость
                Notify("Player", "Speed Boost выключен", 2)
            end
        end
    end, "ToggleSpeedBoost")
end

local function ToggleNoClip()
    SafeCall(function()
        PlayerSettings.NoClip = not PlayerSettings.NoClip
        Notify("Player", "NoClip: " .. (PlayerSettings.NoClip and "ВКЛ" or "ВЫКЛ"), 2)
        
        local Character = GetCharacter()
        if not Character then return end
        
        if PlayerSettings.NoClip then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        else
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end, "ToggleNoClip")
end

-- ============ ФУНКЦИИ TELEPORT ============

local function TeleportToLocation(location)
    SafeCall(function()
        local HRP = GetHumanoidRootPart()
        if not HRP then
            Notify("Teleport", "Телепортация невозможна", 2)
            return
        end
        
        HRP.CFrame = CFrame.new(Vector3.new(location.x, location.y, location.z))
        Notify("Teleport", "Телепортирован на: " .. location.name, 2)
    end, "TeleportToLocation")
end

local function TeleportToPlayer(targetName)
    SafeCall(function()
        local HRP = GetHumanoidRootPart()
        if not HRP then return end
        
        local targetPlayer = game.Players:FindFirstChild(targetName)
        if targetPlayer and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HRP.CFrame = targetHRP.CFrame + Vector3.new(0, 0, 5)
                Notify("Teleport", "Телепортирован к: " .. targetName, 2)
            end
        else
            Notify("Teleport", "Игрок не найден", 2)
        end
    end, "TeleportToPlayer")
end

-- ============ ФУНКЦИИ MISC ============

local function ServerInfo()
    SafeCall(function()
        local Players = game.Players
        local PlayerCount = #Players:GetPlayers()
        local ServerName = game.JobId
        local info = "Игроков: " .. PlayerCount .. "\nID сервера: " .. ServerName:sub(1, 8) .. "..."
        Notify("Info", info, 4)
    end, "ServerInfo")
end

local function ClearChat()
    SafeCall(function()
        local ChatGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Chat")
        if ChatGui then
            ChatGui:Destroy()
            Notify("Misc", "Чат очищен", 2)
        end
    end, "ClearChat")
end

-- ============ СОЗДАНИЕ ВКЛАДОК МЕНЮ ============

-- Вкладка: Главная
local MainTab = Window:CreateTab("Главная", 4483362458)
MainTab:CreateLabel("Добро пожаловать в BloodyBlox!")
MainTab:CreateLabel("Версия: " .. BloodyBlox.Version)
MainTab:CreateButton({
    Name = "Информация о сервере",
    Callback = ServerInfo
})

-- Вкладка: Visual
local VisualTab = Window:CreateTab("Visual", 7734068571)
VisualTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        VisualSettings.ESPEnabled = Value
        if Value then EnableESP() else DisableESP() end
    end
})

VisualTab:CreateToggle({
    Name = "Chams",
    CurrentValue = false,
    Flag = "Chams_Toggle",
    Callback = ToggleChams
})

VisualTab:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "FOV_Toggle",
    Callback = ToggleFOVCircle
})

VisualTab:CreateSlider({
    Name = "Brightness",
    MinValue = 0,
    MaxValue = 2,
    CurrentValue = 1,
    Flag = "Brightness_Slider",
    Callback = function(Value)
        game.Lighting.Brightness = Value
    end
})

-- Вкладка: Farm
local FarmTab = Window:CreateTab("Farm", 7734068571)
FarmTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm_Toggle",
    Callback = function(Value)
        if Value then StartAutoFarm() else StopAutoFarm() end
    end
})

FarmTab:CreateButton({
    Name = "Собрать предметы рядом",
    Callback = CollectNearby
})

FarmTab:CreateSlider({
    Name = "Дальность фарма",
    MinValue = 10,
    MaxValue = 200,
    CurrentValue = 50,
    Flag = "FarmRange_Slider",
    Callback = function(Value)
        FarmSettings.FarmRange = Value
    end
})

-- Вкладка: Player
local PlayerTab = Window:CreateTab("Player", 7734068571)
PlayerTab:CreateButton({
    Name = "Infinite Jump",
    Callback = EnableInfiniteJump
})

PlayerTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "Speed_Toggle",
    Callback = ToggleSpeedBoost
})

PlayerTab:CreateSlider({
    Name = "Множитель скорости",
    MinValue = 1,
    MaxValue = 3,
    CurrentValue = 1.5,
    Flag = "SpeedMult_Slider",
    Callback = function(Value)
        PlayerSettings.SpeedMultiplier = Value
    end
})

PlayerTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "NoClip_Toggle",
    Callback = ToggleNoClip
})

-- Вкладка: Teleport
local TeleportTab = Window:CreateTab("Teleport", 7734068571)
for _, location in ipairs(TeleportLocations) do
    TeleportTab:CreateButton({
        Name = "Tp на " .. location.name,
        Callback = function()
            TeleportToLocation(location)
        end
    })
end

TeleportTab:CreateInput({
    Name = "Teleport к игроку",
    PlaceholderText = "Имя игрока",
    RemoveTextmarginInBox = false,
    Flag = "TeleportPlayer_Input",
    Callback = function(Value)
        if Value ~= "" then
            TeleportToPlayer(Value)
        end
    end
})

-- Вкладка: Misc
local MiscTab = Window:CreateTab("Misc", 7734068571)
MiscTab:CreateButton({
    Name = "Очистить чат",
    Callback = ClearChat
})

MiscTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "Debug_Toggle",
    Callback = function(Value)
        MiscSettings.DebugMode = Value
        if Value then
            print("[BloodyBlox] Debug Mode активирован")
        end
    end
})

-- Вкладка: Settings
local SettingsTab = Window:CreateTab("Settings", 6023426789)
SettingsTab:CreateButton({
    Name = "Закрыть меню",
    Callback = function()
        Window:Close()
        BloodyBlox.MenuOpen = false
    end
})

SettingsTab:CreateLabel("BloodyBlox v" .. BloodyBlox.Version)
SettingsTab:CreateLabel("Автор: dj")
SettingsTab:CreateLabel("Нажми Insert для открытия/закрытия меню")

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

-- ============ ЗАВЕРШЕНИЕ ============

print("[BloodyBlox] Скрипт загружен успешно!")
print("[BloodyBlox] Нажми Insert для открытия меню")
Notify("BloodyBlox", "Скрипт загружен! Нажми Insert", 4)

return BloodyBlox
