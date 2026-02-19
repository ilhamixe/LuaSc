--[[
    FISCH ULTIMATE V3 - STANDALONE STATS
    - New: Standalone Stats Overlay (Always Visible)
    - Fix: Precise Fish Detection
    - Fix: iPad Toggle & Hint Killer
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- [[ STARTUP NOTIF ]]
Fluent:Notify({ Title = "FISCH ULTIMATE | IXE", Content = "Menyiapkan Overlay Stats & Logic...", Duration = 3 })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ CONFIG & STATS ]]
local Settings = { BiteDelay = 2.5, Cooldown = 0, IsFarming = false, BuyID = 14, BuyAmount = 1 }
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

-- [[ 1. STANDALONE OVERLAY STATS (NORMAL UI) ]]
local function CreateNormalStats()
    if PlayerGui:FindFirstChild("IXE_StatsOverlay") then PlayerGui.IXE_StatsOverlay:Destroy() end
    
    local sg = Instance.new("ScreenGui", PlayerGui); sg.Name = "IXE_StatsOverlay"; sg.ResetOnSpawn = false
    local Frame = Instance.new("Frame", sg)
    Frame.Size = UDim2.new(0, 160, 0, 80); Frame.Position = UDim2.new(0.5, -80, 0, 40) -- Posisi atas tengah
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Frame.BackgroundTransparency = 0.2
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", Frame); Stroke.Color = Color3.fromRGB(0, 170, 255); Stroke.Thickness = 2
    
    local Content = Instance.new("TextLabel", Frame)
    Content.Name = "StatText"
    Content.Size = UDim2.new(1, -20, 1, -20); Content.Position = UDim2.new(0, 10, 0, 10)
    Content.BackgroundTransparency = 1; Content.TextColor3 = Color3.fromRGB(255, 255, 255)
    Content.Font = Enum.Font.Code; Content.TextSize = 12; Content.TextXAlignment = 0
    Content.Text = "🐟 Fish: 0\n⏱️ Time: 00:00\n⚡ FPM: 0"

    -- Dragging Logic for Stats Card
    local dragging, dragStart, startPos
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Frame.InputEnded:Connect(function() dragging = false end)
end
CreateNormalStats()

-- [[ 2. SETUP WINDOW (FLUENT) ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH ULTIMATE | IXE", SubTitle = "v3.0 Standalone Stats",
    TabWidth = 160, Size = UDim2.fromOffset(450, 380),
    Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.End
})

-- Hint Killer
task.spawn(function()
    while true do
        for _, v in pairs(PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text:match("Press") and v.Text:match("toggle")) then v.Visible = false end
        end
        task.wait(2)
    end
end)

local Tabs = { Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }), Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }) }

-- [[ 3. FISHING LOGIC ]]
Tabs.Main:AddToggle("AutoFish", {Title = "START AUTO FISHING", Default = false }):OnChanged(function(v)
    Settings.IsFarming = v
    if v then
        Stats.StartTime = tick(); Stats.FishCount = 0
        task.spawn(function()
            while Settings.IsFarming do
                pcall(function() Remotes.Cast:InvokeServer(nil, nil, tick(), nil) end)
                task.wait(Settings.BiteDelay)
                if not Settings.IsFarming then break end
                pcall(function() Remotes.StartMini:InvokeServer(0.5, 0.5, tick()) end)
                task.wait(0.1)
                pcall(function() Remotes.Finish:InvokeServer() end)
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

Tabs.Main:AddInput("Bite", { Title = "Wait for Bite", Default = "2.5", Callback = function(v) Settings.BiteDelay = tonumber(v) or 2.5 end })
Tabs.Main:AddInput("CD", { Title = "Cooldown", Default = "0", Callback = function(v) Settings.Cooldown = tonumber(v) or 0 end })

-- [[ 4. SHOP LOGIC ]]
Tabs.Shop:AddInput("ID", { Title = "Item ID", Default = "14", Callback = function(v) Settings.BuyID = tonumber(v) or 14 end })
Tabs.Shop:AddInput("Amt", { Title = "Qty", Default = "1", Callback = function(v) Settings.BuyAmount = tonumber(v) or 1 end })
Tabs.Shop:AddButton({ Title = "Buy Item", Callback = function()
    for i = 1, Settings.BuyAmount do pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end) task.wait(0.5) end
end})

-- [[ 5. FLOATING ICON (TOGGLE MENU) ]]
local function CreateFloatingIcon()
    local sg = Instance.new("ScreenGui", PlayerGui); sg.Name = "IXE_Toggle"; sg.DisplayOrder = 9999
    local IxeBtn = Instance.new("ImageButton", sg)
    IxeBtn.Size = UDim2.new(0, 55, 0, 55); IxeBtn.Position = UDim2.new(0, 15, 0.5, -27)
    IxeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255); IxeBtn.Image = "rbxassetid://6031094678"
    IxeBtn.BackgroundTransparency = 0.2; Instance.new("UICorner", IxeBtn).CornerRadius = UDim.new(0, 15)

    local function GetMain()
        for _, v in pairs(PlayerGui:GetDescendants()) do
            if v.Name == "Main" and v:IsA("Frame") and v.Parent:IsA("ScreenGui") and v.Parent.Name:match("Fluent") then return v end
        end
        return nil
    end

    IxeBtn.MouseButton1Click:Connect(function()
        local m = GetMain()
        if m then m.Visible = not m.Visible; IxeBtn.BackgroundTransparency = m.Visible and 0.8 or 0.2 end
    end)
    
    -- Dragging
    local dragging, dragStart, startPos
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
    IxeBtn.InputEnded:Connect(function() dragging = false end)
end
CreateFloatingIcon()

-- [[ 6. OVERLAY UPDATE LOOP ]]
task.spawn(function()
    while task.wait(1) do
        local label = PlayerGui.IXE_StatsOverlay.Frame.StatText
        if Settings.IsFarming and Stats.StartTime > 0 then
            local elapsed = tick() - Stats.StartTime
            local mins, secs = math.floor(elapsed/60), math.floor(elapsed%60)
            local fpm = (elapsed > 5) and math.floor((Stats.FishCount / elapsed) * 60) or 0
            label.Text = string.format("🐟 Fish: %d\n⏱️ Time: %02d:%02d\n⚡ FPM: %d", Stats.FishCount, mins, secs, fpm)
        else
            label.Text = "🐟 Fish: " .. Stats.FishCount .. "\n⏱️ Waiting for Start...\n⚡ FPM: 0"
        end
    end
end)

if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

Window:SelectTab(1)
Fluent:Notify({ Title = "READY!", Content = "Stats Overlay Aktif (Bisa Digeser)", Duration = 4 })
