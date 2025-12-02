-------------------------------------------
----- Fish It COMPLETE Edition v3.0
----- FIXED: Complete Minigame System
----- Proper Fish Catching Mechanic
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

-- Fishing Remotes (COMPLETE LIST)
local rodRemote = net:WaitForChild("RF/ChargeFishingRod", 10)
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local finishRemote = net:WaitForChild("RE/FishingCompleted", 10)
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 10)
local unequipRemote = net:WaitForChild("RE/UnequipTool", 10)

-- Minigame Remotes (CRITICAL)
local reelClickRemote = net:FindFirstChild("RE/FishingReelInput") or net:FindFirstChild("RE/ReelClick")
local minigameProgressRemote = net:FindFirstChild("RE/FishingMinigameProgress")

-- Text Effect
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    AntiStuck = true,
    
    -- Speed Settings
    EquipDelay = 0.3,
    ChargeDelay = 0.5,
    CastDelay = 0.3,
    
    -- Minigame Settings (CRITICAL)
    AutoClick = true,
    ClickSpeed = 0.08, -- Click every 0.08s (fast clicking)
    MinigameClicks = 25, -- Number of clicks for minigame
    MinigameWaitTime = 3, -- Max time to wait for minigame
    
    LoopDelay = 0.5,
    UnstuckDelay = 10,
    
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
    UnstuckCount = 0,
    MinigameSuccess = 0,
    MinigameFail = 0
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
    
    local Lighting = game:GetService("Lighting")
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
----- Anti-Stuck System
-------------------------------------------
local function UnequipRod()
    pcall(function()
        unequipRemote:FireServer()
    end)
    task.wait(0.3)
end

local function ForceUnstuck()
    Stats.UnstuckCount = Stats.UnstuckCount + 1
    
    Rayfield:Notify({
        Title = "Anti-Stuck",
        Content = "Forcing unstuck...",
        Duration = 2,
        Image = 4483362458,
    })
    
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
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
    end)
    
    task.wait(1)
end

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
----- MINIGAME SYSTEM (CRITICAL FIX)
-------------------------------------------
local MinigameState = {
    Active = false,
    Completed = false,
    ClickCount = 0
}

-- Function to simulate clicking for minigame
local function PerformMinigameClicks()
    MinigameState.Active = true
    MinigameState.ClickCount = 0
    MinigameState.Completed = false
    
    print("[MINIGAME] Starting fast click sequence...")
    
    -- Fast click sequence
    for i = 1, Config.MinigameClicks do
        if not MinigameState.Active then break end
        
        pcall(function()
            -- Try multiple methods to register clicks
            
            -- Method 1: Fire reel click remote if exists
            if reelClickRemote then
                reelClickRemote:FireServer()
            end
            
            -- Method 2: Virtual mouse click
            VirtualUser:Button1Down(Vector2.new(0,0))
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0,0))
            
            -- Method 3: Simulate KeyCode.Space press (some games use this)
            VirtualUser:TypeKey(" ")
            
            MinigameState.ClickCount = MinigameState.ClickCount + 1
        end)
        
        task.wait(Config.ClickSpeed)
    end
    
    print("[MINIGAME] Completed " .. MinigameState.ClickCount .. " clicks")
    
    -- Give server time to process
    task.wait(0.5)
    
    -- Final finish signal
    for i = 1, 3 do
        pcall(function()
            finishRemote:FireServer()
        end)
        task.wait(0.1)
    end
    
    MinigameState.Completed = true
    MinigameState.Active = false
end

-------------------------------------------
----- FISH DETECTION & CATCH SYSTEM
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    LastCatchTime = 0
}

-- Detect fish bite (Exclaim effect)
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish then return end
    if not FishingState.Active then return end
    if FishingState.FishBit then return end
    
    -- Validate data
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end
    
    -- Check if on player's head
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    print("[FISH] Fish bite detected! Starting minigame...")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    -- Perform minigame (fast clicking)
    task.spawn(function()
        local success = pcall(function()
            PerformMinigameClicks()
        end)
        
        if success and MinigameState.Completed then
            Stats.FishCaught = Stats.FishCaught + 1
            Stats.MinigameSuccess = Stats.MinigameSuccess + 1
            print("[SUCCESS] Fish caught successfully!")
        else
            Stats.MinigameFail = Stats.MinigameFail + 1
            print("[FAIL] Minigame failed")
        end
        
        task.wait(0.5)
        FishingState.FishBit = false
    end)
end)

-------------------------------------------
----- COMPLETE AUTO FISHING SYSTEM
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
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Rod: " .. CurrentRod .. " | Minigame: ON",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            local success, err = pcall(function()
                -- Verify character
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    Humanoid = Character:WaitForChild("Humanoid")
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                    return
                end
                
                print("[FISHING] Starting new fishing cycle...")
                
                FishingState.Active = true
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                
                -- Step 0: Cleanup previous rod
                UnequipRod()
                
                -- Step 1: Equip Rod
                print("[FISHING] Equipping rod...")
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                -- Step 2: Charge Rod
                print("[FISHING] Charging rod...")
                local timestamp = workspace:GetServerTimeNow()
                local chargeSuccess = pcall(function()
                    rodRemote:InvokeServer(timestamp)
                end)
                
                if not chargeSuccess then
                    warn("[ERROR] Failed to charge rod")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    return
                end
                
                task.wait(Config.ChargeDelay)
                
                -- Step 3: Cast Rod
                print("[FISHING] Casting rod...")
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
                    warn("[ERROR] Failed to cast rod")
                    ForceUnstuck()
                    Stats.Errors = Stats.Errors + 1
                    return
                end
                
                task.wait(Config.CastDelay)
                
                print("[FISHING] Waiting for fish bite...")
                FishingState.WaitingForBite = true
                
                -- Wait for fish bite with timeout
                local waitStart = tick()
                local maxWait = CurrentRodDelay + 5
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.1)
                end
                
                -- If fish bit, wait for minigame completion
                if FishingState.FishBit then
                    print("[FISHING] Fish bit! Waiting for minigame...")
                    local minigameStart = tick()
                    while MinigameState.Active and (tick() - minigameStart) < Config.MinigameWaitTime do
                        task.wait(0.1)
                    end
                else
                    print("[FISHING] No bite detected (timeout)")
                end
                
                FishingState.Active = false
                FishingState.WaitingForBite = false
            end)
            
            if not success then
                warn("[ERROR] Fishing error:", err)
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
        
        Rayfield:Notify({
            Title = "Auto Fish Stopped",
            Content = string.format("Caught: %d | Success: %d%%", 
                Stats.FishCaught, 
                Stats.MinigameSuccess > 0 and math.floor((Stats.MinigameSuccess / (Stats.MinigameSuccess + Stats.MinigameFail)) * 100) or 0),
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

local function StopAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.WaitingForBite = false
    FishingState.FishBit = false
    MinigameState.Active = false
    UnequipRod()
end

-------------------------------------------
----- SAFE TELEPORT
-------------------------------------------
local function SafeTeleport(position, locationName)
    local success = pcall(function()
        local wasAutoFishing = Config.AutoFish
        if wasAutoFishing then
            StopAutoFish()
            task.wait(0.5)
        end
        
        UnequipRod()
        task.wait(0.3)
        
        local char = workspace:FindFirstChild("Characters")
        if not char then error("Characters folder not found") end
        
        char = char:FindFirstChild(LocalPlayer.Name)
        if not char then error("Character not found") end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then error("HRP not found") end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
        task.wait(0.5)
        
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
        
        if wasAutoFishing then
            task.wait(1)
            StartAutoFish()
        end
    end)
    
    if not success then
        Rayfield:Notify({
            Title = "Teleport Failed",
            Content = "Please try again",
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
            pcall(function()
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
    Name = "Fish It - COMPLETE v3.0",
    LoadingTitle = "Loading Complete Edition...",
    LoadingSubtitle = "Full Minigame System",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItComplete",
        FileName = "CompleteConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "Complete Edition Loaded",
    Content = "Minigame system active!",
    Duration = 5,
    Image = 4483362458,
})

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)
local MainSection = MainTab:CreateSection("Complete Fishing System")

local AutoFishToggle = MainTab:CreateToggle({
    Name = "Auto Fish (With Minigame)",
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

local PerfectCastToggle = MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        Config.PerfectCast = Value
    end,
})

local MinigameSection = MainTab:CreateSection("Minigame Settings")

local ClickSpeedSlider = MainTab:CreateSlider({
    Name = "Click Speed (Lower = Faster)",
    Range = {0.05, 0.2},
    Increment = 0.01,
    CurrentValue = 0.08,
    Flag = "ClickSpeed",
    Callback = function(Value)
        Config.ClickSpeed = Value
    end,
})

local ClickCountSlider = MainTab:CreateSlider({
    Name = "Minigame Clicks",
    Range = {15, 40},
    Increment = 5,
    CurrentValue = 25,
    Flag = "ClickCount",
    Callback = function(Value)
        Config.MinigameClicks = Value
    end,
})

local SpeedSection = MainTab:CreateSection("General Settings")

local LoopDelaySlider = MainTab:CreateSlider({
    Name = "Loop Delay",
    Range = {0.3, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "LoopDelay",
    Callback = function(Value)
        Config.LoopDelay = Value
    end,
})

local InfoSection = MainTab:CreateSection("Session Statistics")

local StatsLabel = MainTab:CreateLabel("Loading stats...")

task.spawn(function()
    while task.wait(2) do
        local successRate = 0
        if Stats.MinigameSuccess + Stats.MinigameFail > 0 then
            successRate = math.floor((Stats.MinigameSuccess / (Stats.MinigameSuccess + Stats.MinigameFail)) * 100)
        end
        
        StatsLabel:Set(string.format("Fish: %d | Sold: %d | Success: %d%% | Time: %s", 
            Stats.FishCaught, Stats.TotalSold, successRate, Stats.SessionTime))
    end
end)

local ManualSection = MainTab:CreateSection("Manual Controls")

MainTab:CreateButton({
    Name = "Force Unstuck",
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
            Content = "Rod unequipped",
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
        end
    end,
})

local SellThresholdSlider = AutoTab:CreateSlider({
    Name = "Sell Threshold",
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
        end
    end,
})

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
----- TELEPORT TAB
-------------------------------------------
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)

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

-------------------------------------------
----- UTILITY TAB
-------------------------------------------
local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)

UtilityTab:CreateButton({
    Name = "Boost FPS",
    Callback = function()
        BoostFPS()
    end,
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
        Stats.UnstuckCount = 0
        Stats.MinigameSuccess = 0
        Stats.MinigameFail = 0
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

SettingsTab:CreateLabel("Version: 3.0 Complete Edition")
SettingsTab:CreateLabel("Status: Full Minigame System")
SettingsTab:CreateLabel("Mechanics: Click + Finish")
SettingsTab:CreateLabel("UI: Rayfield")

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
print("=================================")
print("Fish It Complete v3.0 Loaded")
print("Rod: " .. CurrentRod)
print("Minigame System: ACTIVE")
print("Fast Click: " .. Config.MinigameClicks .. " clicks")
print("=================================")
