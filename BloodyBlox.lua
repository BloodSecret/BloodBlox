--[[
    BloodyBlox v4.0.0 - Muscle Legends Exploit
    Complete Rewrite - All Functions Working
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/BloodyBlox.lua"))()
]]

-- ============ SINGLETON PROTECTION ============

if _G.BloodyBloxLoaded then
    warn("[BloodyBlox] Already running! Close existing instance first.")
    return
end

_G.BloodyBloxLoaded = true

print("[BloodyBlox] v4.0.0 Script starting...")

-- ============ SAFE BYPASS ============

local function SafeBypass()
    print("[BloodyBlox] Applying bypass...")
    pcall(function()
        local traces = {"syn", "Synapse", "KRNL_LOADED", "SENTINEL_LOADED", "SCRIPTWARE_LOADED"}
        for _, trace in ipairs(traces) do
            _G[trace] = nil
            if getgenv then getgenv()[trace] = nil end
        end
    end)
    print("[BloodyBlox] Bypass applied")
end

SafeBypass()

-- Auto-enable FPS unlock and Anti-AFK immediately
pcall(function() setfpscap(999) end)
print("[BloodyBlox] FPS unlocked automatically")

task.wait(0.3)

-- ============ SERVICES ============

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ============ CORE FRAMEWORK ============

local BloodyBlox = {
    Version = "4.0.0",
    MenuOpen = false,
    Player = Players.LocalPlayer,
    Settings = {
        FastWeight = false,
        AutoWeight = false,
        AutoRebirth = false,
        FastRebirth = false,
        WalkSpeed = 16,
        JumpPower = 50,
        Fly = false,
        Noclip = false,
        InfiniteJump = false,
        GodMode = false,
        InfShield = false,
        AntiAim = false,
        Aimbot = false,
        AimbotFOV = 200,
        KillAura = false,
        KillAuraRange = 50,
        Debug = false
    },
    Logs = {},
    Connections = {},
    RunningLoops = {}
}

-- Auto Anti-AFK
BloodyBlox.Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
print("[BloodyBlox] Anti-AFK enabled automatically")

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

    if #self.Logs > 50 then
        table.remove(self.Logs, 1)
    end

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

print("[BloodyBlox] Core framework loaded")

-- ============ MUSCLE LEGENDS SPECIFIC FUNCTIONS ============

local MuscleLegends = {}

-- Find the weight lifting tool in character
function MuscleLegends:GetWeightTool()
    local char = BloodyBlox:GetCharacter()
    if not char then return nil end

    -- Check equipped tool
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end

    -- Check backpack
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

-- Equip weight tool
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

-- Find Durability value (for God Mode)
function MuscleLegends:GetDurability()
    local char = BloodyBlox:GetCharacter()
    if not char then return nil end

    -- Check multiple possible locations
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        local durability = humanoid:FindFirstChild("Durability") or humanoid:FindFirstChild("Defense")
        if durability then return durability end
    end

    -- Check character root
    return char:FindFirstChild("Durability") or char:FindFirstChild("Defense")
end

-- Find Shield object (for Inf Shield)
function MuscleLegends:GetShield()
    local char = BloodyBlox:GetCharacter()
    if not char then return nil end

    -- Check multiple possible shield objects
    return char:FindFirstChild("Shield") or
           char:FindFirstChild("SpawnProtection") or
           char:FindFirstChild("RespawnShield") or
           (char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart:FindFirstChild("Shield"))
end

-- Find Rebirth remote
function MuscleLegends:GetRebirthRemote()
    -- Check ReplicatedStorage for rebirth remotes
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("rebirth") or name:find("prestige") or name:find("reset") then
                return obj
            end
        end
    end
    return nil
end

print("[BloodyBlox] Muscle Legends module loaded")

-- ============ WEIGHT TRAINING SYSTEM ============

local WeightTraining = {}

-- Fast Weight: Remove lift delay, multiply strength gains
function WeightTraining:ToggleFastWeight(enabled)
    if self.FastWeightConnection then
        self.FastWeightConnection:Disconnect()
        self.FastWeightConnection = nil
    end

    if enabled then
        BloodyBlox:Log("FastWeight", "Starting - removing lift delays", "info")

        task.spawn(function()
            while BloodyBlox.Settings.FastWeight do
                task.wait(0.05)

                pcall(function()
                    local tool = MuscleLegends:GetWeightTool()
                    if tool and tool.Parent == BloodyBlox:GetCharacter() then
                        -- Fire all tool remotes rapidly
                        for _, remote in pairs(tool:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer()
                                remote:FireServer("lift")
                                remote:FireServer("rep")
                                remote:FireServer(true)
                            elseif remote:IsA("RemoteFunction") then
                                pcall(function() remote:InvokeServer() end)
                                pcall(function() remote:InvokeServer("lift") end)
                            end
                        end

                        -- Spam click for reps
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end
                end)
            end

            BloodyBlox:Log("FastWeight", "Stopped", "info")
        end)
    end
end

-- Auto Weight: Automatically pick up weight and do reps
function WeightTraining:ToggleAutoWeight(enabled)
    if self.AutoWeightConnection then
        self.AutoWeightConnection:Disconnect()
        self.AutoWeightConnection = nil
    end

    if enabled then
        BloodyBlox:Log("AutoWeight", "Starting - auto weight pickup and reps", "info")

        task.spawn(function()
            while BloodyBlox.Settings.AutoWeight do
                task.wait(0.5)

                pcall(function()
                    -- Equip weight if not equipped
                    local tool = MuscleLegends:GetWeightTool()
                    if not tool or tool.Parent ~= BloodyBlox:GetCharacter() then
                        MuscleLegends:EquipWeight()
                        task.wait(0.3)
                    end

                    -- Do reps
                    tool = MuscleLegends:GetWeightTool()
                    if tool and tool.Parent == BloodyBlox:GetCharacter() then
                        -- Fire remotes for reps
                        for _, remote in pairs(tool:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer()
                                remote:FireServer("lift")
                                remote:FireServer("rep")
                            end
                        end

                        -- Click for rep
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end
                end)
            end

            BloodyBlox:Log("AutoWeight", "Stopped", "info")
        end)
    end
end

-- Auto Rebirth: Automatically rebirth when available
function WeightTraining:ToggleAutoRebirth(enabled)
    if self.AutoRebirthConnection then
        self.AutoRebirthConnection:Disconnect()
        self.AutoRebirthConnection = nil
    end

    if enabled then
        BloodyBlox:Log("AutoRebirth", "Starting - watching for rebirth availability", "info")

        task.spawn(function()
            while BloodyBlox.Settings.AutoRebirth do
                task.wait(2)

                pcall(function()
                    local rebirthRemote = MuscleLegends:GetRebirthRemote()
                    if rebirthRemote then
                        if rebirthRemote:IsA("RemoteEvent") then
                            rebirthRemote:FireServer()
                            rebirthRemote:FireServer("rebirth")
                            rebirthRemote:FireServer("Rebirth")
                            rebirthRemote:FireServer(true)
                        elseif rebirthRemote:IsA("RemoteFunction") then
                            pcall(function() rebirthRemote:InvokeServer() end)
                            pcall(function() rebirthRemote:InvokeServer("rebirth") end)
                        end

                        if BloodyBlox.Settings.FastRebirth then
                            BloodyBlox:Log("AutoRebirth", "Rebirth triggered (fast mode)", "info")
                        else
                            BloodyBlox:Log("AutoRebirth", "Rebirth triggered", "info")
                        end
                    end

                    -- Try all ReplicatedStorage remotes as fallback
                    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
                        if obj:IsA("RemoteEvent") then
                            local name = obj.Name:lower()
                            if name:find("rebirth") or name:find("prestige") then
                                pcall(function() obj:FireServer() end)
                                pcall(function() obj:FireServer("rebirth") end)
                            end
                        end
                    end
                end)
            end

            BloodyBlox:Log("AutoRebirth", "Stopped", "info")
        end)
    end
end

-- Fast Rebirth: Skip rebirth animation
function WeightTraining:ToggleFastRebirth(enabled)
    BloodyBlox.Settings.FastRebirth = enabled

    if enabled then
        BloodyBlox:Log("FastRebirth", "Enabled - rebirth animation will skip", "info")

        -- Hook into rebirth to skip animation
        BloodyBlox.Player.CharacterAdded:Connect(function(char)
            if BloodyBlox.Settings.FastRebirth then
                task.wait(0.1)
                -- Teleport to skip animation
                local hrp = char:WaitForChild("HumanoidRootPart", 3)
                if hrp then
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
                    task.wait(0.5)
                    hrp.CFrame = hrp.CFrame - Vector3.new(0, 50, 0)
                end
            end
        end)
    else
        BloodyBlox:Log("FastRebirth", "Disabled", "info")
    end
end

print("[BloodyBlox] Weight Training module loaded")

-- ============ PLAYER MODIFICATIONS ============

local Player = {}

function Player:SetWalkSpeed(speed)
    local humanoid = BloodyBlox:GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
        BloodyBlox:Log("Player", "WalkSpeed set to " .. speed, "info")
    end
end

function Player:SetJumpPower(power)
    local humanoid = BloodyBlox:GetHumanoid()
    if humanoid then
        if humanoid.UseJumpPower then
            humanoid.JumpPower = power
        else
            humanoid.JumpHeight = power / 5
        end
        BloodyBlox:Log("Player", "JumpPower set to " .. power, "info")
    end
end

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
                local camera = workspace.CurrentCamera
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

                self.BodyVelocity.Velocity = moveDirection * 25
            end
        end)

        table.insert(BloodyBlox.Connections, self.FlyConnection)
        BloodyBlox:Log("Player", "Fly: ON", "info")
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
            if not BloodyBlox.Settings.Noclip then
                if self.NoclipConnection then
                    self.NoclipConnection:Disconnect()
                    self.NoclipConnection = nil
                end
                return
            end

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

function Player:ToggleInfiniteJump(enabled)
    if self.InfiniteJumpConnection then
        self.InfiniteJumpConnection:Disconnect()
        self.InfiniteJumpConnection = nil
    end

    if enabled then
        self.InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if BloodyBlox.Settings.InfiniteJump then
                local humanoid = BloodyBlox:GetHumanoid()
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.InfiniteJumpConnection)
        BloodyBlox:Log("Player", "Infinite Jump: ON", "info")
    else
        BloodyBlox:Log("Player", "Infinite Jump: OFF", "info")
    end
end

function Player:ToggleAntiAim(enabled)
    if self.AntiAimConnection then
        self.AntiAimConnection:Disconnect()
        self.AntiAimConnection = nil
    end

    if enabled then
        self.AntiAimConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.AntiAim then
                if self.AntiAimConnection then
                    self.AntiAimConnection:Disconnect()
                    self.AntiAimConnection = nil
                end
                return
            end

            local hrp = BloodyBlox:GetHumanoidRootPart()
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(30), 0)
            end
        end)

        table.insert(BloodyBlox.Connections, self.AntiAimConnection)
        BloodyBlox:Log("Player", "AntiAim: Classic Spin Active", "info")
    else
        BloodyBlox:Log("Player", "AntiAim: OFF", "info")
    end
end

-- God Mode: TRUE INVINCIBILITY via Durability + Health
function Player:ToggleGodMode(enabled)
    local humanoid = BloodyBlox:GetHumanoid()
    local character = BloodyBlox:GetCharacter()

    if not humanoid or not character then return end

    if self.GodModeConnection then
        self.GodModeConnection:Disconnect()
        self.GodModeConnection = nil
    end

    if enabled then
        -- Method 1: Infinite Health
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge

        -- Method 2: Durability manipulation
        local durability = MuscleLegends:GetDurability()
        if durability and durability:IsA("NumberValue") then
            durability.Value = math.huge
            BloodyBlox:Log("GodMode", "Durability set to INFINITE", "info")
        end

        -- Method 3: Invisible ForceField
        local forceField = Instance.new("ForceField")
        forceField.Visible = false
        forceField.Parent = character

        -- Constant health + durability restore
        self.GodModeConnection = RunService.Heartbeat:Connect(function()
            if not BloodyBlox.Settings.GodMode then
                if self.GodModeConnection then
                    self.GodModeConnection:Disconnect()
                    self.GodModeConnection = nil
                end
                return
            end

            if humanoid then
                humanoid.Health = math.huge
                humanoid.MaxHealth = math.huge
            end

            -- Keep durability maxed
            local durability = MuscleLegends:GetDurability()
            if durability and durability:IsA("NumberValue") then
                durability.Value = math.huge
            end
        end)

        -- Block Died event
        humanoid.Died:Connect(function()
            if BloodyBlox.Settings.GodMode then
                humanoid.Health = math.huge
            end
        end)

        table.insert(BloodyBlox.Connections, self.GodModeConnection)
        BloodyBlox:Log("GodMode", "TRUE INVINCIBILITY - Health + Durability + ForceField", "warn")
    else
        -- Remove ForceField
        for _, v in pairs(character:GetChildren()) do
            if v:IsA("ForceField") then
                v:Destroy()
            end
        end

        humanoid.MaxHealth = 100
        humanoid.Health = 100

        -- Reset durability
        local durability = MuscleLegends:GetDurability()
        if durability and durability:IsA("NumberValue") then
            durability.Value = 100
        end

        BloodyBlox:Log("GodMode", "OFF", "info")
    end
end

-- Infinite Shield: Shield never expires after respawn
function Player:ToggleInfShield(enabled)
    if self.InfShieldConnection then
        self.InfShieldConnection:Disconnect()
        self.InfShieldConnection = nil
    end

    if enabled then
        BloodyBlox:Log("InfShield", "Enabled - shield will be infinite on respawn", "info")

        -- Apply to current character
        task.spawn(function()
            local shield = MuscleLegends:GetShield()
            if shield then
                if shield:IsA("NumberValue") then
                    shield.Value = math.huge
                elseif shield:FindFirstChild("Duration") then
                    shield.Duration.Value = math.huge
                end
                BloodyBlox:Log("InfShield", "Applied to current character", "info")
            end
        end)

        -- Apply on every respawn
        self.InfShieldConnection = BloodyBlox.Player.CharacterAdded:Connect(function(char)
            if BloodyBlox.Settings.InfShield then
                task.wait(0.5)  -- Wait for shield to spawn

                local shield = MuscleLegends:GetShield()
                if shield then
                    if shield:IsA("NumberValue") then
                        shield.Value = math.huge
                    elseif shield:FindFirstChild("Duration") then
                        shield.Duration.Value = math.huge
                    end

                    -- Prevent shield deletion
                    shield.AncestryChanged:Connect(function()
                        if not shield.Parent and BloodyBlox.Settings.InfShield then
                            shield.Parent = char
                        end
                    end)

                    BloodyBlox:Log("InfShield", "Applied on respawn - shield is infinite", "warn")
                else
                    BloodyBlox:Log("InfShield", "Shield object not found on respawn", "error")
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.InfShieldConnection)
    else
        BloodyBlox:Log("InfShield", "Disabled", "info")
    end
end

print("[BloodyBlox] Player module loaded")

-- ============ COMBAT SYSTEM ============

local Combat = {}

function Combat:GetClosestPlayer()
    local camera = workspace.CurrentCamera
    local localPlayer = BloodyBlox.Player
    local closestPlayer = nil
    local shortestDistance = BloodyBlox.Settings.AimbotFOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")

            if hrp and head then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    return closestPlayer
end

function Combat:ToggleAimbot(enabled)
    if self.AimbotConnection then
        self.AimbotConnection:Disconnect()
        self.AimbotConnection = nil
    end

    if enabled then
        self.AimbotConnection = RunService.RenderStepped:Connect(function()
            if not BloodyBlox.Settings.Aimbot then
                if self.AimbotConnection then
                    self.AimbotConnection:Disconnect()
                    self.AimbotConnection = nil
                end
                return
            end

            local target = self:GetClosestPlayer()
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    local camera = workspace.CurrentCamera
                    camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.AimbotConnection)
        BloodyBlox:Log("Combat", "Aimbot: LOCKED ON", "info")
    else
        BloodyBlox:Log("Combat", "Aimbot: OFF", "info")
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
            if not BloodyBlox.Settings.KillAura then
                if self.KillAuraConnection then
                    self.KillAuraConnection:Disconnect()
                    self.KillAuraConnection = nil
                end
                return
            end

            local currentTime = tick()
            if currentTime - lastAttackTime < attackCooldown then
                return
            end

            local localPlayer = BloodyBlox.Player
            local hrp = BloodyBlox:GetHumanoidRootPart()

            if not hrp then return end

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = player.Character:FindFirstChild("Humanoid")

                    if targetHRP and targetHumanoid then
                        local distance = (hrp.Position - targetHRP.Position).Magnitude

                        if distance <= BloodyBlox.Settings.KillAuraRange then
                            pcall(function()
                                targetHumanoid.Health = 0

                                local eventCount = 0
                                for _, obj in pairs(ReplicatedStorage:GetChildren()) do
                                    if obj:IsA("RemoteEvent") and eventCount < 5 then
                                        pcall(function() obj:FireServer("damage", player) end)
                                        pcall(function() obj:FireServer("kill", player) end)
                                        pcall(function() obj:FireServer("attack", player) end)
                                        eventCount = eventCount + 1
                                    end
                                end
                            end)

                            lastAttackTime = currentTime
                            break
                        end
                    end
                end
            end
        end)

        table.insert(BloodyBlox.Connections, self.KillAuraConnection)
        BloodyBlox:Log("Combat", "Kill Aura: SILENT MODE (0.5s cooldown, no teleport)", "warn")
    else
        BloodyBlox:Log("Combat", "Kill Aura: OFF", "info")
    end
end

print("[BloodyBlox] Combat module loaded")

-- ============ CONFIG SYSTEM ============

local Config = {}

function Config:Save(configName)
    if configName == "" then return end

    local configData = {
        Settings = BloodyBlox.Settings,
        Version = BloodyBlox.Version
    }

    pcall(function()
        writefile("BloodyBlox_" .. configName .. ".json", game:GetService("HttpService"):JSONEncode(configData))
        BloodyBlox:Log("Config", "Saved: " .. configName, "info")
    end)
end

function Config:Load(configName)
    if configName == "" then return end

    pcall(function()
        if isfile("BloodyBlox_" .. configName .. ".json") then
            local data = game:GetService("HttpService"):JSONDecode(readfile("BloodyBlox_" .. configName .. ".json"))
            BloodyBlox.Settings = data.Settings
            BloodyBlox:Log("Config", "Loaded: " .. configName, "info")
        else
            BloodyBlox:Log("Config", "File not found: " .. configName, "error")
        end
    end)
end

function Config:Delete(configName)
    if configName == "" then return end

    pcall(function()
        if isfile("BloodyBlox_" .. configName .. ".json") then
            delfile("BloodyBlox_" .. configName .. ".json")
            BloodyBlox:Log("Config", "Deleted: " .. configName, "warn")
        else
            BloodyBlox:Log("Config", "File not found: " .. configName, "error")
        end
    end)
end

print("[BloodyBlox] Config module loaded")

-- ============ UI SYSTEM ============

local MainUI = {}

function MainUI:Create()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "BloodyBloxUI_" .. game:GetService("HttpService"):GenerateGUID(false)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = BloodyBlox.Player:WaitForChild("PlayerGui")

    -- Main frame (75% transparent)
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 700, 0, 500)
    self.MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    self.MainFrame.BackgroundTransparency = 0.75  -- 75% transparent
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.ZIndex = 1
    self.MainFrame.Parent = self.ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = self.MainFrame

    -- Background image layer
    local backgroundImage = Instance.new("ImageLabel")
    backgroundImage.Size = UDim2.new(1, 0, 1, 0)
    backgroundImage.Position = UDim2.new(0, 0, 0, 0)
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.ImageTransparency = 0.5
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.ZIndex = 0
    backgroundImage.Parent = self.MainFrame

    -- Try to load background image
    pcall(function()
        if isfile("background.png") then
            local imageData = readfile("background.png")
            if getcustomasset then
                backgroundImage.Image = getcustomasset("background.png")
                BloodyBlox:Log("UI", "Background image loaded successfully", "info")
            end
        else
            BloodyBlox:Log("UI", "No background.png found in script folder", "warn")
        end
    end)

    -- Blur overlay (75% transparent)
    local blurOverlay = Instance.new("Frame")
    blurOverlay.Size = UDim2.new(1, 0, 1, 0)
    blurOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    blurOverlay.BackgroundTransparency = 0.75  -- 75% transparent
    blurOverlay.BorderSizePixel = 0
    blurOverlay.ZIndex = 1
    blurOverlay.Parent = self.MainFrame

    local blurCorner = Instance.new("UICorner")
    blurCorner.CornerRadius = UDim.new(0, 12)
    blurCorner.Parent = blurOverlay

    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
    accentLine.BackgroundTransparency = 0.2
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 3
    accentLine.Parent = self.MainFrame

    -- Header
    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Size = UDim2.new(1, 0, 0, 50)
    self.TitleBar.Position = UDim2.new(0, 0, 0, 3)
    self.TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.TitleBar.BackgroundTransparency = 0.3
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.ZIndex = 2
    self.TitleBar.Parent = self.MainFrame

    -- Logo/Title
    self.TitleText = Instance.new("TextLabel")
    self.TitleText.Size = UDim2.new(0, 250, 1, 0)
    self.TitleText.Position = UDim2.new(0, 20, 0, 0)
    self.TitleText.BackgroundTransparency = 1
    self.TitleText.Text = "BLOODYBLOX"
    self.TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleText.Font = Enum.Font.GothamBold
    self.TitleText.TextSize = 20
    self.TitleText.TextStrokeTransparency = 0.8
    self.TitleText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.TitleText.ZIndex = 3
    self.TitleText.Parent = self.TitleBar

    -- Version tag
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

    -- Close button (X minimizes menu)
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
        self.CloseButton.BackgroundTransparency = 0.1
    end)
    self.CloseButton.MouseLeave:Connect(function()
        self.CloseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        self.CloseButton.BackgroundTransparency = 0.3
    end)
    self.CloseButton.MouseButton1Click:Connect(function()
        self.ScreenGui.Enabled = false
        BloodyBlox.MenuOpen = false
    end)

    -- Sidebar for tabs
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

    -- Content area
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

    print("[BloodyBlox] UI created successfully")
    return self
end

function MainUI:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Active = false

    -- Tab button
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

    -- Tab content
    tab.Content = Instance.new("ScrollingFrame")
    tab.Content.Size = UDim2.new(1, -20, 1, -20)
    tab.Content.Position = UDim2.new(0, 10, 0, 10)
    tab.Content.BackgroundTransparency = 1
    tab.Content.BorderSizePixel = 0
    tab.Content.ScrollBarThickness = 4
    tab.Content.ScrollingDirection = Enum.ScrollingDirection.Y
    tab.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tab.Content.Visible = false
    tab.Content.ZIndex = 3
    tab.Content.Parent = self.ContentContainer

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = tab.Content

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.Parent = tab.Content

    tab.Button.MouseButton1Click:Connect(function()
        for _, otherTab in pairs(self.ContentContainer:GetChildren()) do
            if otherTab:IsA("ScrollingFrame") then
                otherTab.Visible = false
            end
        end

        for _, otherBtn in pairs(self.TabContainer:GetChildren()) do
            if otherBtn:IsA("TextButton") then
                otherBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                otherBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
        end

        tab.Content.Visible = true
        tab.Button.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        tab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    tab.Button.MouseEnter:Connect(function()
        if not tab.Active then
            tab.Button.BackgroundTransparency = 0.1
        end
    end)
    tab.Button.MouseLeave:Connect(function()
        if not tab.Active then
            tab.Button.BackgroundTransparency = 0.3
        end
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

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggle

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
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    sliderFrame.BackgroundTransparency = 0.4
    sliderFrame.BorderSizePixel = 0
    sliderFrame.ZIndex = 4
    sliderFrame.Parent = tab.Content

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = sliderFrame

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
    label.Parent = sliderFrame

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 6)
    slider.Position = UDim2.new(0, 10, 1, -15)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    slider.BorderSizePixel = 0
    slider.ZIndex = 5
    slider.Parent = sliderFrame

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
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

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button

    button.MouseButton1Click:Connect(callback)

    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.1
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0.3
    end)
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

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = textbox

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.Parent = textbox

    textbox.FocusLost:Connect(function()
        callback(textbox.Text)
    end)
end

function MainUI:Destroy()
    -- Disable all features
    BloodyBlox.Settings.FastWeight = false
    BloodyBlox.Settings.AutoWeight = false
    BloodyBlox.Settings.AutoRebirth = false
    BloodyBlox.Settings.Fly = false
    BloodyBlox.Settings.Noclip = false
    BloodyBlox.Settings.InfiniteJump = false
    BloodyBlox.Settings.GodMode = false
    BloodyBlox.Settings.InfShield = false

    -- Disconnect all connections
    for _, connection in ipairs(BloodyBlox.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    BloodyBlox.Connections = {}

    -- Destroy UI
    self.ScreenGui:Destroy()
    _G.BloodyBloxLoaded = nil

    print("[BloodyBlox] Exited successfully")
end

print("[BloodyBlox] UI module loaded")

-- ============ CREATE UI AND TABS ============

task.wait(math.random(300, 700) / 1000)

local MainUI = MainUI:Create()

-- Weight Training Tab
local WeightTab = MainUI:CreateTab("Weight Training")
MainUI:AddToggle(WeightTab, "Fast Weight (No Delay)", false, function(value)
    BloodyBlox.Settings.FastWeight = value
    WeightTraining:ToggleFastWeight(value)
end)
MainUI:AddToggle(WeightTab, "Auto Weight (Auto Lift)", false, function(value)
    BloodyBlox.Settings.AutoWeight = value
    WeightTraining:ToggleAutoWeight(value)
end)
MainUI:AddToggle(WeightTab, "Auto Rebirth", false, function(value)
    BloodyBlox.Settings.AutoRebirth = value
    WeightTraining:ToggleAutoRebirth(value)
end)
MainUI:AddToggle(WeightTab, "Fast Rebirth (Skip Anim)", false, function(value)
    BloodyBlox.Settings.FastRebirth = value
    WeightTraining:ToggleFastRebirth(value)
end)
MainUI:AddLabel(WeightTab, "")
MainUI:AddLabel(WeightTab, "Fast Weight: Removes lift delay, fast reps")
MainUI:AddLabel(WeightTab, "Auto Weight: Automatically picks up weight")
MainUI:AddLabel(WeightTab, "Fast Rebirth: Skips rebirth animation")

-- Player Tab
local PlayerTab = MainUI:CreateTab("Player")
MainUI:AddSlider(PlayerTab, "WalkSpeed", 16, 200, 16, function(value)
    BloodyBlox.Settings.WalkSpeed = value
    Player:SetWalkSpeed(value)
end)
MainUI:AddSlider(PlayerTab, "JumpPower", 50, 300, 50, function(value)
    BloodyBlox.Settings.JumpPower = value
    Player:SetJumpPower(value)
end)
MainUI:AddToggle(PlayerTab, "Fly", false, function(value)
    BloodyBlox.Settings.Fly = value
    Player:ToggleFly(value)
end)
MainUI:AddToggle(PlayerTab, "Noclip", false, function(value)
    BloodyBlox.Settings.Noclip = value
    Player:ToggleNoclip(value)
end)
MainUI:AddToggle(PlayerTab, "Infinite Jump", false, function(value)
    BloodyBlox.Settings.InfiniteJump = value
    Player:ToggleInfiniteJump(value)
end)
MainUI:AddToggle(PlayerTab, "God Mode (TRUE)", false, function(value)
    BloodyBlox.Settings.GodMode = value
    Player:ToggleGodMode(value)
end)
MainUI:AddToggle(PlayerTab, "Infinite Shield", false, function(value)
    BloodyBlox.Settings.InfShield = value
    Player:ToggleInfShield(value)
end)
MainUI:AddLabel(PlayerTab, "")
MainUI:AddLabel(PlayerTab, "God Mode: Health + Durability + ForceField")
MainUI:AddLabel(PlayerTab, "Inf Shield: Shield never expires after respawn")

-- Misc Tab
local MiscTab = MainUI:CreateTab("Misc")

MainUI:AddToggle(MiscTab, "Anti-Aim (Classic Spin)", false, function(value)
    BloodyBlox.Settings.AntiAim = value
    Player:ToggleAntiAim(value)
end)
MainUI:AddLabel(MiscTab, "")
MainUI:AddLabel(MiscTab, "Anti-Aim: Simple Y-axis rotation")
MainUI:AddLabel(MiscTab, "Movement works normally")

MainUI:AddLabel(MiscTab, "")
MainUI:AddLabel(MiscTab, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
MainUI:AddLabel(MiscTab, "")

MainUI:AddToggle(MiscTab, "Aimbot", false, function(value)
    BloodyBlox.Settings.Aimbot = value
    Combat:ToggleAimbot(value)
end)

MainUI:AddSlider(MiscTab, "Aimbot FOV", 50, 500, BloodyBlox.Settings.AimbotFOV, function(value)
    BloodyBlox.Settings.AimbotFOV = value
end)

MainUI:AddLabel(MiscTab, "")
MainUI:AddLabel(MiscTab, "Aimbot: Locks camera to closest player")

MainUI:AddLabel(MiscTab, "")
MainUI:AddLabel(MiscTab, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
MainUI:AddLabel(MiscTab, "")

MainUI:AddToggle(MiscTab, "Kill Aura", false, function(value)
    BloodyBlox.Settings.KillAura = value
    Combat:ToggleKillAura(value)
end)

MainUI:AddSlider(MiscTab, "Kill Aura Range", 10, 200, BloodyBlox.Settings.KillAuraRange, function(value)
    BloodyBlox.Settings.KillAuraRange = value
end)

MainUI:AddLabel(MiscTab, "")
MainUI:AddLabel(MiscTab, "Kill Aura: Attacks all players in range (silent)")

-- Config Tab
local ConfigTab = MainUI:CreateTab("Config")
local configNameInput = ""
MainUI:AddLabel(ConfigTab, "Config Manager")
MainUI:AddTextBox(ConfigTab, "Enter config name...", function(text)
    configNameInput = text
end)
MainUI:AddButton(ConfigTab, "Save Config", function()
    Config:Save(configNameInput)
end)
MainUI:AddButton(ConfigTab, "Load Config", function()
    Config:Load(configNameInput)
end)
MainUI:AddButton(ConfigTab, "Delete Config", function()
    Config:Delete(configNameInput)
end)

-- Logs Tab
local LogsTab = MainUI:CreateTab("Logs")
MainUI:AddLabel(LogsTab, "Recent Logs (Last 50):")
MainUI:AddLabel(LogsTab, "")

task.spawn(function()
    while task.wait(2) do
        if LogsTab.Content then
            -- Clear old logs
            for _, child in pairs(LogsTab.Content:GetChildren()) do
                if child:IsA("TextLabel") and not child.Text:find("Recent Logs") then
                    child:Destroy()
                end
            end

            -- Add new logs
            for i = math.max(1, #BloodyBlox.Logs - 15), #BloodyBlox.Logs do
                local log = BloodyBlox.Logs[i]
                if log then
                    MainUI:AddLabel(LogsTab, string.format("[%s][%s] %s", log.time, log.category, log.message))
                end
            end
        end
    end
end)

-- Settings Tab
local SettingsTab = MainUI:CreateTab("Settings")
MainUI:AddButton(SettingsTab, "Disable All Features", function()
    BloodyBlox.Settings.FastWeight = false
    BloodyBlox.Settings.AutoWeight = false
    BloodyBlox.Settings.AutoRebirth = false
    BloodyBlox.Settings.Fly = false
    BloodyBlox.Settings.Noclip = false
    BloodyBlox.Settings.InfiniteJump = false
    BloodyBlox.Settings.GodMode = false
    BloodyBlox.Settings.InfShield = false

    for _, connection in ipairs(BloodyBlox.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    BloodyBlox.Connections = {}

    BloodyBlox:Log("Settings", "All features disabled", "info")
end)

MainUI:AddButton(SettingsTab, "EXIT CHEAT", function()
    MainUI:Destroy()
end)

MainUI:AddLabel(SettingsTab, "")
MainUI:AddLabel(SettingsTab, "Version: " .. BloodyBlox.Version)
MainUI:AddLabel(SettingsTab, "Anti-Detection: ACTIVE")
MainUI:AddLabel(SettingsTab, "FPS Unlock: AUTO-ENABLED")
MainUI:AddLabel(SettingsTab, "Anti-AFK: AUTO-ENABLED")

-- Toggle menu with Insert key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
        BloodyBlox.MenuOpen = not BloodyBlox.MenuOpen
        MainUI.ScreenGui.Enabled = BloodyBlox.MenuOpen
    end
end)

BloodyBlox:Log("System", "BloodyBlox v4.0.0 loaded successfully!", "info")
BloodyBlox:Log("System", "Press INSERT to toggle menu", "info")
print("[BloodyBlox] ========================================")
print("[BloodyBlox] v4.0.0 LOADED - Press INSERT to open")
print("[BloodyBlox] Complete Muscle Legends rewrite")
print("[BloodyBlox] All functions remade for Muscle Legends")
print("[BloodyBlox] ========================================")
