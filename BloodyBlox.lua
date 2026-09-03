repeat task.wait() until game:IsLoaded()

if game:GetService("CoreGui"):FindFirstChild("BloodyBloxUI") then
    game:GetService("CoreGui").BloodyBloxUI:Destroy()
    task.wait(0.5)
end

local Players = game:GetService("Players")
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
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 850, 0, 550)
Main.Position = UDim2.new(0.5, -425, 0.5, -275)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local Background = Instance.new("ImageLabel")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundTransparency = 1
Background.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
Background.ImageTransparency = 0.92
Background.ScaleType = Enum.ScaleType.Crop
Background.ZIndex = 0
Background.Parent = Main

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

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -55)
Sidebar.Position = UDim2.new(0, 10, 0, 50)
Sidebar.BackgroundTransparency = 1
Sidebar.ZIndex = 1
Sidebar.Parent = Main

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
local LogsTab = CreateTab("LOGS")
local SettingTab = CreateTab("SETTING")

local LogHistory = {}
local MaxLogs = 100

local function AddLog(message)
    if not message or message == "" then return end

    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, tostring(message))
    table.insert(LogHistory, logEntry)

    if #LogHistory > MaxLogs then
        table.remove(LogHistory, 1)
    end

    if LogScrollFrame and LogTextLabel then
        local logText = table.concat(LogHistory, "\n")
        LogTextLabel.Text = logText
        LogScrollFrame.CanvasSize = UDim2.new(0, 0, 0, LogTextLabel.TextBounds.Y + 10)
    end
end

local OriginalPrint = print
print = function(...)
    local args = {...}
    local parts = {}
    for _, v in ipairs(args) do
        if v ~= nil and tostring(v) ~= "" then
            table.insert(parts, tostring(v))
        end
    end
    if #parts > 0 then
        local message = table.concat(parts, " ")
        OriginalPrint(message)
        AddLog(message)
    end
end

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 0, 42)
ButtonContainer.Position = UDim2.new(0, 0, 0, 0)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.ZIndex = 2
ButtonContainer.Parent = LogsTab

local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0.48, -6, 0, 38)
CopyButton.Position = UDim2.new(0, 0, 0, 0)
CopyButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
CopyButton.BorderSizePixel = 0
CopyButton.Text = "Копировать всё"
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.TextSize = 12
CopyButton.Font = Enum.Font.GothamBold
CopyButton.AutoButtonColor = false
CopyButton.ZIndex = 3
CopyButton.Parent = ButtonContainer

local CopyCorner = Instance.new("UICorner")
CopyCorner.CornerRadius = UDim.new(0, 4)
CopyCorner.Parent = CopyButton

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0.48, -6, 0, 38)
ClearButton.Position = UDim2.new(0.52, 6, 0, 0)
ClearButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
ClearButton.BorderSizePixel = 0
ClearButton.Text = "Очистить"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.TextSize = 12
ClearButton.Font = Enum.Font.GothamBold
ClearButton.AutoButtonColor = false
ClearButton.ZIndex = 3
ClearButton.Parent = ButtonContainer

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 4)
ClearCorner.Parent = ClearButton

CopyButton.MouseEnter:Connect(function()
    TweenService:Create(CopyButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 0, 0)}):Play()
end)

CopyButton.MouseLeave:Connect(function()
    TweenService:Create(CopyButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
end)

ClearButton.MouseEnter:Connect(function()
    TweenService:Create(ClearButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 0, 0)}):Play()
end)

ClearButton.MouseLeave:Connect(function()
    TweenService:Create(ClearButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(139, 0, 0)}):Play()
end)

local LogContainer = Instance.new("ScrollingFrame")
LogContainer.Size = UDim2.new(1, 0, 1, -50)
LogContainer.Position = UDim2.new(0, 0, 0, 48)
LogContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
LogContainer.BorderSizePixel = 0
LogContainer.ScrollBarThickness = 6
LogContainer.ScrollBarImageColor3 = Color3.fromRGB(139, 0, 0)
LogContainer.ZIndex = 2
LogContainer.Parent = LogsTab

LogScrollFrame = LogContainer

local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0, 4)
LogCorner.Parent = LogContainer

local LogText = Instance.new("TextLabel")
LogText.Size = UDim2.new(1, -12, 1, 0)
LogText.Position = UDim2.new(0, 6, 0, 6)
LogText.BackgroundTransparency = 1
LogText.Text = ""
LogText.TextColor3 = Color3.fromRGB(200, 200, 210)
LogText.TextSize = 11
LogText.Font = Enum.Font.Code
LogText.TextXAlignment = Enum.TextXAlignment.Left
LogText.TextYAlignment = Enum.TextYAlignment.Top
LogText.TextWrapped = true
LogText.ZIndex = 3
LogText.Parent = LogContainer

LogTextLabel = LogText

CopyButton.MouseButton1Click:Connect(function()
    local allLogs = table.concat(LogHistory, "\n")
    if setclipboard then
        setclipboard(allLogs)
        AddLog("[BloodyBlox] Logs copied to clipboard!")
    else
        AddLog("[BloodyBlox] Clipboard not available")
    end
end)

ClearButton.MouseButton1Click:Connect(function()
    LogHistory = {}
    LogText.Text = ""
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    AddLog("[BloodyBlox] Logs cleared")
end)

local Config = {
    Farm = {AutoFarm = false},
    Rebirth = {AutoRebirth = false, NoRemoveTP = false, FastRebirth = false},
    Combat = {AntiAim = false, AutoKill = false},
    Player = {Fly = false, NoClip = false, Speed = 16},
    Misc = {NoWeightSound = false}
}

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
        local lastRebirthTime = 0
        local rebirthCount = 0

        local function tryRebirth()
            if tick() - lastRebirthTime < 3 then return end

            pcall(function()
                local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
                if not rEvents then
                    print("[AutoRebirth] rEvents not found")
                    return
                end

                local rebirthRemote = rEvents:FindFirstChild("rebirthRemote")
                if not rebirthRemote then
                    print("[AutoRebirth] rebirthRemote not found")
                    return
                end

                lastRebirthTime = tick()
                rebirthCount = rebirthCount + 1

                local success, result = pcall(function()
                    return rebirthRemote:InvokeServer("rebirthRequest")
                end)

                if success then
                    if result then
                        print("[AutoRebirth] Rebirth success! (#" .. rebirthCount .. ")")
                    else
                        print("[AutoRebirth] Rebirth failed - not enough strength (#" .. rebirthCount .. ")")
                    end
                else
                    print("[AutoRebirth] Error: " .. tostring(result))
                end
            end)
        end

        Connections.AutoRebirthTimer = RunService.Heartbeat:Connect(function()
            if Config.Rebirth.AutoRebirth then
                tryRebirth()
            end
        end)

        print("[AutoRebirth] Enabled")
    else
        if Connections.AutoRebirthTimer then
            Connections.AutoRebirthTimer:Disconnect()
            Connections.AutoRebirthTimer = nil
        end
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

AddToggle(CombatTab, "Auto Kill", false, function(v)
    Config.Combat.AutoKill = v
    if v then
        Connections.AutoKill = RunService.Heartbeat:Connect(function()
            pcall(function()
                if not Config.Combat.AutoKill then return end

                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") and (remote.Name:lower():find("damage") or remote.Name:lower():find("hit")) then
                                remote:FireServer(player.Character.Humanoid, 999)
                            end
                        end
                    end
                end
            end)
        end)
    else
        if Connections.AutoKill then
            Connections.AutoKill:Disconnect()
            Connections.AutoKill = nil
        end
    end
end)

local function GetPlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local TpDropdown = AddDropdown(TeleportTab, "Teleport", GetPlayers(), function(name)
    pcall(function()
        local target = Players:FindFirstChild(name)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end)
end)

AddButton(TeleportTab, "REFRESH PLAYERS", function()
    TpDropdown.SetOptions(GetPlayers())
end)

AddToggle(PlayerTab, "Fly", false, function(v)
    Config.Player.Fly = v
    if v then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e4
        bg.Parent = hrp

        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not Config.Player.Fly then
                bv:Destroy()
                bg:Destroy()
                Connections.Fly:Disconnect()
                Connections.Fly = nil
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

            bv.Velocity = move * 50
            bg.CFrame = cam.CFrame
        end)
    else
        if Connections.Fly then
            Connections.Fly:Disconnect()
            Connections.Fly = nil
        end
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

AddSlider(PlayerTab, "Speed", 16, 200, 16, function(v)
    Config.Player.Speed = v
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end)
end)

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

AddButton(SettingTab, "EXIT", function()
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    ScreenGui:Destroy()
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    task.wait(0.25)
    Main.Visible = false
    Main.Size = UDim2.new(0, 850, 0, 550)
    Main.Position = UDim2.new(0.5, -425, 0.5, -275)
end)

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement then
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
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            task.wait(0.25)
            Main.Visible = false
            Main.Size = UDim2.new(0, 850, 0, 550)
            Main.Position = UDim2.new(0.5, -425, 0.5, -275)
        else
            Main.Visible = true
            Main.Size = UDim2.new(0, 0, 0, 0)
            Main.Position = UDim2.new(0.5, 0, 0.5, 0)
            TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 850, 0, 550),
                Position = UDim2.new(0.5, -425, 0.5, -275)
            }):Play()
        end
    end
end)

local Watermark = Instance.new("Frame")
Watermark.Size = UDim2.new(0, 200, 0, 42)
Watermark.Position = UDim2.new(0, 12, 0, 12)
Watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Watermark.BorderSizePixel = 0
Watermark.Parent = ScreenGui

local WaterCorner = Instance.new("UICorner")
WaterCorner.CornerRadius = UDim.new(0, 4)
WaterCorner.Parent = Watermark

local WaterStroke = Instance.new("UIStroke")
WaterStroke.Color = Color3.fromRGB(139, 0, 0)
WaterStroke.Thickness = 1.5
WaterStroke.Parent = Watermark

local WaterTitle = Instance.new("TextLabel")
WaterTitle.Size = UDim2.new(1, -16, 0, 18)
WaterTitle.Position = UDim2.new(0, 8, 0, 6)
WaterTitle.BackgroundTransparency = 1
WaterTitle.Text = "BLOODYBLOX 0.3.0"
WaterTitle.TextColor3 = Color3.fromRGB(139, 0, 0)
WaterTitle.TextSize = 12
WaterTitle.Font = Enum.Font.GothamBold
WaterTitle.TextXAlignment = Enum.TextXAlignment.Left
WaterTitle.Parent = Watermark

local WaterSub = Instance.new("TextLabel")
WaterSub.Size = UDim2.new(1, -16, 0, 14)
WaterSub.Position = UDim2.new(0, 8, 0, 22)
WaterSub.BackgroundTransparency = 1
WaterSub.Text = "FPS: 60"
WaterSub.TextColor3 = Color3.fromRGB(120, 120, 130)
WaterSub.TextSize = 10
WaterSub.Font = Enum.Font.Gotham
WaterSub.TextXAlignment = Enum.TextXAlignment.Left
WaterSub.Parent = Watermark

task.spawn(function()
    local lastUpdate = tick()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastUpdate >= 0.5 then
            local fps = math.floor(frames / (tick() - lastUpdate))
            WaterSub.Text = string.format("FPS: %d", fps)
            frames = 0
            lastUpdate = tick()
        end
    end)
end)

Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
task.wait(0.1)
TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 850, 0, 550),
    Position = UDim2.new(0.5, -425, 0.5, -275)
}):Play()

print("✓ BloodyBlox Fixed Edition loaded!")
print("✓ Press INSERT to toggle")
print("✓ Auto Farm: Equips Weight tool and activates")
print("✓ Auto Rebirth: Single-click system")
print("═══════════════════════════════════════")
