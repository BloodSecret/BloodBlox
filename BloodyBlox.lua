--[[
    BloodyBlox v0.5.4
    Muscle Legends helper / analyzer

    v0.5.4 changes (2026-08-31):
    - FastHits throttle added (0.05s cooldown, fixed lag)
    - Watermark draggable with MoveWatermark toggle
    - Watermark position fixed (above chat, right side, persists after close)
    - Menu scale changed to textbox input (removed slider)
    - WalkWithDumbbell speed fixed (25 instead of 16)
    - FastStrafe fixed (removes inertia via AssemblyLinearVelocity)
    - AntiRagdoll added (prevents falling when hit)
    - Teleport/Config UI rebuilt (inline Delete/Overwrite buttons)
    - All Combat logging removed (Kill Aura + Fast Hits silent)

    Core architecture:
    - No loadstring() call is used inside this file.
    - Logs use a dedicated container; Refresh never destroys its own buttons/layout.
    - Exactly one UIListLayout is created for each dynamic container.
    - Remote hook validates hookmetamethod/getnamecallmethod/newcclosure before use.
    - Noclip restores original CanCollide values.
    - Fullbright restores the exact original Lighting values.
    - Config loading merges known settings instead of replacing the settings table.
    - Remote captures serialize arrays/dictionaries/Instances without guessing arguments.
    - Game load guard prevents CoreGui nil crash on cold start.
    - Auto Bad Aura farm targets only NPCs with "bad" in name.
]]

-- Wait for game to fully load before initializing
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

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
    Version = "0.5.4",
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
        GodMode = false,
        Fullbright = false,
        RemoteSpyEnabled = false,
        WeightFarm = false,
        WeightInterval = 0.25,
        DurabilityFarm = false,
        DurabilityInterval = 0.25,
        AutoRebirth = false,
        RebirthInterval = 2,
        CombatFarm = false,
        CombatInterval = 0.25,
        BadAuraFarm = false,
        BadAuraInterval = 0.1,
        AntiAim = false,
        KillAura = false,
        KillAuraRadius = 20,
        FastHits = false,
        WalkWithDumbbell = false,
        FastStrafe = false,
        AntiRagdoll = false,
        ShowWatermark = true,
        WatermarkDraggable = false,
        MenuScale = 1.0,
    },
    State = {
        LogContainer = nil,
        FullbrightBackup = nil,
        NoclipBackup = {},
        FlyVelocity = nil,
        LastCapture = nil,
        CapturingAction = nil,
        Profiles = {},
        AnalyzerHookInstalled = false,
        OriginalNamecall = nil,
        PendingTeleportName = nil,
        RemoteList = {},
        UI = nil,
        WatermarkLabel = nil,
        OriginalWalkSpeed = 16,
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

function BloodyBlox:SaveConfig()
    task.spawn(function()
        Config:Save("autosave")
    end)
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

function Analyzer:ScanNPCs()
    local npcs = {}
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Model") and object:FindFirstChild("Humanoid") and object:FindFirstChild("HumanoidRootPart") then
            local humanoid = object.Humanoid
            local hrp = object.HumanoidRootPart
            table.insert(npcs, {
                name = object.Name,
                health = humanoid.Health,
                maxHealth = humanoid.MaxHealth,
                position = hrp.Position,
            })
        end
    end
    BloodyBlox:Log("Analyzer", "Found " .. tostring(#npcs) .. " NPCs", "info")
    for index, npc in ipairs(npcs) do
        BloodyBlox:Log("NPC", string.format("[%d] %s | HP: %.0f/%.0f | Pos: %s",
            index, npc.name, npc.health, npc.maxHealth, tostring(npc.position)), "info")
    end
    return npcs
end

function Analyzer:ScanTools()
    local tools = {}
    for _, object in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if object:IsA("Tool") then
            table.insert(tools, object.Name)
        end
    end
    local character = BloodyBlox:GetCharacter()
    if character then
        for _, object in ipairs(character:GetChildren()) do
            if object:IsA("Tool") then
                table.insert(tools, object.Name .. " (equipped)")
            end
        end
    end
    BloodyBlox:Log("Analyzer", "Found " .. tostring(#tools) .. " tools", "info")
    for index, name in ipairs(tools) do
        BloodyBlox:Log("Tool", string.format("[%d] %s", index, name), "info")
    end
    return tools
end

function Analyzer:DumpOffsets()
    local character = BloodyBlox:GetCharacter()
    if not character then
        BloodyBlox:Log("Analyzer", "Character unavailable", "error")
        return
    end

    BloodyBlox:Log("Analyzer", "=== CHARACTER DUMP ===", "info")
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            BloodyBlox:Log("Part", string.format("%s | CFrame: %s | Size: %s",
                object.Name, tostring(object.CFrame), tostring(object.Size)), "info")
        elseif object:IsA("Humanoid") then
            BloodyBlox:Log("Humanoid", string.format("HP: %.0f/%.0f | WalkSpeed: %.1f | JumpPower: %.1f",
                object.Health, object.MaxHealth, object.WalkSpeed, object.JumpPower), "info")
        end
    end
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

                    local action = BloodyBlox.State.CapturingAction
                    if BloodyBlox.Settings.RemoteSpyEnabled or action then
                        BloodyBlox:Log(
                            "RemoteSpy",
                            string.format("%s | %s | args=%d", snapshot.path, snapshot.method, #snapshot.args),
                            "info"
                        )
                    end

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

function Farm:StartBadAura()
    self:Stop("BadAura")

    local state = {running = true}
    self.Tasks.BadAura = state

    task.spawn(function()
        while state.running do
            pcall(function()
                local myRoot = BloodyBlox:GetHRP()
                if not myRoot then return end

                local closest = nil
                local closestDist = math.huge

                for _, object in ipairs(Workspace:GetDescendants()) do
                    if object:IsA("Model") and object:FindFirstChild("Humanoid") and object:FindFirstChild("HumanoidRootPart") then
                        local name = object.Name:lower()
                        if name:find("bad") then
                            local humanoid = object.Humanoid
                            local npcRoot = object.HumanoidRootPart
                            if humanoid.Health > 0 then
                                local dist = (myRoot.Position - npcRoot.Position).Magnitude
                                if dist < closestDist then
                                    closest = object
                                    closestDist = dist
                                end
                            end
                        end
                    end
                end

                if not closest then return end

                local targetRoot = closest.HumanoidRootPart
                if not targetRoot then return end

                local targetPos = targetRoot.Position + (targetRoot.CFrame.LookVector * 3)
                myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)

                if type(mouse1press) == "function" and type(mouse1release) == "function" then
                    mouse1press()
                    task.wait(0.01)
                    mouse1release()
                end

                for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                    if remote:IsA("RemoteEvent") then
                        local remoteName = remote.Name:lower()
                        if remoteName:find("punch") or remoteName:find("attack") or remoteName:find("hit") or remoteName:find("damage") then
                            pcall(function()
                                remote:FireServer(closest)
                            end)
                        end
                    end
                end
            end)

            task.wait(BloodyBlox.Settings.BadAuraInterval or 0.1)
        end
    end)

    BloodyBlox:Log("Farm", "Bad Aura farm started", "warn")
    return true
end

--============================================================
-- Combat (NO LOGGING)
--============================================================

local Combat = {}

function Combat:ToggleAntiAim(enabled)
    BloodyBlox.Settings.AntiAim = enabled

    if self.AntiAimConnection then
        safeDisconnect(self.AntiAimConnection)
        self.AntiAimConnection = nil
    end

    if not enabled then
        return
    end

    self.AntiAimConnection = RunService.RenderStepped:Connect(function()
        local root = BloodyBlox:GetHRP()
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(30), 0)
        end
    end)
    BloodyBlox:AddConnection(self.AntiAimConnection)
end

function Combat:ToggleKillAura(enabled)
    BloodyBlox.Settings.KillAura = enabled

    if self.KillAuraConnection then
        safeDisconnect(self.KillAuraConnection)
        self.KillAuraConnection = nil
    end

    if not enabled then
        return
    end

    self.KillAuraConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local myRoot = BloodyBlox:GetHRP()
            if not myRoot then return end

            local radius = BloodyBlox.Settings.KillAuraRadius or 20

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if targetRoot and humanoid and humanoid.Health > 0 then
                        local dist = (myRoot.Position - targetRoot.Position).Magnitude
                        if dist <= radius then
                            if type(mouse1press) == "function" and type(mouse1release) == "function" then
                                mouse1press()
                                task.wait(0.01)
                                mouse1release()
                            end

                            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                if remote:IsA("RemoteEvent") then
                                    local remoteName = remote.Name:lower()
                                    if remoteName:find("punch") or remoteName:find("attack") or remoteName:find("hit") or remoteName:find("damage") then
                                        pcall(function()
                                            remote:FireServer(player)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
    BloodyBlox:AddConnection(self.KillAuraConnection)
end

function Combat:ToggleFastHits(enabled)
    BloodyBlox.Settings.FastHits = enabled

    if self.FastHitsConnection then
        safeDisconnect(self.FastHitsConnection)
        self.FastHitsConnection = nil
    end

    if not enabled then
        return
    end

    local lastHit = 0
    self.FastHitsConnection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastHit < 0.05 then return end
        lastHit = now

        pcall(function()
            local myRoot = BloodyBlox:GetHRP()
            if not myRoot then return end

            local closest = nil
            local closestDist = math.huge

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

                    if targetRoot and humanoid and humanoid.Health > 0 then
                        local dist = (myRoot.Position - targetRoot.Position).Magnitude
                        if dist < closestDist then
                            closest = player
                            closestDist = dist
                        end
                    end
                end
            end

            if not closest then return end

            local targetCharacter = closest.Character
            local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return end

            local targetPos = targetRoot.Position + (targetRoot.CFrame.LookVector * 3)
            myRoot.CFrame = CFrame.new(targetPos, targetRoot.Position)

            if type(mouse1press) == "function" and type(mouse1release) == "function" then
                mouse1press()
                task.wait(0.01)
                mouse1release()
            end

            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local remoteName = remote.Name:lower()
                    if remoteName:find("punch") or remoteName:find("attack") or remoteName:find("hit") or remoteName:find("damage") then
                        pcall(function()
                            remote:FireServer(closest)
                        end)
                    end
                end
            end
        end)
    end)
    BloodyBlox:AddConnection(self.FastHitsConnection)
end

--============================================================
-- Misc
--============================================================

local Misc = {}

function Misc:ToggleWalkWithDumbbell(enabled)
    BloodyBlox.Settings.WalkWithDumbbell = enabled

    if self.WalkWithDumbbellConnection then
        safeDisconnect(self.WalkWithDumbbellConnection)
        self.WalkWithDumbbellConnection = nil
    end

    if not enabled then
        local humanoid = BloodyBlox:GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = BloodyBlox.State.OriginalWalkSpeed
        end
        return
    end

    self.WalkWithDumbbellConnection = RunService.Heartbeat:Connect(function()
        local humanoid = BloodyBlox:GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 25
        end
    end)
    BloodyBlox:AddConnection(self.WalkWithDumbbellConnection)
end

function Misc:ToggleFastStrafe(enabled)
    BloodyBlox.Settings.FastStrafe = enabled

    if self.FastStrafeConnection then
        safeDisconnect(self.FastStrafeConnection)
        self.FastStrafeConnection = nil
    end

    if not enabled then
        return
    end

    self.FastStrafeConnection = RunService.Heartbeat:Connect(function()
        local root = BloodyBlox:GetHRP()
        if root then
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X * 0.5, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z * 0.5)
        end
    end)
    BloodyBlox:AddConnection(self.FastStrafeConnection)
end

function Misc:ToggleAntiRagdoll(enabled)
    BloodyBlox.Settings.AntiRagdoll = enabled

    if self.AntiRagdollConnection then
        safeDisconnect(self.AntiRagdollConnection)
        self.AntiRagdollConnection = nil
    end

    if not enabled then
        return
    end

    self.AntiRagdollConnection = RunService.Heartbeat:Connect(function()
        local humanoid = BloodyBlox:GetHumanoid()
        if humanoid then
            humanoid.PlatformStand = false
        end
    end)
    BloodyBlox:AddConnection(self.AntiRagdollConnection)
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
    if self.FlyVelocity then
        safeDestroy(self.FlyVelocity)
        self.FlyVelocity = nil
    end

    local root = BloodyBlox:GetHRP()
    if root then
        local velocity = root:FindFirstChild("BloodyBloxFlyVelocity")
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

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "BloodyBloxFlyVelocity"
    velocity.MaxForce = Vector3.new(100000, 100000, 100000)
    velocity.Velocity = Vector3.zero
    velocity.Parent = root

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

        local speed = BloodyBlox.Settings.FlySpeed * 50
        self.FlyVelocity.Velocity = direction * speed
    end)
    BloodyBlox:AddConnection(self.FlyConnection)
end

function PlayerTools:ToggleInfiniteJump(enabled)
    BloodyBlox.Settings.InfiniteJump = enabled
end

function PlayerTools:ToggleGodMode(enabled)
    BloodyBlox.Settings.GodMode = enabled

    if self.GodModeConnection then
        safeDisconnect(self.GodModeConnection)
        self.GodModeConnection = nil
    end
    if self.GodModeCharacterConnection then
        safeDisconnect(self.GodModeCharacterConnection)
        self.GodModeCharacterConnection = nil
    end

    if not enabled then
        BloodyBlox:Log("Player", "God Mode disabled", "info")
        return
    end

    local function setupGodMode()
        local humanoid = BloodyBlox:GetHumanoid()
        if not humanoid then
            return false
        end

        local maxHealth = humanoid.MaxHealth
        if maxHealth <= 0 then
            maxHealth = 100
        end

        self.GodModeConnection = RunService.RenderStepped:Connect(function()
            if not BloodyBlox.Settings.GodMode then
                return
            end
            local currentHumanoid = BloodyBlox:GetHumanoid()
            if currentHumanoid and currentHumanoid.Health > 0 then
                currentHumanoid.Health = currentHumanoid.MaxHealth
            end
        end)
        BloodyBlox:AddConnection(self.GodModeConnection)

        BloodyBlox:Log("Player", "God Mode active (client-side only)", "warn")
        return true
    end

    if not setupGodMode() then
        BloodyBlox:Log("Player", "God Mode: Humanoid unavailable", "error")
        return
    end

    self.GodModeCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if BloodyBlox.Settings.GodMode then
            setupGodMode()
        end
    end)
    BloodyBlox:AddConnection(self.GodModeCharacterConnection)
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
        return false
    end

    if hasFolderAPI() and not isfolder("BloodyBlox") then
        pcall(function()
            makefolder("BloodyBlox")
        end)
    end

    local ok, json = safeJsonEncode(BloodyBlox.TeleportPoints)
    if not ok then
        return false
    end

    local saved, err = pcall(function()
        writefile(self:GetPath(), json)
    end)
    return saved
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
        return false
    end

    BloodyBlox.TeleportPoints = data
    return true
end

function Teleport:Add(name)
    local root = BloodyBlox:GetHRP()
    if not root then
        return false
    end

    table.insert(BloodyBlox.TeleportPoints, {
        name = tostring(name or ("Point_" .. (#BloodyBlox.TeleportPoints + 1))),
        x = root.Position.X,
        y = root.Position.Y,
        z = root.Position.Z,
    })

    self:Save()
    BloodyBlox:Log("Teleport", "Point saved: " .. tostring(name), "info")
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
        return false
    end

    name = self:SanitizeName(name)
    if name == "" then
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
        return false
    end

    local saved, err = pcall(function()
        writefile("BloodyBlox_" .. name .. ".json", json)
    end)

    if saved then
        BloodyBlox:Log("Config", "Saved: " .. name, "info")
    end
    return saved
end

function Config:Load(name)
    if not hasFilesystem() then
        return false
    end

    name = self:SanitizeName(name)
    if name == "" then
        return false
    end

    local path = "BloodyBlox_" .. name .. ".json"
    if not isfile(path) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not ok or type(data) ~= "table" then
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
        return false
    end

    name = self:SanitizeName(name)
    local path = "BloodyBlox_" .. name .. ".json"
    if not isfile(path) then
        return false
    end

    local ok, err = pcall(function()
        delfile(path)
    end)
    if ok then
        BloodyBlox:Log("Config", "Deleted: " .. name, "warn")
    end
    return ok
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

function UI:UpdateScale(scale)
    if self.Main then
        local baseWidth = 760
        local baseHeight = 540
        local newWidth = baseWidth * scale
        local newHeight = baseHeight * scale

        self.Main.Size = UDim2.fromOffset(newWidth, newHeight)
        self.Main.Position = UDim2.new(0.5, -newWidth / 2, 0.5, -newHeight / 2)
    end
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

    -- Watermark
    self.Watermark = create("Frame", {
        Size = UDim2.fromOffset(200, 60),
        Position = UDim2.new(1, -210, 1, -230),
        BackgroundColor3 = Color3.fromRGB(10, 10, 15),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Active = false,
        Draggable = false,
    }, self.Gui)
    create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.Watermark)

    local watermarkLabel = create("TextLabel", {
        Size = UDim2.new(1, -16, 1, -10),
        Position = UDim2.fromOffset(8, 5),
        BackgroundTransparency = 1,
        Text = "BloodyBlox v" .. BloodyBlox.Version .. "\nFPS: 0",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, self.Watermark)

    self.Watermark.Visible = BloodyBlox.Settings.ShowWatermark
    BloodyBlox.State.WatermarkLabel = watermarkLabel
    BloodyBlox.State.UI = self

    -- FPS counter
    local lastTime = os.clock()
    local frameCount = 0
    local fps = 0

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()
        if currentTime - lastTime >= 1 then
            fps = frameCount
            frameCount = 0
            lastTime = currentTime

            if watermarkLabel and BloodyBlox.Settings.ShowWatermark then
                watermarkLabel.Text = string.format("BloodyBlox v%s\nFPS: %d", BloodyBlox.Version, fps)
            end
        end
    end)

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

function UI:AddSlider(tab, text, min, max, default, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
        BorderSizePixel = 0,
    }, tab.Page)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)

    local label = create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.fromOffset(5, 3),
        BackgroundTransparency = 1,
        Text = string.format("%s: %.2f", text, default),
        TextColor3 = Color3.fromRGB(225, 225, 225),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local sliderBg = create("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 1, -15),
        BackgroundColor3 = Color3.fromRGB(60, 60, 65),
        BorderSizePixel = 0,
    }, frame)
    create("UICorner", {CornerRadius = UDim.new(0, 4)}, sliderBg)

    local value = default
    local sliderFill = create("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(139, 0, 0),
        BorderSizePixel = 0,
    }, sliderBg)
    create("UICorner", {CornerRadius = UDim.new(0, 4)}, sliderFill)

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = UserInputService:GetMouseLocation()
            local relativeX = mouse.X - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            value = min + (max - min) * percent
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            label.Text = string.format("%s: %.2f", text, value)
            callback(value)
        end
    end)

    return frame
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
    self.Watermark = nil
end

--============================================================
-- Build UI
--============================================================

UI:Create()
Teleport:Load()
Analyzer:LoadProfiles()
Analyzer:InstallHook()

local FarmTab = UI:AddTab("Farm")
UI:AddToggle(FarmTab, "Weight Farm", false, function(state)
    BloodyBlox.Settings.WeightFarm = state
    if state then
        Farm:Start("Weight", BloodyBlox.Settings.WeightInterval, "Weight")
    else
        Farm:Stop("Weight")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(FarmTab, "Weight interval", 0.25, function(value)
    BloodyBlox.Settings.WeightInterval = math.max(0.05, value)
    BloodyBlox:SaveConfig()
end)

UI:AddToggle(FarmTab, "Durability Farm", false, function(state)
    BloodyBlox.Settings.DurabilityFarm = state
    if state then
        Farm:Start("Durability", BloodyBlox.Settings.DurabilityInterval, "Durability")
    else
        Farm:Stop("Durability")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(FarmTab, "Durability interval", 0.25, function(value)
    BloodyBlox.Settings.DurabilityInterval = math.max(0.05, value)
    BloodyBlox:SaveConfig()
end)

UI:AddToggle(FarmTab, "Auto Rebirth", false, function(state)
    BloodyBlox.Settings.AutoRebirth = state
    if state then
        Farm:Start("Rebirth", BloodyBlox.Settings.RebirthInterval, "Rebirth")
    else
        Farm:Stop("Rebirth")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(FarmTab, "Rebirth interval", 2, function(value)
    BloodyBlox.Settings.RebirthInterval = math.max(0.1, value)
    BloodyBlox:SaveConfig()
end)

UI:AddToggle(FarmTab, "Combat Farm", false, function(state)
    BloodyBlox.Settings.CombatFarm = state
    if state then
        Farm:Start("Combat", BloodyBlox.Settings.CombatInterval, "Combat")
    else
        Farm:Stop("Combat")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(FarmTab, "Combat interval", 0.25, function(value)
    BloodyBlox.Settings.CombatInterval = math.max(0.05, value)
    BloodyBlox:SaveConfig()
end)

UI:AddToggle(FarmTab, "Bad Aura Farm", false, function(state)
    BloodyBlox.Settings.BadAuraFarm = state
    if state then
        Farm:StartBadAura()
    else
        Farm:Stop("BadAura")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(FarmTab, "Bad Aura interval", 0.1, function(value)
    BloodyBlox.Settings.BadAuraInterval = math.max(0.05, value)
    BloodyBlox:SaveConfig()
end)

local CombatTab = UI:AddTab("Combat")
UI:AddToggle(CombatTab, "Anti-Aim", false, function(state)
    Combat:ToggleAntiAim(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(CombatTab, "Kill Aura", false, function(state)
    Combat:ToggleKillAura(state)
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(CombatTab, "Kill Aura Radius", 20, function(value)
    BloodyBlox.Settings.KillAuraRadius = math.max(5, value)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(CombatTab, "Fast Hits", false, function(state)
    Combat:ToggleFastHits(state)
    BloodyBlox:SaveConfig()
end)

local AnalyzerTab = UI:AddTab("Analyzer")
UI:AddToggle(AnalyzerTab, "Remote Spy (Log ALL remotes)", false, function(state)
    BloodyBlox.Settings.RemoteSpyEnabled = state
    if state then
        Analyzer:InstallHook()
        BloodyBlox:Log("RemoteSpy", "Continuous logging enabled", "warn")
    else
        BloodyBlox:Log("RemoteSpy", "Continuous logging disabled", "info")
    end
    BloodyBlox:SaveConfig()
end)
UI:AddLabel(AnalyzerTab, "Capture: perform action manually. Next client remote call becomes the profile.")
UI:AddButton(AnalyzerTab, "Scan Remotes", function()
    Analyzer:ScanRemotes()
end)
UI:AddButton(AnalyzerTab, "Scan NPCs", function()
    Analyzer:ScanNPCs()
end)
UI:AddButton(AnalyzerTab, "Scan Tools", function()
    Analyzer:ScanTools()
end)
UI:AddButton(AnalyzerTab, "Dump Character Offsets", function()
    Analyzer:DumpOffsets()
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

local MiscTab = UI:AddTab("Misc")
UI:AddToggle(MiscTab, "Walk With Dumbbell", false, function(state)
    Misc:ToggleWalkWithDumbbell(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(MiscTab, "Fast Strafe", false, function(state)
    Misc:ToggleFastStrafe(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(MiscTab, "Anti Ragdoll", false, function(state)
    Misc:ToggleAntiRagdoll(state)
    BloodyBlox:SaveConfig()
end)

local VisualTab = UI:AddTab("Visual")
UI:AddToggle(VisualTab, "ESP", false, function(state)
    ESP:Toggle(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Boxes", true, function(state)
    BloodyBlox.Settings.ESPBoxes = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Names", true, function(state)
    BloodyBlox.Settings.ESPNames = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Distance", true, function(state)
    BloodyBlox.Settings.ESPDistance = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Health", true, function(state)
    BloodyBlox.Settings.ESPHealth = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Tracers", false, function(state)
    BloodyBlox.Settings.ESPTracers = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Team Check", false, function(state)
    BloodyBlox.Settings.ESPTeamCheck = state
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(VisualTab, "Fullbright", false, function(state)
    PlayerTools:ToggleFullbright(state)
    BloodyBlox:SaveConfig()
end)

local PlayerTab = UI:AddTab("Player")
UI:AddToggle(PlayerTab, "Fly", false, function(state)
    PlayerTools:ToggleFly(state)
    BloodyBlox:SaveConfig()
end)
UI:AddNumberBox(PlayerTab, "Fly speed", 5, function(value)
    BloodyBlox.Settings.FlySpeed = math.clamp(value, 1, 16)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(PlayerTab, "Noclip", false, function(state)
    PlayerTools:ToggleNoclip(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(PlayerTab, "Infinite Jump", false, function(state)
    PlayerTools:ToggleInfiniteJump(state)
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(PlayerTab, "God Mode (Client-Side)", false, function(state)
    PlayerTools:ToggleGodMode(state)
    BloodyBlox:SaveConfig()
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
    BloodyBlox:Log("Teleport", "Reloaded saved points", "info")
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

local SettingsTab = UI:AddTab("Settings")
UI:AddToggle(SettingsTab, "Show Watermark", true, function(state)
    BloodyBlox.Settings.ShowWatermark = state
    if UI.Watermark then
        UI.Watermark.Visible = state
    end
    BloodyBlox:SaveConfig()
end)
UI:AddToggle(SettingsTab, "Move Watermark", false, function(state)
    BloodyBlox.Settings.WatermarkDraggable = state
    if UI.Watermark then
        UI.Watermark.Active = state
        UI.Watermark.Draggable = state
    end
    BloodyBlox:SaveConfig()
end)
UI:AddTextBox(SettingsTab, "Menu Scale (0.5-3.0)", function(text)
    local value = tonumber(text)
    if value and value >= 0.5 and value <= 3.0 then
        BloodyBlox.Settings.MenuScale = value
        UI:UpdateScale(value)
        BloodyBlox:SaveConfig()
    end
end)
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
    BloodyBlox.Settings.BadAuraFarm = false
    BloodyBlox.Settings.AntiAim = false
    BloodyBlox.Settings.KillAura = false
    BloodyBlox.Settings.FastHits = false
    BloodyBlox.Settings.WalkWithDumbbell = false
    BloodyBlox.Settings.FastStrafe = false

    Farm:Stop("Weight")
    Farm:Stop("Durability")
    Farm:Stop("Rebirth")
    Farm:Stop("Combat")
    Farm:Stop("BadAura")

    Combat:ToggleAntiAim(false)
    Combat:ToggleKillAura(false)
    Combat:ToggleFastHits(false)

    Misc:ToggleWalkWithDumbbell(false)
    Misc:ToggleFastStrafe(false)

    ESP:Toggle(false)
    PlayerTools:ToggleFly(false)
    PlayerTools:ToggleNoclip(false)
    PlayerTools:ToggleFullbright(false)

    BloodyBlox:SaveConfig()
end)
UI:AddButton(SettingsTab, "EXIT", function()
    BloodyBlox.MenuOpen = false

    Farm:Stop("Weight")
    Farm:Stop("Durability")
    Farm:Stop("Rebirth")
    Farm:Stop("Combat")
    Farm:Stop("BadAura")

    Combat:ToggleAntiAim(false)
    Combat:ToggleKillAura(false)
    Combat:ToggleFastHits(false)

    Misc:ToggleWalkWithDumbbell(false)
    Misc:ToggleFastStrafe(false)

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
-- Runtime (Anti-AFK hidden but active)
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

-- Anti-AFK (always active, no UI toggle)
BloodyBlox:AddConnection(LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
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
