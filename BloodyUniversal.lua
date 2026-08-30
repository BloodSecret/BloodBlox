-- BloodyBlox Universal v1.0.4 (UI Restored + Zero-Physics Fly)
-- Full UI + Gravity-based Fly (no BodyVelocity, no LinearVelocity)
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

-- Game load guard
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

-- Singleton protection
if _G.BloodyUniversalLoaded then
    warn("[BloodyUniversal] Already running")
    return
end
_G.BloodyUniversalLoaded = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    _G.BloodyUniversalLoaded = nil
    error("[BloodyUniversal] LocalPlayer unavailable")
end

-- Safe wrappers
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

local function safeDisconnect(conn)
    pcall(function() if conn then conn:Disconnect() end end)
end

local function safeDestroy(obj)
    pcall(function() if obj then obj:Destroy() end end)
end

-- State
local State = {
    active = {
        fly = false,
        noclip = false,
        speed = false,
        esp = false,
        fullbright = false
    },
    backup = {
        noclip = {},
        lighting = nil,
        gravity = nil
    },
    fly = {
        ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    },
    cfg = {
        fly_speed = 5,
        walk_speed = 50
    },
    drawings = {},
    connections = {},
    ui = nil
}

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Cleanup
local function Cleanup()
    for _, conn in pairs(State.connections) do
        safeDisconnect(conn)
    end
    State.connections = {}

    for k, _ in pairs(State.active) do
        State.active[k] = false
    end

    -- Restore gravity
    if State.backup.gravity then
        Workspace.Gravity = State.backup.gravity
        State.backup.gravity = nil
    end

    -- Restore noclip
    for part, original in pairs(State.backup.noclip) do
        if part and part.Parent then
            part.CanCollide = original
        end
    end
    State.backup.noclip = {}

    -- Restore speed
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
    end

    -- Clear ESP
    for _, draw in ipairs(State.drawings) do
        safeCall(function() draw:Remove() end)
    end
    State.drawings = {}

    -- Restore fullbright
    if State.backup.lighting then
        local backup = State.backup.lighting
        Lighting.Brightness = backup.Brightness
        Lighting.ClockTime = backup.ClockTime
        Lighting.FogEnd = backup.FogEnd
        Lighting.GlobalShadows = backup.GlobalShadows
        Lighting.OutdoorAmbient = backup.OutdoorAmbient
        State.backup.lighting = nil
    end
end

-- Fly using Gravity manipulation + CFrame (NO physics objects)
local function ToggleFly(enable)
    State.active.fly = enable

    if enable then
        -- Backup and disable gravity
        State.backup.gravity = Workspace.Gravity
        Workspace.Gravity = 0

        -- Reset controls
        State.fly.ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    else
        -- Restore gravity
        if State.backup.gravity then
            Workspace.Gravity = State.backup.gravity
            State.backup.gravity = nil
        end
        State.fly.ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    end
end

local function UpdateFly()
    if not State.active.fly then return end

    local root = GetRootPart()
    if not root then return end

    local cam = Workspace.CurrentCamera
    local move = Vector3.zero
    local speed = State.cfg.fly_speed * 0.5

    if State.fly.ctrl.w then move = move + cam.CFrame.LookVector end
    if State.fly.ctrl.s then move = move - cam.CFrame.LookVector end
    if State.fly.ctrl.a then move = move - cam.CFrame.RightVector end
    if State.fly.ctrl.d then move = move + cam.CFrame.RightVector end
    if State.fly.ctrl.space then move = move + Vector3.new(0, 1, 0) end
    if State.fly.ctrl.shift then move = move - Vector3.new(0, 1, 0) end

    if move.Magnitude > 0 then
        root.CFrame = root.CFrame + (move.Unit * speed)
    end

    -- Cancel any remaining velocity
    root.AssemblyLinearVelocity = Vector3.zero
end

-- Noclip with backup
local function ToggleNoclip(enable)
    State.active.noclip = enable

    if enable then
        local char = GetCharacter()
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                State.backup.noclip[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    else
        for part, original in pairs(State.backup.noclip) do
            if part and part.Parent then
                part.CanCollide = original
            end
        end
        State.backup.noclip = {}
    end
end

local function UpdateNoclip()
    if not State.active.noclip then return end

    local char = GetCharacter()
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

-- Speed
local function ToggleSpeed(enable)
    State.active.speed = enable
    if not enable then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = 16 end
    end
end

local function UpdateSpeed()
    if not State.active.speed then return end
    local hum = GetHumanoid()
    if hum and hum.WalkSpeed ~= State.cfg.walk_speed then
        hum.WalkSpeed = State.cfg.walk_speed
    end
end

-- Fullbright
local function ToggleFullbright(enable)
    State.active.fullbright = enable

    if enable then
        if not State.backup.lighting then
            State.backup.lighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient
            }
        end

        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        if State.backup.lighting then
            local backup = State.backup.lighting
            Lighting.Brightness = backup.Brightness
            Lighting.ClockTime = backup.ClockTime
            Lighting.FogEnd = backup.FogEnd
            Lighting.GlobalShadows = backup.GlobalShadows
            Lighting.OutdoorAmbient = backup.OutdoorAmbient
            State.backup.lighting = nil
        end
    end
end

-- ESP
local function ClearESP()
    for _, draw in ipairs(State.drawings) do
        safeCall(function() draw:Remove() end)
    end
    State.drawings = {}
end

local function DrawESP()
    if not State.active.esp then return end

    ClearESP()

    local cam = Workspace.CurrentCamera

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then continue end

        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
        if not onScreen then continue end

        -- Box
        local box = Drawing.new("Square")
        box.Visible = true
        box.Color = Color3.new(1, 1, 1)
        box.Thickness = 1
        box.Transparency = 1
        box.Filled = false

        local head = char:FindFirstChild("Head")
        local headPos = head and head.Position or root.Position
        local topPos = cam:WorldToViewportPoint(headPos + Vector3.new(0, 0.5, 0))
        local bottomPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        local height = math.abs(topPos.Y - bottomPos.Y)
        local width = height / 2

        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)

        table.insert(State.drawings, box)

        -- Name
        local name = Drawing.new("Text")
        name.Visible = true
        name.Color = Color3.new(1, 1, 1)
        name.Text = player.Name
        name.Size = 14
        name.Center = true
        name.Outline = true
        name.Position = Vector2.new(pos.X, pos.Y - 30)

        table.insert(State.drawings, name)
    end
end

local function ToggleESP(enable)
    State.active.esp = enable
    if enable then
        DrawESP()
    else
        ClearESP()
    end
end

-- UI System
local function CreateUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BloodyUniversalUI"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 500, 0, 400)
    mf.Position = UDim2.new(0.5, -250, 0.5, -200)
    mf.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mf.BackgroundTransparency = 0.1
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.Draggable = true
    mf.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mf

    -- Header
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 35)
    hdr.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    hdr.BackgroundTransparency = 0.2
    hdr.BorderSizePixel = 0
    hdr.Parent = mf

    local hcorner = Instance.new("UICorner")
    hcorner.CornerRadius = UDim.new(0, 10)
    hcorner.Parent = hdr

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BloodyBlox Universal v1.0.4"
    title.TextColor3 = Color3.fromRGB(255, 50, 50)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = hdr

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.TextSize = 14
    close.Font = Enum.Font.GothamBold
    close.Parent = hdr

    local ccorner = Instance.new("UICorner")
    ccorner.CornerRadius = UDim.new(0, 5)
    ccorner.Parent = close

    close.MouseButton1Click:Connect(function()
        mf.Visible = false
    end)

    -- Container
    local cont = Instance.new("ScrollingFrame")
    cont.Size = UDim2.new(1, -10, 1, -45)
    cont.Position = UDim2.new(0, 5, 0, 40)
    cont.BackgroundTransparency = 1
    cont.ScrollBarThickness = 4
    cont.CanvasSize = UDim2.new(0, 0, 0, 0)
    cont.Parent = mf

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = cont

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cont.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- Toggle function
    local function addToggle(text, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = cont

        local fcorner = Instance.new("UICorner")
        fcorner.CornerRadius = UDim.new(0, 5)
        fcorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 22)
        btn.Position = UDim2.new(1, -58, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        btn.Text = "OFF"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = frame

        local bcorner = Instance.new("UICorner")
        bcorner.CornerRadius = UDim.new(0, 4)
        bcorner.Parent = btn

        local active = false
        btn.MouseButton1Click:Connect(function()
            active = not active
            btn.Text = active and "ON" or "OFF"
            btn.BackgroundColor3 = active and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            if callback then callback(active) end
        end)
    end

    -- Slider function
    local function addSlider(text, min, max, def, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = cont

        local fcorner = Instance.new("UICorner")
        fcorner.CornerRadius = UDim.new(0, 5)
        fcorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 18)
        label.Position = UDim2.new(0, 8, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. def
        label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(0.92, 0, 0, 6)
        slider.Position = UDim2.new(0.04, 0, 1, -12)
        slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        slider.BorderSizePixel = 0
        slider.Parent = frame

        local scorner = Instance.new("UICorner")
        scorner.CornerRadius = UDim.new(1, 0)
        scorner.Parent = slider

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def - min)/(max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fill.BorderSizePixel = 0
        fill.Parent = slider

        local fcorner2 = Instance.new("UICorner")
        fcorner2.CornerRadius = UDim.new(1, 0)
        fcorner2.Parent = fill

        local dragging = false
        local val = def

        local function update(input)
            local rx = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * rx)
            fill.Size = UDim2.new(rx, 0, 1, 0)
            label.Text = text .. ": " .. val
            if callback then callback(val) end
        end

        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                update(input)
            end
        end)

        slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
    end

    -- Button function
    local function addButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.Parent = cont

        local bcorner = Instance.new("UICorner")
        bcorner.CornerRadius = UDim.new(0, 5)
        bcorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
    end

    -- Build UI
    addToggle("Fly", ToggleFly)
    addSlider("Fly Speed", 1, 10, 5, function(v)
        State.cfg.fly_speed = v
    end)

    addToggle("Noclip", ToggleNoclip)

    addToggle("Speed", ToggleSpeed)
    addSlider("Walk Speed", 16, 150, 50, function(v)
        State.cfg.walk_speed = v
    end)

    addToggle("ESP", ToggleESP)
    addToggle("Fullbright", ToggleFullbright)

    addButton("EXIT", function()
        Cleanup()
        sg:Destroy()
    end)

    sg.Parent = CoreGui

    State.ui = sg

    -- Toggle with Insert
    State.connections.toggleUI = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            mf.Visible = not mf.Visible
        end
    end)
end

-- Input handling (for fly controls)
State.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    local key = input.KeyCode

    if key == Enum.KeyCode.W then State.fly.ctrl.w = true end
    if key == Enum.KeyCode.A then State.fly.ctrl.a = true end
    if key == Enum.KeyCode.S then State.fly.ctrl.s = true end
    if key == Enum.KeyCode.D then State.fly.ctrl.d = true end
    if key == Enum.KeyCode.Space then State.fly.ctrl.space = true end
    if key == Enum.KeyCode.LeftShift then State.fly.ctrl.shift = true end
end)

State.connections.inputEnded = UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end

    local key = input.KeyCode

    if key == Enum.KeyCode.W then State.fly.ctrl.w = false end
    if key == Enum.KeyCode.A then State.fly.ctrl.a = false end
    if key == Enum.KeyCode.S then State.fly.ctrl.s = false end
    if key == Enum.KeyCode.D then State.fly.ctrl.d = false end
    if key == Enum.KeyCode.Space then State.fly.ctrl.space = false end
    if key == Enum.KeyCode.LeftShift then State.fly.ctrl.shift = false end
end)

-- Main update loop
task.spawn(function()
    while task.wait(0.03) do
        safeCall(UpdateFly)
        safeCall(UpdateNoclip)
        safeCall(UpdateSpeed)
    end
end)

-- Character respawn
State.connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.active.noclip then ToggleNoclip(true) end
    if State.active.speed then ToggleSpeed(true) end
end)

-- Initialize
task.spawn(function()
    task.wait(2)
    CreateUI()

    safeCall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "BloodyBlox Universal v1.0.4";
            Text = "Insert to toggle menu";
            Duration = 8;
        })
    end)
end)

return {State = State, Cleanup = Cleanup}
