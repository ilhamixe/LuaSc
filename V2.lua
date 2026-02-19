--[[
    FISCH ULTIMATE V2 - IPAD SPECIAL FIX
    - Fix: Force Toggle IXE Icon (Pop-up guaranteed)
    - Fix: Aggressive Hint Killer (No more "Press End")
    - Fix: Standalone HUD Stats
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- [[ STARTUP NOTIF ]]
Fluent:Notify({ Title = "IXE EXECUTOR", Content = "Memulai Bypass UI & Loading HUD...", Duration = 3 })

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

-- [[ 1. STANDALONE HUD STATS ]]
local function CreateHUD()
    if PlayerGui:FindFirstChild("IXE_HUD") then PlayerGui.IXE_HUD:Destroy() end
    local sg = Instance.new("ScreenGui", PlayerGui); sg.Name = "IXE_HUD"; sg.ResetOnSpawn = false
    local Frame = Instance.new("Frame", sg)
    Frame.Size = UDim2.new(0, 150, 0, 70); Frame.Position = UDim2.new(0.5, -75, 0, 50)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Frame.BackgroundTransparency = 0.2
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Frame); Stroke.Color = Color3.fromRGB(0, 170, 255); Stroke.Thickness = 1.5
    local TextLabel = Instance.new("TextLabel", Frame)
    TextLabel.Name = "StatLabel"; TextLabel.Size = UDim2.new(1, 0, 1, 0); TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TextLabel.Font = Enum.Font.Code; TextLabel.TextSize = 11
    TextLabel.Text = "🐟 Fish: 0\n⏱️ Time: 00:00\n⚡ FPM: 0"
    
    -- Dragging Logic
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
CreateHUD()

-- [[ 2. WINDOW SETUP (FLUENT) ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH ULTIMATE | IXE", SubTitle = "iPad HUD Edition",
    TabWidth = 160, Size = UDim2.fromOffset(450, 350),
    Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.End
})

-- AGGRESSIVE HINT KILLER (Menghapus pesan "Press End")
task.spawn(function()
    while task.wait(0.5) do
        for _, v in pairs(PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Text:find("Press") and v.Text:find("toggle")) then
                local p = v.Parent
                if p:IsA("Frame") then p.Visible = false end -- Sembunyikan kotaknya
                v.Visible = false -- Sembunyikan teksnya
            end
        end
    end
end)

local Tabs = { 
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }), 
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }) 
}

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
Tabs.Main:AddInput("CD", { Title = "Recast Cooldown", Default = "0", Callback = function(v) Settings.Cooldown = tonumber(v) or 0 end })

-- [[ 4. SHOP LOGIC ]]
Tabs.Shop:AddInput("ID", { Title = "Item ID", Default = "14", Callback = function(v) Settings.BuyID = tonumber(v) or 14 end })
Tabs.Shop:AddInput("Amt", { Title = "Quantity", Default = "1", Callback = function(v) Settings.BuyAmount = tonumber(v) or 1 end })
Tabs.Shop:AddButton({ Title = "Purchase Item", Callback = function()
    task.spawn(function()
        for i = 1, Settings.BuyAmount do pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end) task.wait(0.5) end
    end)
end})

-- [[ 5. FLOATING IXE ICON (FORCE TOGGLE) ]]
local function CreateIxeToggle()
    local sg = Instance.new("ScreenGui", PlayerGui); sg.Name = "IXE_Toggle"; sg.DisplayOrder = 9999; sg.ResetOnSpawn = false
    local IxeBtn = Instance.new("ImageButton", sg)
    IxeBtn.Size = UDim2.new(0, 55, 0, 55); IxeBtn.Position = UDim2.new(0, 20, 0.5, -27)
    IxeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255); IxeBtn.Image = "rbxassetid://6031094678"
    IxeBtn.BackgroundTransparency = 0.2; Instance.new("UICorner", IxeBtn).CornerRadius = UDim.new(0, 15)

    -- Fungsi mencari ScreenGui & Main Frame Fluent secara mendalam
    local function GetFluentUI()
        for _, v in pairs(PlayerGui:GetChildren()) do
            if v:IsA("ScreenGui") and v:FindFirstChild("Main", true) then
                return v, v:FindFirstChild("Main", true)
            end
        end
        return nil, nil
    end

    IxeBtn.MouseButton1Click:Connect(function()
        local gui, main = GetFluentUI()
        if gui and main then
            -- FORCE ACTIVE: Nyalakan bungkus ScreenGui-nya dan Frame Utamanya
            gui.Enabled = not gui.Enabled
            main.Visible = gui.Enabled
            
            -- Atur transparansi ikon
            IxeBtn.BackgroundTransparency = gui.Enabled and 0.8 or 0.2
            Fluent:Notify({ Title = "IXE", Content = gui.Enabled and "Menu Open" or "Menu Minimized", Duration = 1 })
        end
    end)
    
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
end
CreateIxeToggle()

-- [[ 6. OVERLAY UPDATE LOOP ]]
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local label = PlayerGui.IXE_HUD.Frame.StatLabel
            if Settings.IsFarming and Stats.StartTime > 0 then
                local elapsed = tick() - Stats.StartTime
                local mins, secs = math.floor(elapsed/60), math.floor(elapsed%60)
                local fpm = (elapsed > 5) and math.floor((Stats.FishCount / elapsed) * 60) or 0
                label.Text = string.format("🐟 Fish Caught: %d\n⏱️ Time: %02d:%02d\n⚡ FPM: %d", Stats.FishCount, mins, secs, fpm)
            else
                label.Text = "🐟 Fish: " .. Stats.FishCount .. "\n⏱️ Standby...\n⚡ FPM: 0"
            end
        end)
    end
end)

if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

Window:SelectTab(1)
