-- BloodyBlox Universal v1.0.2 (Stealth Mode)
-- Ultra-minimal approach - no Heartbeat/RenderStepped connections
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

-- Delay initialization
task.wait(math.random(3, 6))

-- Services
local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local light = game:GetService("Lighting")

local plr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

-- State
local enabled = {
    fly = false,
    noclip = false,
    speed = false,
    esp = false,
    fb = false
}

local cfg = {
    fly_speed = 5,
    walk_speed = 50
}

-- Fly via player input only (no loop)
local fly_ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}

local function update_fly()
    if not enabled.fly then return end

    local ch = plr.Character
    if not ch then return end

    local hr = ch:FindFirstChild("HumanoidRootPart")
    if not hr then return end

    local move = Vector3.zero
    local sp = cfg.fly_speed * 0.4

    if fly_ctrl.w then move = move + cam.CFrame.LookVector end
    if fly_ctrl.s then move = move - cam.CFrame.LookVector end
    if fly_ctrl.a then move = move - cam.CFrame.RightVector end
    if fly_ctrl.d then move = move + cam.CFrame.RightVector end
    if fly_ctrl.space then move = move + Vector3.new(0, 1, 0) end
    if fly_ctrl.shift then move = move - Vector3.new(0, 1, 0) end

    if move.Magnitude > 0 then
        hr.CFrame = hr.CFrame + (move.Unit * sp)
    end

    -- Cancel gravity
    local vel = hr.AssemblyLinearVelocity
    hr.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
end

-- Noclip via CharacterAdded only
local function setup_noclip()
    if not enabled.noclip then return end

    local ch = plr.Character
    if not ch then return end

    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end

-- Speed via direct set (no loop needed)
local function apply_speed()
    if not enabled.speed then return end

    local ch = plr.Character
    if not ch then return end

    local hm = ch:FindFirstChildOfClass("Humanoid")
    if hm then
        hm.WalkSpeed = cfg.walk_speed
    end
end

-- Fullbright
local function toggle_fullbright(state)
    enabled.fb = state

    if state then
        light.Brightness = 2
        light.FogEnd = 1000000
        light.GlobalShadows = false
        light.Ambient = Color3.new(1, 1, 1)
    else
        light.Brightness = 1
        light.FogEnd = 100000
        light.GlobalShadows = true
        light.Ambient = Color3.new(0.5, 0.5, 0.5)
    end
end

-- ESP (manual trigger only, no auto-update)
local esp_drawings = {}

local function clear_esp()
    for _, d in ipairs(esp_drawings) do
        pcall(function() d:Remove() end)
    end
    esp_drawings = {}
end

local function draw_esp()
    if not enabled.esp then return end

    clear_esp()

    for _, p in ipairs(plrs:GetPlayers()) do
        if p == plr then continue end

        local ch = p.Character
        if not ch then continue end

        local hr = ch:FindFirstChild("HumanoidRootPart")
        local hm = ch:FindFirstChildOfClass("Humanoid")
        if not hr or not hm then continue end

        local pos, vis = cam:WorldToViewportPoint(hr.Position)
        if not vis then continue end

        -- Box
        local box = Drawing.new("Square")
        box.Visible = true
        box.Color = Color3.new(1, 1, 1)
        box.Thickness = 1
        box.Transparency = 1
        box.Filled = false

        local head = ch:FindFirstChild("Head")
        local hpos = head and head.Position or hr.Position
        local tpos = cam:WorldToViewportPoint(hpos + Vector3.new(0, 0.5, 0))
        local bpos = cam:WorldToViewportPoint(hr.Position - Vector3.new(0, 3, 0))

        local h = math.abs(tpos.Y - bpos.Y)
        local w = h / 2

        box.Size = Vector2.new(w, h)
        box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)

        table.insert(esp_drawings, box)

        -- Name
        local txt = Drawing.new("Text")
        txt.Visible = true
        txt.Color = Color3.new(1, 1, 1)
        txt.Text = p.Name
        txt.Size = 14
        txt.Center = true
        txt.Outline = true
        txt.Position = Vector2.new(pos.X, pos.Y - 30)

        table.insert(esp_drawings, txt)
    end
end

-- Cleanup
local function cleanup()
    enabled.fly = false
    enabled.noclip = false
    enabled.speed = false
    enabled.esp = false

    clear_esp()

    local ch = plr.Character
    if ch then
        local hm = ch:FindFirstChildOfClass("Humanoid")
        if hm then
            hm.WalkSpeed = 16
        end

        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
    end

    toggle_fullbright(false)
end

-- Input handler (direct, no connections stored)
uis.InputBegan:Connect(function(input, gp)
    if gp then return end

    local key = input.KeyCode

    -- Fly controls
    if key == Enum.KeyCode.W then fly_ctrl.w = true end
    if key == Enum.KeyCode.A then fly_ctrl.a = true end
    if key == Enum.KeyCode.S then fly_ctrl.s = true end
    if key == Enum.KeyCode.D then fly_ctrl.d = true end
    if key == Enum.KeyCode.Space then fly_ctrl.space = true end
    if key == Enum.KeyCode.LeftShift then fly_ctrl.shift = true end

    -- Toggle keys
    if key == Enum.KeyCode.F then
        enabled.fly = not enabled.fly
        if not enabled.fly then
            fly_ctrl = {w=false,a=false,s=false,d=false,space=false,shift=false}
        end
    end

    if key == Enum.KeyCode.C then
        enabled.noclip = not enabled.noclip
        setup_noclip()
    end

    if key == Enum.KeyCode.V then
        enabled.speed = not enabled.speed
        apply_speed()
    end

    if key == Enum.KeyCode.B then
        enabled.esp = not enabled.esp
        if enabled.esp then
            draw_esp()
        else
            clear_esp()
        end
    end

    if key == Enum.KeyCode.N then
        toggle_fullbright(not enabled.fb)
    end

    if key == Enum.KeyCode.End then
        cleanup()
    end
end)

uis.InputEnded:Connect(function(input, gp)
    if gp then return end

    local key = input.KeyCode

    if key == Enum.KeyCode.W then fly_ctrl.w = false end
    if key == Enum.KeyCode.A then fly_ctrl.a = false end
    if key == Enum.KeyCode.S then fly_ctrl.s = false end
    if key == Enum.KeyCode.D then fly_ctrl.d = false end
    if key == Enum.KeyCode.Space then fly_ctrl.space = false end
    if key == Enum.KeyCode.LeftShift then fly_ctrl.shift = false end
end)

-- Minimal update loop (only for fly physics)
task.spawn(function()
    while task.wait(0.03) do
        if enabled.fly then
            pcall(update_fly)
        end

        if enabled.noclip then
            pcall(setup_noclip)
        end

        if enabled.speed then
            pcall(apply_speed)
        end
    end
end)

-- Character respawn handler
plr.CharacterAdded:Connect(function(ch)
    task.wait(1)
    if enabled.noclip then setup_noclip() end
    if enabled.speed then apply_speed() end
end)

-- Silent notification
task.spawn(function()
    task.wait(1)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Universal";
        Text = "F=Fly C=Noclip V=Speed B=ESP N=FB End=Exit";
        Duration = 8;
    })
end)

return {enabled = enabled, cfg = cfg, cleanup = cleanup}
