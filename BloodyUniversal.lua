-- BloodyBlox Universal v1.0.0 (Anti-Detection)
-- Cross-game exploit framework with obfuscation
-- Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyUniversal.lua"))()

local _G = {}
_G.v = "1.0.0"
_G.e = {}
_G.c = {}
_G.u = {}
_G.l = {}

-- Obfuscated service access
local s1 = game:GetService("Players")
local s2 = game:GetService("RunService")
local s3 = game:GetService("UserInputService")
local s4 = game:GetService("Lighting")
local s5 = game:GetService("StarterGui")
local s6 = game:GetService("VirtualUser")

local p = s1.LocalPlayer
local cam = workspace.CurrentCamera

-- Randomized names generator
local function rn()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local result = "_"
    for i = 1, math.random(8, 12) do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end

-- Logging (obfuscated)
local function lg(m, c)
    c = c or "INFO"
    local t = os.date("%H:%M:%S")
    local e = string.format("[%s][%s] %s", t, c, m)

    if not _G.l then
        _G.l = {}
    end

    table.insert(_G.l, 1, e)

    if #_G.l > 30 then
        table.remove(_G.l, 31)
    end
end

-- Cleanup (obfuscated)
local function clr()
    lg("Cleanup start", "SYS")

    for n, cn in pairs(_G.c) do
        if cn and typeof(cn) == "RBXScriptConnection" then
            pcall(function() cn:Disconnect() end)
        end
    end
    _G.c = {}

    for f, _ in pairs(_G.e) do
        _G.e[f] = false
    end

    local ch = p.Character
    if ch then
        local hm = ch:FindFirstChildOfClass("Humanoid")
        local hr = ch:FindFirstChild("HumanoidRootPart")

        if hm then
            hm.WalkSpeed = 16
        end

        if hr then
            for _, obj in ipairs(hr:GetChildren()) do
                if obj:IsA("BodyVelocity") then
                    obj:Destroy()
                end
            end
        end

        for _, pt in ipairs(ch:GetDescendants()) do
            if pt:IsA("BasePart") then
                pt.CanCollide = true
            end
        end

        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Part") and obj.Transparency == 1 and obj.Size == Vector3.new(10, 0.5, 10) then
                obj:Destroy()
            end
        end
    end

    s4.Brightness = 1
    s4.ClockTime = 14
    s4.FogEnd = 100000
    s4.GlobalShadows = true
    s4.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

    for _, d in ipairs(_G.ed or {}) do
        if d then
            pcall(function() d:Remove() end)
        end
    end
    _G.ed = {}

    lg("Cleanup done", "SYS")
end

-- Anti-AFK
local function aafk()
    p.Idled:Connect(function()
        task.wait(math.random(1, 3))
        s6:ClickButton2(Vector2.new())
        lg("AFK bypass", "SYS")
    end)
end

-- FPS Unlock
pcall(function()
    setfpscap(999)
    lg("FPS unlocked", "SYS")
end)

-- Fly
function _G.tfly(en, sp)
    _G.e.fly = en
    sp = sp or 5

    if en then
        local ch = p.Character
        if not ch then return end

        local hr = ch:FindFirstChild("HumanoidRootPart")
        if not hr then return end

        local bvn = rn()
        local bv = hr:FindFirstChild(bvn) or Instance.new("BodyVelocity")
        bv.Name = bvn
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hr

        _G.c.fly = s2.Heartbeat:Connect(function()
            if not _G.e.fly then return end

            local c = p.Character
            if not c then return end

            local r = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not r or not h then return end

            local v = Vector3.new(0, 0, 0)
            local m = 50 + math.random(-5, 5)

            if s3:IsKeyDown(Enum.KeyCode.W) then
                v = v + cam.CFrame.LookVector * sp
            end
            if s3:IsKeyDown(Enum.KeyCode.S) then
                v = v - cam.CFrame.LookVector * sp
            end
            if s3:IsKeyDown(Enum.KeyCode.A) then
                v = v - cam.CFrame.RightVector * sp
            end
            if s3:IsKeyDown(Enum.KeyCode.D) then
                v = v + cam.CFrame.RightVector * sp
            end
            if s3:IsKeyDown(Enum.KeyCode.Space) then
                v = v + Vector3.new(0, sp, 0)
            end
            if s3:IsKeyDown(Enum.KeyCode.LeftShift) then
                v = v - Vector3.new(0, sp, 0)
            end

            for _, b in ipairs(r:GetChildren()) do
                if b:IsA("BodyVelocity") then
                    b.Velocity = v * m
                end
            end

            h.PlatformStand = true
        end)

        lg("Fly ON (" .. sp .. ")", "PLR")
    else
        if _G.c.fly then
            _G.c.fly:Disconnect()
            _G.c.fly = nil
        end

        local ch = p.Character
        if ch then
            local hr = ch:FindFirstChild("HumanoidRootPart")
            local hm = ch:FindFirstChildOfClass("Humanoid")

            if hr then
                for _, b in ipairs(hr:GetChildren()) do
                    if b:IsA("BodyVelocity") then
                        b:Destroy()
                    end
                end
            end

            if hm then
                hm.PlatformStand = false
            end
        end

        lg("Fly OFF", "PLR")
    end
end

-- Noclip
function _G.tnc(en)
    _G.e.nc = en

    if en then
        local tk = 0
        _G.c.nc = s2.Stepped:Connect(function()
            tk = tk + 1
            if tk % math.random(1, 3) ~= 0 then return end

            if not _G.e.nc then return end

            local ch = p.Character
            if not ch then return end

            for _, pt in ipairs(ch:GetDescendants()) do
                if pt:IsA("BasePart") then
                    pt.CanCollide = false
                end
            end
        end)

        lg("Noclip ON", "PLR")
    else
        if _G.c.nc then
            _G.c.nc:Disconnect()
            _G.c.nc = nil
        end

        local ch = p.Character
        if ch then
            for _, pt in ipairs(ch:GetDescendants()) do
                if pt:IsA("BasePart") then
                    pt.CanCollide = true
                end
            end
        end

        lg("Noclip OFF", "PLR")
    end
end

-- Walk On Water
function _G.tww(en)
    _G.e.ww = en

    if en then
        local pn = rn()
        local pl = Instance.new("Part")
        pl.Name = pn
        pl.Size = Vector3.new(10, 0.5, 10)
        pl.Transparency = 1
        pl.CanCollide = true
        pl.Anchored = true
        pl.Parent = workspace

        _G.c.ww = s2.Heartbeat:Connect(function()
            if not _G.e.ww then return end

            local ch = p.Character
            if not ch then return end

            local hr = ch:FindFirstChild("HumanoidRootPart")
            if not hr then return end

            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Part") and obj.Transparency == 1 and obj.Size == Vector3.new(10, 0.5, 10) then
                    local wl = workspace.Terrain:WorldToCell(hr.Position).Y * 4
                    obj.Position = Vector3.new(hr.Position.X, wl - 3, hr.Position.Z)
                    break
                end
            end
        end)

        lg("Water Walk ON", "PLR")
    else
        if _G.c.ww then
            _G.c.ww:Disconnect()
            _G.c.ww = nil
        end

        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Part") and obj.Transparency == 1 and obj.Size == Vector3.new(10, 0.5, 10) then
                obj:Destroy()
            end
        end

        lg("Water Walk OFF", "PLR")
    end
end

-- Speed
function _G.tsp(en, sp)
    _G.e.sp = en
    sp = sp or 50

    if en then
        local ch = p.Character
        if not ch then return end

        local hm = ch:FindFirstChildOfClass("Humanoid")
        if not hm then return end

        local oi
        oi = hookmetamethod(game, "__index", function(s, k)
            if s == hm and k == "WalkSpeed" and _G.e.sp then
                return sp
            end
            return oi(s, k)
        end)

        local oni
        oni = hookmetamethod(game, "__newindex", function(s, k, v)
            if s == hm and k == "WalkSpeed" and _G.e.sp then
                return
            end
            return oni(s, k, v)
        end)

        hm.WalkSpeed = sp

        _G.c.sp = s2.Heartbeat:Connect(function()
            if not _G.e.sp then return end

            local c = p.Character
            if not c then return end

            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.WalkSpeed ~= sp then
                h.WalkSpeed = sp
            end
        end)

        lg("Speed ON (" .. sp .. ")", "PLR")
    else
        if _G.c.sp then
            _G.c.sp:Disconnect()
            _G.c.sp = nil
        end

        local ch = p.Character
        if ch then
            local hm = ch:FindFirstChildOfClass("Humanoid")
            if hm then
                hm.WalkSpeed = 16
            end
        end

        lg("Speed OFF", "PLR")
    end
end

-- ESP
_G.esp = {
    en = false,
    bx = true,
    nm = true,
    ds = true,
    hp = true,
    tr = false,
    tm = false
}

_G.ed = {}

function _G.tesp(en)
    _G.esp.en = en

    if en then
        _G.c.esp = s2.RenderStepped:Connect(function()
            if not _G.esp.en then return end

            for _, d in ipairs(_G.ed) do
                d:Remove()
            end
            _G.ed = {}

            for _, pl in ipairs(s1:GetPlayers()) do
                if pl == p then continue end

                if _G.esp.tm and pl.Team == p.Team then
                    continue
                end

                local ch = pl.Character
                if not ch then continue end

                local hr = ch:FindFirstChild("HumanoidRootPart")
                local hm = ch:FindFirstChildOfClass("Humanoid")
                if not hr or not hm then continue end

                local vc, vs = cam:WorldToViewportPoint(hr.Position)

                if vs then
                    if _G.esp.bx then
                        local bx = Drawing.new("Square")
                        bx.Visible = true
                        bx.Color = Color3.new(1, 1, 1)
                        bx.Thickness = 2
                        bx.Transparency = 1
                        bx.Filled = false

                        local hp = ch:FindFirstChild("Head") and ch.Head.Position or hr.Position
                        local lp = hr.Position - Vector3.new(0, 3, 0)

                        local tv = cam:WorldToViewportPoint(hp + Vector3.new(0, 0.5, 0))
                        local bv = cam:WorldToViewportPoint(lp)

                        local h = math.abs(tv.Y - bv.Y)
                        local w = h / 2

                        bx.Size = Vector2.new(w, h)
                        bx.Position = Vector2.new(vc.X - w / 2, vc.Y - h / 2)

                        table.insert(_G.ed, bx)
                    end

                    if _G.esp.nm then
                        local tx = Drawing.new("Text")
                        tx.Visible = true
                        tx.Color = Color3.new(1, 1, 1)
                        tx.Text = pl.Name
                        tx.Size = 16
                        tx.Center = true
                        tx.Outline = true
                        tx.Position = Vector2.new(vc.X, vc.Y - 30)

                        table.insert(_G.ed, tx)
                    end

                    if _G.esp.ds then
                        local dt = (hr.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        local dx = Drawing.new("Text")
                        dx.Visible = true
                        dx.Color = Color3.new(1, 1, 1)
                        dx.Text = string.format("[%.0f]", dt)
                        dx.Size = 14
                        dx.Center = true
                        dx.Outline = true
                        dx.Position = Vector2.new(vc.X, vc.Y + 30)

                        table.insert(_G.ed, dx)
                    end

                    if _G.esp.hp then
                        local hp = hm.Health / hm.MaxHealth

                        local bg = Drawing.new("Square")
                        bg.Visible = true
                        bg.Color = Color3.new(0, 0, 0)
                        bg.Thickness = 1
                        bg.Transparency = 0.5
                        bg.Filled = true
                        bg.Size = Vector2.new(50, 6)
                        bg.Position = Vector2.new(vc.X - 25, vc.Y + 15)

                        local fg = Drawing.new("Square")
                        fg.Visible = true
                        fg.Color = Color3.fromRGB(0, 255, 0)
                        fg.Thickness = 1
                        fg.Transparency = 1
                        fg.Filled = true
                        fg.Size = Vector2.new(50 * hp, 6)
                        fg.Position = Vector2.new(vc.X - 25, vc.Y + 15)

                        table.insert(_G.ed, bg)
                        table.insert(_G.ed, fg)
                    end

                    if _G.esp.tr then
                        local tr = Drawing.new("Line")
                        tr.Visible = true
                        tr.Color = Color3.new(1, 1, 1)
                        tr.Thickness = 1
                        tr.Transparency = 1
                        tr.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        tr.To = Vector2.new(vc.X, vc.Y)

                        table.insert(_G.ed, tr)
                    end
                end
            end
        end)

        lg("ESP ON", "VIS")
    else
        if _G.c.esp then
            _G.c.esp:Disconnect()
            _G.c.esp = nil
        end

        for _, d in ipairs(_G.ed) do
            d:Remove()
        end
        _G.ed = {}

        lg("ESP OFF", "VIS")
    end
end

-- Fullbright
function _G.tfb(en)
    _G.e.fb = en

    if en then
        s4.Brightness = 2
        s4.ClockTime = 14
        s4.FogEnd = 1000000
        s4.GlobalShadows = false
        s4.OutdoorAmbient = Color3.fromRGB(255, 255, 255)

        lg("Fullbright ON", "VIS")
    else
        s4.Brightness = 1
        s4.ClockTime = 14
        s4.FogEnd = 100000
        s4.GlobalShadows = true
        s4.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

        lg("Fullbright OFF", "VIS")
    end
end

-- Anti-Aim
function _G.taa(en)
    _G.e.aa = en

    if en then
        local ag = 0
        _G.c.aa = s2.RenderStepped:Connect(function()
            if not _G.e.aa then return end

            local ch = p.Character
            if not ch then return end

            local hr = ch:FindFirstChild("HumanoidRootPart")
            if not hr then return end

            ag = ag + math.random(150, 210)
            hr.CFrame = hr.CFrame * CFrame.Angles(0, math.rad(ag), 0)
        end)

        lg("Anti-Aim ON", "CMB")
    else
        if _G.c.aa then
            _G.c.aa:Disconnect()
            _G.c.aa = nil
        end

        lg("Anti-Aim OFF", "CMB")
    end
end

-- UI System
local function cui()
    local sg = Instance.new("ScreenGui")
    sg.Name = rn()
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mf = Instance.new("Frame")
    mf.Name = rn()
    mf.Size = UDim2.new(0, 600, 0, 450)
    mf.Position = UDim2.new(0.5, -300, 0.5, -225)
    mf.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mf.BackgroundTransparency = 0.25
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.Draggable = true
    mf.Parent = sg

    local co = Instance.new("UICorner")
    co.CornerRadius = UDim.new(0, 12)
    co.Parent = mf

    local hd = Instance.new("Frame")
    hd.Name = rn()
    hd.Size = UDim2.new(1, 0, 0, 40)
    hd.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    hd.BackgroundTransparency = 0.3
    hd.BorderSizePixel = 0
    hd.ZIndex = 2
    hd.Parent = mf

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 12)
    hc.Parent = hd

    local tt = Instance.new("TextLabel")
    tt.Size = UDim2.new(0.7, 0, 1, 0)
    tt.Position = UDim2.new(0, 15, 0, 0)
    tt.BackgroundTransparency = 1
    tt.Text = "Universal " .. _G.v
    tt.TextColor3 = Color3.fromRGB(255, 50, 50)
    tt.TextSize = 18
    tt.Font = Enum.Font.GothamBold
    tt.TextXAlignment = Enum.TextXAlignment.Left
    tt.ZIndex = 3
    tt.Parent = hd

    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0, 30, 0, 30)
    cb.Position = UDim2.new(1, -40, 0, 5)
    cb.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    cb.Text = "X"
    cb.TextColor3 = Color3.new(1, 1, 1)
    cb.TextSize = 16
    cb.Font = Enum.Font.GothamBold
    cb.ZIndex = 3
    cb.Parent = hd

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = cb

    cb.MouseButton1Click:Connect(function()
        mf.Visible = false
        lg("UI hidden", "UI")
    end)

    local tb = Instance.new("ScrollingFrame")
    tb.Name = rn()
    tb.Size = UDim2.new(1, -20, 1, -60)
    tb.Position = UDim2.new(0, 10, 0, 50)
    tb.BackgroundTransparency = 1
    tb.ScrollBarThickness = 6
    tb.CanvasSize = UDim2.new(0, 0, 0, 0)
    tb.ZIndex = 2
    tb.Parent = mf

    local ly = Instance.new("UIListLayout")
    ly.Padding = UDim.new(0, 10)
    ly.SortOrder = Enum.SortOrder.LayoutOrder
    ly.Parent = tb

    ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tb.CanvasSize = UDim2.new(0, 0, 0, ly.AbsoluteContentSize.Y + 10)
    end)

    _G.u.sg = sg
    _G.u.mf = mf
    _G.u.tb = tb

    return sg
end

local function ctg(pr, tx, cb)
    local tf = Instance.new("Frame")
    tf.Size = UDim2.new(1, -10, 0, 35)
    tf.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    tf.BackgroundTransparency = 0.4
    tf.BorderSizePixel = 0
    tf.ZIndex = 3
    tf.Parent = pr

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = tf

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.7, 0, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = tx
    lb.TextColor3 = Color3.new(1, 1, 1)
    lb.TextSize = 14
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 4
    lb.Parent = tf

    local bt = Instance.new("TextButton")
    bt.Size = UDim2.new(0, 60, 0, 25)
    bt.Position = UDim2.new(1, -70, 0.5, -12.5)
    bt.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    bt.Text = "OFF"
    bt.TextColor3 = Color3.new(1, 1, 1)
    bt.TextSize = 12
    bt.Font = Enum.Font.GothamBold
    bt.ZIndex = 4
    bt.Parent = tf

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = bt

    local en = false
    bt.MouseButton1Click:Connect(function()
        en = not en

        if en then
            bt.Text = "ON"
            bt.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            bt.Text = "OFF"
            bt.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        end

        if cb then
            cb(en)
        end
    end)

    return tf, bt
end

local function csl(pr, tx, mn, mx, df, cb)
    local sf = Instance.new("Frame")
    sf.Size = UDim2.new(1, -10, 0, 50)
    sf.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    sf.BackgroundTransparency = 0.4
    sf.BorderSizePixel = 0
    sf.ZIndex = 3
    sf.Parent = pr

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 6)
    sc.Parent = sf

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -20, 0, 20)
    lb.Position = UDim2.new(0, 10, 0, 5)
    lb.BackgroundTransparency = 1
    lb.Text = tx .. ": " .. df
    lb.TextColor3 = Color3.new(1, 1, 1)
    lb.TextSize = 14
    lb.Font = Enum.Font.Gotham
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 4
    lb.Parent = sf

    local sl = Instance.new("Frame")
    sl.Size = UDim2.new(0.9, 0, 0, 8)
    sl.Position = UDim2.new(0.05, 0, 1, -15)
    sl.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    sl.BorderSizePixel = 0
    sl.ZIndex = 4
    sl.Parent = sf

    local slc = Instance.new("UICorner")
    slc.CornerRadius = UDim.new(1, 0)
    slc.Parent = sl

    local fl = Instance.new("Frame")
    fl.Size = UDim2.new((df - mn) / (mx - mn), 0, 1, 0)
    fl.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    fl.BorderSizePixel = 0
    fl.ZIndex = 5
    fl.Parent = sl

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fl

    local dr = false
    local vl = df

    local function upd(ip)
        local rx = math.clamp((ip.Position.X - sl.AbsolutePosition.X) / sl.AbsoluteSize.X, 0, 1)
        vl = math.floor(mn + (mx - mn) * rx)

        fl.Size = UDim2.new(rx, 0, 1, 0)
        lb.Text = tx .. ": " .. vl

        if cb then
            cb(vl)
        end
    end

    sl.InputBegan:Connect(function(ip)
        if ip.UserInputType == Enum.UserInputType.MouseButton1 then
            dr = true
            upd(ip)
        end
    end)

    sl.InputEnded:Connect(function(ip)
        if ip.UserInputType == Enum.UserInputType.MouseButton1 then
            dr = false
        end
    end)

    s3.InputChanged:Connect(function(ip)
        if dr and ip.UserInputType == Enum.UserInputType.MouseMovement then
            upd(ip)
        end
    end)

    return sf
end

local function cbt(pr, tx, cb)
    local bt = Instance.new("TextButton")
    bt.Size = UDim2.new(1, -10, 0, 35)
    bt.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    bt.Text = tx
    bt.TextColor3 = Color3.new(1, 1, 1)
    bt.TextSize = 14
    bt.Font = Enum.Font.GothamBold
    bt.ZIndex = 3
    bt.Parent = pr

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = bt

    bt.MouseButton1Click:Connect(function()
        if cb then
            cb()
        end
    end)

    return bt
end

local function csc(pr, tt)
    local sc = Instance.new("Frame")
    sc.Size = UDim2.new(1, 0, 0, 0)
    sc.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    sc.BackgroundTransparency = 0.3
    sc.BorderSizePixel = 0
    sc.ZIndex = 2
    sc.Parent = pr

    local scc = Instance.new("UICorner")
    scc.CornerRadius = UDim.new(0, 8)
    scc.Parent = sc

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -20, 0, 30)
    tl.Position = UDim2.new(0, 10, 0, 5)
    tl.BackgroundTransparency = 1
    tl.Text = tt
    tl.TextColor3 = Color3.fromRGB(255, 50, 50)
    tl.TextSize = 16
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 3
    tl.Parent = sc

    local ct = Instance.new("Frame")
    ct.Size = UDim2.new(1, -20, 1, -40)
    ct.Position = UDim2.new(0, 10, 0, 35)
    ct.BackgroundTransparency = 1
    ct.ZIndex = 3
    ct.Parent = sc

    local cl = Instance.new("UIListLayout")
    cl.Padding = UDim.new(0, 5)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    cl.Parent = ct

    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sc.Size = UDim2.new(1, 0, 0, cl.AbsoluteContentSize.Y + 45)
    end)

    return sc, ct
end

-- Build UI
local function bld()
    local gu = cui()
    local cn = _G.u.tb

    -- Player
    local ps, pc = csc(cn, "Player")

    local fs = 5
    ctg(pc, "Fly", function(en)
        _G.tfly(en, fs)
    end)

    csl(pc, "Fly Speed", 1, 10, 5, function(v)
        fs = v
        if _G.e.fly then
            _G.tfly(true, fs)
        end
    end)

    ctg(pc, "Noclip", function(en)
        _G.tnc(en)
    end)

    ctg(pc, "Walk On Water", function(en)
        _G.tww(en)
    end)

    local ws = 50
    ctg(pc, "Speed", function(en)
        _G.tsp(en, ws)
    end)

    csl(pc, "Walk Speed", 16, 200, 50, function(v)
        ws = v
        if _G.e.sp then
            _G.tsp(true, ws)
        end
    end)

    -- Visual
    local vs, vc = csc(cn, "Visual")

    ctg(vc, "ESP", function(en)
        _G.tesp(en)
    end)

    ctg(vc, "ESP - Boxes", function(en)
        _G.esp.bx = en
    end)

    ctg(vc, "ESP - Names", function(en)
        _G.esp.nm = en
    end)

    ctg(vc, "ESP - Distance", function(en)
        _G.esp.ds = en
    end)

    ctg(vc, "ESP - Health", function(en)
        _G.esp.hp = en
    end)

    ctg(vc, "ESP - Tracers", function(en)
        _G.esp.tr = en
    end)

    ctg(vc, "ESP - Team Check", function(en)
        _G.esp.tm = en
    end)

    ctg(vc, "Fullbright", function(en)
        _G.tfb(en)
    end)

    -- Combat
    local cs, cc = csc(cn, "Combat")

    ctg(cc, "Anti-Aim", function(en)
        _G.taa(en)
    end)

    -- Logs
    local ls, lc = csc(cn, "Logs")

    local ld = Instance.new("ScrollingFrame")
    ld.Size = UDim2.new(1, -10, 0, 200)
    ld.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    ld.BackgroundTransparency = 0.5
    ld.BorderSizePixel = 0
    ld.ScrollBarThickness = 6
    ld.CanvasSize = UDim2.new(0, 0, 0, 0)
    ld.ZIndex = 4
    ld.Parent = lc

    local ldc = Instance.new("UICorner")
    ldc.CornerRadius = UDim.new(0, 6)
    ldc.Parent = ld

    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 2)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = ld

    local function rf()
        for _, ch in ipairs(ld:GetChildren()) do
            if ch:IsA("TextLabel") then
                ch:Destroy()
            end
        end

        for _, le in ipairs(_G.l or {}) do
            local ll = Instance.new("TextLabel")
            ll.Size = UDim2.new(1, -10, 0, 20)
            ll.BackgroundTransparency = 1
            ll.Text = le
            ll.TextColor3 = Color3.new(1, 1, 1)
            ll.TextSize = 12
            ll.Font = Enum.Font.Code
            ll.TextXAlignment = Enum.TextXAlignment.Left
            ll.TextWrapped = true
            ll.ZIndex = 5
            ll.Parent = ld
        end

        ld.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 10)
    end

    cbt(lc, "Refresh", rf)

    cbt(lc, "Copy All", function()
        local al = table.concat(_G.l or {}, "\n")
        setclipboard(al)
        lg("Logs copied", "SYS")
    end)

    -- Settings
    local ss, stc = csc(cn, "Settings")

    cbt(stc, "Disable All", function()
        for f, en in pairs(_G.e) do
            if en then
                if f == "fly" then
                    _G.tfly(false)
                elseif f == "nc" then
                    _G.tnc(false)
                elseif f == "ww" then
                    _G.tww(false)
                elseif f == "sp" then
                    _G.tsp(false)
                elseif f == "fb" then
                    _G.tfb(false)
                elseif f == "aa" then
                    _G.taa(false)
                end
            end
        end

        _G.tesp(false)

        lg("All disabled", "SYS")
    end)

    cbt(stc, "EXIT", function()
        clr()

        if gu then
            gu:Destroy()
        end

        lg("Exit complete", "SYS")
    end)

    gu.Parent = game:GetService("CoreGui")

    lg("UI loaded", "SYS")
end

-- Toggle UI
s3.InputBegan:Connect(function(ip, gp)
    if gp then return end

    if ip.KeyCode == Enum.KeyCode.Insert then
        for _, ch in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if ch:IsA("ScreenGui") and ch.Name:match("^_") then
                for _, mf in ipairs(ch:GetChildren()) do
                    if mf:IsA("Frame") and mf.Name:match("^_") then
                        mf.Visible = not mf.Visible
                        lg("UI toggled: " .. tostring(mf.Visible), "UI")
                        break
                    end
                end
                break
            end
        end
    end
end)

-- Initialize
task.spawn(function()
    aafk()
    task.wait(0.5)
    bld()
    lg("Universal v" .. _G.v .. " loaded", "SYS")
    lg("Press INSERT to toggle", "SYS")
end)

return _G
