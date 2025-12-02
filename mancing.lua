-------------------------------------------
----- Fish It SPEED Edition - FIXED
----- All Bugs Resolved
----- Version: 2.1
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

-- Wait for character
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Net Remote Paths (with error handling)
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

-- Text Effect for Fish Detection
local REReplicateTextEffect = net:WaitForChild("RE/ReplicateTextEffect", 10)

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    
    -- Speed Settings (Adjusted for stability)
    EquipDelay = 0.3,
    ChargeDelay = 0.5,
    CastDelay = 0.3,
    CatchDelay = 0.15,
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
----- Rod Delay Configuration (Fixed)
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
    Errors = 0
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
----- Rod Detection (Fixed)
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
----- FIXED INSTANT CATCH SYSTEM
-------------------------------------------
local FishingState = {
    Active = false,
    Catching = false,
    LastCatchTime = 0
}

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if not Config.AutoFish then return end
    if not FishingState.Active then return end
    if FishingState.Catching then return end
    
    -- Validate data
    if not data or not data.TextData then return end
    if data.TextData.EffectType ~= "Exclaim" then return end
    
    -- Check if effect is on player's head
    local myHead = Character and Character:FindFirstChild("Head")
    if not myHead or data.Container ~= myHead then return end
    
    -- Prevent spam catching
    local currentTime = tick()
    if currentTime - FishingState.LastCatchTime < 0.5 then return end
    
    FishingState.Catching = true
    FishingState.LastCatchTime = currentTime
    
    task.spawn(function()
        -- Spam finish remote for instant catch
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
----- FIXED AUTO FISHING SYSTEM
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
        Content = "Rod: " .. CurrentRod .. " | Delay: " .. CurrentRodDelay .. "s",
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            local success, err = pcall(function()
                -- Ensure character exists
                if not Character or not Character.Parent then
                    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    task.wait(1)
                    return
                end
                
                FishingState.Active = true
                
                -- Step 1: Equip Rod
                equipRemote:FireServer(1)
                task.wait(Config.EquipDelay)
                
                -- Step 2: Charge Rod
                local timestamp = workspace:GetServerTimeNow()
                local chargeSuccess = pcall(function()
                    rodRemote:InvokeServer(timestamp)
                end)
                
                if not chargeSuccess then
                    warn("Failed to charge rod")
                    Stats.Errors = Stats.Errors + 1
                    task.wait(1)
                    return
                end
                
                task.wait(Config.ChargeDelay)
                
                -- Step 3: Cast Rod with Perfect Cast
                local x, y
                if Config.PerfectCast then
                    -- Perfect cast coordinates with slight randomization
                    x = Config.PerfectCastX + (math.random(-100, 100) / 100000000)
                    y = Config.PerfectCastY + (math.random(-100, 100) / 100000000)
                else
                    -- Random cast
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                
                local castSuccess = pcall(function()
                    miniGameRemote:InvokeServer(x, y)
                end)
                
                if not castSuccess then
                    warn("Failed to cast rod")
                    Stats.Errors = Stats.Errors + 1
                    task.wait(1)
                    return
                end
                
                task.wait(Config.CastDelay)
                
                -- Wait for fish bite (based on rod delay)
                task.wait(CurrentRodDelay)
                
                FishingState.Active = false
            end)
            
            if not success then
                warn("Fishing error:", err)
                Stats.Errors = Stats.Errors + 1
                FishingState.Active = false
                FishingState.Catching = false
                task.wait(2)
            end
            
            -- Loop delay
            task.wait(Config.LoopDelay)
        end
        
        Rayfield:Notify({
            Title = "Auto Fish Stopped",
            Content = "Caught: " .. Stats.FishCaught .. " | Errors: " .. Stats.Errors,
            Duration = 3,
            Image = 4483362458,
        })
    end)
end

local function StopFastAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.Catching = false
end

-------------------------------------------
----- AUTO SELL (Fixed)
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            local success = pcall(function()
                -- Wait for Replion to load
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
----- AUTO FAVORITE (Fixed)
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
    Name = "Fish It - FIXED Edition v2.1",
    LoadingTitle = "Loading Fixed Module...",
    LoadingSubtitle = "All Bugs Resolved",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItFixed",
        FileName = "FixedConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "Fixed Edition Loaded",
    Content = "All bugs resolved! Ready to fish!",
    Duration = 5,
    Image = 4483362458,
})

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)
local MainSection = MainTab:CreateSection("Fixed Fishing System")

local AutoFishToggle = MainTab:CreateToggle({
    Name = "Auto Fish (Fixed)",
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

local SpeedSection = MainTab:CreateSection("Speed Configuration")

local LoopDelaySlider = MainTab:CreateSlider({
    Name = "Loop Delay (Higher = More Stable)",
    Range = {0.3, 2},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "LoopDelay",
    Callback = function(Value)
        Config.LoopDelay = Value
    end,
})

local CatchDelaySlider = MainTab:CreateSlider({
    Name = "Catch Response Time",
    Range = {0.1, 0.5},
    Increment = 0.05,
    CurrentValue = 0.15,
    Flag = "CatchDelay",
    Callback = function(Value)
        Config.CatchDelay = Value
    end,
})

local InfoSection = MainTab:CreateSection("Session Statistics")

local StatsLabel = MainTab:CreateLabel("Loading stats...")

task.spawn(function()
    while task.wait(2) do
        StatsLabel:Set(string.format("Fish: %d | Sold: %d | Errors: %d | Time: %s", 
            Stats.FishCaught, Stats.TotalSold, Stats.Errors, Stats.SessionTime))
    end
end)

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
----- TELEPORT TAB
-------------------------------------------
local TeleportTab = Window:CreateTab("📍 Teleport", 4483362458)
local TPSection = TeleportTab:CreateSection("Island Teleport")

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
            pcall(function()
                local char = workspace:FindFirstChild("Characters")
                if char then
                    char = char:FindFirstChild(LocalPlayer.Name)
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                            Rayfield:Notify({
                                Title = "Teleported",
                                Content = "Now at: " .. Option,
                                Duration = 3,
                                Image = 4483362458,
                            })
                        end
                    end
                end
            end)
        end
    end,
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

SettingsTab:CreateLabel("Version: 2.1 Fixed Edition")
SettingsTab:CreateLabel("Status: All Bugs Resolved")
SettingsTab:CreateLabel("Mode: Stable & Reliable")
SettingsTab:CreateLabel("UI: Rayfield")

local DestroySection = SettingsTab:CreateSection("Unload")

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Config.AutoFish = false
        Config.AutoSell = false
        Config.AutoFavorite = false
        task.wait(0.5)
        Rayfield:Destroy()
    end,
})

-------------------------------------------
----- INITIALIZATION
-------------------------------------------
GetCurrentRod()
print("=================================")
print("Fish It Fixed Edition v2.1 Loaded")
print("Rod Detected: " .. CurrentRod)
print("Rod Delay: " .. CurrentRodDelay .. "s")
print("All systems operational!")
print("=================================")
