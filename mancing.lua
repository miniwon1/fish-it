-------------------------------------------
----- Fish It TRUE FIX v4.1 + AUTO SAVE/LOAD
----- Auto Save Position, Settings & Rotation
----- Auto Execute on Rejoin
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
    
    -- Auto load on respawn if enabled
    if Config.AutoLoadOnRespawn then
        task.wait(2)
        LoadPosition()
        if SavedSettings.AutoFishEnabled then
            task.wait(1)
            StartAutoFish()
        end
    end
end)

-------------------------------------------
----- SAVE/LOAD SYSTEM
-------------------------------------------
local SaveFileName = "FishIt_SaveData_" .. LocalPlayer.UserId .. ".json"

local SavedSettings = {
    -- Position & Rotation
    SavedPosition = nil,
    SavedRotation = nil,
    HasSavedPosition = false,
    
    -- Auto Fish Settings
    AutoFishEnabled = false,
    PerfectCastEnabled = true,
    LoopDelay = 1.0,
    
    -- Auto Sell/Favorite
    AutoSellEnabled = false,
    SellThreshold = 60,
    AutoFavoriteEnabled = false,
    
    -- Favorite Tiers
    FavoriteSecret = true,
    FavoriteMythic = true,
    FavoriteLegendary = true,
    
    -- Auto Load Settings
    AutoLoadOnStart = true,
    AutoLoadOnRespawn = true,
    AutoExecuteOnRejoin = true,
}

-- Save settings to file
local function SaveSettings()
    local success, err = pcall(function()
        -- Get current position and rotation
        if HumanoidRootPart then
            SavedSettings.SavedPosition = {
                X = HumanoidRootPart.Position.X,
                Y = HumanoidRootPart.Position.Y,
                Z = HumanoidRootPart.Position.Z
            }
            
            local _, y, _ = HumanoidRootPart.CFrame:ToOrientation()
            SavedSettings.SavedRotation = math.deg(y)
            SavedSettings.HasSavedPosition = true
        end
        
        -- Save current config
        SavedSettings.AutoFishEnabled = Config.AutoFish
        SavedSettings.PerfectCastEnabled = Config.PerfectCast
        SavedSettings.LoopDelay = Config.LoopDelay
        SavedSettings.AutoSellEnabled = Config.AutoSell
        SavedSettings.SellThreshold = Config.SellThreshold
        SavedSettings.AutoFavoriteEnabled = Config.AutoFavorite
        SavedSettings.FavoriteSecret = Config.FavoriteTiers["Secret"]
        SavedSettings.FavoriteMythic = Config.FavoriteTiers["Mythic"]
        SavedSettings.FavoriteLegendary = Config.FavoriteTiers["Legendary"]
        
        -- Convert to JSON
        local HttpService = game:GetService("HttpService")
        local jsonData = HttpService:JSONEncode(SavedSettings)
        
        -- Save to file
        writefile(SaveFileName, jsonData)
        
        print("[SAVE] Settings saved successfully!")
        return true
    end)
    
    if success then
        Rayfield:Notify({
            Title = "💾 Save Berhasil",
            Content = "Posisi & setting tersimpan!",
            Duration = 3,
            Image = 4483362458
        })
    else
        print("[SAVE] Error:", err)
        Rayfield:Notify({
            Title = "Save Error",
            Content = "Gagal menyimpan: " .. tostring(err),
            Duration = 3,
            Image = 4483362458
        })
    end
    
    return success
end

-- Load settings from file
local function LoadSettings()
    local success, err = pcall(function()
        if not isfile(SaveFileName) then
            print("[LOAD] No save file found")
            return false
        end
        
        local HttpService = game:GetService("HttpService")
        local jsonData = readfile(SaveFileName)
        local loadedData = HttpService:JSONDecode(jsonData)
        
        -- Merge loaded data
        for key, value in pairs(loadedData) do
            SavedSettings[key] = value
        end
        
        -- Apply settings to Config
        Config.PerfectCast = SavedSettings.PerfectCastEnabled
        Config.LoopDelay = SavedSettings.LoopDelay
        Config.AutoSell = SavedSettings.AutoSellEnabled
        Config.SellThreshold = SavedSettings.SellThreshold
        Config.AutoFavorite = SavedSettings.AutoFavoriteEnabled
        Config.FavoriteTiers["Secret"] = SavedSettings.FavoriteSecret
        Config.FavoriteTiers["Mythic"] = SavedSettings.FavoriteMythic
        Config.FavoriteTiers["Legendary"] = SavedSettings.FavoriteLegendary
        
        print("[LOAD] Settings loaded successfully!")
        print("[LOAD] Has saved position:", SavedSettings.HasSavedPosition)
        
        return true
    end)
    
    if not success then
        print("[LOAD] Error:", err)
        return false
    end
    
    return success
end

-- Load position and teleport
local function LoadPosition()
    if not SavedSettings.HasSavedPosition then
        Rayfield:Notify({
            Title = "Load Error",
            Content = "Tidak ada posisi tersimpan!",
            Duration = 3,
            Image = 4483362458
        })
        return false
    end
    
    local success, err = pcall(function()
        if not HumanoidRootPart then
            Character = LocalPlayer.Character
            HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        end
        
        if not HumanoidRootPart then
            error("HumanoidRootPart not found")
        end
        
        -- Create CFrame with position and rotation
        local pos = SavedSettings.SavedPosition
        local position = Vector3.new(pos.X, pos.Y, pos.Z)
        local rotation = math.rad(SavedSettings.SavedRotation or 0)
        
        -- Teleport with rotation
        local targetCFrame = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
        
        HumanoidRootPart.CFrame = targetCFrame
        task.wait(0.1)
        
        if Character.PrimaryPart then
            Character:PivotTo(targetCFrame)
        end
        
        print("[LOAD] Teleported to saved position!")
        print("[LOAD] Position:", position)
        print("[LOAD] Rotation:", SavedSettings.SavedRotation, "degrees")
        
        Stats.TeleportCount = Stats.TeleportCount + 1
    end)
    
    if success then
        Rayfield:Notify({
            Title = "📍 Load Berhasil",
            Content = "Teleport ke posisi tersimpan!",
            Duration = 3,
            Image = 4483362458
        })
        return true
    else
        print("[LOAD] Error:", err)
        Rayfield:Notify({
            Title = "Load Error",
            Content = "Gagal load posisi: " .. tostring(err),
            Duration = 3,
            Image = 4483362458
        })
        return false
    end
end

-- Delete save file
local function DeleteSave()
    local success, err = pcall(function()
        if isfile(SaveFileName) then
            delfile(SaveFileName)
            print("[DELETE] Save file deleted!")
            
            -- Reset saved settings
            SavedSettings.HasSavedPosition = false
            SavedSettings.SavedPosition = nil
            SavedSettings.SavedRotation = nil
            
            return true
        else
            print("[DELETE] No save file found")
            return false
        end
    end)
    
    if success then
        Rayfield:Notify({
            Title = "🗑️ Save Dihapus",
            Content = "Data save berhasil dihapus!",
            Duration = 3,
            Image = 4483362458
        })
    else
        print("[DELETE] Error:", err)
    end
    
    return success
end

-- Auto execute marker
local function SetAutoExecute()
    local marker = "FishIt_AutoExecute_" .. game.PlaceId
    writefile(marker, tostring(os.time()))
    print("[AUTO_EXEC] Marker set for auto execute on rejoin")
end

local function CheckAutoExecute()
    local marker = "FishIt_AutoExecute_" .. game.PlaceId
    if isfile(marker) then
        delfile(marker)
        return true
    end
    return false
end

-------------------------------------------
----- ISLAND TELEPORT LOCATIONS
-------------------------------------------
local IslandLocations = {
    ["Fisherman Island"] = CFrame.new(400, 140, 250),
    ["Coral Reef Island"] = CFrame.new(-500, 140, 800),
    ["Tropical Grove Island"] = CFrame.new(1200, 140, -600),
    ["Kohana Island"] = CFrame.new(-1500, 140, -1500),
    ["Kohana Volcano"] = CFrame.new(-1600, 200, -1700),
    ["Crater Island"] = CFrame.new(2000, 140, 2000),
    ["Esoteric Depths"] = CFrame.new(500, 50, 300),
    ["Lost Isle"] = CFrame.new(-3000, 140, 3000),
    ["Ancient Jungle Island"] = CFrame.new(3500, 140, -2500),
    ["Classic Island"] = CFrame.new(5000, 140, 0),
    ["Heart Island"] = CFrame.new(-800, 140, 2500),
    ["Christmas Island"] = CFrame.new(1800, 140, 1800)
}

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
    MinigameCompleted = 0,
    TeleportCount = 0
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
----- MINIGAME GUI DETECTOR
-------------------------------------------
local function FindMinigameGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local possibleNames = {
        "FishingMinigame",
        "Minigame",
        "ReelGame",
        "FishGame",
        "CatchGame",
        "F
