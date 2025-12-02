-------------------------------------------
----- Fish It Auto Farm - Custom Version
----- Based on: ZIAANHUB Script
----- Modified by: Your Name
----- Version: 1.0
-------------------------------------------

-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-------------------------------------------
----- Services & Variables
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

-- State Variables
local AutoFishState = {
    enabled = false,
    perfectCast = true,
    fishingActive = false,
    delayInitialized = false
}

local AutoSellState = {
    enabled = false,
    threshold = 60,
    lastSellTime = 0,
    sellDelay = 60
}

local AutoFavoriteState = {
    enabled = false,
    tiers = {
        ["Secret"] = true,
        ["Mythic"] = true,
        ["Legendary"] = true
    }
}

-------------------------------------------
----- Rod Delay Configuration
-------------------------------------------
local RodDelays = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45},
    ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45},
    ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2},
    ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6},
    ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8},
    ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1},
    ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1},
    ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local customDelay = 4
local bypassDelay = 1.45

-------------------------------------------
----- Animation Setup
-------------------------------------------
local RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("FishingRodReelIdle")
local RodReel = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("EasyFishReelStart")
local RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("CastFromFullChargePosition1Hand")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodShakeAnim = animator:LoadAnimation(RodShake)
local RodIdleAnim = animator:LoadAnimation(RodIdle)
local RodReelAnim = animator:LoadAnimation(RodReel)

-------------------------------------------
----- Anti-AFK System
-------------------------------------------
local VirtualUser = game:GetService("VirtualUser")

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

for i,v in next, getconnections(LocalPlayer.Idled) do
    v:Disable()
end

-------------------------------------------
----- Auto Reconnect System
-------------------------------------------
local function AutoReconnect()
    while task.wait(5) do
        if not LocalPlayer or not LocalPlayer:IsDescendantOf(game) then
            TeleportService:Teleport(game.PlaceId)
        end
    end
end

LocalPlayer.OnTeleport:Connect(function(teleportState)
    if teleportState == Enum.TeleportState.Failed then
        TeleportService:Teleport(game.PlaceId)
    end
end)

task.spawn(AutoReconnect)

-------------------------------------------
----- FPS Boost System
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
----- Notification Functions
-------------------------------------------
local function NotifySuccess(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Icon = "circle-check"
    })
end

local function NotifyError(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Icon = "ban"
    })
end

local function NotifyInfo(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Icon = "info"
    })
end

local function NotifyWarning(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3,
        Icon = "triangle-alert"
    })
end

-------------------------------------------
----- Rod Detection System
-------------------------------------------
local function getValidRodName()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        local success, itemNamePath = pcall(function()
            return tile.Inner.Tags.ItemName
        end)
        if success and itemNamePath and itemNamePath:IsA("TextLabel") then
            local name = itemNamePath.Text
            if RodDelays[name] then
                return name
            end
        end
    end
    return nil
end

local function updateDelayBasedOnRod(showNotify)
    if AutoFishState.delayInitialized then return end
    
    local rodName = getValidRodName()
    if rodName and RodDelays[rodName] then
        customDelay = RodDelays[rodName].custom
        bypassDelay = RodDelays[rodName].bypass
        AutoFishState.delayInitialized = true
        
        if showNotify and AutoFishState.enabled then
            NotifySuccess("Rod Detected", string.format("Rod: %s | Delay: %.2fs", rodName, customDelay))
        end
    else
        customDelay = 4
        bypassDelay = 1
        AutoFishState.delayInitialized = true
        
        if showNotify and AutoFishState.enabled then
            NotifyWarning("Rod Detection", "Using default delay: 4s")
        end
    end
end

local function setupRodWatcher()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    display.ChildAdded:Connect(function()
        task.wait(0.05)
        if not AutoFishState.delayInitialized then
            updateDelayBasedOnRod(true)
        end
    end)
end

setupRodWatcher()

-------------------------------------------
----- Auto Fish Logic
-------------------------------------------
local REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]

REReplicateTextEffect.OnClientEvent:Connect(function(data)
    if AutoFishState.enabled and AutoFishState.fishingActive
    and data and data.TextData and data.TextData.EffectType == "Exclaim" then
        
        local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        if myHead and data.Container == myHead then
            task.spawn(function()
                for i = 1, 3 do
                    task.wait(bypassDelay)
                    finishRemote:FireServer()
                end
            end)
        end
    end
end)

local function StartAutoFish()
    if AutoFishState.enabled then return end
    
    AutoFishState.enabled = true
    updateDelayBasedOnRod(true)
    NotifySuccess("Auto Fish", "Auto Fishing Started!")
    
    task.spawn(function()
        while AutoFishState.enabled do
            pcall(function()
                AutoFishState.fishingActive = true

                -- Equip Rod
                local equipRemote = net:WaitForChild("RE/EquipToolFromHotbar")
                equipRemote:FireServer(1)
                task.wait(0.1)

                -- Charge Rod
                local timestamp = workspace:GetServerTimeNow()
                RodShakeAnim:Play()
                rodRemote:InvokeServer(timestamp)
                task.wait(0.5)

                -- Cast Rod with Perfect Cast Logic
                local baseX, baseY = -0.7499996423721313, 1
                local x, y
                
                if AutoFishState.perfectCast then
                    x = baseX + (math.random(-500, 500) / 10000000)
                    y = baseY + (math.random(-500, 500) / 10000000)
                else
                    x = math.random(-1000, 1000) / 1000
                    y = math.random(0, 1000) / 1000
                end

                RodIdleAnim:Play()
                miniGameRemote:InvokeServer(x, y)

                task.wait(customDelay)
                AutoFishState.fishingActive = false
            end)
        end
    end)
end

local function StopAutoFish()
    AutoFishState.enabled = false
    AutoFishState.fishingActive = false
    AutoFishState.delayInitialized = false
    
    RodIdleAnim:Stop()
    RodShakeAnim:Stop()
    RodReelAnim:Stop()
    
    NotifyWarning("Auto Fish", "Auto Fishing Stopped!")
end

-------------------------------------------
----- Auto Sell System
-------------------------------------------
local function StartAutoSell()
    task.spawn(function()
        while AutoSellState.enabled do
            pcall(function()
                if not Replion then return end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) ~= "table" then return end

                local unfavoritedCount = 0
                for _, item in ipairs(items) do
                    if not item.Favorited then
                        unfavoritedCount = unfavoritedCount + (item.Count or 1)
                    end
                end

                if unfavoritedCount >= AutoSellState.threshold and 
                   os.time() - AutoSellState.lastSellTime >= AutoSellState.sellDelay then
                    
                    local sellFunc = net:FindFirstChild("RF/SellAllItems")
                    if sellFunc then
                        sellFunc:InvokeServer()
                        NotifyInfo("Auto Sell", "Selling non-favorited items...")
                        AutoSellState.lastSellTime = os.time()
                    end
                end
            end)
            task.wait(10)
        end
    end)
end

-------------------------------------------
----- Auto Favorite System
-------------------------------------------
local function StartAutoFavorite()
    task.spawn(function()
        while AutoFavoriteState.enabled do
            pcall(function()
                if not Replion or not ItemUtility then return end
                
                local DataReplion = Replion.Client:WaitReplion("Data")
                local items = DataReplion and DataReplion:Get({"Inventory","Items"})
                
                if type(items) ~= "table" then return end
                
                for _, item in ipairs(items) do
                    local base = ItemUtility:GetItemData(item.Id)
                    if base and base.Data and AutoFavoriteState.tiers[base.Data.Tier] and not item.Favorited then
                        item.Favorited = true
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-------------------------------------------
----- UI Creation
-------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Fish It - Custom Edition",
    Icon = "fish",
    Author = "Modified for You",
    Folder = "FishItCustom",
    Size = UDim2.fromOffset(600, 450),
    Theme = "Indigo",
    KeySystem = false
})

Window:SetToggleKey(Enum.KeyCode.G)
WindUI:SetNotificationLower(true)

NotifySuccess("Script Loaded", "Fish It Custom Edition Ready!", 5)

-------------------------------------------
----- Auto Fishing Tab
-------------------------------------------
local AutoFishTab = Window:Tab({
    Title = "Auto Fishing",
    Icon = "fish"
})

local AutoFishSection = AutoFishTab:Section({
    Title = "Fishing Automation",
    Icon = "fish"
})

AutoFishSection:Toggle({
    Title = "Auto Fish",
    Content = "Automatically fish with rod detection",
    Callback = function(value)
        if value then
            StartAutoFish()
        else
            StopAutoFish()
        end
    end
})

AutoFishSection:Toggle({
    Title = "Perfect Cast",
    Content = "Enable perfect casting accuracy",
    Value = true,
    Callback = function(value)
        AutoFishState.perfectCast = value
    end
})

AutoFishSection:Input({
    Title = "Bypass Delay",
    Content = "Delay between fish detection (seconds)",
    Placeholder = "Example: 1.45",
    Callback = function(value)
        local number = tonumber(value)
        if number then
            bypassDelay = number
            NotifySuccess("Delay Updated", "Bypass delay set to " .. number .. "s")
        else
            NotifyError("Invalid Input", "Please enter a valid number")
        end
    end,
})

AutoFishSection:Toggle({
    Title = "Auto Sell",
    Content = "Auto sell non-favorited fish when count > 60",
    Callback = function(value)
        AutoSellState.enabled = value
        if value then
            StartAutoSell()
            NotifySuccess("Auto Sell", "Auto Sell Enabled")
        else
            NotifyWarning("Auto Sell", "Auto Sell Disabled")
        end
    end
})

AutoFishSection:Toggle({
    Title = "Auto Favorite",
    Content = "Auto favorite Secret/Mythic/Legendary fish",
    Callback = function(value)
        AutoFavoriteState.enabled = value
        if value then
            StartAutoFavorite()
            NotifySuccess("Auto Favorite", "Auto Favorite Enabled")
        else
            NotifyWarning("Auto Favorite", "Auto Favorite Disabled")
        end
    end
})

-------------------------------------------
----- Utility Tab
-------------------------------------------
local UtilityTab = Window:Tab({
    Title = "Utility",
    Icon = "settings"
})

local TeleportSection = UtilityTab:Section({
    Title = "Teleport",
    Icon = "map-pin"
})

-- Island Coordinates
local islandCoords = {
    ["Kohana"] = Vector3.new(-658, 3, 719),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Coral Reefs"] = Vector3.new(-3095, 1, 2177),
    ["Esoteric Depths"] = Vector3.new(3157, -1303, 1439),
    ["Kohana Volcano"] = Vector3.new(-519, 24, 189),
    ["Winter Fest"] = Vector3.new(1611, 4, 3280),
}

local islandNames = {}
for name, _ in pairs(islandCoords) do
    table.insert(islandNames, name)
end

TeleportSection:Dropdown({
    Title = "Teleport to Island",
    Content = "Quick travel to islands",
    Values = islandNames,
    Callback = function(selectedName)
        local position = islandCoords[selectedName]
        if position then
            local char = workspace:WaitForChild("Characters"):FindFirstChild(LocalPlayer.Name)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
                NotifySuccess("Teleported", "You are now at " .. selectedName)
            end
        end
    end
})

local ServerSection = UtilityTab:Section({
    Title = "Server",
    Icon = "server"
})

ServerSection:Button({
    Title = "Rejoin Server",
    Content = "Rejoin current server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

ServerSection:Button({
    Title = "Boost FPS",
    Content = "Optimize graphics for better performance",
    Callback = function()
        BoostFPS()
        NotifySuccess("FPS Boost", "Graphics optimized!")
    end
})

-------------------------------------------
----- Settings Tab
-------------------------------------------
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "user-cog"
})

local InfoSection = SettingsTab:Section({
    Title = "Information",
    Icon = "info"
})

InfoSection:Paragraph({
    Title = "Fish It - Custom Edition",
    Content = "Modified auto fishing script with advanced features"
})

InfoSection:Label({
    Title = "Version",
    Content = "1.0 Custom"
})

InfoSection:Label({
    Title = "Status",
    Content = "Active"
})

NotifySuccess("Ready!", "All features loaded successfully", 5)
