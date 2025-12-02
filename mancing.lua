-------------------------------------------
----- Fish It TRUE FIX v4.0 + TELEPORT
----- Proper Minigame Interaction
----- Detect & Complete GUI Minigame
----- Island Teleport Feature
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
local UserInputService = game:GetService("UserInputService")

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
----- ISLAND TELEPORT LOCATIONS
-------------------------------------------
local IslandLocations = {
    ["Fisherman Island"] = CFrame.new(400, 140, 250),
    ["Coral Reef Island"] = CFrame.new(-500, 140, 800),
    ["Tropical Grove Island"] = CFrame.new(1200, 140, -600),
    ["Kohana Island"] = CFrame.new(-1500, 140, -1500),
    ["Kohana Volcano"] = CFrame.new(-1600, 140, -1700),
    ["Crater Island"] = CFrame.new(2000, 140, 2000),
    ["Esoteric Depths"] = CFrame.new(500, 50, 300),
    ["Lost Isle"] = CFrame.new(-3000, 140, 3000),
    ["Ancient Jungle Island"] = CFrame.new(3500, 140, -2500),
    ["Classic Island"] = CFrame.new(5000, 140, 0),
    ["Heart Island"] = CFrame.new(-800, 140, 2500),
    ["Christmas Island"] = CFrame.new(1800, 140, 1800)
}

-------------------------------------------
----- TELEPORT FUNCTION
-------------------------------------------
local function TeleportToIsland(islandName)
    if not IslandLocations[islandName] then
        Rayfield:Notify({
            Title = "Teleport Error",
            Content = "Pulau tidak ditemukan!",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    
    if not HumanoidRootPart then
        Rayfield:Notify({
            Title = "Teleport Error", 
            Content = "Character tidak tersedia!",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    
    -- Stop auto fish saat teleport
    local wasAutoFishing = Config.AutoFish
    if wasAutoFishing then
        StopAutoFish()
        task.wait(0.5)
    end
    
    -- Teleport
    pcall(function()
        HumanoidRootPart.CFrame = IslandLocations[islandName]
    end)
    
    Rayfield:Notify({
        Title = "Teleport Berhasil",
        Content = "Teleport ke " .. islandName,
        Duration = 3,
        Image = 4483362458
    })
    
    task.wait(1)
    
    -- Resume auto fish jika sebelumnya aktif
    if wasAutoFishing then
        task.wait(1)
        StartAutoFish()
    end
end

local function SafeTeleport(islandName)
    pcall(function()
        TeleportToIsland(islandName)
    end)
end

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
    AutoFavorite = false,
    
    EquipDelay = 0.4,
    ChargeDelay = 0.6,
    CastDelay = 0.4,
    
    -- Minigame
    MinigameTimeout = 5,
    ClickInterval = 0.05,
    
    LoopDelay = 1.0,
    
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
    TotalSold = 0,
    StartTime = os.time(),
    SessionTime = "0m 0s",
    BiteDetected = 0,
    MinigameFound = 0,
    MinigameCompleted = 0
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
----- MINIGAME GUI DETECTOR (CRITICAL FIX)
-------------------------------------------
local function FindMinigameGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
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
        if gui and gui.Enabled then
            return gui
        end
    end
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            local hasButton = gui:FindFirstChildOfClass("TextButton", true)
            local hasFrame = gui:FindFirstChildOfClass("Frame", true)
            local hasProgress = gui:FindFirstChild("Progress", true) or gui:FindFirstChild("Bar", true)
            
            if hasButton or hasProgress then
                return gui
            end
        end
    end
    
    return nil
end

local function InteractWithMinigameGUI(gui)
    print("[MINIGAME] Found GUI:", gui.Name)
    Stats.MinigameFound = Stats.MinigameFound + 1
    
    local button = gui:FindFirstChildOfClass("TextButton", true)
    if button then
        print("[MINIGAME] Found button:", button.Name)
        
        for i = 1, 50 do
            pcall(function()
                for _, connection in pairs(getconnections(button.MouseButton1Click)) do
                    connection:Fire()
                end
                
                for _, connection in pairs(getconnections(button.MouseButton1Down)) do
                    connection:Fire()
                end
                
                local absPos = button.AbsolutePosition
                local absSize = button.AbsoluteSize
                local center = Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
                
                VirtualUser:Button1Down(center)
                task.wait(0.01)
                VirtualUser:Button1Up(center)
            end)
            
            task.wait(Config.ClickInterval)
        end
        
        Stats.MinigameCompleted = Stats.MinigameCompleted + 1
        return true
    end
    
    print("[MINIGAME] No button found, trying space spam")
    for i = 1, 30 do
        VirtualUser:TypeKey(" ")
        task.wait(Config.ClickInterval)
    end
    
    return false
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
    
    print("[MINIGAME] Starting minigame completion...")
    
    task.wait(0.5)
    
    local gui = FindMinigameGUI()
    
    if gui then
        Rayfield:Notify({
            Title = "Minigame Detected!",
            Content = "GUI: " .. gui.Name,
            Duration = 2,
            Image = 4483362458,
        })
        
        InteractWithMinigameGUI(gui)
    else
        print("[MINIGAME] No GUI found, using fallback method")
        
        for i = 1, 30 do
            pcall(function()
                finishRemote:FireServer()
                VirtualUser:Button1Down(Vector2.new(0,0))
                task.wait(0.01)
                VirtualUser:Button1Up(Vector2.new(0,0))
                VirtualUser:TypeKey(" ")
                VirtualUser:TypeKey("e")
            end)
            task.wait(0.1)
        end
    end
    
    task.wait(0.3)
    for i = 1, 5 do
        pcall(function() finishRemote:FireServer() end)
        task.wait(0.05)
    end
    
    task.wait(1)
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
    print("[BITE] Fish bite detected! (#" .. Stats.BiteDetected .. ")")
    
    FishingState.FishBit = true
    FishingState.WaitingForBite = false
    
    Rayfield:Notify({
        Title = "Fish Bite!",
        Content = "Bite #" .. Stats.BiteDetected,
        Duration = 1,
        Image = 4483362458,
    })
    
    task.spawn(function()
        task.wait(0.3)
        
        local success = pcall(function()
            CompleteMinigame()
        end)
        
        if success then
            Stats.FishCaught = Stats.FishCaught + 1
            print("[SUCCESS] Fish caught! Total: " .. Stats.FishCaught)
        else
            print("[FAIL] Failed to complete minigame")
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
                    while FishingState.ProcessingMinigame do
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
    Name = "Fish It - TRUE FIX v4.0 + Teleport",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "GUI Minigame Detection + Island Teleport",
    ConfigurationSaving = {Enabled = true, FolderName = "FishItTrue", FileName = "TrueConfig"},
    Discord = {Enabled = false},
    KeySystem = false,
})

Rayfield:Notify({Title = "TRUE FIX v4.0 + Teleport", Content = "GUI detection & Teleport active!", Duration = 3, Image = 4483362458})

local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)

MainTab:CreateToggle({
    Name = "Auto Fish (GUI Detection)",
    CurrentValue = false,
    Callback = function(v) if v then StartAutoFish() else StopAutoFish() end end,
})

MainTab:CreateToggle({
    Name = "Perfect Cast",
    CurrentValue = true,
    Callback = function(v) Config.PerfectCast = v end,
})

MainTab:CreateSlider({
    Name = "Loop Delay",
    Range = {0.5, 3},
    Increment = 0.5,
    CurrentValue = 1.0,
    Callback = function(v) Config.LoopDelay = v end,
})

local StatsLabel = MainTab:CreateLabel("Loading...")

task.spawn(function()
    while task.wait(2) do
        StatsLabel:Set(string.format("Fish: %d | Bites: %d | GUI Found: %d | Completed: %d | Time: %s",
            Stats.FishCaught, Stats.BiteDetected, Stats.MinigameFound, Stats.MinigameCompleted, Stats.SessionTime))
    end
end)

MainTab:CreateButton({Name = "Force Unstuck", Callback = function() ForceUnstuck() end})
MainTab:CreateButton({Name = "Test Find GUI", Callback = function()
    local gui = FindMinigameGUI()
    if gui then
        Rayfield:Notify({Title = "GUI Found", Content = gui.Name, Duration = 3, Image = 4483362458})
    else
        Rayfield:Notify({Title = "No GUI", Content = "Minigame GUI not found", Duration = 3, Image = 4483362458})
    end
end})

-------------------------------------------
----- TELEPORT TAB
-------------------------------------------
local TeleportTab = Window:CreateTab("🏝️ Teleport", 4483362458)

TeleportTab:CreateButton({
    Name = "🏠 Fisherman Island (Spawn)",
    Callback = function() SafeTeleport("Fisherman Island") end
})

TeleportTab:CreateButton({
    Name = "🪸 Coral Reef Island",
    Callback = function() SafeTeleport("Coral Reef Island") end
})

TeleportTab:CreateButton({
    Name = "🌴 Tropical Grove Island",
    Callback = function() SafeTeleport("Tropical Grove Island") end
})

TeleportTab:CreateButton({
    Name = "🗿 Kohana Island",
    Callback = function() SafeTeleport("Kohana Island") end
})

TeleportTab:CreateButton({
    Name = "🌋 Kohana Volcano (Best Farm)",
    Callback = function() SafeTeleport("Kohana Volcano") end
})

TeleportTab:CreateButton({
    Name = "💥 Crater Island",
    Callback = function() SafeTeleport("Crater Island") end
})

TeleportTab:CreateButton({
    Name = "🔮 Esoteric Depths (Enchant)",
    Callback = function() SafeTeleport("Esoteric Depths") end
})

TeleportTab:CreateButton({
    Name = "🏴‍☠️ Lost Isle (Challenge)",
    Callback = function() SafeTeleport("Lost Isle") end
})

TeleportTab:CreateButton({
    Name = "🗿 Ancient Jungle Island",
    Callback = function() SafeTeleport("Ancient Jungle Island") end
})

TeleportTab:CreateButton({
    Name = "🏛️ Classic Island (New)",
    Callback = function() SafeTeleport("Classic Island") end
})

TeleportTab:CreateButton({
    Name = "❤️ Heart Island",
    Callback = function() SafeTeleport("Heart Island") end
})

TeleportTab:CreateButton({
    Name = "🎄 Christmas Island",
    Callback = function() SafeTeleport("Christmas Island") end
})

TeleportTab:CreateLabel("Catatan: Auto Fish akan dihentikan sementara saat teleport")

-------------------------------------------
----- AUTO TAB
-------------------------------------------
local AutoTab = Window:CreateTab("⚙️ Automation", 4483362458)

AutoTab:CreateToggle({Name = "Auto Sell", CurrentValue = false, Callback = function(v) Config.AutoSell = v; if v then StartAutoSell() end end})
AutoTab:CreateSlider({Name = "Sell Threshold", Range = {20, 100}, Increment = 5, CurrentValue = 60, Callback = function(v) Config.SellThreshold = v end})
AutoTab:CreateToggle({Name = "Auto Favorite", CurrentValue = false, Callback = function(v) Config.AutoFavorite = v; if v then StartAutoFavorite() end end})

AutoTab:CreateToggle({Name = "Favorite: Secret", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Secret"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Mythic", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Mythic"] = v end})
AutoTab:CreateToggle({Name = "Favorite: Legendary", CurrentValue = true, Callback = function(v) Config.FavoriteTiers["Legendary"] = v end})

-------------------------------------------
----- UTILITY TAB
-------------------------------------------
local UtilityTab = Window:CreateTab("🔧 Utility", 4483362458)

UtilityTab:CreateButton({Name = "Boost FPS", Callback = function() BoostFPS() end})
UtilityTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})
UtilityTab:CreateButton({Name = "Detect Rod", Callback = function()
    GetCurrentRod()
    Rayfield:Notify({Title = "Rod Info", Content = CurrentRod .. " | " .. CurrentRodDelay .. "s", Duration = 3, Image = 4483362458})
end})

UtilityTab:CreateButton({Name = "Print All GUIs", Callback = function()
    print("=== ALL PLAYER GUIs ===")
    for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            print(gui.Name .. " | Enabled: " .. tostring(gui.Enabled))
        end
    end
    Rayfield:Notify({Title = "GUIs Printed", Content = "Check console (F9)", Duration = 2, Image = 4483362458})
end})

-------------------------------------------
----- SETTINGS TAB
-------------------------------------------
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
SettingsTab:CreateLabel("Version: 4.0 TRUE FIX + Teleport")
SettingsTab:CreateLabel("Feature: GUI Minigame Detection")
SettingsTab:CreateLabel("Feature: Island Teleport")
SettingsTab:CreateButton({Name = "Destroy GUI", Callback = function() StopAutoFish(); task.wait(0.5); Rayfield:Destroy() end})

GetCurrentRod()
print("Fish It TRUE FIX v4.1 + Teleport | Rod: " .. CurrentRod)
