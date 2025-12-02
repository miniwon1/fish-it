-------------------------------------------
----- Fish It DEBUG Edition v3.1
----- Auto-Detect Correct Minigame Remote
----- Full Debug Logging
-------------------------------------------

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-------------------------------------------
----- Services & Core Variables
-------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- Character handling
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-- Net Remote Paths
local success, net = pcall(function()
    return ReplicatedStorage:WaitForChild("Packages", 10)
        :WaitForChild("_Index", 10)
        :WaitForChild("sleitnick_net@0.2.0", 10)
        :WaitForChild("net", 10)
end)

if not success or not net then
    warn("Failed to load net remotes!")
    return
end

-- Core Fishing Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod", 10)
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local finishRemote = net:WaitForChild("RE/FishingCompleted", 10)
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 10)
local unequipRemote = net:WaitForChild("RE/UnequipTool", 10)

-- Text Effect
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- SCAN ALL POSSIBLE REMOTES
-------------------------------------------
print("=== SCANNING ALL REMOTES ===")
local AllRemotes = {}

for _, remote in pairs(net:GetDescendants()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        table.insert(AllRemotes, {
            Name = remote.Name,
            Path = remote:GetFullName(),
            Type = remote.ClassName,
            Object = remote
        })
        print(remote.ClassName .. ": " .. remote.Name)
    end
end

-- Try to find minigame-related remotes
local MinigameRemotes = {
    Progress = net:FindFirstChild("RE/FishingMinigameProgress"),
    Click = net:FindFirstChild("RE/FishingReelInput"),
    Reel = net:FindFirstChild("RE/ReelClick"),
    Input = net:FindFirstChild("RE/FishingInput"),
    Complete = net:FindFirstChild("RE/FishingMinigameComplete"),
    Success = net:FindFirstChild("RE/FishingSuccess"),
}

print("=== MINIGAME REMOTES FOUND ===")
for name, remote in pairs(MinigameRemotes) do
    if remote then
        print(name .. ": " .. remote.Name)
    end
end

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    DebugMode = true, -- Enable debug logging
    
    -- Speed Settings
    EquipDelay = 0.3,
    ChargeDelay = 0.5,
    CastDelay = 0.3,
    
    -- Minigame Settings
    ReelSpeed = 0.1, -- Time between reel attempts
    ReelAttempts = 30, -- Number of reel attempts
    WaitAfterBite = 0.2, -- Wait before starting reel
    
    LoopDelay = 0.5,
    
    -- Perfect Cast
    PerfectCast = true,
    PerfectCastX = -0.7499996423721313,
    PerfectCastY = 1,
    
    -- Auto Sell
    SellThreshold = 60,
    SellCooldown = 60,
    LastSellTime = 0,
    
    -- Auto Favorite
    FavoriteTiers = {
        ["Secret"] = true,
        ["Mythic"] = true,
        ["Legendary"] = true
    }
}

-------------------------------------------
----- Rod Delay Configuration
-------------------------------------------
local RodDelays = {
    ["Ares Rod"] = 1.5,
    ["Angler Rod"] = 1.5,
    ["Ghostfinn Rod"] = 1.5,
    ["Astral Rod"] = 2.0,
    ["Chrome Rod"] = 2.5,
    ["Steampunk Rod"] = 3.0,
    ["Lucky Rod"] = 3.5,
    ["Midnight Rod"] = 3.5,
    ["Demascus Rod"] = 4.0,
    ["Grass Rod"] = 4.0,
    ["Luck Rod"] = 4.5,
    ["Carbon Rod"] = 4.0,
    ["Lava Rod"] = 4.5,
    ["Starter Rod"] = 5.0,
}

local CurrentRodDelay = 3.0
local CurrentRod = "Unknown"

-------------------------------------------
----- Statistics
-------------------------------------------
local Stats = {
    FishCaught = 0,
    TotalSold = 0,
    StartTime = os.time(),
    SessionTime = "0m 0s",
    Errors = 0,
    BiteDetected = 0,
    ReelAttempts = 0,
    SuccessfulCatches = 0
}

-------------------------------------------
----- Debug Logger
-------------------------------------------
local function DebugLog(category, message)
    if Config.DebugMode then
        local timestamp = os.date("%H:%M:%S")
        print(string.format("[%s][%s] %s", timestamp, category, message))
    end
end

-------------------------------------------
----- Anti-AFK System
-------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

for i,v in pairs(getconnections(LocalPlayer.Idled)) do
    v:Disable()
end

-------------------------------------------
----- Auto Reconnect
-------------------------------------------
LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Failed then
        task.wait(2)
        TeleportService:Teleport(game.PlaceId)
    end
end)

-------------------------------------------
----- FPS Boost
-------------------------------------------
local function BoostFPS()
    for _, v in pairs(game:GetDescendants()) do
        pcall(function()
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            end
        end)
    end
    
    settings().Rendering.QualityLevel = "Level01"
    
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Graphics optimized!",
        Duration = 3,
        Image = 4483362458,
    })
end

-------------------------------------------
----- Rod Detection
-------------------------------------------
local function GetCurrentRod()
    pcall(function()
        local backpack = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Backpack", 5)
        local display = backpack:WaitForChild("Display", 5)
        
        for _, tile in ipairs(display:GetChildren()) do
            pcall(function()
                local inner = tile:FindFirstChild("Inner")
                if inner then
                    local tags = inner:FindFirstChild("Tags")
                    if tags then
                        local itemName = tags:FindFirstChild("ItemName")
                        if itemName and itemName:IsA("TextLabel") then
                            local rodName = itemName.Text
                            if RodDelays[rodName] then
                                CurrentRod = rodName
                                CurrentRodDelay = RodDelays[rodName]
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-------------------------------------------
----- Anti-Stuck
-------------------------------------------
local function UnequipRod()
    pcall(function()
        unequipRemote:FireServer()
    end)
    task.wait(0.3)
end

local function ForceUnstuck()
    DebugLog("UNSTUCK", "Forcing unstuck...")
    
    UnequipRod()
    
    pcall(function()
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool:Destroy()
            end
        end
    end)
    
    pcall(function()
        Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end)
    
    task.wait(1)
end

-------------------------------------------
----- ADVANCED MINIGAME HANDLER (ALL METHODS)
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    Reeling = false
}

-- Try ALL possible methods to complete minigame
local function CompleteMinigame()
    DebugLog("MINIGAME", "Starting minigame completion...")
    FishingState.Reeling = true
    
    local attempts = 0
    local maxAttempts = Config.ReelAttempts
    
    for i = 1, maxAttempts do
        attempts = attempts + 1
        Stats.ReelAttempts = Stats.ReelAttempts + 1
        
        pcall(function()
            -- Method 1: Fire ALL found minigame remotes
            for name, remote in pairs(MinigameRemotes) do
                if remote then
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    elseif remote:IsA("RemoteFunction") then
                        remote:InvokeServer()
                    end
                end
            end
            
            -- Method 2: Fire finish remote
            finishRemote:FireServer()
            
            -- Method 3: Simulate mouse clicks
            VirtualUser:Button1Down(Vector2.new(0,0))
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0,0))
            
            -- Method 4: Simulate space key
            VirtualUser:TypeKey(" ")
            
            -- Method 5: Simulate E key (some games use this)
            VirtualUser:TypeKey("e")
        end)
        
        DebugLog("REEL", "Attempt " .. i .. "/" .. maxAttempts)
        
        task.wait(Config.ReelSpeed)
    end
    
    DebugLog("MINIGAME", "Completed " .. attempts .. " reel attempts")
    
    -- Final finish signals
    task.wait(0.3)
    for i = 1, 5 do
        pcall(function()
            finishRemote:FireServer()
        end)
        task.wait(0.05)
    end
    
    task.wait(0.5)
    FishingState.Reeling = false
end

-------------------------------------------
----- FISH BITE DETECTION
-------------------------------------------
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish then return end
    if not FishingState.Active then return end
    if FishingState.FishBit then return end
    
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end
    
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    Stats.BiteDetected = Stats.BiteDetected + 1
    DebugLog("BITE", "Fish bite detected! (#" .. Stats.BiteDetected .. ")")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    Rayfield:Notify({
        Title = "Fish Bite!",
        Content = "Starting reel...",
        Duration = 1,
        Image = 4483362458,
    })
    
    task.spawn(function()
        task.wait(Config.WaitAfterBite)
        
        local success = pcall(function()
            CompleteMinigame()
        end)
        
        if success then
            Stats.SuccessfulCatches = Stats.SuccessfulCatches + 1
            Stats.FishCaught = Stats.FishCaught + 1
            DebugLog("SUCCESS", "Fish caught! Total: " .. Stats.FishCaught)
            
            Rayfield:Notify({
                Title = "Fish Caught!",
                Content = "Total: " .. Stats.FishCaught,
                Duration = 2,
                Image = 4483362458,
            })
        else
            DebugLog("FAIL", "Failed to catch fish")
        end
        
        task.wait(0.5)
        FishingState.FishBit = false
    end)
end)

-------------------------------------------
----- MAIN AUTO FISHING LOOP
-------------------------------------------
local function StartAutoFish()
    if Config.AutoFish then 
        Rayfield:Notify({
            Title = "Already Running",
            Content = "Auto Fish is already active!",
            Duration = 2,
            Image = 4483362458,
        })
        return 
    end
    
    Config.AutoFish = true
    GetCurrentRod()
    
    DebugLog("START", "Auto Fish Started | Rod: " .. CurrentRod)
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Debug Mode: ON | Rod: " .. CurrentRod,
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            local success, err = pcall(function()
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    Humanoid = Character:WaitForChild("Humanoid")
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                    return
                end
                
                DebugLog("CYCLE", "Starting new fishing cycle")
                
                FishingState.Active = true
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                
                -- Cleanup
                UnequipRod()
                
                -- Equip Rod
                DebugLog("EQUIP", "Equipping rod slot 1")
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                -- Charge Rod
                DebugLog("CHARGE", "Charging rod")
                local timestamp = workspace:GetServerTimeNow()
                local chargeSuccess = pcall(function()
                    rodRemote:InvokeServer(timestamp)
                end)
                
                if not chargeSuccess then
                    DebugLog("ERROR", "Failed to charge rod")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    return
                end
                
                task.wait(Config.ChargeDelay)
                
                -- Cast Rod
                DebugLog("CAST", "Casting rod")
                local x, y
                if Config.PerfectCast then
                    x = Config.PerfectCastX + (math.random(-100, 100) / 100000000)
                    y = Config.PerfectCastY + (math.random(-100, 100) / 100000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                
                local castSuccess = pcall(function()
                    miniGameRemote:InvokeServer(x, y)
                end)
                
                if not castSuccess then
                    DebugLog("ERROR", "Failed to cast rod")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    return
                end
                
                task.wait(Config.CastDelay)
                
                DebugLog("WAIT", "Waiting for fish bite (max " .. CurrentRodDelay .. "s)")
                FishingState.WaitingForBite = true
                
                -- Wait for fish
                local waitStart = tick()
                local maxWait = CurrentRodDelay + 5
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.1)
                end
                
                if FishingState.FishBit then
                    DebugLog("WAIT", "Fish bit! Waiting for reel completion...")
                    local reelStart = tick()
                    while FishingState.Reeling and (tick() - reelStart) < 5 do
                        task.wait(0.1)
                    end
                else
                    DebugLog("WAIT", "No bite detected (timeout)")
                end
                
                FishingState.Active = false
                FishingState.WaitingForBite = false
            end)
            
            if not success then
                DebugLog("ERROR", "Fishing error: " .. tostring(err))
                Stats.Errors = Stats.Errors + 1
                FishingState.Active = false
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                ForceUnstuck()
                task.wait(2)
            end
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
        DebugLog("STOP", "Auto Fish Stopped")
        
        Rayfield:Notify({
            Title = "Auto Fish Stopped",
            Content = string.format("Caught: %d | Bites: %d | Success Rate: %.1f%%", 
                Stats.FishCaught, 
                Stats.BiteDetected,
                Stats.BiteDetected > 0 and (Stats.SuccessfulCatches / Stats.BiteDetected * 100) or 0),
            Duration = 5,
            Image = 4483362458,
        })
    end)
end

local function StopAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.WaitingForBite = false
    FishingState.FishBit = false
    FishingState.Reeling = false
    UnequipRod()
end

-------------------------------------------
----- AUTO SELL
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                if not _G.Replion then return end
                
                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                if not DataReplion then return end
                
                local items = DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    local unfavoritedCount = 0
                    
                    for _, item in ipairs(items) do
                        if not item.Favorited then
                            unfavoritedCount = unfavoritedCount + (item.Count or 1)
                        end
                    end
                    
                    if unfavoritedCount >= Config.SellThreshold then
                        local currentTime = os.time()
                        if currentTime - Config.LastSellTime >= Config.SellCooldown then
                            local sellRemote = net:FindFirstChild("RF/SellAllItems")
                            if sellRemote then
                                sellRemote:InvokeServer()
                                Config.LastSellTime = currentTime
                                Stats.TotalSold = Stats.TotalSold + unfavoritedCount
                                
                                Rayfield:Notify({
                                    Title = "Auto Sell",
                                    Content = "Sold " .. unfavoritedCount .. " fish!",
                                    Duration = 3,
                                    Image = 4483362458,
                                })
                            end
                        end
                    end
                end
            end)
            
            task.wait(15)
        end
    end)
end

-------------------------------------------
----- AUTO FAVORITE
-------------------------------------------
local function StartAutoFavorite()
    task.spawn(function()
        while Config.AutoFavorite do
            pcall(function()
                if not _G.Replion or not _G.ItemUtility then return end
                
                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                if not DataReplion then return end
                
                local items = DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        local itemData = _G.ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data then
                            local tier = itemData.Data.Tier
                            if Config.FavoriteTiers[tier] and not item.Favorited then
                                item.Favorited = true
                            end
                        end
                    end
                end
            end)
            
            task.wait(10)
        end
    end)
end

-------------------------------------------
----- SESSION TIMER
-------------------------------------------
task.spawn(function()
    while task.wait(1) do
        local elapsed = os.time() - Stats.StartTime
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        Stats.SessionTime = string.format("%dm %ds", minutes, seconds)
    end
end)

-------------------------------------------
----- CREATE UI
-------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Fish It - DEBUG v3.1",
    LoadingTitle = "Loading Debug Edition...",
    LoadingSubtitle = "Full Remote Scanner",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItDebug",
        FileName = "DebugConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "Debug Edition Loaded",
    Content = "Check console (F9) for detailed logs!",
    Duration = 5,
    Image = 4483362458,
})

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (Debug Mode)",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        if Value then
            StartAutoFish()
        else
            StopAutoFish()
        end
    end,
})

MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        Config.PerfectCast = Value
    end,
})

MainTab:CreateToggle({
    Name = "Debug Logging",
    CurrentValue = true,
    Flag = "DebugMode",
    Callback = function(Value)
        Config.DebugMode = Value
    end,
})

MainTab:CreateSlider({
    Name = "Reel Speed (seconds)",
    Range = {0.05, 0.3},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "ReelSpeed",
    Callback = function(Value)
        Config.ReelSpeed = Value
    end,
})

MainTab:CreateSlider({
    Name = "Reel Attempts",
    Range = {10, 50},
    Increment = 5,
    CurrentValue = 30,
    Flag = "ReelAttempts",
    Callback = function(Value)
        Config.ReelAttempts = Value
    end,
})

local StatsLabel = MainTab:CreateLabel("Loading stats...")

task.spawn(function()
    while task.wait(2) do
        local successRate = 0
        if Stats.BiteDetected > 0 then
            successRate = math.floor((Stats.SuccessfulCatches / Stats.BiteDetected) * 100)
        end
        
        StatsLabel:Set(string.format("Fish: %d | Bites: %d | Success: %d%% | Reels: %d | Time: %s", 
            Stats.FishCaught, Stats.BiteDetected, successRate, Stats.ReelAttempts, Stats.SessionTime))
    end
end)

MainTab:CreateButton({
    Name = "Force Unstuck",
    Callback = function()
        ForceUnstuck()
    end,
})

MainTab:CreateButton({
    Name = "Print All Remotes",
    Callback = function()
        print("=== ALL AVAILABLE REMOTES ===")
        for _, info in ipairs(AllRemotes) do
            print(info.Type .. ": " .. info.Name .. " | Path: " .. info.Path)
        end
        Rayfield:Notify({
            Title = "Remotes Printed",
            Content = "Check console (F9) for full list",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-------------------------------------------
----- AUTOMATION TAB
-------------------------------------------
local AutoTab = Window:CreateTab("⚙️ Automation", 4483362458)

AutoTab:CreateToggle({
    Name = "Auto Sell Fish",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(Value)
        Config.AutoSell = Value
        if Value then StartAutoSell() end
    end,
})

AutoTab:CreateSlider({
    Name = "Sell Threshold",
    Range = {20, 100},
    Increment = 5,
    CurrentValue = 60,
    Flag = "SellThreshold",
    Callback = function(Value)
        Config.SellThreshold = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Auto Favorite Rare Fish",
    CurrentValue = false,
    Flag = "AutoFavToggle",
    Callback = function(Value)
        Config.AutoFavorite = Value
        if Value then StartAutoFavorite() end
    end,
})

AutoTab:CreateToggle({Name = "Favorite: Secret", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Secret"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Mythic", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Mythic"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Legendary", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Legendary"] = v end})

-------------------------------------------
----- UTILITY TAB
-------------------------------------------
local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)

UtilityTab:CreateButton({
    Name = "Boost FPS",
    Callback = function() BoostFPS() end,
})

UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

UtilityTab:CreateButton({
    Name = "Detect Current Rod",
    Callback = function()
        GetCurrentRod()
        Rayfield:Notify({
            Title = "Rod Info",
            Content = "Rod: " .. CurrentRod .. " | Delay: " .. CurrentRodDelay .. "s",
            Duration = 5,
            Image = 4483362458,
        })
    end,
})

UtilityTab:CreateButton({
    Name = "Reset Statistics",
    Callback = function()
        Stats.FishCaught = 0
        Stats.TotalSold = 0
        Stats.Errors = 0
        Stats.BiteDetected = 0
        Stats.ReelAttempts = 0
        Stats.SuccessfulCatches = 0
        Stats.StartTime = os.time()
        Rayfield:Notify({
            Title = "Stats Reset",
            Content = "All statistics cleared!",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-------------------------------------------
----- SETTINGS TAB
-------------------------------------------
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateLabel("Version: 3.1 Debug Edition")
SettingsTab:CreateLabel("Status: Auto-Detect Remotes")
SettingsTab:CreateLabel("Debug: Press F9 for console")
SettingsTab:CreateLabel("Total Remotes: " .. #AllRemotes)

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        StopAutoFish()
        task.wait(0.5)
        Rayfield:Destroy()
    end,
})

-------------------------------------------
----- INITIALIZATION
-------------------------------------------
GetCurrentRod()
DebugLog("INIT", "Script initialized successfully")
DebugLog("INIT", "Rod: " .. CurrentRod .. " | Delay: " .. CurrentRodDelay .. "s")
DebugLog("INIT", "Total remotes found: " .. #AllRemotes)
DebugLog("INIT", "Press F9 to see debug console")

print("=================================")
print("Fish It Debug v3.1 Loaded")
print("Rod: " .. CurrentRod)
print("Total Remotes: " .. #AllRemotes)
print("Debug Mode: ACTIVE")
print("=================================")
