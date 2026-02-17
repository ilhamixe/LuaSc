--[[
    FISCH ULTIMATE V3 - FULL INTEGRATED
    Developer: IXE
    Features:
    - Auto Fish (Turbo Mode / Skip Minigame)
    - Live Stats (Fish Count, Timer, FPM)
    - Inputs: Bite Delay & Cooldown (Precision Control)
    - SFX Cleaner (Anti-Lag Mobile)
    - Shop: Multi-Buy by ID
    - Crafting: Dropdown + Multi-Craft
    - UI: Fluent Library (Acrylic Disabled for Mobile)
    - Minimize: Floating Image Icon (Draggable)
]]

-- [[ LOADING LIBRARY ]]
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- [[ CONFIGURATION & STATE ]]
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    IsCleanMode = false,
    BuyID = 14,
    BuyAmount = 1,
    CraftName = "Anchor Charm",
    CraftAmount = 1
}

local Stats = {
    StartTime = 0,
    FishCount = 0
}

-- [[ 1. REMOTE FINDER (ROBUST PATH) ]]
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
    StartCraft = GetNet("RF/StartCrafting"),
    ConfirmCraft = GetNet("RF/ConfirmCrafting"),
    Notif = GetNet("RE/ObtainedNewFishNotification")
}

-- [[ 2. SFX CLEANER LOGIC ]]
local function CleanUI(obj)
    pcall(function()
        if not Settings.IsCleanMode then return end
        if obj:IsA("ViewportFrame") or (obj:IsA("ImageLabel") and obj.Name:lower():match("fish")) then
            obj.Visible = false
            if obj:IsA("ViewportFrame") then obj:Destroy() end
        end
    end)
end

-- [[ 3. MAIN WINDOW SETUP ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH ULTIMATE | IXE",
    SubTitle = "v3.0 Full Integrated",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 440),
    Acrylic = false, -- Disabled to prevent black screen on Mobile
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Shop = Window:AddTab({ Title = "Shop & Craft", Icon = "shopping-cart" })
}

-- [[ 4. FISHING TAB CONTENT ]]
local StatsDisplay = Tabs.Main:AddParagraph({
    Title = "Live Statistics",
    Content = "🐟 Ikan: 0\n⏱️ Waktu: 00:00\n⚡ FPM: 0"
})

Tabs.Main:AddDivider()

-- SFX Cleaner Toggle
Tabs.Main:AddToggle("SFXToggle", {Title = "SFX Cleaner (Anti-Lag)", Default = false }):OnChanged(function(v)
    Settings.IsCleanMode = v
    if v then
        for _, obj in pairs(PlayerGui:GetDescendants()) do CleanUI(obj) end
        _G.CleanConn = PlayerGui.DescendantAdded:Connect(CleanUI)
    else
        if _G.CleanConn then _G.CleanConn:Disconnect() end
    end
end)

-- Auto Fish Toggle
local FarmToggle = Tabs.Main:AddToggle("AutoFish", {Title = "START AUTO FISHING", Default = false })
FarmToggle:OnChanged(function()
    Settings.IsFarming = FarmToggle.Value
    if Settings.IsFarming then
        Stats.StartTime = tick()
        Stats.FishCount = 0
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

-- Delay Inputs
Tabs.Main:AddInput("BiteInput", {
    Title = "Wait for Bite (Detik)",
    Default = "2.5",
    Callback = function(v) Settings.BiteDelay = tonumber(v) or 2.5 end
})

Tabs.Main:AddInput("CooldownInput", {
    Title = "Recast Cooldown (Detik)",
    Default = "0",
    Callback = function(v) Settings.Cooldown = tonumber(v) or 0 end
})

-- [[ 5. SHOP & CRAFT TAB CONTENT ]]
-- Shop Section
Tabs.Shop:AddParagraph({ Title = "Shop Settings", Content = "Beli item otomatis dalam jumlah banyak." })

Tabs.Shop:AddInput("ItemID", { Title = "Item ID", Default = "14", Callback = function(v) Settings.BuyID = tonumber(v) or 14 end })
Tabs.Shop:AddInput("BuyAmt", { Title = "Jumlah Beli", Default = "1", Callback = function(v) Settings.BuyAmount = tonumber(v) or 1 end })

Tabs.Shop:AddButton({
    Title = "Purchase Item (Buy)",
    Callback = function()
        if Remotes.Purchase then
            task.spawn(function()
                for i = 1, Settings.BuyAmount do
                    pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end)
                    task.wait(0.5)
                end
                Fluent:Notify({Title = "Shop", Content = "Selesai membeli " .. Settings.BuyAmount .. "x", Duration = 3})
            end)
        end
    end
})

Tabs.Shop:AddDivider()

-- Crafting Section
Tabs.Shop:AddParagraph({ Title = "Crafting Settings", Content = "Pilih item dan jumlah yang ingin dibuat." })

Tabs.Shop:AddDropdown("CraftDropdown", {
    Title = "Pilih Item Crafting",
    Values = {"Anchor Charm", "Winged Charm", "Heart Charm", "Lure Charm", "Bait Charm"},
    Default = "Anchor Charm",
    Callback = function(v) Settings.CraftName = v end
})

Tabs.Shop:AddInput("CraftAmt", { Title = "Jumlah Craft", Default = "1", Callback = function(v) Settings.CraftAmount = tonumber(v) or 1 end })

Tabs.Shop:AddButton({
    Title = "Mulai Crafting",
    Callback = function()
        if Remotes.StartCraft and Remotes.ConfirmCraft then
            task.spawn(function()
                for i = 1, Settings.CraftAmount do
                    pcall(function() 
                        Remotes.StartCraft:InvokeServer(Settings.CraftName)
                        task.wait(0.3)
                        Remotes.ConfirmCraft:InvokeServer()
                    end)
                    task.wait(0.5)
                end
                Fluent:Notify({Title = "Crafting", Content = "Selesai membuat " .. Settings.CraftAmount .. "x " .. Settings.CraftName, Duration = 3})
            end)
        end
    end
})

-- [[ 6. FLOATING IXE BUTTON (MINIMIZE) ]]
local function CreateIxeButton()
    local IxeBtn = Instance.new("ImageButton")
    local sg = Instance.new("ScreenGui", PlayerGui); sg.Name = "IxeButtonGui"; sg.DisplayOrder = 999; sg.ResetOnSpawn = false
    
    IxeBtn.Size = UDim2.new(0, 55, 0, 55); IxeBtn.Position = UDim2.new(0, 10, 0.5, 0)
    IxeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); IxeBtn.Image = "rbxassetid://6031094678" -- Blue Circle Icon
    IxeBtn.Visible = false; IxeBtn.Parent = sg; IxeBtn.BackgroundTransparency = 0.2
    Instance.new("UICorner", IxeBtn).CornerRadius = UDim.new(0, 15)

    -- Hover Effects
    IxeBtn.MouseEnter:Connect(function() IxeBtn.BackgroundTransparency = 0 end)
    IxeBtn.MouseLeave:Connect(function() IxeBtn.BackgroundTransparency = 0.2 end)

    -- Mobile Dragging Logic
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

    -- Restore Window Logic
    IxeBtn.MouseButton1Click:Connect(function()
        Window:Minimize() -- Library handles restoration
        IxeBtn.Visible = false
    end)

    -- Visibility Monitor
    task.spawn(function()
        while task.wait(0.5) do
            local mainFrame = PlayerGui:FindFirstChild("Main", true)
            if mainFrame then
                if mainFrame.Visible == false then
                    IxeBtn.Visible = true
                else
                    IxeBtn.Visible = false
                end
            end
        end
    end)
end
CreateIxeButton()

-- [[ 7. BACKGROUND LOOPS & LISTENERS ]]
task.spawn(function()
    while task.wait(1) do
        if Settings.IsFarming and Stats.StartTime > 0 then
            local elapsed = tick() - Stats.StartTime
            local mins, secs = math.floor(elapsed / 60), math.floor(elapsed % 60)
            local fpm = (elapsed > 5) and math.floor((Stats.FishCount / elapsed) * 60) or 0
            StatsDisplay:SetContent(string.format("🐟 Ikan: %d\n⏱️ Waktu: %02d:%02d\n⚡ FPM: %d", Stats.FishCount, mins, secs, fpm))
        end
    end
end)

-- Fish Counter Listener
if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

-- Default Tab
Window:SelectTab(1)
