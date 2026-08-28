--[[
    BloodyBlox v3.2 - Muscle Legends Exploit
    Minimal Safe Version - Guaranteed Load
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

print("[BloodyBlox] Script starting...")

-- ============ SAFE BYPASS (NO METAMETHOD HOOKS) ============

local function SafeBypass()
    print("[BloodyBlox] Applying safe bypass...")

    -- Remove executor traces silently
    pcall(function()
        local traces = {"syn", "Synapse", "KRNL_LOADED", "SENTINEL_LOADED"}
        for _, trace in ipairs(traces) do
            _G[trace] = nil
            if getgenv then getgenv()[trace] = nil end
        end
    end)

    print("[BloodyBlox] Bypass applied")
end

SafeBypass()

-- Small delay
task.wait(0.5)
print("[BloodyBlox] Creating UI...")

-- ============ CORE FRAMEWORK ============

local BloodyBlox = {
    Version = "3.2.0",
    MenuOpen = false,
    Player = game:GetService("Players").LocalPlayer,
    Settings = {
        FastFarm = false,
        AutoWeight = false,
        AutoRebirth = false,
        WalkSpeed = 16,
        JumpPower = 50,
        Fly = false,
        Noclip = false,
        InfiniteJump = false,
        GodMode = false,
        AntiAFK = false,
        Debug = false
    },
    Connections = {}
}

print("[BloodyBlox] Framework initialized")

-- ============ UTILITY FUNCTIONS ============

function BloodyBlox:GetCharacter()
    return self.Player.Character or self.Player:WaitForChild("Character", 5)
end

function BloodyBlox:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("Humanoid")
end

function BloodyBlox:GetHumanoidRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============ EMBEDDED UI ============

local UI = {}
UI.__index = UI

function UI:Create()
    print("[BloodyBlox] Creating ScreenGui...")
    local self = setmetatable({}, UI)

    -- Create ScreenGui in PlayerGui (safer than CoreGui)
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloodyBloxUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 500, 0, 350)
    self.MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.Parent = self.ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.MainFrame

    -- Title Bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 35)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = self.TitleBar

    -- Title Text
    self.TitleText = Instance.new("TextLabel")
    self.TitleText.Size = UDim2.new(1, -80, 1, 0)
    self.TitleText.Position = UDim2.new(0, 10, 0, 0)
    self.TitleText.BackgroundTransparency = 1
    self.TitleText.Text = "BloodyBlox v" .. BloodyBlox.Version
    self.TitleText.TextColor3 = Color3.fromRGB(255, 50, 50)
    self.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleText.Font = Enum.Font.GothamBold
    self.TitleText.TextSize = 16
    self.TitleText.Parent = self.TitleBar

    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0, 35, 0, 35)
    self.CloseButton.Position = UDim2.new(1, -35, 0, 0)
    self.CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Text = "X"
    self.CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.TextSize = 18
    self.CloseButton.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = self.CloseButton

    self.CloseButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Tab Container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Size = UDim2.new(0, 110, 1, -45)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 40)
    self.TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.Parent = self.MainFrame

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = self.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabContainer

    -- Content Container
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -125, 1, -45)
    self.ContentContainer.Position = UDim2.new(0, 120, 0, 40)
    self.ContentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.Parent = self.MainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = self.ContentContainer

    self.Tabs = {}
    self.ActiveTab = nil

    -- Parent to PlayerGui
    self.ScreenGui.Parent = BloodyBlox.Player:WaitForChild("PlayerGui")

    print("[BloodyBlox] UI created successfully")
    return self
end

function UI:CreateTab(name)
    local tab = {}

    -- Tab Button
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, -6, 0, 32)
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = 13
    tabButton.Parent = self.TabContainer

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = tabButton

    -- Tab Content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -10, 1, -10)
    tabContent.Position = UDim2.new(0, 5, 0, 5)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 4
    tabContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    tabContent.Visible = false
    tabContent.Parent = self.ContentContainer

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent

    tab.Button = tabButton
    tab.Content = tabContent

    tabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
    end)

    self.Tabs[name] = tab

    if not self.ActiveTab then
        self:SwitchTab(name)
    end

    return tab
end

function UI:SwitchTab(name)
    for tabName, tab in pairs(self.Tabs) do
        if tabName == name then
            tab.Content.Visible = true
            tab.Button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            self.ActiveTab = name
        else
            tab.Content.Visible = false
            tab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

function UI:AddLabel(tab, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab.Content
    return label
end

function UI:AddToggle(tab, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 45, 0, 25)
    toggle.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggle.BackgroundColor3 = default and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 11
    toggle.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggle

    local state = default

    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        callback(state)
    end)

    return toggle
end

function UI:AddButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

function UI:AddSlider(tab, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 55)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -20, 0, 8)
    sliderBack.Position = UDim2.new(0, 10, 1, -18)
    sliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderBack

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill

    local dragging = false

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. value
        callback(value)
    end

    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)

    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)

    return container
end

function UI:Toggle()
    self.ScreenGui.Enabled = not self.ScreenGui.Enabled
    BloodyBlox.MenuOpen = self.ScreenGui.Enabled
end

print("[BloodyBlox] UI module loaded")

-- ============ FARM FUNCTIONS ============

local Farm = {}

function Farm:FastFarm()
    while BloodyBlox.Settings.FastFarm do
        task.wait(0.1)
        pcall(function()
            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                    local name = gui.Name:lower()
                    if name:find("train") or name:find("click") then
                        for i = 1, 3 do
                            gui.MouseButton1Click:Fire()
                            task.wait(0.03)
                        end
                        break
                    end
                end
            end
        end)
    end
end

function Farm:AutoWeight()
    while BloodyBlox.Settings.AutoWeight do
        task.wait(0.3)
        pcall(function()
            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("weight") then
                        gui.MouseButton1Click:Fire()
                        task.wait(0.5)
                        break
                    end
                end
            end
        end)
    end
end

function Farm:AutoRebirth()
    while BloodyBlox.Settings.AutoRebirth do
        task.wait(1)
        pcall(function()
            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("rebirth") then
                        gui.MouseButton1Click:Fire()
                        task.wait(2)
                        break
                    end
                end
            end
        end)
    end
end

print("[BloodyBlox] Farm module loaded")

-- ============ PLAYER MODIFICATIONS ============

local Player = {}

function Player:SetWalkSpeed(speed)
    local humanoid = BloodyBlox:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

function Player:SetJumpPower(power)
    local humanoid = BloodyBlox:GetHumanoid()
    if humanoid then
        humanoid.JumpPower = power
    end
end

function Player:ToggleFly(enabled)
    if enabled then
        local flyConnection
        flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if not BloodyBlox.Settings.Fly then
                flyConnection:Disconnect()
                return
            end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if hrp then
                local UIS = game:GetService("UserInputService")
                local velocity = Vector3.new(0, 0, 0)

                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    velocity = velocity + (workspace.CurrentCamera.CFrame.LookVector * 2)
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    velocity = velocity - (workspace.CurrentCamera.CFrame.LookVector * 2)
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    velocity = velocity - (workspace.CurrentCamera.CFrame.RightVector * 2)
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    velocity = velocity + (workspace.CurrentCamera.CFrame.RightVector * 2)
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    velocity = velocity + Vector3.new(0, 2, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                    velocity = velocity - Vector3.new(0, 2, 0)
                end

                hrp.Velocity = velocity * 20
            end
        end)

        table.insert(BloodyBlox.Connections, flyConnection)
    end
end

function Player:ToggleNoclip(enabled)
    if enabled then
        local noclipConnection
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            if not BloodyBlox.Settings.Noclip then
                noclipConnection:Disconnect()
                return
            end

            local char = BloodyBlox:GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        table.insert(BloodyBlox.Connections, noclipConnection)
    end
end

function Player:ToggleInfiniteJump(enabled)
    if enabled then
        local infJumpConnection
        infJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
            if not BloodyBlox.Settings.InfiniteJump then
                infJumpConnection:Disconnect()
                return
            end

            local humanoid = BloodyBlox:GetHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)

        table.insert(BloodyBlox.Connections, infJumpConnection)
    end
end

function Player:ToggleGodMode(enabled)
    local humanoid = BloodyBlox:GetHumanoid()
    if humanoid then
        if enabled then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        else
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
end

print("[BloodyBlox] Player module loaded")

-- ============ MISC FUNCTIONS ============

local Misc = {}

function Misc:AntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    BloodyBlox.Player.Idled:Connect(function()
        if BloodyBlox.Settings.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

function Misc:UnlockFPS()
    pcall(function()
        setfpscap(999)
    end)
end

print("[BloodyBlox] Misc module loaded")

-- ============ CREATE UI ============

print("[BloodyBlox] Building interface...")

local MainUI = UI:Create()

-- Main Tab
local MainTab = MainUI:CreateTab("Main")
MainUI:AddLabel(MainTab, "BloodyBlox v" .. BloodyBlox.Version)
MainUI:AddLabel(MainTab, "Muscle Legends Exploit")
MainUI:AddLabel(MainTab, "Press INSERT to toggle menu")
MainUI:AddButton(MainTab, "Test Button", function()
    print("[BloodyBlox] Button clicked!")
end)

-- Farm Tab
local FarmTab = MainUI:CreateTab("Farm")
MainUI:AddToggle(FarmTab, "Fast Farm", false, function(value)
    BloodyBlox.Settings.FastFarm = value
    if value then
        task.spawn(function() Farm:FastFarm() end)
    end
end)
MainUI:AddToggle(FarmTab, "Auto Weight", false, function(value)
    BloodyBlox.Settings.AutoWeight = value
    if value then
        task.spawn(function() Farm:AutoWeight() end)
    end
end)
MainUI:AddToggle(FarmTab, "Auto Rebirth", false, function(value)
    BloodyBlox.Settings.AutoRebirth = value
    if value then
        task.spawn(function() Farm:AutoRebirth() end)
    end
end)

-- Player Tab
local PlayerTab = MainUI:CreateTab("Player")
MainUI:AddSlider(PlayerTab, "Walk Speed", 16, 200, 16, function(value)
    BloodyBlox.Settings.WalkSpeed = value
    Player:SetWalkSpeed(value)
end)
MainUI:AddSlider(PlayerTab, "Jump Power", 50, 200, 50, function(value)
    BloodyBlox.Settings.JumpPower = value
    Player:SetJumpPower(value)
end)
MainUI:AddToggle(PlayerTab, "Fly (WASD + Space/Shift)", false, function(value)
    BloodyBlox.Settings.Fly = value
    Player:ToggleFly(value)
end)
MainUI:AddToggle(PlayerTab, "Noclip", false, function(value)
    BloodyBlox.Settings.Noclip = value
    Player:ToggleNoclip(value)
end)
MainUI:AddToggle(PlayerTab, "Infinite Jump", false, function(value)
    BloodyBlox.Settings.InfiniteJump = value
    Player:ToggleInfiniteJump(value)
end)
MainUI:AddToggle(PlayerTab, "God Mode", false, function(value)
    BloodyBlox.Settings.GodMode = value
    Player:ToggleGodMode(value)
end)

-- Misc Tab
local MiscTab = MainUI:CreateTab("Misc")
MainUI:AddToggle(MiscTab, "Anti-AFK", false, function(value)
    BloodyBlox.Settings.AntiAFK = value
    if value then
        Misc:AntiAFK()
    end
end)
MainUI:AddButton(MiscTab, "Unlock FPS", function()
    Misc:UnlockFPS()
end)

-- Settings Tab
local SettingsTab = MainUI:CreateTab("Settings")
MainUI:AddButton(SettingsTab, "Disable All Features", function()
    BloodyBlox.Settings.FastFarm = false
    BloodyBlox.Settings.AutoWeight = false
    BloodyBlox.Settings.AutoRebirth = false
    BloodyBlox.Settings.Fly = false
    BloodyBlox.Settings.Noclip = false
    BloodyBlox.Settings.InfiniteJump = false
    BloodyBlox.Settings.GodMode = false

    for _, connection in ipairs(BloodyBlox.Connections) do
        connection:Disconnect()
    end
    BloodyBlox.Connections = {}
end)
MainUI:AddButton(SettingsTab, "Close Menu", function()
    MainUI:Toggle()
end)
MainUI:AddLabel(SettingsTab, "Version: " .. BloodyBlox.Version)

print("[BloodyBlox] All tabs created")

-- ============ MENU TOGGLE ============

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        MainUI:Toggle()
    end
end)

-- Character respawn handler
BloodyBlox.Player.CharacterAdded:Connect(function(character)
    task.wait(1)

    if BloodyBlox.Settings.WalkSpeed ~= 16 then
        Player:SetWalkSpeed(BloodyBlox.Settings.WalkSpeed)
    end
    if BloodyBlox.Settings.JumpPower ~= 50 then
        Player:SetJumpPower(BloodyBlox.Settings.JumpPower)
    end
    if BloodyBlox.Settings.GodMode then
        Player:ToggleGodMode(true)
    end
end)

print("[BloodyBlox] Script loaded successfully!")
print("[BloodyBlox] Press INSERT to open menu")

return BloodyBlox
