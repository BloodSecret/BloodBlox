--[[
    BloodyBlox v0.2.1 - Muscle Legends Advanced Exploit
    CRITICAL BUGFIXES - Crash fix, performance optimization, correct implementations
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()

    CHANGELOG v0.2.1:
    - FIXED: Game crash on exit (proper cleanup system)
    - FIXED: KillAura lag (1 FPS -> optimized with cooldown)
    - FIXED: Fast Weight now only accelerates, doesn't auto-lift
    - FIXED: Walk On Water platform collision
    - FIXED: Teleport Tool now saves points correctly
    - FIXED: Config save/load system working
    - FIXED: Auto/Fast Rebirth remote finding
    - FIXED: Analyzer results now save to Logs tab
    - REMOVED: Infinity Yield (unclear/broken feature)
    - NOTE: God Mode/Fast Hits/-999T may not work (server-side protection)
]]

if _G.BloodyBloxLoaded then
    warn("[BloodyBlox] Already running!")
    return
end
_G.BloodyBloxLoaded = true

-- ============ ADVANCED BYPASS SYSTEM ============

local function AdvancedBypass()
    pcall(function()
        local traces = {"syn", "Synapse", "KRNL_LOADED", "SENTINEL_LOADED", "SCRIPTWARE_LOADED", "exploit", "executor"}
        for _, trace in ipairs(traces) do
            _G[trace] = nil
            if getgenv then getgenv()[trace] = nil end
        end

        if getgc then
            for _, obj in pairs(getgc(true)) do
                if type(obj) == "table" then
                    if rawget(obj, "Detected") then rawset(obj, "Detected", false) end
                    if rawget(obj, "AntiCheat") then rawset(obj, "AntiCheat", nil) end
                end
            end
        end
    end)
end

AdvancedBypass()
pcall(function() setfpscap(999) end)
task.wait(0.3)

-- ============ SERVICES ============

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

-- ============ CORE FRAMEWORK ============

local BloodyBlox = {
    Version = "0.2.1",
    MenuOpen = false,
    Player = Players.LocalPlayer,
    Settings = {
        -- Farm
        FastWeight = false,
        AutoWeight = false,

        -- Rebirth
        AutoRebirth = false,
        FastRebirth = false,

        -- Player
        Fly = false,
        FlySpeed = 5,
        Noclip = false,
        WalkOnWater = false,
        GodMode = false,

        -- Visual
        ESP = false,
        ESPBoxes = true,
        ESPNames = true,
        ESPDistance = true,
        ESPHealth = true,
        ESPTracers = false,
        ESPTeamCheck = false,
        Fullbright = false,

        -- Combat
        AntiAim = false,
        KillAura = false,
        KillAuraRange = 50,
        FastHits = false,
        FastHitsTarget = nil,
        MegaDamage = false,

        -- Experimental
        FastTime = false,
        FastTimeMultiplier = 2,

        -- Analyzer
        AnalyzerActive = false,
        LogRemotes = false,
        DumpOffsets = false,

        Debug = false
    },
    Logs = {},
    Connections = {},
    TeleportPoints = {},
    ESPObjects = {},
    AnalyzerData = {
        Remotes = {},
        Offsets = {},
        GameStructure = {}
    }
}

-- Auto Anti-AFK
BloodyBlox.Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============ LOGGING SYSTEM ============

function BloodyBlox:Log(category, message, level)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = {
        time = timestamp,
        category = category,
        message = message,
        level = level or "info"
    }
    table.insert(self.Logs, logEntry)
    if #self.Logs > 200 then table.remove(self.Logs, 1) end
    print(string.format("[%s][%s] %s", timestamp, category, message))
end

-- ============ UTILITY FUNCTIONS ============

function BloodyBlox:GetCharacter()
    return self.Player.Character or self.Player.CharacterAdded:Wait()
end

function BloodyBlox:GetHumanoid()
    local char = self:GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function BloodyBlox:GetHumanoidRootPart()
    local char = self:GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============ SAFE CLEANUP SYSTEM (FIXED - prevents crash) ============

function BloodyBlox:SafeCleanup()
    self:Log("System", "Starting safe cleanup...", "warn")

    -- Disable all toggles first
    for key, value in pairs(self.Settings) do
        if type(value) == "boolean" then
            self.Settings[key] = false
        end
    end

    -- Wait for settings to propagate
    task.wait(0.2)

    -- Disconnect all connections safely
    for i, conn in ipairs(self.Connections) do
        pcall(function()
            if conn and typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end)
    end
    self.Connections = {}

    -- Clean ESP objects
    for _, espObj in ipairs(self.ESPObjects) do
        pcall(function()
            if espObj.Box then espObj.Box:Remove() end
            if espObj.Name then espObj.Name:Remove() end
            if espObj.Distance then espObj.Distance:Remove() end
            if espObj.HealthBar then espObj.HealthBar:Remove() end
            if espObj.HealthBarOutline then espObj.HealthBarOutline:Remove() end
            if espObj.Tracer then espObj.Tracer:Remove() end
        end)
    end
    self.ESPObjects = {}

    -- Clean character modifications
    local char = self:GetCharacter()
    if char then
        pcall(function()
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
                if obj:IsA("ForceField") then
                    obj:Destroy()
                end
            end

            -- Restore collisions
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end)
    end

    -- Clean workspace modifications
    pcall(function()
        local platform = Workspace:FindFirstChild("WaterPlatform")
        if platform then platform:Destroy() end
    end)

    self:Log("System", "Cleanup complete", "info")
end

-- ============ CONFIG SYSTEM ============

function BloodyBlox:SaveTeleportPoints()
    pcall(function()
        if writefile then
            local success = writefile("BloodyBlox_TeleportPoints.json", HttpService:JSONEncode(self.TeleportPoints))
            if success ~= false then
                self:Log("Config", "Teleport points saved", "info")
            end
        end
    end)
end

function BloodyBlox:LoadTeleportPoints()
    pcall(function()
        if isfile and isfile("BloodyBlox_TeleportPoints.json") then
            local data = readfile("BloodyBlox_TeleportPoints.json")
            self.TeleportPoints = HttpService:JSONDecode(data)
            self:Log("Config", "Loaded " .. #self.TeleportPoints .. " points", "info")
        end
    end)
end

-- ============ ANALYZER SYSTEM (FIXED - saves to logs) ============

local Analyzer = {}

function Analyzer:Start()
    BloodyBlox:Log("Analyzer", "=== ANALYSIS START ===", "warn")

    if BloodyBlox.Settings.LogRemotes then
        self:LogAllRemotes()
    end

    if BloodyBlox.Settings.DumpOffsets then
        self:DumpOffsets()
    end

    self:AnalyzeGameStructure()
    BloodyBlox:Log("Analyzer", "=== ANALYSIS COMPLETE ===", "warn")
end

function Analyzer:LogAllRemotes()
    BloodyBlox:Log("Analyzer", "--- REMOTE EVENTS SCAN ---", "warn")

    local remoteCount = 0
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            remoteCount = remoteCount + 1
            local path = obj:GetFullName()
            BloodyBlox:Log("Analyzer", string.format("[%d] %s (%s)", remoteCount, obj.Name, obj.ClassName), "info")

            table.insert(BloodyBlox.AnalyzerData.Remotes, {
                Name = obj.Name,
                Type = obj.ClassName,
                Path = path
            })
        end
    end

    BloodyBlox:Log("Analyzer", "Total remotes: " .. remoteCount, "warn")
end

function Analyzer:DumpOffsets()
    BloodyBlox:Log("Analyzer", "--- OFFSET DUMP ---", "warn")

    local player = BloodyBlox.Player
    local char = BloodyBlox:GetCharacter()

    -- Player Stats Offsets
    if player:FindFirstChild("leaderstats") then
        BloodyBlox:Log("Analyzer", "LEADERSTATS:", "info")
        for _, stat in pairs(player.leaderstats:GetChildren()) do
            BloodyBlox:Log("Analyzer", "  " .. stat.Name .. " = " .. tostring(stat.Value), "info")
        end
    end

    if player:FindFirstChild("PlayerStats") or player:FindFirstChild("Stats") then
        local stats = player:FindFirstChild("PlayerStats") or player:FindFirstChild("Stats")
        BloodyBlox:Log("Analyzer", "PLAYER STATS:", "info")
        for _, stat in pairs(stats:GetChildren()) do
            BloodyBlox:Log("Analyzer", "  " .. stat.Name .. " = " .. tostring(stat.Value), "info")
        end
    end

    -- Tool Analysis
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        BloodyBlox:Log("Analyzer", "TOOL: " .. tool.Name, "info")
        for _, obj in pairs(tool:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                BloodyBlox:Log("Analyzer", "  Remote: " .. obj.Name, "info")
            end
        end
    end

    -- Workspace Analysis
    BloodyBlox:Log("Analyzer", "WORKSPACE SCAN:", "info")
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Tool") or obj.Name:lower():find("weight") or obj.Name:lower():find("dumbbell") then
            BloodyBlox:Log("Analyzer", "  " .. obj.Name .. " (" .. obj.ClassName .. ")", "info")
        end
    end
end

function Analyzer:AnalyzeGameStructure()
    BloodyBlox:Log("Analyzer", "--- GAME STRUCTURE ---", "warn")

    -- PlayerGui Analysis
    local playerGui = BloodyBlox.Player:FindFirstChild("PlayerGui")
    if playerGui then
        BloodyBlox:Log("Analyzer", "GUI COUNT: " .. #playerGui:GetChildren(), "info")
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                BloodyBlox:Log("Analyzer", "  GUI: " .. gui.Name, "info")
            end
        end
    end

    -- ReplicatedStorage Structure
    BloodyBlox:Log("Analyzer", "REPLICATED STORAGE:", "info")
    for _, obj in pairs(ReplicatedStorage:GetChildren()) do
        BloodyBlox:Log("Analyzer", "  " .. obj.Name .. " (" .. obj.ClassName .. ")", "info")
    end
end

-- ============ MUSCLE LEGENDS MODULE ============

local MuscleLegends = {}

function MuscleLegends:GetWeightTool()
    local char = BloodyBlox:GetCharacter()
    if not char then return nil end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end

    local backpack = BloodyBlox.Player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("weight") or item.Name:lower():find("dumbbell")) then
                return item
            end
        end
    end
    return nil
end

function MuscleLegends:EquipWeight()
    local tool = self:GetWeightTool()
    if tool and tool.Parent ~= BloodyBlox:GetCharacter() then
        local humanoid = BloodyBlox:GetHumanoid()
        if humanoid then
            humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end

function MuscleLegends:FireAllWeightRemotes()
    local tool = self:GetWeightTool()
    if not tool or tool.Parent ~= BloodyBlox:GetCharacter() then return end

    for _, remote in pairs(tool:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            pcall(function()
                remote:FireServer()
                remote:FireServer("lift")
                remote:FireServer("rep")
                remote:FireServer("workout")
                remote:FireServer(true)
                remote:FireServer(1)
            end)
        elseif remote:IsA("RemoteFunction") then
            pcall(function()
                remote:InvokeServer()
                remote:InvokeServer("lift")
                remote:InvokeServer("rep")
            end)
        end
    end
end

function MuscleLegends:TriggerRebirth()
    BloodyBlox:Log("Rebirth", "Attempting rebirth...", "info")

    -- Method 1: ReplicatedStorage remotes
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("rebirth") or name:find("prestige") or name:find("reset") or name:find("reborn") then
                BloodyBlox:Log("Rebirth", "Found remote: " .. obj.Name, "info")
                if obj:IsA("RemoteEvent") then
                    pcall(function()
                        obj:FireServer()
                        obj:FireServer("rebirth")
                        obj:FireServer(true)
                        obj:FireServer(1)
                    end)
                else
                    pcall(function()
                        obj:InvokeServer()
                        obj:InvokeServer("rebirth")
                    end)
                end
            end
        end
    end

    -- Method 2: PlayerGui buttons
    local playerGui = BloodyBlox.Player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("TextButton") then
                local text = gui.Text:lower()
                if text:find("rebirth") or text:find("prestige") or text:find("reborn") then
                    BloodyBlox:Log("Rebirth", "Found button: " .. gui.Text, "info")
                    for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                        pcall(function() connection:Fire() end)
                    end
                end
            end
        end
    end
end

-- ============ FARM SYSTEM (FIXED - no auto lifting, only acceleration) ============

local Farm = {}

function Farm:ToggleFastWeight(enabled)
    if self.FastWeightLoop then
        self.FastWeightLoop:Disconnect()
        self.FastWeightLoop = nil
    end

    if enabled then
        BloodyBlox:Log("Farm", "Fast Weight: ON (acceleration only)", "info")

        -- NO AUTO LIFTING - only remove delays
        self.FastWeightLoop = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.FastWeight then return end

            pcall(function()
                -- Just fire remotes without auto-clicking
                MuscleLegends:FireAllWeightRemotes()
            end)
        end)

        table.insert(BloodyBlox.Connections, self.FastWeightLoop)
    else
        BloodyBlox:Log("Farm", "Fast Weight: OFF", "info")
    end
end

function Farm:ToggleAutoWeight(enabled)
    if self.AutoWeightTask then
        pcall(function() task.cancel(self.AutoWeightTask) end)
        self.AutoWeightTask = nil
    end

    if enabled then
        BloodyBlox:Log("Farm", "Auto Weight: ON", "info")

        self.AutoWeightTask = task.spawn(function()
            while BloodyBlox.Settings.AutoWeight do
                task.wait(0.5)

                pcall(function()
                    local tool = MuscleLegends:GetWeightTool()

                    if not tool then
                        -- Search workspace for weights
                        for _, obj in pairs(Workspace:GetDescendants()) do
                            if obj:IsA("Tool") and (obj.Name:lower():find("weight") or obj.Name:lower():find("dumbbell")) then
                                local hrp = BloodyBlox:GetHumanoidRootPart()
                                if hrp and obj:FindFirstChild("Handle") then
                                    local distance = (hrp.Position - obj.Handle.Position).Magnitude
                                    if distance < 150 then
                                        hrp.CFrame = obj.Handle.CFrame
                                        task.wait(0.2)
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if not tool or tool.Parent ~= BloodyBlox:GetCharacter() then
                        MuscleLegends:EquipWeight()
                        task.wait(0.3)
                    end

                    MuscleLegends:FireAllWeightRemotes()

                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end)
            end
        end)
    else
        BloodyBlox:Log("Farm", "Auto Weight: OFF", "info")
    end
end

-- ============ REBIRTH SYSTEM (FIXED) ============

local Rebirth = {}

function Rebirth:ToggleAutoRebirth(enabled)
    if self.AutoRebirthTask then
        pcall(function() task.cancel(self.AutoRebirthTask) end)
        self.AutoRebirthTask = nil
    end

    if enabled then
        BloodyBlox:Log("Rebirth", "Auto Rebirth: ON", "info")

        self.AutoRebirthTask = task.spawn(function()
            while BloodyBlox.Settings.AutoRebirth do
                task.wait(5)
                pcall(function()
                    MuscleLegends:TriggerRebirth()
                end)
            end
        end)
    else
        BloodyBlox:Log("Rebirth", "Auto Rebirth: OFF", "info")
    end
end

function Rebirth:ToggleFastRebirth(enabled)
    if self.FastRebirthConnection then
        self.FastRebirthConnection:Disconnect()
        self.FastRebirthConnection = nil
    end

    if enabled then
        BloodyBlox:Log("Rebirth", "Fast Rebirth: ON", "info")

        self.FastRebirthConnection = BloodyBlox.Player.CharacterAdded:Connect(function(char)
            if BloodyBlox.Settings.FastRebirth then
                task.wait(0.1)
                local hrp = char:WaitForChild("HumanoidRootPart", 3)
                if hrp then
                    -- Skip spawn animation by teleporting up and back
                    local originalCF = hrp.CFrame
                    hrp.Anchored = true
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 500, 0)
                    task.wait(0.05)
                    hrp.CFrame = originalCF
                    task.wait(0.05)
                    hrp.Anchored = false
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.FastRebirthConnection)
    else
        BloodyBlox:Log("Rebirth", "Fast Rebirth: OFF", "info")
    end
end

function Rebirth:RebirthNow()
    MuscleLegends:TriggerRebirth()
end

-- ============ PLAYER SYSTEM ============

local Player = {}

function Player:ToggleFly(enabled)
    if self.FlyConnection then
        self.FlyConnection:Disconnect()
        self.FlyConnection = nil
    end

    if self.BodyVelocity then
        self.BodyVelocity:Destroy()
        self.BodyVelocity = nil
    end

    if enabled then
        local hrp = BloodyBlox:GetHumanoidRootPart()
        if not hrp then return end

        self.BodyVelocity = Instance.new("BodyVelocity")
        self.BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        self.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        self.BodyVelocity.Parent = hrp

        self.FlyConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.Fly then
                if self.FlyConnection then
                    self.FlyConnection:Disconnect()
                    self.FlyConnection = nil
                end
                if self.BodyVelocity then
                    self.BodyVelocity:Destroy()
                    self.BodyVelocity = nil
                end
                return
            end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if hrp and self.BodyVelocity then
                local camera = Workspace.CurrentCamera
                local moveDirection = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end

                local speed = BloodyBlox.Settings.FlySpeed * 50
                self.BodyVelocity.Velocity = moveDirection * speed
            end
        end)

        table.insert(BloodyBlox.Connections, self.FlyConnection)
        BloodyBlox:Log("Player", "Fly: ON (Speed: " .. BloodyBlox.Settings.FlySpeed * 50 .. ")", "info")
    else
        BloodyBlox:Log("Player", "Fly: OFF", "info")
    end
end

function Player:ToggleNoclip(enabled)
    if self.NoclipConnection then
        self.NoclipConnection:Disconnect()
        self.NoclipConnection = nil
    end

    if enabled then
        self.NoclipConnection = RunService.Stepped:Connect(function()
            if not BloodyBlox.Settings.Noclip then return end

            local char = BloodyBlox:GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.NoclipConnection)
        BloodyBlox:Log("Player", "Noclip: ON", "info")
    else
        local char = BloodyBlox:GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        BloodyBlox:Log("Player", "Noclip: OFF", "info")
    end
end

function Player:ToggleWalkOnWater(enabled)
    if self.WalkOnWaterConnection then
        self.WalkOnWaterConnection:Disconnect()
        self.WalkOnWaterConnection = nil
    end

    if self.WaterPlatform then
        self.WaterPlatform:Destroy()
        self.WaterPlatform = nil
    end

    if enabled then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if not terrain then
            BloodyBlox:Log("Player", "Terrain not found", "error")
            return
        end

        self.WaterPlatform = Instance.new("Part")
        self.WaterPlatform.Name = "WaterPlatform"
        self.WaterPlatform.Size = Vector3.new(12, 1, 12)
        self.WaterPlatform.Transparency = 1
        self.WaterPlatform.CanCollide = true
        self.WaterPlatform.Anchored = true
        self.WaterPlatform.Material = Enum.Material.SmoothPlastic
        self.WaterPlatform.Parent = Workspace

        self.WalkOnWaterConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.WalkOnWater then return end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if hrp and self.WaterPlatform then
                local position = hrp.Position
                local region = Region3.new(position - Vector3.new(4, 4, 4), position + Vector3.new(4, 4, 4))
                region = region:ExpandToGrid(4)

                local success, materials, sizes = pcall(function()
                    return terrain:ReadVoxels(region, 4)
                end)

                if success and materials then
                    local size = materials.Size
                    local hasWater = false

                    for x = 1, size.X do
                        for y = 1, size.Y do
                            for z = 1, size.Z do
                                if materials[x][y][z] == Enum.Material.Water then
                                    hasWater = true
                                    break
                                end
                            end
                            if hasWater then break end
                        end
                        if hasWater then break end
                    end

                    if hasWater then
                        self.WaterPlatform.CFrame = CFrame.new(position.X, position.Y - 3.5, position.Z)
                        self.WaterPlatform.CanCollide = true
                    else
                        self.WaterPlatform.CFrame = CFrame.new(position.X, position.Y - 1000, position.Z)
                    end
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.WalkOnWaterConnection)
        BloodyBlox:Log("Player", "Walk On Water: ON", "info")
    else
        BloodyBlox:Log("Player", "Walk On Water: OFF", "info")
    end
end

function Player:ToggleGodMode(enabled)
    if self.GodModeConnection then
        self.GodModeConnection:Disconnect()
        self.GodModeConnection = nil
    end

    if enabled then
        local humanoid = BloodyBlox:GetHumanoid()
        local char = BloodyBlox:GetCharacter()

        if not humanoid or not char then return end

        -- Constant health restoration (only method that might work)
        self.GodModeConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.GodMode then return end

            local hum = BloodyBlox:GetHumanoid()
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)

        table.insert(BloodyBlox.Connections, self.GodModeConnection)
        BloodyBlox:Log("Player", "God Mode: ON (health restoration)", "warn")
        BloodyBlox:Log("Player", "NOTE: Server-side damage may still work", "warn")
    else
        BloodyBlox:Log("Player", "God Mode: OFF", "info")
    end
end

function Player:ToggleAntiAim(enabled)
    if self.AntiAimConnection then
        self.AntiAimConnection:Disconnect()
        self.AntiAimConnection = nil
    end

    if enabled then
        self.AntiAimConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.AntiAim then return end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(45), 0)
            end
        end)

        table.insert(BloodyBlox.Connections, self.AntiAimConnection)
        BloodyBlox:Log("Player", "AntiAim: ON", "info")
    else
        BloodyBlox:Log("Player", "AntiAim: OFF", "info")
    end
end

-- ============ ESP SYSTEM ============

local ESP = {}

function ESP:CreateESP(player)
    if player == BloodyBlox.Player then return end

    local espObjects = {
        Player = player,
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        HealthBarOutline = Drawing.new("Line"),
        Tracer = Drawing.new("Line")
    }

    espObjects.Box.Thickness = 2
    espObjects.Box.Filled = false
    espObjects.Box.Color = Color3.fromRGB(255, 255, 255)
    espObjects.Box.Visible = false
    espObjects.Box.ZIndex = 2

    espObjects.Name.Size = 13
    espObjects.Name.Center = true
    espObjects.Name.Outline = true
    espObjects.Name.Color = Color3.fromRGB(255, 255, 255)
    espObjects.Name.Visible = false
    espObjects.Name.ZIndex = 2

    espObjects.Distance.Size = 12
    espObjects.Distance.Center = true
    espObjects.Distance.Outline = true
    espObjects.Distance.Color = Color3.fromRGB(200, 200, 200)
    espObjects.Distance.Visible = false
    espObjects.Distance.ZIndex = 2

    espObjects.HealthBar.Thickness = 3
    espObjects.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    espObjects.HealthBar.Visible = false
    espObjects.HealthBar.ZIndex = 2

    espObjects.HealthBarOutline.Thickness = 5
    espObjects.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    espObjects.HealthBarOutline.Visible = false
    espObjects.HealthBarOutline.ZIndex = 1

    espObjects.Tracer.Thickness = 1
    espObjects.Tracer.Color = Color3.fromRGB(255, 255, 255)
    espObjects.Tracer.Visible = false
    espObjects.Tracer.ZIndex = 2

    table.insert(BloodyBlox.ESPObjects, espObjects)
end

function ESP:RemoveESP(player)
    for i, espObj in ipairs(BloodyBlox.ESPObjects) do
        if espObj.Player == player then
            espObj.Box:Remove()
            espObj.Name:Remove()
            espObj.Distance:Remove()
            espObj.HealthBar:Remove()
            espObj.HealthBarOutline:Remove()
            espObj.Tracer:Remove()
            table.remove(BloodyBlox.ESPObjects, i)
            break
        end
    end
end

function ESP:UpdateESP()
    local camera = Workspace.CurrentCamera
    local localPlayer = BloodyBlox.Player

    for _, espObj in ipairs(BloodyBlox.ESPObjects) do
        local player = espObj.Player

        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head")

            if BloodyBlox.Settings.ESPTeamCheck then
                if player.Team == localPlayer.Team then
                    espObj.Box.Visible = false
                    espObj.Name.Visible = false
                    espObj.Distance.Visible = false
                    espObj.HealthBar.Visible = false
                    espObj.HealthBarOutline.Visible = false
                    espObj.Tracer.Visible = false
                    continue
                end
            end

            local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)

            if onScreen and BloodyBlox.Settings.ESP then
                local hrpPos = camera:WorldToViewportPoint(hrp.Position)
                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2

                if BloodyBlox.Settings.ESPBoxes then
                    espObj.Box.Size = Vector2.new(width, height)
                    espObj.Box.Position = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
                    espObj.Box.Visible = true
                else
                    espObj.Box.Visible = false
                end

                if BloodyBlox.Settings.ESPNames then
                    espObj.Name.Text = player.Name
                    espObj.Name.Position = Vector2.new(hrpPos.X, headPos.Y - 15)
                    espObj.Name.Visible = true
                else
                    espObj.Name.Visible = false
                end

                if BloodyBlox.Settings.ESPDistance then
                    local distance = math.floor((BloodyBlox:GetHumanoidRootPart().Position - hrp.Position).Magnitude)
                    espObj.Distance.Text = tostring(distance) .. "m"
                    espObj.Distance.Position = Vector2.new(hrpPos.X, legPos.Y + 5)
                    espObj.Distance.Visible = true
                else
                    espObj.Distance.Visible = false
                end

                if BloodyBlox.Settings.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent

                    espObj.HealthBarOutline.From = Vector2.new(hrpPos.X - width / 2 - 7, hrpPos.Y - height / 2)
                    espObj.HealthBarOutline.To = Vector2.new(hrpPos.X - width / 2 - 7, hrpPos.Y + height / 2)
                    espObj.HealthBarOutline.Visible = true

                    espObj.HealthBar.From = Vector2.new(hrpPos.X - width / 2 - 7, hrpPos.Y + height / 2)
                    espObj.HealthBar.To = Vector2.new(hrpPos.X - width / 2 - 7, hrpPos.Y + height / 2 - barHeight)
                    espObj.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    espObj.HealthBar.Visible = true
                else
                    espObj.HealthBar.Visible = false
                    espObj.HealthBarOutline.Visible = false
                end

                if BloodyBlox.Settings.ESPTracers then
                    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    espObj.Tracer.From = screenCenter
                    espObj.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    espObj.Tracer.Visible = true
                else
                    espObj.Tracer.Visible = false
                end
            else
                espObj.Box.Visible = false
                espObj.Name.Visible = false
                espObj.Distance.Visible = false
                espObj.HealthBar.Visible = false
                espObj.HealthBarOutline.Visible = false
                espObj.Tracer.Visible = false
            end
        else
            espObj.Box.Visible = false
            espObj.Name.Visible = false
            espObj.Distance.Visible = false
            espObj.HealthBar.Visible = false
            espObj.HealthBarOutline.Visible = false
            espObj.Tracer.Visible = false
        end
    end
end

function ESP:Toggle(enabled)
    if enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= BloodyBlox.Player then
                self:CreateESP(player)
            end
        end

        if not self.UpdateConnection then
            self.UpdateConnection = RunService.RenderStepped:Connect(function()
                if BloodyBlox.Settings.ESP then
                    self:UpdateESP()
                end
            end)
            table.insert(BloodyBlox.Connections, self.UpdateConnection)
        end

        if not self.PlayerAddedConnection then
            self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
                if BloodyBlox.Settings.ESP then
                    self:CreateESP(player)
                end
            end)
            table.insert(BloodyBlox.Connections, self.PlayerAddedConnection)
        end

        if not self.PlayerRemovingConnection then
            self.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
                self:RemoveESP(player)
            end)
            table.insert(BloodyBlox.Connections, self.PlayerRemovingConnection)
        end

        BloodyBlox:Log("Visual", "ESP: ON", "info")
    else
        for i = #BloodyBlox.ESPObjects, 1, -1 do
            local espObj = BloodyBlox.ESPObjects[i]
            espObj.Box:Remove()
            espObj.Name:Remove()
            espObj.Distance:Remove()
            espObj.HealthBar:Remove()
            espObj.HealthBarOutline:Remove()
            espObj.Tracer:Remove()
            table.remove(BloodyBlox.ESPObjects, i)
        end
        BloodyBlox:Log("Visual", "ESP: OFF", "info")
    end
end

function ESP:ToggleFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        BloodyBlox:Log("Visual", "Fullbright: ON", "info")
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        BloodyBlox:Log("Visual", "Fullbright: OFF", "info")
    end
end

-- ============ COMBAT SYSTEM (OPTIMIZED - no more 1 FPS lag) ============

local Combat = {}

function Combat:GetPlayerList()
    local playerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= BloodyBlox.Player and player.Character then
            table.insert(playerList, player)
        end
    end
    return playerList
end

function Combat:ToggleFastHits(enabled)
    if self.FastHitsConnection then
        self.FastHitsConnection:Disconnect()
        self.FastHitsConnection = nil
    end

    if enabled and BloodyBlox.Settings.FastHitsTarget then
        BloodyBlox:Log("Combat", "Fast Hits: ON (Target: " .. BloodyBlox.Settings.FastHitsTarget.Name .. ")", "warn")

        local lastHitTime = 0
        self.FastHitsConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.FastHits or not BloodyBlox.Settings.FastHitsTarget then return end

            local currentTime = tick()
            if currentTime - lastHitTime < 0.1 then return end
            lastHitTime = currentTime

            local target = BloodyBlox.Settings.FastHitsTarget
            if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end

            local targetHRP = target.Character.HumanoidRootPart
            local hrp = BloodyBlox:GetHumanoidRootPart()

            if hrp then
                hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)

                for i = 1, 10 do
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)

                        local tool = MuscleLegends:GetWeightTool()
                        if tool and tool.Parent == BloodyBlox:GetCharacter() then
                            for _, remote in pairs(tool:GetDescendants()) do
                                if remote:IsA("RemoteEvent") then
                                    remote:FireServer("hit", target)
                                    remote:FireServer("attack", target)
                                end
                            end
                        end
                    end)
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.FastHitsConnection)
    else
        BloodyBlox:Log("Combat", "Fast Hits: OFF", "info")
    end
end

function Combat:ToggleKillAura(enabled)
    if self.KillAuraConnection then
        self.KillAuraConnection:Disconnect()
        self.KillAuraConnection = nil
    end

    if enabled then
        local lastAttackTime = 0
        local attackCooldown = 0.5

        self.KillAuraConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.KillAura then return end

            local currentTime = tick()
            if currentTime - lastAttackTime < attackCooldown then return end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if not hrp then return end

            local tool = MuscleLegends:GetWeightTool()
            if not tool or tool.Parent ~= BloodyBlox:GetCharacter() then return end

            local nearestPlayer = nil
            local nearestDistance = math.huge

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= BloodyBlox.Player and player.Character then
                    local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = player.Character:FindFirstChild("Humanoid")

                    if targetHRP and targetHumanoid and targetHumanoid.Health > 0 then
                        local distance = (hrp.Position - targetHRP.Position).Magnitude

                        if distance <= BloodyBlox.Settings.KillAuraRange and distance < nearestDistance then
                            nearestPlayer = player
                            nearestDistance = distance
                        end
                    end
                end
            end

            if nearestPlayer then
                pcall(function()
                    for _, remote in pairs(tool:GetDescendants()) do
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer("hit", nearestPlayer)
                            break
                        end
                    end
                end)

                lastAttackTime = currentTime
            end
        end)

        table.insert(BloodyBlox.Connections, self.KillAuraConnection)
        BloodyBlox:Log("Combat", "Kill Aura: ON (optimized, Range: " .. BloodyBlox.Settings.KillAuraRange .. ")", "warn")
    else
        BloodyBlox:Log("Combat", "Kill Aura: OFF", "info")
    end
end

function Combat:ToggleMegaDamage(enabled)
    if self.MegaDamageHook then
        BloodyBlox:Log("Combat", "Mega Damage already hooked", "warn")
        return
    end

    if enabled then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall

            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}

                if method == "FireServer" and self:IsA("RemoteEvent") then
                    local name = self.Name:lower()
                    if name:find("combat") or name:find("damage") or name:find("hit") or name:find("attack") then
                        for i = 1, #args do
                            if type(args[i]) == "number" then
                                args[i] = 999000000000000
                            end
                        end
                        return oldNamecall(self, unpack(args))
                    end
                end

                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)

            self.MegaDamageHook = true
            BloodyBlox:Log("Combat", "Mega Damage: HOOKED (may not work server-side)", "warn")
        end)
    end
end

-- ============ EXPERIMENTAL FEATURES ============

local Experimental = {}

function Experimental:ToggleFastTime(enabled)
    if self.FastTimeConnection then
        self.FastTimeConnection:Disconnect()
        self.FastTimeConnection = nil
    end

    if enabled then
        local multiplier = BloodyBlox.Settings.FastTimeMultiplier

        self.FastTimeConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not BloodyBlox.Settings.FastTime then return end

            pcall(function()
                Lighting.ClockTime = Lighting.ClockTime + (deltaTime * multiplier)

                if Workspace:FindFirstChild("DistributedGameTime") then
                    Workspace.DistributedGameTime = Workspace.DistributedGameTime + (deltaTime * multiplier)
                end
            end)
        end)

        table.insert(BloodyBlox.Connections, self.FastTimeConnection)
        BloodyBlox:Log("Experimental", "Fast Time: ON (x" .. multiplier .. ")", "warn")
    else
        BloodyBlox:Log("Experimental", "Fast Time: OFF", "info")
    end
end

-- ============ TELEPORT SYSTEM (FIXED) ============

local Teleport = {}

function Teleport:CreateTool()
    local tool = Instance.new("Tool")
    tool.Name = "Teleport Point Setter"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    tool.Activated:Connect(function()
        local hrp = BloodyBlox:GetHumanoidRootPart()
        if hrp then
            local pointName = "Point_" .. tostring(#BloodyBlox.TeleportPoints + 1)
            local newPoint = {Name = pointName, Position = {X = hrp.Position.X, Y = hrp.Position.Y, Z = hrp.Position.Z}}
            table.insert(BloodyBlox.TeleportPoints, newPoint)
            BloodyBlox:SaveTeleportPoints()
            BloodyBlox:Log("Teleport", "Point saved: " .. pointName, "info")
        end
    end)

    return tool
end

function Teleport:GiveTool()
    local backpack = BloodyBlox.Player:FindFirstChild("Backpack")
    if backpack then
        local existing = backpack:FindFirstChild("Teleport Point Setter")
        if existing then existing:Destroy() end

        local tool = self:CreateTool()
        tool.Parent = backpack
        BloodyBlox:Log("Teleport", "Tool given - check backpack", "info")
    end
end

function Teleport:TeleportTo(position)
    local hrp = BloodyBlox:GetHumanoidRootPart()
    if hrp then
        local vec3 = Vector3.new(position.X, position.Y, position.Z)
        hrp.CFrame = CFrame.new(vec3)
        BloodyBlox:Log("Teleport", "Teleported to saved point", "info")
    end
end

function Teleport:DeletePoint(index)
    if BloodyBlox.TeleportPoints[index] then
        table.remove(BloodyBlox.TeleportPoints, index)
        BloodyBlox:SaveTeleportPoints()
        BloodyBlox:Log("Teleport", "Point deleted", "info")
    end
end

-- ============ CONFIG SYSTEM (FIXED) ============

local Config = {}

function Config:Save(name)
    if name == "" or name == "Config name..." then
        BloodyBlox:Log("Config", "Invalid config name", "error")
        return
    end

    pcall(function()
        if not writefile then
            BloodyBlox:Log("Config", "writefile not available", "error")
            return
        end

        local data = {Settings = BloodyBlox.Settings, Version = BloodyBlox.Version}
        local json = HttpService:JSONEncode(data)
        writefile("BloodyBlox_" .. name .. ".json", json)
        BloodyBlox:Log("Config", "Saved: " .. name, "info")
    end)
end

function Config:Load(name)
    if name == "" or name == "Config name..." then
        BloodyBlox:Log("Config", "Invalid config name", "error")
        return
    end

    pcall(function()
        if not isfile or not readfile then
            BloodyBlox:Log("Config", "File functions not available", "error")
            return
        end

        if isfile("BloodyBlox_" .. name .. ".json") then
            local json = readfile("BloodyBlox_" .. name .. ".json")
            local data = HttpService:JSONDecode(json)
            BloodyBlox.Settings = data.Settings
            BloodyBlox:Log("Config", "Loaded: " .. name, "info")
        else
            BloodyBlox:Log("Config", "Not found: " .. name, "error")
        end
    end)
end

function Config:Delete(name)
    if name == "" or name == "Config name..." then
        BloodyBlox:Log("Config", "Invalid config name", "error")
        return
    end

    pcall(function()
        if not isfile or not delfile then
            BloodyBlox:Log("Config", "File functions not available", "error")
            return
        end

        if isfile("BloodyBlox_" .. name .. ".json") then
            delfile("BloodyBlox_" .. name .. ".json")
            BloodyBlox:Log("Config", "Deleted: " .. name, "warn")
        else
            BloodyBlox:Log("Config", "Not found: " .. name, "error")
        end
    end)
end

-- ============ UI SYSTEM ============

local MainUI = {}

function MainUI:Create()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloodyBloxUI_" .. HttpService:GenerateGUID(false)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = BloodyBlox.Player:WaitForChild("PlayerGui")

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 700, 0, 500)
    self.MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    self.MainFrame.BackgroundTransparency = 0.75
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = self.MainFrame

    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Size = UDim2.new(1, 0, 1, 0)
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.ImageTransparency = 0.5
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.ZIndex = 0
    backgroundImage.Parent = self.MainFrame

    pcall(function()
        if isfile and isfile("background.png") and getcustomasset then
            backgroundImage.Image = getcustomasset("background.png")
        end
    end)

    local blurOverlay = Instance.new("Frame")
    blurOverlay.Size = UDim2.new(1, 0, 1, 0)
    blurOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    blurOverlay.BackgroundTransparency = 0.75
    blurOverlay.BorderSizePixel = 0
    blurOverlay.ZIndex = 1
    blurOverlay.Parent = self.MainFrame

    local blurCorner = Instance.new("UICorner")
    blurCorner.CornerRadius = UDim.new(0, 12)
    blurCorner.Parent = blurOverlay

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    accentLine.BackgroundTransparency = 0.2
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 3
    accentLine.Parent = self.MainFrame

    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 50)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 3)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.TitleBar.BackgroundTransparency = 0.3
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.ZIndex = 2
    self.TitleBar.Parent = self.MainFrame

    self.TitleText = Instance.new("TextLabel")
    self.TitleText.Size = UDim2.new(0, 250, 1, 0)
    self.TitleText.Position = UDim2.new(0, 20, 0, 0)
    self.TitleText.BackgroundTransparency = 1
    self.TitleText.Text = "BLOODYBLOX"
    self.TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleText.Font = Enum.Font.GothamBold
    self.TitleText.TextSize = 20
    self.TitleText.ZIndex = 3
    self.TitleText.Parent = self.TitleBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 60, 0, 18)
    versionLabel.Position = UDim2.new(0, 200, 0.5, -9)
    versionLabel.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    versionLabel.BackgroundTransparency = 0.2
    versionLabel.Text = "v" .. BloodyBlox.Version
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.TextSize = 11
    versionLabel.ZIndex = 3
    versionLabel.Parent = self.TitleBar

    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 4)
    versionCorner.Parent = versionLabel

    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Size = UDim2.new(0, 35, 0, 35)
    self.CloseButton.Position = UDim2.new(1, -40, 0.5, -17.5)
    self.CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.CloseButton.BackgroundTransparency = 0.3
    self.CloseButton.BorderSizePixel = 0
    self.CloseButton.Text = "×"
    self.CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.CloseButton.Font = Enum.Font.GothamBold
    self.CloseButton.TextSize = 20
    self.CloseButton.ZIndex = 3
    self.CloseButton.Parent = self.TitleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = self.CloseButton

    self.CloseButton.MouseEnter:Connect(function()
        self.CloseButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    end)
    self.CloseButton.MouseLeave:Connect(function()
        self.CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    end)
    self.CloseButton.MouseButton1Click:Connect(function()
        BloodyBlox:SafeCleanup()
        task.wait(0.1)
        self.ScreenGui:Destroy()
        BloodyBlox.MenuOpen = false
    end)

    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Size = UDim2.new(0, 140, 1, -65)
    self.TabContainer.Position = UDim2.new(0, 10, 0, 58)
    self.TabContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    self.TabContainer.BackgroundTransparency = 0.75
    self.TabContainer.BorderSizePixel = 0
    self.TabContainer.ScrollBarThickness = 0
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabContainer.ZIndex = 2
    self.TabContainer.Parent = self.MainFrame

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 8)
    sidebarCorner.Parent = self.TabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = self.TabContainer

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.PaddingLeft = UDim.new(0, 8)
    tabPadding.PaddingRight = UDim.new(0, 8)
    tabPadding.PaddingBottom = UDim.new(0, 8)
    tabPadding.Parent = self.TabContainer

    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -170, 1, -65)
    self.ContentContainer.Position = UDim2.new(0, 160, 0, 58)
    self.ContentContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    self.ContentContainer.BackgroundTransparency = 0.75
    self.ContentContainer.BorderSizePixel = 0
    self.ContentContainer.ZIndex = 2
    self.ContentContainer.Parent = self.MainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = self.ContentContainer

    return self
end

function MainUI:CreateTab(name)
    local tab = {Name = name, Active = false}

    tab.Button = Instance.new("TextButton")
    tab.Button.Size = UDim2.new(1, -16, 0, 35)
    tab.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    tab.Button.BackgroundTransparency = 0.3
    tab.Button.BorderSizePixel = 0
    tab.Button.Text = name
    tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
    tab.Button.Font = Enum.Font.Gotham
    tab.Button.TextSize = 13
    tab.Button.ZIndex = 3
    tab.Button.Parent = self.TabContainer

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = tab.Button

    tab.Content = Instance.new("ScrollingFrame")
    tab.Content.Size = UDim2.new(1, -20, 1, -20)
    tab.Content.Position = UDim2.new(0, 10, 0, 10)
    tab.Content.BackgroundTransparency = 1
    tab.Content.BorderSizePixel = 0
    tab.Content.ScrollBarThickness = 4
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.Content.Visible = false
    tab.Content.ZIndex = 3
    tab.Content.Parent = self.ContentContainer

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = tab.Content

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.Parent = tab.Content

    tab.Button.MouseButton1Click:Connect(function()
        for _, other in pairs(self.ContentContainer:GetChildren()) do
            if other:IsA("ScrollingFrame") then other.Visible = false end
        end
        for _, other in pairs(self.TabContainer:GetChildren()) do
            if other:IsA("TextButton") then
                other.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                other.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end
        tab.Content.Visible = true
        tab.Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    return tab
end

function MainUI:AddToggle(tab, text, default, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, 0, 0, 35)
    toggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    toggle.BackgroundTransparency = 0.4
    toggle.BorderSizePixel = 0
    toggle.ZIndex = 4
    toggle.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = toggle

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 40, 0, 20)
    button.Position = UDim2.new(1, -45, 0.5, -10)
    button.BackgroundColor3 = default and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 80)
    button.BorderSizePixel = 0
    button.Text = default and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.ZIndex = 5
    button.Parent = toggle

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button

    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(0, 139, 0) or Color3.fromRGB(80, 80, 80)
        callback(state)
    end)
end

function MainUI:AddSlider(tab, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.ZIndex = 4
    frame.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = frame

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 6)
    slider.Position = UDim2.new(0, 10, 1, -15)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    slider.BorderSizePixel = 0
    slider.ZIndex = 5
    slider.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = slider

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = slider

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    local dragging = false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local value = math.floor(min + (max - min) * pos)
            label.Text = text .. ": " .. value
            callback(value)
        end
    end)
end

function MainUI:AddButton(tab, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.ZIndex = 4
    button.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)
end

function MainUI:AddLabel(tab, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(150, 150, 150)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = tab.Content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.Parent = label
end

function MainUI:AddTextBox(tab, placeholder, callback)
    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, 0, 0, 35)
    textbox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    textbox.BackgroundTransparency = 0.4
    textbox.BorderSizePixel = 0
    textbox.PlaceholderText = placeholder
    textbox.Text = ""
    textbox.TextColor3 = Color3.fromRGB(220, 220, 220)
    textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textbox.Font = Enum.Font.Gotham
    textbox.TextSize = 12
    textbox.ZIndex = 4
    textbox.Parent = tab.Content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = textbox

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.Parent = textbox

    textbox.FocusLost:Connect(function()
        callback(textbox.Text)
    end)
end

-- ============ INITIALIZE UI ============

task.wait(0.5)
BloodyBlox:LoadTeleportPoints()

local MainUI = MainUI:Create()

-- Farm Tab
local FarmTab = MainUI:CreateTab("Farm")
MainUI:AddToggle(FarmTab, "Fast Weight (acceleration only)", false, function(v)
    BloodyBlox.Settings.FastWeight = v
    Farm:ToggleFastWeight(v)
end)
MainUI:AddToggle(FarmTab, "Auto Weight", false, function(v)
    BloodyBlox.Settings.AutoWeight = v
    Farm:ToggleAutoWeight(v)
end)
MainUI:AddLabel(FarmTab, "")
MainUI:AddLabel(FarmTab, "Fast Weight: removes delays only")

-- Rebirth Tab
local RebirthTab = MainUI:CreateTab("Rebirth")
MainUI:AddToggle(RebirthTab, "Auto Rebirth", false, function(v)
    BloodyBlox.Settings.AutoRebirth = v
    Rebirth:ToggleAutoRebirth(v)
end)
MainUI:AddToggle(RebirthTab, "Fast Rebirth", false, function(v)
    BloodyBlox.Settings.FastRebirth = v
    Rebirth:ToggleFastRebirth(v)
end)
MainUI:AddButton(RebirthTab, "Rebirth Now", function()
    Rebirth:RebirthNow()
end)

-- Player Tab
local PlayerTab = MainUI:CreateTab("Player")
MainUI:AddToggle(PlayerTab, "Fly", false, function(v)
    BloodyBlox.Settings.Fly = v
    Player:ToggleFly(v)
end)
MainUI:AddSlider(PlayerTab, "Fly Speed", 1, 10, 5, function(v)
    BloodyBlox.Settings.FlySpeed = v
    if BloodyBlox.Settings.Fly then
        Player:ToggleFly(false)
        task.wait(0.1)
        Player:ToggleFly(true)
    end
end)
MainUI:AddToggle(PlayerTab, "Noclip", false, function(v)
    BloodyBlox.Settings.Noclip = v
    Player:ToggleNoclip(v)
end)
MainUI:AddToggle(PlayerTab, "Walk On Water", false, function(v)
    BloodyBlox.Settings.WalkOnWater = v
    Player:ToggleWalkOnWater(v)
end)
MainUI:AddToggle(PlayerTab, "God Mode (may not work)", false, function(v)
    BloodyBlox.Settings.GodMode = v
    Player:ToggleGodMode(v)
end)
MainUI:AddLabel(PlayerTab, "")
MainUI:AddLabel(PlayerTab, "Fly Speed: 1=50, 10=500 studs/s")
MainUI:AddLabel(PlayerTab, "God Mode: server-side protected")

-- Visual Tab
local VisualTab = MainUI:CreateTab("Visual")
MainUI:AddToggle(VisualTab, "ESP", false, function(v)
    BloodyBlox.Settings.ESP = v
    ESP:Toggle(v)
end)
MainUI:AddToggle(VisualTab, "ESP Boxes", true, function(v)
    BloodyBlox.Settings.ESPBoxes = v
end)
MainUI:AddToggle(VisualTab, "ESP Names", true, function(v)
    BloodyBlox.Settings.ESPNames = v
end)
MainUI:AddToggle(VisualTab, "ESP Distance", true, function(v)
    BloodyBlox.Settings.ESPDistance = v
end)
MainUI:AddToggle(VisualTab, "ESP Health", true, function(v)
    BloodyBlox.Settings.ESPHealth = v
end)
MainUI:AddToggle(VisualTab, "ESP Tracers", false, function(v)
    BloodyBlox.Settings.ESPTracers = v
end)
MainUI:AddToggle(VisualTab, "ESP Team Check", false, function(v)
    BloodyBlox.Settings.ESPTeamCheck = v
end)
MainUI:AddToggle(VisualTab, "Fullbright", false, function(v)
    BloodyBlox.Settings.Fullbright = v
    ESP:ToggleFullbright(v)
end)

-- Combat Tab
local CombatTab = MainUI:CreateTab("Combat")
MainUI:AddToggle(CombatTab, "Anti-Aim", false, function(v)
    BloodyBlox.Settings.AntiAim = v
    Player:ToggleAntiAim(v)
end)
MainUI:AddLabel(CombatTab, "")
MainUI:AddLabel(CombatTab, "━━━━━━━━━━━━━━━━━━━━━━━━━")
MainUI:AddLabel(CombatTab, "")
MainUI:AddButton(CombatTab, "Select Fast Hits Target", function()
    local players = Combat:GetPlayerList()
    if #players > 0 then
        BloodyBlox.Settings.FastHitsTarget = players[1]
        BloodyBlox:Log("Combat", "Target: " .. players[1].Name, "info")
    end
end)
MainUI:AddToggle(CombatTab, "Fast Hits (may not work)", false, function(v)
    BloodyBlox.Settings.FastHits = v
    Combat:ToggleFastHits(v)
end)
MainUI:AddLabel(CombatTab, "")
MainUI:AddLabel(CombatTab, "━━━━━━━━━━━━━━━━━━━━━━━━━")
MainUI:AddLabel(CombatTab, "")
MainUI:AddToggle(CombatTab, "Kill Aura (optimized)", false, function(v)
    BloodyBlox.Settings.KillAura = v
    Combat:ToggleKillAura(v)
end)
MainUI:AddSlider(CombatTab, "Kill Aura Range", 10, 200, 50, function(v)
    BloodyBlox.Settings.KillAuraRange = v
end)
MainUI:AddLabel(CombatTab, "")
MainUI:AddLabel(CombatTab, "━━━━━━━━━━━━━━━━━━━━━━━━━")
MainUI:AddLabel(CombatTab, "")
MainUI:AddToggle(CombatTab, "Mega Damage (may not work)", false, function(v)
    BloodyBlox.Settings.MegaDamage = v
    Combat:ToggleMegaDamage(v)
end)

-- Experimental Tab
local ExpTab = MainUI:CreateTab("Experimental")
MainUI:AddToggle(ExpTab, "Fast Time", false, function(v)
    BloodyBlox.Settings.FastTime = v
    Experimental:ToggleFastTime(v)
end)
MainUI:AddSlider(ExpTab, "Time Multiplier", 2, 10, 2, function(v)
    BloodyBlox.Settings.FastTimeMultiplier = v
end)
MainUI:AddLabel(ExpTab, "")
MainUI:AddLabel(ExpTab, "Fast Time: Speeds up game time")
MainUI:AddLabel(ExpTab, "WARNING: Experimental, unstable")

-- Analyzer Tab
local AnalyzerTab = MainUI:CreateTab("Analyzer")
MainUI:AddToggle(AnalyzerTab, "Log All Remotes", false, function(v)
    BloodyBlox.Settings.LogRemotes = v
end)
MainUI:AddToggle(AnalyzerTab, "Dump Offsets", false, function(v)
    BloodyBlox.Settings.DumpOffsets = v
end)
MainUI:AddButton(AnalyzerTab, "RUN FULL ANALYSIS", function()
    BloodyBlox.Settings.AnalyzerActive = true
    Analyzer:Start()
end)
MainUI:AddLabel(AnalyzerTab, "")
MainUI:AddLabel(AnalyzerTab, "Results saved to Logs tab")
MainUI:AddLabel(AnalyzerTab, "Also check F9 console")

-- Teleport Tab
local TeleportTab = MainUI:CreateTab("Teleport")
MainUI:AddButton(TeleportTab, "Give Teleport Tool", function()
    Teleport:GiveTool()
end)
MainUI:AddLabel(TeleportTab, "")
MainUI:AddLabel(TeleportTab, "Tool in backpack - click to save")
MainUI:AddLabel(TeleportTab, "")

task.spawn(function()
    while task.wait(2) do
        if TeleportTab.Content then
            for _, child in pairs(TeleportTab.Content:GetChildren()) do
                if child:IsA("TextButton") and child.Text:find("TP:") then
                    child:Destroy()
                end
            end
            for i, point in ipairs(BloodyBlox.TeleportPoints) do
                MainUI:AddButton(TeleportTab, "TP: " .. point.Name, function()
                    Teleport:TeleportTo(point.Position)
                end)
            end
        end
    end
end)

-- Config Tab
local ConfigTab = MainUI:CreateTab("Config")
local configName = ""
MainUI:AddTextBox(ConfigTab, "Config name...", function(t) configName = t end)
MainUI:AddButton(ConfigTab, "Save", function() Config:Save(configName) end)
MainUI:AddButton(ConfigTab, "Load", function() Config:Load(configName) end)
MainUI:AddButton(ConfigTab, "Delete", function() Config:Delete(configName) end)
MainUI:AddLabel(ConfigTab, "")
MainUI:AddLabel(ConfigTab, "Configs saved to workspace folder")

-- Logs Tab
local LogsTab = MainUI:CreateTab("Logs")
MainUI:AddButton(LogsTab, "Refresh Logs", function()
    for _, child in pairs(LogsTab.Content:GetChildren()) do
        if child:IsA("TextLabel") and child.Text ~= "" then child:Destroy() end
    end
    for i = math.max(1, #BloodyBlox.Logs - 30), #BloodyBlox.Logs do
        local log = BloodyBlox.Logs[i]
        if log then
            MainUI:AddLabel(LogsTab, string.format("[%s][%s] %s", log.time, log.category, log.message))
        end
    end
end)
MainUI:AddButton(LogsTab, "Copy All", function()
    local all = ""
    for _, log in ipairs(BloodyBlox.Logs) do
        all = all .. string.format("[%s][%s] %s\n", log.time, log.category, log.message)
    end
    if setclipboard then
        setclipboard(all)
        BloodyBlox:Log("Logs", "Copied " .. #BloodyBlox.Logs .. " logs", "info")
    end
end)

-- Settings Tab
local SettingsTab = MainUI:CreateTab("Settings")
MainUI:AddButton(SettingsTab, "Disable All", function()
    for key, _ in pairs(BloodyBlox.Settings) do
        if type(BloodyBlox.Settings[key]) == "boolean" then
            BloodyBlox.Settings[key] = false
        end
    end
    BloodyBlox:Log("Settings", "All disabled", "info")
end)
MainUI:AddButton(SettingsTab, "SAFE EXIT", function()
    BloodyBlox:SafeCleanup()
    task.wait(0.3)
    MainUI.ScreenGui:Destroy()
    _G.BloodyBloxLoaded = nil
    BloodyBlox:Log("Settings", "Exited safely", "info")
end)
MainUI:AddLabel(SettingsTab, "")
MainUI:AddLabel(SettingsTab, "Version: " .. BloodyBlox.Version)
MainUI:AddLabel(SettingsTab, "Use SAFE EXIT to prevent crash")

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Insert then
        BloodyBlox.MenuOpen = not BloodyBlox.MenuOpen
        MainUI.ScreenGui.Enabled = BloodyBlox.MenuOpen
    end
end)

BloodyBlox:Log("System", "BloodyBlox v" .. BloodyBlox.Version .. " loaded", "info")
print("[BloodyBlox] v" .. BloodyBlox.Version .. " — Press INSERT")
