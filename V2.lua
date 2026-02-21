--[[
    FISCH ULTIMATE V2 - ORIGINAL FLEX
    - Feature: Delay Original Notification (Flex Mode)
    - Feature: Auto-Fish, SFX Cleaner, Shop
    - Stability: Infinite Style (iPad Friendly)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ SETTINGS & STATS ]]
local Settings = { 
    BiteDelay = 2.5, 
    Cooldown = 0, 
    IsFarming = false, 
    IsCleanMode = false,
    FlexTime = 10, -- Detik tambahan buat pamer notif asli
    BuyID = 14, 
    BuyAmount = 1 
}
local Stats = { StartTime = 0, FishCount = 0 }

-- [[ REMOTE FINDER ]]
local function GetNet(name)
    local path = nil
    pcall(function()
        local idx = ReplicatedStorage:FindFirstChild("Packages")._Index
        for _, f in pairs(idx:GetChildren()) do
            if f.Name:match("sleitnick_net") then
                local net = f:FindFirstChild("net")
                if net then path = net:FindFirstChild(name) end
            end
        end
    end)
    return path
end

local Remotes = {
    Cast = GetNet("RF/ChargeFishingRod"),
    StartMini = GetNet("RF/RequestFishingMinigameStarted"),
    Finish = GetNet("RF/CatchFishCompleted"),
    Purchase = GetNet("RF/PurchaseCharm"),
    Notif = GetNet("RE/ObtainedNewFishNotification")
}

-- [[ 1. NOTIF DELAYER LOGIC (FITUR PAMER) ]]
-- Mencari folder notifikasi asli game Fisch
local hudGui = PlayerGui:WaitForChild("Gui")
local notifFolder = hudGui:WaitForChild("Notifications")

notifFolder.ChildAdded:Connect(function(child)
    -- Tunggu sebentar sampai game selesai menganimasi notif muncul
    task.wait(2) 
    
    -- "Menahan" notif agar tidak hilang sesuai FlexTime
    local holdStart = tick()
    while tick() - holdStart < Settings.FlexTime do
        pcall(function()
            if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("CanvasGroup") then
                child.Visible = true
                -- Paksa transparansi tetap nol (terlihat)
                if child:FindFirstChildOfClass("UIStroke") then child:FindFirstChildOfClass("UIStroke").Transparency = 0 end
                child.BackgroundTransparency = child.BackgroundTransparency > 0.5 and 0 or child.BackgroundTransparency
            end
        end)
        task.wait(0.5)
    end
    -- Setelah FlexTime habis, biarkan sistem game menghapusnya
end)

-- [[ 2. DRAGGING ENGINE ]]
local function MakeDraggable(UI, DragArea)
    DragArea = DragArea or UI
    local dragging, dragStart, startPos
    DragArea.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = UI.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            UI.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    DragArea.InputEnded:Connect(function() dragging = false end)
end

-- [[ 3. UI CONSTRUCTION ]]
if PlayerGui:FindFirstChild("IXE_Fisch_V2") then PlayerGui.IXE_Fisch_V2:Destroy() end
local ScreenGui = Instance.new("ScreenGui", PlayerGui); ScreenGui.Name = "IXE_Fisch_V2"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 350, 0, 320); Main.Position = UDim2.new(0.5, -175, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main)
local Stroke = Instance.new("UIStroke", Main); Stroke.Color = Color3.fromRGB(0, 170, 255); Stroke.Thickness = 2

-- Header & Sidebar
local Header = Instance.new("Frame", Main); Header.Size = UDim2.new(1, 0, 0, 35); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30); Instance.new("UICorner", Header)
local Title = Instance.new("TextLabel", Header); Title.Text = "  FISCH V2 | DELAY NOTIF"; Title.Size = UDim2.new(1, 0, 1, 0); Title.BackgroundTransparency = 1; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.TextXAlignment = 0
MakeDraggable(Main, Header)

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 80, 1, -35); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -90, 1, -45); Container.Position = UDim2.new(0, 85, 0, 40); Container.BackgroundTransparency = 1

local FishPage = Instance.new("ScrollingFrame", Container); FishPage.Size = UDim2.new(1, 0, 1, 0); FishPage.BackgroundTransparency = 1; FishPage.ScrollBarTransparency = 1; FishPage.CanvasSize = UDim2.new(0,0,1.5,0)
local ShopPage = Instance.new("ScrollingFrame", Container); ShopPage.Size = UDim2.new(1, 0, 1, 0); ShopPage.BackgroundTransparency = 1; ShopPage.Visible = false; ShopPage.ScrollBarTransparency = 1

-- UI Helpers
local function CreateButton(p, y, txt, color, callback)
    local btn = Instance.new("TextButton", p); btn.Size = UDim2.new(0.95, 0, 0, 30); btn.Position = UDim2.new(0, 0, 0, y)
    btn.Text = txt; btn.BackgroundColor3 = color; btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; Instance.new("UICorner", btn); btn.MouseButton1Click:Connect(callback); return btn
end

local function CreateInput(p, y, label, def, callback)
    local lbl = Instance.new("TextLabel", p); lbl.Text = label; lbl.Size = UDim2.new(1, 0, 0, 15); lbl.Position = UDim2.new(0, 0, 0, y); lbl.TextColor3 = Color3.fromRGB(150, 150, 150); lbl.BackgroundTransparency = 1; lbl.TextSize = 9; lbl.Font = Enum.Font.Gotham
    local box = Instance.new("TextBox", p); box.Text = tostring(def); box.Size = UDim2.new(0.95, 0, 0, 25); box.Position = UDim2.new(0, 0, 0, y+15); box.BackgroundColor3 = Color3.fromRGB(30, 30, 35); box.TextColor3 = Color3.fromRGB(255, 255, 255); box.Font = Enum.Font.Gotham; box.TextSize = 11; Instance.new("UICorner", box); box.FocusLost:Connect(function() callback(box.Text) end)
end

-- [[ FISHING PAGE CONTENT ]]
CreateButton(FishPage, 0, "HIDE SFX: OFF", Color3.fromRGB(60, 60, 65), function()
    Settings.IsCleanMode = not Settings.IsCleanMode
    for _, b in pairs(FishPage:GetChildren()) do if b:IsA("TextButton") and b.Text:match("SFX") then b.Text = Settings.IsCleanMode and "HIDE SFX: ON" or "HIDE SFX: OFF"; b.BackgroundColor3 = Settings.IsCleanMode and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 65) end end
end)

CreateInput(FishPage, 35, "Flex Delay (Seconds)", Settings.FlexTime, function(v) Settings.FlexTime = tonumber(v) or 10 end)
CreateInput(FishPage, 80, "Bite Delay", Settings.BiteDelay, function(v) Settings.BiteDelay = tonumber(v) or 2.5 end)
CreateInput(FishPage, 125, "Cooldown", Settings.Cooldown, function(v) Settings.Cooldown = tonumber(v) or 0 end)

local FarmBtn = CreateButton(FishPage, 175, "START AUTO FISH", Color3.fromRGB(0, 150, 100), function()
    Settings.IsFarming = not Settings.IsFarming
    for _, b in pairs(FishPage:GetChildren()) do if b:IsA("TextButton") and b.Text:match("FISH") then b.Text = Settings.IsFarming and "STOP FARMING" or "START AUTO FISH"; b.BackgroundColor3 = Settings.IsFarming and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(0, 150, 100) end end
    if Settings.IsFarming then
        Stats.StartTime = tick(); Stats.FishCount = 0
        task.spawn(function()
            while Settings.IsFarming do
                pcall(function() Remotes.Cast:InvokeServer(nil, nil, tick(), nil) end)
                task.wait(Settings.BiteDelay)
                if not Settings.IsFarming then break end
                pcall(function() Remotes.StartMini:InvokeServer(0.5, 0.5, tick()) end)
                task.wait(0.1); pcall(function() Remotes.Finish:InvokeServer() end)
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

-- Sidebar Tabs Switcher
CreateButton(Sidebar, 10, "FISH", Color3.fromRGB(30, 30, 35), function() FishPage.Visible = true; ShopPage.Visible = false end)
CreateButton(Sidebar, 50, "SHOP", Color3.fromRGB(30, 30, 35), function() FishPage.Visible = false; ShopPage.Visible = true end)

-- [[ IXE ICON & HUD ]]
local IxeIcon = Instance.new("ImageButton", ScreenGui); IxeIcon.Size = UDim2.new(0, 55, 0, 55); IxeIcon.Position = UDim2.new(0, 20, 0.5, -27); IxeIcon.BackgroundColor3 = Color3.fromRGB(0, 170, 255); IxeIcon.Image = "rbxassetid://6031094678"; IxeIcon.Visible = false; Instance.new("UICorner", IxeIcon); MakeDraggable(IxeIcon)
IxeIcon.MouseButton1Click:Connect(function() Main.Visible = true; IxeIcon.Visible = false end)
CreateButton(Header, 5, "-", Color3.fromRGB(50, 50, 55), function() Main.Visible = false; IxeIcon.Visible = true end).Size = UDim2.new(0, 25, 0, 25); Header:FindFirstChild("-").Position = UDim2.new(1, -30, 0, 5)

local Hud = Instance.new("Frame", ScreenGui); Hud.Size = UDim2.new(0, 140, 0, 65); Hud.Position = UDim2.new(0.5, -70, 0, 20); Hud.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Hud.BackgroundTransparency = 0.3; Instance.new("UICorner", Hud); local HudLbl = Instance.new("TextLabel", Hud); HudLbl.Size = UDim2.new(1, 0, 1, 0); HudLbl.BackgroundTransparency = 1; HudLbl.TextColor3 = Color3.fromRGB(255, 255, 255); HudLbl.Font = Enum.Font.Code; HudLbl.TextSize = 11; HudLbl.Text = "Fish: 0\nTime: 00:00\nFPM: 0"; MakeDraggable(Hud)

-- [[ FINAL LOOPS ]]
task.spawn(function()
    while task.wait(1) do
        if Settings.IsFarming and Stats.StartTime > 0 then
            local el = tick() - Stats.StartTime
            HudLbl.Text = string.format("Fish: %d\nTime: %02d:%02d\nFPM: %d", Stats.FishCount, math.floor(el/60), math.floor(el%60), (el > 5) and math.floor((Stats.FishCount/el)*60) or 0)
        end
        if Settings.IsCleanMode then
            for _, v in pairs(PlayerGui:GetDescendants()) do 
                if v:IsA("ViewportFrame") then v.Visible = false end 
            end
        end
    end
end)

if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function() if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end end)
end
