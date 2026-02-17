--[[
    FISCH V2 - FLUENT EDITION (COMPLETE)
    - Fitur: Auto-Fish, SFX Cleaner, Shop, Crafting
    - Stats: Timer, Total Ikan, Fish Per Minute (FPM)
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ CONFIG & STATS ]]
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    IsCleanMode = false,
    BuyID = 14,
    CraftName = "Anchor Charm"
}

local Stats = {
    StartTime = 0,
    FishCount = 0
}

-- [[ VISUAL CLEANER LOGIC ]]
local function CleanUI(obj)
    pcall(function()
        if not Settings.IsCleanMode then return end
        if obj:IsA("ViewportFrame") then 
            obj:Destroy() 
        elseif obj:IsA("ImageLabel") and obj.Name:lower():match("fish") then
            obj.Visible = false
        end
    end)
end

-- [[ WINDOW SETUP ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH V2 | IXE",
    SubTitle = "Complete Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 350), -- Ukuran sedikit lebih tinggi untuk stats
    Acrylic = false, 
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Shop = Window:AddTab({ Title = "Shop & Craft", Icon = "shopping-cart" })
}

-- [[ FISHING TAB ]]

-- 1. Progress & Stats Paragraph
local StatsDisplay = Tabs.Main:AddParagraph({
    Title = "Statistics",
    Content = "🐟 Ikan: 0\n⏱️ Waktu: 00:00\n⚡ FPM: 0"
})

Tabs.Main:AddDivider()

-- 2. SFX Cleaner Toggle
local CleanToggle = Tabs.Main:AddToggle("SFXToggle", {Title = "SFX / Visual Cleaner", Default = false })
CleanToggle:OnChanged(function()
    Settings.IsCleanMode = CleanToggle.Value
    if Settings.IsCleanMode then
        for _, v in pairs(PlayerGui:GetDescendants()) do CleanUI(v) end
        _G.CleanConn = PlayerGui.DescendantAdded:Connect(CleanUI)
    else
        if _G.CleanConn then _G.CleanConn:Disconnect() end
    end
end)

-- 3. Auto Fish Toggle
local FarmToggle = Tabs.Main:AddToggle("AutoFish", {Title = "Start Auto Fishing", Default = false })
FarmToggle:OnChanged(function()
    Settings.IsFarming = FarmToggle.Value
    if Settings.IsFarming then
        Stats.StartTime = tick()
        Stats.FishCount = 0
        
        task.spawn(function()
            local Cast = ReplicatedStorage:FindFirstChild("ChargeFishingRod", true)
            local Mini = ReplicatedStorage:FindFirstChild("RequestFishingMinigameStarted", true)
            local Done = ReplicatedStorage:FindFirstChild("CatchFishCompleted", true)
            
            while Settings.IsFarming do
                if Cast then pcall(function() Cast:InvokeServer(nil, nil, tick(), nil) end) end
                task.wait(Settings.BiteDelay)
                if Mini then pcall(function() Mini:InvokeServer(0.5, 0.5, tick()) end) end
                task.wait(0.1)
                if Done then pcall(function() Done:InvokeServer() end) end
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

Tabs.Main:AddSlider("BiteSlider", {
    Title = "Bite Delay",
    Default = 2.5,
    Min = 1, Max = 5, Rounding = 1,
    Callback = function(V) Settings.BiteDelay = V end
})

-- [[ SHOP & CRAFT TAB ]]
Tabs.Shop:AddInput("ItemID", {
    Title = "Item ID",
    Default = "14",
    Callback = function(V) Settings.BuyID = tonumber(V) or 14 end
})

Tabs.Shop:AddButton({
    Title = "Purchase Item",
    Callback = function()
        local Buy = ReplicatedStorage:FindFirstChild("PurchaseCharm", true)
        if Buy then pcall(function() Buy:InvokeServer(Settings.BuyID) end) end
    end
})

Tabs.Shop:AddDropdown("CraftDropdown", {
    Title = "Select Charm",
    Values = {"Anchor Charm", "Winged Charm", "Heart Charm", "Lure Charm"},
    Default = "Anchor Charm",
    Callback = function(V) Settings.CraftName = V end
})

Tabs.Shop:AddButton({
    Title = "Start Crafting",
    Callback = function()
        local SC = ReplicatedStorage:FindFirstChild("StartCrafting", true)
        local CC = ReplicatedStorage:FindFirstChild("ConfirmCrafting", true)
        if SC and CC then 
            pcall(function() SC:InvokeServer(Settings.CraftName) end)
            task.wait(0.5)
            pcall(function() CC:InvokeServer() end)
        end
    end
})

-- [[ BACKGROUND LOOPS ]]

-- Loop untuk Update Stats (Timer & FPM)
task.spawn(function()
    while task.wait(1) do
        if Settings.IsFarming and Stats.StartTime > 0 then
            local elapsed = tick() - Stats.StartTime
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            local fpm = (elapsed > 10) and math.floor((Stats.FishCount / elapsed) * 60) or 0
            
            StatsDisplay:SetContent(string.format(
                "🐟 Ikan: %d\n⏱️ Waktu: %02d:%02d\n⚡ FPM: %d",
                Stats.FishCount, mins, secs, fpm
            ))
        end
    end
end)

-- Listener untuk Count Ikan
local NotifRemote = ReplicatedStorage:FindFirstChild("ObtainedNewFishNotification", true)
if NotifRemote then
    NotifRemote.OnClientEvent:Connect(function()
        if Settings.IsFarming then
            Stats.FishCount = Stats.FishCount + 1
        end
    end)
end

Window:SelectTab(1)
