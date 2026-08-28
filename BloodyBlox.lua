--[[
    BloodyBlox v3.1 - Muscle Legends Exploit
    Embedded UI - Zero External Loads
    Game: Muscle Legends
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

-- ============ ADVANCED ANTI-DETECTION BYPASS ============

local Bypass = {
    Hooked = false,
    OriginalFunctions = {},
    DetectionAttempts = 0,
    LastDetection = 0
}

-- Execute bypass BEFORE anything else
function Bypass:Initialize()
    -- Protect metamethods
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local old_namecall = mt.__namecall
    local old_index = mt.__index

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self):lower()
            if name:find("anticheat") or name:find("detect") or name:find("log") or name:find("report") or name:find("kick") then
                return wait(9e9)
            end
        end

        return old_namecall(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        if key == "BloodyBlox" or key == "Exploit" or key == "Cheat" then
            return nil
        end
        return old_index(self, key)
    end)

    setreadonly(mt, true)

    -- Remove executor traces
    local traces = {
        "syn", "Synapse", "KRNL_LOADED", "SENTINEL_LOADED",
        "SCRIPTWARE_LOADED", "getexecutorname", "identifyexecutor",
        "is_sirhurt_closure", "issentinelclosure", "is_synapse_function",
        "PROTOSMASHER_LOADED", "ELYSIAN_LOADED"
    }

    for _, trace in ipairs(traces) do
        pcall(function()
            _G[trace] = nil
            getgenv()[trace] = nil
        end)
    end

    self.Hooked = true
end

-- Initialize bypass immediately
Bypass:Initialize()

-- Delay to avoid instant detection
task.wait(math.random(300, 700) / 1000)

-- ============ CORE FRAMEWORK ============

local BloodyBlox = {
    Version = "3.1.0",
    MenuOpen = false,
    Services = {},
    Player = nil,
    Character = nil,
    Humanoid = nil,
    HumanoidRootPart = nil,

    Settings = {
        ESP_Enabled = false,
        ESP_Boxes = true,
        ESP_Tracers = true,
        ESP_Names = true,
        ESP_HealthBars = true,
        ESP_Distance = true,
        ESP_TeamCheck = false,

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
        UnlockFPS = false,

        Debug = false
    },

    Logs = {},
    ESP_Objects = {},
    Connections = {}
}

-- ============ EMBEDDED UI LIBRARY ============

local UI = {}
UI.__index = UI

function UI:Create()
    local self = setmetatable({}, UI)

    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = game:GetService("HttpService"):GenerateGUID(false)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 550, 0, 400)
    self.MainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.Parent = self.ScreenGui

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = self.MainFrame

    -- Title Bar
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.Parent = self.MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = self.TitleBar

    -- Title Text
    self.TitleText = Instance.new("TextLabel")
    self.TitleText.Name = "TitleText"
    self.TitleText.Size = UDim2.new(1, -10, 1, 0)
    self.TitleText.Position = UDim2.new(0, 10, 0, 0)
    self.TitleText.BackgroundTransparency = 1
    self.TitleText.Text = "BloodyBlox v" .. BloodyBlox.Version
    self.TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleText.Font = Enum.Font.GothamBold
    self.TitleText.TextSize = 14
    self.TitleText.Parent = self.TitleBar

    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 30, 0, 30)
    self.CloseButton.Position = UDim2.new(1, -30, 0, 0)
    self.CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Text = "X"
    self.CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.TextSize = 14
    self.CloseButton.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = self.CloseButton

    self.CloseButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Tab Container
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer.Size = UDim2.new(0, 120, 1, -40)
    self.TabContainer.Position = UDim2.new(0, 5, 0, 35)
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
    self.ContentContainer.Name = "ContentContainer"
    self.ContentContainer.Size = UDim2.new(1, -135, 1, -40)
    self.ContentContainer.Position = UDim2.new(0, 130, 0, 35)
    self.ContentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.Parent = self.MainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = self.ContentContainer

    self.Tabs = {}
    self.ActiveTab = nil

    self.ScreenGui.Parent = game:GetService("CoreGui")

    return self
end

function UI:CreateTab(name)
    local tab = {}

    -- Tab Button
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name .. "Tab"
    tabButton.Size = UDim2.new(1, -6, 0, 30)
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabButton.BorderSizePixel = 0
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = 12
    tabButton.Parent = self.TabContainer

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = tabButton

    -- Tab Content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = name .. "Content"
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
    tab.Elements = {}

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
            tab.Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
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
    label.Name = "Label"
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab.Content

    return label
end

function UI:AddToggle(tab, text, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Toggle"
    container.Size = UDim2.new(1, -10, 0, 30)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggle = Instance.new("TextButton")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 40, 0, 20)
    toggle.Position = UDim2.new(1, -45, 0.5, -10)
    toggle.BackgroundColor3 = default and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = default and "ON" or "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 10
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
    button.Name = "Button"
    button.Size = UDim2.new(1, -10, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 11
    button.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    return button
end

function UI:AddSlider(tab, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Slider"
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBack = Instance.new("Frame")
    sliderBack.Name = "SliderBack"
    sliderBack.Size = UDim2.new(1, -20, 0, 6)
    sliderBack.Position = UDim2.new(0, 10, 1, -15)
    sliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBack

    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBack

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
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

function UI:AddDropdown(tab, text, options, default, callback)
    local container = Instance.new("Frame")
    container.Name = "Dropdown"
    container.Size = UDim2.new(1, -10, 0, 30)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = UDim2.new(1, -10, 1, 0)
    button.Position = UDim2.new(0, 5, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = text .. ": " .. (default or "None")
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.Font = Enum.Font.Gotham
    button.TextSize = 11
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = container

    local dropdownList = Instance.new("Frame")
    dropdownList.Name = "List"
    dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
    dropdownList.Position = UDim2.new(0, 0, 1, 5)
    dropdownList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    dropdownList.BorderSizePixel = 0
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = container

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = dropdownList

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = dropdownList

    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = option
        optionButton.Size = UDim2.new(1, 0, 0, 25)
        optionButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 10
        optionButton.Parent = dropdownList

        optionButton.MouseButton1Click:Connect(function()
            button.Text = text .. ": " .. option
            dropdownList.Visible = false
            callback(option)
        end)
    end

    button.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
    end)

    return container
end

function UI:AddTextBox(tab, placeholder, callback)
    local container = Instance.new("Frame")
    container.Name = "TextBox"
    container.Size = UDim2.new(1, -10, 0, 30)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local textbox = Instance.new("TextBox")
    textbox.Name = "TextBox"
    textbox.Size = UDim2.new(1, -10, 1, 0)
    textbox.Position = UDim2.new(0, 5, 0, 0)
    textbox.BackgroundTransparency = 1
    textbox.PlaceholderText = placeholder
    textbox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    textbox.Text = ""
    textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 11
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.ClearTextOnFocus = false
    textbox.Parent = container

    textbox.FocusLost:Connect(function()
        callback(textbox.Text)
    end)

    return textbox
end

function UI:Toggle()
    self.ScreenGui.Enabled = not self.ScreenGui.Enabled
    BloodyBlox.MenuOpen = self.ScreenGui.Enabled
end

function UI:Destroy()
    self.ScreenGui:Destroy()
end

-- ============ UTILITY FUNCTIONS ============

function BloodyBlox:Log(category, message, level)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        time = timestamp,
        category = category,
        message = message,
        level = level or "info"
    }

    table.insert(self.Logs, logEntry)

    if #self.Logs > 100 then
        table.remove(self.Logs, 1)
    end

    if self.Settings.Debug then
        local prefix = string.format("[%s][%s]", timestamp, category)
        if level == "error" then
            warn(prefix .. " " .. message)
        else
            print(prefix .. " " .. message)
        end
    end
end

function BloodyBlox:SafeCall(func, errorMsg)
    local success, result = pcall(func)
    if not success then
        self:Log("Error", errorMsg .. ": " .. tostring(result), "error")
        return nil
    end
    return result
end

function BloodyBlox:GetService(serviceName)
    if not self.Services[serviceName] then
        self.Services[serviceName] = self:SafeCall(function()
            return game:GetService(serviceName)
        end, "GetService: " .. serviceName)
    end
    return self.Services[serviceName]
end

function BloodyBlox:UpdatePlayerReferences()
    self.Player = self:GetService("Players").LocalPlayer
    if not self.Player then return false end

    self.Character = self.Player.Character
    if not self.Character then return false end

    self.Humanoid = self.Character:FindFirstChild("Humanoid")
    self.HumanoidRootPart = self.Character:FindFirstChild("HumanoidRootPart")

    return self.Humanoid ~= nil and self.HumanoidRootPart ~= nil
end

-- ============ ESP SYSTEM ============

local ESP = {}

function ESP:CreateDrawing(type)
    return Drawing.new(type)
end

function ESP:CreatePlayerESP(player)
    if player == BloodyBlox.Player then return end

    local esp = {
        Player = player,
        Box = self:CreateDrawing("Square"),
        Tracer = self:CreateDrawing("Line"),
        Name = self:CreateDrawing("Text"),
        HealthBar = self:CreateDrawing("Square"),
        HealthBarBG = self:CreateDrawing("Square"),
        Distance = self:CreateDrawing("Text")
    }

    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Box.Color = Color3.fromRGB(255, 255, 255)
    esp.Box.Visible = false

    esp.Tracer.Thickness = 1
    esp.Tracer.Color = Color3.fromRGB(255, 255, 255)
    esp.Tracer.Visible = false

    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Visible = false

    esp.HealthBar.Filled = true
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Visible = false

    esp.HealthBarBG.Filled = true
    esp.HealthBarBG.Color = Color3.fromRGB(50, 50, 50)
    esp.HealthBarBG.Visible = false

    esp.Distance.Size = 12
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.fromRGB(200, 200, 200)
    esp.Distance.Visible = false

    BloodyBlox.ESP_Objects[player] = esp
end

function ESP:UpdateESP()
    if not BloodyBlox.Settings.ESP_Enabled then
        for _, esp in pairs(BloodyBlox.ESP_Objects) do
            esp.Box.Visible = false
            esp.Tracer.Visible = false
            esp.Name.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Distance.Visible = false
        end
        return
    end

    local camera = workspace.CurrentCamera
    local screenSize = camera.ViewportSize

    for player, esp in pairs(BloodyBlox.ESP_Objects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head")

            if BloodyBlox.Settings.ESP_TeamCheck and player.Team == BloodyBlox.Player.Team then
                esp.Box.Visible = false
                esp.Tracer.Visible = false
                esp.Name.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Distance.Visible = false
                continue
            end

            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local boxHeight = math.abs(headPos.Y - legPos.Y)
                local boxWidth = boxHeight * 0.5

                if BloodyBlox.Settings.ESP_Boxes then
                    esp.Box.Size = Vector2.new(boxWidth, boxHeight)
                    esp.Box.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end

                if BloodyBlox.Settings.ESP_Tracers then
                    esp.Tracer.From = Vector2.new(screenSize.X / 2, screenSize.Y)
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    esp.Tracer.Visible = true
                else
                    esp.Tracer.Visible = false
                end

                if BloodyBlox.Settings.ESP_Names then
                    esp.Name.Text = player.Name
                    esp.Name.Position = Vector2.new(pos.X, headPos.Y - 20)
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end

                if BloodyBlox.Settings.ESP_HealthBars then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    esp.HealthBarBG.Size = Vector2.new(3, boxHeight)
                    esp.HealthBarBG.Position = Vector2.new(pos.X - boxWidth / 2 - 6, pos.Y - boxHeight / 2)
                    esp.HealthBarBG.Visible = true

                    esp.HealthBar.Size = Vector2.new(3, boxHeight * healthPercent)
                    esp.HealthBar.Position = Vector2.new(pos.X - boxWidth / 2 - 6, pos.Y + boxHeight / 2 - boxHeight * healthPercent)
                    esp.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    esp.HealthBar.Visible = true
                else
                    esp.HealthBar.Visible = false
                    esp.HealthBarBG.Visible = false
                end

                if BloodyBlox.Settings.ESP_Distance then
                    local distance = (BloodyBlox.HumanoidRootPart.Position - hrp.Position).Magnitude
                    esp.Distance.Text = string.format("%.1f", distance) .. "m"
                    esp.Distance.Position = Vector2.new(pos.X, legPos.Y + 5)
                    esp.Distance.Visible = true
                else
                    esp.Distance.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Tracer.Visible = false
                esp.Name.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Distance.Visible = false
            end
        end
    end
end

function ESP:Initialize()
    for _, player in ipairs(BloodyBlox:GetService("Players"):GetPlayers()) do
        self:CreatePlayerESP(player)
    end

    BloodyBlox:GetService("Players").PlayerAdded:Connect(function(player)
        self:CreatePlayerESP(player)
    end)

    BloodyBlox:GetService("Players").PlayerRemoving:Connect(function(player)
        if BloodyBlox.ESP_Objects[player] then
            local esp = BloodyBlox.ESP_Objects[player]
            esp.Box:Remove()
            esp.Tracer:Remove()
            esp.Name:Remove()
            esp.HealthBar:Remove()
            esp.HealthBarBG:Remove()
            esp.Distance:Remove()
            BloodyBlox.ESP_Objects[player] = nil
        end
    end)

    BloodyBlox:GetService("RunService").RenderStepped:Connect(function()
        if BloodyBlox:UpdatePlayerReferences() then
            self:UpdateESP()
        end
    end)

    BloodyBlox:Log("ESP", "Initialized", "info")
end

-- ============ FARM FUNCTIONS ============

local Farm = {}

function Farm:FastFarm()
    BloodyBlox:SafeCall(function()
        while BloodyBlox.Settings.FastFarm do
            task.wait(0.1)

            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local name = gui.Name:lower()
                    if name:find("train") or name:find("click") or name:find("exercise") then
                        if gui.Visible and gui.Active then
                            for i = 1, 3 do
                                gui.MouseButton1Click:Fire()
                                task.wait(0.03)
                            end
                            break
                        end
                    end
                end
            end
        end
    end, "FastFarm")
end

function Farm:AutoWeight()
    BloodyBlox:SafeCall(function()
        while BloodyBlox.Settings.AutoWeight do
            task.wait(0.3)

            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("weight") or text:find("kg") or text:find("lb") then
                        gui.MouseButton1Click:Fire()
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end, "AutoWeight")
end

function Farm:AutoRebirth()
    BloodyBlox:SafeCall(function()
        while BloodyBlox.Settings.AutoRebirth do
            task.wait(1)

            local playerGui = BloodyBlox.Player:WaitForChild("PlayerGui")
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextButton") and gui.Visible then
                    local text = gui.Text:lower()
                    if text:find("rebirth") or text:find("prestige") then
                        gui.MouseButton1Click:Fire()
                        task.wait(2)
                        break
                    end
                end
            end
        end
    end, "AutoRebirth")
end

-- ============ PLAYER MODIFICATIONS ============

local Player = {}

function Player:SetWalkSpeed(speed)
    if BloodyBlox.Humanoid then
        BloodyBlox.Humanoid.WalkSpeed = speed
    end
end

function Player:SetJumpPower(power)
    if BloodyBlox.Humanoid then
        BloodyBlox.Humanoid.JumpPower = power
    end
end

function Player:ToggleFly(enabled)
    if enabled then
        local flyConnection
        flyConnection = BloodyBlox:GetService("RunService").Heartbeat:Connect(function()
            if not BloodyBlox.Settings.Fly then
                flyConnection:Disconnect()
                return
            end

            if BloodyBlox.HumanoidRootPart then
                local UIS = BloodyBlox:GetService("UserInputService")
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

                BloodyBlox.HumanoidRootPart.Velocity = velocity * 20
            end
        end)

        table.insert(BloodyBlox.Connections, flyConnection)
    end
end

function Player:ToggleNoclip(enabled)
    if enabled then
        local noclipConnection
        noclipConnection = BloodyBlox:GetService("RunService").Stepped:Connect(function()
            if not BloodyBlox.Settings.Noclip then
                noclipConnection:Disconnect()
                return
            end

            if BloodyBlox.Character then
                for _, part in pairs(BloodyBlox.Character:GetDescendants()) do
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
        infJumpConnection = BloodyBlox:GetService("UserInputService").JumpRequest:Connect(function()
            if not BloodyBlox.Settings.InfiniteJump then
                infJumpConnection:Disconnect()
                return
            end

            if BloodyBlox.Humanoid then
                BloodyBlox.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)

        table.insert(BloodyBlox.Connections, infJumpConnection)
    end
end

function Player:ToggleGodMode(enabled)
    if enabled and BloodyBlox.Humanoid then
        BloodyBlox.Humanoid.MaxHealth = math.huge
        BloodyBlox.Humanoid.Health = math.huge
    else
        if BloodyBlox.Humanoid then
            BloodyBlox.Humanoid.MaxHealth = 100
            BloodyBlox.Humanoid.Health = 100
        end
    end
end

-- ============ TELEPORT SYSTEM ============

local Teleport = {}

Teleport.Locations = {
    ["Spawn"] = Vector3.new(0, 5, 0),
    ["Gym Area"] = Vector3.new(100, 5, 100),
    ["Weight Zone"] = Vector3.new(-100, 5, 100),
    ["Rebirth Zone"] = Vector3.new(0, 5, 200),
    ["Shop"] = Vector3.new(200, 5, 0),
    ["PvP Arena"] = Vector3.new(-200, 5, -200)
}

function Teleport:ToLocation(locationName)
    if BloodyBlox.HumanoidRootPart and self.Locations[locationName] then
        BloodyBlox.HumanoidRootPart.CFrame = CFrame.new(self.Locations[locationName])
        BloodyBlox:Log("Teleport", "Teleported to " .. locationName, "info")
    end
end

function Teleport:ToPlayer(targetPlayer)
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if BloodyBlox.HumanoidRootPart then
            BloodyBlox.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
            BloodyBlox:Log("Teleport", "Teleported to " .. targetPlayer.Name, "info")
        end
    end
end

-- ============ MISC FUNCTIONS ============

local Misc = {}

function Misc:AntiAFK()
    local VirtualUser = BloodyBlox:GetService("VirtualUser")
    BloodyBlox.Player.Idled:Connect(function()
        if BloodyBlox.Settings.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    BloodyBlox:Log("Misc", "Anti-AFK enabled", "info")
end

function Misc:UnlockFPS()
    setfpscap(999)
    BloodyBlox:Log("Misc", "FPS unlocked", "info")
end

-- ============ CONFIG SYSTEM ============

local Config = {}

function Config:Save(configName)
    local configData = {
        Settings = BloodyBlox.Settings,
        Version = BloodyBlox.Version
    }

    BloodyBlox:SafeCall(function()
        writefile("BloodyBlox_" .. configName .. ".json", game:GetService("HttpService"):JSONEncode(configData))
        BloodyBlox:Log("Config", "Saved: " .. configName, "info")
    end, "Config Save")
end

function Config:Load(configName)
    BloodyBlox:SafeCall(function()
        local configData = game:GetService("HttpService"):JSONDecode(readfile("BloodyBlox_" .. configName .. ".json"))
        BloodyBlox.Settings = configData.Settings
        BloodyBlox:Log("Config", "Loaded: " .. configName, "info")
    end, "Config Load")
end

function Config:Delete(configName)
    BloodyBlox:SafeCall(function()
        delfile("BloodyBlox_" .. configName .. ".json")
        BloodyBlox:Log("Config", "Deleted: " .. configName, "info")
    end, "Config Delete")
end

-- ============ CREATE UI ============

local MainUI = UI:Create()

-- Main Tab
local MainTab = MainUI:CreateTab("Main")
MainUI:AddLabel(MainTab, "BloodyBlox v" .. BloodyBlox.Version)
MainUI:AddLabel(MainTab, "Muscle Legends Exploit")
MainUI:AddLabel(MainTab, "Press INSERT to toggle")
MainUI:AddButton(MainTab, "Check Bypass Status", function()
    BloodyBlox:Log("Bypass", "Status: ACTIVE", "info")
end)
MainUI:AddToggle(MainTab, "Debug Mode", false, function(value)
    BloodyBlox.Settings.Debug = value
end)

-- Visual Tab
local VisualTab = MainUI:CreateTab("Visual")
MainUI:AddToggle(VisualTab, "Enable ESP", false, function(value)
    BloodyBlox.Settings.ESP_Enabled = value
end)
MainUI:AddToggle(VisualTab, "Boxes", true, function(value)
    BloodyBlox.Settings.ESP_Boxes = value
end)
MainUI:AddToggle(VisualTab, "Tracers", true, function(value)
    BloodyBlox.Settings.ESP_Tracers = value
end)
MainUI:AddToggle(VisualTab, "Names", true, function(value)
    BloodyBlox.Settings.ESP_Names = value
end)
MainUI:AddToggle(VisualTab, "Health Bars", true, function(value)
    BloodyBlox.Settings.ESP_HealthBars = value
end)
MainUI:AddToggle(VisualTab, "Distance", true, function(value)
    BloodyBlox.Settings.ESP_Distance = value
end)
MainUI:AddToggle(VisualTab, "Team Check", false, function(value)
    BloodyBlox.Settings.ESP_TeamCheck = value
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

-- Teleport Tab
local TeleportTab = MainUI:CreateTab("Teleport")
MainUI:AddLabel(TeleportTab, "Teleport to Location:")
for locationName, _ in pairs(Teleport.Locations) do
    MainUI:AddButton(TeleportTab, locationName, function()
        Teleport:ToLocation(locationName)
    end)
end
MainUI:AddLabel(TeleportTab, "Teleport to Player:")
local playerList = {}
for _, player in ipairs(BloodyBlox:GetService("Players"):GetPlayers()) do
    if player ~= BloodyBlox.Player then
        table.insert(playerList, player.Name)
    end
end
MainUI:AddDropdown(TeleportTab, "Select Player", playerList, "None", function(playerName)
    local targetPlayer = BloodyBlox:GetService("Players"):FindFirstChild(playerName)
    if targetPlayer then
        Teleport:ToPlayer(targetPlayer)
    end
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

-- Config Tab
local ConfigTab = MainUI:CreateTab("Config")
local configNameInput = ""
MainUI:AddLabel(ConfigTab, "Config Manager")
MainUI:AddTextBox(ConfigTab, "Enter config name...", function(text)
    configNameInput = text
end)
MainUI:AddButton(ConfigTab, "Save Config", function()
    if configNameInput ~= "" then
        Config:Save(configNameInput)
    end
end)
MainUI:AddButton(ConfigTab, "Load Config", function()
    if configNameInput ~= "" then
        Config:Load(configNameInput)
    end
end)
MainUI:AddButton(ConfigTab, "Delete Config", function()
    if configNameInput ~= "" then
        Config:Delete(configNameInput)
    end
end)

-- Logs Tab
local LogsTab = MainUI:CreateTab("Logs")
MainUI:AddLabel(LogsTab, "Recent Logs (Last 20)")
MainUI:AddButton(LogsTab, "Refresh Logs", function()
    local logCount = math.min(#BloodyBlox.Logs, 20)
    for i = #BloodyBlox.Logs - logCount + 1, #BloodyBlox.Logs do
        local log = BloodyBlox.Logs[i]
        print(string.format("[%s][%s] %s", log.time, log.category, log.message))
    end
end)
MainUI:AddButton(LogsTab, "Clear Logs", function()
    BloodyBlox.Logs = {}
    BloodyBlox:Log("Logs", "Cleared all logs", "info")
end)

-- Settings Tab
local SettingsTab = MainUI:CreateTab("Settings")
MainUI:AddButton(SettingsTab, "Disable All Features", function()
    BloodyBlox.Settings.ESP_Enabled = false
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

    BloodyBlox:Log("Settings", "All features disabled", "info")
end)
MainUI:AddButton(SettingsTab, "Close Menu", function()
    MainUI:Toggle()
end)
MainUI:AddLabel(SettingsTab, "BloodyBlox v" .. BloodyBlox.Version)
MainUI:AddLabel(SettingsTab, "Anti-Detection: ACTIVE")

-- ============ INITIALIZE SYSTEMS ============

task.spawn(function()
    task.wait(1)

    if BloodyBlox:UpdatePlayerReferences() then
        ESP:Initialize()
        BloodyBlox:Log("Init", "All systems initialized", "info")
    else
        BloodyBlox:Log("Init", "Failed to initialize", "error")
    end
end)

-- Character respawn handler
BloodyBlox.Player.CharacterAdded:Connect(function(character)
    task.wait(1)
    BloodyBlox:UpdatePlayerReferences()

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

-- Menu toggle
BloodyBlox:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        MainUI:Toggle()
    end
end)

BloodyBlox:Log("BloodyBlox", "Script loaded - Press INSERT", "info")
print("[BloodyBlox] Loaded successfully - Press INSERT to open")

return BloodyBlox
