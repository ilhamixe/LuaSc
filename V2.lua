--[[
    FISCH ULTIMATE V2 (FIXED FOR MOBILE)
    - Anti-Stuck Loading (UI muncul duluan)
    - Touch-Optimized Dragging
    - Fix Black Screen / Blank UI
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ====================================================
-- 1. SETTINGS & GLOBALS
-- ====================================================
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    BuyID = 14,
    CraftName = "Anchor Charm",
    IsProcessing = false
}

local Stats = { StartTime = 0, FishCount = 0 }
local CraftItems = {"Anchor Charm", "Winged Charm", "Heart Charm", "Lure Charm", "Bait Charm"}
local Remotes = {}

-- [[ ASYNC REMOTE FINDER ]]
-- Kita jalankan di background agar UI tidak macet
task.spawn(function()
    local function GetNet(name)
        local p = ReplicatedStorage:FindFirstChild("Packages")
        local idx = p and p:FindFirstChild("_Index")
        if idx then
            for _, f in pairs(idx:GetChildren()) do
                if f.Name:match("sleitnick_net") then
                    local n = f:FindFirstChild("net")
                    if n then return n:FindFirstChild(name) end
                end
            end
        end
        return nil
    end

    Remotes.Cast = GetNet("RF/ChargeFishingRod")
    Remotes.StartMini = GetNet("RF/RequestFishingMinigameStarted")
    Remotes.Finish = GetNet("RF/CatchFishCompleted")
    Remotes.Notif = GetNet("RE/ObtainedNewFishNotification")
    Remotes.Purchase = GetNet("RF/PurchaseCharm")
    Remotes.StartCraft = GetNet("RF/StartCrafting")
    Remotes.ConfirmCraft = GetNet("RF/ConfirmCrafting")
    
    if Remotes.Notif then
        Remotes.Notif.OnClientEvent:Connect(function()
            if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
        end)
    end
end)

-- ====================================================
-- 2. MOBILE DRAGGING ENGINE
-- ====================================================
local function MakeDraggable(UI, DragArea)
    DragArea = DragArea or UI
    local dragging, dragInput, dragStart, startPos

    DragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UI.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            UI.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    DragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ====================================================
-- 3. UI RENDERING (FIXED)
-- ====================================================
if CoreGui:FindFirstChild("FischMobileApp") then CoreGui.FischMobileApp:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FischMobileApp"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

-- [[ IXE ICON (MINIMIZE) ]]
local MiniIcon = Instance.new("TextButton")
MiniIcon.Size = UDim2.new(0, 60, 0, 60); MiniIcon.Position = UDim2.new(0, 10, 0.4, 0)
MiniIcon.BackgroundColor3 = Color3.fromRGB(0, 170, 255); MiniIcon.Text = "IXE"
MiniIcon.Font = Enum.Font.GothamBlack; MiniIcon.TextColor3 = Color3.fromRGB(255, 255, 255); MiniIcon.TextSize = 20
MiniIcon.Visible = false; MiniIcon.Active = true; MiniIcon.Parent = ScreenGui
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 15)
MakeDraggable(MiniIcon)

-- [[ MAIN FRAME ]]
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 300); Main.Position = UDim2.new(0.5, -160, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(25, 27, 32); Main.BorderSizePixel = 0; Main.Active = true; Main.Visible = true; Main.Parent = ScreenGui
Instance.new("UICorner", Main)

-- Header
local Header = Instance.new("Frame"); Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundTransparency = 1; Header.Parent = Main
local Title = Instance.new("TextLabel"); Title.Text = " FISCH V2 | IXE"; Title.Size = UDim2.new(0.6, 0, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0)
Title.TextColor3 = Color3.fromRGB(0, 200, 255); Title.Font = Enum.Font.GothamBlack; Title.BackgroundTransparency = 1; Title.TextXAlignment = 0; Title.Parent = Header
MakeDraggable(Main, Header)

-- Window Controls
local ExitBtn = Instance.new("TextButton"); ExitBtn.Size = UDim2.new(0, 30, 0, 30); ExitBtn.Position = UDim2.new(1, -35, 0, 5)
ExitBtn.Text = "×"; ExitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); ExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ExitBtn.Parent = Header; Instance.new("UICorner", ExitBtn)

local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.Text = "-"; MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65); MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Parent = Header; Instance.new("UICorner", MinBtn)

-- Sidebar
local Sidebar = Instance.new("Frame"); Sidebar.Size = UDim2.new(0, 85, 1, -45); Sidebar.Position = UDim2.new(0, 5, 0, 40); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 20, 24); Sidebar.Parent = Main; Instance.new("UICorner", Sidebar)

-- Pages
local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -100, 1, -50); Container.Position = UDim2.new(0, 95, 0, 45); Container.BackgroundTransparency = 1; Container.Parent = Main
local FishPage = Instance.new("ScrollingFrame"); FishPage.Size = UDim2.new(1, 0, 1, 0); FishPage.BackgroundTransparency = 1; FishPage.ScrollBarTransparency = 1; FishPage.Visible = true; FishPage.Parent = Container
local ShopPage = Instance.new("ScrollingFrame"); ShopPage.Size = UDim2.new(1, 0, 1, 0); ShopPage.BackgroundTransparency = 1; ShopPage.ScrollBarTransparency = 1; ShopPage.Visible = false; ShopPage.Parent = Container

-- ====================================================
-- 4. BUTTON ACTIONS
-- ====================================================
ExitBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
MinBtn.MouseButton1Click:Connect(function() Main.Visible = false; MiniIcon.Visible = true end)
MiniIcon.MouseButton1Click:Connect(function() Main.Visible = true; MiniIcon.Visible = false end)

local function CreateTab(y, txt, pName)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0.9, 0, 0, 35); b.Position = UDim2.new(0.05, 0, 0, y)
    b.Text = txt; b.BackgroundColor3 = Color3.fromRGB(35, 38, 45); b.TextColor3 = Color3.fromRGB(200, 200, 200); b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.Parent = Sidebar; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() FishPage.Visible = (pName == "Fish"); ShopPage.Visible = (pName == "Shop") end)
end
CreateTab(10, "FISHING", "Fish"); CreateTab(50, "SHOP", "Shop")

-- ====================================================
-- 5. FISHING CONTENT
-- ====================================================
local StatLbl = Instance.new("TextLabel"); StatLbl.Size = UDim2.new(1, 0, 0, 30); StatLbl.Text = "Status: Idle"; StatLbl.TextColor3 = Color3.fromRGB(0, 255, 150); StatLbl.BackgroundTransparency = 1; StatLbl.Parent = FishPage

local function AddInput(p, y, label, def, callback)
    local l = Instance.new("TextLabel"); l.Text = label; l.Size = UDim2.new(1, 0, 0, 15); l.Position = UDim2.new(0, 0, 0, y); l.TextColor3 = Color3.fromRGB(180, 180, 180); l.BackgroundTransparency = 1; l.TextSize = 10; l.Parent = p
    local i = Instance.new("TextBox"); i.Text = tostring(def); i.Size = UDim2.new(0.9, 0, 0, 30); i.Position = UDim2.new(0, 0, 0, y+15); i.BackgroundColor3 = Color3.fromRGB(40, 43, 50); i.TextColor3 = Color3.fromRGB(255, 255, 255); i.Parent = p; Instance.new("UICorner", i)
    i.FocusLost:Connect(function() callback(i.Text) end)
end

AddInput(FishPage, 40, "Bite Delay", Settings.BiteDelay, function(t) Settings.BiteDelay = tonumber(t) or 2.5 end)
AddInput(FishPage, 90, "Cooldown", Settings.Cooldown, function(t) Settings.Cooldown = tonumber(t) or 0 end)

local farmBtn = Instance.new("TextButton"); farmBtn.Size = UDim2.new(0.9, 0, 0, 45); farmBtn.Position = UDim2.new(0, 0, 0, 160); farmBtn.Text = "START FISHING"; farmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100); farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255); farmBtn.Font = Enum.Font.GothamBlack; farmBtn.Parent = FishPage; Instance.new("UICorner", farmBtn)

farmBtn.MouseButton1Click:Connect(function()
    Settings.IsFarming = not Settings.IsFarming
    farmBtn.Text = Settings.IsFarming and "STOP" or "START FISHING"
    farmBtn.BackgroundColor3 = Settings.IsFarming and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(0, 180, 100)
    
    if Settings.IsFarming then
        Stats.StartTime = tick(); Stats.FishCount = 0
        task.spawn(function()
            while Settings.IsFarming do
                if Remotes.Cast then pcall(function() Remotes.Cast:InvokeServer(nil, nil, tick(), nil) end) end
                task.wait(Settings.BiteDelay)
                if Remotes.StartMini then pcall(function() Remotes.StartMini:InvokeServer(0.5, 0.5, tick()) end) end
                task.wait(0.1)
                if Remotes.Finish then pcall(function() Remotes.Finish:InvokeServer() end) end
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

-- ====================================================
-- 6. SHOP CONTENT
-- ====================================================
AddInput(ShopPage, 5, "Item ID", Settings.BuyID, function(t) Settings.BuyID = tonumber(t) or 14 end)
local buyBtn = Instance.new("TextButton"); buyBtn.Size = UDim2.new(0.9, 0, 0, 35); buyBtn.Position = UDim2.new(0, 0, 0, 55); buyBtn.Text = "BUY ITEM"; buyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200); buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255); buyBtn.Parent = ShopPage; Instance.new("UICorner", buyBtn)
buyBtn.MouseButton1Click:Connect(function() if Remotes.Purchase then pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end) end end)

-- Dropdown Craft
local dropBtn = Instance.new("TextButton"); dropBtn.Size = UDim2.new(0.9, 0, 0, 35); dropBtn.Position = UDim2.new(0, 0, 0, 110); dropBtn.Text = "Select Charm..."; dropBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 65); dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255); dropBtn.Parent = ShopPage; Instance.new("UICorner", dropBtn)
local dropList = Instance.new("ScrollingFrame"); dropList.Size = UDim2.new(0.9, 0, 0, 100); dropList.Position = UDim2.new(0, 0, 0, 150); dropList.BackgroundColor3 = Color3.fromRGB(30, 32, 38); dropList.Visible = false; dropList.ZIndex = 10; dropList.Parent = ShopPage
for i, name in pairs(CraftItems) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 30); b.Position = UDim2.new(0, 0, 0, (i-1)*30); b.Text = name; b.BackgroundTransparency = 1; b.TextColor3 = Color3.fromRGB(220, 220, 220); b.Parent = dropList
    b.MouseButton1Click:Connect(function() Settings.CraftName = name; dropBtn.Text = name; dropList.Visible = false end)
end
dropBtn.MouseButton1Click:Connect(function() dropList.Visible = not dropList.Visible end)

local craftBtn = Instance.new("TextButton"); craftBtn.Size = UDim2.new(0.9, 0, 0, 35); craftBtn.Position = UDim2.new(0, 0, 0, 260); craftBtn.Text = "CRAFT ITEM"; craftBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0); craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255); craftBtn.Parent = ShopPage; Instance.new("UICorner", craftBtn)
craftBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        if Remotes.StartCraft then pcall(function() Remotes.StartCraft:InvokeServer(Settings.CraftName) end) end
        task.wait(0.3)
        if Remotes.ConfirmCraft then pcall(function() Remotes.ConfirmCraft:InvokeServer() end) end
    end)
end)

-- ====================================================
-- 7. STATS UPDATER
-- ====================================================
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
