task.spawn(function()
    -- Layanan dan Variabel Global
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")
    local MaterialService = game:GetService("MaterialService")
    
    -- Pengaturan Default
    local Settings = {
        FlySpeed = 1,
        WalkSpeed = 16,
        MaxFlySpeed = 10,
        MaxWalkSpeed = 500,
        KillAuraRadius = 25,
        KillAuraDamage = 10,
        MaxKillAuraRadius = 100,
        MaxKillAuraDamage = 100,
        AimbotFOV = 90,
        AimbotPart = "Head",
        MaxAimbotFOV = 200,
        TeleportDistance = 100,
    }
    
    -- Variabel Status
    local IsFlying = false
    local IsNoclipEnabled = false
    local IsGodModeEnabled = false 
    local IsKillAuraEnabled = false
    local IsAimbotEnabled = false
    local IsWalkSpeedEnabled = false
    local OriginalWalkSpeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed or 16
    local FlyConnections = {}
    local godModeConnection = nil 
    local KillAuraConnection = nil
    local AimbotConnection = nil
    local AimbotTarget = nil
    local FOVPart = nil
    local IsInfinityJumpEnabled = false
    local infinityJumpConnection = nil
    local PlayerButtons = {} -- Cache untuk elemen UI pemain
    local CurrentPlayerFilter = ""
    local touchFlingGui = nil
    local isUpdatingPlayerList = false 
    local isMiniToggleDraggable = true -- Tombol hide bisa digeser secara default
    
    -- Variabel Teleport
    local savedTeleportLocations = {}
    local TELEPORT_SAVE_FILE = "ArexansTools_Teleports_" .. tostring(game.PlaceId) .. ".json"
    
    -- Variabel AntiFling
    local antifling_velocity_threshold = 85
    local antifling_angular_threshold = 25
    local antifling_last_safe_cframe = nil
    local antifling_enabled = false
    local antifling_connection = nil
    
    -- Variabel Anti Lag
    local IsAntiLagEnabled = false
    local OriginalGraphicsSettings = {}
    
    -- Membuat GUI utama
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArexansToolsGUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    -- Tombol toggle mini
    local MiniToggleButton = Instance.new("TextButton")
    MiniToggleButton.Name = "MiniToggleButton"
    MiniToggleButton.Size = UDim2.new(0, 15, 0, 15)
    MiniToggleButton.Position = UDim2.new(1, -25, 0.5, -7.5) 
    MiniToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MiniToggleButton.BackgroundTransparency = 1
    MiniToggleButton.BorderSizePixel = 0
    MiniToggleButton.Text = "◀"
    MiniToggleButton.TextColor3 = Color3.fromRGB(0, 200, 255)
    MiniToggleButton.TextSize = 10
    MiniToggleButton.Font = Enum.Font.SourceSansBold
    MiniToggleButton.Parent = ScreenGui
    MiniToggleButton.Active = true
    
    local MiniUICorner = Instance.new("UICorner")
    MiniUICorner.CornerRadius = UDim.new(0, 8)
    MiniUICorner.Parent = MiniToggleButton
    
    local MiniUIStroke = Instance.new("UIStroke")
    MiniUIStroke.Color = Color3.fromRGB(0, 150, 255)
    MiniUIStroke.Thickness = 2
    MiniUIStroke.Transparency = 0.5
    MiniUIStroke.Parent = MiniToggleButton
    
    -- Frame GUI utama
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 230, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -115, 0.5, -160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.5
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Visible = false
    
    local MainUICorner = Instance.new("UICorner")
    MainUICorner.CornerRadius = UDim.new(0, 8)
    MainUICorner.Parent = MainFrame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 150, 255)
    UIStroke.Thickness = 2
    UIStroke.Transparency = 0.5
    UIStroke.Parent = MainFrame
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    TitleBar.Active = true
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Arexans Tools"
    TitleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Parent = TitleBar
    
    local TabsFrame = Instance.new("Frame")
    TabsFrame.Name = "TabsFrame"
    TabsFrame.Size = UDim2.new(0, 80, 1, -30)
    TabsFrame.Position = UDim2.new(0, 0, 0, 30)
    TabsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TabsFrame.BorderSizePixel = 0
    TabsFrame.Parent = MainFrame
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Name = "TabListLayout"
    TabListLayout.Padding = UDim.new(0, 5)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    TabListLayout.FillDirection = Enum.FillDirection.Vertical
    TabListLayout.Parent = TabsFrame
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -80, 1, -30)
    ContentFrame.Position = UDim2.new(0, 80, 0, 30)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    
    -- Frame konten tab
    local PlayerTabContent = Instance.new("Frame")
    PlayerTabContent.Name = "PlayerTab"
    PlayerTabContent.Size = UDim2.new(1, -10, 1, -10)
    PlayerTabContent.Position = UDim2.new(0, 5, 0, 5)
    PlayerTabContent.BackgroundTransparency = 1
    PlayerTabContent.Visible = false
    PlayerTabContent.Parent = ContentFrame
    
    local PlayerListContainer = Instance.new("ScrollingFrame")
    PlayerListContainer.Name = "PlayerListContainer"
    PlayerListContainer.Size = UDim2.new(1, 0, 1, -55)
    PlayerListContainer.Position = UDim2.new(0, 0, 0, 55)
    PlayerListContainer.BackgroundTransparency = 1
    PlayerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerListContainer.ScrollBarThickness = 10
    PlayerListContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    PlayerListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    PlayerListContainer.Parent = PlayerTabContent
    
    local GeneralTabContent = Instance.new("ScrollingFrame")
    GeneralTabContent.Name = "GeneralTab"
    GeneralTabContent.Size = UDim2.new(1, -10, 1, -10)
    GeneralTabContent.Position = UDim2.new(0, 5, 0, 5)
    GeneralTabContent.BackgroundTransparency = 1
    GeneralTabContent.Visible = false
    GeneralTabContent.CanvasSize = UDim2.new(0, 0, 0, 0) 
    GeneralTabContent.ScrollBarThickness = 10
    GeneralTabContent.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    GeneralTabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    GeneralTabContent.Parent = ContentFrame
    
    local CombatTabContent = Instance.new("ScrollingFrame")
    CombatTabContent.Name = "CombatTab"
    CombatTabContent.Size = UDim2.new(1, -10, 1, -10)
    CombatTabContent.Position = UDim2.new(0, 5, 0, 5)
    CombatTabContent.BackgroundTransparency = 1
    CombatTabContent.Visible = false
    CombatTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    CombatTabContent.ScrollBarThickness = 10
    CombatTabContent.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    CombatTabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    CombatTabContent.Parent = ContentFrame
    
    local TeleportTabContent = Instance.new("ScrollingFrame")
    TeleportTabContent.Name = "TeleportTab"
    TeleportTabContent.Size = UDim2.new(1, -10, 1, -10)
    TeleportTabContent.Position = UDim2.new(0, 5, 0, 5)
    TeleportTabContent.BackgroundTransparency = 1
    TeleportTabContent.Visible = false
    TeleportTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TeleportTabContent.ScrollBarThickness = 10
    TeleportTabContent.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    TeleportTabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    TeleportTabContent.Parent = ContentFrame
    
    local SettingsTabContent = Instance.new("ScrollingFrame")
    SettingsTabContent.Name = "SettingsTab"
    SettingsTabContent.Size = UDim2.new(1, -10, 1, -10)
    SettingsTabContent.Position = UDim2.new(0, 5, 0, 5)
    SettingsTabContent.BackgroundTransparency = 1
    SettingsTabContent.Visible = false
    SettingsTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    SettingsTabContent.ScrollBarThickness = 10
    SettingsTabContent.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    SettingsTabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    SettingsTabContent.Parent = ContentFrame
    
    -- Menambahkan UIListLayout ke konten tab
    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Name = "PlayerListLayout"
    PlayerListLayout.Padding = UDim.new(0, 5)
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Menggunakan LayoutOrder untuk konsistensi
    PlayerListLayout.Parent = PlayerListContainer
    
    local GeneralListLayout = Instance.new("UIListLayout")
    GeneralListLayout.Padding = UDim.new(0, 5)
    GeneralListLayout.Parent = GeneralTabContent
    
    local CombatListLayout = Instance.new("UIListLayout")
    CombatListLayout.Padding = UDim.new(0, 5)
    CombatListLayout.Parent = CombatTabContent
    
    local TeleportListLayout = Instance.new("UIListLayout")
    TeleportListLayout.Padding = UDim.new(0, 2)
    TeleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TeleportListLayout.Parent = TeleportTabContent
    
    local SettingsListLayout = Instance.new("UIListLayout")
    SettingsListLayout.Padding = UDim.new(0, 5)
    SettingsListLayout.Parent = SettingsTabContent
    
    -- Atur CanvasSize untuk Tab secara dinamis
    local function setupCanvasSize(listLayout, scrollingFrame)
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
        end)
    end
    
    setupCanvasSize(PlayerListLayout, PlayerListContainer)
    setupCanvasSize(GeneralListLayout, GeneralTabContent)
    setupCanvasSize(CombatListLayout, CombatTabContent)
    setupCanvasSize(TeleportListLayout, TeleportTabContent)
    setupCanvasSize(SettingsListLayout, SettingsTabContent)
    
    -- Deklarasi fungsi di awal
    local function createButton(parent, name, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        button.BorderSizePixel = 0
        button.Text = name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.SourceSansBold
        button.Parent = parent
        local buttonUICorner = Instance.new("UICorner", button)
        buttonUICorner.CornerRadius = UDim.new(0, 5)
        button.MouseButton1Click:Connect(callback)
        return button
    end
    
    -- ====================================================================
    -- == BAGIAN TELEPORT DAN FUNGSI UTILITAS                          ==
    -- ====================================================================
    
    local function naturalCompare(a, b)
        local function split(s)
            local parts = {}; for text, number in s:gmatch("([^%d]*)(%d*)") do if text ~= "" then table.insert(parts, text:lower()) end; if number ~= "" then table.insert(parts, tonumber(number)) end end; return parts
        end
        local partsA = split(a.Name or ""); local partsB = split(b.Name or ""); for i = 1, math.min(#partsA, #partsB) do local partA = partsA[i]; local partB = partsB[i]; if type(partA) ~= type(partB) then return type(partA) == "number" end; if partA < partB then return true elseif partA > partB then return false end end; return #partsA < #partsB
    end
    
    local updateTeleportList 
    
    local function showNotification(message, color)
        local notifFrame = Instance.new("Frame", ScreenGui); notifFrame.Size = UDim2.new(0, 200, 0, 50); notifFrame.Position = UDim2.new(0.5, -100, 0, -60); notifFrame.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30); notifFrame.BorderSizePixel = 0; local corner = Instance.new("UICorner", notifFrame); corner.CornerRadius = UDim.new(0, 8)
        local notifLabel = Instance.new("TextLabel", notifFrame); notifLabel.Size = UDim2.new(1, 0, 1, 0); notifLabel.BackgroundTransparency = 1; notifLabel.Text = message; notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255); notifLabel.Font = Enum.Font.SourceSansBold
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out); local goalPosition = UDim2.new(0.5, -100, 0, 10); TweenService:Create(notifFrame, tweenInfo, {Position = goalPosition}):Play()
        task.delay(3, function() TweenService:Create(notifFrame, tweenInfo, {Position = UDim2.new(0.5, -100, 0, -60)}):Play(); task.wait(0.5); notifFrame:Destroy() end)
    end
    
    local function saveTeleportData()
        if not writefile then showNotification("Executor tidak mendukung penyimpanan file.", Color3.fromRGB(200, 50, 50)); return end
        local dataToSave = {}; for _, loc in ipairs(savedTeleportLocations) do table.insert(dataToSave, {Name = loc.Name, CFrameData = {loc.CFrame:GetComponents()}}) end
        local success, result = pcall(function() local jsonData = HttpService:JSONEncode(dataToSave); writefile(TELEPORT_SAVE_FILE, jsonData) end)
        if not success then warn("Gagal menyimpan data teleport:", result) end
    end
    
    local function loadTeleportData()
        if not readfile or not isfile or not isfile(TELEPORT_SAVE_FILE) then return end
        local success, result = pcall(function()
            local fileContent = readfile(TELEPORT_SAVE_FILE); local decodedData = HttpService:JSONDecode(fileContent); savedTeleportLocations = {}
            for _, data in ipairs(decodedData) do table.insert(savedTeleportLocations, {Name = data.Name, CFrame = CFrame.new(unpack(data.CFrameData))}) end
            table.sort(savedTeleportLocations, naturalCompare)
            if updateTeleportList then updateTeleportList() end
        end)
        if not success then warn("Gagal memuat data teleport:", result) end
    end
    
    local function showRenamePrompt(locationIndex, callback)
        local oldName = savedTeleportLocations[locationIndex].Name
        local promptFrame = Instance.new("Frame"); promptFrame.Size = UDim2.new(0, 200, 0, 100); promptFrame.Position = UDim2.new(0.5, -100, 0.5, -50); promptFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); promptFrame.BorderSizePixel = 0; promptFrame.ZIndex = 10; promptFrame.Parent = MainFrame
        local corner = Instance.new("UICorner", promptFrame); corner.CornerRadius = UDim.new(0, 8); local stroke = Instance.new("UIStroke", promptFrame); stroke.Color = Color3.fromRGB(0, 150, 255); stroke.Thickness = 1
        local title = Instance.new("TextLabel", promptFrame); title.Size = UDim2.new(1, 0, 0, 20); title.Text = "Ganti Nama Lokasi"; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold
        local textBox = Instance.new("TextBox", promptFrame); textBox.Size = UDim2.new(1, -20, 0, 30); textBox.Position = UDim2.new(0.5, -90, 0, 30); textBox.Text = oldName; textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50); textBox.TextColor3 = Color3.fromRGB(255, 255, 255); textBox.ClearTextOnFocus = false; local tbCorner = Instance.new("UICorner", textBox); tbCorner.CornerRadius = UDim.new(0, 5)
        local okButton = createButton(promptFrame, "OK", function() callback(textBox.Text); promptFrame:Destroy() end); okButton.Size = UDim2.new(0.5, -10, 0, 25); okButton.Position = UDim2.new(0, 5, 1, -30)
        local cancelButton = createButton(promptFrame, "Batal", function() promptFrame:Destroy() end); cancelButton.Size = UDim2.new(0.5, -10, 0, 25); cancelButton.Position = UDim2.new(0.5, 5, 1, -30); cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    local function showImportPrompt(callback)
        local promptFrame = Instance.new("Frame"); promptFrame.Size = UDim2.new(0, 220, 0, 150); promptFrame.Position = UDim2.new(0.5, -110, 0.5, -75); promptFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); promptFrame.BorderSizePixel = 0; promptFrame.ZIndex = 10; promptFrame.Parent = MainFrame
        local corner = Instance.new("UICorner", promptFrame); corner.CornerRadius = UDim.new(0, 8); local stroke = Instance.new("UIStroke", promptFrame); stroke.Color = Color3.fromRGB(0, 150, 255); stroke.Thickness = 1
        local title = Instance.new("TextLabel", promptFrame); title.Size = UDim2.new(1, 0, 0, 20); title.Text = "Impor Lokasi"; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.BackgroundTransparency = 1; title.Font = Enum.Font.SourceSansBold
        local textBox = Instance.new("TextBox", promptFrame); textBox.Size = UDim2.new(1, -20, 1, -60); textBox.Position = UDim2.new(0.5, -100, 0, 25); textBox.PlaceholderText = "Tempel data di sini..."; textBox.MultiLine = true; textBox.TextXAlignment = Enum.TextXAlignment.Left; textBox.TextYAlignment = Enum.TextYAlignment.Top; textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50); textBox.TextColor3 = Color3.fromRGB(255, 255, 255); local tbCorner = Instance.new("UICorner", textBox); tbCorner.CornerRadius = UDim.new(0, 5)
        local okButton = createButton(promptFrame, "Impor", function() callback(textBox.Text); promptFrame:Destroy() end); okButton.Size = UDim2.new(0.5, -10, 0, 25); okButton.Position = UDim2.new(0, 5, 1, -30)
        local cancelButton = createButton(promptFrame, "Batal", function() promptFrame:Destroy() end); cancelButton.Size = UDim2.new(0.5, -10, 0, 25); cancelButton.Position = UDim2.new(0.5, 5, 1, -30); cancelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
    
    local function addTeleportLocation(name, cframe)
        for _, loc in pairs(savedTeleportLocations) do if loc.Name == name then return end end
        table.insert(savedTeleportLocations, {Name = name, CFrame = cframe}); table.sort(savedTeleportLocations, naturalCompare); saveTeleportData(); if updateTeleportList then updateTeleportList() end
    end
    
    updateTeleportList = function()
        for _, child in pairs(TeleportTabContent:GetChildren()) do if child.Name == "TeleportLocationFrame" then child:Destroy() end end
        for i, locData in ipairs(savedTeleportLocations) do
            local locFrame = Instance.new("Frame"); locFrame.Name = "TeleportLocationFrame"; locFrame.Size = UDim2.new(1, 0, 0, 22); locFrame.BackgroundTransparency = 1; locFrame.Parent = TeleportTabContent; locFrame.LayoutOrder = i + 4; locFrame.ZIndex = 2
            local tpButton = createButton(locFrame, locData.Name, function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = locData.CFrame * CFrame.new(0, 3, 0) end end); tpButton.Size = UDim2.new(1, -50, 1, 0); tpButton.TextSize = 10; tpButton.TextXAlignment = Enum.TextXAlignment.Left; local pad = Instance.new("UIPadding", tpButton); pad.PaddingLeft = UDim.new(0,5)
            local renameButton = createButton(locFrame, "R", function() showRenamePrompt(i, function(newName) if newName and newName ~= "" and newName ~= savedTeleportLocations[i].Name then savedTeleportLocations[i].Name = newName; table.sort(savedTeleportLocations, naturalCompare); saveTeleportData(); updateTeleportList() end end) end); renameButton.Size = UDim2.new(0, 22, 1, 0); renameButton.Position = UDim2.new(1, -47, 0, 0); renameButton.TextSize = 10
            local deleteButton = createButton(locFrame, "X", function() table.remove(savedTeleportLocations, i); saveTeleportData(); updateTeleportList() end); deleteButton.Size = UDim2.new(0, 22, 1, 0); deleteButton.Position = UDim2.new(1, -22, 0, 0); deleteButton.TextSize = 10; deleteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    end
    
    local updatePlayerList
    local function switchTab(tabName)
        PlayerTabContent.Visible = (tabName == "Player"); GeneralTabContent.Visible = (tabName == "Umum"); CombatTabContent.Visible = (tabName == "Tempur"); TeleportTabContent.Visible = (tabName == "Teleport"); SettingsTabContent.Visible = (tabName == "Pengaturan")
        if tabName == "Player" and updatePlayerList then updatePlayerList() end
    end
    
    local function createTabButton(name, parent)
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 0, 25); button.BackgroundColor3 = Color3.fromRGB(30, 30, 30); button.BorderSizePixel = 0; button.Text = name; button.TextColor3 = Color3.fromRGB(255, 255, 255); button.TextSize = 12; button.Font = Enum.Font.SourceSansSemibold; button.Parent = parent; local btnCorner = Instance.new("UICorner", button); btnCorner.CornerRadius = UDim.new(0, 5); button.MouseButton1Click:Connect(function() switchTab(name) end); return button
    end
    
    local PlayerTabButton = createTabButton("Player", TabsFrame)
    local GeneralTabButton = createTabButton("Umum", TabsFrame)
    local CombatTabButton = createTabButton("Tempur", TabsFrame)
    local TeleportTabButton = createTabButton("Teleport", TabsFrame)
    local SettingsTabButton = createTabButton("Pengaturan", TabsFrame)
    
    local function CreateFOVCircle()
        if FOVPart then FOVPart:Destroy() end
        FOVPart = Instance.new("Part", Workspace); FOVPart.Name = "AimbotFOV"; FOVPart.Anchored = true; FOVPart.CanCollide = false; FOVPart.Transparency = 1; FOVPart.Size = Vector3.new(0.1, 0.1, 0.1)
        local billboard = Instance.new("BillboardGui", FOVPart); billboard.Name = "FOVGui"; billboard.Adornee = FOVPart; billboard.Size = UDim2.new(Settings.AimbotFOV * 2 / 50, 0, Settings.AimbotFOV * 2 / 50, 0); billboard.AlwaysOnTop = true
        local frame = Instance.new("Frame", billboard); frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
        local uiStroke = Instance.new("UIStroke", frame); uiStroke.Thickness = 2; uiStroke.Color = Color3.fromRGB(0, 200, 255); uiStroke.Transparency = 0.2
    end
    
    local function UpdateFOVCircle()
        if FOVPart and FOVPart:FindFirstChild("FOVGui") then FOVPart.FOVGui.Size = UDim2.new(Settings.AimbotFOV * 2 / 50, 0, Settings.AimbotFOV * 2 / 50, 0) end
    end
    
    -- ====================================================================
    -- == BAGIAN FUNGSI UTAMA (PLAYER, COMBAT, DLL)                      ==
    -- ====================================================================
    
    local function StartFly()
        if IsFlying then return end; local character = LocalPlayer.Character; if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then return end; local root = character:WaitForChild("HumanoidRootPart"); local humanoid = character:FindFirstChildOfClass("Humanoid"); IsFlying = true; humanoid.PlatformStand = true; local bodyGyro = Instance.new("BodyGyro", root); bodyGyro.Name = "FlyGyro"; bodyGyro.P = 9e4; bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bodyGyro.CFrame = root.CFrame; local bodyVelocity = Instance.new("BodyVelocity", root); bodyVelocity.Name = "FlyVelocity"; bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); bodyVelocity.Velocity = Vector3.new(0, 0, 0); local controls = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        table.insert(FlyConnections, UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; if input.UserInputType == Enum.UserInputType.Keyboard then local key = input.KeyCode.Name:lower(); if key == "w" then controls.F = Settings.FlySpeed elseif key == "s" then controls.B = -Settings.FlySpeed elseif key == "a" then controls.L = -Settings.FlySpeed elseif key == "d" then controls.R = Settings.FlySpeed elseif key == "e" then controls.Q = Settings.FlySpeed * 2 elseif key == "q" then controls.E = -Settings.FlySpeed * 2 end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Track end end))
        table.insert(FlyConnections, UserInputService.InputEnded:Connect(function(input, processed) if processed then return end; if input.UserInputType == Enum.UserInputType.Keyboard then local key = input.KeyCode.Name:lower(); if key == "w" then controls.F = 0 elseif key == "s" then controls.B = 0 elseif key == "a" then controls.L = 0 elseif key == "d" then controls.R = 0 elseif key == "e" then controls.Q = 0 elseif key == "q" then controls.E = 0 end end end))
        table.insert(FlyConnections, RunService.RenderStepped:Connect(function() if not IsFlying then return end; local speed = (controls.L + controls.R ~= 0 or controls.F + controls.B ~= 0 or controls.Q + controls.E ~= 0) and 50 or 0; local camera = Workspace.CurrentCamera; if speed ~= 0 then bodyVelocity.Velocity = ((camera.CFrame.LookVector * (controls.F + controls.B)) + ((camera.CFrame * CFrame.new(controls.L + controls.R, (controls.F + controls.B + controls.Q + controls.E) * 0.2, 0).Position) - camera.CFrame.Position)) * speed else bodyVelocity.Velocity = Vector3.new(0, 0, 0) end; bodyGyro.CFrame = camera.CFrame end))
    end
    
    local function StopFly()
        if not IsFlying then return end; IsFlying = false; local character = LocalPlayer.Character; if character and character:FindFirstChildOfClass("Humanoid") then character.Humanoid.PlatformStand = false end; for _, conn in pairs(FlyConnections) do conn:Disconnect() end; FlyConnections = {}; local root = character and character:FindFirstChild("HumanoidRootPart"); if root then if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end; if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
    
    local function StopMobileFly()
        if not IsFlying then return end; IsFlying = false; local character = LocalPlayer.Character; if character and character:FindFirstChildOfClass("Humanoid") then character.Humanoid.PlatformStand = false end; for _, conn in pairs(FlyConnections) do conn:Disconnect() end; FlyConnections = {}; local root = character and character:FindFirstChild("HumanoidRootPart"); if root then if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end; if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
    
    local function StartMobileFly()
        if IsFlying then return end; local character = LocalPlayer.Character; if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then return end; local root = character:WaitForChild("HumanoidRootPart"); local humanoid = character:FindFirstChildOfClass("Humanoid"); local success, controlModule = pcall(require, LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule")); if not success then showNotification("Gagal memuat modul kontrol mobile.", Color3.fromRGB(255, 100, 100)); return end
        IsFlying = true; humanoid.PlatformStand = true; local bodyVelocity = Instance.new("BodyVelocity", root); bodyVelocity.Name = "FlyVelocity"; bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); bodyVelocity.Velocity = Vector3.new(0, 0, 0); local bodyGyro = Instance.new("BodyGyro", root); bodyGyro.Name = "FlyGyro"; bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bodyGyro.P = 1000; bodyGyro.D = 50
        table.insert(FlyConnections, RunService.RenderStepped:Connect(function() if not IsFlying then return end; local camera = Workspace.CurrentCamera; if not (character and root and root:FindFirstChild("FlyVelocity") and root:FindFirstChild("FlyGyro")) then StopMobileFly(); return end; root.FlyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); root.FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); root.FlyGyro.CFrame = camera.CFrame; root.FlyVelocity.Velocity = Vector3.new(0, 0, 0); local direction = controlModule:GetMoveVector(); if direction.X ~= 0 then root.FlyVelocity.Velocity = root.FlyVelocity.Velocity + camera.CFrame.RightVector * (direction.X * (Settings.FlySpeed * 50)) end; if direction.Z ~= 0 then root.FlyVelocity.Velocity = root.FlyVelocity.Velocity - camera.CFrame.LookVector * (direction.Z * (Settings.FlySpeed * 50)) end end))
        table.insert(FlyConnections, LocalPlayer.CharacterAdded:Connect(function() if IsFlying then task.wait(0.1); StartMobileFly() end end))
    end
    
    local function ToggleNoclip(enabled)
        IsNoclipEnabled = enabled
        if enabled then task.spawn(function() while IsNoclipEnabled and LocalPlayer.Character do for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end; task.wait(0.1) end; if LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end end) end
    end
    
    local function applyGodMode(character)
        if not character then return end; local humanoid = character:FindFirstChildOfClass("Humanoid"); if not humanoid then return end; if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
        godModeConnection = humanoid.HealthChanged:Connect(function(newHealth) if newHealth <= 0 and IsGodModeEnabled then humanoid.Health = humanoid.MaxHealth end end)
    end
    
    local function ToggleGodMode(enabled)
        IsGodModeEnabled = enabled; if enabled then if LocalPlayer.Character then applyGodMode(LocalPlayer.Character) end elseif godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
    end
    
    local function ToggleWalkSpeed(enabled)
        IsWalkSpeedEnabled = enabled; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = enabled and Settings.WalkSpeed or OriginalWalkSpeed end
    end
    
    local function CreateTouchFlingGUI()
        if touchFlingGui and touchFlingGui.Parent then return end; local FlingScreenGui = Instance.new("ScreenGui"); FlingScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"); FlingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; FlingScreenGui.ResetOnSpawn = false; touchFlingGui = FlingScreenGui
        local Frame = Instance.new("Frame", FlingScreenGui); Frame.BackgroundColor3 = Color3.fromRGB(170, 200, 255); Frame.BackgroundTransparency = 0.3; Frame.BorderSizePixel = 0; Frame.Position = UDim2.new(0.5, -45, 0.5, -28); Frame.Size = UDim2.new(0, 90, 0, 56); Frame.Active = true; Frame.Draggable = true; local FrameUICorner = Instance.new("UICorner", Frame); FrameUICorner.CornerRadius = UDim.new(0, 6); local FrameUIStroke = Instance.new("UIStroke", Frame); FrameUIStroke.Color = Color3.fromRGB(0, 100, 255); FrameUIStroke.Thickness = 1.5; FrameUIStroke.Transparency = 0.2
        local TitleBar = Instance.new("Frame", Frame); TitleBar.BackgroundColor3 = Color3.fromRGB(140, 170, 235); TitleBar.BackgroundTransparency = 0.4; TitleBar.BorderSizePixel = 0; TitleBar.Size = UDim2.new(1, 0, 0, 18); local TitleLabel = Instance.new("TextLabel", TitleBar); TitleLabel.BackgroundTransparency = 1.0; TitleLabel.Size = UDim2.new(1, -20, 1, 0); TitleLabel.Position = UDim2.new(0, 5, 0, 0); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.Text = "Touch Fling"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.TextSize = 11; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        local OnOffButton = Instance.new("TextButton", Frame); OnOffButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255); OnOffButton.BorderSizePixel = 0; OnOffButton.Position = UDim2.new(0.5, -30, 0, 25); OnOffButton.Size = UDim2.new(0, 60, 0, 22); OnOffButton.Font = Enum.Font.SourceSansBold; OnOffButton.Text = "OFF"; OnOffButton.TextColor3 = Color3.fromRGB(255, 255, 255); OnOffButton.TextSize = 14; local OnOffButtonCorner = Instance.new("UICorner", OnOffButton); OnOffButtonCorner.CornerRadius = UDim.new(0, 5); local OnOffButtonGradient = Instance.new("UIGradient", OnOffButton); OnOffButtonGradient.Color = ColorSequence.new(Color3.fromRGB(100, 180, 255), Color3.fromRGB(80, 150, 255)); OnOffButtonGradient.Rotation = 90
        local CloseButton = Instance.new("TextButton", TitleBar); CloseButton.Size = UDim2.new(0, 16, 0, 16); CloseButton.Position = UDim2.new(1, -18, 0.5, -8); CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseButton.Text = "X"; CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255); CloseButton.Font = Enum.Font.SourceSansBold; CloseButton.TextSize = 11; local corner = Instance.new("UICorner", CloseButton); corner.CornerRadius = UDim.new(1, 0)
        local hiddenfling, flingThread = false, nil
        local function fling() while hiddenfling do local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp then local vel = hrp.Velocity; hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0); RunService.RenderStepped:Wait(); if hrp and hrp.Parent then hrp.Velocity = vel end; RunService.Stepped:Wait(); if hrp and hrp.Parent then hrp.Velocity = vel + Vector3.new(0, 0.1 * (math.random(0, 1) == 0 and -1 or 1), 0) end end; RunService.Heartbeat:Wait() end end
        OnOffButton.MouseButton1Click:Connect(function() hiddenfling = not hiddenfling; OnOffButton.Text = hiddenfling and "ON" or "OFF"; if hiddenfling then if not flingThread or coroutine.status(flingThread) == "dead" then flingThread = coroutine.create(fling); coroutine.resume(flingThread) end end end)
        CloseButton.MouseButton1Click:Connect(function() hiddenfling = false; FlingScreenGui:Destroy(); touchFlingGui = nil end)
    end
    
    local function ToggleKillAura(enabled)
        IsKillAuraEnabled = enabled
        if enabled then KillAuraConnection = RunService.Heartbeat:Connect(function() local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not root then return end; for _, npc in pairs(Workspace:GetDescendants()) do if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then local humanoid = npc.Humanoid; if humanoid.Health > 0 and (npc.HumanoidRootPart.Position - root.Position).Magnitude <= Settings.KillAuraRadius then humanoid:TakeDamage(Settings.KillAuraDamage) end end end end)
        elseif KillAuraConnection then KillAuraConnection:Disconnect(); KillAuraConnection = nil end
    end
    
    local function ToggleAimbot(enabled)
        IsAimbotEnabled = enabled
        if enabled then CreateFOVCircle(); AimbotConnection = RunService.RenderStepped:Connect(function() local camera = Workspace.CurrentCamera; local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not (root and camera) then return end; local mousePos = UserInputService:GetMouseLocation(); local closestNPC, closestDistance = nil, Settings.AimbotFOV; for _, npc in pairs(Workspace:GetDescendants()) do if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild(Settings.AimbotPart) then local humanoid = npc.Humanoid; if humanoid.Health > 0 then local screenPos, onScreen = camera:WorldToViewportPoint(npc[Settings.AimbotPart].Position); if onScreen then local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude; if distance <= closestDistance then closestDistance, closestNPC = distance, npc end end end end end; AimbotTarget = closestNPC; if AimbotTarget and AimbotTarget:FindFirstChild(Settings.AimbotPart) then camera.CFrame = CFrame.new(camera.CFrame.Position, AimbotTarget[Settings.AimbotPart].Position); AimbotTarget.Humanoid:TakeDamage(Settings.KillAuraDamage) end; if FOVPart then FOVPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0)); FOVPart.FOVGui.Enabled = true end end)
        else if AimbotConnection then AimbotConnection:Disconnect(); AimbotConnection = nil end; AimbotTarget = nil; if FOVPart then FOVPart:Destroy(); FOVPart = nil end end
    end
    
    local function protect_character()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if root and antifling_enabled then if root.Velocity.Magnitude <= antifling_velocity_threshold then antifling_last_safe_cframe = root.CFrame end; if root.Velocity.Magnitude > antifling_velocity_threshold and antifling_last_safe_cframe then root.Velocity, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity, root.CFrame = Vector3.new(), Vector3.new(), Vector3.new(), antifling_last_safe_cframe end; if root.AssemblyAngularVelocity.Magnitude > antifling_angular_threshold then root.AssemblyAngularVelocity = Vector3.new() end; if LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end
    end
    
    local function ToggleAntiFling(enabled)
        antifling_enabled = enabled; if enabled and not antifling_connection then antifling_connection = RunService.Heartbeat:Connect(protect_character) elseif not enabled and antifling_connection then antifling_connection:Disconnect(); antifling_connection = nil end
    end
    
    local function ToggleAntiLag(enabled)
        IsAntiLagEnabled = enabled; local currentSettings = settings()
        if enabled then
            if not OriginalGraphicsSettings.Technology then OriginalGraphicsSettings.Technology = Lighting.Technology; OriginalGraphicsSettings.GlobalShadows = Lighting.GlobalShadows; OriginalGraphicsSettings.QualityLevel = currentSettings.Rendering.QualityLevel; OriginalGraphicsSettings.MaterialQuality = MaterialService.MaterialQuality; OriginalGraphicsSettings.Descendants = {}; for _, v in pairs(Lighting:GetDescendants()) do if v:IsA("PostEffect") then OriginalGraphicsSettings.Descendants[v] = v.Enabled end end; if Workspace:FindFirstChild("Terrain") then OriginalGraphicsSettings.Decoration = Workspace.Terrain.Decoration; OriginalGraphicsSettings.WaterWaveSize = Workspace.Terrain.WaterWaveSize; OriginalGraphicsSettings.WaterWaveSpeed = Workspace.Terrain.WaterWaveSpeed; OriginalGraphicsSettings.WaterReflectance = Workspace.Terrain.WaterReflectance end end
            Lighting.Technology = Enum.Technology.Compatibility; Lighting.GlobalShadows = false; currentSettings.Rendering.QualityLevel = Enum.QualityLevel.Level01; MaterialService.MaterialQuality = Enum.MaterialQuality.Low; for _, v in pairs(Lighting:GetDescendants()) do if v:IsA("PostEffect") then v.Enabled = false end end; if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = false; Workspace.Terrain.WaterWaveSize = 0; Workspace.Terrain.WaterWaveSpeed = 0; Workspace.Terrain.WaterReflectance = 0 end
        else
            if OriginalGraphicsSettings.Technology then Lighting.Technology = OriginalGraphicsSettings.Technology; Lighting.GlobalShadows = OriginalGraphicsSettings.GlobalShadows; currentSettings.Rendering.QualityLevel = OriginalGraphicsSettings.QualityLevel; MaterialService.MaterialQuality = OriginalGraphicsSettings.MaterialQuality; for v, originalState in pairs(OriginalGraphicsSettings.Descendants) do if v and v.Parent then v.Enabled = originalState end end; if Workspace:FindFirstChild("Terrain") then if OriginalGraphicsSettings.Decoration ~= nil then Workspace.Terrain.Decoration = OriginalGraphicsSettings.Decoration end; if OriginalGraphicsSettings.WaterWaveSize ~= nil then Workspace.Terrain.WaterWaveSize = OriginalGraphicsSettings.WaterWaveSize end; if OriginalGraphicsSettings.WaterWaveSpeed ~= nil then Workspace.Terrain.WaterWaveSpeed = OriginalGraphicsSettings.WaterWaveSpeed end; if OriginalGraphicsSettings.WaterReflectance ~= nil then Workspace.Terrain.WaterReflectance = OriginalGraphicsSettings.WaterReflectance end end; OriginalGraphicsSettings = {} end
        end
    end
    
    local function DisableAllFeatures()
        if IsFlying then if UserInputService.TouchEnabled then StopMobileFly() else StopFly() end end; if IsWalkSpeedEnabled then ToggleWalkSpeed(false) end; if IsNoclipEnabled then ToggleNoclip(false) end; if IsGodModeEnabled then ToggleGodMode(false) end; if IsKillAuraEnabled then ToggleKillAura(false) end; if IsAimbotEnabled then ToggleAimbot(false) end; if IsInfinityJumpEnabled then IsInfinityJumpEnabled = false; if infinityJumpConnection then infinityJumpConnection:Disconnect(); infinityJumpConnection = nil end end; if antifling_enabled then ToggleAntiFling(false) end; if IsAntiLagEnabled then ToggleAntiLag(false) end; if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = OriginalWalkSpeed end
    end
    
    local function CloseScript()
        DisableAllFeatures(); ScreenGui:Destroy(); if touchFlingGui and touchFlingGui.Parent then touchFlingGui:Destroy() end
    end
    
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.1); if character:FindFirstChildOfClass("Humanoid") then character.Humanoid.WalkSpeed = IsWalkSpeedEnabled and Settings.WalkSpeed or OriginalWalkSpeed end; if antifling_enabled then ToggleAntiFling(true) end; if IsGodModeEnabled then applyGodMode(character) end 
    end)
    
    -- ====================================================================
    -- == BAGIAN PEMBUATAN ELEMEN UI (SLIDER, TOGGLE, DLL)             ==
    -- ====================================================================
    
    local function createSlider(parent, name, min, max, current, suffix, increment, callback)
        local sliderFrame = Instance.new("Frame", parent); sliderFrame.Size = UDim2.new(1, 0, 0, 50); sliderFrame.BackgroundTransparency = 1; local titleLabel = Instance.new("TextLabel", sliderFrame); titleLabel.Size = UDim2.new(1, 0, 0, 15); titleLabel.BackgroundTransparency = 1; titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200); titleLabel.TextSize = 12; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Text = name .. ": " .. tostring(math.floor(current * 10) / 10) .. " " .. suffix; titleLabel.Font = Enum.Font.SourceSans
        local sliderBase = Instance.new("Frame", sliderFrame); sliderBase.Name = "SliderBase"; sliderBase.Size = UDim2.new(1, 0, 0, 10); sliderBase.Position = UDim2.new(0, 0, 0, 25); sliderBase.BackgroundColor3 = Color3.fromRGB(35, 35, 35); sliderBase.BorderSizePixel = 0; local sbCorner = Instance.new("UICorner", sliderBase); sbCorner.CornerRadius = UDim.new(0, 5)
        local sliderFill = Instance.new("Frame", sliderBase); sliderFill.Name = "SliderFill"; local fillWidth = (current - min) / (max - min); sliderFill.Size = UDim2.new(fillWidth, 0, 1, 0); sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); sliderFill.BorderSizePixel = 0; local sfCorner = Instance.new("UICorner", sliderFill); sfCorner.CornerRadius = UDim.new(0, 5)
        local sliderThumb = Instance.new("Frame", sliderBase); sliderThumb.Name = "SliderThumb"; sliderThumb.Size = UDim2.new(0, 15, 0, 25); sliderThumb.Position = UDim2.new(fillWidth, -7.5, 0.5, -12.5); sliderThumb.BackgroundColor3 = Color3.fromRGB(0, 200, 255); sliderThumb.BorderSizePixel = 0; local stCorner = Instance.new("UICorner", sliderThumb); stCorner.CornerRadius = UDim.new(0, 5); local stStroke = Instance.new("UIStroke", sliderThumb); stStroke.Color = Color3.fromRGB(255, 255, 255); stStroke.Thickness = 1; stStroke.Transparency = 0.8
        local isDraggingSlider = false; local function updateSlider(input) local pos = input.Position.X - sliderBase.AbsolutePosition.X; local newWidth = math.min(math.max(pos, 0), sliderBase.AbsoluteSize.X); local newValue = min + (newWidth / sliderBase.AbsoluteSize.X) * (max - min); newValue = math.floor(newValue / increment) * increment; local newFillWidth = (newValue - min) / (max - min); sliderFill.Size = UDim2.new(newFillWidth, 0, 1, 0); sliderThumb.Position = UDim2.new(newFillWidth, -7.5, 0.5, -12.5); titleLabel.Text = name .. ": " .. tostring(math.floor(newValue * 10) / 10) .. " " .. suffix; callback(newValue) end
        sliderBase.InputBegan:Connect(function(input, processed) if processed then return end; if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingSlider = true; updateSlider(input) end end)
        sliderBase.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingSlider = false end end)
        UserInputService.InputChanged:Connect(function(input) if isDraggingSlider then updateSlider(input) end end)
        return sliderFrame
    end
    
    local function createToggle(parent, name, initialState, callback)
        local toggleFrame = Instance.new("Frame", parent); toggleFrame.Size = UDim2.new(1, 0, 0, 25); toggleFrame.BackgroundTransparency = 1; local toggleLabel = Instance.new("TextLabel", toggleFrame); toggleLabel.Size = UDim2.new(0.8, -10, 1, 0); toggleLabel.Position = UDim2.new(0, 5, 0, 0); toggleLabel.BackgroundTransparency = 1; toggleLabel.Text = name; toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); toggleLabel.TextSize = 12; toggleLabel.TextXAlignment = Enum.TextXAlignment.Left; toggleLabel.Font = Enum.Font.SourceSans
        local switch = Instance.new("TextButton", toggleFrame); switch.Name = "Switch"; switch.Size = UDim2.new(0, 40, 0, 20); switch.Position = UDim2.new(1, -50, 0.5, -10); switch.BackgroundColor3 = Color3.fromRGB(50, 50, 50); switch.BorderSizePixel = 0; switch.Text = ""; local switchCorner = Instance.new("UICorner", switch); switchCorner.CornerRadius = UDim.new(1, 0)
        local thumb = Instance.new("Frame", switch); thumb.Name = "Thumb"; thumb.Size = UDim2.new(0, 16, 0, 16); thumb.Position = UDim2.new(0, 2, 0.5, -8); thumb.BackgroundColor3 = Color3.fromRGB(220, 220, 220); thumb.BorderSizePixel = 0; local thumbCorner = Instance.new("UICorner", thumb); thumbCorner.CornerRadius = UDim.new(1, 0)
        local onColor, offColor = Color3.fromRGB(0, 150, 255), Color3.fromRGB(60, 60, 60); local onPosition, offPosition = UDim2.new(1, -18, 0.5, -8), UDim2.new(0, 2, 0.5, -8); local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out); local isToggled = initialState
        local function updateVisuals(isInstant) local goalPosition, goalColor = isToggled and onPosition or offPosition, isToggled and onColor or offColor; if isInstant then thumb.Position, switch.BackgroundColor3 = goalPosition, goalColor else TweenService:Create(thumb, tweenInfo, {Position = goalPosition}):Play(); TweenService:Create(switch, tweenInfo, {BackgroundColor3 = goalColor}):Play() end end
        switch.MouseButton1Click:Connect(function() isToggled = not isToggled; updateVisuals(false); callback(isToggled) end); updateVisuals(true)
        return toggleFrame, switch
    end
    
    local function createDropdown(parent, name, options, current, callback)
        local dropdownFrame = Instance.new("Frame", parent); dropdownFrame.Size = UDim2.new(1, 0, 0, 50); dropdownFrame.BackgroundTransparency = 1; local label = Instance.new("TextLabel", dropdownFrame); label.Size = UDim2.new(1, 0, 0, 20); label.BackgroundTransparency = 1; label.TextXAlignment = Enum.TextXAlignment.Left; label.Text = name .. ": " .. current; label.TextColor3 = Color3.fromRGB(255, 255, 255); label.TextSize = 12; label.Font = Enum.Font.SourceSans
        local optionButton = Instance.new("TextButton", dropdownFrame); optionButton.Size = UDim2.new(1, 0, 0, 25); optionButton.Position = UDim2.new(0, 0, 0, 25); optionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255); optionButton.BorderSizePixel = 0; optionButton.Text = "Ubah Target"; optionButton.TextColor3 = Color3.fromRGB(255, 255, 255); optionButton.TextSize = 12; optionButton.Font = Enum.Font.SourceSans; local btnCorner = Instance.new("UICorner", optionButton); btnCorner.CornerRadius = UDim.new(0, 5)
        local currentIndex = 1; optionButton.MouseButton1Click:Connect(function() currentIndex = currentIndex + 1; if currentIndex > #options then currentIndex = 1 end; local newOption = options[currentIndex]; label.Text = name .. ": " .. newOption; callback(newOption) end); return dropdownFrame
    end
    
    -- ====================================================================
    -- == BAGIAN PENGATURAN KONTEN TAB                                  ==
    -- ====================================================================
    
    -- Tab Player
    local playerHeaderFrame = Instance.new("Frame", PlayerTabContent); playerHeaderFrame.Size = UDim2.new(1, 0, 0, 55); playerHeaderFrame.BackgroundTransparency = 1
    local playerCountLabel = Instance.new("TextLabel", playerHeaderFrame); playerCountLabel.Name = "PlayerCountLabel"; playerCountLabel.Size = UDim2.new(1, -20, 0, 15); playerCountLabel.BackgroundTransparency = 1; playerCountLabel.Text = "Pemain Online: " .. #Players:GetPlayers(); playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255); playerCountLabel.TextSize = 12; playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left; playerCountLabel.Font = Enum.Font.SourceSansBold
    
    local refreshButton = Instance.new("TextButton", playerHeaderFrame)
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 15, 0, 15)
    refreshButton.Position = UDim2.new(1, -15, 0, 0)
    refreshButton.BackgroundTransparency = 1
    refreshButton.Text = "🔄"
    refreshButton.TextColor3 = Color3.fromRGB(0, 200, 255)
    refreshButton.TextSize = 14
    refreshButton.Font = Enum.Font.SourceSansBold
    
    local isAnimatingRefresh = false
    refreshButton.MouseButton1Click:Connect(function() 
        if isAnimatingRefresh then return end
        isAnimatingRefresh = true
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(refreshButton, tweenInfo, { Rotation = refreshButton.Rotation + 360 })
        tween:Play()
        if updatePlayerList then updatePlayerList() end 
        tween.Completed:Connect(function()
            isAnimatingRefresh = false
        end)
    end)

    local searchFrame = Instance.new("Frame", playerHeaderFrame); searchFrame.Size = UDim2.new(1, 0, 0, 25); searchFrame.Position = UDim2.new(0, 0, 0, 20); searchFrame.BackgroundTransparency = 1
    local searchTextBox = Instance.new("TextBox", searchFrame); searchTextBox.Size = UDim2.new(0.7, -10, 1, 0); searchTextBox.Position = UDim2.new(0, 5, 0, 0); searchTextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35); searchTextBox.TextColor3 = Color3.fromRGB(200, 200, 200); searchTextBox.PlaceholderText = "Cari Pemain..."; searchTextBox.TextSize = 12; searchTextBox.Font = Enum.Font.SourceSans; searchTextBox.ClearTextOnFocus = true; local sboxCorner = Instance.new("UICorner", searchTextBox); sboxCorner.CornerRadius = UDim.new(0, 5)
    local searchButton = Instance.new("TextButton", searchFrame); searchButton.Size = UDim2.new(0.3, 0, 1, 0); searchButton.Position = UDim2.new(0.7, 0, 0, 0); searchButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255); searchButton.BorderSizePixel = 0; searchButton.Text = "Cari"; searchButton.TextColor3 = Color3.fromRGB(255, 255, 255); searchButton.TextSize = 12; searchButton.Font = Enum.Font.SourceSansBold; local sbtnCorner = Instance.new("UICorner", searchButton); sbtnCorner.CornerRadius = UDim.new(0, 5)
    
    local function createPlayerButton(player)
        local playerFrame = Instance.new("Frame", PlayerListContainer); playerFrame.Size = UDim2.new(1, 0, 0, 50); playerFrame.BackgroundTransparency = 1; playerFrame.Name = player.Name
        local avatarImage = Instance.new("ImageLabel", playerFrame); avatarImage.Size = UDim2.new(0, 30, 0, 30); avatarImage.Position = UDim2.new(0, 5, 0.5, -15); avatarImage.BackgroundTransparency = 1
        local success, _ = pcall(function() avatarImage.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end); if not success then warn("Gagal memuat thumbnail untuk", player.Name) end
        local displaynameLabel = Instance.new("TextLabel", playerFrame); displaynameLabel.Size = UDim2.new(1, -90, 0, 15); displaynameLabel.Position = UDim2.new(0, 40, 0, 2); displaynameLabel.BackgroundTransparency = 1; displaynameLabel.TextXAlignment = Enum.TextXAlignment.Left; displaynameLabel.Text = player.DisplayName; displaynameLabel.TextColor3 = Color3.fromRGB(255, 255, 255); displaynameLabel.TextSize = 11; displaynameLabel.Font = Enum.Font.SourceSansSemibold
        local usernameLabel = Instance.new("TextLabel", playerFrame); usernameLabel.Size = UDim2.new(1, -90, 0, 15); usernameLabel.Position = UDim2.new(0, 40, 0, 18); usernameLabel.BackgroundTransparency = 1; usernameLabel.TextXAlignment = Enum.TextXAlignment.Left; usernameLabel.Text = "@" .. player.Name; usernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150); usernameLabel.TextSize = 9; usernameLabel.Font = Enum.Font.SourceSans
        local distanceLabel = Instance.new("TextLabel", playerFrame); distanceLabel.Name = "DistanceLabel"; distanceLabel.Size = UDim2.new(1, -90, 0, 15); distanceLabel.Position = UDim2.new(0, 40, 0, 34); distanceLabel.BackgroundTransparency = 1; distanceLabel.TextXAlignment = Enum.TextXAlignment.Left; distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 127); distanceLabel.TextSize = 10; distanceLabel.Font = Enum.Font.SourceSansSemibold
        local teleportButton = createButton(playerFrame, "TP", function() if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position) end end); teleportButton.Size = UDim2.new(0, 40, 0, 20); teleportButton.Position = UDim2.new(1, -45, 0.5, -10); teleportButton.TextSize = 10
        return playerFrame
    end
    
    updatePlayerList = function()
        if isUpdatingPlayerList then return end
        if not (MainFrame.Visible and PlayerTabContent.Visible) then return end
        isUpdatingPlayerList = true
        pcall(function()
            playerCountLabel.Text = "Pemain Online: " .. #Players:GetPlayers()
            local currentPlayers = {}; for _, player in ipairs(Players:GetPlayers()) do currentPlayers[player.UserId] = player end
            for userId, button in pairs(PlayerButtons) do if not currentPlayers[userId] then button:Destroy(); PlayerButtons[userId] = nil end end
            for i, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local passesFilter = (CurrentPlayerFilter == "" or CurrentPlayerFilter == "Cari Pemain..." or player.Name:lower():find(CurrentPlayerFilter:lower(), 1, true) or player.DisplayName:lower():find(CurrentPlayerFilter:lower(), 1, true))
                    local existingButton = PlayerButtons[player.UserId]
                    if not existingButton then existingButton = createPlayerButton(player); PlayerButtons[player.UserId] = existingButton end
                    existingButton.Visible = passesFilter; existingButton.LayoutOrder = i 
                    local distLabel = existingButton:FindFirstChild("DistanceLabel")
                    if distLabel then
                        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local targetHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        distLabel.Text = (localHRP and targetHRP) and tostring(math.floor((localHRP.Position - targetHRP.Position).Magnitude)) .. "m" or "..."
                    end
                end
            end
        end)
        isUpdatingPlayerList = false
    end
    
    searchTextBox.FocusLost:Connect(function() CurrentPlayerFilter = searchTextBox.Text; updatePlayerList() end)
    searchButton.MouseButton1Click:Connect(function() CurrentPlayerFilter = searchTextBox.Text; updatePlayerList() end)
    
    task.spawn(function() while task.wait(1) do if updatePlayerList then updatePlayerList() end end end)
    Players.PlayerAdded:Connect(function() task.wait(0.5); if updatePlayerList then updatePlayerList() end end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); if updatePlayerList then updatePlayerList() end end)
    
    -- Tab Umum
    createSlider(GeneralTabContent, "Kecepatan Jalan", 0, Settings.MaxWalkSpeed, Settings.WalkSpeed, "", 1, function(v) Settings.WalkSpeed = v; if IsWalkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character.Humanoid then LocalPlayer.Character.Humanoid.WalkSpeed = v end end)
    createToggle(GeneralTabContent, "Jalan Cepat", IsWalkSpeedEnabled, function(v) IsWalkSpeedEnabled = v; ToggleWalkSpeed(v) end)
    createSlider(GeneralTabContent, "Kecepatan Terbang", 0, Settings.MaxFlySpeed, Settings.FlySpeed, "", 0.1, function(v) Settings.FlySpeed = v end)
    createToggle(GeneralTabContent, "Terbang", IsFlying, function(v) if v then if UserInputService.TouchEnabled then StartMobileFly() else StartFly() end else if UserInputService.TouchEnabled then StopMobileFly() else StopFly() end end end)
    createToggle(GeneralTabContent, "Noclip", IsNoclipEnabled, function(v) ToggleNoclip(v) end)
    createToggle(GeneralTabContent, "Infinity Jump", IsInfinityJumpEnabled, function(v) IsInfinityJumpEnabled = v; if v then if LocalPlayer.Character and LocalPlayer.Character.Humanoid then infinityJumpConnection = UserInputService.JumpRequest:Connect(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end elseif infinityJumpConnection then infinityJumpConnection:Disconnect(); infinityJumpConnection = nil end end)
    createToggle(GeneralTabContent, "Mode Kebal", IsGodModeEnabled, ToggleGodMode) 
    createButton(GeneralTabContent, "Buka Touch Fling", CreateTouchFlingGUI)
    createToggle(GeneralTabContent, "Anti-Fling", antifling_enabled, ToggleAntiFling)
    createToggle(GeneralTabContent, "Anti Lag", IsAntiLagEnabled, ToggleAntiLag)
    
    -- Tab Tempur
    createSlider(CombatTabContent, "Radius Aura Serang", 0, Settings.MaxKillAuraRadius, Settings.KillAuraRadius, "Studs", 1, function(v) Settings.KillAuraRadius = v end)
    createSlider(CombatTabContent, "Kerusakan", 0, Settings.MaxKillAuraDamage, Settings.KillAuraDamage, "HP", 1, function(v) Settings.KillAuraDamage = v end)
    createToggle(CombatTabContent, "Aura Serang", IsKillAuraEnabled, ToggleKillAura)
    createSlider(CombatTabContent, "FOV Aimbot", 0, Settings.MaxAimbotFOV, Settings.AimbotFOV, "Piksel", 1, function(v) Settings.AimbotFOV = v; UpdateFOVCircle() end)
    createDropdown(CombatTabContent, "Target Aimbot", {"Head", "HumanoidRootPart", "Torso"}, Settings.AimbotPart, function(v) Settings.AimbotPart = v end)
    createToggle(CombatTabContent, "Aimbot", IsAimbotEnabled, ToggleAimbot)
    
    -- Tab Teleport
    createButton(TeleportTabContent, "Pindai Ulang Map", function() for _, part in pairs(Workspace:GetDescendants()) do if part:IsA("BasePart") then local nameLower = part.Name:lower(); if (nameLower:find("checkpoint") or nameLower:find("pos") or nameLower:find("finish") or nameLower:find("start")) and not Players:GetPlayerFromCharacter(part.Parent) then addTeleportLocation(part.Name, part.CFrame) end end end end).LayoutOrder = 1
    createButton(TeleportTabContent, "Simpan Lokasi Saat Ini", function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then local newName = "Kustom " .. (#savedTeleportLocations + 1); addTeleportLocation(newName, LocalPlayer.Character.HumanoidRootPart.CFrame) end end).LayoutOrder = 2
    createButton(TeleportTabContent, "Ekspor Semua", function() if not setclipboard then showNotification("Executor tidak mendukung clipboard!", Color3.fromRGB(200, 50, 50)); return end; local dataToExport = {}; for _, loc in ipairs(savedTeleportLocations) do table.insert(dataToExport, { Name = loc.Name, CFrameData = {loc.CFrame:GetComponents()} }) end; local success, result = pcall(function() local jsonData = HttpService:JSONEncode(dataToExport); setclipboard(jsonData); showNotification("Data disalin ke clipboard!", Color3.fromRGB(50, 200, 50)) end); if not success then showNotification("Gagal mengekspor data!", Color3.fromRGB(200, 50, 50)) end end).LayoutOrder = 3
    createButton(TeleportTabContent, "Impor Semua", function() showImportPrompt(function(text) if not text or text == "" then return end; local success, decodedData = pcall(HttpService.JSONDecode, HttpService, text); if not success or type(decodedData) ~= "table" then showNotification("Data impor tidak valid!", Color3.fromRGB(200, 50, 50)); return end; local existingNames = {}; for _, loc in ipairs(savedTeleportLocations) do existingNames[loc.Name] = true end; local importedCount = 0; for _, data in ipairs(decodedData) do if type(data) == "table" and data.Name and data.CFrameData and not existingNames[data.Name] then local cframe = CFrame.new(unpack(data.CFrameData)); table.insert(savedTeleportLocations, { Name = data.Name, CFrame = cframe }); existingNames[data.Name] = true; importedCount = importedCount + 1 end end; if importedCount > 0 then table.sort(savedTeleportLocations, naturalCompare); saveTeleportData(); updateTeleportList(); showNotification(importedCount .. " lokasi berhasil diimpor!", Color3.fromRGB(50, 200, 50)) else showNotification("Tidak ada lokasi baru untuk diimpor.", Color3.fromRGB(200, 150, 50)) end end) end).LayoutOrder = 4
    
    -- Tab Pengaturan
    createToggle(SettingsTabContent, "Kunci Tombol ◀", not isMiniToggleDraggable, function(v)
        isMiniToggleDraggable = not v
    end).LayoutOrder = 1
    createButton(SettingsTabContent, "Tutup Skrip", CloseScript).LayoutOrder = 2
    
    -- =================================================================================
    -- == FUNGSI UNTUK MEMBUAT GUI DAPAT DIGESER (DRAGGABLE)                          ==
    -- =================================================================================
    local function MakeDraggable(guiObject, dragHandle)
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local isDragging = false; local dragStartMousePos = input.Position; local startObjectPos = guiObject.Position; local inputChangedConnection; local inputEndedConnection; local DRAG_THRESHOLD = 5
                
                inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInput) 
                    if changedInput.UserInputType == input.UserInputType then 
                        local delta = changedInput.Position - dragStartMousePos
                        
                        if not isDragging and delta.Magnitude > DRAG_THRESHOLD then 
                            if not (dragHandle == MiniToggleButton and not isMiniToggleDraggable) then
                                isDragging = true 
                            end
                        end
                        
                        if isDragging then 
                            guiObject.Position = UDim2.new(startObjectPos.X.Scale, startObjectPos.X.Offset + delta.X, startObjectPos.Y.Scale, startObjectPos.Y.Offset + delta.Y) 
                        end 
                    end 
                end)

                inputEndedConnection = UserInputService.InputEnded:Connect(function(endedInput)
                     if endedInput.UserInputType == input.UserInputType then
                        if inputChangedConnection then inputChangedConnection:Disconnect() end
                        if inputEndedConnection then inputEndedConnection:Disconnect() end
                        
                        if dragHandle == MiniToggleButton and not isDragging then
                            MainFrame.Visible = not MainFrame.Visible; MiniToggleButton.Text = MainFrame.Visible and "◀" or "▶"; MiniToggleButton.BackgroundTransparency = MainFrame.Visible and 0.5 or 1
                            if MainFrame.Visible then
                                if not (PlayerTabContent.Visible or GeneralTabContent.Visible or CombatTabContent.Visible or TeleportTabContent.Visible or SettingsTabContent.Visible) then switchTab("Player") else updatePlayerList() end
                            end
                        end
                     end
                end)
            end
        end)
    end
    
    MakeDraggable(MainFrame, TitleBar)
    MakeDraggable(MiniToggleButton, MiniToggleButton)
    
    -- Toggle terbang dengan tombol F
    UserInputService.InputBegan:Connect(function(input, processed) 
        if processed then return end; if input.KeyCode == Enum.KeyCode.F and not UserInputService.TouchEnabled then if not IsFlying then StartFly() else StopFly() end end 
    end)
    
    -- INISIALISASI
    loadTeleportData()
    switchTab("Player")
    if LocalPlayer.Character and IsGodModeEnabled then applyGodMode(LocalPlayer.Character) end
end)

