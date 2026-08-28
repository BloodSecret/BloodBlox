--[[
    BloodyBlox v3.3 - Muscle Legends Exploit
    Complete Redesign - Fixed Functions
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

-- ============ SINGLETON PROTECTION ============

if _G.BloodyBloxLoaded then
    warn("[BloodyBlox] Already running! Close existing instance first.")
    return
end

_G.BloodyBloxLoaded = true

print("[BloodyBlox] Script starting...")

-- ============ SAFE BYPASS ============

local function SafeBypass()
    print("[BloodyBlox] Applying bypass...")
    pcall(function()
        local traces = {"syn", "Synapse", "KRNL_LOADED", "SENTINEL_LOADED", "SCRIPTWARE_LOADED"}
        for _, trace in ipairs(traces) do
            _G[trace] = nil
            if getgenv then getgenv()[trace] = nil end
        end
    end)
    print("[BloodyBlox] Bypass applied")
end

SafeBypass()

-- Auto-enable FPS unlock and Anti-AFK immediately
pcall(function() setfpscap(999) end)
print("[BloodyBlox] FPS unlocked automatically")

task.wait(0.3)

-- ============ CORE FRAMEWORK ============

local BloodyBlox = {
    Version = "3.3.0",
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
        Debug = false
    },
    Logs = {},
    Connections = {}
}

-- Auto Anti-AFK
local VirtualUser = game:GetService("VirtualUser")
BloodyBlox.Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
print("[BloodyBlox] Anti-AFK enabled automatically")

-- ============ LOGGING SYSTEM ============

function BloodyBlox:Log(category, message, level)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        time = timestamp,
        category = category,
        message = message,
        level = level or "info"
    }

    table.insert(self.Logs, logEntry)

    if #self.Logs > 50 then
        table.remove(self.Logs, 1)
    end

    print(string.format("[%s][%s] %s", timestamp, category, message))
end

-- ============ UTILITY FUNCTIONS ============

function BloodyBlox:GetCharacter()
    return self.Player.Character or self.Player.CharacterAdded:Wait()
end

function BloodyBlox:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BloodyBlox:GetHumanoidRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============ MODERN UI LIBRARY ============

local UI = {}
UI.__index = UI

function UI:Create()
    print("[BloodyBlox] Creating transparent UI with background...")
    local self = setmetatable({}, UI)

    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloodyBloxUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.DisplayOrder = 999

    -- Main Container (transparent)
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 600, 0, 400)
    self.MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    self.MainFrame.BackgroundTransparency = 0.15  -- Slightly transparent
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = self.MainFrame

    -- Background Image (non-transparent)
    local background = Instance.new("ImageLabel")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundTransparency = 1
    background.ScaleType = Enum.ScaleType.Crop
    background.ImageTransparency = 0  -- Fully opaque
    background.ZIndex = 0
    background.Parent = self.MainFrame

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 12)
    bgCorner.Parent = background

    -- Try to load background image from file
    pcall(function()
        local bgPath = "C:\\Roblox\\background.png"
        if isfile and readfile and isfile(bgPath) then
            local bgData = readfile(bgPath)
            -- Try to use getcustomasset if available
            if getcustomasset then
                background.Image = getcustomasset(bgPath)
                print("[BloodyBlox] Background loaded from file")
            elseif getsynasset then
                background.Image = getsynasset(bgPath)
                print("[BloodyBlox] Background loaded from file")
            else
                -- Fallback: use dark gradient
                background.Image = ""
                background.BackgroundTransparency = 0
                background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)

                local gradient = Instance.new("UIGradient")
                gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 20)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 20))
                }
                gradient.Rotation = 45
                gradient.Parent = background
                print("[BloodyBlox] Using gradient background (getcustomasset not available)")
            end
        else
            -- Fallback: dark gradient
            background.Image = ""
            background.BackgroundTransparency = 0
            background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)

            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 20)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 20))
            }
            gradient.Rotation = 45
            gradient.Parent = background
            print("[BloodyBlox] Background file not found, using gradient")
        end
    end)

    -- Blur overlay for glassmorphism effect
    local blurOverlay = Instance.new("Frame")
    blurOverlay.Size = UDim2.new(1, 0, 1, 0)
    blurOverlay.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    blurOverlay.BackgroundTransparency = 0.3  -- Semi-transparent for blur effect
    blurOverlay.BorderSizePixel = 0
    blurOverlay.ZIndex = 1
    blurOverlay.Parent = self.MainFrame

    local blurCorner = Instance.new("UICorner")
    blurCorner.CornerRadius = UDim.new(0, 12)
    blurCorner.Parent = blurOverlay

    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    accentLine.BackgroundTransparency = 0.2
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 3
    accentLine.Parent = self.MainFrame

    -- Header
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 50)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 3)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.TitleBar.BackgroundTransparency = 0.3
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.ZIndex = 2
    self.TitleBar.Parent = self.MainFrame

    -- Logo/Title
    self.TitleText = Instance.new("TextLabel")
    self.TitleText.Size = UDim2.new(0, 250, 1, 0)
    self.TitleText.Position = UDim2.new(0, 20, 0, 0)
    self.TitleText.BackgroundTransparency = 1
    self.TitleText.Text = "BLOODYBLOX"
    self.TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleText.Font = Enum.Font.GothamBold
    self.TitleText.TextSize = 20
    self.TitleText.TextStrokeTransparency = 0.8
    self.TitleText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.TitleText.ZIndex = 3
    self.TitleText.Parent = self.TitleBar

    -- Version tag
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 60, 0, 18)
    versionLabel.Position = UDim2.new(0, 200, 0.5, -9)
    versionLabel.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    versionLabel.BackgroundTransparency = 0.2
    versionLabel.Text = "v" .. BloodyBlox.Version
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 11
    versionLabel.ZIndex = 3
    versionLabel.Parent = self.TitleBar

    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 4)
    versionCorner.Parent = versionLabel

    -- Control buttons
    self.MinimizeButton = Instance.new("TextButton")
    self.MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
    self.MinimizeButton.Position = UDim2.new(1, -80, 0.5, -17.5)
    self.MinimizeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.MinimizeButton.BackgroundTransparency = 0.3
    self.MinimizeButton.BorderSizePixel = 0
    self.MinimizeButton.Text = "—"
    self.MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.MinimizeButton.Font = Enum.Font.GothamBold
    self.MinimizeButton.TextSize = 16
    self.MinimizeButton.ZIndex = 3
    self.MinimizeButton.Parent = self.TitleBar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = self.MinimizeButton

    self.MinimizeButton.MouseEnter:Connect(function()
        self.MinimizeButton.BackgroundTransparency = 0.1
    end)
    self.MinimizeButton.MouseLeave:Connect(function()
        self.MinimizeButton.BackgroundTransparency = 0.3
    end)
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.ScreenGui.Enabled = false
        BloodyBlox.MenuOpen = false
    end)

    self.ExitButton = Instance.new("TextButton")
    self.ExitButton.Size = UDim2.new(0, 35, 0, 35)
    self.ExitButton.Position = UDim2.new(1, -40, 0.5, -17.5)
    self.ExitButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.ExitButton.BackgroundTransparency = 0.3
    self.ExitButton.BorderSizePixel = 0
    self.ExitButton.Text = "×"
    self.ExitButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.ExitButton.Font = Enum.Font.GothamBold
    self.ExitButton.TextSize = 20
    self.ExitButton.ZIndex = 3
    self.ExitButton.Parent = self.TitleBar

    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 6)
    exitCorner.Parent = self.ExitButton

    self.ExitButton.MouseEnter:Connect(function()
        self.ExitButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        self.ExitButton.BackgroundTransparency = 0.1
    end)
    self.ExitButton.MouseLeave:Connect(function()
        self.ExitButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        self.ExitButton.BackgroundTransparency = 0.3
    end)
    self.ExitButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    -- Sidebar for tabs (semi-transparent)
    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Size = UDim2.new(0, 140, 1, -65)
    self.TabContainer.Position = UDim2.new(0, 10, 0, 58)
    self.TabContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.TabContainer.BackgroundTransparency = 0.3
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.ScrollBarThickness = 0
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContainer.ZIndex = 2
    self.TabContainer.Parent = self.MainFrame

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 8)
    sidebarCorner.Parent = self.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingLeft = UDim.new(0, 8)
    tabPadding.PaddingRight = UDim.new(0, 8)
    tabPadding.PaddingBottom = UDim.new(0, 8)
    tabPadding.Parent = self.TabContainer

    -- Content area (semi-transparent)
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -170, 1, -65)
    self.ContentContainer.Position = UDim2.new(0, 160, 0, 58)
    self.ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.ContentContainer.BackgroundTransparency = 0.3
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.ZIndex = 2
    self.ContentContainer.Parent = self.MainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = self.ContentContainer

    self.Tabs = {}
    self.ActiveTab = nil

    self.ScreenGui.Parent = BloodyBlox.Player:WaitForChild("PlayerGui")

    print("[BloodyBlox] Transparent UI with background created")
    return self
end

function UI:CreateTab(name)
    local tab = {}

    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(1, 0, 0, 36)
    tabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(160, 160, 165)
    tabButton.Font = Enum.Font.GothamSemibold
    tabButton.TextSize = 14
    tabButton.TextXAlignment = Enum.TextXAlignment.Left
    tabButton.Parent = self.TabContainer

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = tabButton

    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 12)
    buttonPadding.Parent = tabButton

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -20, 1, -20)
    tabContent.Position = UDim2.new(0, 10, 0, 10)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 4
    tabContent.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
    tabContent.Visible = false
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContent.Parent = self.ContentContainer

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tabContent

    tab.Button = tabButton
    tab.Content = tabContent

    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= name then
            tabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= name then
            tabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        end
    end)

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
            tab.Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
            tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
            self.ActiveTab = name
        else
            tab.Content.Visible = false
            tab.Button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            tab.Button.TextColor3 = Color3.fromRGB(160, 160, 165)
        end
    end
end

function UI:AddLabel(tab, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 205)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab.Content
    return label
end

function UI:AddToggle(tab, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 42)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    -- Toggle switch background
    local toggleBG = Instance.new("Frame")
    toggleBG.Size = UDim2.new(0, 48, 0, 26)
    toggleBG.Position = UDim2.new(1, -60, 0.5, -13)
    toggleBG.BackgroundColor3 = default and Color3.fromRGB(139, 0, 0) or Color3.fromRGB(40, 40, 45)
    toggleBG.BorderSizePixel = 0
    toggleBG.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = toggleBG

    -- Toggle circle
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBG

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, 0, 1, 0)
    toggle.BackgroundTransparency = 1
    toggle.Text = ""
    toggle.Parent = toggleBG

    local state = default

    toggle.MouseButton1Click:Connect(function()
        state = not state

        toggleBG.BackgroundColor3 = state and Color3.fromRGB(139, 0, 0) or Color3.fromRGB(40, 40, 45)
        toggleCircle:TweenPosition(
            state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )

        callback(state)
    end)

    return toggle
end

function UI:AddButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 42)
    button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
    end)

    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end)

    button.MouseButton1Click:Connect(callback)

    return button
end

function UI:AddSlider(tab, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 65)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 0, 26)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 205)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 26)
    valueLabel.Position = UDim2.new(1, -74, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(139, 0, 0)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -28, 0, 6)
    sliderBack.Position = UDim2.new(0, 14, 1, -18)
    sliderBack.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBack

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill

    local dragging = false

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(value)
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

function UI:AddTextBox(tab, placeholder, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 42)
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, -24, 1, 0)
    textbox.Position = UDim2.new(0, 12, 0, 0)
    textbox.BackgroundTransparency = 1
    textbox.PlaceholderText = placeholder
    textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
    textbox.Text = ""
    textbox.TextColor3 = Color3.fromRGB(220, 220, 225)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 13
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.ClearTextOnFocus = false
    textbox.Parent = container

    textbox.Focused:Connect(function()
        container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    end)

    textbox.FocusLost:Connect(function()
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        callback(textbox.Text)
    end)

    return textbox
end

function UI:Destroy()
    _G.BloodyBloxLoaded = false

    -- Disable all features
    BloodyBlox.Settings.FastFarm = false
    BloodyBlox.Settings.AutoWeight = false
    BloodyBlox.Settings.AutoRebirth = false
    BloodyBlox.Settings.Fly = false
    BloodyBlox.Settings.Noclip = false
    BloodyBlox.Settings.InfiniteJump = false
    BloodyBlox.Settings.GodMode = false

    -- Disconnect all connections
    for _, connection in ipairs(BloodyBlox.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    BloodyBlox.Connections = {}

    -- Destroy UI
    self.ScreenGui:Destroy()

    print("[BloodyBlox] Exited successfully")
end

print("[BloodyBlox] UI module loaded")

-- ============ FARM FUNCTIONS (FIXED FOR MUSCLE LEGENDS) ============

local Farm = {}

function Farm:FastFarm()
    BloodyBlox:Log("FastFarm", "Started", "info")

    while BloodyBlox.Settings.FastFarm do
        task.wait(0.05)

        pcall(function()
            -- Method 1: Direct VirtualInputManager (most reliable)
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)

            -- Method 2: Find and fire RemoteEvents
            local RS = game:GetService("ReplicatedStorage")
            for _, obj in pairs(RS:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    local name = obj.Name:lower()
                    if name:find("click") or name:find("train") or name:find("add") or name:find("gain") then
                        obj:FireServer()
                    end
                end
            end
        end)
    end

    BloodyBlox:Log("FastFarm", "Stopped", "info")
end

function Farm:AutoWeight()
    BloodyBlox:Log("AutoWeight", "Started", "info")

    while BloodyBlox.Settings.AutoWeight do
        task.wait(0.5)

        pcall(function()
            local RS = game:GetService("ReplicatedStorage")

            -- Find weight/equipment remotes
            for _, obj in pairs(RS:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = obj.Name:lower()
                    if name:find("weight") or name:find("equip") or name:find("tool") then
                        if obj:IsA("RemoteEvent") then
                            obj:FireServer("Heavy") -- Common parameter
                            obj:FireServer("MAX")
                            obj:FireServer(999999)
                        else
                            pcall(function() obj:InvokeServer("Heavy") end)
                            pcall(function() obj:InvokeServer("MAX") end)
                        end
                    end
                end
            end
        end)
    end

    BloodyBlox:Log("AutoWeight", "Stopped", "info")
end

function Farm:AutoRebirth()
    BloodyBlox:Log("AutoRebirth", "Started", "info")

    while BloodyBlox.Settings.AutoRebirth do
        task.wait(2)

        pcall(function()
            local RS = game:GetService("ReplicatedStorage")

            -- Find rebirth remotes
            for _, obj in pairs(RS:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = obj.Name:lower()
                    if name:find("rebirth") or name:find("prestige") or name:find("reset") then
                        if obj:IsA("RemoteEvent") then
                            obj:FireServer()
                            BloodyBlox:Log("AutoRebirth", "Rebirth attempted", "info")
                        else
                            pcall(function()
                                obj:InvokeServer()
                                BloodyBlox:Log("AutoRebirth", "Rebirth attempted", "info")
                            end)
                        end
                        task.wait(3)
                    end
                end
            end
        end)
    end

    BloodyBlox:Log("AutoRebirth", "Stopped", "info")
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

                if UIS:IsKeyDown(Enum.KeyCode.W) then velocity = velocity + (workspace.CurrentCamera.CFrame.LookVector * 2) end
                if UIS:IsKeyDown(Enum.KeyCode.S) then velocity = velocity - (workspace.CurrentCamera.CFrame.LookVector * 2) end
                if UIS:IsKeyDown(Enum.KeyCode.A) then velocity = velocity - (workspace.CurrentCamera.CFrame.RightVector * 2) end
                if UIS:IsKeyDown(Enum.KeyCode.D) then velocity = velocity + (workspace.CurrentCamera.CFrame.RightVector * 2) end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then velocity = velocity + Vector3.new(0, 2, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then velocity = velocity - Vector3.new(0, 2, 0) end

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

-- ============ CONFIG SYSTEM ============

local Config = {}

function Config:Save(configName)
    if configName == "" then return end

    local configData = {
        Settings = BloodyBlox.Settings,
        Version = BloodyBlox.Version
    }

    pcall(function()
        writefile("BloodyBlox_" .. configName .. ".json", game:GetService("HttpService"):JSONEncode(configData))
        BloodyBlox:Log("Config", "Saved: " .. configName, "info")
    end)
end

function Config:Load(configName)
    if configName == "" then return end

    pcall(function()
        local configData = game:GetService("HttpService"):JSONDecode(readfile("BloodyBlox_" .. configName .. ".json"))
        BloodyBlox.Settings = configData.Settings
        BloodyBlox:Log("Config", "Loaded: " .. configName, "info")
    end)
end

function Config:Delete(configName)
    if configName == "" then return end

    pcall(function()
        delfile("BloodyBlox_" .. configName .. ".json")
        BloodyBlox:Log("Config", "Deleted: " .. configName, "info")
    end)
end

print("[BloodyBlox] Config module loaded")

-- ============ CREATE MODERN UI ============

print("[BloodyBlox] Building modern interface...")

local MainUI = UI:Create()

-- Main Tab
local MainTab = MainUI:CreateTab("Main")
MainUI:AddLabel(MainTab, "BLOODYBLOX v" .. BloodyBlox.Version)
MainUI:AddLabel(MainTab, "Muscle Legends Exploit")
MainUI:AddLabel(MainTab, "")
MainUI:AddLabel(MainTab, "✓ Anti-AFK: Auto-Enabled")
MainUI:AddLabel(MainTab, "✓ FPS Unlock: Auto-Enabled")
MainUI:AddLabel(MainTab, "")
MainUI:AddLabel(MainTab, "Press INSERT to toggle menu")

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

-- Rebirth Tab
local RebirthTab = MainUI:CreateTab("Rebirth")
MainUI:AddToggle(RebirthTab, "Auto Rebirth", false, function(value)
    BloodyBlox.Settings.AutoRebirth = value
    if value then
        task.spawn(function() Farm:AutoRebirth() end)
    end
end)
MainUI:AddLabel(RebirthTab, "")
MainUI:AddLabel(RebirthTab, "Auto rebirth will trigger when available")

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

-- Config Tab
local ConfigTab = MainUI:CreateTab("Config")
local configNameInput = ""
MainUI:AddLabel(ConfigTab, "Config Manager")
MainUI:AddTextBox(ConfigTab, "Enter config name...", function(text)
    configNameInput = text
end)
MainUI:AddButton(ConfigTab, "Save Config", function()
    Config:Save(configNameInput)
end)
MainUI:AddButton(ConfigTab, "Load Config", function()
    Config:Load(configNameInput)
end)
MainUI:AddButton(ConfigTab, "Delete Config", function()
    Config:Delete(configNameInput)
end)

-- Logs Tab
local LogsTab = MainUI:CreateTab("Logs")
MainUI:AddLabel(LogsTab, "Recent Logs (Last 20)")
MainUI:AddButton(LogsTab, "Refresh Logs", function()
    local logCount = math.min(#BloodyBlox.Logs, 20)
    print("\n========== BloodyBlox Logs ==========")
    for i = math.max(1, #BloodyBlox.Logs - logCount + 1), #BloodyBlox.Logs do
        local log = BloodyBlox.Logs[i]
        print(string.format("[%s][%s] %s", log.time, log.category, log.message))
    end
    print("=====================================\n")
end)
MainUI:AddButton(LogsTab, "Clear Logs", function()
    BloodyBlox.Logs = {}
    BloodyBlox:Log("Logs", "Cleared all logs", "info")
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
        pcall(function() connection:Disconnect() end)
    end
    BloodyBlox.Connections = {}

    BloodyBlox:Log("Settings", "All features disabled", "info")
end)
MainUI:AddLabel(SettingsTab, "")
MainUI:AddLabel(SettingsTab, "Version: " .. BloodyBlox.Version)
MainUI:AddLabel(SettingsTab, "Anti-Detection: ACTIVE")

print("[BloodyBlox] All tabs created")

-- ============ MENU TOGGLE ============

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        MainUI.ScreenGui.Enabled = not MainUI.ScreenGui.Enabled
        BloodyBlox.MenuOpen = MainUI.ScreenGui.Enabled
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
print("[BloodyBlox] Anti-AFK and FPS Unlock are AUTO-ENABLED")

return BloodyBlox
