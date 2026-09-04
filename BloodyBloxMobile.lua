repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer.PlayerGui:FindFirstChild("BloodyBloxUI") then
    LocalPlayer.PlayerGui.BloodyBloxUI:Destroy()
    task.wait(0.5)
end
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

print("═══════════════════════════════════════")
print("  BloodyBlox Beta 0.3.0")
print("  Fixed Edition")
print("═══════════════════════════════════════")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BloodyBloxUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 850, 0, 550)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BackgroundTransparency = 0.30
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MobileScale = Instance.new("UIScale")
MobileScale.Scale = 0.33
MobileScale.Name = "MobileScale"
MobileScale.Parent = Main

local Background = Instance.new("ImageLabel")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundTransparency = 1
Background.ImageTransparency = 0.4
Background.ScaleType = Enum.ScaleType.Crop
Background.ZIndex = 0
Background.Parent = Main

task.spawn(function()
    pcall(function()
        if getcustomasset then
            local imagePath = "C:\\Roblox\\Muscle legends\\Фон\\Фон.png"
            Background.Image = getcustomasset(imagePath)
        end
    end)
end)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(139, 0, 0)
MainStroke.Thickness = 2
MainStroke.Parent = Main

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857472"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
Shadow.ZIndex = 0
Shadow.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TopBar.BackgroundTransparency = 0.30
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 1
TopBar.Parent = Main

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 6)
TopBarCorner.Parent = TopBar

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 6)
TopBarFix.Position = UDim2.new(0, 0, 1, -6)
TopBarFix.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
TopBarFix.BackgroundTransparency = 0.30
TopBarFix.BorderSizePixel = 0
TopBarFix.ZIndex = 1
TopBarFix.Parent = TopBar

local TopBarLine = Instance.new("Frame")
TopBarLine.Size = UDim2.new(1, 0, 0, 1)
TopBarLine.Position = UDim2.new(0, 0, 1, 0)
TopBarLine.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
TopBarLine.BorderSizePixel = 0
TopBarLine.ZIndex = 2
TopBarLine.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 400, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOODYBLOX"
Title.TextColor3 = Color3.fromRGB(139, 0, 0)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2
Title.Parent = TopBar

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0, 100, 1, 0)
Version.Position = UDim2.new(0, 145, 0, 0)
Version.BackgroundTransparency = 1
Version.Text = "BETA 0.3.0"
Version.TextColor3 = Color3.fromRGB(80, 80, 85)
Version.TextSize = 11
Version.Font = Enum.Font.GothamBold
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.ZIndex = 2
Version.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 2
CloseBtn.Parent = TopBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 4)
CloseBtnCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
end)

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(0, 180, 1, -55)
SidebarScroll.Position = UDim2.new(0, 10, 0, 50)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 4
SidebarScroll.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SidebarScroll.ZIndex = 1
SidebarScroll.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(1, 0, 1, 0)
Sidebar.BackgroundTransparency = 1
Sidebar.ZIndex = 1
Sidebar.Parent = SidebarScroll

local TabList = Instance.new("UIListLayout")
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 6)
TabList.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -210, 1, -65)
ContentArea.Position = UDim2.new(0, 200, 0, 55)
ContentArea.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 1
ContentArea.Parent = Main

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 4)
ContentCorner.Parent = ContentArea

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(25, 25, 30)
ContentStroke.Thickness = 1
ContentStroke.Parent = ContentArea

local Tabs = {}
local ActiveTab = nil

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 38)
    TabBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = ""
    TabBtn.AutoButtonColor = false
    TabBtn.ZIndex = 2
    TabBtn.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 4)
    TabCorner.Parent = TabBtn

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Size = UDim2.new(1, -20, 1, 0)
    TabLabel.Position = UDim2.new(0, 15, 0, 0)
    TabLabel.BackgroundTransparency = 1
    TabLabel.Text = name
    TabLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    TabLabel.TextSize = 13
    TabLabel.Font = Enum.Font.GothamBold
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.ZIndex = 3
    TabLabel.Parent = TabBtn

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 1, -8)
    Indicator.Position = UDim2.new(0, 0, 0, 4)
    Indicator.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.ZIndex = 3
    Indicator.Parent = TabBtn

    local IndicatorCorner = Instance.new("UICorner")
    IndicatorCorner.CornerRadius = UDim.new(1, 0)
    IndicatorCorner.Parent = Indicator

    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, -20, 1, -20)
    Content.Position = UDim2.new(0, 10, 0, 10)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Visible = false
    Content.ZIndex = 2
    Content.Parent = ContentArea

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Content

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
    end)

    TabBtn.MouseEnter:Connect(function()
        if ActiveTab and ActiveTab.Button ~= TabBtn then
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
        end
    end)

    TabBtn.MouseLeave:Connect(function()
        if ActiveTab and ActiveTab.Button ~= TabBtn then
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
        end
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
            tab.Label.TextColor3 = Color3.fromRGB(140, 140, 150)
            tab.Indicator.Visible = false
            tab.Content.Visible = false
        end

        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
        TabLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        Indicator.Visible = true
        Content.Visible = true
        ActiveTab = {Button = TabBtn, Content = Content, Label = TabLabel, Indicator = Indicator}
    end)

    local tab = {Button = TabBtn, Content = Content, Label = TabLabel, Indicator = Indicator}
    table.insert(Tabs, tab)

    if #Tabs == 1 then
        TabBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        TabLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        Indicator.Visible = true
        Content.Visible = true
        ActiveTab = tab
    end

    return Content
end

local function AddToggle(parent, text, default, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 42)
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Container.BorderSizePixel = 0
    Container.ZIndex = 2
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 3
    Label.Parent = Container

    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0, 44, 0, 22)
    ToggleFrame.Position = UDim2.new(1, -54, 0.5, -11)
    ToggleFrame.BackgroundColor3 = default and Color3.fromRGB(139, 0, 0) or Color3.fromRGB(35, 35, 40)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.ZIndex = 3
    ToggleFrame.Parent = Container

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleFrame

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.ZIndex = 4
    Circle.Parent = ToggleFrame

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.ZIndex = 5
    Button.Parent = ToggleFrame

    local enabled = default

    Button.MouseButton1Click:Connect(function()
        enabled = not enabled

        TweenService:Create(ToggleFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundColor3 = enabled and Color3.fromRGB(139, 0, 0) or Color3.fromRGB(35, 35, 40)
        }):Play()

        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()

        callback(enabled)
    end)
end

local function AddButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = false
    Button.ZIndex = 2
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Button

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 0, 0)}):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
    end)

    Button.MouseButton1Click:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(110, 0, 0)
        task.wait(0.08)
        Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        callback()
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 60)
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Container.BorderSizePixel = 0
    Container.ZIndex = 2
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 0, 20)
    Label.Position = UDim2.new(0, 12, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 3
    Label.Parent = Container

    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0.35, -12, 0, 20)
    Value.Position = UDim2.new(0.65, 0, 0, 8)
    Value.BackgroundTransparency = 1
    Value.Text = tostring(default)
    Value.TextColor3 = Color3.fromRGB(139, 0, 0)
    Value.TextSize = 13
    Value.Font = Enum.Font.GothamBold
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.ZIndex = 3
    Value.Parent = Container

    local SliderBack = Instance.new("Frame")
    SliderBack.Size = UDim2.new(1, -24, 0, 6)
    SliderBack.Position = UDim2.new(0, 12, 0, 38)
    SliderBack.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    SliderBack.BorderSizePixel = 0
    SliderBack.ZIndex = 3
    SliderBack.Parent = Container

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = SliderBack

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    SliderFill.BorderSizePixel = 0
    SliderFill.ZIndex = 4
    SliderFill.Parent = SliderBack

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 14, 0, 14)
    Circle.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.ZIndex = 5
    Circle.Parent = SliderBack

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local CircleStroke = Instance.new("UIStroke")
    CircleStroke.Color = Color3.fromRGB(139, 0, 0)
    CircleStroke.Thickness = 2
    CircleStroke.Parent = Circle

    local dragging = false
    local currentValue = default

    local function update(input)
        local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
        currentValue = math.floor(min + (max - min) * pos)

        TweenService:Create(SliderFill, TweenInfo.new(0.08), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.08), {Position = UDim2.new(pos, -7, 0.5, -7)}):Play()

        Value.Text = tostring(currentValue)
        callback(currentValue)
    end

    SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function AddDropdown(parent, text, options, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 42)
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Container.BorderSizePixel = 0
    Container.ZIndex = 2
    Container.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 4)
    Corner.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.35, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 3
    Label.Parent = Container

    local Dropdown = Instance.new("TextButton")
    Dropdown.Size = UDim2.new(0.62, -16, 0, 28)
    Dropdown.Position = UDim2.new(0.38, 0, 0.5, -14)
    Dropdown.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
    Dropdown.BorderSizePixel = 0
    Dropdown.Text = "  Select..."
    Dropdown.TextColor3 = Color3.fromRGB(180, 180, 190)
    Dropdown.TextSize = 11
    Dropdown.Font = Enum.Font.Gotham
    Dropdown.TextXAlignment = Enum.TextXAlignment.Left
    Dropdown.AutoButtonColor = false
    Dropdown.ZIndex = 3
    Dropdown.Parent = Container

    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 3)
    DropCorner.Parent = Dropdown

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Position = UDim2.new(1, -22, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = Color3.fromRGB(139, 0, 0)
    Arrow.TextSize = 9
    Arrow.Font = Enum.Font.GothamBold
    Arrow.ZIndex = 4
    Arrow.Parent = Dropdown

    local List = Instance.new("Frame")
    List.Size = UDim2.new(0.62, -16, 0, math.min(#options * 28, 112))
    List.Position = UDim2.new(0.38, 0, 1, 4)
    List.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    List.BorderSizePixel = 0
    List.Visible = false
    List.ZIndex = 10
    List.Parent = Container

    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0, 3)
    ListCorner.Parent = List

    local ListStroke = Instance.new("UIStroke")
    ListStroke.Color = Color3.fromRGB(139, 0, 0)
    ListStroke.Thickness = 1
    ListStroke.Parent = List

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -4, 1, -4)
    Scroll.Position = UDim2.new(0, 2, 0, 2)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
    Scroll.ZIndex = 11
    Scroll.Parent = List

    for i, option in ipairs(options) do
        local Opt = Instance.new("TextButton")
        Opt.Size = UDim2.new(1, 0, 0, 28)
        Opt.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
        Opt.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
        Opt.BorderSizePixel = 0
        Opt.Text = "  " .. option
        Opt.TextColor3 = Color3.fromRGB(180, 180, 190)
        Opt.TextSize = 11
        Opt.Font = Enum.Font.Gotham
        Opt.TextXAlignment = Enum.TextXAlignment.Left
        Opt.AutoButtonColor = false
        Opt.ZIndex = 12
        Opt.Parent = Scroll

        Opt.MouseEnter:Connect(function()
            TweenService:Create(Opt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
        end)

        Opt.MouseLeave:Connect(function()
            TweenService:Create(Opt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28, 28, 33)}):Play()
        end)

        Opt.MouseButton1Click:Connect(function()
            Dropdown.Text = "  " .. option
            List.Visible = false
            TweenService:Create(Arrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
            callback(option)
        end)
    end

    Dropdown.MouseButton1Click:Connect(function()
        List.Visible = not List.Visible
        TweenService:Create(Arrow, TweenInfo.new(0.15), {Rotation = List.Visible and 180 or 0}):Play()
    end)

    return {
        SetOptions = function(newOptions)
            Scroll:ClearAllChildren()
            for i, option in ipairs(newOptions) do
                local Opt = Instance.new("TextButton")
                Opt.Size = UDim2.new(1, 0, 0, 28)
                Opt.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
                Opt.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
                Opt.BorderSizePixel = 0
                Opt.Text = "  " .. option
                Opt.TextColor3 = Color3.fromRGB(180, 180, 190)
                Opt.TextSize = 11
                Opt.Font = Enum.Font.Gotham
                Opt.TextXAlignment = Enum.TextXAlignment.Left
                Opt.AutoButtonColor = false
                Opt.ZIndex = 12
                Opt.Parent = Scroll

                Opt.MouseEnter:Connect(function()
                    TweenService:Create(Opt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
                end)

                Opt.MouseLeave:Connect(function()
                    TweenService:Create(Opt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(28, 28, 33)}):Play()
                end)

                Opt.MouseButton1Click:Connect(function()
                    Dropdown.Text = "  " .. option
                    List.Visible = false
                    TweenService:Create(Arrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
                    callback(option)
                end)
            end
            Scroll.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 28)
            List.Size = UDim2.new(0.62, -16, 0, math.min(#newOptions * 28, 112))
        end
    }
end

local FarmTab = CreateTab("FARM")
local RebirthTab = CreateTab("REBIRTH")
local CombatTab = CreateTab("COMBAT")
local TeleportTab = CreateTab("TELEPORT")
local PlayerTab = CreateTab("PLAYER")
local MiscTab = CreateTab("MISC")
local SettingTab = CreateTab("SETTING")

local Config = {
    MenuSize = 1.0,
    Farm = {AutoFarm = false},
    Rebirth = {AutoRebirth = false, NoRemoveTP = false, FastRebirth = false},
    Combat = {AntiAim = false, AutoKill = false, AutoKillWhiteList = {}},
    Player = {Fly = false, NoClip = false, Speed = 16, AntiAFK = true},
    Misc = {NoWeightSound = false},
    Teleport = {Locations = {}},
    UI = {ShowWatermark = true, WatermarkDraggable = true}
}

local function GetMenuSize()
    local baseScale = 0.33
    return baseScale * Config.MenuSize
end

local function UpdateMenuSize()
    local scale = GetMenuSize()
    local mobileScale = Main:FindFirstChild("MobileScale")
    if mobileScale then
        TweenService:Create(mobileScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Scale = scale
        }):Play()
    end
end

local Connections = {}

AddToggle(FarmTab, "Auto Farm", false, function(v)
    Config.Farm.AutoFarm = v
    if v then
        Connections.AutoFarm = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not Config.Farm.AutoFarm then return end

                local char = LocalPlayer.Character
                if not char then return end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end

                local weightTool = char:FindFirstChild("Weight")
                if not weightTool then
                    local backpackWeight = LocalPlayer.Backpack:FindFirstChild("Weight")
                    if backpackWeight then
                        humanoid:EquipTool(backpackWeight)
                    end
                    return
                end

                if weightTool and weightTool:IsA("Tool") then
                    weightTool:Activate()
                end
            end)
        end)
    else
        if Connections.AutoFarm then
            Connections.AutoFarm:Disconnect()
            Connections.AutoFarm = nil
        end
    end
end)

AddToggle(RebirthTab, "Auto Rebirth", false, function(v)
    Config.Rebirth.AutoRebirth = v
    if v then
        local checkInterval = 5

        Connections.AutoRebirthTimer = task.spawn(function()
            while Config.Rebirth.AutoRebirth do
                pcall(function()
                    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                    if not rEvents then return end

                    local rebirthRemote = rEvents:FindFirstChild("rebirthRemote")
                    if not rebirthRemote then return end

                    local success, result = pcall(function()
                        return rebirthRemote:InvokeServer("rebirthRequest")
                    end)

                    if success and result then
                        print("[AutoRebirth] ✓ Rebirth successful!")
                    end
                end)

                task.wait(checkInterval)
            end
        end)

        print("[AutoRebirth] Enabled - checking every " .. checkInterval .. " seconds")
    else
        Config.Rebirth.AutoRebirth = false
        print("[AutoRebirth] Disabled")
    end
end)

AddToggle(RebirthTab, "No Remove TP", false, function(v)
    Config.Rebirth.NoRemoveTP = v
end)

AddToggle(RebirthTab, "Fast Rebirth", false, function(v)
    Config.Rebirth.FastRebirth = v
end)

AddToggle(CombatTab, "Anti Aim", false, function(v)
    Config.Combat.AntiAim = v
    if v then
        Connections.AntiAim = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not Config.Combat.AntiAim then return end
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
                end
            end)
        end)
    else
        if Connections.AntiAim then
            Connections.AntiAim:Disconnect()
            Connections.AntiAim = nil
        end
    end
end)

local function getAutoKillTargets()
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local isWhitelisted = false
                for _, name in pairs(Config.Combat.AutoKillWhiteList) do
                    if player.Name == name then
                        isWhitelisted = true
                        break
                    end
                end
                if not isWhitelisted then
                    table.insert(targets, player)
                end
            end
        end
    end
    return targets
end

AddToggle(CombatTab, "Auto Kill", false, function(v)
    Config.Combat.AutoKill = v
    if v then
        Connections.AutoKill = task.spawn(function()
            while Config.Combat.AutoKill do
                pcall(function()
                    local targets = getAutoKillTargets()
                    if #targets == 0 then
                        task.wait(1)
                        return
                    end

                    for _, target in pairs(targets) do
                        if not Config.Combat.AutoKill then break end

                        local char = LocalPlayer.Character
                        local targetChar = target.Character

                        if char and targetChar and char:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("HumanoidRootPart") then
                            local targetHRP = targetChar.HumanoidRootPart
                            local targetHum = targetChar:FindFirstChild("Humanoid")

                            if targetHum and targetHum.Health > 0 then
                                local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 3)
                                char.HumanoidRootPart.CFrame = behindPos
                                task.wait(0.3)

                                local muscleEvent = LocalPlayer:FindFirstChild("muscleEvent")
                                if muscleEvent then
                                    muscleEvent:FireServer("punch", "leftHand")
                                    task.wait(0.15)
                                    muscleEvent:FireServer("punch", "rightHand")
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.3)
            end
        end)
        print("[AutoKill] Enabled - ВАЖНО: Возьмите кулаки в руки ВРУЧНУЮ перед использованием!")
    else
        if Connections.AutoKill then
            Connections.AutoKill = nil
        end
        print("[AutoKill] Disabled")
    end
end)

local WLFrame = Instance.new("Frame")
WLFrame.Size = UDim2.new(1, 0, 0, 150)
WLFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
WLFrame.BorderSizePixel = 0
WLFrame.Parent = CombatTab

local WLCorner = Instance.new("UICorner")
WLCorner.CornerRadius = UDim.new(0, 4)
WLCorner.Parent = WLFrame

local WLTitle = Instance.new("TextLabel")
WLTitle.Size = UDim2.new(1, -16, 0, 24)
WLTitle.Position = UDim2.new(0, 8, 0, 4)
WLTitle.BackgroundTransparency = 1
WLTitle.Text = "Auto Kill WhiteList"
WLTitle.TextColor3 = Color3.fromRGB(200, 200, 210)
WLTitle.TextSize = 12
WLTitle.Font = Enum.Font.GothamBold
WLTitle.TextXAlignment = Enum.TextXAlignment.Left
WLTitle.Parent = WLFrame

local WLScroll = Instance.new("ScrollingFrame")
WLScroll.Size = UDim2.new(1, -16, 1, -64)
WLScroll.Position = UDim2.new(0, 8, 0, 32)
WLScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
WLScroll.BorderSizePixel = 0
WLScroll.ScrollBarThickness = 4
WLScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
WLScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
WLScroll.Parent = WLFrame

local WLScrollCorner = Instance.new("UICorner")
WLScrollCorner.CornerRadius = UDim.new(0, 4)
WLScrollCorner.Parent = WLScroll

local WLList = Instance.new("UIListLayout")
WLList.Padding = UDim.new(0, 4)
WLList.SortOrder = Enum.SortOrder.LayoutOrder
WLList.Parent = WLScroll

local function updateAutoKillWhiteList()
    for _, child in pairs(WLScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for idx, playerName in pairs(Config.Combat.AutoKillWhiteList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        btn.BorderSizePixel = 0
        btn.Text = playerName .. " [Remove]"
        btn.TextColor3 = Color3.fromRGB(200, 200, 210)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Parent = WLScroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            table.remove(Config.Combat.AutoKillWhiteList, idx)
            updateAutoKillWhiteList()
            print("[AutoKill] Removed: " .. playerName)
        end)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
        end)

        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
        end)
    end
end

local WLAddBtn = Instance.new("TextButton")
WLAddBtn.Size = UDim2.new(1, -16, 0, 28)
WLAddBtn.Position = UDim2.new(0, 8, 1, -32)
WLAddBtn.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
WLAddBtn.BorderSizePixel = 0
WLAddBtn.Text = "Добавить игрока"
WLAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WLAddBtn.TextSize = 11
WLAddBtn.Font = Enum.Font.GothamBold
WLAddBtn.Parent = WLFrame

local WLAddCorner = Instance.new("UICorner")
WLAddCorner.CornerRadius = UDim.new(0, 4)
WLAddCorner.Parent = WLAddBtn

WLAddBtn.MouseButton1Click:Connect(function()
    local availablePlayers = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local alreadyListed = false
            for _, name in pairs(Config.Combat.AutoKillWhiteList) do
                if player.Name == name then
                    alreadyListed = true
                    break
                end
            end
            if not alreadyListed then
                table.insert(availablePlayers, player.Name)
            end
        end
    end

    if #availablePlayers > 0 then
        local selected = availablePlayers[math.random(1, #availablePlayers)]
        table.insert(Config.Combat.AutoKillWhiteList, selected)
        updateAutoKillWhiteList()
        print("[AutoKill] Added: " .. selected)
    end
end)

WLAddBtn.MouseEnter:Connect(function()
    TweenService:Create(WLAddBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 0, 0)}):Play()
end)

WLAddBtn.MouseLeave:Connect(function()
    TweenService:Create(WLAddBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
end)

updateAutoKillWhiteList()

local PlayerButtonsContainer = Instance.new("ScrollingFrame")
PlayerButtonsContainer.Size = UDim2.new(1, -8, 0, 200)
PlayerButtonsContainer.Position = UDim2.new(0, 4, 0, 180)
PlayerButtonsContainer.BackgroundTransparency = 1
PlayerButtonsContainer.BorderSizePixel = 0
PlayerButtonsContainer.ScrollBarThickness = 4
PlayerButtonsContainer.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
PlayerButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerButtonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerButtonsContainer.Parent = TeleportTab

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = PlayerButtonsContainer

local function RefreshPlayerButtons()
    for _, child in pairs(PlayerButtonsContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local playerCount = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and playerCount < 25 then
            playerCount = playerCount + 1

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 32)
            btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            btn.BorderSizePixel = 0
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(200, 200, 210)
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.LayoutOrder = playerCount
            btn.Parent = PlayerButtonsContainer

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                pcall(function()
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                        print("[TP] Teleported to: " .. player.Name)
                    end
                end)
            end)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
            end)

            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}):Play()
            end)
        end
    end
end

RefreshPlayerButtons()

Players.PlayerAdded:Connect(RefreshPlayerButtons)
Players.PlayerRemoving:Connect(RefreshPlayerButtons)

AddToggle(PlayerTab, "Fly", false, function(v)
    Config.Player.Fly = v
    if v then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            Config.Player.Fly = false
            return
        end
        local hrp = char.HumanoidRootPart

        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp

        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = hrp

        Connections.Fly = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not Config.Player.Fly or not hrp or not hrp.Parent then
                    if bv and bv.Parent then bv:Destroy() end
                    if bg and bg.Parent then bg:Destroy() end
                    if Connections.Fly then
                        Connections.Fly:Disconnect()
                        Connections.Fly = nil
                    end
                    return
                end

                local cam = workspace.CurrentCamera
                local move = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end

                if bv and bv.Parent then
                    bv.Velocity = move * 150
                end
                if bg and bg.Parent then
                    bg.CFrame = cam.CFrame
                end
            end)
        end)

        print("[Fly] Enabled")
    else
        if Connections.Fly then
            Connections.Fly:Disconnect()
            Connections.Fly = nil
        end

        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local bv = hrp:FindFirstChild("FlyVelocity")
                local bg = hrp:FindFirstChild("FlyGyro")
                if bv then bv:Destroy() end
                if bg then bg:Destroy() end
            end
        end)

        print("[Fly] Disabled")
    end
end)

AddToggle(PlayerTab, "No Clip", false, function(v)
    Config.Player.NoClip = v
    if v then
        Connections.NoClip = RunService.Stepped:Connect(function()
            pcall(function()
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end)
    else
        if Connections.NoClip then
            Connections.NoClip:Disconnect()
            Connections.NoClip = nil
        end
    end
end)

AddSlider(PlayerTab, "Speed", 10, 500, 16, function(v)
    Config.Player.Speed = v
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end)
end)

AddToggle(PlayerTab, "Anti AFK", true, function(v)
    Config.Player.AntiAFK = v
    if v then
        local VirtualUser = game:GetService("VirtualUser")

        Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)

        Connections.AntiAFKBackup = task.spawn(function()
            while Config.Player.AntiAFK do
                task.wait(60)
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.05)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        end)

        print("[BloodyBlox] Anti AFK enabled")
    else
        if Connections.AntiAFK then
            Connections.AntiAFK:Disconnect()
            Connections.AntiAFK = nil
        end
        if Connections.AntiAFKBackup then
            Connections.AntiAFKBackup = nil
        end
        print("[BloodyBlox] Anti AFK disabled")
    end
end)

local gymLocations = {
    {name = "Промышленный Спортзал", pos = Vector3.new(-5563.23, 57.55, 4942.44)},
    {name = "Джунгли", pos = Vector3.new(-8685.62, 3.88, 2392.33)},
    {name = "Рай", pos = Vector3.new(4603.28, 988.63, -3897.87)},
    {name = "Ад", pos = Vector3.new(-6758.96, 4.45, -1284.92)},
    {name = "Король Мускулов", pos = Vector3.new(-8625.93, 14.30, -5730.47)},
    {name = "Мифический", pos = Vector3.new(2250.78, 4.45, 1073.23)},
    {name = "Мороз", pos = Vector3.new(-2623.02, 4.45, -409.07)},
    {name = "Крошечный Остров", pos = Vector3.new(-26.45, 4.60, 1917.58)}
}

for _, gym in ipairs(gymLocations) do
    AddButton(TeleportTab, gym.name, function()
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(gym.pos)
                print("[TP] Teleported to: " .. gym.name)
            end
        end)
    end)
end

local originalSoundVolumes = {}
local noWeightSoundTarget = "All"

local NoWeightSoundLabel = Instance.new("TextLabel")
NoWeightSoundLabel.Size = UDim2.new(1, 0, 0, 32)
NoWeightSoundLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
NoWeightSoundLabel.BorderSizePixel = 0
NoWeightSoundLabel.Text = "  Target: Все игроки"
NoWeightSoundLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
NoWeightSoundLabel.TextSize = 11
NoWeightSoundLabel.Font = Enum.Font.Gotham
NoWeightSoundLabel.TextXAlignment = Enum.TextXAlignment.Left
NoWeightSoundLabel.ZIndex = 2
NoWeightSoundLabel.Parent = MiscTab

local LabelCorner = Instance.new("UICorner")
LabelCorner.CornerRadius = UDim.new(0, 4)
LabelCorner.Parent = NoWeightSoundLabel

local TargetButton = Instance.new("TextButton")
TargetButton.Size = UDim2.new(0, 120, 0, 24)
TargetButton.Position = UDim2.new(1, -130, 0, 4)
TargetButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
TargetButton.BorderSizePixel = 0
TargetButton.Text = "Сменить"
TargetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetButton.TextSize = 11
TargetButton.Font = Enum.Font.GothamBold
TargetButton.ZIndex = 3
TargetButton.Parent = NoWeightSoundLabel

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 4)
BtnCorner.Parent = TargetButton

TargetButton.MouseButton1Click:Connect(function()
    if noWeightSoundTarget == "All" then
        noWeightSoundTarget = "Me"
        NoWeightSoundLabel.Text = "  Target: Только я"
    else
        noWeightSoundTarget = "All"
        NoWeightSoundLabel.Text = "  Target: Все игроки"
    end
    print("[BloodyBlox] Target changed to: " .. noWeightSoundTarget)
end)

local printedSounds = {}

AddToggle(MiscTab, "No Weight Sound", false, function(v)
    Config.Misc.NoWeightSound = v
    if v then
        printedSounds = {}
        print("[BloodyBlox] NoWeightSound DEBUG MODE")
        print("[BloodyBlox] Начни качать СЕЙЧАС - буду выводить новые звуки в консоль")

        Connections.NoWeightSoundDebug = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not Config.Misc.NoWeightSound then return end

                local targetChars = {}
                if noWeightSoundTarget == "Me" then
                    if LocalPlayer.Character then
                        table.insert(targetChars, LocalPlayer.Character)
                    end
                else
                    for _, player in pairs(Players:GetPlayers()) do
                        if player.Character then
                            table.insert(targetChars, player.Character)
                        end
                    end
                end

                for _, char in pairs(targetChars) do
                    for _, obj in pairs(char:GetDescendants()) do
                        if obj:IsA("Sound") and obj.Playing then
                            local soundKey = obj.Name .. "_" .. obj.SoundId
                            if not printedSounds[soundKey] then
                                print(string.format("[NEW SOUND] Name: '%s' | Parent: '%s' | SoundId: '%s'", obj.Name, obj.Parent.Name, obj.SoundId))
                                printedSounds[soundKey] = true
                            end

                            if not originalSoundVolumes[obj] then
                                originalSoundVolumes[obj] = obj.Volume
                            end
                            obj.Volume = 0
                        end
                    end
                end
            end)
        end)
    else
        if Connections.NoWeightSoundDebug then
            Connections.NoWeightSoundDebug:Disconnect()
            Connections.NoWeightSoundDebug = nil
        end

        pcall(function()
            for sound, volume in pairs(originalSoundVolumes) do
                if sound and sound.Parent then
                    sound.Volume = volume
                end
            end
            originalSoundVolumes = {}
        end)

        printedSounds = {}
        print("[BloodyBlox] NoWeightSound disabled")
    end
end)

AddToggle(MiscTab, "Skip Egg Animation", false, function(v)
    Config.Misc.SkipEggAnimation = v
    if v then
        Connections.SkipEggAnimation = LocalPlayer.PlayerGui.ChildAdded:Connect(function(gui)
            pcall(function()
                if not Config.Misc.SkipEggAnimation then return end

                if gui.Name:lower():find("egg") or gui.Name:lower():find("hatch") or gui.Name:lower():find("open") then
                    task.wait(0.1)
                    for _, btn in pairs(gui:GetDescendants()) do
                        if btn:IsA("TextButton") then
                            local text = btn.Text:lower()
                            if text:find("skip") or text:find("claim") or text:find("ok") or text:find("close") then
                                if getconnections then
                                    for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                                        pcall(function() conn:Fire() end)
                                    end
                                else
                                    pcall(function() btn.MouseButton1Click:Fire() end)
                                end
                                break
                            end
                        end
                    end
                    gui:Destroy()
                end
            end)
        end)
    else
        if Connections.SkipEggAnimation then
            Connections.SkipEggAnimation:Disconnect()
            Connections.SkipEggAnimation = nil
        end
    end
end)

AddButton(AnalyzerTab, "Analyze ReplicatedStorage", function()
    print("═══════════════════════════════════════")
    print("  REPLICATED STORAGE ANALYSIS")
    print("═══════════════════════════════════════")

    local function scanFolder(folder, depth)
        depth = depth or 0
        local indent = string.rep("  ", depth)

        for _, child in pairs(folder:GetChildren()) do
            local childType = child.ClassName
            print(indent .. "├─ " .. child.Name .. " (" .. childType .. ")")

            if child:IsA("Folder") or child:IsA("Configuration") then
                scanFolder(child, depth + 1)
            end
        end
    end

    scanFolder(ReplicatedStorage, 0)
    print("═══════════════════════════════════════")
end)

AddButton(AnalyzerTab, "Find All Remotes", function()
    print("═══════════════════════════════════════")
    print("  REMOTE EVENTS & FUNCTIONS")
    print("═══════════════════════════════════════")

    local remoteCount = 0

    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            remoteCount = remoteCount + 1
            print(string.format("[%d] %s (%s)", remoteCount, remote:GetFullName(), remote.ClassName))
        end
    end

    print("═══════════════════════════════════════")
    print("Total remotes found: " .. remoteCount)
end)

AddButton(AnalyzerTab, "Scan Player Character", function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then
            print("[Analyzer] Character not found")
            return
        end

        print("═══════════════════════════════════════")
        print("  CHARACTER ANALYSIS")
        print("═══════════════════════════════════════")

        for _, child in pairs(char:GetChildren()) do
            print("├─ " .. child.Name .. " (" .. child.ClassName .. ")")
        end

        print("═══════════════════════════════════════")
    end)
end)

AddButton(AnalyzerTab, "Find LocalPlayer Events", function()
    print("═══════════════════════════════════════")
    print("  LOCAL PLAYER DESCENDANTS")
    print("═══════════════════════════════════════")

    for _, desc in pairs(LocalPlayer:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") or desc:IsA("BindableEvent") then
            print("├─ " .. desc:GetFullName() .. " (" .. desc.ClassName .. ")")
        end
    end

    print("═══════════════════════════════════════")
end)

AddButton(TesterTab, "Test Auto Rebirth Remote", function()
    pcall(function()
        local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
        if not rEvents then
            print("[Tester] rEvents not found")
            return
        end

        local rebirthRemote = rEvents:FindFirstChild("rebirthRemote")
        if not rebirthRemote then
            print("[Tester] rebirthRemote not found")
            return
        end

        print("[Tester] Found rebirthRemote at: " .. rebirthRemote:GetFullName())
        print("[Tester] Attempting rebirth...")

        local success, result = pcall(function()
            return rebirthRemote:InvokeServer("rebirthRequest")
        end)

        if success then
            if result then
                print("[Tester] ✓ Rebirth SUCCESS - server returned true")
            else
                print("[Tester] ✗ Rebirth FAILED - server returned false (not enough strength?)")
            end
        else
            print("[Tester] ✗ Error calling remote: " .. tostring(result))
        end
    end)
end)

AddButton(TesterTab, "Test Weight Tool", function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then
            print("[Tester] Character not found")
            return
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            print("[Tester] Humanoid not found")
            return
        end

        local weightTool = char:FindFirstChild("Weight") or LocalPlayer.Backpack:FindFirstChild("Weight")
        if not weightTool then
            print("[Tester] Weight tool not found in character or backpack")
            return
        end

        print("[Tester] Found Weight tool")

        if weightTool.Parent ~= char then
            humanoid:EquipTool(weightTool)
            print("[Tester] Equipped Weight tool")
            task.wait(0.1)
        end

        weightTool:Activate()
        print("[Tester] ✓ Weight tool activated")
    end)
end)

AddButton(TesterTab, "Test AntiAFK", function()
    print("[Tester] Testing AntiAFK system...")

    local VirtualUser = game:GetService("VirtualUser")
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())

    print("[Tester] ✓ AntiAFK input sent")
end)

AddButton(TesterTab, "Test Location Save/TP", function()
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            print("[Tester] Character/HRP not found")
            return
        end

        local originalPos = char.HumanoidRootPart.CFrame
        print("[Tester] Original position: " .. tostring(originalPos.Position))

        local testPos = originalPos * CFrame.new(10, 0, 0)
        char.HumanoidRootPart.CFrame = testPos
        print("[Tester] Teleported +10 studs X")

        task.wait(1)

        char.HumanoidRootPart.CFrame = originalPos
        print("[Tester] ✓ Teleported back to original position")
    end)
end)

AddButton(TesterTab, "Clear All Connections", function()
    local count = 0
    for name, conn in pairs(Connections) do
        if conn then
            conn:Disconnect()
            count = count + 1
        end
    end
    Connections = {}
    print("[Tester] ✓ Disconnected " .. count .. " connections")
end)

AddButton(TesterTab, "Test Menu Resize", function()
    local originalSize = Config.MenuSize
    print("[Tester] Original menu size: " .. (originalSize * 100) .. "%")

    Config.MenuSize = 0.5
    UpdateMenuSize()
    print("[Tester] Resized to 50%")

    task.wait(1)

    Config.MenuSize = 1.5
    UpdateMenuSize()
    print("[Tester] Resized to 150%")

    task.wait(1)

    Config.MenuSize = originalSize
    UpdateMenuSize()
    print("[Tester] ✓ Restored to original size")
end)

local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 100, 0, 21)
Watermark.Position = UDim2.new(0.5, -50, 0, 12)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Watermark.BackgroundTransparency = 0.25
Watermark.BorderSizePixel = 0
Watermark.Parent = ScreenGui

local WaterCorner = Instance.new("UICorner")
WaterCorner.CornerRadius = UDim.new(0, 2)
WaterCorner.Parent = Watermark

local WaterStroke = Instance.new("UIStroke")
WaterStroke.Color = Color3.fromRGB(139, 0, 0)
WaterStroke.Thickness = 1
WaterStroke.Parent = Watermark

local WaterButton = Instance.new("TextButton")
WaterButton.Size = UDim2.new(1, 0, 1, 0)
WaterButton.BackgroundTransparency = 1
WaterButton.Text = ""
WaterButton.ZIndex = 10
WaterButton.Parent = Watermark

local WaterTitle = Instance.new("TextLabel")
WaterTitle.Size = UDim2.new(1, -8, 0, 9)
WaterTitle.Position = UDim2.new(0, 4, 0, 3)
WaterTitle.BackgroundTransparency = 1
WaterTitle.Text = "BLOODYBLOX 0.4.0 BETA"
WaterTitle.TextColor3 = Color3.fromRGB(139, 0, 0)
WaterTitle.TextSize = 6
WaterTitle.Font = Enum.Font.GothamBold
WaterTitle.TextXAlignment = Enum.TextXAlignment.Left
WaterTitle.Parent = Watermark

local WaterSub = Instance.new("TextLabel")
WaterSub.Size = UDim2.new(1, -8, 0, 7)
WaterSub.Position = UDim2.new(0, 4, 0, 11)
WaterSub.BackgroundTransparency = 1
WaterSub.Text = "FPS: 60 | Click to toggle"
WaterSub.TextColor3 = Color3.fromRGB(120, 120, 130)
WaterSub.TextSize = 5
WaterSub.Font = Enum.Font.Gotham
WaterSub.TextXAlignment = Enum.TextXAlignment.Left
WaterSub.Parent = Watermark
WaterTitle.TextColor3 = Color3.fromRGB(139, 0, 0)
WaterTitle.TextSize = 12
WaterTitle.Font = Enum.Font.GothamBold
WaterTitle.TextXAlignment = Enum.TextXAlignment.Left
WaterTitle.Parent = Watermark

local WaterSub = Instance.new("TextLabel")
WaterSub.Size = UDim2.new(1, -16, 0, 14)
WaterSub.Position = UDim2.new(0, 8, 0, 22)
WaterSub.BackgroundTransparency = 1
WaterSub.Text = "FPS: 60 | Click to toggle"
WaterSub.TextColor3 = Color3.fromRGB(120, 120, 130)
WaterSub.TextSize = 10
WaterSub.Font = Enum.Font.Gotham
WaterSub.TextXAlignment = Enum.TextXAlignment.Left
WaterSub.Parent = Watermark

local waterDragging, waterDragStart, waterStartPos

WaterButton.MouseButton1Click:Connect(function()
    local width, height = GetMenuSize()
    if Main.Visible then
        local currentPos = Main.Position
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset, currentPos.Y.Scale, currentPos.Y.Offset)
        }):Play()
        task.wait(0.25)
        Main.Visible = false
        Main.Size = UDim2.new(0, width, 0, height)
    else
        Main.Visible = true
        local savedPos = Main.Position
        Main.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, width, 0, height),
            Position = savedPos
        }):Play()
    end
end)

WaterButton.InputBegan:Connect(function(input)
    if Config.UI.WatermarkDraggable and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        waterDragging = true
        waterDragStart = input.Position
        waterStartPos = Watermark.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                waterDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Config.UI.WatermarkDraggable and waterDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - waterDragStart
        Watermark.Position = UDim2.new(waterStartPos.X.Scale, waterStartPos.X.Offset + delta.X, waterStartPos.Y.Scale, waterStartPos.Y.Offset + delta.Y)
    end
end)

WaterButton.MouseEnter:Connect(function()
    TweenService:Create(WaterStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(160, 0, 0)}):Play()
end)

WaterButton.MouseLeave:Connect(function()
    TweenService:Create(WaterStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(139, 0, 0)}):Play()
end)

task.spawn(function()
    local lastUpdate = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastUpdate >= 0.5 then
            local fps = math.floor(frames / (tick() - lastUpdate))
            WaterSub.Text = string.format("FPS: %d | Click to toggle", fps)
            frames = 0
            lastUpdate = tick()
        end
    end)
end)

AddToggle(SettingTab, "Watermark Draggable", true, function(v)
    Config.UI.WatermarkDraggable = v
    if v then
        print("[Settings] Watermark dragging enabled")
    else
        print("[Settings] Watermark dragging disabled")
    end
end)

AddButton(SettingTab, "EXIT", function()
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    ScreenGui:Destroy()
end)

AddSlider(SettingTab, "Menu Size", 50, 150, 100, function(value)
    Config.MenuSize = value / 100
    UpdateMenuSize()
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.wait(0.25)
    Main.Visible = false
    Main.Size = UDim2.new(0, 850, 0, 550)
end)

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if Main.Visible then
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            task.wait(0.25)
            Main.Visible = false
            Main.Size = UDim2.new(0, 850, 0, 550)
        else
            Main.Visible = true
            Main.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 850, 0, 550)
            }):Play()
        end
    end
end)

Main.Size = UDim2.new(0, 850, 0, 550)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Visible = true

print("✓ BloodyBlox Fixed Edition loaded!")
print("✓ Press INSERT to toggle")
print("✓ Auto Farm: Equips Weight tool and activates")
print("✓ Auto Rebirth: Single-click system")
print("═══════════════════════════════════════")
