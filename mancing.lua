-------------------------------------------
----- Fish It ADVANCED DEBUG v7.0
----- Complete Inventory Tracking
----- Real-Time Fish Detection
----- Full Debug System
-------------------------------------------

_G.FishItVersion = "7.0 ADVANCED DEBUG"

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-------------------------------------------
----- Services
-------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-------------------------------------------
----- Character
-------------------------------------------
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-------------------------------------------
----- Net Remotes
-------------------------------------------
local net = ReplicatedStorage:WaitForChild("Packages", 10)
    :WaitForChild("_Index", 10)
    :WaitForChild("sleitnick_net@0.2.0", 10)
    :WaitForChild("net", 10)

local rodRemote = net:WaitForChild("RF/ChargeFishingRod", 10)
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local finishRemote = net:WaitForChild("RE/FishingCompleted", 10)
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 10)
local unequipRemote = net:WaitForChild("RE/UnequipTool", 10)
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- Load Replion
-------------------------------------------
task.spawn(function()
    task.wait(3)
    pcall(function()
        if not _G.Replion then
            _G.Replion = require(ReplicatedStorage.Packages._Index["nightcycle_replica@0.2.2"].replica)
        end
        if not _G.ItemUtility then
            _G.ItemUtility = require(ReplicatedStorage.Shared.Modules.ItemUtility)
        end
    end)
end)

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    DebugMode = true, -- Advanced debug logging
    
    EquipDelay = 0.4,
    ChargeDelay = 0.5,
    CastDelay = 0.4,
    
    -- Minigame
    WaitForGUI = 0.8,
    ClickSpeed = 0.08,
    TotalClicks = 30,
    AfterMinigameWait = 2.0, -- Increased for reliability
    
    LoopDelay = 0.6,
    
    PerfectCast = true,
    PerfectCastX = -0.7499996423721313,
    PerfectCastY = 1,
    
    SellThreshold = 60,
    SellCooldown = 60,
    LastSellTime = 0,
    
    FavoriteTiers = {
        ["Secret"] = true,
        ["Mythic"] = true,
        ["Legendary"] = true
    }
}

-------------------------------------------
----- Rod Delays
-------------------------------------------
local RodDelays = {
    ["Ares Rod"] = 2.0,
    ["Angler Rod"] = 2.0,
    ["Ghostfinn Rod"] = 2.0,
    ["Astral Rod"] = 2.5,
    ["Chrome Rod"] = 3.0,
    ["Steampunk Rod"] = 3.5,
    ["Lucky Rod"] = 4.0,
    ["Midnight Rod"] = 4.0,
    ["Demascus Rod"] = 4.5,
    ["Grass Rod"] = 4.5,
    ["Luck Rod"] = 5.0,
    ["Carbon Rod"] = 4.5,
    ["Lava Rod"] = 5.0,
    ["Starter Rod"] = 5.5,
}

local CurrentRodDelay = 4.0
local CurrentRod = "Unknown"

-------------------------------------------
----- Statistics
-------------------------------------------
local Stats = {
    FishCaught = 0,
    RealFishCaught = 0, -- Based on inventory tracking
    TotalSold = 0,
    StartTime = os.time(),
    SessionTime = "0m 0s",
    BiteDetected = 0,
    MinigameAttempts = 0,
    LastFishName = "None",
    FishPerMinute = 0
}

-------------------------------------------
----- Debug Logger
-------------------------------------------
local function DebugLog(category, message, color)
    if not Config.DebugMode then return end
    
    local timestamp = os.date("%H:%M:%S")
    local colorCode = color or ""
    print(string.format("[%s][%s] %s", timestamp, category, message))
end

-------------------------------------------
----- INVENTORY TRACKER (CRITICAL!)
-------------------------------------------
local InventoryCache = {}
local InventoryLoaded = false

local function GetInventoryData()
    local inventory = {}
    
    pcall(function()
        if not _G.Replion then return end
        
        local DataReplion = _G.Replion.Client:WaitReplion("Data")
        if not DataReplion then return end
        
        local items = DataReplion:Get({"Inventory","Items"})
        
        if type(items) == "table" then
            for _, item in ipairs(items) do
                if item.Id then
                    local fishData = {
                        Id = item.Id,
                        Count = item.Count or 1,
                        Favorited = item.Favorited or false
                    }
                    
                    -- Try to get fish name
                    if _G.ItemUtility then
                        local itemData = _G.ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data then
                            fishData.Name = itemData.Data.DisplayName or item.Id
                            fishData.Tier = itemData.Data.Tier or "Unknown"
                        end
                    end
                    
                    inventory[item.Id] = fishData
                end
            end
        end
    end)
    
    return inventory
end

local function CheckInventoryChange()
    if not InventoryLoaded then return end
    
    local newInventory = GetInventoryData()
    local fishAdded = {}
    
    -- Compare with cache
    for id, fishData in pairs(newInventory) do
        local oldData = InventoryCache[id]
        
        if not oldData then
            -- New fish
            table.insert(fishAdded, {
                Name = fishData.Name or "Unknown Fish",
                Tier = fishData.Tier or "Common",
                Count = fishData.Count
            })
            DebugLog("INVENTORY", "NEW FISH: " .. (fishData.Name or id) .. " x" .. fishData.Count)
        elseif oldData.Count < fishData.Count then
            -- Count increased
            local added = fishData.Count - oldData.Count
            table.insert(fishAdded, {
                Name = fishData.Name or "Unknown Fish",
                Tier = fishData.Tier or "Common",
                Count = added
            })
            DebugLog("INVENTORY", "FISH ADDED: " .. (fishData.Name or id) .. " +" .. added .. " (total: " .. fishData.Count .. ")")
        end
    end
    
    -- Update cache
    InventoryCache = newInventory
    
    -- Update stats
    if #fishAdded > 0 then
        for _, fish in ipairs(fishAdded) do
            Stats.RealFishCaught = Stats.RealFishCaught + fish.Count
            Stats.LastFishName = fish.Name .. " (" .. fish.Tier .. ")"
            
            Rayfield:Notify({
                Title = "🐟 Fish Added!",
                Content = fish.Name .. " x" .. fish.Count,
                Duration = 2,
                Image = 4483362458,
            })
        end
    end
    
    return #fishAdded > 0
end

-- Initialize inventory
task.spawn(function()
    task.wait(5)
    InventoryCache = GetInventoryData()
    InventoryLoaded = true
    DebugLog("INIT", "Inventory tracker initialized")
end)

-------------------------------------------
----- Anti-AFK
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
                v.Enabled = false
            end
        end)
    end
    settings().Rendering.QualityLevel = "Level01"
    Rayfield:Notify({Title = "FPS Boost", Content = "Optimized!", Duration = 2, Image = 4483362458})
end

-------------------------------------------
----- Rod Detection
-------------------------------------------
local function GetCurrentRod()
    pcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack", 5):WaitForChild("Display", 5)
        for _, tile in ipairs(display:GetChildren()) do
            pcall(function()
                local itemName = tile.Inner.Tags.ItemName
                if itemName and itemName:IsA("TextLabel") then
                    local rodName = itemName.Text
                    if RodDelays[rodName] then
                        CurrentRod = rodName
                        CurrentRodDelay = RodDelays[rodName]
                        DebugLog("ROD", "Detected: " .. rodName)
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
    pcall(function() unequipRemote:FireServer() end)
    task.wait(0.2)
end

-------------------------------------------
----- MINIGAME GUI DETECTOR
-------------------------------------------
local function FindMinigameGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    for _, name in ipairs({"FishingMinigame", "Minigame", "ReelGame", "FishGame", "CatchGame"}) do
        local gui = playerGui:FindFirstChild(name)
        if gui and gui:IsA("ScreenGui") and gui.Enabled then
            DebugLog("GUI", "Found by name: " .. name)
            return gui
        end
    end
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "Rayfield" then
            local hasButton = gui:FindFirstChildOfClass("TextButton", true)
            if hasButton then
                DebugLog("GUI", "Found by search: " .. gui.Name)
                return gui
            end
        end
    end
    
    DebugLog("GUI", "No GUI found")
    return nil
end

local function SolveMinigame(button)
    DebugLog("MINIGAME", "Clicking button: " .. button.Name)
    
    local clicksSuccess = 0
    
    for i = 1, Config.TotalClicks do
        local success = pcall(function()
            for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                conn:Fire()
            end
            for _, conn in pairs(getconnections(button.MouseButton1Down)) do
                conn:Fire()
            end
            
            local pos = button.AbsolutePosition
            local size = button.AbsoluteSize
            local center = Vector2.new(pos.X + size.X/2, pos.Y + size.Y/2)
            VirtualUser:Button1Down(center)
            task.wait(0.005)
            VirtualUser:Button1Up(center)
            VirtualUser:TypeKey(" ")
            
            clicksSuccess = clicksSuccess + 1
        end)
        
        task.wait(Config.ClickSpeed)
        
        if not button.Visible or not button.Parent then
            DebugLog("MINIGAME", "Button gone after " .. clicksSuccess .. " clicks")
            break
        end
    end
    
    DebugLog("MINIGAME", "Total clicks: " .. clicksSuccess)
end

-------------------------------------------
----- MINIGAME HANDLER
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    ProcessingMinigame = false
}

local function CompleteMinigame()
    if FishingState.ProcessingMinigame then return end
    FishingState.ProcessingMinigame = true
    Stats.MinigameAttempts = Stats.MinigameAttempts + 1
    
    DebugLog("MINIGAME", "========== STARTING MINIGAME #" .. Stats.MinigameAttempts .. " ==========")
    
    -- Get inventory before minigame
    local inventoryBefore = GetInventoryData()
    local fishCountBefore = 0
    for _, fish in pairs(inventoryBefore) do
        fishCountBefore = fishCountBefore + fish.Count
    end
    DebugLog("MINIGAME", "Inventory before: " .. fishCountBefore .. " fish")
    
    -- Wait for GUI
    task.wait(Config.WaitForGUI)
    
    -- Find and solve GUI
    local gui = FindMinigameGUI()
    
    if gui then
        local button = gui:FindFirstChildOfClass("TextButton", true)
        if button then
            SolveMinigame(button)
        else
            DebugLog("MINIGAME", "No button in GUI, fallback")
        end
    else
        DebugLog("MINIGAME", "No GUI, using direct method")
    end
    
    -- Fallback method
    DebugLog("MINIGAME", "Executing fallback spam...")
    for i = 1, Config.TotalClicks do
        pcall(function()
            finishRemote:FireServer()
            VirtualUser:Button1Down(Vector2.new(0,0))
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0,0))
            VirtualUser:TypeKey(" ")
        end)
        task.wait(Config.ClickSpeed)
    end
    
    -- Send finish signals
    DebugLog("MINIGAME", "Sending " .. 5 .. " finish signals...")
    for i = 1, 5 do
        pcall(function()
            finishRemote:FireServer()
        end)
        task.wait(0.1)
    end
    
    -- Wait for server
    DebugLog("MINIGAME", "Waiting " .. Config.AfterMinigameWait .. "s for server...")
    task.wait(Config.AfterMinigameWait)
    
    -- Check inventory after
    local fishAdded = CheckInventoryChange()
    
    local inventoryAfter = GetInventoryData()
    local fishCountAfter = 0
    for _, fish in pairs(inventoryAfter) do
        fishCountAfter = fishCountAfter + fish.Count
    end
    
    local diff = fishCountAfter - fishCountBefore
    DebugLog("MINIGAME", "Inventory after: " .. fishCountAfter .. " fish (+" .. diff .. ")")
    
    if fishAdded or diff > 0 then
        DebugLog("MINIGAME", "========== SUCCESS! Fish added to inventory ==========")
    else
        DebugLog("MINIGAME", "========== WARNING! No fish detected in inventory ==========")
    end
    
    FishingState.ProcessingMinigame = false
end

-------------------------------------------
----- FISH BITE DETECTION
-------------------------------------------
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish or not FishingState.Active or FishingState.FishBit then return end
    if not data or not data.TextData or data.TextData.EffectType ~= "Exclaim" then return end
    
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    Stats.BiteDetected = Stats.BiteDetected + 1
    DebugLog("BITE", "========== FISH BITE #" .. Stats.BiteDetected .. " DETECTED! ==========")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    task.spawn(function()
        task.wait(0.4)
        
        pcall(function()
            CompleteMinigame()
        end)
        
        Stats.FishCaught = Stats.FishCaught + 1
        
        task.wait(0.3)
        FishingState.FishBit = false
    end)
end)

-------------------------------------------
----- MAIN AUTO FISHING
-------------------------------------------
local function StartAutoFish()
    if Config.AutoFish then return end
    Config.AutoFish = true
    GetCurrentRod()
    
    DebugLog("START", "==================== AUTO FISH STARTED ====================")
    DebugLog("START", "Rod: " .. CurrentRod .. " | Delay: " .. CurrentRodDelay .. "s")
    DebugLog("START", "Debug Mode: " .. (Config.DebugMode and "ON" or "OFF"))
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Debug Mode ON | Rod: " .. CurrentRod,
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        local cycleCount = 0
        
        while Config.AutoFish do
            pcall(function()
                cycleCount = cycleCount + 1
                
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    Humanoid = Character:WaitForChild("Humanoid")
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                    return
                end
                
                DebugLog("CYCLE", "---------- Cycle #" .. cycleCount .. " ----------")
                
                FishingState.Active = true
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                
                UnequipRod()
                
                DebugLog("CYCLE", "Equipping rod...")
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                DebugLog("CYCLE", "Charging rod...")
                local timestamp = workspace:GetServerTimeNow()
                pcall(function() rodRemote:InvokeServer(timestamp) end)
                task.wait(Config.ChargeDelay)
                
                DebugLog("CYCLE", "Casting rod...")
                local x = Config.PerfectCastX + (math.random(-100, 100) / 100000000)
                local y = Config.PerfectCastY + (math.random(-100, 100) / 100000000)
                
                pcall(function() miniGameRemote:InvokeServer(x, y) end)
                task.wait(Config.CastDelay)
                
                DebugLog("CYCLE", "Waiting for bite (max " .. CurrentRodDelay .. "s)...")
                FishingState.WaitingForBite = true
                
                local waitStart = tick()
                local maxWait = CurrentRodDelay + 3
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.2)
                end
                
                if FishingState.FishBit then
                    while FishingState.ProcessingMinigame do
                        task.wait(0.2)
                    end
                else
                    DebugLog("CYCLE", "No bite (timeout)")
                end
                
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
        DebugLog("STOP", "==================== AUTO FISH STOPPED ====================")
    end)
end

local function StopAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.WaitingForBite = false
    FishingState.FishBit = false
    FishingState.ProcessingMinigame = false
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
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    local count = 0
                    for _, item in ipairs(items) do
                        if not item.Favorited then count = count + (item.Count or 1) end
                    end
                    
                    if count >= Config.SellThreshold and os.time() - Config.LastSellTime >= Config.SellCooldown then
                        local sellRemote = net:FindFirstChild("RF/SellAllItems")
                        if sellRemote then
                            DebugLog("SELL", "Selling " .. count .. " fish...")
                            sellRemote:InvokeServer()
                            Config.LastSellTime = os.time()
                            Stats.TotalSold = Stats.TotalSold + count
                            
                            -- Refresh inventory
                            task.wait(1)
                            InventoryCache = GetInventoryData()
                            
                            Rayfield:Notify({Title = "Auto Sell", Content = "Sold " .. count .. " fish!", Duration = 2, Image = 4483362458})
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
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        local itemData = _G.ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data and Config.FavoriteTiers[itemData.Data.Tier] and not item.Favorited then
                            item.Favorited = true
                            DebugLog("FAVORITE", "Favorited: " .. (itemData.Data.DisplayName or item.Id))
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
        Stats.SessionTime = string.format("%dm %ds", math.floor(elapsed / 60), elapsed % 60)
        
        if elapsed > 0 then
            Stats.FishPerMinute = (Stats.RealFishCaught / elapsed) * 60
        end
    end
end)

-------------------------------------------
----- UI
-------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Fish It - DEBUG v7.0",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Advanced Debug System",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItDebug", FileName = "DebugConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

Rayfield:Notify({Title = "DEBUG v7.0 Loaded", Content = "Full inventory tracking active!", Duration = 3, Image = 4483362458})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (Debug Mode)",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Debug Logging (F9 Console)",
    CurrentValue = true,
    Callback = function(v) Config.DebugMode = v end,
})

MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Callback = function(v) Config.PerfectCast = v end,
})

MainTab:CreateSlider({
    Name = "After Minigame Wait",
    Range = {1, 4},
    Increment = 0.5,
    CurrentValue = 2.0,
    Callback = function(v) Config.AfterMinigameWait = v end,
})

MainTab:CreateSlider({
    Name = "Loop Delay",
    Range = {0.3, 2},
    Increment = 0.1,
    CurrentValue = 0.6,
    Callback = function(v) Config.LoopDelay = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")
local LastFishLabel = MainTab:CreateLabel("Last Fish: None")

task.spawn(function()
    while task.wait(1) do
        local successRate = Stats.BiteDetected > 0 and math.floor((Stats.RealFishCaught / Stats.BiteDetected) * 100) or 0
        StatsLabel:Set(string.format("🐟 Real Fish: %d | 🎣 Bites: %d | ✅ %d%% | ⚡ %.1f/min | ⏱️ %s", 
            Stats.RealFishCaught, Stats.BiteDetected, successRate, Stats.FishPerMinute, Stats.SessionTime))
        LastFishLabel:Set("Last Fish: " .. Stats.LastFishName)
    end
end)

MainTab:CreateButton({Name = "Force Unstuck", Callback = function() UnequipRod() end})
MainTab:CreateButton({Name = "Check Inventory Now", Callback = function()
    local inv = GetInventoryData()
    local total = 0
    for _, fish in pairs(inv) do
        total = total + fish.Count
    end
    Rayfield:Notify({Title = "Inventory", Content = "Total fish: " .. total, Duration = 3, Image = 4483362458})
end})

local AutoTab = Window:CreateTab("⚙️ Automation", 4483362458)

AutoTab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) Config.AutoSell = v; if v then StartAutoSell() end end})
AutoTab:CreateSlider({Name = "Sell Threshold", Range = {20, 100}, Increment = 5, CurrentValue = 60, Callback = function(v) Config.SellThreshold = v end})
AutoTab:CreateToggle({Name = "Auto Favorite", CurrentValue = false, Callback = function(v) Config.AutoFavorite = v; if v then StartAutoFavorite() end end})

AutoTab:CreateToggle({Name = "Favorite: Secret", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Secret"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Mythic", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Mythic"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Legendary", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Legendary"] = v end})

local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)

UtilityTab:CreateButton({Name = "Boost FPS", Callback = function() BoostFPS() end})
UtilityTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
UtilityTab:CreateButton({Name = "Detect Rod", Callback = function() 
    GetCurrentRod()
    Rayfield:Notify({Title = "Rod Info", Content = CurrentRod, Duration = 2, Image = 4483362458})
end})

UtilityTab:CreateButton({Name = "Reset Stats", Callback = function()
    Stats.FishCaught = 0
    Stats.RealFishCaught = 0
    Stats.TotalSold = 0
    Stats.BiteDetected = 0
    Stats.MinigameAttempts = 0
    Stats.StartTime = os.time()
    Rayfield:Notify({Title = "Stats Reset", Content = "Cleared!", Duration = 2, Image = 4483362458})
end})

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("Version: 7.0 ADVANCED DEBUG")
SettingsTab:CreateLabel("Feature: Inventory Tracking")
SettingsTab:CreateLabel("Feature: Real-Time Detection")
SettingsTab:CreateLabel("Press F9 for detailed logs")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() StopAutoFish(); task.wait(0.5); Rayfield:Destroy() end})

GetCurrentRod()
print("=================================")
print("Fish It ADVANCED DEBUG v7.0")
print("Version: " .. _G.FishItVersion)
print("Rod: " .. CurrentRod)
print("Debug Mode: ACTIVE")
print("Inventory Tracking: ACTIVE")
print("Press F9 to see detailed logs")
print("=================================")
