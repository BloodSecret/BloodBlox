-- BloodyBlox Universal v1.0.3 (BloodyBlox Bypass Integration)
-- Imported detection bypass methods from BloodyBlox.lua
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

--[[
    Critical bypass methods from BloodyBlox.lua:
    - Game load guard (wait for full initialization)
    - Safe call wrappers (pcall protection)
    - LinearVelocity + Attachment for Fly (not BodyVelocity)
    - Noclip with CanCollide backup/restore
    - Fullbright with exact Lighting backup
    - Remote hook validation before use
    - Global singleton protection
]]

-- Wait for game to fully load (CRITICAL - prevents early detection)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

-- Singleton guard
if _G.BloodyUniversalLoaded then
    warn("[BloodyUniversal] Already running")
    return
end
_G.BloodyUniversalLoaded = true

-- Safe call wrapper from BloodyBlox
local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, "not a function"
    end
    return pcall(fn, ...)
end

local function safeDisconnect(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function safeDestroy(obj)
    if obj then
        pcall(function() obj:Destroy() end)
    end
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    _G.BloodyUniversalLoaded = nil
    error("[BloodyUniversal] LocalPlayer unavailable")
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
        lighting = nil
    },
    fly = {
        velocity = nil,
        attachment = nil,
        ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    },
    cfg = {
        fly_speed = 5,
        walk_speed = 50
    },
    drawings = {},
    connections = {}
}

-- Get character safely
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
    -- Disconnect all
    for _, conn in pairs(State.connections) do
        safeDisconnect(conn)
    end
    State.connections = {}

    -- Disable all
    for k, _ in pairs(State.active) do
        State.active[k] = false
    end

    -- Restore Fly
    if State.fly.velocity then
        safeDestroy(State.fly.velocity)
        State.fly.velocity = nil
    end
    if State.fly.attachment then
        safeDestroy(State.fly.attachment)
        State.fly.attachment = nil
    end

    -- Restore Noclip
    for part, original in pairs(State.backup.noclip) do
        if part and part.Parent then
            part.CanCollide = original
        end
    end
    State.backup.noclip = {}

    -- Restore Speed
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
    end

    -- Clear ESP
    for _, draw in ipairs(State.drawings) do
        safeCall(function() draw:Remove() end)
    end
    State.drawings = {}

    -- Restore Fullbright
    if State.backup.lighting then
        local backup = State.backup.lighting
        Lighting.Brightness = backup.Brightness
        Lighting.ClockTime = backup.ClockTime
        Lighting.FogEnd = backup.FogEnd
        Lighting.GlobalShadows = backup.GlobalShadows
        Lighting.OutdoorAmbient = backup.OutdoorAmbient
        Lighting.Ambient = backup.Ambient
        State.backup.lighting = nil
    end
end

-- Fly using LinearVelocity + Attachment (from BloodyBlox - not detected)
local function ToggleFly(enable)
    State.active.fly = enable

    if enable then
        local root = GetRootPart()
        if not root then return end

        -- Create Attachment (required for LinearVelocity)
        local attachment = Instance.new("Attachment")
        attachment.Parent = root
        State.fly.attachment = attachment

        -- Create LinearVelocity (modern physics, not detected like BodyVelocity)
        local velocity = Instance.new("LinearVelocity")
        velocity.MaxForce = math.huge
        velocity.VectorVelocity = Vector3.zero
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.Parent = root
        State.fly.velocity = velocity

        -- Reset controls
        State.fly.ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    else
        if State.fly.velocity then
            safeDestroy(State.fly.velocity)
            State.fly.velocity = nil
        end
        if State.fly.attachment then
            safeDestroy(State.fly.attachment)
            State.fly.attachment = nil
        end
        State.fly.ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
    end
end

local function UpdateFly()
    if not State.active.fly then return end
    if not State.fly.velocity then return end

    local root = GetRootPart()
    if not root then return end

    local cam = Workspace.CurrentCamera
    local move = Vector3.zero
    local speed = State.cfg.fly_speed

    if State.fly.ctrl.w then move = move + cam.CFrame.LookVector end
    if State.fly.ctrl.s then move = move - cam.CFrame.LookVector end
    if State.fly.ctrl.a then move = move - cam.CFrame.RightVector end
    if State.fly.ctrl.d then move = move + cam.CFrame.RightVector end
    if State.fly.ctrl.space then move = move + Vector3.new(0, 1, 0) end
    if State.fly.ctrl.shift then move = move - Vector3.new(0, 1, 0) end

    if move.Magnitude > 0 then
        move = move.Unit * speed * 50
    end

    State.fly.velocity.VectorVelocity = move
end

-- Noclip with backup/restore (from BloodyBlox)
local function ToggleNoclip(enable)
    State.active.noclip = enable

    if enable then
        local char = GetCharacter()
        if not char then return end

        -- Backup original CanCollide values
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                State.backup.noclip[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    else
        -- Restore original values
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

-- Speed (direct override)
local function ToggleSpeed(enable)
    State.active.speed = enable

    if not enable then
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = 16
        end
    end
end

local function UpdateSpeed()
    if not State.active.speed then return end

    local hum = GetHumanoid()
    if hum and hum.WalkSpeed ~= State.cfg.walk_speed then
        hum.WalkSpeed = State.cfg.walk_speed
    end
end

-- Fullbright with exact backup (from BloodyBlox)
local function ToggleFullbright(enable)
    State.active.fullbright = enable

    if enable then
        -- Backup original values
        if not State.backup.lighting then
            State.backup.lighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Ambient = Lighting.Ambient
            }
        end

        -- Apply fullbright
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
    else
        -- Restore backup
        if State.backup.lighting then
            local backup = State.backup.lighting
            Lighting.Brightness = backup.Brightness
            Lighting.ClockTime = backup.ClockTime
            Lighting.FogEnd = backup.FogEnd
            Lighting.GlobalShadows = backup.GlobalShadows
            Lighting.OutdoorAmbient = backup.OutdoorAmbient
            Lighting.Ambient = backup.Ambient
            State.backup.lighting = nil
        end
    end
end

-- ESP (manual refresh)
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

        -- Distance
        local dist = (root.Position - GetRootPart().Position).Magnitude
        local distText = Drawing.new("Text")
        distText.Visible = true
        distText.Color = Color3.new(1, 1, 1)
        distText.Text = string.format("[%d]", math.floor(dist))
        distText.Size = 12
        distText.Center = true
        distText.Outline = true
        distText.Position = Vector2.new(pos.X, pos.Y + 25)

        table.insert(State.drawings, distText)
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

-- Input handling
State.connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    local key = input.KeyCode

    -- Fly controls
    if key == Enum.KeyCode.W then State.fly.ctrl.w = true end
    if key == Enum.KeyCode.A then State.fly.ctrl.a = true end
    if key == Enum.KeyCode.S then State.fly.ctrl.s = true end
    if key == Enum.KeyCode.D then State.fly.ctrl.d = true end
    if key == Enum.KeyCode.Space then State.fly.ctrl.space = true end
    if key == Enum.KeyCode.LeftShift then State.fly.ctrl.shift = true end

    -- Toggle hotkeys
    if key == Enum.KeyCode.F then ToggleFly(not State.active.fly) end
    if key == Enum.KeyCode.C then ToggleNoclip(not State.active.noclip) end
    if key == Enum.KeyCode.V then ToggleSpeed(not State.active.speed) end
    if key == Enum.KeyCode.B then ToggleESP(not State.active.esp) end
    if key == Enum.KeyCode.N then ToggleFullbright(not State.active.fullbright) end
    if key == Enum.KeyCode.End then Cleanup() end
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

-- Character respawn handler
State.connections.characterAdded = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if State.active.noclip then ToggleNoclip(true) end
    if State.active.speed then ToggleSpeed(true) end
end)

-- Notification
task.spawn(function()
    task.wait(2)
    local StarterGui = game:GetService("StarterGui")
    safeCall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "BloodyBlox Universal v1.0.3";
            Text = "F=Fly C=Noclip V=Speed B=ESP N=Fullbright End=Exit";
            Duration = 10;
        })
    end)
end)

return {
    State = State,
    Cleanup = Cleanup,
    ToggleFly = ToggleFly,
    ToggleNoclip = ToggleNoclip,
    ToggleSpeed = ToggleSpeed,
    ToggleESP = ToggleESP,
    ToggleFullbright = ToggleFullbright
}
