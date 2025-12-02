-------------------------------------------
----- Fish It FINAL Edition v3.2
----- Optimized & Stable
----- Proven Working!
-------------------------------------------

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-------------------------------------------
----- Services & Core Variables
-------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
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
local net = ReplicatedStorage:WaitForChild("Packages", 10)
    :WaitForChild("_Index", 10)
    :WaitForChild("sleitnick_net@0.2.0", 10)
    :WaitForChild("net", 10)

-- Fishing Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod", 10)
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted", 10)
local finishRemote = net:WaitForChild("RE/FishingCompleted", 10)
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar", 10)
local unequipRemote = net:WaitForChild("RE/UnequipTool", 10)
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- Configuration (OPTIMIZED)
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    
    -- Optimized Settings
    EquipDelay = 0.4,
    ChargeDelay = 0.6,
    CastDelay = 0.4,
    
    -- Minigame Settings (PROVEN WORKING)
    ReelSpeed = 0.1,
    ReelAttempts = 15, -- Reduced from 30
    WaitAfterBite = 0.3,
    
    LoopDelay = 1.0, -- Increased for stability
    
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
    TotalSold = 0,
    StartTime = os.time(),
    SessionTime = "0m 0s",
    BiteDetected = 0,
    SuccessfulCatches = 0
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
    task.wait(0.3)
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
----- MINIGAME HANDLER (PROVEN METHOD)
-------------------------------------------
local FishingState = {
    Active = false,
    WaitingForBite = false,
    FishBit = false,
    Reeling = false
}

local function CompleteMinigame()
    FishingState.Reeling = true
    
    -- Proven method from your logs
    for i = 1, Config.ReelAttempts do
        pcall(function()
            finishRemote:FireServer()
            VirtualUser:Button1Down(Vector2.new(0,0))
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0,0))
            VirtualUser:TypeKey(" ")
        end)
        task.wait(Config.ReelSpeed)
    end
    
    -- Final finish signals
    task.wait(0.3)
    for i = 1, 3 do
        pcall(function() finishRemote:FireServer() end)
        task.wait(0.05)
    end
    
    task.wait(0.5)
    FishingState.Reeling = false
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
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    task.spawn(function()
        task.wait(Config.WaitAfterBite)
        
        local success = pcall(function()
            CompleteMinigame()
        end)
        
        if success then
            Stats.SuccessfulCatches = Stats.SuccessfulCatches + 1
            Stats.FishCaught = Stats.FishCaught + 1
        end
        
        task.wait(0.5)
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
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Rod: " .. CurrentRod,
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
                
                FishingState.Active = true
                FishingState.WaitingForBite = false
                FishingState.FishBit = false
                
                UnequipRod()
                
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                local timestamp = workspace:GetServerTimeNow()
                pcall(function() rodRemote:InvokeServer(timestamp) end)
                task.wait(Config.ChargeDelay)
                
                local x = Config.PerfectCastX + (math.random(-100, 100) / 100000000)
                local y = Config.PerfectCastY + (math.random(-100, 100) / 100000000)
                
                pcall(function() miniGameRemote:InvokeServer(x, y) end)
                task.wait(Config.CastDelay)
                
                FishingState.WaitingForBite = true
                
                local waitStart = tick()
                local maxWait = CurrentRodDelay + 3
                
                while FishingState.WaitingForBite and not FishingState.FishBit and (tick() - waitStart) < maxWait do
                    task.wait(0.2)
                end
                
                if FishingState.FishBit then
                    while FishingState.Reeling do
                        task.wait(0.2)
                    end
                end
                
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
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
                            Rayfield:Notify({Title = "Auto Sell", Content = "Sold " .. count .. " fish!", Duration = 3, Image = 4483362458})
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
    end
end)

-------------------------------------------
----- UI
-------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Fish It - FINAL v3.2",
    LoadingTitle = "Loading Final Edition...",
    LoadingSubtitle = "Optimized & Stable",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItFinal", FileName = "FinalConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

Rayfield:Notify({Title = "Final Edition", Content = "Optimized & Ready!", Duration = 3, Image = 4483362458})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (Optimized)",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Callback = function(v) Config.PerfectCast = v end,
})

MainTab:CreateSlider({
    Name = "Loop Delay (Stability)",
    Range = {0.5, 3},
    Increment = 0.5,
    CurrentValue = 1.0,
    Callback = function(v) Config.LoopDelay = v end,
})

MainTab:CreateSlider({
    Name = "Reel Attempts",
    Range = {10, 30},
    Increment = 5,
    CurrentValue = 15,
    Callback = function(v) Config.ReelAttempts = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")

task.spawn(function()
    while task.wait(2) do
        local rate = Stats.BiteDetected > 0 and math.floor((Stats.SuccessfulCatches / Stats.BiteDetected) * 100) or 0
        StatsLabel:Set(string.format("Fish: %d | Bites: %d | Success: %d%% | Time: %s", 
            Stats.FishCaught, Stats.BiteDetected, rate, Stats.SessionTime))
    end
end)

MainTab:CreateButton({Name = "Force Unstuck", Callback = function() ForceUnstuck() end})
MainTab:CreateButton({Name = "Unequip Rod", Callback = function() UnequipRod() end})

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
    Rayfield:Notify({Title = "Rod Info", Content = CurrentRod .. " | " .. CurrentRodDelay .. "s", Duration = 3, Image = 4483362458})
end})

UtilityTab:CreateButton({Name = "Reset Stats", Callback = function()
    Stats.FishCaught = 0
    Stats.TotalSold = 0
    Stats.BiteDetected = 0
    Stats.SuccessfulCatches = 0
    Stats.StartTime = os.time()
end})

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("Version: 3.2 Final")
SettingsTab:CreateLabel("Status: Optimized & Stable")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() StopAutoFish(); task.wait(0.5); Rayfield:Destroy() end})

GetCurrentRod()
print("Fish It Final v3.2 | Rod: " .. CurrentRod .. " | READY!")
