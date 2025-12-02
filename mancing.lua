-------------------------------------------
----- Fish It CRITICAL FIX v7.1
----- Fixed Replion Loading
----- Fixed Race Conditions
----- Guaranteed Fish Detection
-------------------------------------------

_G.FishItVersion = "7.1 CRITICAL FIX"

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
----- CRITICAL: Load Replion PROPERLY
-------------------------------------------
local ReplionLoaded = false
local ItemUtilityLoaded = false

task.spawn(function()
    print("[INIT] Loading Replion...")
    
    local attempts = 0
    while not ReplionLoaded and attempts < 10 do
        attempts = attempts + 1
        
        local success = pcall(function()
            if not _G.Replion then
                local replionPath = ReplicatedStorage:FindFirstChild("Packages")
                if replionPath then
                    replionPath = replionPath:FindFirstChild("_Index")
                    if replionPath then
                        for _, v in pairs(replionPath:GetChildren()) do
                            if v.Name:match("replica") then
                                local replica = v:FindFirstChild("replica")
                                if replica then
                                    _G.Replion = require(replica)
                                    print("[INIT] ✅ Replion loaded from:", v.Name)
                                    ReplionLoaded = true
                                    break
                                end
                            end
                        end
                    end
                end
            else
                ReplionLoaded = true
                print("[INIT] ✅ Replion already loaded")
            end
        end)
        
        if not success then
            print("[INIT] ⚠️ Attempt " .. attempts .. " failed, retrying...")
            task.wait(1)
        end
    end
    
    if not ReplionLoaded then
        print("[INIT] ❌ Failed to load Replion after " .. attempts .. " attempts")
        return
    end
    
    -- Load ItemUtility
    task.wait(1)
    pcall(function()
        if not _G.ItemUtility then
            local itemUtil = ReplicatedStorage:FindFirstChild("Shared")
            if itemUtil then
                itemUtil = itemUtil:FindFirstChild("Modules")
                if itemUtil then
                    itemUtil = itemUtil:FindFirstChild("ItemUtility")
                    if itemUtil then
                        _G.ItemUtility = require(itemUtil)
                        ItemUtilityLoaded = true
                        print("[INIT] ✅ ItemUtility loaded")
                    end
                end
            end
        else
            ItemUtilityLoaded = true
            print("[INIT] ✅ ItemUtility already loaded")
        end
    end)
    
    print("[INIT] Replion Status:", ReplionLoaded and "✅" or "❌")
    print("[INIT] ItemUtility Status:", ItemUtilityLoaded and "✅" or "❌")
end)

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    DebugMode = true,
    
    EquipDelay = 0.4,
    ChargeDelay = 0.5,
    CastDelay = 0.4,
    
    WaitForGUI = 0.8,
    ClickSpeed = 0.08,
    TotalClicks = 30,
    AfterMinigameWait = 2.5, -- Increased for safety
    
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
    RealFishCaught = 0,
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
local function DebugLog(category, message)
    if not Config.DebugMode then return end
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s][%s] %s", timestamp, category, message))
end

-------------------------------------------
----- IMPROVED INVENTORY TRACKER
-------------------------------------------
local InventoryCache = {}
local InventoryLoaded = false

local function GetInventoryData()
    local inventory = {}
    
    if not ReplionLoaded or not _G.Replion then
        DebugLog("INVENTORY", "❌ Replion not loaded yet")
        return inventory
    end
    
    local success, err = pcall(function()
        local DataReplion = _G.Replion.Client:WaitReplion("Data", 5)
        if not DataReplion then
            DebugLog("INVENTORY", "❌ DataReplion not found")
            return
        end
        
        local items = DataReplion:Get({"Inventory","Items"})
        
        if type(items) ~= "table" then
            DebugLog("INVENTORY", "❌ Items is not a table: " .. type(items))
            return
        end
        
        DebugLog("INVENTORY", "Found " .. #items .. " items in inventory")
        
        for _, item in ipairs(items) do
            if item.Id then
                local fishData = {
                    Id = item.Id,
                    Count = item.Count or 1,
                    Favorited = item.Favorited or false
                }
                
                if ItemUtilityLoaded and _G.ItemUtility then
                    local itemData = _G.ItemUtility:GetItemData(item.Id)
                    if itemData and itemData.Data then
                        fishData.Name = itemData.Data.DisplayName or item.Id
                        fishData.Tier = itemData.Data.Tier or "Unknown"
                    end
                end
                
                inventory[item.Id] = fishData
            end
        end
    end)
    
    if not success then
        DebugLog("INVENTORY", "❌ Error getting inventory: " .. tostring(err))
    end
    
    return inventory
end

local function CheckInventoryChange()
    if not InventoryLoaded then
        DebugLog("INVENTORY", "Inventory not initialized yet")
        return false
    end
    
    local newInventory = GetInventoryData()
    local fishAdded = {}
    
    for id, fishData in pairs(newInventory) do
        local oldData = InventoryCache[id]
        
        if not oldData then
            table.insert(fishAdded, {
                Name = fishData.Name or id,
                Tier = fishData.Tier or "Common",
                Count = fishData.Count
            })
            DebugLog("INVENTORY", "✅ NEW FISH: " .. (fishData.Name or id) .. " x" .. fishData.Count)
        elseif oldData.Count < fishData.Count then
            local added = fishData.Count - oldData.Count
            table.insert(fishAdded, {
                Name = fishData.Name or id,
                Tier = fishData.Tier or "Common",
                Count = added
            })
            DebugLog("INVENTORY", "✅ FISH ADDED: " .. (fishData.Name or id) .. " +" .. added)
        end
    end
    
    InventoryCache = newInventory
    
    if #fishAdded > 0 then
        for _, fish in ipairs(fishAdded) do
            Stats.RealFishCaught = Stats.RealFishCaught + fish.Count
            Stats.LastFishName = fish.Name .. " (" .. fish.Tier .. ")"
            
            Rayfield:Notify({
                Title = "🐟 " .. fish.Name,
                Content = "+" .. fish.Count .. " | Total: " .. Stats.RealFishCaught,
                Duration = 2,
                Image = 4483362458,
            })
        end
    end
    
    return #fishAdded > 0
end

-- Initialize after delay
task.spawn(function()
    task.wait(8) -- Wait longer for Replion to load
    
    local retries = 0
    while not ReplionLoaded and retries < 5 do
        DebugLog("INIT", "Waiting for Replion... (" .. retries .. "/5)")
        task.wait(2)
        retries = retries + 1
    end
    
    if ReplionLoaded then
        InventoryCache = GetInventoryData()
        InventoryLoaded = true
        
        local totalFish = 0
        for _, fish in pairs(InventoryCache) do
            totalFish = totalFish + fish.Count
        end
        
        DebugLog("INIT", "✅ Inventory tracker initialized | Total fish: " .. totalFish)
    else
        DebugLog("INIT", "❌ Inventory tracker failed - Replion not loaded")
    end
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
----- MINIGAME GUI
-------------------------------------------
local function FindMinigameGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    for _, name in ipairs({"FishingMinigame", "Minigame", "ReelGame", "FishGame", "CatchGame"}) do
        local gui = playerGui:FindFirstChild(name)
        if gui and gui:IsA("ScreenGui") and gui.Enabled then
            DebugLog("GUI", "Found: " .. name)
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
    
    return nil
end

local function SolveMinigame(button)
    DebugLog("MINIGAME", "Solving button: " .. button.Name)
    
    for i = 1, Config.TotalClicks do
        pcall(function()
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
        end)
        
        task.wait(Config.ClickSpeed)
        
        if not button.Visible or not button.Parent then
            DebugLog("MINIGAME", "Button disappeared after " .. i .. " clicks")
            break
        end
    end
end

-------------------------------------------
----- MINIGAME HANDLER (NO RACE CONDITION)
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    ProcessingMinigame = false
}

local MinigameLock = false -- CRITICAL: Prevent overlapping minigames

local function CompleteMinigame()
    -- CRITICAL: Check lock to prevent race condition
    if MinigameLock or FishingState.ProcessingMinigame then
        DebugLog("MINIGAME", "⚠️ Already processing, skipping")
        return
    end
    
    MinigameLock = true
    FishingState.ProcessingMinigame = true
    Stats.MinigameAttempts = Stats.MinigameAttempts + 1
    
    DebugLog("MINIGAME", "========== MINIGAME #" .. Stats.MinigameAttempts .. " ==========")
    
    -- Get inventory count before
    local fishCountBefore = 0
    for _, fish in pairs(InventoryCache) do
        fishCountBefore = fishCountBefore + fish.Count
    end
    DebugLog("MINIGAME", "Inventory before: " .. fishCountBefore .. " fish")
    
    -- Wait for GUI
    task.wait(Config.WaitForGUI)
    
    -- Solve minigame
    local gui = FindMinigameGUI()
    
    if gui then
        local button = gui:FindFirstChildOfClass("TextButton", true)
        if button then
            SolveMinigame(button)
        end
    else
        DebugLog("MINIGAME", "No GUI, using fallback")
    end
    
    -- Fallback spam
    DebugLog("MINIGAME", "Executing fallback...")
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
    
    -- Finish signals
    DebugLog("MINIGAME", "Sending finish signals...")
    for i = 1, 5 do
        pcall(function()
            finishRemote:FireServer()
        end)
        task.wait(0.1)
    end
    
    -- CRITICAL: Wait for server
    DebugLog("MINIGAME", "Waiting " .. Config.AfterMinigameWait .. "s for server...")
    task.wait(Config.AfterMinigameWait)
    
    -- Check inventory
    local fishAdded = CheckInventoryChange()
    
    local fishCountAfter = 0
    for _, fish in pairs(InventoryCache) do
        fishCountAfter = fishCountAfter + fish.Count
    end
    
    local diff = fishCountAfter - fishCountBefore
    DebugLog("MINIGAME", "Inventory after: " .. fishCountAfter .. " fish (+" .. diff .. ")")
    
    if fishAdded or diff > 0 then
        DebugLog("MINIGAME", "========== ✅ SUCCESS! ==========")
    else
        DebugLog("MINIGAME", "========== ⚠️ WARNING: No fish detected ==========")
    end
    
    -- CRITICAL: Release lock
    FishingState.ProcessingMinigame = false
    MinigameLock = false
end

-------------------------------------------
----- FISH BITE
-------------------------------------------
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish or not FishingState.Active or FishingState.FishBit then return end
    if not data or not data.TextData or data.TextData.EffectType ~= "Exclaim" then return end
    
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    Stats.BiteDetected = Stats.BiteDetected + 1
    DebugLog("BITE", "========== FISH BITE #" .. Stats.BiteDetected .. " ==========")
    
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
----- MAIN AUTO FISHING (NO OVERLAP)
-------------------------------------------
local function StartAutoFish()
    if Config.AutoFish then return end
    Config.AutoFish = true
    GetCurrentRod()
    
    DebugLog("START", "==================== AUTO FISH STARTED ====================")
    DebugLog("START", "Replion: " .. (ReplionLoaded and "✅" or "❌"))
    DebugLog("START", "ItemUtility: " .. (ItemUtilityLoaded and "✅" or "❌"))
    DebugLog("START", "Rod: " .. CurrentRod)
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Rod: " .. CurrentRod,
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        local cycleCount = 0
        
        while Config.AutoFish do
            -- CRITICAL: Wait for previous minigame to complete
            while MinigameLock or FishingState.ProcessingMinigame do
                DebugLog("CYCLE", "⏸️ Waiting for minigame to complete...")
                task.wait(0.5)
            end
            
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
                
                DebugLog("CYCLE", "Waiting for bite (max " .. (CurrentRodDelay + 3) .. "s)...")
                FishingState.WaitingForBite = true
                
                local waitStart = tick()
                local maxWait = CurrentRodDelay + 3
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.2)
                end
                
                if FishingState.FishBit then
                    DebugLog("CYCLE", "Fish bit! Waiting for minigame...")
                    -- Wait for minigame to complete (handled by lock)
                else
                    DebugLog("CYCLE", "No bite (timeout)")
                end
                
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
        DebugLog("STOP", "==================== STOPPED ====================")
    end)
end

local function StopAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.WaitingForBite = false
    FishingState.FishBit = false
    FishingState.ProcessingMinigame = false
    MinigameLock = false
    UnequipRod()
end

-------------------------------------------
----- AUTO SELL & FAVORITE (Same as before, shortened for space)
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                if not ReplionLoaded or not _G.Replion then return end
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
                            sellRemote:InvokeServer()
                            Config.LastSellTime = os.time()
                            Stats.TotalSold = Stats.TotalSold + count
                            task.wait(1)
                            InventoryCache = GetInventoryData()
                            Rayfield:Notify({Title = "Sold", Content = count .. " fish", Duration = 2, Image = 4483362458})
                        end
                    end
                end
            end)
            task.wait(15)
        end
    end)
end

local function StartAutoFavorite()
    task.spawn(function()
        while Config.AutoFavorite do
            pcall(function()
                if not ReplionLoaded or not _G.Replion or not _G.ItemUtility then return end
                local DataReplion = _G.Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        local itemData = _G.ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data and Config.FavoriteTiers[itemData.Data.Tier] and not item.Favorited then
                            item.Favorited = true
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
----- UI (Simplified)
-------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Fish It v7.1 FIXED",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Critical Fixes Applied",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItFixed", FileName = "FixedConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Debug Logs (F9)",
    CurrentValue = true,
    Callback = function(v) Config.DebugMode = v end,
})

MainTab:CreateSlider({
    Name = "After Minigame Wait",
    Range = {1, 4},
    Increment = 0.5,
    CurrentValue = 2.5,
    Callback = function(v) Config.AfterMinigameWait = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")
local LastFishLabel = MainTab:CreateLabel("Last Fish: None")
local SystemLabel = MainTab:CreateLabel("System: Initializing...")

task.spawn(function()
    while task.wait(1) do
        local successRate = Stats.BiteDetected > 0 and math.floor((Stats.RealFishCaught / Stats.BiteDetected) * 100) or 0
        StatsLabel:Set(string.format("🐟 %d | 🎣 %d | ✅ %d%% | ⚡ %.1f/min | ⏱️ %s", 
            Stats.RealFishCaught, Stats.BiteDetected, successRate, Stats.FishPerMinute, Stats.SessionTime))
        LastFishLabel:Set("Last: " .. Stats.LastFishName)
        
        local sysStatus = ""
        if ReplionLoaded then sysStatus = sysStatus .. "✅ Replion " else sysStatus = sysStatus .. "❌ Replion " end
        if InventoryLoaded then sysStatus = sysStatus .. "✅ Inventory" else sysStatus = sysStatus .. "❌ Inventory" end
        SystemLabel:Set(sysStatus)
    end
end)

local AutoTab = Window:CreateTab("⚙️ Auto", 4483362458)
AutoTab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) Config.AutoSell = v; if v then StartAutoSell() end end})
AutoTab:CreateToggle({Name = "Auto Favorite", CurrentValue = false, Callback = function(v) Config.AutoFavorite = v; if v then StartAutoFavorite() end end})

local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)
UtilityTab:CreateButton({Name = "Force Unstuck", Callback = function() UnequipRod() end})
UtilityTab:CreateButton({Name = "Check Inventory", Callback = function()
    local total = 0
    for _, fish in pairs(InventoryCache) do
        total = total + fish.Count
    end
    Rayfield:Notify({Title = "Inventory", Content = "Total: " .. total, Duration = 2, Image = 4483362458})
end})
UtilityTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})

GetCurrentRod()
print("=================================")
print("Fish It v7.1 CRITICAL FIX")
print("Fixes: Replion loading, Race conditions")
print("Press F9 for detailed logs")
print("=================================")
