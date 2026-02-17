--[[ 
    FISCH V2 - LOGIC FIXED
    - Jalur Remote diperkuat (Full Path)
    - Notifikasi error ditambahkan
    - Anti-stuck UI
]]

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer

-- [[ SETTINGS & STATS ]]
local Settings = {
    BiteDelay = 2.5,
    Cooldown = 0,
    IsFarming = false,
    BuyID = 14,
    CraftName = "Anchor Charm"
}
local Stats = { StartTime = 0, FishCount = 0 }

-- [[ 1. ADVANCED REMOTE FINDER ]]
-- Mencari remote dengan jalur spesifik sleitnick_net
local function GetRemote(name)
    local path = nil
    pcall(function()
        local Packages = ReplicatedStorage:FindFirstChild("Packages")
        local Index = Packages and Packages:FindFirstChild("_Index")
        if Index then
            for _, folder in pairs(Index:GetChildren()) do
                if folder.Name:match("sleitnick_net") then
                    local net = folder:FindFirstChild("net")
                    if net then path = net:FindFirstChild(name) end
                end
            end
        end
    end)
    return path
end

-- Load Remotes secara spesifik
local Remotes = {
    Cast = GetRemote("RF/ChargeFishingRod"),
    StartMini = GetRemote("RF/RequestFishingMinigameStarted"),
    Finish = GetRemote("RF/CatchFishCompleted"),
    Purchase = GetRemote("RF/PurchaseCharm"),
    StartCraft = GetRemote("RF/StartCrafting"),
    ConfirmCraft = GetRemote("RF/ConfirmCrafting"),
    Notif = GetRemote("RE/ObtainedNewFishNotification")
}

-- [[ 2. WINDOW SETUP ]]
local Window = Fluent:CreateWindow({
    Title = "FISCH V2 | IXE",
    SubTitle = "Logic Fixed Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = false,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Shop = Window:AddTab({ Title = "Shop & Craft", Icon = "shopping-cart" })
}

-- [[ 3. FISHING LOGIC ]]
local StatsDisplay = Tabs.Main:AddParagraph({
    Title = "Live Statistics",
    Content = "Menunggu pancingan dimulai..."
})

local FarmToggle = Tabs.Main:AddToggle("AutoFish", {Title = "Start Auto Fishing", Default = false })
FarmToggle:OnChanged(function()
    Settings.IsFarming = FarmToggle.Value
    
    if Settings.IsFarming then
        -- Cek ketersediaan remote sebelum mulai
        if not (Remotes.Cast and Remotes.StartMini and Remotes.Finish) then
            Fluent:Notify({
                Title = "Error!",
                Content = "Alamat Pancingan tidak ditemukan. Coba rejoin server.",
                Duration = 5
            })
            FarmToggle:SetValue(false)
            return
        end

        Stats.StartTime = tick()
        Stats.FishCount = 0
        
        task.spawn(function()
            while Settings.IsFarming do
                -- 1. Lempar (Cast)
                pcall(function() Remotes.Cast:InvokeServer(nil, nil, tick(), nil) end)
                
                -- 2. Tunggu Ikan Makan
                task.wait(Settings.BiteDelay)
                if not Settings.IsFarming then break end
                
                -- 3. Mulai Minigame
                pcall(function() Remotes.StartMini:InvokeServer(0.5, 0.5, tick()) end)
                task.wait(0.1)
                
                -- 4. Selesai (Catch)
                local success, err = pcall(function() Remotes.Finish:InvokeServer() end)
                if not success then warn("Gagal Catch: " .. tostring(err)) end
                
                -- 5. Jeda antar pancingan
                task.wait(Settings.Cooldown + 0.5)
            end
        end)
    end
end)

Tabs.Main:AddSlider("BiteSlider", {
    Title = "Bite Delay (Waktu Tunggu)",
    Default = 2.5, Min = 1, Max = 5, Rounding = 1,
    Callback = function(V) Settings.BiteDelay = V end
})

-- [[ 4. SHOP & CRAFT LOGIC ]]
Tabs.Shop:AddButton({
    Title = "Purchase Item (ID: " .. Settings.BuyID .. ")",
    Callback = function()
        if Remotes.Purchase then
            local success = pcall(function() Remotes.Purchase:InvokeServer(Settings.BuyID) end)
            if success then Fluent:Notify({Title = "Shop", Content = "Membeli ID " .. Settings.BuyID, Duration = 2}) end
        else
            Fluent:Notify({Title = "Error", Content = "Remote Purchase tidak ditemukan.", Duration = 3})
        end
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
        if Remotes.StartCraft and Remotes.ConfirmCraft then
            pcall(function() 
                Remotes.StartCraft:InvokeServer(Settings.CraftName)
                task.wait(0.3)
                Remotes.ConfirmCraft:InvokeServer()
            end)
            Fluent:Notify({Title = "Crafting", Content = "Mencoba membuat " .. Settings.CraftName, Duration = 2})
        end
    end
})

-- [[ 5. BACKGROUND LOOPS ]]
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

if Remotes.Notif then
    Remotes.Notif.OnClientEvent:Connect(function()
        if Settings.IsFarming then Stats.FishCount = Stats.FishCount + 1 end
    end)
end

Window:SelectTab(1)
