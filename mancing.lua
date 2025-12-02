-------------------------------------------
----- Fish It SPEED Edition - Ultra Fast Auto Farm
----- No Animation Delay - Instant Catch
----- Version: 2.0 Speed
-------------------------------------------

-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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
    CastDelay = 0.05,          -- Delay setelah cast (minimal)
    CatchDelay = 0.05,         -- Delay untuk catch fish
    LoopDelay = 0.1,           -- Delay antar loop fishing
    
    -- Perfect Cast
    PerfectCast = true,
    PerfectCastX = -0.7499996423721313,
    PerfectCastY = 1,
    
    -- Auto Sell Settings
    SellThreshold = 60,
    SellCooldown = 60,
    LastSellTime = 0,
    
    -- Auto Favorite Tiers
    FavoriteTiers = {
        ["Secret"] = true,
        ["Mythic"] = true,
        ["Legendary"] = true
    }
}

-------------------------------------------
----- Rod Delay Configuration (Optimized)
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
local function AutoReconnect()
    task.spawn(function()
        while task.wait(5) do
            if not LocalPlayer or not LocalPlayer:IsDescendantOf(game) then
                TeleportService:Teleport(game.PlaceId)
            end
        end
    end)
end

LocalPlayer.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Failed then
        TeleportService:Teleport(game.PlaceId)
    end
end)

AutoReconnect()

-------------------------------------------
----- FPS Boost
-------------------------------------------
local function BoostFPS()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end

    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e10
    settings().Rendering.QualityLevel = "Level01"
end

-------------------------------------------
----- Notification System
-------------------------------------------
local function Notify(title, message, icon)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = 3,
        Icon = icon or "circle-check"
    })
end

-------------------------------------------
----- Rod Detection System
-------------------------------------------
local function GetCurrentRod()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        pcall(function()
            local itemName = tile.Inner.Tags.ItemName
            if itemName and itemName:IsA("TextLabel") then
                local rodName = itemName.Text
                if RodDelays[rodName] then
                    CurrentRod = rodName
                    CurrentRodDelay = RodDelays[rodName]
                    return rodName
                end
            end
        end)
    end
    CurrentRod = "Unknown"
    CurrentRodDelay = 1.0
    return "Unknown"
end

-- Watch for rod changes
local function WatchRodChanges()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    display.ChildAdded:Connect(function()
        task.wait(0.1)
        GetCurrentRod()
    end)
end

WatchRodChanges()

-------------------------------------------
----- INSTANT CATCH SYSTEM (No Animation)
-------------------------------------------
local FishingState = {
    Active = false,
    Catching = false
}

-- Detect fish bite (Exclaim effect)
REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if Config.AutoFish and FishingState.Active then
        if data and data.TextData and data.TextData.EffectType == "Exclaim" then
            local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if myHead and data.Container == myHead then
                FishingState.Catching = true
                
                -- Instant catch (spam finish remote)
                task.spawn(function()
                    for i = 1, 5 do
                        finishRemote:FireServer()
                        task.wait(Config.CatchDelay)
                    end
                    FishingState.Catching = false
                end)
            end
        end
    end
end)

-------------------------------------------
----- ULTRA FAST AUTO FISHING (Skip Animation)
-------------------------------------------
local function StartFastAutoFish()
    if Config.AutoFish then return end
    Config.AutoFish = true
    
    GetCurrentRod()
    Notify("Speed Auto Fish", "Ultra Fast Mode Activated! Rod: " .. CurrentRod, "zap")
    
    task.spawn(function()
        while Config.AutoFish do
            local success = pcall(function()
                FishingState.Active = true
                
                -- Step 1: Equip Rod (Instant)
                equipRemote:FireServer(1)
                task.wait(Config.CastDelay)
                
                -- Step 2: Charge Rod (Skip animation)
                local timestamp = workspace:GetServerTimeNow()
                rodRemote:InvokeServer(timestamp)
                task.wait(Config.CastDelay)
                
                -- Step 3: Cast Rod with Perfect Cast
                local x, y
                if Config.PerfectCast then
                    x = Config.PerfectCastX + (math.random(-500, 500) / 10000000)
                    y = Config.PerfectCastY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end
                
                miniGameRemote:InvokeServer(x, y)
                
                -- Wait for fish bite (optimized delay based on rod)
                task.wait(CurrentRodDelay)
                
                FishingState.Active = false
            end)
            
            if not success then
                warn("Fishing error, retrying...")
            end
            
            -- Minimal loop delay untuk max speed
            task.wait(Config.LoopDelay)
        end
        
        Notify("Auto Fish", "Auto Fishing Stopped", "ban")
    end)
end

local function StopFastAutoFish()
    Config.AutoFish = false
    FishingState.Active = false
    FishingState.Catching = false
end

-------------------------------------------
----- AUTO SELL SYSTEM
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while Config.AutoSell do
            pcall(function()
                -- Check if Replion is loaded
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
                    
                    -- Auto sell if threshold reached
                    if unfavoritedCount >= Config.SellThreshold then
                        local currentTime = os.time()
                        if currentTime - Config.LastSellTime >= Config.SellCooldown then
                            local sellRemote = net:FindFirstChild("RF/SellAllItems")
                            if sellRemote then
                                sellRemote:InvokeServer()
                                Config.LastSellTime = currentTime
                                Notify("Auto Sell", "Sold " .. unfavoritedCount .. " fish!", "badge-dollar-sign")
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
----- AUTO FAVORITE SYSTEM
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
----- UI CREATION
-------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Fish It - SPEED Edition",
    Icon = "zap",
    Author = "Ultra Fast Auto Farm",
    Folder = "FishItSpeed",
    Size = UDim2.fromOffset(550, 400),
    Theme = "Darker",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.RightShift)
WindUI:SetNotificationLower(true)

Notify("Speed Edition Loaded", "Press RIGHT SHIFT to toggle UI", "rocket")

-------------------------------------------
----- MAIN TAB
-------------------------------------------
local MainTab = Window:Tab({
    Title = "Speed Fishing",
    Icon = "zap"
})

local FishingSection = MainTab:Section({
    Title = "Ultra Fast Auto Fishing",
    Icon = "fish"
})

FishingSection:Toggle({
    Title = "Speed Auto Fish",
    Content = "Ultra fast fishing with animation skip",
    Callback = function(value)
        if value then
            StartFastAutoFish()
        else
            StopFastAutoFish()
        end
    end
})

FishingSection:Toggle({
    Title = "Perfect Cast",
    Content = "Always perfect cast for maximum catch rate",
    Value = true,
    Callback = function(value)
        Config.PerfectCast = value
    end
})

FishingSection:Slider({
    Title = "Cast Speed",
    Content = "Delay between casts (lower = faster)",
    Min = 0.05,
    Max = 1.0,
    Default = 0.1,
    Callback = function(value)
        Config.LoopDelay = value
        Notify("Speed Updated", "Loop delay: " .. value .. "s", "gauge")
    end
})

FishingSection:Slider({
    Title = "Catch Response Time",
    Content = "Delay for instant catch (0.05 = fastest)",
    Min = 0.01,
    Max = 0.5,
    Default = 0.05,
    Callback = function(value)
        Config.CatchDelay = value
    end
})

local AutoSection = MainTab:Section({
    Title = "Automation",
    Icon = "bot"
})

AutoSection:Toggle({
    Title = "Auto Sell",
    Content = "Auto sell when > 60 non-favorited fish",
    Callback = function(value)
        Config.AutoSell = value
        if value then
            StartAutoSell()
            Notify("Auto Sell", "Enabled", "shopping-cart")
        end
    end
})

AutoSection:Toggle({
    Title = "Auto Favorite",
    Content = "Auto favorite Secret/Mythic/Legendary",
    Callback = function(value)
        Config.AutoFavorite = value
        if value then
            StartAutoFavorite()
            Notify("Auto Favorite", "Enabled", "star")
        end
    end
})

AutoSection:Slider({
    Title = "Sell Threshold",
    Content = "Sell when fish count reaches",
    Min = 20,
    Max = 100,
    Default = 60,
    Callback = function(value)
        Config.SellThreshold = value
    end
})

-------------------------------------------
----- TELEPORT TAB
-------------------------------------------
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin"
})

local TPSection = TeleportTab:Section({
    Title = "Quick Travel",
    Icon = "navigation"
})

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

local islandNames = {}
for name, _ in pairs(Islands) do
    table.insert(islandNames, name)
end

TPSection:Dropdown({
    Title = "Teleport to Island",
    Values = islandNames,
    Callback = function(selected)
        local pos = Islands[selected]
        if pos then
            local char = workspace:FindFirstChild("Characters")
            if char then
                char = char:FindFirstChild(LocalPlayer.Name)
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                        Notify("Teleported", "Now at: " .. selected, "map-pin")
                    end
                end
            end
        end
    end
})

-------------------------------------------
----- UTILITY TAB
-------------------------------------------
local UtilityTab = Window:Tab({
    Title = "Utility",
    Icon = "settings"
})

local UtilSection = UtilityTab:Section({
    Title = "Performance & Server",
    Icon = "zap"
})

UtilSection:Button({
    Title = "Boost FPS",
    Content = "Remove graphics for max performance",
    Callback = function()
        BoostFPS()
        Notify("FPS Boost", "Graphics optimized!", "zap")
    end
})

UtilSection:Button({
    Title = "Rejoin Server",
    Content = "Reconnect to current server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

UtilSection:Button({
    Title = "Server Hop",
    Content = "Find and join a new server",
    Callback = function()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        
        local _place = game.PlaceId
        local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
        
        function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next; repeat
            local Servers = ListServers(Next)
            Server = Servers.data[1]
            Next = Servers.nextPageCursor
        until Server
        
        TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
    end
})

local RodInfoSection = UtilityTab:Section({
    Title = "Rod Information",
    Icon = "info"
})

RodInfoSection:Button({
    Title = "Detect Current Rod",
    Content = "Show current rod and delay",
    Callback = function()
        GetCurrentRod()
        Notify("Rod Info", "Rod: " .. CurrentRod .. " | Delay: " .. CurrentRodDelay .. "s", "info")
    end
})

-------------------------------------------
----- SETTINGS TAB
-------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

local InfoSection = SettingsTab:Section({
    Title = "Script Info",
    Icon = "info"
})

InfoSection:Paragraph({
    Title = "Fish It - Speed Edition",
    Content = "Ultra fast auto fishing with animation skip technology for maximum efficiency"
})

InfoSection:Label({Title = "Version", Content = "2.0 Speed"})
InfoSection:Label({Title = "Mode", Content = "Ultra Fast (No Animation)"})
InfoSection:Label({Title = "Status", Content = "Active & Optimized"})

InfoSection:Button({
    Title = "Destroy GUI",
    Content = "Close and remove script",
    Callback = function()
        Config.AutoFish = false
        Config.AutoSell = false
        Config.AutoFavorite = false
        Notify("Goodbye!", "Script unloaded", "x")
        task.wait(1)
        Window:Destroy()
    end
})

-------------------------------------------
----- INITIALIZATION
-------------------------------------------
GetCurrentRod()
Notify("Ready!", "All systems loaded. Toggle features to start!", "rocket")
