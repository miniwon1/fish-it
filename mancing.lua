-------------------------------------------
----- Fish It SPEED Edition - Ultra Fast
----- UI: Rayfield (Lightweight & Modern)
----- No Animation Delay - Instant Catch
----- Version: 2.0
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

-- Net Remote Paths
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

-- Fishing Remotes
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")

-- Text Effect for Fish Detection
local REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]

-------------------------------------------
----- Configuration
-------------------------------------------
local Config = {
    AutoFish = false,
    AutoSell = false,
    AutoFavorite = false,
    
    -- Speed Settings
    CastDelay = 0.05,
    CatchDelay = 0.05,
    LoopDelay = 0.1,
    
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
    ["Ares Rod"] = 0.8,
    ["Angler Rod"] = 0.8,
    ["Ghostfinn Rod"] = 0.8,
    ["Astral Rod"] = 1.2,
    ["Chrome Rod"] = 1.5,
    ["Steampunk Rod"] = 1.8,
    ["Lucky Rod"] = 2.0,
    ["Midnight Rod"] = 2.0,
    ["Demascus Rod"] = 2.2,
    ["Grass Rod"] = 2.2,
    ["Luck Rod"] = 2.5,
    ["Carbon Rod"] = 2.3,
    ["Lava Rod"] = 2.5,
    ["Starter Rod"] = 2.8,
}

local CurrentRodDelay = 1.0
local CurrentRod = "Unknown"

-------------------------------------------
----- Statistics
-------------------------------------------
local Stats = {
    FishCaught = 0,
    TotalSold = 0,
    StartTime = os.time(),
    SessionTime = "0m 0s"
}

-------------------------------------------
----- Anti-AFK System
-------------------------------------------
local VirtualUser = game:GetService("VirtualUser")

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
        TeleportService:Teleport(game.PlaceId)
    end
end)

task.spawn(function()
    while task.wait(5) do
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
        Content = "Graphics optimized for performance!",
        Duration = 3,
        Image = 4483362458,
    })
end

-------------------------------------------
----- Rod Detection
-------------------------------------------
local function GetCurrentRod()
    pcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
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

local function WatchRodChanges()
    pcall(function()
        local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
        display.ChildAdded:Connect(function()
            task.wait(0.1)
            GetCurrentRod()
        end)
    end)
end

WatchRodChanges()

-------------------------------------------
----- INSTANT CATCH SYSTEM
-------------------------------------------
local FishingState = {
    Active = false,
    Catching = false
}

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if Config.AutoFish and FishingState.Active then
        if data and data.TextData and data.TextData.EffectType == "Exclaim" then
            local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if myHead and data.Container == myHead then
                FishingState.Catching = true
                
                task.spawn(function()
                    for i = 1, 5 do
                        finishRemote:FireServer()
                        task.wait(Config.CatchDelay)
                    end
                    FishingState.Catching = false
                    Stats.FishCaught = Stats.FishCaught + 1
                end)
            end
        end
    end
end)

-------------------------------------------
----- ULTRA FAST AUTO FISHING
-------------------------------------------
local function StartFastAutoFish()
    if Config.AutoFish then return end
    Config.AutoFish = true
    
    GetCurrentRod()
    Rayfield:Notify({
        Title = "Auto Fish Started",
        Content = "Ultra Fast Mode | Rod: " .. CurrentRod,
        Duration = 3,
        Image = 4483362458,
    })
    
    task.spawn(function()
        while Config.AutoFish do
            pcall(function()
                FishingState.Active = true
                
                -- Equip Rod
                equipRemote:FireServer(1)
                task.wait(Config.CastDelay)
                
                -- Charge Rod
                local timestamp = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(timestamp)
                task.wait(Config.CastDelay)
                
                -- Cast Rod with Perfect Cast
                local x, y
                if Config.PerfectCast then
                    x = Config.PerfectCastX + (math.random(-500, 500) / 10000000)
                    y = Config.PerfectCastY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                
                miniGameRemote:InvokeServer(x, y)
                
                -- Wait for fish
                task.wait(CurrentRodDelay)
                FishingState.Active = false
            end)
            
            task.wait(Config.LoopDelay)
        end
    end)
end

local function StopFastAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.Catching = false
    
    Rayfield:Notify({
        Title = "Auto Fish Stopped",
        Content = "Total Caught: " .. Stats.FishCaught,
        Duration = 3,
        Image = 4483362458,
    })
end

-------------------------------------------
----- AUTO SELL
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                if not Replion then 
                    task.wait(5)
                    return 
                end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
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
            
            task.wait(10)
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
                if not Replion or not ItemUtility then 
                    task.wait(5)
                    return 
                end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) == "table" then
                    for _, item in ipairs(items) do
                        local itemData = ItemUtility:GetItemData(item.Id)
                        if itemData and itemData.Data then
                            local tier = itemData.Data.Tier
                            if Config.FavoriteTiers[tier] and not item.Favorited then
                                item.Favorited = true
                            end
                        end
                    end
                end
            end)
            
            task.wait(5)
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
    Name = "Fish It - SPEED Edition",
    LoadingTitle = "Loading Speed Module...",
    LoadingSubtitle = "by Ultra Fast Team",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FishItSpeed",
        FileName = "SpeedConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

Rayfield:Notify({
    Title = "Speed Edition Loaded",
    Content = "Ultra Fast Auto Fishing Ready!",
    Duration = 5,
    Image = 4483362458,
})

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:CreateTab("🎣 Auto Fish", 4483362458)
local MainSection = MainTab:CreateSection("Speed Fishing")

local AutoFishToggle = MainTab:CreateToggle({
    Name = "Ultra Fast Auto Fish",
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
    Name = "Perfect Cast (Always ON)",
    CurrentValue = true,
    Flag = "PerfectCastToggle",
    Callback = function(Value)
        Config.PerfectCast = Value
    end,
})

local SpeedSection = MainTab:CreateSection("Speed Configuration")

local CastSpeedSlider = MainTab:CreateSlider({
    Name = "Cast Speed (Lower = Faster)",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "CastSpeed",
    Callback = function(Value)
        Config.LoopDelay = Value
    end,
})

local CatchSpeedSlider = MainTab:CreateSlider({
    Name = "Catch Response Time",
    Range = {0.01, 0.5},
    Increment = 0.01,
    CurrentValue = 0.05,
    Flag = "CatchSpeed",
    Callback = function(Value)
        Config.CatchDelay = Value
    end,
})

local InfoSection = MainTab:CreateSection("Session Statistics")

local StatsLabel = MainTab:CreateLabel("Fish Caught: 0 | Sold: 0 | Time: 0m")

task.spawn(function()
    while task.wait(2) do
        StatsLabel:Set(string.format("Fish: %d | Sold: %d | Time: %s", 
            Stats.FishCaught, Stats.TotalSold, Stats.SessionTime))
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

-------------------------------------------
----- SETTINGS TAB
-------------------------------------------
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Script Information")

SettingsTab:CreateLabel("Version: 2.0 Speed Edition")
SettingsTab:CreateLabel("Mode: Ultra Fast (No Animation)")
SettingsTab:CreateLabel("UI: Rayfield (Lightweight)")
SettingsTab:CreateLabel("Status: Operational")

local DestroySection = SettingsTab:CreateSection("Unload")

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Config.AutoFish = false
        Config.AutoSell = false
        Config.AutoFavorite = false
        Rayfield:Destroy()
    end,
})

-------------------------------------------
----- INITIALIZATION
-------------------------------------------
GetCurrentRod()
print("Fish It Speed Edition Loaded Successfully!")
