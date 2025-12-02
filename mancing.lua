-------------------------------------------
----- Fish It v8.3 - KEYBOARD ONLY
----- Virtual Key Press (No Mouse)
----- Space + E Spam
-------------------------------------------

_G.FishItVersion = "8.3 KEYBOARD"

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-------------------------------------------
----- Services
-------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

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
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    DebugMode = false,
    
    EquipDelay = 0.4,
    ChargeDelay = 0.5,
    CastDelay = 0.4,
    
    WaitForGUI = 0.6,
    KeyPressDelay = 0.06, -- Keyboard spam speed
    TotalKeyPresses = 40, -- More presses since keyboard is faster
    AfterMinigameWait = 2.5,
    
    LoopDelay = 0.6,
    
    PerfectCast = true,
    PerfectCastX = -0.7499996423721313,
    PerfectCastY = 1,
    
    SellThreshold = 60,
    SellCooldown = 60,
    LastSellTime = 0,
}

-------------------------------------------
----- Rod Delays
-------------------------------------------
local RodDelays = {
    ["Ares Rod"] = 2.0, ["Angler Rod"] = 2.0, ["Ghostfinn Rod"] = 2.0,
    ["Astral Rod"] = 2.5, ["Chrome Rod"] = 3.0, ["Steampunk Rod"] = 3.5,
    ["Lucky Rod"] = 4.0, ["Midnight Rod"] = 4.0, ["Demascus Rod"] = 4.5,
    ["Grass Rod"] = 4.5, ["Luck Rod"] = 5.0, ["Carbon Rod"] = 4.5,
    ["Lava Rod"] = 5.0, ["Starter Rod"] = 5.5,
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
    MinigameCompleted = 0,
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
----- KEYBOARD-ONLY MINIGAME SOLVER
-------------------------------------------
local function SolveMinigameKeyboard()
    DebugLog("MINIGAME", "⌨️ Keyboard solver started")
    
    -- Try multiple key combinations
    local keys = {
        Enum.KeyCode.Space,
        Enum.KeyCode.E,
        Enum.KeyCode.Return,
    }
    
    for i = 1, Config.TotalKeyPresses do
        pcall(function()
            -- Method 1: VirtualInputManager (Most reliable)
            for _, keyCode in ipairs(keys) do
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.005)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end
            
            -- Method 2: VirtualUser TypeKey
            VirtualUser:TypeKey(" ")
            VirtualUser:TypeKey("e")
            
            -- Method 3: Fire remote directly
            finishRemote:FireServer()
        end)
        
        task.wait(Config.KeyPressDelay)
    end
    
    DebugLog("MINIGAME", "⌨️ Keyboard solver finished")
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

local MinigameLock = false

local function CompleteMinigame()
    if MinigameLock or FishingState.ProcessingMinigame then return end
    
    MinigameLock = true
    FishingState.ProcessingMinigame = true
    Stats.MinigameCompleted = Stats.MinigameCompleted + 1
    
    DebugLog("MINIGAME", "========== MINIGAME #" .. Stats.MinigameCompleted .. " ==========")
    
    task.wait(Config.WaitForGUI)
    
    -- KEYBOARD-ONLY SOLVING (No mouse!)
    SolveMinigameKeyboard()
    
    -- Extra finish signals
    for i = 1, 5 do
        pcall(function()
            finishRemote:FireServer()
        end)
        task.wait(0.1)
    end
    
    -- Wait for server response
    task.wait(Config.AfterMinigameWait)
    
    -- Count fish
    Stats.FishCaught = Stats.FishCaught + 1
    
    DebugLog("MINIGAME", "========== COMPLETE | Fish #" .. Stats.FishCaught .. " ==========")
    
    Rayfield:Notify({
        Title = "🎣 Fish #" .. Stats.FishCaught,
        Content = "⌨️ Keyboard solved!",
        Duration = 1.5,
        Image = 4483362458,
    })
    
    FishingState.ProcessingMinigame = false
    MinigameLock = false
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
    DebugLog("BITE", "========== FISH BITE #" .. Stats.BiteDetected .. " ==========")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    task.spawn(function()
        task.wait(0.4)
        
        pcall(function()
            CompleteMinigame()
        end)
        
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
    
    print("==================== AUTO FISH STARTED ====================")
    print("Rod: " .. CurrentRod)
    print("Method: Keyboard-Only (No Mouse)")
    print("===========================================================")
    
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "⌨️ Keyboard mode!",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        local cycleCount = 0
        
        while Config.AutoFish do
            while MinigameLock or FishingState.ProcessingMinigame do
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
                
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
        
        UnequipRod()
        print("==================== AUTO FISH STOPPED ====================")
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
----- AUTO SELL
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                local sellRemote = net:FindFirstChild("RF/SellAllItems")
                if sellRemote and Stats.FishCaught >= Config.SellThreshold and os.time() - Config.LastSellTime >= Config.SellCooldown then
                    sellRemote:InvokeServer()
                    Config.LastSellTime = os.time()
                    local sold = Stats.FishCaught
                    Stats.TotalSold = Stats.TotalSold + sold
                    
                    Rayfield:Notify({Title = "💰 Sold!", Content = sold .. " fish", Duration = 2, Image = 4483362458})
                end
            end)
            task.wait(15)
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
    Name = "Fish It v8.3 KEYBOARD",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Keyboard-Only Mode",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItKeyboard", FileName = "KeyboardConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

Rayfield:Notify({Title = "v8.3 KEYBOARD", Content = "⌨️ No mouse clicks!", Duration = 3, Image = 4483362458})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (Keyboard Mode)",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Debug Logs",
    CurrentValue = false,
    Callback = function(v) Config.DebugMode = v end,
})

MainTab:CreateSlider({
    Name = "Key Press Speed",
    Range = {0.03, 0.15},
    Increment = 0.01,
    CurrentValue = 0.06,
    Callback = function(v) Config.KeyPressDelay = v end,
})

MainTab:CreateSlider({
    Name = "Total Key Presses",
    Range = {20, 60},
    Increment = 5,
    CurrentValue = 40,
    Callback = function(v) Config.TotalKeyPresses = v end,
})

MainTab:CreateSlider({
    Name = "After Minigame Wait",
    Range = {1, 4},
    Increment = 0.5,
    CurrentValue = 2.5,
    Callback = function(v) Config.AfterMinigameWait = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")

task.spawn(function()
    while task.wait(1) do
        local successRate = Stats.BiteDetected > 0 and math.floor((Stats.FishCaught / Stats.BiteDetected) * 100) or 0
        StatsLabel:Set(string.format("🐟 Fish: %d | 🎣 Bites: %d | ✅ %d%% | ⚡ %.1f/min | ⏱️ %s", 
            Stats.FishCaught, Stats.BiteDetected, successRate, Stats.FishPerMinute, Stats.SessionTime))
    end
end)

MainTab:CreateButton({Name = "Reset Counter", Callback = function()
    Stats.FishCaught = 0
    Stats.BiteDetected = 0
    Stats.MinigameCompleted = 0
    Stats.StartTime = os.time()
end})

local AutoTab = Window:CreateTab("⚙️ Auto", 4483362458)
AutoTab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) Config.AutoSell = v; if v then StartAutoSell() end end})
AutoTab:CreateSlider({Name = "Sell Threshold", Range = {20, 100}, Increment = 5, CurrentValue = 60, Callback = function(v) Config.SellThreshold = v end})

local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)
UtilityTab:CreateButton({Name = "Force Unstuck", Callback = function() UnequipRod() end})
UtilityTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})

local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("Version: 8.3 KEYBOARD")
SettingsTab:CreateLabel("Method: Virtual Key Input")
SettingsTab:CreateLabel("⌨️ Space + E + Enter spam")
SettingsTab:CreateLabel("No mouse movement!")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() StopAutoFish(); task.wait(0.5); Rayfield:Destroy() end})

GetCurrentRod()
print("=================================")
print("Fish It v8.3 KEYBOARD")
print("Method: Virtual Key Input")
print("Keys: Space + E + Enter")
print("=================================")
