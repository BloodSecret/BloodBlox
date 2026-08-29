--[[
    BloodyBlox v0.3.0
    Muscle Legends helper / analyzer

    Important:
    - Local features (UI, ESP, Fly, Noclip, Fullbright, Teleport points, Anti-AFK) are self-contained.
    - Game-server actions are NOT guessed. Use Analyzer -> Capture Next Action and perform the action manually.
    - A captured RemoteEvent/RemoteFunction can be replayed only while the game accepts the same call/arguments.
]]

if _G.BloodyBloxLoaded then
    warn("[BloodyBlox] Already running")
    return
end
_G.BloodyBloxLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    _G.BloodyBloxLoaded = nil
    error("[BloodyBlox] LocalPlayer unavailable")
end

local function safeCall(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if ok then
        return true, a, b, c
    end
    return false, a
end

local function disconnect(conn)
    if conn and typeof(conn) == "RBXScriptConnection" then
        pcall(function() conn:Disconnect() end)
    end
end

local function destroy(obj)
    if obj then
        pcall(function() obj:Destroy() end)
    end
end

local BloodyBlox = {
    Version = "0.3.0",
    MenuOpen = true,
    Player = LocalPlayer,
    Connections = {},
    Logs = {},
    ESPObjects = {},
    TeleportPoints = {},
    Settings = {
        ESP = false,
        ESPBoxes = true,
        ESPNames = true,
        ESPDistance = true,
        ESPHealth = true,
        ESPTracers = false,
        ESPTeamCheck = false,
        Fly = false,
        FlySpeed = 5,
        Noclip = false,
        InfiniteJump = false,
        Fullbright = false,
        AntiAFK = true,
        WeightFarm = false,
        WeightInterval = 0.25,
        DurabilityFarm = false,
        DurabilityInterval = 0.25,
        AutoRebirth = false,
        RebirthInterval = 2,
        CombatFarm = false,
        CombatInterval = 0.25,
        Analyzer = false,
    },
    State = {
        FullbrightBackup = nil,
        NoclipBackup = {},
        FlyVelocity = nil,
        WaterPlatform = nil,
        LastCapture = nil,
        CapturingAction = nil,
        Profiles = {},
        AnalyzerHookInstalled = false,
        OriginalNamecall = nil,
    }
}

function BloodyBlox:Log(category, message, level)
    local entry = {
        time = os.date("%H:%M:%S"),
        category = category,
        message = tostring(message),
        level = level or "info",
    }
    table.insert(self.Logs, entry)
    if #self.Logs > 300 then
        table.remove(self.Logs, 1)
    end
    print(string.format("[%s][%s] %s", entry.time, entry.category, entry.message))
end

function BloodyBlox:GetCharacter()
    return self.Player.Character
end

function BloodyBlox:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

function BloodyBlox:GetHRP()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

function BloodyBlox:AddConnection(conn)
    if conn then
        table.insert(self.Connections, conn)
    end
    return conn
end

--============================================================
-- Serialization used by the analyzer/profile system
--============================================================

local function serialize(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    if depth > 4 then
        return "<max-depth>"
    end

    local t = typeof(value)
    if value == nil then
        return {kind = "nil"}
    elseif t == "boolean" or t == "number" or t == "string" then
        return {kind = t, value = value}
    elseif t == "Vector3" then
        return {kind = "Vector3", x = value.X, y = value.Y, z = value.Z}
    elseif t == "Vector2" then
        return {kind = "Vector2", x = value.X, y = value.Y}
    elseif t == "CFrame" then
        local p = value.Position
        return {kind = "CFrame", x = p.X, y = p.Y, z = p.Z, components = {value:GetComponents()}}
    elseif t == "Color3" then
        return {kind = "Color3", r = value.R, g = value.G, b = value.B}
    elseif t == "BrickColor" then
        return {kind = "BrickColor", name = value.Name}
    elseif t == "EnumItem" then
        return {kind = "EnumItem", enumType = tostring(value.EnumType), name = value.Name}
    elseif t == "Instance" then
        return {kind = "Instance", path = value:GetFullName(), class = value.ClassName}
    elseif t == "table" then
        if seen[value] then
            return {kind = "table", value = "<cycle>"}
        end
        seen[value] = true
        local out = {}
        for k, v in pairs(value) do
            local key = tostring(k)
            out[key] = serialize(v, depth + 1, seen)
        end
        seen[value] = nil
        return {kind = "table", value = out}
    end

    return {kind = t, value = tostring(value)}
end

local function resolveSerialized(value)
    if type(value) ~= "table" then
        return value
    end
    local kind = value.kind
    if kind == "nil" then
        return nil
    elseif kind == "boolean" or kind == "number" or kind == "string" then
        return value.value
    elseif kind == "Vector3" then
        return Vector3.new(value.x, value.y, value.z)
    elseif kind == "Vector2" then
        return Vector2.new(value.x, value.y)
    elseif kind == "CFrame" then
        if type(value.components) == "table" and #value.components == 12 then
            return CFrame.new(unpack(value.components))
        end
        return CFrame.new(value.x, value.y, value.z)
    elseif kind == "Color3" then
        return Color3.new(value.r, value.g, value.b)
    elseif kind == "BrickColor" then
        return BrickColor.new(value.name)
    elseif kind == "EnumItem" then
        local enum = Enum[value.enumType]
        if enum and enum[value.name] then
            return enum[value.name]
        end
        return nil
    elseif kind == "Instance" then
        local current = game
        for part in string.gmatch(value.path, "[^%.]+") do
            if part ~= "game" then
                local nextObject = current:FindFirstChild(part)
                if not nextObject then
                    return nil
                end
                current = nextObject
            end
        end
        return current
    elseif kind == "table" then
        local out = {}
        for k, v in pairs(value.value or {}) do
            out[k] = resolveSerialized(v)
        end
        return out
    end
    return value.value
end

local function formatValue(value)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(serialize(value))
    end)
    return ok and encoded or ("<encode error: " .. tostring(encoded) .. ">")
end

--============================================================
-- Analyzer
--============================================================

local Analyzer = {}

function Analyzer:ScanRemotes()
    local result = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(result, {
                path = obj:GetFullName(),
                name = obj.Name,
                class = obj.ClassName,
            })
        end
    end
    table.sort(result, function(a, b) return a.path < b.path end)
    BloodyBlox.State.RemoteList = result
    BloodyBlox:Log("Analyzer", "Found " .. #result .. " remotes", "info")
    for i, remote in ipairs(result) do
        BloodyBlox:Log("Remote", string.format("[%d] %s (%s)", i, remote.path, remote.class), "info")
    end
    return result
end

function Analyzer:StartCapture(actionName)
    BloodyBlox.State.CapturingAction = actionName
    BloodyBlox:Log("Analyzer", "Capture started: " .. actionName, "warn")
end

function Analyzer:StopCapture()
    BloodyBlox.State.CapturingAction = nil
    BloodyBlox:Log("Analyzer", "Capture stopped", "info")
end

function Analyzer:InstallHook()
    if BloodyBlox.State.AnalyzerHookInstalled then
        return true
    end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
        BloodyBlox:Log("Analyzer", "Executor lacks hookmetamethod/getnamecallmethod", "error")
        return false
    end

    local ok, err = pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer")
                and typeof(self) == "Instance"
                and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then

                local args = {...}
                local captureName = BloodyBlox.State.CapturingAction
                local snapshot = {
                    path = self:GetFullName(),
                    name = self.Name,
                    class = self.ClassName,
                    method = method,
                    args = {},
                    time = os.clock(),
                }
                for i, arg in ipairs(args) do
                    snapshot.args[i] = serialize(arg)
                end

                BloodyBlox.State.LastCapture = snapshot
                BloodyBlox:Log("RemoteSpy", snapshot.path .. " | " .. method .. " | args=" .. #args, "info")

                if captureName then
                    BloodyBlox.State.Profiles[captureName] = snapshot
                    BloodyBlox.State.CapturingAction = nil
                    BloodyBlox:Log("Analyzer", "Profile saved: " .. captureName, "warn")
                end
            end

            return old(self, ...)
        end))
        BloodyBlox.State.OriginalNamecall = old
        BloodyBlox.State.AnalyzerHookInstalled = true
    end)

    if not ok then
        BloodyBlox:Log("Analyzer", "Hook failed: " .. tostring(err), "error")
        return false
    end

    BloodyBlox:Log("Analyzer", "Remote spy installed", "warn")
    return true
end

function Analyzer:RunProfile(name)
    local profile = BloodyBlox.State.Profiles[name]
    if not profile then
        BloodyBlox:Log("Farm", "No profile: " .. name, "error")
        return false
    end

    local remote = game
    for part in string.gmatch(profile.path, "[^%.]+") do
        if part ~= "game" then
            local nextObject = remote:FindFirstChild(part)
            if not nextObject then
                BloodyBlox:Log("Farm", "Remote not found: " .. profile.path, "error")
                return false
            end
            remote = nextObject
        end
    end

    local args = {}
    for i, encoded in ipairs(profile.args or {}) do
        args[i] = resolveSerialized(encoded)
    end

    local ok, err
    if profile.method == "FireServer" and remote:IsA("RemoteEvent") then
        ok, err = pcall(function() remote:FireServer(unpack(args)) end)
    elseif profile.method == "InvokeServer" and remote:IsA("RemoteFunction") then
        ok, err = pcall(function() remote:InvokeServer(unpack(args)) end)
    else
        BloodyBlox:Log("Farm", "Profile method/object mismatch", "error")
        return false
    end

    if not ok then
        BloodyBlox:Log("Farm", "Replay failed: " .. tostring(err), "error")
        return false
    end
    return true
end

function Analyzer:SaveProfiles()
    if not (writefile and isfolder and makefolder) then
        BloodyBlox:Log("Config", "Filesystem API unavailable", "error")
        return
    end
    pcall(function()
        if not isfolder("BloodyBlox") then
            makefolder("BloodyBlox")
        end
        writefile("BloodyBlox/profiles.json", HttpService:JSONEncode(BloodyBlox.State.Profiles))
        BloodyBlox:Log("Config", "Profiles saved", "info")
    end)
end

function Analyzer:LoadProfiles()
    if not (isfile and readfile) then
        return
    end
    pcall(function()
        if isfile("BloodyBlox/profiles.json") then
            local data = HttpService:JSONDecode(readfile("BloodyBlox/profiles.json"))
            if type(data) == "table" then
                BloodyBlox.State.Profiles = data
                BloodyBlox:Log("Config", "Profiles loaded", "info")
            end
        end
    end)
end

--============================================================
-- Server-action farm loops: replay only captured profiles
--============================================================

local Farm = {
    Tasks = {},
}

function Farm:Stop(name)
    local taskObject = self.Tasks[name]
    if taskObject then
        taskObject.running = false
        self.Tasks[name] = nil
    end
end

function Farm:Start(name, interval, profile)
    self:Stop(name)
    if not BloodyBlox.State.Profiles[profile] then
        BloodyBlox:Log("Farm", "Capture profile first: " .. profile, "error")
        return
    end

    local state = {running = true}
    self.Tasks[name] = state
    task.spawn(function()
        while state.running do
            if not BloodyBlox.State.Profiles[profile] then
                break
            end
            Analyzer:RunProfile(profile)
            task.wait(math.max(0.05, tonumber(interval) or 0.25))
        end
    end)
    BloodyBlox:Log("Farm", name .. " started -> " .. profile, "warn")
end

--============================================================
-- Visual
--============================================================

local ESP = {}

function ESP:Remove(player)
    for i = #BloodyBlox.ESPObjects, 1, -1 do
        local obj = BloodyBlox.ESPObjects[i]
        if obj.Player == player then
            for _, drawing in pairs(obj.Drawings) do
                pcall(function() drawing:Remove() end)
            end
            table.remove(BloodyBlox.ESPObjects, i)
        end
    end
end

function ESP:Add(player)
    if player == LocalPlayer then return end
    self:Remove(player)
    if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
        BloodyBlox:Log("ESP", "Drawing API unavailable", "error")
        return
    end

    local d = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Line"),
        HealthOutline = Drawing.new("Line"),
        Tracer = Drawing.new("Line"),
    }

    d.Box.Thickness = 2
    d.Box.Filled = false
    d.Box.Visible = false
    d.Box.Color = Color3.fromRGB(255, 255, 255)

    d.Name.Size = 13
    d.Name.Center = true
    d.Name.Outline = true
    d.Name.Visible = false
    d.Name.Color = Color3.fromRGB(255, 255, 255)

    d.Distance.Size = 12
    d.Distance.Center = true
    d.Distance.Outline = true
    d.Distance.Visible = false
    d.Distance.Color = Color3.fromRGB(200, 200, 200)

    d.Health.Thickness = 3
    d.Health.Visible = false
    d.Health.Color = Color3.fromRGB(0, 255, 0)

    d.HealthOutline.Thickness = 5
    d.HealthOutline.Visible = false
    d.HealthOutline.Color = Color3.fromRGB(0, 0, 0)

    d.Tracer.Thickness = 1
    d.Tracer.Visible = false
    d.Tracer.Color = Color3.fromRGB(255, 255, 255)

    table.insert(BloodyBlox.ESPObjects, {Player = player, Drawings = d})
end

function ESP:SetVisible(obj, visible)
    for _, drawing in pairs(obj.Drawings) do
        drawing.Visible = visible
    end
end

function ESP:Update()
    local camera = Workspace.CurrentCamera
    local myRoot = BloodyBlox:GetHRP()
    if not camera then return end

    for _, obj in ipairs(BloodyBlox.ESPObjects) do
        local player = obj.Player
        local d = obj.Drawings
        local char = player and player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not hrp or not head or not hum or hum.Health <= 0 then
            self:SetVisible(obj, false)
            continue
        end
        if BloodyBlox.Settings.ESPTeamCheck and player.Team == LocalPlayer.Team then
            self:SetVisible(obj, false)
            continue
        end
        if not BloodyBlox.Settings.ESP then
            self:SetVisible(obj, false)
            continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if not onScreen or rootPos.Z <= 0 then
            self:SetVisible(obj, false)
            continue
        end

        local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local height = math.max(20, math.abs(headPos.Y - legPos.Y))
        local width = math.max(10, height / 2)

        if BloodyBlox.Settings.ESPBoxes then
            d.Box.Size = Vector2.new(width, height)
            d.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
            d.Box.Visible = true
        else
            d.Box.Visible = false
        end

        if BloodyBlox.Settings.ESPNames then
            d.Name.Text = player.Name
            d.Name.Position = Vector2.new(rootPos.X, headPos.Y - 15)
            d.Name.Visible = true
        else
            d.Name.Visible = false
        end

        if BloodyBlox.Settings.ESPDistance and myRoot then
            d.Distance.Text = tostring(math.floor((myRoot.Position - hrp.Position).Magnitude))
            d.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
            d.Distance.Visible = true
        else
            d.Distance.Visible = false
        end

        if BloodyBlox.Settings.ESPHealth then
            local maxHealth = math.max(hum.MaxHealth, 1)
            local ratio = math.clamp(hum.Health / maxHealth, 0, 1)
            local x = rootPos.X - width / 2 - 7
            d.HealthOutline.From = Vector2.new(x, rootPos.Y - height / 2)
            d.HealthOutline.To = Vector2.new(x, rootPos.Y + height / 2)
            d.HealthOutline.Visible = true
            d.Health.From = Vector2.new(x, rootPos.Y + height / 2)
            d.Health.To = Vector2.new(x, rootPos.Y + height / 2 - height * ratio)
            d.Health.Visible = true
        else
            d.Health.Visible = false
            d.HealthOutline.Visible = false
        end

        if BloodyBlox.Settings.ESPTracers then
            local from = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            d.Tracer.From = from
            d.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            d.Tracer.Visible = true
        else
            d.Tracer.Visible = false
        end
    end
end

function ESP:Toggle(enabled)
    BloodyBlox.Settings.ESP = enabled
    if enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            self:Add(p)
        end
    else
        for i = #BloodyBlox.ESPObjects, 1, -1 do
            local obj = BloodyBlox.ESPObjects[i]
            for _, drawing in pairs(obj.Drawings) do
                pcall(function() drawing:Remove() end)
            end
            table.remove(BloodyBlox.ESPObjects, i)
        end
    end
end

--============================================================
-- Player
--============================================================

local PlayerTools = {}

function PlayerTools:ToggleNoclip(enabled)
    BloodyBlox.Settings.Noclip = enabled
    if enabled then
        if self.NoclipConnection then disconnect(self.NoclipConnection) end
        self.NoclipConnection = RunService.Stepped:Connect(function()
            local char = BloodyBlox:GetCharacter()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if BloodyBlox.State.NoclipBackup[part] == nil then
                        BloodyBlox.State.NoclipBackup[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
        BloodyBlox:AddConnection(self.NoclipConnection)
    else
        if self.NoclipConnection then disconnect(self.NoclipConnection) end
        self.NoclipConnection = nil
        for part, original in pairs(BloodyBlox.State.NoclipBackup) do
            if part and part.Parent then
                pcall(function() part.CanCollide = original end)
            end
        end
        BloodyBlox.State.NoclipBackup = {}
    end
end

function PlayerTools:ToggleFly(enabled)
    BloodyBlox.Settings.Fly = enabled
    if self.FlyConnection then disconnect(self.FlyConnection) end
    self.FlyConnection = nil
    if self.FlyVelocity then
        destroy(self.FlyVelocity)
        self.FlyVelocity = nil
    end

    if not enabled then
        return
    end

    local hrp = BloodyBlox:GetHRP()
    if not hrp then
        BloodyBlox:Log("Player", "Fly: HRP unavailable", "error")
        return
    end

    self.FlyVelocity = Instance.new("BodyVelocity")
    self.FlyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    self.FlyVelocity.Velocity = Vector3.zero
    self.FlyVelocity.Parent = hrp

    self.FlyConnection = RunService.RenderStepped:Connect(function()
        if not BloodyBlox.Settings.Fly then return end
        local root = BloodyBlox:GetHRP()
        local camera = Workspace.CurrentCamera
        if not root or not camera or not self.FlyVelocity then return end

        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.yAxis end

        local speed = math.max(1, BloodyBlox.Settings.FlySpeed) * 50
        self.FlyVelocity.Velocity = direction * speed
    end)
    BloodyBlox:AddConnection(self.FlyConnection)
end

function PlayerTools:ToggleInfiniteJump(enabled)
    BloodyBlox.Settings.InfiniteJump = enabled
end

function PlayerTools:ToggleFullbright(enabled)
    BloodyBlox.Settings.Fullbright = enabled
    if enabled then
        if not BloodyBlox.State.FullbrightBackup then
            BloodyBlox.State.FullbrightBackup = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        local b = BloodyBlox.State.FullbrightBackup
        if b then
            Lighting.Brightness = b.Brightness
            Lighting.ClockTime = b.ClockTime
            Lighting.FogEnd = b.FogEnd
            Lighting.GlobalShadows = b.GlobalShadows
            Lighting.OutdoorAmbient = b.OutdoorAmbient
        end
        BloodyBlox.State.FullbrightBackup = nil
    end
end

--============================================================
-- Teleports
--============================================================

local Teleport = {}

function Teleport:Save()
    if not writefile then
        BloodyBlox:Log("Teleport", "writefile unavailable", "error")
        return
    end
    pcall(function()
        writefile("BloodyBlox_Teleports.json", HttpService:JSONEncode(BloodyBlox.TeleportPoints))
    end)
end

function Teleport:Load()
    if not (isfile and readfile) then return end
    pcall(function()
        if isfile("BloodyBlox_Teleports.json") then
            local data = HttpService:JSONDecode(readfile("BloodyBlox_Teleports.json"))
            if type(data) == "table" then
                BloodyBlox.TeleportPoints = data
            end
        end
    end)
end

function Teleport:Add(name)
    local root = BloodyBlox:GetHRP()
    if not root then return end
    table.insert(BloodyBlox.TeleportPoints, {
        name = name or ("Point_" .. (#BloodyBlox.TeleportPoints + 1)),
        x = root.Position.X,
        y = root.Position.Y,
        z = root.Position.Z,
    })
    self:Save()
    BloodyBlox:Log("Teleport", "Point saved", "info")
end

function Teleport:Go(point)
    local root = BloodyBlox:GetHRP()
    if root and point then
        root.CFrame = CFrame.new(point.x, point.y, point.z)
    end
end

--============================================================
-- Config
--============================================================

local Config = {}

function Config:Save(name)
    if not writefile then
        BloodyBlox:Log("Config", "writefile unavailable", "error")
        return
    end
    name = tostring(name or ""):gsub("[^%w_%-]", "_")
    if name == "" then
        BloodyBlox:Log("Config", "Invalid name", "error")
        return
    end
    local data = {
        Version = BloodyBlox.Version,
        Settings = BloodyBlox.Settings,
        Profiles = BloodyBlox.State.Profiles,
        Teleports = BloodyBlox.TeleportPoints,
    }
    local ok, err = pcall(function()
        writefile("BloodyBlox_" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    if ok then
        BloodyBlox:Log("Config", "Saved: " .. name, "info")
    else
        BloodyBlox:Log("Config", "Save failed: " .. tostring(err), "error")
    end
end

function Config:Load(name)
    if not (isfile and readfile) then
        BloodyBlox:Log("Config", "readfile/isfile unavailable", "error")
        return
    end
    name = tostring(name or ""):gsub("[^%w_%-]", "_")
    if name == "" then
        BloodyBlox:Log("Config", "Invalid name", "error")
        return
    end
    local path = "BloodyBlox_" .. name .. ".json"
    if not isfile(path) then
        BloodyBlox:Log("Config", "Not found: " .. name, "error")
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        BloodyBlox:Log("Config", "Invalid JSON", "error")
        return
    end
    if type(data.Settings) == "table" then
        for key, default in pairs(BloodyBlox.Settings) do
            if data.Settings[key] ~= nil and type(data.Settings[key]) == type(default) then
                BloodyBlox.Settings[key] = data.Settings[key]
            end
        end
    end
    if type(data.Profiles) == "table" then
        BloodyBlox.State.Profiles = data.Profiles
    end
    if type(data.Teleports) == "table" then
        BloodyBlox.TeleportPoints = data.Teleports
    end
    BloodyBlox:Log("Config", "Loaded: " .. name, "info")
end

function Config:Delete(name)
    if not (isfile and delfile) then
        BloodyBlox:Log("Config", "Filesystem delete unavailable", "error")
        return
    end
    name = tostring(name or ""):gsub("[^%w_%-]", "_")
    local path = "BloodyBlox_" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        BloodyBlox:Log("Config", "Deleted: " .. name, "warn")
    else
        BloodyBlox:Log("Config", "Not found", "error")
    end
end

--============================================================
-- UI
--============================================================

local UI = {
    Tabs = {},
    CurrentTab = nil,
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

function UI:Create()
    local parent = LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = create("ScreenGui", {
        Name = "BloodyBloxUI_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)

    self.Main = create("Frame", {
        Size = UDim2.fromOffset(760, 540),
        Position = UDim2.new(0.5, -380, 0.5, -270),
        BackgroundColor3 = Color3.fromRGB(10, 10, 15),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    }, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(0, 12)}, self.Main)

    local title = create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 44),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = "BLOODYBLOX  v" .. BloodyBlox.Version,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Main)

    local close = create("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -44, 0, 6),
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        BorderSizePixel = 0,
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
    }, self.Main)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, close)
    close.MouseButton1Click:Connect(function()
        self.Gui.Enabled = false
        BloodyBlox.MenuOpen = false
    end)

    self.Sidebar = create("ScrollingFrame", {
        Size = UDim2.new(0, 150, 1, -58),
        Position = UDim2.fromOffset(10, 50),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Main)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.Sidebar)
    create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, self.Sidebar)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    }, self.Sidebar)

    self.Content = create("Frame", {
        Size = UDim2.new(1, -170, 1, -58),
        Position = UDim2.fromOffset(160, 50),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0,
    }, self.Main)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.Content)
    return self
end

function UI:AddTab(name)
    local tab = {}
    tab.Name = name
    tab.Button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, self.Sidebar)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, tab.Button)

    tab.Page = create("ScrollingFrame", {
        Size = UDim2.new(1, -18, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, self.Content)
    create("UIListLayout", {Padding = UDim.new(0, 7)}, tab.Page)
    create("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)}, tab.Page)

    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    table.insert(self.Tabs, tab)
    if not self.CurrentTab then
        self:SelectTab(tab)
    end
    return tab
end

function UI:SelectTab(tab)
    for _, item in ipairs(self.Tabs) do
        item.Page.Visible = false
        item.Button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    end
    tab.Page.Visible = true
    tab.Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    self.CurrentTab = tab
end

function UI:AddLabel(tab, text)
    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(155, 155, 165),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, tab.Page)
end

function UI:AddButton(tab, text, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(139, 0, 0),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
    button.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return button
end

function UI:AddToggle(tab, text, default, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(225, 225, 225),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(42, 20),
        Position = UDim2.new(1, -48, 0.5, -10),
        BackgroundColor3 = default and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 85),
        BorderSizePixel = 0,
        Text = default and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, frame)
    create("UICorner", {CornerRadius = UDim.new(0, 5)}, button)
    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 85)
        safeCall(callback, state)
    end)
    return button
end

function UI:AddTextBox(tab, placeholder, callback)
    local box = create("TextBox", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
        PlaceholderText = placeholder,
        Text = "",
        TextColor3 = Color3.fromRGB(230, 230, 230),
        PlaceholderColor3 = Color3.fromRGB(110, 110, 120),
        Font = Enum.Font.Gotham,
        TextSize = 12,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
    box.FocusLost:Connect(function()
        safeCall(callback, box.Text)
    end)
    return box
end

function UI:AddNumberBox(tab, labelText, default, callback)
    local box = self:AddTextBox(tab, labelText .. " = " .. tostring(default), function(text)
        local number = tonumber(text)
        if number then
            callback(number)
        end
    end)
    return box
end

function UI:RefreshLogs(page)
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    create("UIListLayout", {Padding = UDim.new(0, 5)}, page)
    for i = math.max(1, #BloodyBlox.Logs - 60), #BloodyBlox.Logs do
        local log = BloodyBlox.Logs[i]
        if log then
            self:AddLabel({Page = page}, string.format("[%s][%s] %s", log.time, log.category, log.message))
        end
    end
end

--============================================================
-- Build UI
--============================================================

UI:Create()
Teleport:Load()
Analyzer:LoadProfiles()
Analyzer:InstallHook()

local MainTab = UI:AddTab("Main")
UI:AddLabel(MainTab, "Muscle Legends: server actions require captured profiles.")
UI:AddButton(MainTab, "Analyze Remotes", function() Analyzer:ScanRemotes() end)
UI:AddButton(MainTab, "Save Profiles", function() Analyzer:SaveProfiles() end)
UI:AddButton(MainTab, "Run Weight Profile Once", function() Analyzer:RunProfile("Weight") end)
UI:AddButton(MainTab, "Run Durability Profile Once", function() Analyzer:RunProfile("Durability") end)
UI:AddButton(MainTab, "Run Rebirth Profile Once", function() Analyzer:RunProfile("Rebirth") end)
UI:AddButton(MainTab, "Run Combat Profile Once", function() Analyzer:RunProfile("Combat") end)

local FarmTab = UI:AddTab("Farm")
UI:AddToggle(FarmTab, "Weight Farm", false, function(v)
    BloodyBlox.Settings.WeightFarm = v
    if v then Farm:Start("Weight", BloodyBlox.Settings.WeightInterval, "Weight") else Farm:Stop("Weight") end
end)
UI:AddNumberBox(FarmTab, "Weight interval", 0.25, function(v)
    BloodyBlox.Settings.WeightInterval = math.max(0.05, v)
end)
UI:AddToggle(FarmTab, "Durability Farm", false, function(v)
    BloodyBlox.Settings.DurabilityFarm = v
    if v then Farm:Start("Durability", BloodyBlox.Settings.DurabilityInterval, "Durability") else Farm:Stop("Durability") end
end)
UI:AddNumberBox(FarmTab, "Durability interval", 0.25, function(v)
    BloodyBlox.Settings.DurabilityInterval = math.max(0.05, v)
end)
UI:AddToggle(FarmTab, "Auto Rebirth", false, function(v)
    BloodyBlox.Settings.AutoRebirth = v
    if v then Farm:Start("Rebirth", BloodyBlox.Settings.RebirthInterval, "Rebirth") else Farm:Stop("Rebirth") end
end)
UI:AddNumberBox(FarmTab, "Rebirth interval", 2, function(v)
    BloodyBlox.Settings.RebirthInterval = math.max(0.1, v)
end)
UI:AddToggle(FarmTab, "Combat Farm", false, function(v)
    BloodyBlox.Settings.CombatFarm = v
    if v then Farm:Start("Combat", BloodyBlox.Settings.CombatInterval, "Combat") else Farm:Stop("Combat") end
end)
UI:AddNumberBox(FarmTab, "Combat interval", 0.25, function(v)
    BloodyBlox.Settings.CombatInterval = math.max(0.05, v)
end)

local AnalyzerTab = UI:AddTab("Analyzer")
UI:AddLabel(AnalyzerTab, "1) Start capture. 2) Perform the action manually once. 3) The profile is saved automatically.")
UI:AddButton(AnalyzerTab, "Scan Remotes", function() Analyzer:ScanRemotes() end)
UI:AddButton(AnalyzerTab, "Capture Next Weight", function() Analyzer:StartCapture("Weight") end)
UI:AddButton(AnalyzerTab, "Capture Next Durability", function() Analyzer:StartCapture("Durability") end)
UI:AddButton(AnalyzerTab, "Capture Next Rebirth", function() Analyzer:StartCapture("Rebirth") end)
UI:AddButton(AnalyzerTab, "Capture Next Combat", function() Analyzer:StartCapture("Combat") end)
UI:AddButton(AnalyzerTab, "Cancel Capture", function() Analyzer:StopCapture() end)
UI:AddButton(AnalyzerTab, "Run Last Capture", function()
    local p = BloodyBlox.State.LastCapture
    if not p then
        BloodyBlox:Log("Analyzer", "Nothing captured", "error")
        return
    end
    BloodyBlox.State.Profiles.__Last = p
    Analyzer:RunProfile("__Last")
end)
UI:AddButton(AnalyzerTab, "Save Profiles", function() Analyzer:SaveProfiles() end)

local VisualTab = UI:AddTab("Visual")
UI:AddToggle(VisualTab, "ESP", false, function(v) ESP:Toggle(v) end)
UI:AddToggle(VisualTab, "Boxes", true, function(v) BloodyBlox.Settings.ESPBoxes = v end)
UI:AddToggle(VisualTab, "Names", true, function(v) BloodyBlox.Settings.ESPNames = v end)
UI:AddToggle(VisualTab, "Distance", true, function(v) BloodyBlox.Settings.ESPDistance = v end)
UI:AddToggle(VisualTab, "Health", true, function(v) BloodyBlox.Settings.ESPHealth = v end)
UI:AddToggle(VisualTab, "Tracers", false, function(v) BloodyBlox.Settings.ESPTracers = v end)
UI:AddToggle(VisualTab, "Team Check", false, function(v) BloodyBlox.Settings.ESPTeamCheck = v end)
UI:AddToggle(VisualTab, "Fullbright", false, function(v) PlayerTools:ToggleFullbright(v) end)

local PlayerTab = UI:AddTab("Player")
UI:AddToggle(PlayerTab, "Fly", false, function(v) PlayerTools:ToggleFly(v) end)
UI:AddNumberBox(PlayerTab, "Fly speed", 5, function(v) BloodyBlox.Settings.FlySpeed = math.clamp(v, 1, 10) end)
UI:AddToggle(PlayerTab, "Noclip", false, function(v) PlayerTools:ToggleNoclip(v) end)
UI:AddToggle(PlayerTab, "Infinite Jump", false, function(v) PlayerTools:ToggleInfiniteJump(v) end)
UI:AddToggle(PlayerTab, "Anti-AFK", true, function(v) BloodyBlox.Settings.AntiAFK = v end)

local TeleportTab = UI:AddTab("Teleport")
UI:AddTextBox(TeleportTab, "Point name...", function(name)
    BloodyBlox.State.PendingTeleportName = name ~= "" and name or nil
end)
UI:AddButton(TeleportTab, "Save Current Position", function()
    Teleport:Add(BloodyBlox.State.PendingTeleportName)
end)
UI:AddButton(TeleportTab, "Refresh Points", function() end)
UI:AddLabel(TeleportTab, "Restart script to rebuild the teleport list from the saved file.")
for _, point in ipairs(BloodyBlox.TeleportPoints) do
    UI:AddButton(TeleportTab, "TP: " .. tostring(point.name), function() Teleport:Go(point) end)
end

local ConfigTab = UI:AddTab("Config")
local configName = ""
UI:AddTextBox(ConfigTab, "Config name...", function(text) configName = text end)
UI:AddButton(ConfigTab, "Save", function() Config:Save(configName) end)
UI:AddButton(ConfigTab, "Load", function() Config:Load(configName) end)
UI:AddButton(ConfigTab, "Delete", function() Config:Delete(configName) end)

local LogsTab = UI:AddTab("Logs")
UI:AddButton(LogsTab, "Refresh", function() UI:RefreshLogs(LogsTab.Page) end)
UI:AddButton(LogsTab, "Copy All", function()
    local lines = {}
    for _, log in ipairs(BloodyBlox.Logs) do
        table.insert(lines, string.format("[%s][%s] %s", log.time, log.category, log.message))
    end
    if setclipboard then
        setclipboard(table.concat(lines, "\n"))
    end
end)
UI:AddLabel(LogsTab, "Open this tab and press Refresh.")

local SettingsTab = UI:AddTab("Settings")
UI:AddButton(SettingsTab, "Disable All", function()
    BloodyBlox.Settings.ESP = false
    BloodyBlox.Settings.Fly = false
    BloodyBlox.Settings.Noclip = false
    BloodyBlox.Settings.InfiniteJump = false
    BloodyBlox.Settings.Fullbright = false
    BloodyBlox.Settings.WeightFarm = false
    BloodyBlox.Settings.DurabilityFarm = false
    BloodyBlox.Settings.AutoRebirth = false
    BloodyBlox.Settings.CombatFarm = false
    Farm:Stop("Weight")
    Farm:Stop("Durability")
    Farm:Stop("Rebirth")
    Farm:Stop("Combat")
    ESP:Toggle(false)
    PlayerTools:ToggleFly(false)
    PlayerTools:ToggleNoclip(false)
    PlayerTools:ToggleFullbright(false)
end)
UI:AddButton(SettingsTab, "EXIT", function()
    BloodyBlox.MenuOpen = false
    if UI.Gui then UI.Gui:Destroy() end
    for _, conn in ipairs(BloodyBlox.Connections) do disconnect(conn) end
    PlayerTools:ToggleFly(false)
    PlayerTools:ToggleNoclip(false)
    PlayerTools:ToggleFullbright(false)
    ESP:Toggle(false)
    Farm:Stop("Weight")
    Farm:Stop("Durability")
    Farm:Stop("Rebirth")
    Farm:Stop("Combat")
    _G.BloodyBloxLoaded = nil
end)
UI:AddLabel(SettingsTab, "Insert = menu toggle")

--============================================================
-- Runtime connections
--============================================================

BloodyBlox:AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        BloodyBlox.MenuOpen = not BloodyBlox.MenuOpen
        if UI.Gui then
            UI.Gui.Enabled = BloodyBlox.MenuOpen
        end
    elseif input.KeyCode == Enum.KeyCode.Space and BloodyBlox.Settings.InfiniteJump then
        local hum = BloodyBlox:GetHumanoid()
        if hum then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end
end))

BloodyBlox:AddConnection(RunService.RenderStepped:Connect(function()
    if BloodyBlox.Settings.ESP then
        ESP:Update()
    end
end))

BloodyBlox:AddConnection(Players.PlayerAdded:Connect(function(player)
    task.delay(1, function()
        if BloodyBlox.Settings.ESP then
            ESP:Add(player)
        end
    end)
end))

BloodyBlox:AddConnection(Players.PlayerRemoving:Connect(function(player)
    ESP:Remove(player)
end))

BloodyBlox:AddConnection(LocalPlayer.Idled:Connect(function()
    if BloodyBlox.Settings.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))

BloodyBlox:AddConnection(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if BloodyBlox.Settings.Fly then
        PlayerTools:ToggleFly(false)
        PlayerTools:ToggleFly(true)
    end
    if BloodyBlox.Settings.Noclip then
        PlayerTools:ToggleNoclip(false)
        PlayerTools:ToggleNoclip(true)
    end
end))

BloodyBlox:Log("System", "v" .. BloodyBlox.Version .. " loaded", "info")
print("[BloodyBlox] Loaded. Insert = toggle menu")
