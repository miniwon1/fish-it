-------------------------------------------
----- Fish It ULTIMATE Edition - No Stuck
----- Anti-Stuck System + Working Teleport
----- Version: 2.2
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
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- Character handling with refresh
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update character reference on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2) -- Wait for character to fully load
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

-- Fishing Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod", 10)
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local finishRemote = net:WaitForChild("RE/FishingCompleted", 10)
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 10)
local unequipRemote = net:WaitForChild("RE/UnequipTool", 10) -- ADDED: Unequip remote

-- Text Effect for Fish Detection
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    AntiStuck = true, -- NEW: Anti-stuck system
    
    -- Speed Settings
    EquipDelay = 0.3,
    ChargeDelay = 0.5,
    CastDelay = 0.3,
    CatchDelay = 0.15,
    LoopDelay = 0.5,
    UnstuckDelay = 10, -- Check for stuck every 10 seconds
    
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
    UnstuckCount = 0
}

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

task.spawn(function()
    while task.wait(10) do
        if not LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(game.PlaceId)
        end
    end
end)

-------------------------------------------
----- FPS Boost
-------------------------------------------
local function BoostFPS()
    local decals = game:GetDescendants()
    for _, v in pairs(decals) do
        pcall(function()
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            end
        end)
    end
    
    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
    
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    settings().Rendering.QualityLevel = "Level01"
    
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Graphics optimized!",
        Duration = 3,
        Image = 4483362458,
    })
end

-------------------------------------------
----- ANTI-STUCK SYSTEM (NEW)
-------------------------------------------
local StuckDetector = {
    LastPosition = nil,
    StuckTime = 0,
    CheckInterval = 5
}

local function UnequipRod()
    pcall(function()
        unequipRemote:FireServer()
    end)
    task.wait(0.5)
end

local function ForceUnstuck()
    Stats.UnstuckCount = Stats.UnstuckCount + 1
    
    Rayfield:Notify({
        Title = "Anti-Stuck",
        Content = "Unstucking character...",
        Duration = 2,
        Image = 4483362458,
    })
    
    -- Method 1: Unequip all tools
    UnequipRod()
    
    -- Method 2: Delete fishing rod from character if stuck
    pcall(function()
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name:lower(), "rod") then
                tool:Destroy()
            end
        end
    end)
    
    -- Method 3: Reset humanoid state
    pcall(function()
        Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end)
    
    -- Method 4: Small position adjustment
    pcall(function()
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    end)
    
    task.wait(1)
end

-- Anti-stuck monitor
task.spawn(function()
    while task.wait(StuckDetector.CheckInterval) do
        if Config.AntiStuck and Config.AutoFish then
            pcall(function()
                local currentPos = HumanoidRootPart.Position
                
                if StuckDetector.LastPosition then
                    local distance = (currentPos - StuckDetector.LastPosition).Magnitude
                    
                    -- If character hasn't moved and is not fishing actively
                    if distance < 0.5 then
                        StuckDetector.StuckTime = StuckDetector.StuckTime + StuckDetector.CheckInterval
                        
                        if StuckDetector.StuckTime >= Config.UnstuckDelay then
                            ForceUnstuck()
                            StuckDetector.StuckTime = 0
                        end
                    else
                        StuckDetector.StuckTime = 0
                    end
                end
                
                StuckDetector.LastPosition = currentPos
            end)
        end
    end
end)

-------------------------------------------
----- Rod Detection
-------------------------------------------
local function GetCurrentRod()
    local success = pcall(function()
        local backpack = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Backpack", 5)
        local display = backpack:WaitForChild("Display", 5)
        
        for _, tile in ipairs(display:GetChildren()) do
            if tile:IsA("Frame") or tile:IsA("GuiObject") then
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
                                    return true
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
    
    if not success then
        CurrentRod = "Unknown"
        CurrentRodDelay = 3.0
    end
end

local function WatchRodChanges()
    pcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        display.ChildAdded:Connect(function()
            task.wait(0.2)
            GetCurrentRod()
        end)
    end)
end

WatchRodChanges()
GetCurrentRod()

-------------------------------------------
----- INSTANT CATCH SYSTEM
-------------------------------------------
local FishingState = {
    Active = false,
    Catching = false,
    LastCatchTime = 0,
    CastTime = 0
}

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish then return end
    if not FishingState.Active then return end
    if FishingState.Catching then return end
    
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end
    
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    local currentTime = tick()
    if currentTime - FishingState.LastCatchTime < 0.5 then return end
    
    FishingState.Catching = true
    FishingState.LastCatchTime = currentTime
    
    task.spawn(function()
        for i = 1, 3 do
            pcall(function()
                finishRemote:FireServer()
            end)
            task.wait(Config.CatchDelay)
        end
        
        Stats.FishCaught = Stats.FishCaught + 1
        task.wait(0.3)
        FishingState.Catching = false
    end)
end)

-------------------------------------------
----- FIXED AUTO FISHING WITH ANTI-STUCK
-------------------------------------------
local function StartFastAutoFish()
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
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Rod: " .. CurrentRod .. " | Anti-Stuck: ON",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            local success, err = pcall(function()
                -- Verify character exists
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    Humanoid = Character:WaitForChild("Humanoid")
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                    return
                end
                
                -- Check if stuck (timeout protection)
                local timeout = tick()
                FishingState.Active = true
                FishingState.CastTime = tick()
                
                -- Step 0: Ensure previous rod is unequipped
                UnequipRod()
                task.wait(0.2)
                
                -- Step 1: Equip Rod
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                -- Step 2: Charge Rod
                local timestamp = workspace:GetServerTimeNow()
                local chargeSuccess = pcall(function()
                    rodRemote:InvokeServer(timestamp)
                end)
                
                if not chargeSuccess then
                    warn("Failed to charge rod, unstucking...")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    task.wait(1)
                    return
                end
                
                task.wait(Config.ChargeDelay)
                
                -- Step 3: Cast Rod
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
                    warn("Failed to cast rod, unstucking...")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    task.wait(1)
                    return
                end
                
                task.wait(Config.CastDelay)
                
                -- Wait for fish with timeout protection
                local waitStart = tick()
                local maxWaitTime = CurrentRodDelay + 3
                
                while FishingState.Active and (tick() - waitStart) < maxWaitTime do
                    task.wait(0.1)
                end
                
                -- Timeout protection
                if (tick() - waitStart) >= maxWaitTime then
                    warn("Fishing timeout, forcing unstuck...")
                    ForceUnstuck()
                end
                
                FishingState.Active = false
            end)
            
            if not success then
                warn("Fishing error:", err)
                Stats.Errors = Stats.Errors + 1
                FishingState.Active = false
                FishingState.Catching = false
                ForceUnstuck()
                task.wait(2)
            end
            
            task.wait(Config.LoopDelay)
        end
        
        -- Cleanup on stop
        UnequipRod()
        
        Rayfield:Notify({
            Title = "Auto Fish Stopped",
            Content = string.format("Caught: %d | Unstuck: %d", Stats.FishCaught, Stats.UnstuckCount),
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

local function StopFastAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.Catching = false
    UnequipRod()
end

-------------------------------------------
----- FIXED TELEPORT SYSTEM
-------------------------------------------
local function SafeTeleport(position, locationName)
    local success = pcall(function()
        -- Stop auto fish during teleport
        local wasAutoFishing = Config.AutoFish
        if wasAutoFishing then
            StopFastAutoFish()
            task.wait(0.5)
        end
        
        -- Unequip rod before teleport
        UnequipRod()
        task.wait(0.3)
        
        -- Get fresh character reference
        local char = workspace:FindFirstChild("Characters")
        if not char then
            error("Characters folder not found")
        end
        
        char = char:FindFirstChild(LocalPlayer.Name)
        if not char then
            error("Character not found in workspace")
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            error("HumanoidRootPart not found")
        end
        
        -- Disable character collision temporarily
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        -- Teleport with offset
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
        task.wait(0.5)
        
        -- Re-enable collision
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
        
        Rayfield:Notify({
            Title = "Teleported",
            Content = "Now at: " .. locationName,
            Duration = 3,
            Image = 4483362458,
        })
        
        -- Resume auto fish if was active
        if wasAutoFishing then
            task.wait(1)
            StartFastAutoFish()
        end
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "Teleport Failed",
            Content = "Please try again in a moment",
            Duration = 3,
            Image = 4483362458,
        })
    end
end

-------------------------------------------
----- AUTO SELL
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            local success = pcall(function()
                if not _G.Replion then
                    task.wait(5)
                    return
                end
                
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
            
            if not success then
                warn("Auto sell error")
            end
            
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
            local success = pcall(function()
                if not _G.Replion or not _G.ItemUtility then 
                    task.wait(5)
                    return 
                end
                
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
            
            if not success then
                warn("Auto favorite error")
            end
            
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
    Name = "Fish It - ULTIMATE v2.2",
    LoadingTitle = "Loading Ultimate Edition...",
    LoadingSubtitle = "Anti-Stuck + Fixed Teleport",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItUltimate",
        FileName = "UltimateConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "Ultimate Edition Loaded",
    Content = "Anti-Stuck System Active!",
    Duration = 5,
    Image = 4483362458,
})

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)
local MainSection = MainTab:CreateSection("Ultimate Fishing System")

local AutoFishToggle = MainTab:CreateToggle({
    Name = "Auto Fish (Anti-Stuck)",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(Value)
        if Value then
            StartFastAutoFish()
        else
            StopFastAutoFish()
        end
    end,
})

local PerfectCastToggle = MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        Config.PerfectCast = Value
    end,
})

local AntiStuckToggle = MainTab:CreateToggle({
    Name = "Anti-Stuck System",
    CurrentValue = true,
    Flag = "AntiStuckToggle",
    Callback = function(Value)
        Config.AntiStuck = Value
    end,
})

local SpeedSection = MainTab:CreateSection("Speed Configuration")

local LoopDelaySlider = MainTab:CreateSlider({
    Name = "Loop Delay (Stability)",
    Range = {0.3, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "LoopDelay",
    Callback = function(Value)
        Config.LoopDelay = Value
    end,
})

local UnstuckDelaySlider = MainTab:CreateSlider({
    Name = "Unstuck Check Interval",
    Range = {5, 30},
    Increment = 5,
    CurrentValue = 10,
    Flag = "UnstuckDelay",
    Callback = function(Value)
        Config.UnstuckDelay = Value
    end,
})

local InfoSection = MainTab:CreateSection("Session Statistics")

local StatsLabel = MainTab:CreateLabel("Loading stats...")

task.spawn(function()
    while task.wait(2) do
        StatsLabel:Set(string.format("Fish: %d | Sold: %d | Unstuck: %d | Time: %s", 
            Stats.FishCaught, Stats.TotalSold, Stats.UnstuckCount, Stats.SessionTime))
    end
end)

local ManualSection = MainTab:CreateSection("Manual Controls")

MainTab:CreateButton({
    Name = "Force Unstuck Now",
    Callback = function()
        ForceUnstuck()
    end,
})

MainTab:CreateButton({
    Name = "Unequip Rod",
    Callback = function()
        UnequipRod()
        Rayfield:Notify({
            Title = "Unequipped",
            Content = "Rod unequipped successfully",
            Duration = 2,
            Image = 4483362458,
        })
    end,
})

-------------------------------------------
----- AUTOMATION TAB
-------------------------------------------
local AutoTab = Window:CreateTab("⚙️ Automation", 4483362458)
local AutoSection = AutoTab:CreateSection("Auto Features")

local AutoSellToggle = AutoTab:CreateToggle({
    Name = "Auto Sell Fish",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(Value)
        Config.AutoSell = Value
        if Value then
            StartAutoSell()
            Rayfield:Notify({
                Title = "Auto Sell",
                Content = "Auto Sell Enabled",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local SellThresholdSlider = AutoTab:CreateSlider({
    Name = "Sell Threshold (Fish Count)",
    Range = {20, 100},
    Increment = 5,
    CurrentValue = 60,
    Flag = "SellThreshold",
    Callback = function(Value)
        Config.SellThreshold = Value
    end,
})

local AutoFavToggle = AutoTab:CreateToggle({
    Name = "Auto Favorite Rare Fish",
    CurrentValue = false,
    Flag = "AutoFavToggle",
    Callback = function(Value)
        Config.AutoFavorite = Value
        if Value then
            StartAutoFavorite()
            Rayfield:Notify({
                Title = "Auto Favorite",
                Content = "Protecting rare fish!",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

local FavSection = AutoTab:CreateSection("Favorite Tiers")

AutoTab:CreateToggle({
    Name = "Favorite: Secret",
    CurrentValue = true,
    Flag = "FavSecret",
    Callback = function(Value)
        Config.FavoriteTiers["Secret"] = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Favorite: Mythic",
    CurrentValue = true,
    Flag = "FavMythic",
    Callback = function(Value)
        Config.FavoriteTiers["Mythic"] = Value
    end,
})

AutoTab:CreateToggle({
    Name = "Favorite: Legendary",
    CurrentValue = true,
    Flag = "FavLegendary",
    Callback = function(Value)
        Config.FavoriteTiers["Legendary"] = Value
    end,
})

-------------------------------------------
----- TELEPORT TAB (FIXED)
-------------------------------------------
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)
local TPSection = TeleportTab:CreateSection("Safe Island Teleport")

local Islands = {
    ["Kohana (Spawn)"] = Vector3.new(-658, 3, 719),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Coral Reefs"] = Vector3.new(-3095, 1, 2177),
    ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
    ["Kohana Volcano"] = Vector3.new(-519, 24, 189),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773),
    ["Crater Island"] = Vector3.new(968, 1, 4854),
}

local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = {"Kohana (Spawn)", "Tropical Grove", "Coral Reefs", "Esoteric Depths", 
               "Kohana Volcano", "Winter Fest", "Stingray Shores", "Crater Island"},
    CurrentOption = "Kohana (Spawn)",
    Flag = "IslandSelect",
    Callback = function(Option)
        local pos = Islands[Option]
        if pos then
            SafeTeleport(pos, Option)
        end
    end,
})

TeleportTab:CreateParagraph({
    Title = "How to Use",
    Content = "Select island from dropdown. Auto-fish will pause during teleport and resume after."
})

-------------------------------------------
----- UTILITY TAB
-------------------------------------------
local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)
local UtilSection = UtilityTab:CreateSection("Performance")

local FPSBoostButton = UtilityTab:CreateButton({
    Name = "Boost FPS",
    Callback = function()
        BoostFPS()
    end,
})

local ServerSection = UtilityTab:CreateSection("Server")

local RejoinButton = UtilityTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

local ServerHopButton = UtilityTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        pcall(function()
            local Http = HttpService
            local TPS = TeleportService
            local Api = "https://games.roblox.com/v1/games/"
            
            local _place = game.PlaceId
            local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
            
            function ListServers(cursor)
                local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
                return Http:JSONDecode(Raw)
            end
            
            local Server, Next
            repeat
                local Servers = ListServers(Next)
                Server = Servers.data[1]
                Next = Servers.nextPageCursor
            until Server
            
            TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
        end)
    end,
})

local RodSection = UtilityTab:CreateSection("Rod Information")

local RodInfoButton = UtilityTab:CreateButton({
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

local DebugSection = UtilityTab:CreateSection("Debug")

UtilityTab:CreateButton({
    Name = "Reset Statistics",
    Callback = function()
        Stats.FishCaught = 0
        Stats.TotalSold = 0
        Stats.Errors = 0
        Stats.UnstuckCount = 0
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
local SettingsSection = SettingsTab:CreateSection("Script Information")

SettingsTab:CreateLabel("Version: 2.2 Ultimate Edition")
SettingsTab:CreateLabel("Status: Anti-Stuck Active")
SettingsTab:CreateLabel("Teleport: Fixed & Safe")
SettingsTab:CreateLabel("UI: Rayfield")

local DestroySection = SettingsTab:CreateSection("Unload")

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Config.AutoFish = false
        Config.AutoSell = false
        Config.AutoFavorite = false
        UnequipRod()
        task.wait(0.5)
        Rayfield:Destroy()
    end,
})

-------------------------------------------
----- INITIALIZATION
-------------------------------------------
GetCurrentRod()
print("=================================")
print("Fish It Ultimate v2.2 Loaded")
print("Rod: " .. CurrentRod)
print("Rod Delay: " .. CurrentRodDelay .. "s")
print("Anti-Stuck: ACTIVE")
print("Teleport: FIXED")
print("=================================")
