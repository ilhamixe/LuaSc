--[[
    FISCH ULTIMATE V2 (GITHUB REPO VERSION)
    - Tabbed UI (Fishing & Shop/Craft)
    - Minimize to "IXE" Icon & Exit System
    - Mobile-Friendly Smooth Dragging
    - Dropdown Crafting List
]]

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ====================================================
-- 1. CONFIG & STATE
-- ====================================================
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    IsCleanMode = false,
    BuyID = 14,
    BuyAmt = 1,
    CraftName = "Anchor Charm",
    CraftAmt = 1,
    EquipName = "Heart Charm",
    IsProcessing = false
}

local Stats = { StartTime = 0, FishCount = 0 }
local CraftItems = {"Anchor Charm", "Winged Charm", "Heart Charm", "Lure Charm", "Bait Charm"}

-- ====================================================
-- 2. REMOTE FINDER
-- ====================================================
local function GetNetRemote(name)
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    local Index = Packages and Packages:FindFirstChild("_Index")
    if Index then
        for _, folder in pairs(Index:GetChildren()) do
            if folder.Name:match("sleitnick_net") then
                local NetFolder = folder:FindFirstChild("net")
                if NetFolder then return NetFolder:FindFirstChild(name) end
            end
        end
    end
    return nil
end

local Remotes = {
    Cast = GetNetRemote("RF/ChargeFishingRod"),
    StartMini = GetNetRemote("RF/RequestFishingMinigameStarted"),
    Finish = GetNetRemote("RF/CatchFishCompleted"),
    Notif = GetNetRemote("RE/ObtainedNewFishNotification"),
    Purchase = GetNetRemote("RF/PurchaseCharm"),
    StartCraft = GetNetRemote("RF/StartCrafting"),
    ConfirmCraft = GetNetRemote("RF/ConfirmCrafting"),
    Equip = GetNetRemote("RE/EquipCharm"),
    Cutscene = GetNetRemote("RE/ReplicateCutscene")
}

-- ====================================================
-- 3. MOBILE DRAGGING FIX
-- ====================================================
local function MakeDraggable(frame, parentFrame)
    parentFrame = parentFrame or frame
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = parentFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            parentFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- ====================================================
-- 4. GUI CONSTRUCTION
-- ====================================================
if CoreGui:FindFirstChild("FischV2App") then CoreGui.FischV2App:Destroy() end
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "FischV2App"; ScreenGui.Parent = CoreGui

-- [[ MINI ICON ]]
local MiniIcon = Instance.new("TextButton")
MiniIcon.Size = UDim2.new(0, 55, 0, 55); MiniIcon.Position = UDim2.new(0, 10, 0.5, 0)
MiniIcon.BackgroundColor3 = Color3.fromRGB(0, 170, 255); MiniIcon.Text = "IXE"
MiniIcon.Font = Enum.Font.GothamBlack; MiniIcon.TextColor3 = Color3.fromRGB(255, 255, 255); MiniIcon.TextSize = 18
MiniIcon.Visible = false; MiniIcon.Parent = ScreenGui; Instance.new("UICorner", MiniIcon)
MakeDraggable(MiniIcon)

-- [[ MAIN FRAME ]]
local Main = Instance.new("Frame"); Main.Size = UDim2.new(0, 320, 0, 330); Main.Position = UDim2.new(0.5, -160, 0.5, -165)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 26); Main.BorderSizePixel = 0; Main.Parent = ScreenGui
Instance.new("UICorner", Main)

-- Header
local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 35); Header.BackgroundTransparency = 1; Header.Parent = Main
local Title = Instance.new("TextLabel"); Title.Text = "FISCH V2 | IXE"; Title.Size = UDim2.new(0.6, 0, 1, 0); Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.TextColor3 = Color3.fromRGB(0, 200, 255); Title.Font = Enum.Font.GothamBlack; Title.BackgroundTransparency = 1; Title.TextXAlignment = 0; Title.Parent = Header
MakeDraggable(Header, Main)

local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -30, 0.5, -12); CloseBtn.Text = "×"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseBtn.Parent = Header; Instance.new("UICorner", CloseBtn)
local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 25, 0, 25); MinBtn.Position = UDim2.new(1, -60, 0.5, -12); MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55); MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Parent = Header; Instance.new("UICorner", MinBtn)

-- Sidebar
local Sidebar = Instance.new("Frame"); Sidebar.Size = UDim2.new(0, 80, 1, -35); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 16, 20); Sidebar.Parent = Main; Instance.new("UICorner", Sidebar)
local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -90, 1, -45); Container.Position = UDim2.new(0, 85, 0, 40); Container.BackgroundTransparency = 1; Container.Parent = Main

local FishingPage = Instance.new("ScrollingFrame"); FishingPage.Size = UDim2.new(1, 0, 1, 0); FishingPage.BackgroundTransparency = 1; FishingPage.ScrollBarTransparency = 1; FishingPage.Parent = Container
local ShopPage = Instance.new("ScrollingFrame"); ShopPage.Size = UDim2.new(1, 0, 1, 0); ShopPage.BackgroundTransparency = 1; ShopPage.Visible = false; ShopPage.ScrollBarTransparency = 1; ShopPage.Parent = Container

-- ====================================================
-- 5. WINDOW LOGIC
-- ====================================================
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MiniIcon.Visible = true end)
MiniIcon.MouseButton1Click:Connect(function() Main.Visible = true; MiniIcon.Visible = false end)

local function CreateTab(y, txt, pName)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0.8, 0, 0, 35); b.Position = UDim2.new(0.1, 0, 0, y)
    b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(30, 32, 38); b.TextColor3 = Color3.fromRGB(200, 200, 200); b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = Sidebar; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() FishingPage.Visible = (pName == "Fish"); ShopPage.Visible = (pName == "Shop") end)
end
CreateTab(10, "FISHING", "Fish"); CreateTab(50, "SHOP & CRAFT", "Shop")

-- ====================================================
-- 6. PAGE: FISHING
-- ====================================================
local StatLbl = Instance.new("TextLabel"); StatLbl.Size = UDim2.new(1, 0, 0, 30); StatLbl.Text = "Status: Idle"; StatLbl.TextColor3 = Color3.fromRGB(0, 255, 150); StatLbl.BackgroundTransparency = 1; StatLbl.Parent = FishingPage
local function AddInput(p, y, label, def, callback)
    local l = Instance.new("TextLabel"); l.Text = label; l.Size = UDim2.new(1, 0, 0, 15); l.Position = UDim2.new(0, 0, 0, y); l.TextColor3 = Color3.fromRGB(150, 150, 150); l.BackgroundTransparency = 1; l.TextSize = 9; l.Parent = p
    local i = Instance.new("TextBox"); i.Text = tostring(def); i.Size = UDim2.new(0.8, 0, 0, 25); i.Position = UDim2.new(0.1, 0, 0, y+15); i.BackgroundColor3 = Color3.fromRGB(30, 32, 40); i.TextColor3 = Color3.fromRGB(255, 255, 255); i.Parent = p; Instance.new("UICorner", i)
    i.FocusLost:Connect(function() callback(i.Text) end)
end

AddInput(FishingPage, 35, "Bite Delay", Settings.BiteDelay, function(t) Settings.BiteDelay = tonumber(t) or 2.5 end)
AddInput(FishingPage, 80, "Cooldown", Settings.Cooldown, function(t) Settings.Cooldown = tonumber(t) or 0 end)

local sfxBtn = Instance.new("TextButton"); sfxBtn.Size = UDim2.new(0.8, 0, 0, 30); sfxBtn.Position = UDim2.new(0.1, 0, 0, 125); sfxBtn.Text = "SFX CLEANER: OFF"; sfxBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); sfxBtn.Parent = FishingPage; Instance.new("UICorner", sfxBtn)
sfxBtn.MouseButton1Click:Connect(function() 
    Settings.IsCleanMode = not Settings.IsCleanMode
    sfxBtn.Text = Settings.IsCleanMode and "SFX CLEANER: ON" or "SFX CLEANER: OFF"
    sfxBtn.BackgroundColor3 = Settings.IsCleanMode and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 60)
end)

local farmBtn = Instance.new("TextButton"); farmBtn.Size = UDim2.new(0.8, 0, 0, 40); farmBtn.Position = UDim2.new(0.1, 0, 0, 165); farmBtn.Text = "START FISHING"; farmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100); farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255); farmBtn.Font = Enum.Font.GothamBlack; farmBtn.Parent = FishingPage; Instance.new("UICorner", farmBtn)
farmBtn.MouseButton1Click:Connect(function()
    Settings.IsFarming = not Settings.IsFarming
    farmBtn.Text = Settings.IsFarming and "STOP" or "START FISHING"
    farmBtn.BackgroundColor3 = Settings.IsFarming and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 100)
    if Settings.IsFarming then 
        Stats.StartTime = tick(); Stats.FishCount = 0
        task.spawn(function()
            while Settings.IsFarming do
                pcall(function() Remotes.Cast:InvokeServer(nil, nil, tick(), nil) end)
                task.wait(Settings.BiteDelay)
                pcall(function() Remotes.StartMini:InvokeServer(0.5, 0.5, tick()) end)
                task.wait(0.05)
                pcall(function() Remotes.Finish:InvokeServer() end)
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

-- ====================================================
-- 7. PAGE: SHOP & CRAFT
-- ====================================================
AddInput(ShopPage, 5, "Buy ID", Settings.BuyID, function(t) Settings.BuyID = tonumber(t) or 14 end)
local buyBtn = Instance.new("TextButton"); buyBtn.Size = UDim2.new(0.8, 0, 0, 30); buyBtn.Position = UDim2.new(0.1, 0, 0, 50); buyBtn.Text = "BUY ITEM"; buyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200); buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255); buyBtn.Parent = ShopPage; Instance.new("UICorner", buyBtn)
buyBtn.MouseButton1Click:Connect(function() pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end) end)

-- Dropdown Craft
local dropBtn = Instance.new("TextButton"); dropBtn.Size = UDim2.new(0.8, 0, 0, 30); dropBtn.Position = UDim2.new(0.1, 0, 0, 95); dropBtn.Text = "Select Charm..."; dropBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60); dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255); dropBtn.Parent = ShopPage; Instance.new("UICorner", dropBtn)
local dropList = Instance.new("ScrollingFrame"); dropList.Size = UDim2.new(0.8, 0, 0, 100); dropList.Position = UDim2.new(0.1, 0, 0, 125); dropList.BackgroundColor3 = Color3.fromRGB(30, 30, 35); dropList.Visible = false; dropList.CanvasSize = UDim2.new(0,0,0,#CraftItems*25); dropList.ZIndex = 5; dropList.Parent = ShopPage
for i, name in pairs(CraftItems) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 25); b.Position = UDim2.new(0, 0, 0, (i-1)*25); b.Text = name; b.BackgroundTransparency = 1; b.TextColor3 = Color3.fromRGB(200, 200, 200); b.Parent = dropList
    b.MouseButton1Click:Connect(function() Settings.CraftName = name; dropBtn.Text = name; dropList.Visible = false end)
end
dropBtn.MouseButton1Click:Connect(function() dropList.Visible = not dropList.Visible end)

local craftBtn = Instance.new("TextButton"); craftBtn.Size = UDim2.new(0.8, 0, 0, 35); craftBtn.Position = UDim2.new(0.1, 0, 0, 235); craftBtn.Text = "START CRAFTING"; craftBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0); craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255); craftBtn.Parent = ShopPage; Instance.new("UICorner", craftBtn)
craftBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        pcall(function() Remotes.StartCraft:InvokeServer(Settings.CraftName) end)
        task.wait(0.3); pcall(function() Remotes.ConfirmCraft:InvokeServer() end)
    end)
end)

-- Stats Loop
task.spawn(function()
    while Main.Parent do
        if Settings.IsFarming then
            local dur = tick() - Stats.StartTime
            local fpm = dur > 5 and math.floor((Stats.FishCount/dur)*60) or 0
            StatLbl.Text = string.format("🐟 %d | ⏱️ %02d:%02d | ⚡ %d FPM", Stats.FishCount, math.floor(dur/60), math.floor(dur%60), fpm)
        end
        task.wait(1)
    end
end)
if Remotes.Notif then Remotes.Notif.OnClientEvent:Connect(function() if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end end) end
