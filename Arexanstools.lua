local SCRIPT_URL = "https://raw.githubusercontent.com/AREXANS/emoteff/refs/heads/main/Arexanstools.lua" -- << WAJIB DIISI!

-- Mencegah GUI dibuat berulang kali jika skrip dieksekusi lebih dari sekali tanpa me-refresh game.
if game:GetService("CoreGui"):FindFirstChild("ArexansToolsGUI") then
    game:GetService("CoreGui"):FindFirstChild("ArexansToolsGUI"):Destroy()
end

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
    local TeleportService = game:GetService("TeleportService")
    
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
    local isMiniToggleDraggable = true 
    local IsAntiLagEnabled = false 
    local antiLagConnection = nil 
    local IsInvisibilityEnabled = false -- Variabel untuk fitur invisible BARU
    
    local isEmoteToggleDraggable = true
    local isAnimationToggleDraggable = true

    local isEmoteTransparent = true
    local isAnimationTransparent = true

    -- Variabel Teleport
    local savedTeleportLocations = {}
    local TELEPORT_SAVE_FILE = "ArexansTools_Teleports_" .. tostring(game.PlaceId) .. ".json"
    
    -- BARU: Variabel untuk menyimpan posisi GUI
    local GUI_POSITIONS_SAVE_FILE = "ArexansTools_GuiPositions_" .. tostring(game.PlaceId) .. ".json"
    local loadedGuiPositions = nil
    
    -- [[ PERBAIKAN HOP SERVER ]] --
    -- Variabel untuk menyimpan status fitur
    local FEATURE_STATES_SAVE_FILE = "ArexansTools_FeatureStates_" .. tostring(game.PlaceId) .. ".json"
    
    -- Variabel untuk menyimpan data original karakter saat invisible
    local originalCharacterAppearance = {}

    -- Variabel AntiFling
    local antifling_velocity_threshold = 85
    local antifling_angular_threshold = 25
    local antifling_last_safe_cframe = nil
    local antifling_enabled = false
    local antifling_connection = nil
    
    -- ====================================================================
    -- == VARIABEL UNTUK FITUR EMOTE DAN ANIMASI (DIPISAHKAN)          ==
    -- ====================================================================
    -- Fitur Emote Asli
    local isEmoteEnabled = false
    local EmoteScreenGui = nil
    -- Fitur Animasi VIP (Integrasi)
    local isAnimationEnabled = false 
    local AnimationScreenGui = nil 
    
    -- ## PERBAIKAN ANIMASI: Variabel Global untuk menyimpan animasi
    local lastAnimations = {}
    local ANIMATION_SAVE_FILE = "ArexansTools_Animations.json" -- File penyimpanan global

    -- Membuat GUI utama
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArexansToolsGUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    -- Kontainer untuk semua tombol mini
    -- ## PERBAIKAN: Diubah ke TextButton untuk menangkap input mouse dengan lebih baik saat digeser
    local MiniToggleContainer = Instance.new("TextButton")
    MiniToggleContainer.Name = "MiniToggleContainer"
    MiniToggleContainer.AnchorPoint = Vector2.new(1, 0.5)
    MiniToggleContainer.Position = UDim2.new(1, -25, 0.5, -7.5) 
    MiniToggleContainer.BackgroundTransparency = 1
    MiniToggleContainer.BorderSizePixel = 0
    MiniToggleContainer.AutomaticSize = Enum.AutomaticSize.X
    MiniToggleContainer.Size = UDim2.new(0,0,0,25) 
    MiniToggleContainer.Text = ""
    MiniToggleContainer.AutoButtonColor = false
    MiniToggleContainer.Parent = ScreenGui
    
    local MiniToggleLayout = Instance.new("UIListLayout")
    MiniToggleLayout.FillDirection = Enum.FillDirection.Horizontal
    MiniToggleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    MiniToggleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    MiniToggleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MiniToggleLayout.Padding = UDim.new(0, 5)
    MiniToggleLayout.Parent = MiniToggleContainer
    
    -- Tombol toggle utama
    local MiniToggleButton = Instance.new("TextButton")
    MiniToggleButton.Name = "MiniToggleButton"
    MiniToggleButton.LayoutOrder = 1
    MiniToggleButton.Size = UDim2.new(0, 15, 0, 15)
    MiniToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MiniToggleButton.BackgroundTransparency = 1
    MiniToggleButton.BorderSizePixel = 0
    MiniToggleButton.Text = "◀"
    MiniToggleButton.TextColor3 = Color3.fromRGB(0, 200, 255)
    MiniToggleButton.TextSize = 10
    MiniToggleButton.Font = Enum.Font.SourceSansBold
    MiniToggleButton.Parent = MiniToggleContainer
    
    local MiniUICorner = Instance.new("UICorner", MiniToggleButton)
    MiniUICorner.CornerRadius = UDim.new(0, 8)
    
    local MiniUIStroke = Instance.new("UIStroke", MiniToggleButton)
    MiniUIStroke.Color = Color3.fromRGB(0, 150, 255)
    MiniUIStroke.Thickness = 2
    MiniUIStroke.Transparency = 0.5
    MiniUIStroke.Parent = MiniToggleButton
    
    -- Tombol toggle Emote (🤡)
    local EmoteToggleButton = Instance.new("TextButton")
    EmoteToggleButton.Name = "EmoteToggleButton"
    EmoteToggleButton.LayoutOrder = 2
    EmoteToggleButton.Size = UDim2.new(0, 25, 0, 25)
    EmoteToggleButton.BackgroundColor3 = Color3.fromRGB(48, 63, 90)
    EmoteToggleButton.BorderColor3 = Color3.fromRGB(90, 150, 255)
    EmoteToggleButton.BorderSizePixel = 1
    EmoteToggleButton.Font = Enum.Font.GothamBold
    EmoteToggleButton.Text = "🤡"
    EmoteToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    EmoteToggleButton.TextSize = 24
    EmoteToggleButton.Visible = false 
    EmoteToggleButton.Parent = MiniToggleContainer
    local EmoteToggleCorner = Instance.new("UICorner", EmoteToggleButton)
    EmoteToggleCorner.CornerRadius = UDim.new(0, 8)
    
    -- Tombol toggle Animasi (😀)
    local AnimationShowButton = Instance.new("TextButton")
    AnimationShowButton.Name = "AnimationShowButton"
    AnimationShowButton.LayoutOrder = 3
    AnimationShowButton.Size = UDim2.new(0, 25, 0, 25)
    AnimationShowButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    AnimationShowButton.BackgroundTransparency = 0.3
    AnimationShowButton.Font = Enum.Font.SourceSansBold
    AnimationShowButton.Text = "😀"
    AnimationShowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AnimationShowButton.TextScaled = true
    AnimationShowButton.Visible = false
    AnimationShowButton.Parent = MiniToggleContainer
    local AnimationToggleCorner = Instance.new("UICorner", AnimationShowButton)
    AnimationToggleCorner.CornerRadius = UDim.new(0.5, 0)

    
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
    
    -- ## PERBAIKAN: TitleBar diubah menjadi TextButton untuk mencegah kamera bergerak saat digeser
    local TitleBar = Instance.new("TextButton")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TitleBar.BorderSizePixel = 0
    TitleBar.Text = ""
    TitleBar.AutoButtonColor = false
    TitleBar.Parent = MainFrame
    
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
    
    local VipTabContent = Instance.new("ScrollingFrame")
    VipTabContent.Name = "VipTab"
    VipTabContent.Size = UDim2.new(1, -10, 1, -10)
    VipTabContent.Position = UDim2.new(0, 5, 0, 5)
    VipTabContent.BackgroundTransparency = 1
    VipTabContent.Visible = false
    VipTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    VipTabContent.ScrollBarThickness = 10
    VipTabContent.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    VipTabContent.ScrollingDirection = Enum.ScrollingDirection.Y
    VipTabContent.Parent = ContentFrame

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
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
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
    
    local VipListLayout = Instance.new("UIListLayout")
    VipListLayout.Padding = UDim.new(0, 5)
    VipListLayout.Parent = VipTabContent

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
    setupCanvasSize(VipListLayout, VipTabContent)
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
    local saveFeatureStates -- Deklarasi awal agar bisa diakses
    local saveGuiPositions -- Deklarasi awal
    
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
    
    -- BARU: Fungsi untuk menyimpan dan memuat posisi GUI
    saveGuiPositions = function()
        if not writefile then
            -- showNotification("Executor tidak mendukung penyimpanan file.", Color3.fromRGB(200, 50, 50))
            return
        end
    
        local positionsToSave = {}
    
        -- Helper untuk mendapatkan data posisi dari objek GUI
        local function getPositionData(guiObject)
            if guiObject and guiObject.Parent then
                return {
                    XScale = guiObject.Position.X.Scale,
                    XOffset = guiObject.Position.X.Offset,
                    YScale = guiObject.Position.Y.Scale,
                    YOffset = guiObject.Position.Y.Offset,
                }
            end
            return nil
        end
    
        positionsToSave.MainFrame = getPositionData(MainFrame)
        positionsToSave.MiniToggleContainer = getPositionData(MiniToggleContainer)
        if EmoteScreenGui then
            positionsToSave.EmoteFrame = getPositionData(EmoteScreenGui:FindFirstChild("MainFrame"))
        end
        if AnimationScreenGui then
            positionsToSave.Animationframe = getPositionData(AnimationScreenGui:FindFirstChild("GazeBro"))
        end
        if touchFlingGui then
             positionsToSave.FlingFrame = getPositionData(touchFlingGui:FindFirstChild("Frame"))
        end
    
        local success, result = pcall(function()
            local jsonData = HttpService:JSONEncode(positionsToSave)
            writefile(GUI_POSITIONS_SAVE_FILE, jsonData)
        end)
    
        if success then
            -- showNotification("Posisi UI berhasil disimpan!", Color3.fromRGB(50, 200, 50))
        else
            warn("Gagal menyimpan posisi GUI:", result)
            -- showNotification("Gagal menyimpan posisi UI.", Color3.fromRGB(200, 50, 50))
        end
    end
    
    local function loadGuiPositions()
        if not readfile or not isfile or not isfile(GUI_POSITIONS_SAVE_FILE) then
            return
        end
    
        local success, result = pcall(function()
            local fileContent = readfile(GUI_POSITIONS_SAVE_FILE)
            loadedGuiPositions = HttpService:JSONDecode(fileContent)
    
            -- Helper untuk menerapkan posisi
            local function applyPosition(guiObject, posData)
                if guiObject and guiObject.Parent and posData then
                    guiObject.Position = UDim2.new(posData.XScale, posData.XOffset, posData.YScale, posData.YOffset)
                end
            end
    
            applyPosition(MainFrame, loadedGuiPositions.MainFrame)
            applyPosition(MiniToggleContainer, loadedGuiPositions.MiniToggleContainer)
        end)
        
        if not success then
            warn("Gagal memuat posisi GUI:", result)
            loadedGuiPositions = nil -- Reset jika gagal
        end
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
    
    -- ## PERBAIKAN ANIMASI: Fungsi untuk memuat animasi dari file
    local function loadAnimations()
        if isfile and isfile(ANIMATION_SAVE_FILE) and readfile then
            local success, data = pcall(function() return HttpService:JSONDecode(readfile(ANIMATION_SAVE_FILE)) end)
            if success and type(data) == "table" then
                lastAnimations = data
            end
        end
    end

    -- [[ PERBAIKAN HOP SERVER ]] --
    saveFeatureStates = function()
        if not writefile then return end
        
        local statesToSave = {
            WalkSpeed = IsWalkSpeedEnabled,
            Fly = IsFlying,
            Noclip = IsNoclipEnabled,
            InfinityJump = IsInfinityJumpEnabled,
            GodMode = IsGodModeEnabled,
            AntiFling = antifling_enabled,
            AntiLag = IsAntiLagEnabled,
            Invisible = IsInvisibilityEnabled,
            KillAura = IsKillAuraEnabled,
            Aimbot = IsAimbotEnabled,
            -- Simpan juga nilai slider
            WalkSpeedValue = Settings.WalkSpeed,
            FlySpeedValue = Settings.FlySpeed,
            KillAuraRadiusValue = Settings.KillAuraRadius,
            KillAuraDamageValue = Settings.KillAuraDamage,
            AimbotFOVValue = Settings.AimbotFOV
        }
        
        pcall(function()
            writefile(FEATURE_STATES_SAVE_FILE, HttpService:JSONEncode(statesToSave))
        end)
    end
    
    local function loadFeatureStates()
        if not readfile or not isfile or not isfile(FEATURE_STATES_SAVE_FILE) then return end
        
        local success, result = pcall(function()
            local fileContent = readfile(FEATURE_STATES_SAVE_FILE)
            local decodedData = HttpService:JSONDecode(fileContent)
            
            if type(decodedData) == "table" then
                IsWalkSpeedEnabled = decodedData.WalkSpeed or false
                IsFlying = decodedData.Fly or false
                IsNoclipEnabled = decodedData.Noclip or false
                IsInfinityJumpEnabled = decodedData.InfinityJump or false
                IsGodModeEnabled = decodedData.GodMode or false
                antifling_enabled = decodedData.AntiFling or false
                IsAntiLagEnabled = decodedData.AntiLag or false
                IsInvisibilityEnabled = decodedData.Invisible or false
                IsKillAuraEnabled = decodedData.KillAura or false
                IsAimbotEnabled = decodedData.Aimbot or false
                
                -- Muat juga nilai slider
                Settings.WalkSpeed = decodedData.WalkSpeedValue or 16
                Settings.FlySpeed = decodedData.FlySpeedValue or 1
                Settings.KillAuraRadius = decodedData.KillAuraRadiusValue or 25
                Settings.KillAuraDamage = decodedData.KillAuraDamageValue or 10
                Settings.AimbotFOV = decodedData.AimbotFOVValue or 90
            end
        end)
        if not success then
            warn("Gagal memuat status fitur:", result)
        end
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
        PlayerTabContent.Visible = (tabName == "Player"); GeneralTabContent.Visible = (tabName == "Umum"); CombatTabContent.Visible = (tabName == "Tempur"); TeleportTabContent.Visible = (tabName == "Teleport"); VipTabContent.Visible = (tabName == "VIP"); SettingsTabContent.Visible = (tabName == "Pengaturan")
        if tabName == "Player" and updatePlayerList then updatePlayerList() end
    end
    
    local function createTabButton(name, parent)
        local button = Instance.new("TextButton"); button.Size = UDim2.new(1, 0, 0, 25); button.BackgroundColor3 = Color3.fromRGB(30, 30, 30); button.BorderSizePixel = 0; button.Text = name; button.TextColor3 = Color3.fromRGB(255, 255, 255); button.TextSize = 12; button.Font = Enum.Font.SourceSansSemibold; button.Parent = parent; local btnCorner = Instance.new("UICorner", button); btnCorner.CornerRadius = UDim.new(0, 5); button.MouseButton1Click:Connect(function() switchTab(name) end); return button
    end
    
    local PlayerTabButton = createTabButton("Player", TabsFrame)
    local GeneralTabButton = createTabButton("Umum", TabsFrame)
    local CombatTabButton = createTabButton("Tempur", TabsFrame)
    local TeleportTabButton = createTabButton("Teleport", TabsFrame)
    local VipTabButton = createTabButton("VIP", TabsFrame)
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

    -- ## PERBAIKAN: Fungsi geser yang disempurnakan
    local function MakeDraggable(guiObject, dragHandle, isDraggableCheck, clickCallback)
        dragHandle.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end -- Abaikan jika input sudah diproses oleh elemen lain
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local isDragging = false
                local dragStartMousePos = input.Position
                local startObjectPos = guiObject.Position
                local inputChangedConnection
                local inputEndedConnection
                local DRAG_THRESHOLD = 5

                inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInput)
                    if changedInput.UserInputType == input.UserInputType then
                        local delta = changedInput.Position - dragStartMousePos
                        if not isDragging and delta.Magnitude > DRAG_THRESHOLD then
                            if isDraggableCheck and isDraggableCheck() then
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
                        if not isDragging and clickCallback then
                            clickCallback()
                        end
                     end
                end)
            end
        end)
    end
    
    -- ====================================================================
    -- == BAGIAN FUNGSI EMOTE ASLI (DIKEMBALIKAN)                      ==
    -- ====================================================================
    local applyEmoteTransparency -- Deklarasi awal

    local function destroyEmoteGUI()
        if EmoteScreenGui and EmoteScreenGui.Parent then
            EmoteScreenGui:Destroy()
        end
        EmoteScreenGui = nil
    end

    local function initializeEmoteGUI()
        destroyEmoteGUI()

        local EmoteList = {}
        local currentTrack = nil
        local currentAnimId = nil

        local TempEmoteGui = Instance.new("ScreenGui")
        TempEmoteGui.Name = "EmoteGuiRevised"
        TempEmoteGui.Parent = CoreGui
        TempEmoteGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        EmoteScreenGui = TempEmoteGui

        local EmoteMainFrame = Instance.new("Frame")
        EmoteMainFrame.Name = "MainFrame"
        EmoteMainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        EmoteMainFrame.Size = UDim2.new(0, 180, 0, 200)
        -- Atur posisi default, lalu terapkan posisi yang disimpan jika ada
        EmoteMainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        if loadedGuiPositions and loadedGuiPositions.EmoteFrame then
            local posData = loadedGuiPositions.EmoteFrame
            pcall(function() EmoteMainFrame.Position = UDim2.new(posData.XScale, posData.XOffset, posData.YScale, posData.YOffset) end)
        end
        EmoteMainFrame.BackgroundColor3 = Color3.fromRGB(28, 43, 70)
        EmoteMainFrame.BorderColor3 = Color3.fromRGB(90, 150, 255)
        EmoteMainFrame.BorderSizePixel = 1
        EmoteMainFrame.ClipsDescendants = true
        EmoteMainFrame.Parent = TempEmoteGui
        EmoteMainFrame.Visible = false 

        local UICorner = Instance.new("UICorner", EmoteMainFrame)
        UICorner.CornerRadius = UDim.new(0, 8)

        local Header = Instance.new("TextButton") 
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 30)
        Header.BackgroundColor3 = Color3.fromRGB(48, 63, 90)
        Header.BorderSizePixel = 0
        Header.Text = "" 
        Header.AutoButtonColor = false 
        Header.Parent = EmoteMainFrame

        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Size = UDim2.new(1, -40, 1, 0)
        Title.Position = UDim2.new(0, 10, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Enum.Font.GothamBold
        Title.Text = "Arexans Emotes [VIP]"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Header

        local CloseButton = Instance.new("TextButton")
        CloseButton.Name = "CloseButton"
        CloseButton.Size = UDim2.new(0, 20, 0, 20)
        CloseButton.Position = UDim2.new(1, -15, 0.5, 0)
        CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
        CloseButton.BackgroundTransparency = 1
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.Text = "X"
        CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseButton.TextSize = 18
        CloseButton.Parent = Header
        CloseButton.MouseButton1Click:Connect(function() 
            EmoteMainFrame.Visible = false
            EmoteToggleButton.Visible = true 
        end)
        
        MakeDraggable(EmoteMainFrame, Header, function() return true end, nil)

        local SearchBox = Instance.new("TextBox")
        SearchBox.Name = "SearchBox"
        SearchBox.Size = UDim2.new(1, -20, 0, 25)
        SearchBox.Position = UDim2.new(0, 10, 0, 35)
        SearchBox.BackgroundColor3 = Color3.fromRGB(48, 63, 90)
        SearchBox.PlaceholderText = "Cari emote..."
        SearchBox.PlaceholderColor3 = Color3.fromRGB(180, 190, 210)
        SearchBox.Font = Enum.Font.Gotham
        SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        SearchBox.ClearTextOnFocus = false
        SearchBox.Parent = EmoteMainFrame
        local SearchCorner = Instance.new("UICorner", SearchBox); SearchCorner.CornerRadius = UDim.new(0, 6)
        local SearchPadding = Instance.new("UIPadding", SearchBox); SearchPadding.PaddingLeft = UDim.new(0, 10); SearchPadding.PaddingRight = UDim.new(0, 10)

        local EmoteArea = Instance.new("ScrollingFrame")
        EmoteArea.Name = "EmoteArea"
        EmoteArea.Size = UDim2.new(1, 0, 1, -70)
        EmoteArea.Position = UDim2.new(0, 0, 0, 65)
        EmoteArea.BackgroundTransparency = 1
        EmoteArea.BorderSizePixel = 0
        EmoteArea.ScrollBarImageColor3 = Color3.fromRGB(90, 150, 255)
        EmoteArea.ScrollBarThickness = 5
        EmoteArea.Parent = EmoteMainFrame
        local UIPadding = Instance.new("UIPadding", EmoteArea); UIPadding.PaddingLeft = UDim.new(0, 10); UIPadding.PaddingRight = UDim.new(0, 10); UIPadding.PaddingTop = UDim.new(0, 5); UIPadding.PaddingBottom = UDim.new(0, 10)

        local UIGridLayout = Instance.new("UIGridLayout")
        UIGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        UIGridLayout.CellSize = UDim2.new(0, 36, 0, 50)
        UIGridLayout.SortOrder = Enum.SortOrder.Name
        UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIGridLayout.Parent = EmoteArea

        local function updateCanvasSize()
            task.wait()
            local contentHeight = UIGridLayout.AbsoluteContentSize.Y
            EmoteArea.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        end

        local function toggleAnimation(animId)
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Humanoid") then return end
            local humanoid = char.Humanoid
            if currentTrack and currentAnimId == animId then
                currentTrack:Stop(0.2); currentTrack = nil; currentAnimId = nil; return
            end
            if currentTrack then currentTrack:Stop(0.2) end
            local anim = Instance.new("Animation"); anim.AnimationId = animId
            local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
            if animator then
                local track = animator:LoadAnimation(anim)
                track:Play(0.1); currentTrack = track; currentAnimId = animId
                track.Stopped:Once(function() if currentTrack == track then currentTrack = nil; currentAnimId = nil end end)
            end
            anim:Destroy()
        end

        local function createEmoteButton(emoteData)
            local button = Instance.new("ImageButton"); button.Name = emoteData.name; button.BackgroundColor3 = Color3.fromRGB(48, 63, 90); button.Size = UDim2.new(0, 36, 0, 50); button.Parent = EmoteArea
            local corner = Instance.new("UICorner", button); corner.CornerRadius = UDim.new(0, 6)
            local image = Instance.new("ImageLabel", button); image.Size = UDim2.new(1, -4, 0, 32); image.Position = UDim2.new(0.5, 0, 0, 3); image.AnchorPoint = Vector2.new(0.5, 0); image.BackgroundTransparency = 1; image.Image = "rbxthumb://type=Asset&id=" .. tostring(emoteData.id) .. "&w=420&h=420"
            local nameLabel = Instance.new("TextLabel", button); nameLabel.Size = UDim2.new(1, -4, 0, 12); nameLabel.Position = UDim2.new(0, 2, 0, 36); nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.Gotham; nameLabel.Text = emoteData.name; nameLabel.TextScaled = true; nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.MouseButton1Click:Connect(function() toggleAnimation(emoteData.animationid) end)
            return button
        end

        local function populateEmotes(filter)
            filter = filter and filter:lower() or ""
            EmoteArea.CanvasPosition = Vector2.zero
            for _, button in pairs(EmoteArea:GetChildren()) do
                if button:IsA("ImageButton") then button.Visible = (filter == "" or button.Name:lower():find(filter, 1, true)) end
            end
            updateCanvasSize()
        end

        task.spawn(function()
            local success, result = pcall(function() return HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/AREXANS/emoteff/main/emote.json")) end)
            if success and type(result) == "table" then
                EmoteList = result; local existingEmotes = {}
                for _, emote in pairs(EmoteList) do
                    if emote.name and emote.animationid and emote.id and not existingEmotes[emote.name:lower()] then
                        createEmoteButton(emote); existingEmotes[emote.name:lower()] = true
                    end
                end
            else
                warn("Gagal mengambil daftar emote:", result); createEmoteButton({id = 14353423348, animationid = "rbxassetid://14352343065", name = "Bouncy"})
            end
            updateCanvasSize()
            if applyEmoteTransparency then applyEmoteTransparency(isEmoteTransparent) end
        end)

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function() populateEmotes(SearchBox.Text) end)
        
        if applyEmoteTransparency then
            applyEmoteTransparency(isEmoteTransparent)
        end
    end

    applyEmoteTransparency = function(isTransparent)
        if not EmoteScreenGui then return end
        local mainFrame = EmoteScreenGui:FindFirstChild("MainFrame", true)
        if not mainFrame then return end

        local header = mainFrame:FindFirstChild("Header")
        local searchBox = mainFrame:FindFirstChild("SearchBox")
        
        local transValue = 0.85
        local opaqueValue = 0
        
        mainFrame.BackgroundTransparency = isTransparent and transValue or opaqueValue
        EmoteToggleButton.BackgroundTransparency = isTransparent and transValue or 0
        if header then header.BackgroundTransparency = isTransparent and transValue or opaqueValue end
        if searchBox then searchBox.BackgroundTransparency = isTransparent and transValue or opaqueValue end

        local emoteArea = mainFrame:FindFirstChild("EmoteArea")
        if emoteArea then
            for _, button in ipairs(emoteArea:GetChildren()) do
                if button:IsA("ImageButton") then
                    button.BackgroundTransparency = isTransparent and transValue or opaqueValue
                end
            end
        end
    end
    
    -- ====================================================================
    -- == BAGIAN FUNGSI ANIMASI (INTEGRASI DARI animation.lua)         ==
    -- ====================================================================
    local applyAnimationTransparency -- Deklarasi awal

    local function destroyAnimationGUI()
        if AnimationScreenGui and AnimationScreenGui.Parent then
            AnimationScreenGui:Destroy()
        end
        AnimationScreenGui = nil
    end

    local function initializeAnimationGUI()
        destroyAnimationGUI()

        pcall(function()
            local GazeGoGui = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

            local guiName = "GazeVerificator"
            if GazeGoGui:FindFirstChild(guiName) then return end

            AnimationScreenGui = Instance.new("ScreenGui")
            AnimationScreenGui.Name = guiName
            AnimationScreenGui.Parent = GazeGoGui

            local camera = workspace.CurrentCamera
            local function getScaledSize(relativeWidth, relativeHeight)
                local viewportSize = camera.ViewportSize
                return UDim2.new(0, viewportSize.X * relativeWidth, 0, viewportSize.Y * relativeHeight)
            end
            
            -- ## PERBAIKAN: Jendela animasi sekarang menjadi Frame biasa, bukan TextButton
            local frame = Instance.new("Frame")
            frame.Name = "GazeBro"
            frame.Size = getScaledSize(0.18, 0.28) 
            -- Atur posisi default, lalu terapkan posisi yang disimpan jika ada
            frame.Position = UDim2.new(0.5, -frame.Size.X.Offset / 2, 0.5, -frame.Size.Y.Offset / 2)
            if loadedGuiPositions and loadedGuiPositions.Animationframe then
                local posData = loadedGuiPositions.Animationframe
                pcall(function() frame.Position = UDim2.new(posData.XScale, posData.XOffset, posData.YScale, posData.YOffset) end)
            end
            frame.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 2
            frame.BorderColor3 = Color3.fromRGB(0, 120, 255)
            frame.Visible = false 
            frame.Parent = AnimationScreenGui

            -- ## PERBAIKAN: Header ditambahkan untuk menjadi handle geser
            local animHeader = Instance.new("TextButton", frame)
            animHeader.Name = "AnimHeader"
            animHeader.Text = ""
            animHeader.Size = UDim2.new(1,0,0.1,0)
            animHeader.Position = UDim2.new(0,0,0,0)
            animHeader.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
            animHeader.BorderSizePixel = 0
            animHeader.AutoButtonColor = false
            -- Terapkan fungsi geser ke header ini
            MakeDraggable(frame, animHeader, function() return true end, nil)


            local labelSize = UDim2.new(1, 0, 1, 0)
            local gazeLabel = Instance.new("TextLabel", animHeader)
            gazeLabel.Name = "GazeLabel"
            gazeLabel.Text = "Arexans Anim [VIP]"
            gazeLabel.Font = Enum.Font.SourceSansBold
            gazeLabel.TextScaled = true
            gazeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            gazeLabel.BackgroundTransparency = 1
            gazeLabel.Size = labelSize
            gazeLabel.Position = UDim2.new(0, 0, 0, 0)

            local hideButton = Instance.new("TextButton", animHeader)
            hideButton.Name = "HideButton"
            hideButton.Text = "😑"
            hideButton.Font = Enum.Font.SourceSansBold
            hideButton.TextScaled = true
            hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            hideButton.BackgroundTransparency = 1
            hideButton.BorderSizePixel = 0
            hideButton.Size = UDim2.new(0.1, 0, 1, 0)
            hideButton.Position = UDim2.new(0.9, 0, 0, 0)
            hideButton.MouseButton1Click:Connect(function()
                frame.Visible = false
                AnimationShowButton.Visible = true
            end)

            local searchBar = Instance.new("TextBox", frame)
            searchBar.Name = "SearchBar"
            searchBar.PlaceholderText = "Search..."
            searchBar.Font = Enum.Font.SourceSans
            searchBar.TextScaled = true
            searchBar.TextColor3 = Color3.fromRGB(200, 200, 200)
            searchBar.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            searchBar.BorderSizePixel = 0
            searchBar.Size = UDim2.new(0.9, 0, 0.1, 0)
            searchBar.Position = UDim2.new(0.05, 0, 0.12, 0)
            searchBar.ClearTextOnFocus = true

            local scrollFrame = Instance.new("ScrollingFrame", frame)
            scrollFrame.Name = "ScrollFrame"
            scrollFrame.Size = UDim2.new(0.9, 0, 0.75, 0)
            scrollFrame.Position = UDim2.new(0.05, 0, 0.23, 0)
            scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            scrollFrame.BorderSizePixel = 0
            scrollFrame.ScrollBarThickness = 6
            scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)

            local resizeHandle = Instance.new("TextButton", frame)
            resizeHandle.Name = "ResizeHandle"
            resizeHandle.Text = ""
            resizeHandle.Size = UDim2.new(0, 15, 0, 15)
            resizeHandle.Position = UDim2.new(1, -15, 1, -15)
            resizeHandle.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            resizeHandle.BackgroundTransparency = 0.5
            resizeHandle.BorderSizePixel = 0
            resizeHandle.ZIndex = 2
            
            -- [[ PERBAIKAN DELAY ]]
            -- Memindahkan semua proses pembuatan tombol dan logika animasi ke thread baru
            -- agar tidak memblokir UI utama. Ini akan membuat ikon muncul seketika.
            task.spawn(function()
                local buttons = {}
                local function createTheButton(text, callback)
                    local button = Instance.new("TextButton", scrollFrame)
                    button.Text = text
                    button.Font = Enum.Font.SourceSans
                    button.TextScaled = false 
                    button.TextSize = 10 
                    button.TextColor3 = Color3.fromRGB(255, 255, 255)
                    button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                    button.Size = UDim2.new(1, 0, 0, 25) 
                    button.Position = UDim2.new(1, 0, 0, #buttons * 30) 
                    button.BackgroundTransparency = 1
                    button.BorderSizePixel = 0
                    button.MouseButton1Click:Connect(callback)
                    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local targetTransparency = isAnimationTransparent and 0.85 or 0.3
                    local goal = {Position = UDim2.new(0, 0, 0, #buttons * 30), BackgroundTransparency = targetTransparency} 
                    TweenService:Create(button, tweenInfo, goal):Play()
                    table.insert(buttons, button)
                    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buttons * 30)
                end

                searchBar:GetPropertyChangedSignal("Text"):Connect(function()
                    local searchText = searchBar.Text:lower()
                    local order = 0
                    for _, button in ipairs(buttons) do
                        if searchText == "" or button.Text:lower():find(searchText) then
                            button.Visible = true
                            button.Position = UDim2.new(0, 0, 0, order * 30) 
                            order = order + 1
                        else
                            button.Visible = false
                        end
                    end
                    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, order * 30)
                end)
                
                local isResizing = false
                local initialMousePosition, initialFrameSize
                resizeHandle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isResizing = true; initialMousePosition = UserInputService:GetMouseLocation(); initialFrameSize = frame.AbsoluteSize; end end)
                UserInputService.InputChanged:Connect(function(input) if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = UserInputService:GetMouseLocation() - initialMousePosition; local newSizeX = math.max(100, initialFrameSize.X + delta.X); local newSizeY = math.max(100, initialFrameSize.Y + delta.Y); frame.Size = UDim2.new(0, newSizeX, 0, newSizeY); frame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset) end end)
                UserInputService.InputEnded:Connect(function(input) if isResizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then isResizing = false; end end)
                
                local speaker = Players.LocalPlayer

                local function StopAnim()
                    local char = speaker.Character; if not char then return end
                    local Hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController"); if not Hum then return end
                    for _, v in next, Hum:GetPlayingAnimationTracks() do v:Stop() end
                end

                local function refresh()
                    local char = speaker.Character; if not char then return end
                    local humanoid = char:WaitForChild("Humanoid"); if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
                end

                local function refreshswim()
                    local char = speaker.Character; if not char then return end
                    local humanoid = char:WaitForChild("Humanoid"); if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp); task.wait(0.1); humanoid:ChangeState(Enum.HumanoidStateType.Swimming) end
                end

                local function refreshclimb()
                    local char = speaker.Character; if not char then return end
                    local humanoid = char:WaitForChild("Humanoid"); if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp); task.wait(0.1); humanoid:ChangeState(Enum.HumanoidStateType.Climbing) end
                end

                local Animations = {
                    Idle={["2016 Animation (mm2)"]={"387947158","387947464"},["Oh Really?"]={"98004748982532","98004748982532"},Astronaut={"891621366","891633237"},["Adidas Community"]={"122257458498464","102357151005774"},Bold={"16738333868","16738334710"},Sans={"123627677663418","123627677663418"},Sans2={"113203077347750","113203077347750"},Magician={"139433213852503","139433213852503"},["John Doe"]={"72526127498800","72526127498800"},Noli={"139360856809483","139360856809483"},Coolkid={"95203125292023","95203125292023"},["Survivor Injured"]={"73905365652295","73905365652295"},["1x1x1x1"]={"76780522821306","76780522821306"},Borock={"3293641938","3293642554"},Kaneki={"133277876379233","133277876379233"},Bubbly={"910004836","910009958"},Cartoony={"742637544","742638445"},Confident={"1069977950","1069987858"},["Catwalk Glam"]={"133806214992291","94970088341563"},Cowboy={"1014390418","1014398616"},["Drooling Zombie"]={"3489171152","3489171152"},Elder={"10921101664","10921102574"},Ghost={"616006778","616008087"},Knight={"657595757","657568135"},Levitation={"616006778","616008087"},Mage={"707742142","707855907"},MrToilet={"4417977954","4417978624"},Ninja={"656117400","656118341"},NFL={"92080889861410","74451233229259"},OldSchool={"10921230744","10921232093"},Patrol={"1149612882","1150842221"},Pirate={"750781874","750782770"},["Default Retarget"]={"95884606664820","95884606664820"},["Very Long"]={"18307781743","18307781743"},Sway={"560832030","560833564"},Popstar={"1212900985","1150842221"},Princess={"941003647","941013098"},R6={"12521158637","12521162526"},["R15 Reanimated"]={"4211217646","4211218409"},Realistic={"17172918855","17173014241"},Robot={"616088211","616089559"},Sneaky={"1132473842","1132477671"},["Sports (Adidas)"]={"18537376492","18537371272"},Soldier={"3972151362","3972151362"},Stylish={"616136790","616138447"},["Stylized Female"]={"4708191566","4708192150"},Superhero={"10921288909","10921290167"},Toy={"782841498","782845736"},Udzal={"3303162274","3303162549"},Vampire={"1083445855","1083450166"},Werewolf={"1083195517","1083214717"},["Wicked (Popular)"]={"118832222982049","76049494037641"},["No Boundaries (Walmart)"]={"18747067405","18747063918"},Zombie={"616158929","616160636"}},
                    Walk={Gojo="95643163365384",Geto="85811471336028",Astronaut="891667138",["Adidas Community"]="122150855457006",Bold="16738340646",Bubbly="910034870",Smooth="76630051272791",Cartoony="742640026",Confident="1070017263",Cowboy="1014421541",["Catwalk Glam"]="109168724482748",["Drooling Zombie"]="3489174223",Elder="10921111375",Ghost="616013216",Knight="10921127095",Levitation="616013216",Mage="707897309",Ninja="656121766",NFL="110358958299415",OldSchool="10921244891",Patrol="1151231493",Pirate="750785693",["Default Retarget"]="115825677624788",Popstar="1212980338",Princess="941028902",R6="12518152696",["R15 Reanimated"]="4211223236",["2016 Animation (mm2)"]="387947975",Robot="616095330",Sneaky="1132510133",["Sports (Adidas)"]="18537392113",Stylish="616146177",["Stylized Female"]="4708193840",Superhero="10921298616",Toy="782843345",Udzal="3303162967",Vampire="1083473930",Werewolf="1083178339",["Wicked (Popular)"]="92072849924640",["No Boundaries (Walmart)"]="18747074203",Zombie="616168032"},
                    Run={["2016 Animation (mm2)"]="387947975",Soccer="116881956670910",["Adidas Community"]="82598234841035",Astronaut="10921039308",Naruto="104074120169874",Bold="16738337225",Bubbly="10921057244",Cartoony="10921076136",Dog="130072963359721",Confident="1070001516",Lagging="71095688469567",Cowboy="1014401683",["Catwalk Glam"]="81024476153754",["Drooling Zombie"]="3489173414",Elder="10921104374",Ghost="616013216",["Heavy Run (Udzal / Borock)"]="3236836670",Knight="10921121197",Levitation="616010382",Mage="10921148209",MrToilet="4417979645",Ninja="656118852",NFL="117333533048078",OldSchool="10921240218",Patrol="1150967949",Pirate="750783738",["Default Retarget"]="102294264237491",Popstar="1212980348",Princess="941015281",R6="12518152696",["R15 Reanimated"]="4211220381",Robot="10921250460",Sneaky="1132494274",["Sports (Adidas)"]="18537384940",Stylish="10921276116",["Stylized Female"]="4708192705",Superhero="10921291831",Toy="10921306285",Vampire="10921320299",Werewolf="10921336997",["Wicked (Popular)"]="72301599441680",["No Boundaries (Walmart)"]="18747070484",Zombie="616163682"},
                    Jump={Astronaut="891627522",["Adidas Community"]="656117878",Bold="16738336650",Bubbly="910016857",Cartoony="742637942",["Catwalk Glam"]="116936326516985",Confident="1069984524",Cowboy="1014394726",Elder="10921107367",Ghost="616008936",Knight="910016857",Levitation="616008936",Mage="10921149743",Ninja="656117878",NFL="119846112151352",OldSchool="10921242013",Patrol="1148811837",Pirate="750782230",["Default Retarget"]="117150377950987",Popstar="1212954642",Princess="941008832",Robot="616090535",["R15 Reanimated"]="4211219390",R6="12520880485",Sneaky="1132489853",["Sports (Adidas)"]="18537380791",Stylish="616139451",["Stylized Female"]="4708188025",Superhero="10921294559",Toy="10921308158",Vampire="1083455352",Werewolf="1083218792",["Wicked (Popular)"]="104325245285198",["No Boundaries (Walmart)"]="18747069148",Zombie="616161997"},
                    Fall={Astronaut="891617961",["Adidas Community"]="98600215928904",Bold="16738333171",Bubbly="910001910",Cartoony="742637151",["Catwalk Glam"]="92294537340807",Confident="1069973677",Cowboy="1014384571",Elder="10921105765",Knight="10921122579",Levitation="616005863",Mage="707829716",Ninja="656115606",NFL="129773241321032",OldSchool="10921241244",Patrol="1148863382",Pirate="750780242",["Default Retarget"]="110205622518029",Popstar="1212900995",Princess="941000007",Robot="616087089",["R15 Reanimated"]="4211216152",R6="12520972571",Sneaky="1132469004",["Sports (Adidas)"]="18537367238",Stylish="616134815",["Stylized Female"]="4708186162",Superhero="10921293373",Toy="782846423",Vampire="1083443587",Werewolf="1083189019",["Wicked (Popular)"]="121152442762481",["No Boundaries (Walmart)"]="18747062535",Zombie="616157476"},
                    SwimIdle={Astronaut="891663592",["Adidas Community"]="109346520324160",Bold="16738339817",Bubbly="910030921",Cartoony="10921079380",["Catwalk Glam"]="98854111361360",Confident="1070012133",CowBoy="1014411816",Elder="10921110146",Mage="707894699",Ninja="656118341",NFL="79090109939093",Patrol="1151221899",Knight="10921125935",OldSchool="10921244018",Levitation="10921139478",Popstar="1212998578",Princess="941025398",Pirate="750785176",R6="12518152696",Robot="10921253767",Sneaky="1132506407",["Sports (Adidas)"]="18537387180",Stylish="10921281964",Stylized="4708190607",SuperHero="10921297391",Toy="10921310341",Vampire="10921325443",Werewolf="10921341319",["Wicked (Popular)"]="113199415118199",["No Boundaries (Walmart)"]="18747071682"},
                    Swim={Astronaut="891663592",["Adidas Community"]="133308483266208",Bubbly="910028158",Bold="16738339158",Cartoony="10921079380",["Catwalk Glam"]="134591743181628",CowBoy="1014406523",Confident="1070009914",Elder="10921108971",Knight="10921125160",Mage="707876443",NFL="132697394189921",OldSchool="10921243048",PopStar="1212998578",Princess="941018893",Pirate="750784579",Patrol="1151204998",R6="12518152696",Robot="10921253142",Levitation="10921138209",Stylish="10921281000",SuperHero="10921295495",Sneaky="1132500520",["Sports (Adidas)"]="18537389531",Toy="10921309319",Vampire="10921324408",Werewolf="10921340419",["Wicked (Popular)"]="99384245425157",["No Boundaries (Walmart)"]="18747073181",Zombie="616165109"},
                    Climb={Astronaut="10921032124",["Adidas Community"]="88763136693023",Bold="16738332169",Cartoony="742636889",["Catwalk Glam"]="119377220967554",Confident="1069946257",CowBoy="1014380606",Elder="845392038",Ghost="616003713",Knight="10921125160",Levitation="10921132092",Mage="707826056",Ninja="656114359",NFL="134630013742019",OldSchool="10921229866",Patrol="1148811837",Popstar="1213044953",Princess="940996062",R6="12520982150",["Reanimated R15"]="4211214992",Robot="616086039",Sneaky="1132461372",["Sports (Adidas)"]="18537363391",Stylish="10921271391",["Stylized Female"]="4708184253",SuperHero="10921286911",Toy="10921300839",Vampire="1083439238",WereWolf="10921329322",["Wicked (Popular)"]="131326830509784",["No Boundaries (Walmart)"]="18747060903",Zombie="616156119"}}
                
                local function loadAnimation(animationId) local char = speaker.Character or speaker.CharacterAdded:Wait(); local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..tostring(animationId); return char:WaitForChild("Humanoid"):LoadAnimation(anim) end
                for _, sets in pairs(Animations) do for _, ids in pairs(sets) do if type(ids)=="table" then for _, id in ipairs(ids) do task.spawn(loadAnimation, id) end else task.spawn(loadAnimation, ids) end end end

                local function Buy(gamePassID)
                    pcall(function() game:GetService("MarketplaceService"):PromptGamePassPurchase(speaker, gamePassID) end)
                end

                local function ResetIdle() pcall(function() StopAnim(); local anim = speaker.Character.Animate; anim.idle.Animation1.AnimationId, anim.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0", "http://www.roblox.com/asset/?id=0" end) end
                local function ResetWalk() pcall(function() StopAnim(); speaker.Character.Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end) end
                local function ResetRun() pcall(function() StopAnim(); task.wait(0.1); speaker.Character.Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end) end
                local function ResetJump() pcall(function() StopAnim(); task.wait(0.1); speaker.Character.Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end) end
                local function ResetFall() pcall(function() StopAnim(); speaker.Character.Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end) end
                local function ResetSwim() pcall(function() StopAnim(); local anim = speaker.Character.Animate; if anim.swim then anim.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=0" end end) end
                local function ResetSwimIdle() pcall(function() StopAnim(); local anim = speaker.Character.Animate; if anim.swimidle then anim.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=0" end end) end
                local function ResetClimb() pcall(function() StopAnim(); speaker.Character.Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=0" end) end
                
                local function setAnimation(animationType, animationId)
                    -- ## PERBAIKAN ANIMASI: Fungsi untuk menyimpan animasi ke file global
                    local function saveLastAnimations() 
                        if writefile then 
                            pcall(function() 
                                local data = HttpService:JSONEncode(lastAnimations)
                                writefile(ANIMATION_SAVE_FILE, data) 
                            end) 
                        end 
                    end
                    local char = speaker.Character; if not char then return end
                    local Anim = char:FindFirstChild("Animate"); if not Anim then return end
                    local humanoid = char:WaitForChild("Humanoid"); humanoid.PlatformStand = true; task.wait(0.1)
                    
                    if animationType == "Idle" then lastAnimations.Idle = animationId; ResetIdle(); Anim.idle.Animation1.AnimationId, Anim.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id="..animationId[1], "http://www.roblox.com/asset/?id="..animationId[2]; refresh()
                    elseif animationType == "Walk" then lastAnimations.Walk = animationId; ResetWalk(); Anim.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refresh()
                    elseif animationType == "Run" then lastAnimations.Run = animationId; ResetRun(); Anim.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refresh()
                    elseif animationType == "Jump" then lastAnimations.Jump = animationId; ResetJump(); Anim.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refresh()
                    elseif animationType == "Fall" then lastAnimations.Fall = animationId; ResetFall(); Anim.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refresh()
                    elseif animationType == "Swim" and Anim.swim then lastAnimations.Swim = animationId; ResetSwim(); Anim.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refreshswim()
                    elseif animationType == "SwimIdle" and Anim.swimidle then lastAnimations.SwimIdle = animationId; ResetSwimIdle(); Anim.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refreshswim()
                    elseif animationType == "Climb" then lastAnimations.Climb = animationId; ResetClimb(); Anim.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id="..animationId; refreshclimb() end
                    saveLastAnimations(); task.wait(0.1); humanoid.PlatformStand = false
                end
                
                -- Hapus fungsi loadLastAnimations lokal, karena sudah ada di global
                
                local function PlayEmote(animationId) StopAnim(); local track = loadAnimation(animationId); track:Play(); local conn; conn = RunService.RenderStepped:Connect(function() if speaker.Character:WaitForChild("Humanoid").MoveDirection.Magnitude > 0 then track:Stop(); conn:Disconnect() end end) end
                local function ZeroPlayEmote(animationId) StopAnim(); local track = loadAnimation(animationId); track:Play(); track:AdjustSpeed(0); local conn; conn = RunService.RenderStepped:Connect(function() if speaker.Character:WaitForChild("Humanoid").MoveDirection.Magnitude > 0 then track:Stop(); conn:Disconnect() end end) end
                local function FPlayEmote(animationId) StopAnim(); local track = loadAnimation(animationId); track:Play(); task.delay(track.Length * 0.9, function() track:AdjustSpeed(0) end); local conn; conn = RunService.RenderStepped:Connect(function() if speaker.Character:WaitForChild("Humanoid").MoveDirection.Magnitude > 0 then track:Stop(); conn:Disconnect() end end) end
                
                local function AddEmote(name, id) createTheButton(name.." - Emote", function() PlayEmote(id) end) end
                local function ZeroAddEmote(name, id) createTheButton(name.." - Emote", function() ZeroPlayEmote(id) end) end
                local function AddFEmote(name, id) createTheButton(name.." - Emote", function() FPlayEmote(id) end) end
                local function AddDonate(Price, Id) createTheButton("Donate "..Price.." Robux", function() Buy(Id) end) end
                local function createAnimationButton(text, animType, animId) createTheButton(text.." - "..animType, function() setAnimation(animType, animId) end) end
                
                local function resetToAdidasSport()
                    local anims = Animations
                    if anims.Walk["Sports (Adidas)"] then setAnimation("Walk", anims.Walk["Sports (Adidas)"]) end
                    if anims.Run["Sports (Adidas)"] then setAnimation("Run", anims.Run["Sports (Adidas)"]) end
                    if anims.Jump["Sports (Adidas)"] then setAnimation("Jump", anims.Jump["Sports (Adidas)"]) end
                    if anims.Fall["Sports (Adidas)"] then setAnimation("Fall", anims.Fall["Sports (Adidas)"]) end
                    if anims.Swim["Sports (Adidas)"] then setAnimation("Swim", anims.Swim["Sports (Adidas)"]) end
                    if anims.SwimIdle["Sports (Adidas)"] then setAnimation("SwimIdle", anims.SwimIdle["Sports (Adidas)"]) end
                    if anims.Climb["Sports (Adidas)"] then setAnimation("Climb", anims.Climb["Sports (Adidas)"]) end
                end
                createTheButton("Reset to Adidas Sport", resetToAdidasSport)
                
                for name, ids in pairs(Animations.Idle) do task.wait(); createAnimationButton(name, "Idle", ids) end
                for name, id in pairs(Animations.Walk) do task.wait(); createAnimationButton(name, "Walk", id) end
                for name, id in pairs(Animations.Run) do task.wait(); createAnimationButton(name, "Run", id) end
                for name, id in pairs(Animations.Jump) do task.wait(); createAnimationButton(name, "Jump", id) end
                for name, id in pairs(Animations.Fall) do task.wait(); createAnimationButton(name, "Fall", id) end
                for name, id in pairs(Animations.SwimIdle) do task.wait(); createAnimationButton(name, "SwimIdle", id) end
                for name, id in pairs(Animations.Swim) do task.wait(); createAnimationButton(name, "Swim", id) end
                for name, id in pairs(Animations.Climb) do task.wait(); createAnimationButton(name, "Climb", id) end

                -- ## PERBAIKAN ANIMASI: Hapus CharacterAdded lokal, akan ditangani secara global
                -- speaker.CharacterAdded:Connect(...) DIHAPUS DARI SINI
                
                AddDonate(20, 1131371530); AddDonate(200, 1131065702); AddDonate(183, 1129915318); AddDonate(2000, 1128299749)
                AddEmote("Dance 1", 12521009666); AddEmote("Dance 2", 12521169800); AddEmote("Dance 3", 12521178362); AddEmote("Cheer", 12521021991); AddEmote("Laugh", 12521018724); AddEmote("Point", 12521007694); AddEmote("Wave", 12521004586)
                AddFEmote("Soldier - Assault Fire", 4713811763); AddEmote("Soldier - Assault Aim", 4713633512); AddEmote("Zombie - Attack", 3489169607); AddFEmote("Zombie - Death", 3716468774); AddEmote("Roblox - Sleep", 2695918332); AddEmote("Roblox - Quake", 2917204509); AddEmote("Roblox - Rifle Reload", 3972131105)
                ZeroAddEmote("Accurate T Pose", 2516930867)
            end)

            -- Tidak perlu load animasi di sini lagi
            
            if applyAnimationTransparency then
                applyAnimationTransparency(isAnimationTransparent)
            end
        end)
    end
    
    applyAnimationTransparency = function(isTransparent)
        if not AnimationScreenGui then return end
        local frame = AnimationScreenGui:FindFirstChild("GazeBro", true)
        
        local transValue = 0.85

        if frame then
            local searchBar = frame:FindFirstChild("SearchBar")
            local scrollFrame = frame:FindFirstChild("ScrollFrame")
            local resizeHandle = frame:FindFirstChild("ResizeHandle")
            
            frame.BackgroundTransparency = isTransparent and transValue or 0.2
            AnimationShowButton.BackgroundTransparency = isTransparent and transValue or 0.3
            if searchBar then searchBar.BackgroundTransparency = isTransparent and transValue or 0 end
            if scrollFrame then scrollFrame.BackgroundTransparency = isTransparent and transValue or 0 end
            if resizeHandle then resizeHandle.BackgroundTransparency = isTransparent and 0.9 or 0.5 end

            if scrollFrame then
                for _, button in ipairs(scrollFrame:GetChildren()) do
                    if button:IsA("TextButton") then
                        local targetTransparency = isTransparent and transValue or 0.3
                        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundTransparency = targetTransparency}):Play()
                    end
                end
            end
        end
    end
	
    -- ====================================================================
    -- == BAGIAN FITUR BARU: INVISIBLE (DARI KODE ANDA)                ==
    -- ====================================================================
    
    -- Variabel Global Khusus untuk Fitur Invisible
    local invisRunning = false
    local Character = nil
    local InvisibleCharacter = nil
    local IsInvis = false
    local IsRunning = true
    local invisFix = nil
    local invisDied = nil
    
    -- Deklarasi fungsi agar bisa dipanggil satu sama lain
    local TurnVisible 
    
    -- Fungsi untuk memperbaiki kamera setelah berganti karakter
    function fixcam(speaker)
        -- StopFreecam() -- Dihapus karena tidak relevan
        Workspace.CurrentCamera:Destroy()
        task.wait(.1)
        repeat task.wait() until speaker.Character ~= nil
        Workspace.CurrentCamera.CameraSubject = speaker.Character:FindFirstChildWhichIsA('Humanoid')
        Workspace.CurrentCamera.CameraType = "Custom"
        speaker.CameraMinZoomDistance = 0.5
        speaker.CameraMaxZoomDistance = 400
        speaker.CameraMode = "Classic"
        if speaker.Character and speaker.Character.Head then
            speaker.Character.Head.Anchored = false
        end
    end
    
    function makeInvisible()
        if invisRunning then return end
        invisRunning = true
        
        repeat task.wait(.1) until LocalPlayer.Character
        Character = LocalPlayer.Character
        Character.Archivable = true
        IsInvis = false
        IsRunning = true
        InvisibleCharacter = Character:Clone()
        InvisibleCharacter.Parent = game:GetService("Lighting")
        local Void = workspace.FallenPartsDestroyHeight
        InvisibleCharacter.Name = ""
        local CF
    
        local function Respawn()
            IsRunning = false
            if IsInvis == true then
                pcall(function()
                    -- Dapatkan posisi klon sebelum beralih kembali
                    local clonePosition = InvisibleCharacter.HumanoidRootPart.CFrame
                    
                    LocalPlayer.Character = Character
                    task.wait()
                    Character.Parent = workspace
                    
                    -- Pindahkan karakter asli ke tempat klon berada
                    Character.PrimaryPart.CFrame = clonePosition
                    
                    if Character:FindFirstChildWhichIsA('Humanoid') then
                        Character:FindFirstChildWhichIsA('Humanoid'):Destroy()
                    end
                    IsInvis = false
                    if InvisibleCharacter then
                        InvisibleCharacter:Destroy()
                    end
                    invisRunning = false
                end)
            elseif IsInvis == false then
                pcall(function()
                    LocalPlayer.Character = Character
                    task.wait()
                    Character.Parent = workspace
                    if Character:FindFirstChildWhichIsA('Humanoid') then
                        Character:FindFirstChildWhichIsA('Humanoid'):Destroy()
                    end
                    TurnVisible()
                end)
            end
        end
    
        invisFix = game:GetService("RunService").Stepped:Connect(function()
            pcall(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                local IsInteger
                if tostring(Void):find'-' then
                    IsInteger = true
                else
                    IsInteger = false
                end
                local Pos = LocalPlayer.Character.HumanoidRootPart.Position
                local Y = Pos.Y
                if IsInteger == true then
                    if Y <= Void then
                        Respawn()
                    end
                elseif IsInteger == false then
                    if Y >= Void then
                        Respawn()
                    end
                end
            end)
        end)
    
        for i,v in pairs(InvisibleCharacter:GetDescendants())do
            if v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" then
                    v.Transparency = 1
                else
                    v.Transparency = .5
                end
            end
        end
    
        invisDied = InvisibleCharacter:FindFirstChildOfClass('Humanoid').Died:Connect(function()
            Respawn()
            invisDied:Disconnect()
        end)
    
        if IsInvis == true then return end
        IsInvis = true
        CF = Workspace.CurrentCamera.CFrame
        local CF_1 = LocalPlayer.Character.HumanoidRootPart.CFrame
        
        -- [PERBAIKAN UTAMA] Mengganti MoveTo dengan SetPrimaryPartCFrame untuk teleportasi instan tanpa animasi.
        Character:SetPrimaryPartCFrame(CFrame.new(0, 1000000, 0))
        
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        task.wait(.2)
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        Character.Parent = game:GetService("Lighting")
        InvisibleCharacter.Parent = workspace
        InvisibleCharacter.HumanoidRootPart.CFrame = CF_1
        LocalPlayer.Character = InvisibleCharacter
        fixcam(LocalPlayer)
        LocalPlayer.Character.Animate.Disabled = true
        LocalPlayer.Character.Animate.Disabled = false
    
        showNotification('Invisible','Anda sekarang tidak terlihat oleh pemain lain', Color3.fromRGB(50, 200, 50))
    end
    
    TurnVisible = function()
        if IsInvis == false then return end
        if invisFix then
            invisFix:Disconnect()
            invisFix = nil
        end
        if invisDied then
            invisDied:Disconnect()
            invisDied = nil
        end

        local CF_1 = CFrame.new()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
             CF_1 = LocalPlayer.Character.HumanoidRootPart.CFrame
        end
       
        if InvisibleCharacter then
            InvisibleCharacter:Destroy()
            InvisibleCharacter = nil
        end

        LocalPlayer.Character = Character
        Character.Parent = workspace
        if Character:FindFirstChild("HumanoidRootPart") then
             Character.HumanoidRootPart.CFrame = CF_1
        end

        IsInvis = false
        LocalPlayer.Character.Animate.Disabled = true
        LocalPlayer.Character.Animate.Disabled = false
        
        pcall(function()
            invisDied = Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
                if invisDied then invisDied:Disconnect(); invisDied = nil end
            end)
        end)

        invisRunning = false
        showNotification('Visible','Anda sekarang terlihat oleh pemain lain', Color3.fromRGB(200, 150, 50))
    end

    -- ====================================================================
    -- == BAGIAN FUNGSI UTAMA (PLAYER, COMBAT, DLL)                      ==
    -- ====================================================================

    local function StartFly()
        if IsFlying then return end; local character = LocalPlayer.Character; if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then return end; local root = character:WaitForChild("HumanoidRootPart"); local humanoid = character:FindFirstChildOfClass("Humanoid"); IsFlying = true; saveFeatureStates(); humanoid.PlatformStand = true; local bodyGyro = Instance.new("BodyGyro", root); bodyGyro.Name = "FlyGyro"; bodyGyro.P = 9e4; bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bodyGyro.CFrame = root.CFrame; local bodyVelocity = Instance.new("BodyVelocity", root); bodyVelocity.Name = "FlyVelocity"; bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); bodyVelocity.Velocity = Vector3.new(0, 0, 0); local controls = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
        table.insert(FlyConnections, UserInputService.InputBegan:Connect(function(input, processed) if processed then return end; if input.UserInputType == Enum.UserInputType.Keyboard then local key = input.KeyCode.Name:lower(); if key == "w" then controls.F = Settings.FlySpeed elseif key == "s" then controls.B = -Settings.FlySpeed elseif key == "a" then controls.L = -Settings.FlySpeed elseif key == "d" then controls.R = Settings.FlySpeed elseif key == "e" then controls.Q = Settings.FlySpeed * 2 elseif key == "q" then controls.E = -Settings.FlySpeed * 2 end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Track end end))
        table.insert(FlyConnections, UserInputService.InputEnded:Connect(function(input, processed) if processed then return end; if input.UserInputType == Enum.UserInputType.Keyboard then local key = input.KeyCode.Name:lower(); if key == "w" then controls.F = 0 elseif key == "s" then controls.B = 0 elseif key == "a" then controls.L = 0 elseif key == "d" then controls.R = 0 elseif key == "e" then controls.Q = 0 elseif key == "q" then controls.E = 0 end end end))
        table.insert(FlyConnections, RunService.RenderStepped:Connect(function() if not IsFlying then return end; local speed = (controls.L + controls.R ~= 0 or controls.F + controls.B ~= 0 or controls.Q + controls.E ~= 0) and 50 or 0; local camera = Workspace.CurrentCamera; if speed ~= 0 then bodyVelocity.Velocity = ((camera.CFrame.LookVector * (controls.F + controls.B)) + ((camera.CFrame * CFrame.new(controls.L + controls.R, (controls.F + controls.B + controls.Q + controls.E) * 0.2, 0).Position) - camera.CFrame.Position)) * speed else bodyVelocity.Velocity = Vector3.new(0, 0, 0) end; bodyGyro.CFrame = camera.CFrame end))
    end

    local function StopFly()
        if not IsFlying then return end; IsFlying = false; saveFeatureStates(); local character = LocalPlayer.Character; if character and character:FindFirstChildOfClass("Humanoid") then character.Humanoid.PlatformStand = false end; for _, conn in pairs(FlyConnections) do conn:Disconnect() end; FlyConnections = {}; local root = character and character:FindFirstChild("HumanoidRootPart"); if root then if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end; if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end

    local function StopMobileFly()
        if not IsFlying then return end; IsFlying = false; saveFeatureStates(); local character = LocalPlayer.Character; if character and character:FindFirstChildOfClass("Humanoid") then character.Humanoid.PlatformStand = false end; for _, conn in pairs(FlyConnections) do conn:Disconnect() end; FlyConnections = {}; local root = character and character:FindFirstChild("HumanoidRootPart"); if root then if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end; if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end end; Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end

    local function StartMobileFly()
        if IsFlying then return end; local character = LocalPlayer.Character; if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then return end; local root = character:WaitForChild("HumanoidRootPart"); local humanoid = character:FindFirstChildOfClass("Humanoid"); local success, controlModule = pcall(require, LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule")); if not success then showNotification("Gagal memuat modul kontrol mobile.", Color3.fromRGB(255, 100, 100)); return end
        IsFlying = true; saveFeatureStates(); humanoid.PlatformStand = true; local bodyVelocity = Instance.new("BodyVelocity", root); bodyVelocity.Name = "FlyVelocity"; bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); bodyVelocity.Velocity = Vector3.new(0, 0, 0); local bodyGyro = Instance.new("BodyGyro", root); bodyGyro.Name = "FlyGyro"; bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bodyGyro.P = 1000; bodyGyro.D = 50
        table.insert(FlyConnections, RunService.RenderStepped:Connect(function() if not IsFlying then return end; local camera = Workspace.CurrentCamera; if not (character and root and root:FindFirstChild("FlyVelocity") and root:FindFirstChild("FlyGyro")) then StopMobileFly(); return end; root.FlyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9); root.FlyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); root.FlyGyro.CFrame = camera.CFrame; root.FlyVelocity.Velocity = Vector3.new(0, 0, 0); local direction = controlModule:GetMoveVector(); if direction.X ~= 0 then root.FlyVelocity.Velocity = root.FlyVelocity.Velocity + camera.CFrame.RightVector * (direction.X * (Settings.FlySpeed * 50)) end; if direction.Z ~= 0 then root.FlyVelocity.Velocity = root.FlyVelocity.Velocity - camera.CFrame.LookVector * (direction.Z * (Settings.FlySpeed * 50)) end end))
    end

    local function ToggleNoclip(enabled)
        IsNoclipEnabled = enabled
        saveFeatureStates()
        if enabled then task.spawn(function() while IsNoclipEnabled and LocalPlayer.Character do for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end; task.wait(0.1) end; if LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end end end) end
    end

    local function applyGodMode(character)
        if not character then return end; local humanoid = character:FindFirstChildOfClass("Humanoid"); if not humanoid then return end; if godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
        godModeConnection = humanoid.HealthChanged:Connect(function(newHealth) if newHealth <= 0 and IsGodModeEnabled then humanoid.Health = humanoid.MaxHealth end end)
    end

    local function ToggleGodMode(enabled)
        IsGodModeEnabled = enabled; saveFeatureStates(); if enabled then if LocalPlayer.Character then applyGodMode(LocalPlayer.Character) end elseif godModeConnection then godModeConnection:Disconnect(); godModeConnection = nil end
    end

    local function ToggleWalkSpeed(enabled)
        IsWalkSpeedEnabled = enabled; saveFeatureStates(); if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = enabled and Settings.WalkSpeed or OriginalWalkSpeed end
    end

    local function CreateTouchFlingGUI()
        if touchFlingGui and touchFlingGui.Parent then return end; local FlingScreenGui = Instance.new("ScreenGui"); FlingScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"); FlingScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; FlingScreenGui.ResetOnSpawn = false; touchFlingGui = FlingScreenGui
        local Frame = Instance.new("Frame", FlingScreenGui); Frame.BackgroundColor3 = Color3.fromRGB(170, 200, 255); Frame.BackgroundTransparency = 0.3; Frame.BorderSizePixel = 0; 
        -- Atur posisi default, lalu terapkan posisi yang disimpan jika ada
        Frame.Position = UDim2.new(0.5, -45, 0, 20); 
        if loadedGuiPositions and loadedGuiPositions.FlingFrame then
            local posData = loadedGuiPositions.FlingFrame
            pcall(function() Frame.Position = UDim2.new(posData.XScale, posData.XOffset, posData.YScale, posData.YOffset) end)
        end
        Frame.Size = UDim2.new(0, 90, 0, 56); local FrameUICorner = Instance.new("UICorner", Frame); FrameUICorner.CornerRadius = UDim.new(0, 6); local FrameUIStroke = Instance.new("UIStroke", Frame); FrameUIStroke.Color = Color3.fromRGB(0, 100, 255); FrameUIStroke.Thickness = 1.5; FrameUIStroke.Transparency = 0.2
        -- ## PERBAIKAN: TitleBar diubah menjadi TextButton untuk geser yang lebih baik
        local TitleBar = Instance.new("TextButton", Frame); TitleBar.BackgroundColor3 = Color3.fromRGB(140, 170, 235); TitleBar.BackgroundTransparency = 0.4; TitleBar.BorderSizePixel = 0; TitleBar.Size = UDim2.new(1, 0, 0, 18); TitleBar.Text = ""; TitleBar.AutoButtonColor = false
        MakeDraggable(Frame, TitleBar, function() return true end, nil) -- Terapkan fungsi geser
        
        local TitleLabel = Instance.new("TextLabel", TitleBar); TitleLabel.BackgroundTransparency = 1.0; TitleLabel.Size = UDim2.new(1, -20, 1, 0); TitleLabel.Position = UDim2.new(0, 5, 0, 0); TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.Text = "Touch Fling"; TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLabel.TextSize = 11; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        local OnOffButton = Instance.new("TextButton", Frame); OnOffButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255); OnOffButton.BorderSizePixel = 0; OnOffButton.Position = UDim2.new(0.5, -30, 0, 25); OnOffButton.Size = UDim2.new(0, 60, 0, 22); OnOffButton.Font = Enum.Font.SourceSansBold; OnOffButton.Text = "OFF"; OnOffButton.TextColor3 = Color3.fromRGB(255, 255, 255); OnOffButton.TextSize = 14; local OnOffButtonCorner = Instance.new("UICorner", OnOffButton); OnOffButtonCorner.CornerRadius = UDim.new(0, 5); local OnOffButtonGradient = Instance.new("UIGradient", OnOffButton); OnOffButtonGradient.Color = ColorSequence.new(Color3.fromRGB(100, 180, 255), Color3.fromRGB(80, 150, 255)); OnOffButtonGradient.Rotation = 90
        local CloseButton = Instance.new("TextButton", TitleBar); CloseButton.Size = UDim2.new(0, 16, 0, 16); CloseButton.Position = UDim2.new(1, -18, 0.5, -8); CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50); CloseButton.Text = "X"; CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255); CloseButton.Font = Enum.Font.SourceSansBold; CloseButton.TextSize = 11; local corner = Instance.new("UICorner", CloseButton); corner.CornerRadius = UDim.new(1, 0)
        local hiddenfling, flingThread = false, nil
        local function fling() while hiddenfling do local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if hrp then local vel = hrp.Velocity; hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0); RunService.RenderStepped:Wait(); if hrp and hrp.Parent then hrp.Velocity = vel end; RunService.Stepped:Wait(); if hrp and hrp.Parent then hrp.Velocity = vel + Vector3.new(0, 0.1 * (math.random(0, 1) == 0 and -1 or 1), 0) end end; RunService.Heartbeat:Wait() end end
        OnOffButton.MouseButton1Click:Connect(function() hiddenfling = not hiddenfling; OnOffButton.Text = hiddenfling and "ON" or "OFF"; if hiddenfling then if not flingThread or coroutine.status(flingThread) == "dead" then flingThread = coroutine.create(fling); coroutine.resume(flingThread) end end end)
        CloseButton.MouseButton1Click:Connect(function() hiddenfling = false; FlingScreenGui:Destroy(); touchFlingGui = nil end)
    end
    
    local function ToggleKillAura(enabled)
        IsKillAuraEnabled = enabled
        saveFeatureStates()
        if enabled then KillAuraConnection = RunService.Heartbeat:Connect(function() local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not root then return end; for _, npc in pairs(Workspace:GetDescendants()) do if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then local humanoid = npc.Humanoid; if humanoid.Health > 0 and (npc.HumanoidRootPart.Position - root.Position).Magnitude <= Settings.KillAuraRadius then humanoid:TakeDamage(Settings.KillAuraDamage) end end end end)
        elseif KillAuraConnection then KillAuraConnection:Disconnect(); KillAuraConnection = nil end
    end
    
    local function ToggleAimbot(enabled)
        IsAimbotEnabled = enabled
        saveFeatureStates()
        if enabled then CreateFOVCircle(); AimbotConnection = RunService.RenderStepped:Connect(function() local camera = Workspace.CurrentCamera; local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not (root and camera) then return end; local mousePos = UserInputService:GetMouseLocation(); local closestNPC, closestDistance = nil, Settings.AimbotFOV; for _, npc in pairs(Workspace:GetDescendants()) do if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild(Settings.AimbotPart) then local humanoid = npc.Humanoid; if humanoid.Health > 0 then local screenPos, onScreen = camera:WorldToViewportPoint(npc[Settings.AimbotPart].Position); if onScreen then local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude; if distance <= closestDistance then closestDistance, closestNPC = distance, npc end end end end end; AimbotTarget = closestNPC; if AimbotTarget and AimbotTarget:FindFirstChild(Settings.AimbotPart) then camera.CFrame = CFrame.new(camera.CFrame.Position, AimbotTarget[Settings.AimbotPart].Position); AimbotTarget.Humanoid:TakeDamage(Settings.KillAuraDamage) end; if FOVPart then FOVPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0)); FOVPart.FOVGui.Enabled = true end end)
        else if AimbotConnection then AimbotConnection:Disconnect(); AimbotConnection = nil end; AimbotTarget = nil; if FOVPart then FOVPart:Destroy(); FOVPart = nil end end
    end
    
    local function protect_character()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if root and antifling_enabled then if root.Velocity.Magnitude <= antifling_velocity_threshold then antifling_last_safe_cframe = root.CFrame end; if root.Velocity.Magnitude > antifling_velocity_threshold and antifling_last_safe_cframe then root.Velocity, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity, root.CFrame = Vector3.new(), Vector3.new(), Vector3.new(), antifling_last_safe_cframe end; if root.AssemblyAngularVelocity.Magnitude > antifling_angular_threshold then root.AssemblyAngularVelocity = Vector3.new() end; if LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end end
    end
    
    local function ToggleAntiFling(enabled)
        antifling_enabled = enabled; saveFeatureStates(); if enabled and not antifling_connection then antifling_connection = RunService.Heartbeat:Connect(protect_character) elseif not enabled and antifling_connection then antifling_connection:Disconnect(); antifling_connection = nil end
    end

    local function ToggleAntiLag(enabled)
        IsAntiLagEnabled = enabled
        saveFeatureStates()
        if enabled then
            Lighting.GlobalShadows = false; Lighting.FogEnd = 999999
            if settings then pcall(function() settings().Rendering.QualityLevel = "Level01" end) end
            for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Explosion") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false end end
            for _, v in pairs(Lighting:GetChildren()) do if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end end
            antiLagConnection = Workspace.DescendantAdded:Connect(function(descendant) if descendant:IsA("ParticleEmitter") or descendant:IsA("Explosion") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then task.wait(); descendant.Enabled = false end end)
            -- showNotification("Anti-Lag Diaktifkan", Color3.fromRGB(50, 200, 50))
        else
            if antiLagConnection then antiLagConnection:Disconnect(); antiLagConnection = nil end
            Lighting.GlobalShadows = true
            if settings then pcall(function() settings().Rendering.QualityLevel = "Automatic" end) end
            for _, v in pairs(Workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Explosion") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = true end end
            for _, v in pairs(Lighting:GetChildren()) do if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = true end end
            -- showNotification("Anti-Lag Dinonaktifkan", Color3.fromRGB(200, 150, 50))
        end
    end

    local function HopServer()
        -- [[ FUNGSI HOP SERVER DENGAN RE-EXECUTOR ]]
        
        -- Langkah 1: Pengecekan Setup
        if SCRIPT_URL == "GANTI_DENGAN_URL_RAW_PASTEBIN_ATAU_GIST_ANDA" then
            showNotification("URL Skrip belum diatur! Lihat bagian atas skrip.", Color3.fromRGB(255, 100, 0))
            return
        end

        local servers = {}
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)

        if not success or not response or not response.data then
            showNotification("Gagal mengambil daftar server.", Color3.fromRGB(200, 50, 50))
            warn("Server Hop Error:", response)
            return
        end
        
        for _, server in ipairs(response.data) do
            if type(server) == 'table' and server.id ~= game.JobId and server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end

        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            
            -- Langkah 2: Simpan semua status dan posisi UI
            saveFeatureStates()
            saveGuiPositions()
            
            -- Langkah 3: Jadwalkan re-eksekusi jika memungkinkan
            if queue_on_teleport and type(queue_on_teleport) == "function" then
                local loaderCode = "loadstring(game:HttpGet('" .. SCRIPT_URL .. "'))()"
                queue_on_teleport(loaderCode)
                showNotification("Re-eksekusi terjadwal, pindah server...", Color3.fromRGB(50, 150, 255))
            else
                showNotification("Executor tidak mendukung 'queue_on_teleport'. Gunakan auto-exec.", Color3.fromRGB(255, 150, 0))
            end

            task.wait(0.1) 
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
            end)
        else
            showNotification("Tidak ada server lain yang ditemukan.", Color3.fromRGB(200, 150, 50))
        end
    end
    
    local function DisableAllFeatures()
		-- Panggil TurnVisible jika fitur sedang aktif untuk membersihkan
		if IsInvisibilityEnabled or invisRunning then TurnVisible() end
		
        if IsFlying then if UserInputService.TouchEnabled then StopMobileFly() else StopFly() end end; if IsWalkSpeedEnabled then ToggleWalkSpeed(false) end; if IsNoclipEnabled then ToggleNoclip(false) end; if IsGodModeEnabled then ToggleGodMode(false) end; if IsKillAuraEnabled then ToggleKillAura(false) end; if IsAimbotEnabled then ToggleAimbot(false) end; if IsInfinityJumpEnabled then IsInfinityJumpEnabled = false; if infinityJumpConnection then infinityJumpConnection:Disconnect(); infinityJumpConnection = nil end end; if antifling_enabled then ToggleAntiFling(false) end; if IsAntiLagEnabled then ToggleAntiLag(false) end
        if isEmoteEnabled then destroyEmoteGUI(); EmoteToggleButton.Visible = false end
        if isAnimationEnabled then destroyAnimationGUI(); AnimationShowButton.Visible = false end 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = OriginalWalkSpeed end
    end
    
    local function CloseScript()
        DisableAllFeatures(); ScreenGui:Destroy(); if touchFlingGui and touchFlingGui.Parent then touchFlingGui:Destroy() end
    end
    
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
        sliderBase.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDraggingSlider = false; saveFeatureStates() end end)
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
        local currentIndex = 1; for i,v in pairs(options) do if v == current then currentIndex = i break end end
        optionButton.MouseButton1Click:Connect(function() currentIndex = currentIndex % #options + 1; local newOption = options[currentIndex]; label.Text = name .. ": " .. newOption; callback(newOption) end); return dropdownFrame
    end
    
    -- ====================================================================
    -- == BAGIAN PENGATURAN KONTEN TAB                                  ==
    -- ====================================================================
    
    -- Tab Player
    local playerHeaderFrame = Instance.new("Frame", PlayerTabContent); playerHeaderFrame.Size = UDim2.new(1, 0, 0, 55); playerHeaderFrame.BackgroundTransparency = 1
    local playerCountLabel = Instance.new("TextLabel", playerHeaderFrame); playerCountLabel.Name = "PlayerCountLabel"; playerCountLabel.Size = UDim2.new(1, -20, 0, 15); playerCountLabel.BackgroundTransparency = 1; playerCountLabel.Text = "Pemain Online: " .. #Players:GetPlayers(); playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255); playerCountLabel.TextSize = 12; playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left; playerCountLabel.Font = Enum.Font.SourceSansBold
    
    local refreshButton = Instance.new("TextButton", playerHeaderFrame)
    refreshButton.Name = "RefreshButton"
    refreshButton.Size = UDim2.new(0, 15, 0, 15); refreshButton.Position = UDim2.new(1, -15, 0, 0); refreshButton.BackgroundTransparency = 1
    refreshButton.Text = "🔄"; refreshButton.TextColor3 = Color3.fromRGB(0, 200, 255); refreshButton.TextSize = 14; refreshButton.Font = Enum.Font.SourceSansBold
    
    local isAnimatingRefresh = false
    refreshButton.MouseButton1Click:Connect(function() 
        if isAnimatingRefresh then return end; isAnimatingRefresh = true
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear); local tween = TweenService:Create(refreshButton, tweenInfo, { Rotation = refreshButton.Rotation + 360 }); tween:Play()
        if updatePlayerList then updatePlayerList() end 
        tween.Completed:Connect(function() isAnimatingRefresh = false end)
    end)

    local searchFrame = Instance.new("Frame", playerHeaderFrame); searchFrame.Size = UDim2.new(1, 0, 0, 25); searchFrame.Position = UDim2.new(0, 0, 0, 20); searchFrame.BackgroundTransparency = 1
    local searchTextBox = Instance.new("TextBox", searchFrame); searchTextBox.Size = UDim2.new(0.7, -10, 1, 0); searchTextBox.Position = UDim2.new(0, 5, 0, 0); searchTextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35); searchTextBox.TextColor3 = Color3.fromRGB(200, 200, 200); searchTextBox.PlaceholderText = "Cari Pemain..."; searchTextBox.TextSize = 12; searchTextBox.Font = Enum.Font.SourceSans; searchTextBox.ClearTextOnFocus = true; local sboxCorner = Instance.new("UICorner", searchTextBox); sboxCorner.CornerRadius = UDim.new(0, 5)
    local searchButton = Instance.new("TextButton", searchFrame); searchButton.Size = UDim2.new(0.3, 0, 1, 0); searchButton.Position = UDim2.new(0.7, 0, 0, 0); searchButton.BackgroundColor3 = Color3.fromRGB(0, 150,  255); searchButton.BorderSizePixel = 0; searchButton.Text = "Cari"; searchButton.TextColor3 = Color3.fromRGB(255, 255, 255); searchButton.TextSize = 12; searchButton.Font = Enum.Font.SourceSansBold; local sbtnCorner = Instance.new("UICorner", searchButton); sbtnCorner.CornerRadius = UDim.new(0, 5)
    
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
        if isUpdatingPlayerList then return end; if not (MainFrame.Visible and PlayerTabContent.Visible) then return end
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
    createToggle(GeneralTabContent, "Infinity Jump", IsInfinityJumpEnabled, function(v) IsInfinityJumpEnabled = v; saveFeatureStates(); if v then if LocalPlayer.Character and LocalPlayer.Character.Humanoid then infinityJumpConnection = UserInputService.JumpRequest:Connect(function() LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end elseif infinityJumpConnection then infinityJumpConnection:Disconnect(); infinityJumpConnection = nil end end)
    createToggle(GeneralTabContent, "Mode Kebal", IsGodModeEnabled, ToggleGodMode) 
    createButton(GeneralTabContent, "Buka Touch Fling", CreateTouchFlingGUI)
    createToggle(GeneralTabContent, "Anti-Fling", antifling_enabled, ToggleAntiFling)
    createToggle(GeneralTabContent, "Anti-Lag", IsAntiLagEnabled, ToggleAntiLag)
    -- [[ PERBAIKAN TOMBOL INVISIBLE ]] --
    createToggle(GeneralTabContent, "Invisible", IsInvisibilityEnabled, function(v)
        IsInvisibilityEnabled = v
        if v then
            makeInvisible()
        else
            TurnVisible()
        end
        saveFeatureStates()
    end)
    createButton(GeneralTabContent, "Hop Server", function() HopServer() end)

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
    
    -- Tab VIP (Berisi Emote dan Animasi)
    createToggle(VipTabContent, "Aktifkan Emote Asli", isEmoteEnabled, function(v) 
        isEmoteEnabled = v; 
        if isEmoteEnabled then 
            initializeEmoteGUI() 
            EmoteToggleButton.Visible = true
        else 
            destroyEmoteGUI() 
            EmoteToggleButton.Visible = false
        end 
    end)
    -- [[ PERBAIKAN LOGIKA TOGGLE ANIMASI ]]
    createToggle(VipTabContent, "Aktifkan Animasi VIP", isAnimationEnabled, function(v) 
        isAnimationEnabled = v; 
        if isAnimationEnabled then 
            initializeAnimationGUI() 
            AnimationShowButton.Visible = true
        else 
            destroyAnimationGUI() 
            AnimationShowButton.Visible = false
        end 
    end)

    -- Tab Pengaturan
    createToggle(SettingsTabContent, "Kunci Bar Tombol", not isMiniToggleDraggable, function(v) isMiniToggleDraggable = not v end).LayoutOrder = 1
    createToggle(SettingsTabContent, "Transparansi Emote", isEmoteTransparent, function(v)
        isEmoteTransparent = v
        if isEmoteEnabled and applyEmoteTransparency then applyEmoteTransparency(v) end
    end).LayoutOrder = 2
    createToggle(SettingsTabContent, "Transparansi Animasi", isAnimationTransparent, function(v)
        isAnimationTransparent = v
        if isAnimationEnabled and applyAnimationTransparency then applyAnimationTransparency(v) end
    end).LayoutOrder = 3
    -- BARU: Tombol untuk menyimpan posisi UI
    createButton(SettingsTabContent, "Simpan Posisi UI", saveGuiPositions).LayoutOrder = 4
    createButton(SettingsTabContent, "Tutup Skrip", CloseScript).LayoutOrder = 5
    
    -- =================================================================================
    -- == BAGIAN UTAMA DAN KONEKSI EVENT                                              ==
    -- =================================================================================
    
    MakeDraggable(MainFrame, TitleBar, function() return true end, nil)
    MakeDraggable(MiniToggleContainer, MiniToggleContainer, function() return isMiniToggleDraggable end, nil)

    MiniToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        MiniToggleButton.Text = MainFrame.Visible and "◀" or "▶"
        MiniToggleButton.BackgroundTransparency = MainFrame.Visible and 0.5 or 1
        if MainFrame.Visible then
            if not (PlayerTabContent.Visible or GeneralTabContent.Visible or CombatTabContent.Visible or TeleportTabContent.Visible or SettingsTabContent.Visible or VipTabContent.Visible) then
                switchTab("Player")
            else
                updatePlayerList()
            end
        end
    end)

    EmoteToggleButton.MouseButton1Click:Connect(function()
        if EmoteScreenGui then
            local frame = EmoteScreenGui:FindFirstChild("MainFrame")
            if frame then
                frame.Visible = true
                EmoteToggleButton.Visible = false
            end
        end
    end)

    AnimationShowButton.MouseButton1Click:Connect(function()
        if AnimationScreenGui then
            local frame = AnimationScreenGui:FindFirstChild("GazeBro")
            if frame then
                frame.Visible = true
                AnimationShowButton.Visible = false
            end
        end
    end)
    
    -- Toggle terbang dengan tombol F
    UserInputService.InputBegan:Connect(function(input, processed) 
        if processed then return end; if input.KeyCode == Enum.KeyCode.F and not UserInputService.TouchEnabled then if not IsFlying then StartFly() else StopFly() end end 
    end)
    
    -- ## PERBAIKAN ANIMASI: Fungsi global untuk menerapkan semua animasi yang tersimpan
    local function applyAllAnimations(character)
        if not character or not next(lastAnimations) then return end
        
        local animateScript = character:WaitForChild("Animate", 10)
        if not animateScript then 
            warn("ArexansTools: Gagal menerapkan animasi, script 'Animate' tidak ditemukan.")
            return
        end
        
        task.wait(0.5) -- Beri waktu tambahan agar script Animate bisa inisialisasi
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        pcall(function()
            local Anim = animateScript
            humanoid.PlatformStand = true
            task.wait(0.1)

            if lastAnimations.Idle then Anim.idle.Animation1.AnimationId, Anim.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Idle[1], "http://www.roblox.com/asset/?id="..lastAnimations.Idle[2] end
            if lastAnimations.Walk then Anim.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Walk end
            if lastAnimations.Run then Anim.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Run end
            if lastAnimations.Jump then Anim.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Jump end
            if lastAnimations.Fall then Anim.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Fall end
            if lastAnimations.Swim and Anim.swim then Anim.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Swim end
            if lastAnimations.SwimIdle and Anim.swimidle then Anim.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.SwimIdle end
            if lastAnimations.Climb then Anim.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id="..lastAnimations.Climb end

            task.wait(0.1)
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    
    -- [[ PERBAIKAN ANTI-RESET SAAT RESPAWN & HOP SERVER ]]

    -- Fungsi ini HANYA untuk fitur yang tidak bergantung pada karakter, dijalankan sekali saat skrip dimuat
    local function applyInitialStates()
        if IsAntiLagEnabled then ToggleAntiLag(true) end
        if IsKillAuraEnabled then ToggleKillAura(true) end
        if IsAimbotEnabled then ToggleAimbot(true) end
    end
    
    -- Fungsi ini akan menerapkan kembali semua fitur yang bergantung pada karakter baru Anda.
    local function reapplyFeaturesOnRespawn(character)
        if not character then return end
    
        -- Menunggu sebentar agar karakter dan humanoid sepenuhnya dimuat
        task.wait(0.2) 
    
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
    
        -- Terapkan kembali WalkSpeed
        if IsWalkSpeedEnabled then
            humanoid.WalkSpeed = Settings.WalkSpeed
        else
            humanoid.WalkSpeed = OriginalWalkSpeed
        end
    
        -- Terapkan kembali GodMode
        if IsGodModeEnabled then
            applyGodMode(character)
        end
    
        -- Terapkan kembali Anti-Fling
        if antifling_enabled then
            ToggleAntiFling(true)
        end
        
        -- Terapkan kembali Noclip
        if IsNoclipEnabled then
            ToggleNoclip(true) -- Memulai kembali loop noclip pada karakter baru
        end
    
        -- Terapkan kembali Infinity Jump
        if IsInfinityJumpEnabled then
            if infinityJumpConnection then infinityJumpConnection:Disconnect() end -- Hapus koneksi lama
            infinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    
        -- Terapkan kembali Fly
        if IsFlying then
            IsFlying = false -- Reset sementara status untuk mengizinkan StartFly/StartMobileFly berjalan kembali
            if UserInputService.TouchEnabled then
                StartMobileFly()
            else
                StartFly()
            end
        end

        -- Terapkan kembali Invisibility
        if IsInvisibilityEnabled then
			-- Jangan langsung panggil makeInvisible(), karena itu akan membuat loop tak terbatas saat respawn.
			-- Status sudah ON, biarkan pengguna menonaktifkannya secara manual jika diperlukan.
			-- Jika fitur rusak setelah respawn, ini perlu di-debug lebih lanjut.
        end

        -- ## PERBAIKAN ANIMASI: Panggil fungsi untuk menerapkan animasi
        applyAllAnimations(character)
    end
    
    -- Sambungkan fungsi di atas ke event CharacterAdded
    LocalPlayer.CharacterAdded:Connect(reapplyFeaturesOnRespawn)

    -- INISIALISASI
    loadAnimations()
    loadTeleportData()
    loadGuiPositions()
    loadFeatureStates() -- Muat status fitur yang tersimpan
    applyInitialStates() -- Terapkan fitur yang tidak bergantung pada karakter
    switchTab("Player")
    
    -- Terapkan fitur ke karakter yang sudah ada saat skrip dieksekusi pertama kali
    if LocalPlayer.Character then
        reapplyFeaturesOnRespawn(LocalPlayer.Character)
    end
end)
