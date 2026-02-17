--[[
    FISCH V2 - IXE EDITION (FIXED BUTTONS)
    - Fix: Hidden Buttons
    - Fix: Custom IXE Minimize Symbol
    - Library: Fluent (No Acrylic for Mobile)
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ SETTINGS & STATS ]]
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    IsCleanMode = false,
    BuyID = 14,
    CraftName = "Anchor Charm"
}
local Stats = { StartTime = 0, FishCount = 0 }
local CraftItems = {"Anchor Charm", "Winged Charm", "Heart Charm", "Lure Charm"}

-- [[ 1. CREATE WINDOW ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH V2 | IXE",
    SubTitle = "Mobile Stable",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = false, -- WAJIB FALSE agar tidak blank
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Keybind PC, abaikan buat Mobile
})

-- [[ 2. TABS SETUP ]]
local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Shop = Window:AddTab({ Title = "Shop & Craft", Icon = "shopping-cart" })
}

-- [[ 3. FISHING CONTENT ]]
local StatsDisplay = Tabs.Main:AddParagraph({
    Title = "Live Statistics",
    Content = "🐟 Ikan: 0\n⏱️ Waktu: 00:00\n⚡ FPM: 0"
})

-- Toggle SFX Cleaner
local CleanToggle = Tabs.Main:AddToggle("SFXToggle", {Title = "SFX Cleaner (Anti-Lag)", Default = false })
CleanToggle:OnChanged(function()
    Settings.IsCleanMode = CleanToggle.Value
end)

-- Toggle Auto Fish
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

-- Slider Bite Delay
Tabs.Main:AddSlider("BiteSlider", {
    Title = "Bite Delay",
    Default = 2.5,
    Min = 1, Max = 5, Rounding = 1,
    Callback = function(V) Settings.BiteDelay = V end
})

-- [[ 4. SHOP & CRAFT CONTENT ]]
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
    Values = CraftItems,
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

-- [[ 5. CUSTOM IXE MINIMIZE BUTTON (FIX) ]]
-- Mencari ScreenGui buatan Fluent
local FluentGui = PlayerGui:FindFirstChild("FluentGui") or CoreGui:FindFirstChild("FluentGui")
if not FluentGui then
    -- Jika library ganti nama, kita cari ScreenGui yang punya Frame 'Main'
    for _, v in pairs(PlayerGui:GetChildren()) do
        if v:IsA("ScreenGui") and v:FindFirstChild("Main", true) then
            FluentGui = v
            break
        end
    end
end

if FluentGui then
    local MainFrame = FluentGui:FindFirstChild("Main", true)
    
    -- Buat Tombol IXE Melayang
    local IxeBtn = Instance.new("TextButton")
    IxeBtn.Name = "IxeMinimize"
    IxeBtn.Parent = FluentGui
    IxeBtn.Size = UDim2.new(0, 50, 0, 50)
    IxeBtn.Position = UDim2.new(0, 10, 0.5, 0) -- Di kiri tengah
    IxeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    IxeBtn.Text = "IXE"
    IxeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    IxeBtn.Font = Enum.Font.GothamBlack
    IxeBtn.TextSize = 18
    IxeBtn.Visible = false -- Sembunyi saat Menu buka
    IxeBtn.ZIndex = 10000 -- Paling depan
    Instance.new("UICorner", IxeBtn).CornerRadius = UDim.new(0, 10)
    
    -- Tambahkan fitur Dragging buat tombol IXE (Biar bisa digeser)
    local UserInputService = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos
    IxeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = IxeBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            IxeBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    IxeBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    -- Fungsi Toggle
    IxeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        IxeBtn.Visible = false
    end)
    
    -- Tambahkan tombol Minimize di Header Fluent
    -- Karena Fluent tidak kasih akses mudah ke tombol min, kita pakai logika:
    -- Jika User menekan tombol minimize asli Fluent, paksakan IxeBtn muncul.
    task.spawn(function()
        while task.wait(0.5) do
            if MainFrame.Visible == false then
                IxeBtn.Visible = true
            end
        end
    end)
end

-- [[ 6. BACKGROUND LOOPS ]]
task.spawn(function()
    while task.wait(1) do
        if Settings.IsFarming and Stats.StartTime > 0 then
            local elapsed = tick() - Stats.StartTime
            local mins, secs = math.floor(elapsed / 60), math.floor(elapsed % 60)
            local fpm = (elapsed > 10) and math.floor((Stats.FishCount / elapsed) * 60) or 0
            StatsDisplay:SetContent(string.format("🐟 Ikan: %d\n⏱️ Waktu: %02d:%02d\n⚡ FPM: %d", Stats.FishCount, mins, secs, fpm))
        end
    end
end)

local NotifRemote = ReplicatedStorage:FindFirstChild("ObtainedNewFishNotification", true)
if NotifRemote then
    NotifRemote.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

Window:SelectTab(1)
