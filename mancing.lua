--[[
    Fish It Auto Fish Script
    Author: Your Name
    Version: 1.0
    License: MIT
    
    Features:
    - Auto Cast & Auto Catch
    - Auto Sell Fish
    - Customizable Speed
    - Simple GUI (Rayfield UI)
]]

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Fish It Auto Farm",
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "by Your Name",
   ConfigurationSaving = {
      Enabled = false,
      FileName = "FishItConfig"
   }
})

-- Variables
local AutoFish = false
local AutoSell = false
local FishingSpeed = 0.5

-- Get Player & Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Main Tab
local MainTab = Window:CreateTab("🎣 Auto Fish", nil)
local Section = MainTab:CreateSection("Main Features")

-- Toggle Auto Fish
MainTab:CreateToggle({
   Name = "Auto Fish",
   CurrentValue = false,
   Flag = "AutoFishToggle",
   Callback = function(Value)
       AutoFish = Value
       print("Auto Fish:", Value)
   end,
})

-- Toggle Auto Sell
MainTab:CreateToggle({
   Name = "Auto Sell",
   CurrentValue = false,
   Flag = "AutoSellToggle",
   Callback = function(Value)
       AutoSell = Value
       print("Auto Sell:", Value)
   end,
})

-- Fishing Speed Slider
MainTab:CreateSlider({
   Name = "Fishing Speed",
   Range = {0.1, 2},
   Increment = 0.1,
   CurrentValue = 0.5,
   Flag = "SpeedSlider",
   Callback = function(Value)
       FishingSpeed = Value
       print("Speed set to:", Value)
   end,
})

-- Auto Fish Function
spawn(function()
    while task.wait(FishingSpeed) do
        if AutoFish and Character then
            pcall(function()
                -- Ganti dengan remote Fish It yang benar
                -- Contoh: ReplicatedStorage.Events.CastRod:FireServer()
                local CastEvent = ReplicatedStorage:FindFirstChild("CastRod") or ReplicatedStorage:FindFirstChild("Events")
                
                if CastEvent then
                    -- Cast Rod
                    CastEvent:FireServer()
                    task.wait(0.5)
                    
                    -- Auto Catch (ganti sesuai event game)
                    local CatchEvent = ReplicatedStorage:FindFirstChild("CatchFish")
                    if CatchEvent then
                        CatchEvent:FireServer()
                    end
                end
            end)
        end
    end
end)

-- Auto Sell Function
spawn(function()
    while task.wait(5) do
        if AutoSell then
            pcall(function()
                -- Teleport ke Sell NPC atau fire sell event
                local SellEvent = ReplicatedStorage:FindFirstChild("SellFish")
                if SellEvent then
                    SellEvent:FireServer()
                end
            end)
        end
    end
end)

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings", nil)
SettingsTab:CreateSection("Script Info")

SettingsTab:CreateParagraph({Title = "Version", Content = "v1.0 - Open Source"})
SettingsTab:CreateButton({
   Name = "Destroy GUI",
   Callback = function()
       Rayfield:Destroy()
   end,
})
