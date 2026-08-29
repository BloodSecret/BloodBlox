--[[
    BloodyBlox v0.4.0
    Muscle Legends helper / analyzer

    Core fixes:
    - No loadstring() call is used inside this file.
    - Logs use a dedicated container; Refresh never destroys its own buttons/layout.
    - Exactly one UIListLayout is created for each dynamic container.
    - Remote hook validates hookmetamethod/getnamecallmethod/newcclosure before use.
    - Fly uses LinearVelocity + Attachment, not BodyVelocity.
    - Noclip restores original CanCollide values.
    - Fullbright restores the exact original Lighting values.
    - Config loading merges known settings instead of replacing the settings table.
    - Remote captures serialize arrays/dictionaries/Instances without guessing arguments.
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
    if type(fn) ~= "function" then
        return false, "callback is not a function"
    end
    return pcall(fn, ...)
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function getGlobal(name)
    local ok, value = pcall(function()
        return _G[name]
    end)
    if ok and value ~= nil then
        return value
    end
    if type(getgenv) == "function" then
        local ok2, env = pcall(getgenv)
        if ok2 and type(env) == "table" then
            return env[name]
        end
    end
    return nil
end

local BloodyBlox = {
    Version = "0.4.0",
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
    },
    State = {
        LogContainer = nil,
        FullbrightBackup = nil,
        NoclipBackup = {},
        FlyVelocity = nil,
        FlyAttachment = nil,
        LastCapture = nil,
        CapturingAction = nil,
        Profiles = {},
        AnalyzerHookInstalled = false,
        OriginalNamecall = nil,
        PendingTeleportName = nil,
        RemoteList = {},
        UI = nil,
    },
}

function BloodyBlox:Log(category, message, level)
    local entry = {
        time = os.date("%H:%M:%S"),
        category = tostring(category),
        message = tostring(message),
        level = level or "info",
    }
    table.insert(self.Logs, entry)
    if #self.Logs > 400 then
        table.remove(self.Logs, 1)
    end
    print(string.format("[%s][%s] %s", entry.time, entry.category, entry.message))
end

function BloodyBlox:GetCharacter()
    return self.Player.Character
end

function BloodyBlox:GetHumanoid()
    local character = self:GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

function BloodyBlox:GetHRP()
    local character = self:GetCharacter()
    return character and character:FindFirstChild("HumanoidRootPart") or nil
end

function BloodyBlox:AddConnection(connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

function BloodyBlox:DisconnectAll()
    for i = #self.Connections, 1, -1 do
        safeDisconnect(self.Connections[i])
        self.Connections[i] = nil
    end
end

--============================================================
-- Serialization
--============================================================

local function serialize(value, depth, seen)
    depth = depth or 0
    seen = seen or {}

    if depth > 5 then
        return {kind = "string", value = "<max-depth>"}
    end

    if value == nil then
        return {kind = "nil"}
    end

    local kind = typeof(value)

    if kind == "boolean" or kind == "number" or kind == "string" then
        return {kind = kind, value = value}
    elseif kind == "Vector3" then
        return {kind = "Vector3", x = value.X, y = value.Y, z = value.Z}
    elseif kind == "Vector2" then
        return {kind = "Vector2", x = value.X, y = value.Y}
    elseif kind == "CFrame" then
        local components = {value:GetComponents()}
        return {
            kind = "CFrame",
            components = components,
        }
    elseif kind == "Color3" then
        return {kind = "Color3", r = value.R, g = value.G, b = value.B}
    elseif kind == "BrickColor" then
        return {kind = "BrickColor", name = value.Name}
    elseif kind == "EnumItem" then
        return {
            kind = "EnumItem",
            enumType = tostring(value.EnumType),
            name = value.Name,
        }
    elseif kind == "Instance" then
        local fullName = ""
        pcall(function()
            fullName = value:GetFullName()
        end)
        return {
            kind = "Instance",
            path = fullName,
            class = value.ClassName,
        }
    elseif kind == "table" then
        if seen[value] then
            return {kind = "string", value = "<cycle>"}
        end

        seen[value] = true
        local array = {}
        local map = {}

        for key, item in pairs(value) do
            if type(key) == "number" and key >= 1 and key % 1 == 0 then
                array[key] = serialize(item, depth + 1, seen)
            else
                map[tostring(key)] = serialize(item, depth + 1, seen)
            end
        end

        seen[value] = nil
        return {
            kind = "table",
            array = array,
            map = map,
        }
    end

    return {kind = kind, value = tostring(value)}
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
        return Vector3.new(value.x or 0, value.y or 0, value.z or 0)
    elseif kind == "Vector2" then
        return Vector2.new(value.x or 0, value.y or 0)
    elseif kind == "CFrame" then
        local components = value.components
        if type(components) == "table" and #components == 12 then
            return CFrame.new(unpack(components))
        end
        return CFrame.new()
    elseif kind == "Color3" then
        return Color3.new(value.r or 0, value.g or 0, value.b or 0)
    elseif kind == "BrickColor" then
        local ok, result = pcall(function()
            return BrickColor.new(value.name)
        end)
        return ok and result or nil
    elseif kind == "EnumItem" then
        local enumName = tostring(value.enumType or ""):gsub("Enum%.", "")
        local enumType = Enum[enumName]
        if enumType and value.name then
            return enumType[value.name]
        end
        return nil
    elseif kind == "Instance" then
        local path = tostring(value.path or "")
        local current = game
        for segment in string.gmatch(path, "[^%.]+") do
            if segment ~= "game" then
                local nextObject = current:FindFirstChild(segment)
                if not nextObject then
                    return nil
                end
                current = nextObject
            end
        end
        return current
    elseif kind == "table" then
        local result = {}
        for key, item in pairs(value.array or {}) do
            result[tonumber(key) or key] = resolveSerialized(item)
        end
        for key, item in pairs(value.map or {}) do
            result[key] = resolveSerialized(item)
        end
        return result
    end

    return value.value
end

local function safeJsonEncode(value)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    return ok, result
end

--============================================================
-- File helpers
--============================================================

local function hasFilesystem()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function hasFolderAPI()
    return type(makefolder) == "function" and type(isfolder) == "function"
end

--============================================================
-- Analyzer / Remote Spy
--============================================================

local Analyzer = {}

function Analyzer:ScanRemotes()
    local list = {}
    for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
        if object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
            table.insert(list, {
                path = object:GetFullName(),
                name = object.Name,
                class = object.ClassName,
            })
        end
    end
    table.sort(list, function(a, b)
        return a.path < b.path
    end)
    BloodyBlox.State.RemoteList = list
    BloodyBlox:Log("Analyzer", "Found " .. tostring(#list) .. " remotes", "info")
    for index, remote in ipairs(list) do
        BloodyBlox:Log("Remote", string.format("[%d] %s (%s)", index, remote.path, remote.class), "info")
    end
    return list
end

function Analyzer:StartCapture(actionName)
    self:InstallHook()
    BloodyBlox.State.CapturingAction = tostring(actionName)
    BloodyBlox:Log("Analyzer", "Capture armed: " .. tostring(actionName), "warn")
end

function Analyzer:StopCapture()
    BloodyBlox.State.CapturingAction = nil
    BloodyBlox:Log("Analyzer", "Capture cancelled", "info")
end

function Analyzer:InstallHook()
    if BloodyBlox.State.AnalyzerHookInstalled then
        return true
    end

    if type(hookmetamethod) ~= "function" then
        BloodyBlox:Log("Analyzer", "hookmetamethod unavailable", "error")
        return false
    end
    if type(getnamecallmethod) ~= "function" then
        BloodyBlox:Log("Analyzer", "getnamecallmethod unavailable", "error")
        return false
    end
    if type(newcclosure) ~= "function" then
        BloodyBlox:Log("Analyzer", "newcclosure unavailable", "error")
        return false
    end

    local ok, result = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local args = {...}
                    local snapshot = {
                        path = self:GetFullName(),
                        name = self.Name,
                        class = self.ClassName,
                        method = method,
                        args = {},
                        time = os.clock(),
                    }

                    for index, arg in ipairs(args) do
                        snapshot.args[index] = serialize(arg)
                    end

                    BloodyBlox.State.LastCapture = snapshot
                    BloodyBlox:Log(
                        "RemoteSpy",
                        string.format("%s | %s | args=%d", snapshot.path, snapshot.method, #snapshot.args),
                        "info"
                    )

                    local action = BloodyBlox.State.CapturingAction
                    if action then
                        BloodyBlox.State.Profiles[action] = snapshot
                        BloodyBlox.State.CapturingAction = nil
                        BloodyBlox:Log("Analyzer", "Profile captured: " .. action, "warn")
                    end
                end
            end

            return oldNamecall(self, ...)
        end))

        BloodyBlox.State.OriginalNamecall = oldNamecall
        BloodyBlox.State.AnalyzerHookInstalled = true
        return true
    end)

    if not ok then
        BloodyBlox:Log("Analyzer", "Hook installation failed: " .. tostring(result), "error")
        return false
    end

    BloodyBlox:Log("Analyzer", "Remote spy installed", "warn")
    return true
end

function Analyzer:ResolveRemote(path)
    local current = game
    for segment in string.gmatch(tostring(path), "[^%.]+") do
        if segment ~= "game" then
            local nextObject = current:FindFirstChild(segment)
            if not nextObject then
                return nil
            end
            current = nextObject
        end
    end
    return current
end

function Analyzer:RunProfile(name)
    local profile = BloodyBlox.State.Profiles[name]
    if type(profile) ~= "table" then
        BloodyBlox:Log("Farm", "Profile missing: " .. tostring(name), "error")
        return false
    end

    local remote = self:ResolveRemote(profile.path)
    if not remote then
        BloodyBlox:Log("Farm", "Remote missing: " .. tostring(profile.path), "error")
        return false
    end

    local args = {}
    for index, encoded in ipairs(profile.args or {}) do
        args[index] = resolveSerialized(encoded)
    end

    local ok, err
    if profile.method == "FireServer" and remote:IsA("RemoteEvent") then
        ok, err = pcall(function()
            remote:FireServer(unpack(args))
        end)
    elseif profile.method == "InvokeServer" and remote:IsA("RemoteFunction") then
        ok, err = pcall(function()
            remote:InvokeServer(unpack(args))
        end)
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
    if not hasFilesystem() then
        BloodyBlox:Log("Config", "Filesystem API unavailable", "error")
        return false
    end

    if hasFolderAPI() and not isfolder("BloodyBlox") then
        pcall(function()
            makefolder("BloodyBlox")
        end)
    end

    local ok, json = safeJsonEncode(BloodyBlox.State.Profiles)
    if not ok then
        BloodyBlox:Log("Config", "Profile JSON encode failed: " .. tostring(json), "error")
        return false
    end

    local path = hasFolderAPI() and "BloodyBlox/profiles.json" or "BloodyBlox_profiles.json"
    local saved, err = pcall(function()
        writefile(path, json)
    end)
    if not saved then
        BloodyBlox:Log("Config", "Profiles save failed: " .. tostring(err), "error")
        return false
    end

    BloodyBlox:Log("Config", "Profiles saved", "info")
    return true
end

function Analyzer:LoadProfiles()
    if not hasFilesystem() then
        return false
    end

    local path = hasFolderAPI() and "BloodyBlox/profiles.json" or "BloodyBlox_profiles.json"
    if not isfile(path) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        BloodyBlox:Log("Config", "Profiles JSON invalid", "error")
        return false
    end

    BloodyBlox.State.Profiles = data
    BloodyBlox:Log("Config", "Profiles loaded", "info")
    return true
end

--============================================================
-- Farm loops
--============================================================

local Farm = {
    Tasks = {},
}

function Farm:Stop(name)
    local state = self.Tasks[name]
    if state then
        state.running = false
        self.Tasks[name] = nil
    end
end

function Farm:Start(name, interval, profileName)
    self:Stop(name)

    if not BloodyBlox.State.Profiles[profileName] then
        BloodyBlox:Log("Farm", "Capture profile first: " .. profileName, "error")
        return false
    end

    local state = {running = true}
    self.Tasks[name] = state

    task.spawn(function()
        while state.running do
            Analyzer:RunProfile(profileName)
            task.wait(math.max(0.05, tonumber(interval) or 0.25))
        end
    end)

    BloodyBlox:Log("Farm", name .. " started -> " .. profileName, "warn")
    return true
end

--============================================================
-- ESP
--============================================================

local ESP = {}

function ESP:Remove(player)
    for index = #BloodyBlox.ESPObjects, 1, -1 do
        local record = BloodyBlox.ESPObjects[index]
        if record.Player == player then
            for _, drawing in pairs(record.Drawings) do
                pcall(function()
                    drawing:Remove()
                end)
            end
            table.remove(BloodyBlox.ESPObjects, index)
        end
    end
end

function ESP:Add(player)
    if player == LocalPlayer then
        return
    end

    self:Remove(player)

    if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
        BloodyBlox:Log("ESP", "Drawing API unavailable", "error")
        return
    end

    local ok, drawings = pcall(function()
        return {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
            Health = Drawing.new("Line"),
            HealthOutline = Drawing.new("Line"),
            Tracer = Drawing.new("Line"),
        }
    end)

    if not ok or type(drawings) ~= "table" then
        BloodyBlox:Log("ESP", "Drawing creation failed", "error")
        return
    end

    drawings.Box.Thickness = 2
    drawings.Box.Filled = false
    drawings.Box.Visible = false
    drawings.Box.Color = Color3.fromRGB(255, 255, 255)

    drawings.Name.Size = 13
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Visible = false
    drawings.Name.Color = Color3.fromRGB(255, 255, 255)

    drawings.Distance.Size = 12
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Visible = false
    drawings.Distance.Color = Color3.fromRGB(200, 200, 200)

    drawings.Health.Thickness = 3
    drawings.Health.Visible = false
    drawings.Health.Color = Color3.fromRGB(0, 255, 0)

    drawings.HealthOutline.Thickness = 5
    drawings.HealthOutline.Visible = false
    drawings.HealthOutline.Color = Color3.fromRGB(0, 0, 0)

    drawings.Tracer.Thickness = 1
    drawings.Tracer.Visible = false
    drawings.Tracer.Color = Color3.fromRGB(255, 255, 255)

    table.insert(BloodyBlox.ESPObjects, {
        Player = player,
        Drawings = drawings,
    })
end

function ESP:SetVisible(record, visible)
    for _, drawing in pairs(record.Drawings) do
        drawing.Visible = visible
    end
end

function ESP:Update()
    local camera = Workspace.CurrentCamera
    local myRoot = BloodyBlox:GetHRP()
    if not camera then
        return
    end

    for _, record in ipairs(BloodyBlox.ESPObjects) do
        local player = record.Player
        local d = record.Drawings
        local character = player and player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not root or not head or not humanoid or humanoid.Health <= 0 then
            self:SetVisible(record, false)
        elseif BloodyBlox.Settings.ESPTeamCheck and player.Team == LocalPlayer.Team then
            self:SetVisible(record, false)
        else
            local rootPosition, onScreen = camera:WorldToViewportPoint(root.Position)
            if not onScreen or rootPosition.Z <= 0 then
                self:SetVisible(record, false)
            else
                local headPosition = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPosition = camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local height = math.max(20, math.abs(headPosition.Y - legPosition.Y))
                local width = math.max(10, height / 2)

                d.Box.Visible = BloodyBlox.Settings.ESPBoxes
                if BloodyBlox.Settings.ESPBoxes then
                    d.Box.Size = Vector2.new(width, height)
                    d.Box.Position = Vector2.new(rootPosition.X - width / 2, rootPosition.Y - height / 2)
                end

                d.Name.Visible = BloodyBlox.Settings.ESPNames
                if BloodyBlox.Settings.ESPNames then
                    d.Name.Text = player.Name
                    d.Name.Position = Vector2.new(rootPosition.X, headPosition.Y - 15)
                end

                d.Distance.Visible = BloodyBlox.Settings.ESPDistance and myRoot ~= nil
                if d.Distance.Visible and myRoot then
                    d.Distance.Text = tostring(math.floor((myRoot.Position - root.Position).Magnitude))
                    d.Distance.Position = Vector2.new(rootPosition.X, legPosition.Y + 5)
                end

                d.HealthOutline.Visible = BloodyBlox.Settings.ESPHealth
                d.Health.Visible = BloodyBlox.Settings.ESPHealth
                if BloodyBlox.Settings.ESPHealth then
                    local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
                    local x = rootPosition.X - width / 2 - 7
                    d.HealthOutline.From = Vector2.new(x, rootPosition.Y - height / 2)
                    d.HealthOutline.To = Vector2.new(x, rootPosition.Y + height / 2)
                    d.Health.From = Vector2.new(x, rootPosition.Y + height / 2)
                    d.Health.To = Vector2.new(x, rootPosition.Y + height / 2 - height * ratio)
                    d.Health.Color = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
                end

                d.Tracer.Visible = BloodyBlox.Settings.ESPTracers
                if BloodyBlox.Settings.ESPTracers then
                    d.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    d.Tracer.To = Vector2.new(rootPosition.X, rootPosition.Y)
                end
            end
        end
    end
end

function ESP:Toggle(enabled)
    BloodyBlox.Settings.ESP = enabled

    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            self:Add(player)
        end
    else
        for index = #BloodyBlox.ESPObjects, 1, -1 do
            local record = BloodyBlox.ESPObjects[index]
            for _, drawing in pairs(record.Drawings) do
                pcall(function()
                    drawing:Remove()
                end)
            end
            table.remove(BloodyBlox.ESPObjects, index)
        end
    end
end

--============================================================
-- Player tools
--============================================================

local PlayerTools = {}

function PlayerTools:ToggleNoclip(enabled)
    BloodyBlox.Settings.Noclip = enabled

    if self.NoclipConnection then
        safeDisconnect(self.NoclipConnection)
        self.NoclipConnection = nil
    end

    if not enabled then
        for part, original in pairs(BloodyBlox.State.NoclipBackup) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = original
                end)
            end
        end
        BloodyBlox.State.NoclipBackup = {}
        return
    end

    self.NoclipConnection = RunService.Stepped:Connect(function()
        local character = BloodyBlox:GetCharacter()
        if not character then
            return
        end

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if BloodyBlox.State.NoclipBackup[part] == nil then
                    BloodyBlox.State.NoclipBackup[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
    BloodyBlox:AddConnection(self.NoclipConnection)
end

function PlayerTools:ClearFlyObjects()
    safeDestroy(self.FlyVelocity)
    safeDestroy(self.FlyAttachment)
    self.FlyVelocity = nil
    self.FlyAttachment = nil

    local root = BloodyBlox:GetHRP()
    if root then
        local attachment = root:FindFirstChild("BloodyBloxFlyAttachment")
        local velocity = root:FindFirstChild("BloodyBloxFlyVelocity")
        safeDestroy(attachment)
        safeDestroy(velocity)
    end
end

function PlayerTools:ToggleFly(enabled)
    BloodyBlox.Settings.Fly = enabled

    if self.FlyConnection then
        safeDisconnect(self.FlyConnection)
        self.FlyConnection = nil
    end

    self:ClearFlyObjects()

    if not enabled then
        return
    end

    local root = BloodyBlox:GetHRP()
    if not root then
        BloodyBlox:Log("Player", "Fly: HumanoidRootPart unavailable", "error")
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "BloodyBloxFlyAttachment"
    attachment.Parent = root

    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "BloodyBloxFlyVelocity"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VectorVelocity = Vector3.zero
    velocity.Parent = root

    self.FlyAttachment = attachment
    self.FlyVelocity = velocity

    self.FlyConnection = RunService.RenderStepped:Connect(function()
        if not BloodyBlox.Settings.Fly then
            return
        end

        local currentRoot = BloodyBlox:GetHRP()
        local camera = Workspace.CurrentCamera
        if not currentRoot or not camera or not self.FlyVelocity then
            return
        end

        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction -= Vector3.yAxis
        end

        local speed = math.clamp(tonumber(BloodyBlox.Settings.FlySpeed) or 5, 1, 20) * 50
        self.FlyVelocity.VectorVelocity = direction * speed
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
        local backup = BloodyBlox.State.FullbrightBackup
        if backup then
            Lighting.Brightness = backup.Brightness
            Lighting.ClockTime = backup.ClockTime
            Lighting.FogEnd = backup.FogEnd
            Lighting.GlobalShadows = backup.GlobalShadows
            Lighting.OutdoorAmbient = backup.OutdoorAmbient
        end
        BloodyBlox.State.FullbrightBackup = nil
    end
end

--============================================================
-- Teleport
--============================================================

local Teleport = {}

function Teleport:GetPath()
    if hasFolderAPI() then
        return "BloodyBlox/teleports.json"
    end
    return "BloodyBlox_teleports.json"
end

function Teleport:Save()
    if not hasFilesystem() then
        BloodyBlox:Log("Teleport", "Filesystem API unavailable", "error")
        return false
    end

    if hasFolderAPI() and not isfolder("BloodyBlox") then
        pcall(function()
            makefolder("BloodyBlox")
        end)
    end

    local ok, json = safeJsonEncode(BloodyBlox.TeleportPoints)
    if not ok then
        BloodyBlox:Log("Teleport", "JSON encode failed", "error")
        return false
    end

    local saved, err = pcall(function()
        writefile(self:GetPath(), json)
    end)
    if not saved then
        BloodyBlox:Log("Teleport", "Save failed: " .. tostring(err), "error")
        return false
    end

    return true
end

function Teleport:Load()
    if not hasFilesystem() then
        return false
    end

    local path = self:GetPath()
    if not isfile(path) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        BloodyBlox:Log("Teleport", "Teleport file invalid", "error")
        return false
    end

    BloodyBlox.TeleportPoints = data
    return true
end

function Teleport:Add(name)
    local root = BloodyBlox:GetHRP()
    if not root then
        BloodyBlox:Log("Teleport", "HumanoidRootPart unavailable", "error")
        return false
    end

    table.insert(BloodyBlox.TeleportPoints, {
        name = tostring(name or ("Point_" .. (#BloodyBlox.TeleportPoints + 1))),
        x = root.Position.X,
        y = root.Position.Y,
        z = root.Position.Z,
    })

    self:Save()
    BloodyBlox:Log("Teleport", "Point saved", "info")
    return true
end

function Teleport:Go(point)
    if type(point) ~= "table" then
        return false
    end

    local root = BloodyBlox:GetHRP()
    if not root then
        return false
    end

    root.CFrame = CFrame.new(tonumber(point.x) or 0, tonumber(point.y) or 0, tonumber(point.z) or 0)
    return true
end

function Teleport:Delete(index)
    index = tonumber(index)
    if not index or not BloodyBlox.TeleportPoints[index] then
        return false
    end
    table.remove(BloodyBlox.TeleportPoints, index)
    self:Save()
    return true
end

--============================================================
-- Config
--============================================================

local Config = {}

function Config:SanitizeName(name)
    return tostring(name or ""):gsub("[^%w_%-]", "_")
end

function Config:Save(name)
    if not hasFilesystem() then
        BloodyBlox:Log("Config", "Filesystem API unavailable", "error")
        return false
    end

    name = self:SanitizeName(name)
    if name == "" then
        BloodyBlox:Log("Config", "Invalid config name", "error")
        return false
    end

    local data = {
        Version = BloodyBlox.Version,
        Settings = BloodyBlox.Settings,
        Profiles = BloodyBlox.State.Profiles,
        Teleports = BloodyBlox.TeleportPoints,
    }

    local ok, json = safeJsonEncode(data)
    if not ok then
        BloodyBlox:Log("Config", "Config encode failed", "error")
        return false
    end

    local saved, err = pcall(function()
        writefile("BloodyBlox_" .. name .. ".json", json)
    end)

    if not saved then
        BloodyBlox:Log("Config", "Save failed: " .. tostring(err), "error")
        return false
    end

    BloodyBlox:Log("Config", "Saved: " .. name, "info")
    return true
end

function Config:Load(name)
    if not hasFilesystem() then
        BloodyBlox:Log("Config", "Filesystem API unavailable", "error")
        return false
    end

    name = self:SanitizeName(name)
    if name == "" then
        BloodyBlox:Log("Config", "Invalid config name", "error")
        return false
    end

    local path = "BloodyBlox_" .. name .. ".json"
    if not isfile(path) then
        BloodyBlox:Log("Config", "Not found: " .. name, "error")
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok or type(data) ~= "table" then
        BloodyBlox:Log("Config", "Invalid JSON", "error")
        return false
    end

    if type(data.Settings) == "table" then
        for key, defaultValue in pairs(BloodyBlox.Settings) do
            local loadedValue = data.Settings[key]
            if loadedValue ~= nil and type(loadedValue) == type(defaultValue) then
                BloodyBlox.Settings[key] = loadedValue
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
    return true
end

function Config:Delete(name)
    if type(isfile) ~= "function" or type(delfile) ~= "function" then
        BloodyBlox:Log("Config", "Delete API unavailable", "error")
        return false
    end

    name = self:SanitizeName(name)
    local path = "BloodyBlox_" .. name .. ".json"
    if not isfile(path) then
        BloodyBlox:Log("Config", "Not found", "error")
        return false
    end

    local ok, err = pcall(function()
        delfile(path)
    end)
    if not ok then
        BloodyBlox:Log("Config", "Delete failed: " .. tostring(err), "error")
        return false
    end

    BloodyBlox:Log("Config", "Deleted: " .. name, "warn")
    return true
end

--============================================================
-- UI
--============================================================

local UI = {
    Tabs = {},
    CurrentTab = nil,
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function UI:Create()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    self.Gui = create("ScreenGui", {
        Name = "BloodyBloxUI_" .. HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

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

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = Color3.fromRGB(139, 0, 0),
        BorderSizePixel = 0,
    }, self.Main)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 0, 44),
        Position = UDim2.fromOffset(16, 3),
        BackgroundTransparency = 1,
        Text = "BLOODYBLOX  v" .. BloodyBlox.Version,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.Main)

    local close = create("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -44, 0, 7),
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
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, self.Sidebar)
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Sidebar)

    self.Content = create("Frame", {
        Size = UDim2.new(1, -170, 1, -58),
        Position = UDim2.fromOffset(160, 50),
        BackgroundColor3 = Color3.fromRGB(18, 18, 24),
        BorderSizePixel = 0,
    }, self.Main)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.Content)

    BloodyBlox.State.UI = self
    return self
end

function UI:AddTab(name)
    local tab = {
        Name = name,
    }

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
    create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
    }, tab.Page)
    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tab.Page)

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
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = Color3.fromRGB(190, 190, 200),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, tab.Page)
end

function UI:AddButton(tab, text, callback)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(139, 0, 0),
        BorderSizePixel = 0,
        Text = tostring(text),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
    button.MouseButton1Click:Connect(function()
        local ok, err = safeCall(callback)
        if not ok then
            BloodyBlox:Log("UI", "Callback error: " .. tostring(err), "error")
        end
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
        Text = tostring(text),
        TextColor3 = Color3.fromRGB(225, 225, 225),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local state = default == true
    local button = create("TextButton", {
        Size = UDim2.fromOffset(42, 20),
        Position = UDim2.new(1, -48, 0.5, -10),
        BackgroundColor3 = state and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 85),
        BorderSizePixel = 0,
        Text = state and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, frame)
    create("UICorner", {CornerRadius = UDim.new(0, 5)}, button)

    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 85)
        local ok, err = safeCall(callback, state)
        if not ok then
            BloodyBlox:Log("UI", "Toggle error: " .. tostring(err), "error")
        end
    end)

    return button
end

function UI:AddTextBox(tab, placeholder, callback)
    local box = create("TextBox", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
        PlaceholderText = tostring(placeholder),
        Text = "",
        TextColor3 = Color3.fromRGB(230, 230, 230),
        PlaceholderColor3 = Color3.fromRGB(110, 110, 120),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, box)

    box.FocusLost:Connect(function()
        local ok, err = safeCall(callback, box.Text)
        if not ok then
            BloodyBlox:Log("UI", "Textbox error: " .. tostring(err), "error")
        end
    end)

    return box
end

function UI:AddNumberBox(tab, placeholder, default, callback)
    return self:AddTextBox(tab, tostring(placeholder) .. " = " .. tostring(default), function(text)
        local number = tonumber(text)
        if number then
            callback(number)
        end
    end)
end

function UI:CreateLogContainer(page)
    local existing = page:FindFirstChild("LogEntries")
    if existing then
        BloodyBlox.State.LogContainer = existing
        return existing
    end

    local container = create("ScrollingFrame", {
        Name = "LogEntries",
        Size = UDim2.new(1, 0, 0, 280),
        BackgroundColor3 = Color3.fromRGB(24, 24, 30),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, container)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    }, container)
    create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, container)

    BloodyBlox.State.LogContainer = container
    return container
end

function UI:RefreshLogs(page)
    local container = self:CreateLogContainer(page)

    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local startIndex = math.max(1, #BloodyBlox.Logs - 100)
    local order = 0

    for index = startIndex, #BloodyBlox.Logs do
        local log = BloodyBlox.Logs[index]
        if log then
            order += 1
            local label = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = string.format("[%s][%s] %s", log.time, log.category, log.message),
                TextColor3 = Color3.fromRGB(205, 205, 215),
                Font = Enum.Font.Code,
                TextSize = 11,
                TextWrapped = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = order,
            }, container)
            label:SetAttribute("LogRow", true)
        end
    end
end

function UI:Destroy()
    if self.Gui then
        pcall(function()
            self.Gui:Destroy()
        end)
    end
    self.Gui = nil
    self.Main = nil
    self.Sidebar = nil
    self.Content = nil
end

--============================================================
-- Build UI
--============================================================

UI:Create()
Teleport:Load()
Analyzer:LoadProfiles()
Analyzer:InstallHook()

local MainTab = UI:AddTab("Main")
UI:AddLabel(MainTab, "Local tools work independently. Game actions require real captured calls.")
UI:AddButton(MainTab, "Analyze Remotes", function()
    Analyzer:ScanRemotes()
end)
UI:AddButton(MainTab, "Save Profiles", function()
    Analyzer:SaveProfiles()
end)
UI:AddButton(MainTab, "Run Weight Once", function()
    Analyzer:RunProfile("Weight")
end)
UI:AddButton(MainTab, "Run Durability Once", function()
    Analyzer:RunProfile("Durability")
end)
UI:AddButton(MainTab, "Run Rebirth Once", function()
    Analyzer:RunProfile("Rebirth")
end)
UI:AddButton(MainTab, "Run Combat Once", function()
    Analyzer:RunProfile("Combat")
end)

local FarmTab = UI:AddTab("Farm")
UI:AddToggle(FarmTab, "Weight Farm", false, function(state)
    BloodyBlox.Settings.WeightFarm = state
    if state then
        Farm:Start("Weight", BloodyBlox.Settings.WeightInterval, "Weight")
    else
        Farm:Stop("Weight")
    end
end)
UI:AddNumberBox(FarmTab, "Weight interval", 0.25, function(value)
    BloodyBlox.Settings.WeightInterval = math.max(0.05, value)
end)

UI:AddToggle(FarmTab, "Durability Farm", false, function(state)
    BloodyBlox.Settings.DurabilityFarm = state
    if state then
        Farm:Start("Durability", BloodyBlox.Settings.DurabilityInterval, "Durability")
    else
        Farm:Stop("Durability")
    end
end)
UI:AddNumberBox(FarmTab, "Durability interval", 0.25, function(value)
    BloodyBlox.Settings.DurabilityInterval = math.max(0.05, value)
end)

UI:AddToggle(FarmTab, "Auto Rebirth", false, function(state)
    BloodyBlox.Settings.AutoRebirth = state
    if state then
        Farm:Start("Rebirth", BloodyBlox.Settings.RebirthInterval, "Rebirth")
    else
        Farm:Stop("Rebirth")
    end
end)
UI:AddNumberBox(FarmTab, "Rebirth interval", 2, function(value)
    BloodyBlox.Settings.RebirthInterval = math.max(0.1, value)
end)

UI:AddToggle(FarmTab, "Combat Farm", false, function(state)
    BloodyBlox.Settings.CombatFarm = state
    if state then
        Farm:Start("Combat", BloodyBlox.Settings.CombatInterval, "Combat")
    else
        Farm:Stop("Combat")
    end
end)
UI:AddNumberBox(FarmTab, "Combat interval", 0.25, function(value)
    BloodyBlox.Settings.CombatInterval = math.max(0.05, value)
end)

local AnalyzerTab = UI:AddTab("Analyzer")
UI:AddLabel(AnalyzerTab, "Press Capture, then perform exactly one action manually. The next client remote call becomes the profile.")
UI:AddButton(AnalyzerTab, "Scan Remotes", function()
    Analyzer:ScanRemotes()
end)
UI:AddButton(AnalyzerTab, "Capture Next Weight", function()
    Analyzer:StartCapture("Weight")
end)
UI:AddButton(AnalyzerTab, "Capture Next Durability", function()
    Analyzer:StartCapture("Durability")
end)
UI:AddButton(AnalyzerTab, "Capture Next Rebirth", function()
    Analyzer:StartCapture("Rebirth")
end)
UI:AddButton(AnalyzerTab, "Capture Next Combat", function()
    Analyzer:StartCapture("Combat")
end)
UI:AddButton(AnalyzerTab, "Cancel Capture", function()
    Analyzer:StopCapture()
end)
UI:AddButton(AnalyzerTab, "Run Last Capture", function()
    local last = BloodyBlox.State.LastCapture
    if not last then
        BloodyBlox:Log("Analyzer", "Nothing captured", "error")
        return
    end
    BloodyBlox.State.Profiles.__Last = last
    Analyzer:RunProfile("__Last")
end)
UI:AddButton(AnalyzerTab, "Save Profiles", function()
    Analyzer:SaveProfiles()
end)

local VisualTab = UI:AddTab("Visual")
UI:AddToggle(VisualTab, "ESP", false, function(state)
    ESP:Toggle(state)
end)
UI:AddToggle(VisualTab, "Boxes", true, function(state)
    BloodyBlox.Settings.ESPBoxes = state
end)
UI:AddToggle(VisualTab, "Names", true, function(state)
    BloodyBlox.Settings.ESPNames = state
end)
UI:AddToggle(VisualTab, "Distance", true, function(state)
    BloodyBlox.Settings.ESPDistance = state
end)
UI:AddToggle(VisualTab, "Health", true, function(state)
    BloodyBlox.Settings.ESPHealth = state
end)
UI:AddToggle(VisualTab, "Tracers", false, function(state)
    BloodyBlox.Settings.ESPTracers = state
end)
UI:AddToggle(VisualTab, "Team Check", false, function(state)
    BloodyBlox.Settings.ESPTeamCheck = state
end)
UI:AddToggle(VisualTab, "Fullbright", false, function(state)
    PlayerTools:ToggleFullbright(state)
end)

local PlayerTab = UI:AddTab("Player")
UI:AddToggle(PlayerTab, "Fly", false, function(state)
    PlayerTools:ToggleFly(state)
end)
UI:AddNumberBox(PlayerTab, "Fly speed", 5, function(value)
    BloodyBlox.Settings.FlySpeed = math.clamp(value, 1, 20)
end)
UI:AddToggle(PlayerTab, "Noclip", false, function(state)
    PlayerTools:ToggleNoclip(state)
end)
UI:AddToggle(PlayerTab, "Infinite Jump", false, function(state)
    PlayerTools:ToggleInfiniteJump(state)
end)
UI:AddToggle(PlayerTab, "Anti-AFK", true, function(state)
    BloodyBlox.Settings.AntiAFK = state
end)

local TeleportTab = UI:AddTab("Teleport")
UI:AddTextBox(TeleportTab, "Point name...", function(text)
    BloodyBlox.State.PendingTeleportName = (#text > 0 and text) or nil
end)
UI:AddButton(TeleportTab, "Save Current Position", function()
    Teleport:Add(BloodyBlox.State.PendingTeleportName)
end)
UI:AddButton(TeleportTab, "Rebuild Saved Points", function()
    Teleport:Load()
    UI:SelectTab(TeleportTab)
    BloodyBlox:Log("Teleport", "Reloaded saved points. Restart is not required.", "info")
end)

for index, point in ipairs(BloodyBlox.TeleportPoints) do
    UI:AddButton(TeleportTab, "TP: " .. tostring(point.name or ("Point_" .. index)), function()
        Teleport:Go(point)
    end)
end

local ConfigTab = UI:AddTab("Config")
local ConfigName = ""
UI:AddTextBox(ConfigTab, "Config name...", function(text)
    ConfigName = text
end)
UI:AddButton(ConfigTab, "Save Config", function()
    Config:Save(ConfigName)
end)
UI:AddButton(ConfigTab, "Load Config", function()
    Config:Load(ConfigName)
end)
UI:AddButton(ConfigTab, "Delete Config", function()
    Config:Delete(ConfigName)
end)

local LogsTab = UI:AddTab("Logs")
UI:AddButton(LogsTab, "Refresh", function()
    UI:RefreshLogs(LogsTab.Page)
end)
UI:AddButton(LogsTab, "Copy All", function()
    local lines = {}
    for _, log in ipairs(BloodyBlox.Logs) do
        lines[#lines + 1] = string.format("[%s][%s] %s", log.time, log.category, log.message)
    end
    local text = table.concat(lines, "\n")
    if type(setclipboard) == "function" then
        pcall(function()
            setclipboard(text)
        end)
        BloodyBlox:Log("Logs", "Copied to clipboard", "info")
    else
        BloodyBlox:Log("Logs", "setclipboard unavailable", "error")
    end
end)
local LogContainer = UI:CreateLogContainer(LogsTab.Page)
UI:AddLabel(LogsTab, "Refresh updates only the log list. The buttons/layout are never destroyed.")

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

    Farm:Stop("Weight")
    Farm:Stop("Durability")
    Farm:Stop("Rebirth")
    Farm:Stop("Combat")

    ESP:Toggle(false)
    PlayerTools:ToggleFly(false)
    PlayerTools:ToggleNoclip(false)
    PlayerTools:ToggleFullbright(false)

    BloodyBlox:DisconnectAll()
    UI:Destroy()
    BloodyBlox.State.UI = nil
    _G.BloodyBloxLoaded = nil
end)
UI:AddLabel(SettingsTab, "Insert = toggle menu")

--============================================================
-- Runtime
--============================================================

BloodyBlox:AddConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Insert then
        BloodyBlox.MenuOpen = not BloodyBlox.MenuOpen
        if UI.Gui then
            UI.Gui.Enabled = BloodyBlox.MenuOpen
        end
    elseif input.KeyCode == Enum.KeyCode.Space and BloodyBlox.Settings.InfiniteJump then
        local humanoid = BloodyBlox:GetHumanoid()
        if humanoid then
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
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
        task.wait(0.05)
        PlayerTools:ToggleFly(true)
    end

    if BloodyBlox.Settings.Noclip then
        PlayerTools:ToggleNoclip(false)
        task.wait(0.05)
        PlayerTools:ToggleNoclip(true)
    end
end))

BloodyBlox:Log("System", "v" .. BloodyBlox.Version .. " loaded", "info")
print("[BloodyBlox] Loaded. Insert = toggle menu")

name:BloodyBlox_v0.4.0.lua
path:/mnt/data/BloodyBlox_v0.4.0.lua
 
