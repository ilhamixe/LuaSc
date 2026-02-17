--[[
    FISCH ULTIMATE V3 - IPAD STABLE (FIXED TOGGLE)
    - Fix: Floating Icon won't pop up menu
    - New: Force Re-scan Logic for iPad
    - New: Loading & Ready Notifications
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- [[ STARTUP NOTIF ]]
Fluent:Notify({
    Title = "FISCH ULTIMATE | IXE",
    Content = "Memulai Inisialisasi... Tunggu sebentar.",
    Duration = 3
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ CONFIG & STATS ]]
local Settings = { BiteDelay = 2.5, Cooldown = 0, IsFarming = false, BuyID = 14, BuyAmount = 1, CraftName = "Anchor Charm" }
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

-- [[ SETUP WINDOW ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH ULTIMATE | IXE",
    SubTitle = "iPad Special Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 420),
    Acrylic = false, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End -- Mencegah konflik Ctrl di iPad
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Shop = Window:AddTab({ Title = "Shop & Craft", Icon = "shopping-cart" })
}

-- [[ FISHING PAGE ]]
local StatsDisplay = Tabs.Main:AddParagraph({
    Title = "Live Statistics",
    Content = "🐟 Ikan: 0\n⏱️ Waktu: 00:00\n⚡ FPM: 0"
})

Tabs.Main:AddToggle("AutoFish", {Title = "START AUTO FISHING", Default = false }):OnChanged(function(v)
    Settings.IsFarming = v
    if v then
        Stats.StartTime = tick()
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

-- [[ SHOP PAGE ]]
Tabs.Shop:AddInput("ID", { Title = "Item ID", Default = "14", Callback = function(v) Settings.BuyID = tonumber(v) or 14 end })
Tabs.Shop:AddInput("Amt", { Title = "Qty", Default = "1", Callback = function(v) Settings.BuyAmount = tonumber(v) or 1 end })
Tabs.Shop:AddButton({
    Title = "Buy Item",
    Callback = function()
        for i = 1, Settings.BuyAmount do pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end) task.wait(0.5) end
    end
})

-- [[ FLOATING ICON IXE (THE REPAIR) ]]
local function CreateFloatingIcon()
    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = "IXE_Mobile_Toggle"
    sg.DisplayOrder = 9999
    sg.ResetOnSpawn = false
    
    local IxeBtn = Instance.new("ImageButton", sg)
    IxeBtn.Size = UDim2.new(0, 55, 0, 55)
    IxeBtn.Position = UDim2.new(0, 15, 0.5, -27)
    IxeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    IxeBtn.Image = "rbxassetid://6031094678" -- Ikon Circle
    IxeBtn.BackgroundTransparency = 0.2
    IxeBtn.Visible = false -- Muncul hanya saat menu tertutup
    Instance.new("UICorner", IxeBtn).CornerRadius = UDim.new(0, 15)

    -- Fungsi mencari Main Frame Fluent (Agresif)
    local function GetFluentMain()
        for _, v in pairs(PlayerGui:GetDescendants()) do
            if v.Name == "Main" and v:IsA("Frame") and v.Parent:IsA("ScreenGui") and v.Parent.Name:match("Fluent") then
                return v
            end
        end
        return nil
    end

    -- Dragging Logic
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

    -- CLICK LOGIC (POP UP FIX)
    IxeBtn.MouseButton1Click:Connect(function()
        local main = GetFluentMain()
        if main then
            main.Visible = true
            IxeBtn.Visible = false
            Fluent:Notify({ Title = "IXE", Content = "Menu Kembali Terbuka", Duration = 1 })
        else
            warn("Fluent Main Frame tidak ditemukan!")
        end
    end)

    -- Auto Monitor
    task.spawn(function()
        while task.wait(0.5) do
            local main = GetFluentMain()
            if main then
                -- Jika menu ditutup pakai tombol minimize asli Fluent
                if main.Visible == false then
                    IxeBtn.Visible = true
                else
                    IxeBtn.Visible = false
                end
            end
        end
    end)
end
CreateFloatingIcon()

-- [[ LIVE STATS ENGINE ]]
task.spawn(function()
    while task.wait(1) do
        if Settings.IsFarming and Stats.StartTime > 0 then
            local elapsed = tick() - Stats.StartTime
            local mins, secs = math.floor(elapsed/60), math.floor(elapsed%60)
            local fpm = (elapsed > 5) and math.floor((Stats.FishCount / elapsed) * 60) or 0
            StatsDisplay:SetContent(string.format("🐟 Ikan Terdeteksi: %d\n⏱️ Durasi: %02d:%02d\n⚡ Kecepatan: %d FPM", Stats.FishCount, mins, secs, fpm))
        end
    end
end)

-- Listener Ikan
if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

Window:SelectTab(1)
Fluent:Notify({ Title = "READY!", Content = "Gunakan Ikon IXE untuk memunculkan menu.", Duration = 4 })
