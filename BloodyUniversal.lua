-- BloodyBlox Universal v1.0.1 (Deep Anti-Detection)
-- Hardcore obfuscation + anti-tamper layer
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

-- Anti-tamper: delay initialization
task.wait(math.random(2, 5))

-- Polymorphic core
local function poly()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, math.random(16, 24) do
        result = result .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return result
end

-- Encrypted namespace
local ns = {}
ns[poly()] = "1.0.1"
ns[poly()] = {}
ns[poly()] = {}
ns[poly()] = {}
ns[poly()] = {}

-- Service access with retry logic
local function gsvc(name)
    local attempts = 0
    while attempts < 3 do
        local success, result = pcall(function()
            return game:GetService(name)
        end)
        if success then
            return result
        end
        attempts = attempts + 1
        task.wait(0.5)
    end
    return nil
end

local svc = {}
svc[1] = gsvc("Players")
svc[2] = gsvc("RunService")
svc[3] = gsvc("UserInputService")
svc[4] = gsvc("Lighting")
svc[5] = gsvc("VirtualUser")

if not svc[1] or not svc[2] then
    return
end

local plr = svc[1].LocalPlayer
local cam = workspace.CurrentCamera

-- Logging (silent mode)
local logs = {}
local function log(m, c)
    table.insert(logs, 1, {t = os.time(), c = c or "SYS", m = m})
    if #logs > 30 then
        table.remove(logs, 31)
    end
end

-- State machine
local state = {
    active = {},
    conn = {},
    draw = {},
    cfg = {
        fly_speed = 5,
        walk_speed = 50,
        esp = {box = true, name = true, dist = true, hp = true, trace = false, team = false}
    }
}

-- Cleanup with state validation
local function cleanup()
    for _, c in pairs(state.conn) do
        pcall(function() c:Disconnect() end)
    end
    state.conn = {}

    for k, _ in pairs(state.active) do
        state.active[k] = false
    end

    local ch = plr.Character
    if ch then
        local hm = ch:FindFirstChildOfClass("Humanoid")
        if hm then
            hm.WalkSpeed = 16
            hm.PlatformStand = false
        end

        for _, p in ipairs(ch:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
            if p:IsA("BodyVelocity") then
                p:Destroy()
            end
        end
    end

    for _, p in ipairs(workspace:GetChildren()) do
        if p:IsA("Part") and p.Anchored and p.Transparency >= 0.9 then
            p:Destroy()
        end
    end

    svc[4].Brightness = 1
    svc[4].FogEnd = 100000
    svc[4].GlobalShadows = true

    for _, d in ipairs(state.draw) do
        pcall(function() d:Remove() end)
    end
    state.draw = {}

    log("Cleanup complete", "SYS")
end

-- Anti-AFK with jitter
task.spawn(function()
    plr.Idled:Connect(function()
        task.wait(math.random(1, 4))
        svc[5]:ClickButton2(Vector2.new())
    end)
end)

-- FPS (silent fail)
pcall(function() setfpscap(999) end)

-- Fly via CFrame (no BodyVelocity detection)
local function fly_toggle(en)
    state.active.fly = en

    if en then
        local ch = plr.Character
        if not ch then return end

        local hr = ch:FindFirstChild("HumanoidRootPart")
        local hm = ch:FindFirstChildOfClass("Humanoid")
        if not hr or not hm then return end

        -- Store original state
        state.fly_original_gravity = workspace.Gravity

        local tick = 0
        state.conn.fly = svc[2].Heartbeat:Connect(function(dt)
            tick = tick + 1
            if tick % 2 ~= 0 then return end

            if not state.active.fly then return end

            local c = plr.Character
            if not c then return end

            local r = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not r or not h then return end

            -- Disable gravity effect
            local vel = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)

            -- Calculate movement
            local move = Vector3.zero
            local sp = state.cfg.fly_speed * 0.5

            if svc[3]:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if svc[3]:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if svc[3]:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if svc[3]:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if svc[3]:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if svc[3]:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end

            if move.Magnitude > 0 then
                move = move.Unit
                r.CFrame = r.CFrame + (move * sp)
            end

            -- Keep humanoid state
            if h.Sit then
                h.Sit = false
            end
        end)

        log("Fly ON (CFrame)", "MOD")
    else
        if state.conn.fly then
            state.conn.fly:Disconnect()
            state.conn.fly = nil
        end

        log("Fly OFF", "MOD")
    end
end

-- Noclip with sparse checking
local function noclip_toggle(en)
    state.active.noclip = en

    if en then
        local tick = 0
        state.conn.noclip = svc[2].Stepped:Connect(function()
            tick = tick + 1
            if tick % math.random(2, 4) ~= 0 then return end

            if not state.active.noclip then return end

            local ch = plr.Character
            if not ch then return end

            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)

        log("Noclip ON", "MOD")
    else
        if state.conn.noclip then
            state.conn.noclip:Disconnect()
            state.conn.noclip = nil
        end

        local ch = plr.Character
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end

        log("Noclip OFF", "MOD")
    end
end

-- Walk on water (invisible + sparse update)
local function water_toggle(en)
    state.active.water = en

    if en then
        local pl = Instance.new("Part")
        pl.Name = poly()
        pl.Size = Vector3.new(10, 0.2, 10)
        pl.Transparency = 1
        pl.CanCollide = true
        pl.Anchored = true
        pl.Material = Enum.Material.SmoothPlastic
        pl.Parent = workspace

        local tick = 0
        state.conn.water = svc[2].Heartbeat:Connect(function()
            tick = tick + 1
            if tick % 3 ~= 0 then return end

            if not state.active.water then return end

            local ch = plr.Character
            if not ch then return end

            local hr = ch:FindFirstChild("HumanoidRootPart")
            if not hr then return end

            for _, p in ipairs(workspace:GetChildren()) do
                if p:IsA("Part") and p.Transparency == 1 and p.Anchored and p.Size.Y < 1 then
                    p.Position = Vector3.new(hr.Position.X, hr.Position.Y - 3.5, hr.Position.Z)
                    break
                end
            end
        end)

        log("Water Walk ON", "MOD")
    else
        if state.conn.water then
            state.conn.water:Disconnect()
            state.conn.water = nil
        end

        for _, p in ipairs(workspace:GetChildren()) do
            if p:IsA("Part") and p.Transparency == 1 and p.Anchored and p.Size.Y < 1 then
                p:Destroy()
            end
        end

        log("Water Walk OFF", "MOD")
    end
end

-- Speed without hooks (direct WalkSpeed override)
local function speed_toggle(en)
    state.active.speed = en

    if en then
        local ch = plr.Character
        if not ch then return end

        local hm = ch:FindFirstChildOfClass("Humanoid")
        if not hm then return end

        state.conn.speed = svc[2].Heartbeat:Connect(function()
            if not state.active.speed then return end

            local c = plr.Character
            if not c then return end

            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                local sp = state.cfg.walk_speed
                if h.WalkSpeed ~= sp then
                    h.WalkSpeed = sp
                end
            end
        end)

        log("Speed ON (Direct)", "MOD")
    else
        if state.conn.speed then
            state.conn.speed:Disconnect()
            state.conn.speed = nil
        end

        local ch = plr.Character
        if ch then
            local hm = ch:FindFirstChildOfClass("Humanoid")
            if hm then
                hm.WalkSpeed = 16
            end
        end

        log("Speed OFF", "MOD")
    end
end

-- ESP with render throttle
local function esp_toggle(en)
    state.active.esp = en

    if en then
        local tick = 0
        state.conn.esp = svc[2].RenderStepped:Connect(function()
            tick = tick + 1
            if tick % 2 ~= 0 then return end -- Render every 2 frames

            if not state.active.esp then return end

            for _, d in ipairs(state.draw) do
                d:Remove()
            end
            state.draw = {}

            for _, p in ipairs(svc[1]:GetPlayers()) do
                if p == plr then continue end
                if state.cfg.esp.team and p.Team == plr.Team then continue end

                local ch = p.Character
                if not ch then continue end

                local hr = ch:FindFirstChild("HumanoidRootPart")
                local hm = ch:FindFirstChildOfClass("Humanoid")
                if not hr or not hm then continue end

                local pos, vis = cam:WorldToViewportPoint(hr.Position)
                if not vis then continue end

                -- Box
                if state.cfg.esp.box then
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

                    table.insert(state.draw, box)
                end

                -- Name
                if state.cfg.esp.name then
                    local txt = Drawing.new("Text")
                    txt.Visible = true
                    txt.Color = Color3.new(1, 1, 1)
                    txt.Text = p.Name
                    txt.Size = 14
                    txt.Center = true
                    txt.Outline = true
                    txt.Position = Vector2.new(pos.X, pos.Y - 30)

                    table.insert(state.draw, txt)
                end

                -- Distance
                if state.cfg.esp.dist then
                    local dist = (hr.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    local dtxt = Drawing.new("Text")
                    dtxt.Visible = true
                    dtxt.Color = Color3.new(1, 1, 1)
                    dtxt.Text = string.format("[%d]", math.floor(dist))
                    dtxt.Size = 12
                    dtxt.Center = true
                    dtxt.Outline = true
                    dtxt.Position = Vector2.new(pos.X, pos.Y + 25)

                    table.insert(state.draw, dtxt)
                end

                -- Health
                if state.cfg.esp.hp then
                    local hp = hm.Health / hm.MaxHealth

                    local hpbar = Drawing.new("Square")
                    hpbar.Visible = true
                    hpbar.Color = Color3.fromRGB(0, 255, 0)
                    hpbar.Thickness = 1
                    hpbar.Transparency = 1
                    hpbar.Filled = true
                    hpbar.Size = Vector2.new(40 * hp, 4)
                    hpbar.Position = Vector2.new(pos.X - 20, pos.Y + 15)

                    table.insert(state.draw, hpbar)
                end

                -- Tracers
                if state.cfg.esp.trace then
                    local line = Drawing.new("Line")
                    line.Visible = true
                    line.Color = Color3.new(1, 1, 1)
                    line.Thickness = 1
                    line.Transparency = 1
                    line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)

                    table.insert(state.draw, line)
                end
            end
        end)

        log("ESP ON", "VIS")
    else
        if state.conn.esp then
            state.conn.esp:Disconnect()
            state.conn.esp = nil
        end

        for _, d in ipairs(state.draw) do
            d:Remove()
        end
        state.draw = {}

        log("ESP OFF", "VIS")
    end
end

-- Fullbright
local function fullbright_toggle(en)
    state.active.fullbright = en

    if en then
        svc[4].Brightness = 2
        svc[4].FogEnd = 1000000
        svc[4].GlobalShadows = false
        svc[4].OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        log("Fullbright ON", "VIS")
    else
        svc[4].Brightness = 1
        svc[4].FogEnd = 100000
        svc[4].GlobalShadows = true
        svc[4].OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        log("Fullbright OFF", "VIS")
    end
end

-- Anti-Aim with variable rotation
local function antiaim_toggle(en)
    state.active.antiaim = en

    if en then
        local angle = 0
        state.conn.antiaim = svc[2].RenderStepped:Connect(function()
            if not state.active.antiaim then return end

            local ch = plr.Character
            if not ch then return end

            local hr = ch:FindFirstChild("HumanoidRootPart")
            if not hr then return end

            angle = angle + math.random(140, 220)
            hr.CFrame = hr.CFrame * CFrame.Angles(0, math.rad(angle), 0)
        end)

        log("Anti-Aim ON", "CMB")
    else
        if state.conn.antiaim then
            state.conn.antiaim:Disconnect()
            state.conn.antiaim = nil
        end

        log("Anti-Aim OFF", "CMB")
    end
end

-- Minimal UI
local function create_ui()
    local sg = Instance.new("ScreenGui")
    sg.Name = poly()
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 550, 0, 400)
    mf.Position = UDim2.new(0.5, -275, 0.5, -200)
    mf.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mf.BackgroundTransparency = 0.1
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.Draggable = true
    mf.Parent = sg

    Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)

    -- Header
    local hdr = Instance.new("Frame", mf)
    hdr.Size = UDim2.new(1, 0, 0, 35)
    hdr.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    hdr.BackgroundTransparency = 0.2
    hdr.BorderSizePixel = 0

    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", hdr)
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Universal"
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local close = Instance.new("TextButton", hdr)
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "X"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.TextSize = 14
    close.Font = Enum.Font.GothamBold

    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 5)

    close.MouseButton1Click:Connect(function()
        mf.Visible = false
    end)

    -- Container
    local cont = Instance.new("ScrollingFrame", mf)
    cont.Size = UDim2.new(1, -10, 1, -45)
    cont.Position = UDim2.new(0, 5, 0, 40)
    cont.BackgroundTransparency = 1
    cont.ScrollBarThickness = 4
    cont.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout", cont)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cont.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    -- Toggle helper
    local function add_toggle(text, callback)
        local frame = Instance.new("Frame", cont)
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 50, 0, 22)
        btn.Position = UDim2.new(1, -58, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        btn.Text = "OFF"
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local active = false
        btn.MouseButton1Click:Connect(function()
            active = not active
            btn.Text = active and "ON" or "OFF"
            btn.BackgroundColor3 = active and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            if callback then callback(active) end
        end)
    end

    -- Slider helper
    local function add_slider(text, min, max, def, callback)
        local frame = Instance.new("Frame", cont)
        frame.Size = UDim2.new(1, -10, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -10, 0, 18)
        label.Position = UDim2.new(0, 8, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. def
        label.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        local slider = Instance.new("Frame", frame)
        slider.Size = UDim2.new(0.92, 0, 0, 6)
        slider.Position = UDim2.new(0.04, 0, 1, -12)
        slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        slider.BorderSizePixel = 0

        Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", slider)
        fill.Size = UDim2.new((def - min)/(max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        fill.BorderSizePixel = 0

        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

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

        svc[3].InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
    end

    -- Build UI
    add_toggle("Fly", fly_toggle)
    add_slider("Fly Speed", 1, 10, 5, function(v) state.cfg.fly_speed = v end)

    add_toggle("Noclip", noclip_toggle)
    add_toggle("Walk On Water", water_toggle)

    add_toggle("Speed", speed_toggle)
    add_slider("Walk Speed", 16, 150, 50, function(v) state.cfg.walk_speed = v end)

    add_toggle("ESP", esp_toggle)
    add_toggle("Fullbright", fullbright_toggle)
    add_toggle("Anti-Aim", antiaim_toggle)

    -- Exit button
    local exit = Instance.new("TextButton", cont)
    exit.Size = UDim2.new(1, -10, 0, 35)
    exit.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    exit.Text = "EXIT"
    exit.TextColor3 = Color3.new(1, 1, 1)
    exit.TextSize = 14
    exit.Font = Enum.Font.GothamBold

    Instance.new("UICorner", exit).CornerRadius = UDim.new(0, 5)

    exit.MouseButton1Click:Connect(function()
        cleanup()
        sg:Destroy()
    end)

    sg.Parent = game:GetService("CoreGui")

    -- Toggle with Insert
    svc[3].InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            mf.Visible = not mf.Visible
        end
    end)

    log("UI loaded", "SYS")
end

-- Init with delay
task.spawn(function()
    task.wait(1)
    create_ui()
    log("System ready", "SYS")
end)

return state
