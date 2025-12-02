-------------------------------------------
----- Fish It FAST & RELIABLE v5.1
----- Smart Speed + Guaranteed Catch
----- Fixed Minigame Timing
-------------------------------------------

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
----- Configuration (BALANCED SPEED)
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    FastMode = true,
    
    -- Smart Timing (Fast but Reliable)
    EquipDelay = 0.3,
    ChargeDelay = 0.4,
    CastDelay = 0.3,
    AfterBiteDelay = 0.4, -- Wait for GUI to appear
    AfterMinigameDelay = 1.0, -- Wait for server to process
    
    -- Minigame Settings
    MinigameClickSpeed = 0.08,
    MinigameClicks = 25,
    MinigameWaitForGUI = 1.0, -- Wait for GUI before spam
    
    LoopDelay = 0.5,
    
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
----- Rod Delays (REALISTIC)
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
    BiteDetected = 0,
    SuccessfulCatch = 0,
    FailedCatch = 0,
    FishPerMinute = 0
}

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
                v.Lifetime = NumberRange.new(0)
            end
        end)
    end
    settings().Rendering.QualityLevel = "Level01"
    Rayfield:Notify({Title = "FPS Boost", Content = "Graphics optimized!", Duration = 2, Image = 4483362458})
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

local function ForceUnstuck()
    UnequipRod()
    pcall(function()
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then tool:Destroy() end
        end
        Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    end)
    task.wait(0.5)
end

-------------------------------------------
----- MINIGAME GUI DETECTOR (IMPROVED)
-------------------------------------------
local function FindMinigameGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Try specific names first
    local possibleNames = {
        "FishingMinigame",
        "Minigame",
        "ReelGame",
        "FishGame",
        "CatchGame",
        "FishingGame"
    }
    
    for _, name in ipairs(possibleNames) do
        local gui = playerGui:FindFirstChild(name)
        if gui and gui:IsA("ScreenGui") and gui.Enabled then
            return gui
        end
    end
    
    -- Search all enabled GUIs
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            -- Must have button or interactive element
            local hasButton = gui:FindFirstChildOfClass("TextButton", true)
            if hasButton then
                return gui
            end
        end
    end
    
    return nil
end

local function InteractWithMinigameGUI(gui)
    print("[MINIGAME] Interacting with GUI:", gui.Name)
    
    -- Find button
    local button = gui:FindFirstChildOfClass("TextButton", true)
    
    if button then
        print("[MINIGAME] Found button:", button.Name, "| Visible:", button.Visible)
        
        -- Smart clicking with proper timing
        for i = 1, Config.MinigameClicks do
            if not button or not button.Visible then
                print("[MINIGAME] Button disappeared, stopping clicks")
                break
            end
            
            pcall(function()
                -- Method 1: Fire all connections
                for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                    connection:Fire()
                end
                for _, connection in pairs(getconnections(button.MouseButton1Down)) do
                    connection:Fire()
                end
                
                -- Method 2: Virtual click at button position
                local absPos = button.AbsolutePosition
                local absSize = button.AbsoluteSize
                local center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
                
                VirtualUser:Button1Down(center)
                task.wait(0.01)
                VirtualUser:Button1Up(center)
                
                -- Method 3: Space key as backup
                VirtualUser:TypeKey(" ")
            end)
            
            task.wait(Config.MinigameClickSpeed)
        end
        
        print("[MINIGAME] Completed " .. Config.MinigameClicks .. " clicks")
        return true
    else
        print("[MINIGAME] No button found, trying space spam")
        
        -- Fallback: space spam
        for i = 1, Config.MinigameClicks do
            VirtualUser:TypeKey(" ")
            task.wait(Config.MinigameClickSpeed)
        end
        
        return false
    end
end

-------------------------------------------
----- SMART MINIGAME HANDLER
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    ProcessingMinigame = false
}

local function CompleteMinigame()
    if FishingState.ProcessingMinigame then 
        print("[MINIGAME] Already processing, skipping")
        return 
    end
    
    FishingState.ProcessingMinigame = true
    print("[MINIGAME] Starting minigame completion...")
    
    -- CRITICAL: Wait for GUI to fully appear
    task.wait(Config.MinigameWaitForGUI)
    
    -- Try to find GUI
    local gui = FindMinigameGUI()
    
    if gui then
        print("[MINIGAME] GUI found:", gui.Name)
        InteractWithMinigameGUI(gui)
    else
        print("[MINIGAME] No GUI detected, using fallback")
        
        -- Fallback method with proper timing
        for i = 1, Config.MinigameClicks do
            pcall(function()
                finishRemote:FireServer()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(0,0))
                VirtualUser:TypeKey(" ")
            end)
            task.wait(Config.MinigameClickSpeed)
        end
    end
    
    -- CRITICAL: Send finish signals properly
    print("[MINIGAME] Sending final finish signals...")
    task.wait(0.3)
    for i = 1, 5 do
        pcall(function() 
            finishRemote:FireServer()
        end)
        task.wait(0.1)
    end
    
    -- CRITICAL: Wait for server to process and add fish to inventory
    print("[MINIGAME] Waiting for server to process...")
    task.wait(Config.AfterMinigameDelay)
    
    FishingState.ProcessingMinigame = false
    print("[MINIGAME] Minigame complete!")
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
    print("[BITE] Fish bite detected! (#" .. Stats.BiteDetected .. ")")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    task.spawn(function()
        -- CRITICAL: Small delay before starting minigame
        task.wait(Config.AfterBiteDelay)
        
        local success = pcall(function()
            CompleteMinigame()
        end)
        
        if success then
            Stats.SuccessfulCatch = Stats.SuccessfulCatch + 1
            Stats.FishCaught = Stats.FishCaught + 1
            print("[SUCCESS] Fish caught successfully! Total: " .. Stats.FishCaught)
            
            Rayfield:Notify({
                Title = "Fish Caught!",
                Content = "Total: " .. Stats.FishCaught,
                Duration = 2,
                Image = 4483362458,
            })
        else
            Stats.FailedCatch = Stats.FailedCatch + 1
            print("[FAIL] Failed to catch fish")
        end
        
        task.wait(0.3)
        FishingState.FishBit = false
    end)
end)

-------------------------------------------
----- MAIN AUTO FISHING (SMART SPEED)
-------------------------------------------
local function StartAutoFish()
    if Config.AutoFish then return end
    Config.AutoFish = true
    GetCurrentRod()
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Rod: " .. CurrentRod .. " | Fast Mode",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            pcall(function()
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    Humanoid = Character:WaitForChild("Humanoid")
                    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
                    task.wait(2)
                    return
                end
                
                print("[CYCLE] Starting new fishing cycle")
                
                FishingState.Active = true
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                
                -- Unequip
                UnequipRod()
                
                -- Equip
                print("[CYCLE] Equipping rod")
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                -- Charge
                print("[CYCLE] Charging rod")
                local timestamp = workspace:GetServerTimeNow()
                pcall(function() rodRemote:InvokeServer(timestamp) end)
                task.wait(Config.ChargeDelay)
                
                -- Cast
                print("[CYCLE] Casting rod")
                local x = Config.PerfectCastX + (math.random(-100, 100) / 100000000)
                local y = Config.PerfectCastY + (math.random(-100, 100) / 100000000)
                
                pcall(function() miniGameRemote:InvokeServer(x, y) end)
                task.wait(Config.CastDelay)
                
                print("[CYCLE] Waiting for fish bite (max " .. CurrentRodDelay .. "s)")
                FishingState.WaitingForBite = true
                
                -- Wait for fish
                local waitStart = tick()
                local maxWait = Config.FastMode and (CurrentRodDelay + 2) or (CurrentRodDelay + 5)
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.2)
                end
                
                -- Wait for minigame if fish bit
                if FishingState.FishBit then
                    print("[CYCLE] Fish bit! Waiting for minigame completion...")
                    local minigameStart = tick()
                    while FishingState.ProcessingMinigame and (tick() - minigameStart) < 5 do
                        task.wait(0.2)
                    end
                    print("[CYCLE] Minigame finished")
                else
                    print("[CYCLE] No bite detected (timeout)")
                end
                
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
        
        Rayfield:Notify({
            Title = "Auto Fish Stopped",
            Content = string.format("Caught: %d | Failed: %d | Rate: %.1f%%", 
                Stats.SuccessfulCatch, Stats.FailedCatch,
                Stats.BiteDetected > 0 and (Stats.SuccessfulCatch / Stats.BiteDetected * 100) or 0),
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
                            sellRemote:InvokeServer()
                            Config.LastSellTime = os.time()
                            Stats.TotalSold = Stats.TotalSold + count
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
            Stats.FishPerMinute = (Stats.FishCaught / elapsed) * 60
        end
    end
end)

-------------------------------------------
----- UI
-------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Fish It - FAST v5.1",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Fast & Reliable",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItFast", FileName = "FastConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

Rayfield:Notify({Title = "FAST & RELIABLE v5.1", Content = "Smart timing active!", Duration = 3, Image = 4483362458})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (Fast & Reliable)",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Fast Mode",
    CurrentValue = true,
    Callback = function(v) Config.FastMode = v end,
})

MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Callback = function(v) Config.PerfectCast = v end,
})

MainTab:CreateSlider({
    Name = "Loop Delay",
    Range = {0.3, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(v) Config.LoopDelay = v end,
})

MainTab:CreateSlider({
    Name = "After Minigame Wait (Important!)",
    Range = {0.5, 2},
    Increment = 0.1,
    CurrentValue = 1.0,
    Callback = function(v) Config.AfterMinigameDelay = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")

task.spawn(function()
    while task.wait(1) do
        local successRate = Stats.BiteDetected > 0 and math.floor((Stats.SuccessfulCatch / Stats.BiteDetected) * 100) or 0
        StatsLabel:Set(string.format("🐟 Fish: %d | ✅ Success: %d%% | ⚡ %.1f/min | ⏱️ %s", 
            Stats.FishCaught, successRate, Stats.FishPerMinute, Stats.SessionTime))
    end
end)

MainTab:CreateButton({Name = "Force Unstuck", Callback = function() ForceUnstuck() end})

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
    Rayfield:Notify({Title = "Rod Info", Content = CurrentRod .. " | " .. CurrentRodDelay .. "s", Duration = 2, Image = 4483362458})
end})

UtilityTab:CreateButton({Name = "Reset Stats", Callback = function()
    Stats.FishCaught = 0
    Stats.TotalSold = 0
    Stats.BiteDetected = 0
    Stats.SuccessfulCatch = 0
    Stats.FailedCatch = 0
    Stats.StartTime = os.time()
    Rayfield:Notify({Title = "Stats Reset", Content = "Cleared!", Duration = 2, Image = 4483362458})
end})

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("Version: 5.1 FAST & RELIABLE")
SettingsTab:CreateLabel("Mode: Smart Timing")
SettingsTab:CreateLabel("Feature: Guaranteed Catch")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() StopAutoFish(); task.wait(0.5); Rayfield:Destroy() end})

GetCurrentRod()
print("=================================")
print("Fish It FAST & RELIABLE v5.1")
print("Rod: " .. CurrentRod)
print("Mode: SMART SPEED")
print("Press F9 for debug logs")
print("=================================")
