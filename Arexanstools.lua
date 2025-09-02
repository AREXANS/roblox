-- File: cheat.lua
--[[
 * ArexansTools (Tanpa Fitur Teleport)
 *
 * Versi ini dari skrip "ArexansTools" mencakup fitur-fitur dasar:
 * - Tab "Pengaturan" yang dapat di-scroll
 * - Auto looping untuk mencapai puncak di obby
 * - Fly, Noclip, dan Walkspeed
 * - Infinity Jump (Fitur baru)
 * - Fling on Touch (Fitur baru)
 * - Anti-Fling (Fitur baru)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Settings
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
    ObbyLoopInterval = 0.5,
}

-- Status variables
local IsFlying = false
local IsNoclipEnabled = false
local IsKillAuraEnabled = false
local IsAimbotEnabled = false
local IsWalkSpeedEnabled = false
local OriginalWalkSpeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed or 16
local FlyConnections = {}
local KillAuraConnection = nil
local AimbotConnection = nil
local AimbotTarget = nil
local FOVPart = nil
local IsAutoObbyEnabled = false
local AutoObbyConnection = nil
local IsInfinityJumpEnabled = false
local infinityJumpConnection = nil
local PlayerButtons = {} -- Tabel untuk melacak tombol pemain yang ada
local CurrentPlayerFilter = "" -- Variabel untuk menyimpan filter pencarian
local IsFlingOnTouchEnabled = false
local flingConnection = nil

-- AntiFling Variables
local antifling_velocity_threshold = 85
local antifling_angular_threshold = 25
local antifling_last_safe_cframe = nil
local antifling_enabled = false
local antifling_connection = nil


-- Daftar titik teleportasi gunung
local MountainCheckpoints = {
    ["Checkpoint 1 (Pangkalan)"] = Vector3.new(200, 10, 150),
    ["Checkpoint 2 (Lembah)"] = Vector3.new(350, 50, 200),
    ["Checkpoint 3 (Tanjakan)"] = Vector3.new(500, 120, 250),
    ["Checkpoint 4 (Puncak)"] = Vector3.new(650, 200, 300),
}

-- Create custom GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArexansToolsGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Mini toggle button
local MiniToggleButton = Instance.new("TextButton")
MiniToggleButton.Name = "MiniToggleButton"
MiniToggleButton.Size = UDim2.new(0, 15, 0, 15) -- Ukuran sangat kecil
MiniToggleButton.Position = UDim2.new(1, -25, 0, 10) -- Pindah ke sudut kanan atas
MiniToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MiniToggleButton.BackgroundTransparency = 1 -- Sangat transparan
MiniToggleButton.BorderSizePixel = 0
MiniToggleButton.Text = "▼" -- Menggunakan segitiga unicode
MiniToggleButton.TextColor3 = Color3.fromRGB(0, 200, 255)
MiniToggleButton.TextSize = 10
MiniToggleButton.Font = Enum.Font.SourceSansBold
MiniToggleButton.Parent = ScreenGui

local MiniUICorner = Instance.new("UICorner")
MiniUICorner.CornerRadius = UDim.new(0, 8)
MiniUICorner.Parent = MiniToggleButton

local MiniUIStroke = Instance.new("UIStroke")
MiniUIStroke.Color = Color3.fromRGB(0, 150, 255)
MiniUIStroke.Thickness = 2
MiniUIStroke.Transparency = 0.5
MiniUIStroke.Parent = MiniToggleButton

-- Main GUI frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 350) -- Ukuran lebih kecil
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -175) -- Posisi di tengah
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
TitleBar.Size = UDim2.new(1, 0, 0, 30) -- Ukuran title bar lebih kecil
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Arexans Tools"
TitleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
TitleLabel.TextSize = 14 -- Ukuran font lebih kecil
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = TitleBar

local TabsFrame = Instance.new("Frame")
TabsFrame.Name = "TabsFrame"
TabsFrame.Size = UDim2.new(0, 80, 1, -30) -- Lebar tab lebih kecil
TabsFrame.Position = UDim2.new(0, 0, 0, 30)
TabsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabsFrame.BorderSizePixel = 0
TabsFrame.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.Name = "TabListLayout"
TabListLayout.Padding = UDim.new(0, 5) -- Padding lebih kecil
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
TabListLayout.FillDirection = Enum.FillDirection.Vertical
TabListLayout.Parent = TabsFrame

-- Add ScrollingFrame to ContentFrame for easy scrolling
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -80, 1, -30)
ContentFrame.Position = UDim2.new(0, 80, 0, 30)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

-- Tab content frames
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
PlayerListContainer.ScrollBarThickness = 6
PlayerListContainer.Parent = PlayerTabContent

local GeneralTabContent = Instance.new("ScrollingFrame")
GeneralTabContent.Name = "GeneralTab"
GeneralTabContent.Size = UDim2.new(1, -10, 1, -10)
GeneralTabContent.Position = UDim2.new(0, 5, 0, 5)
GeneralTabContent.BackgroundTransparency = 1
GeneralTabContent.Visible = false
GeneralTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
GeneralTabContent.ScrollBarThickness = 6
GeneralTabContent.Parent = ContentFrame

local CombatTabContent = Instance.new("ScrollingFrame")
CombatTabContent.Name = "CombatTab"
CombatTabContent.Size = UDim2.new(1, -10, 1, -10)
CombatTabContent.Position = UDim2.new(0, 5, 0, 5)
CombatTabContent.BackgroundTransparency = 1
CombatTabContent.Visible = false
CombatTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
CombatTabContent.ScrollBarThickness = 6
CombatTabContent.Parent = ContentFrame

local TeleportTabContent = Instance.new("ScrollingFrame")
TeleportTabContent.Name = "TeleportTab"
TeleportTabContent.Size = UDim2.new(1, -10, 1, -10)
TeleportTabContent.Position = UDim2.new(0, 5, 0, 5)
TeleportTabContent.BackgroundTransparency = 1
TeleportTabContent.Visible = false
TeleportTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
TeleportTabContent.ScrollBarThickness = 6
TeleportTabContent.Parent = ContentFrame

local SettingsTabContent = Instance.new("ScrollingFrame")
SettingsTabContent.Name = "SettingsTab"
SettingsTabContent.Size = UDim2.new(1, -10, 1, -10)
SettingsTabContent.Position = UDim2.new(0, 5, 0, 5)
SettingsTabContent.BackgroundTransparency = 1
SettingsTabContent.Visible = false
SettingsTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsTabContent.ScrollBarThickness = 6
SettingsTabContent.Parent = ContentFrame

-- Add UIListLayout to tab contents
local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Name = "PlayerListLayout"
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
PlayerListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
PlayerListLayout.FillDirection = Enum.FillDirection.Vertical
PlayerListLayout.Parent = PlayerListContainer

local GeneralListLayout = Instance.new("UIListLayout")
GeneralListLayout.Name = "GeneralListLayout"
GeneralListLayout.Padding = UDim.new(0, 5)
GeneralListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GeneralListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
GeneralListLayout.FillDirection = Enum.FillDirection.Vertical
GeneralListLayout.Parent = GeneralTabContent

local CombatListLayout = Instance.new("UIListLayout")
CombatListLayout.Name = "CombatListLayout"
CombatListLayout.Padding = UDim.new(0, 5)
CombatListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
CombatListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
CombatListLayout.FillDirection = Enum.FillDirection.Vertical
CombatListLayout.Parent = CombatTabContent

local TeleportListLayout = Instance.new("UIListLayout")
TeleportListLayout.Name = "TeleportListLayout"
TeleportListLayout.Padding = UDim.new(0, 5)
TeleportListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TeleportListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
TeleportListLayout.FillDirection = Enum.FillDirection.Vertical
TeleportListLayout.Parent = TeleportTabContent

local SettingsListLayout = Instance.new("UIListLayout")
SettingsListLayout.Name = "SettingsListLayout"
SettingsListLayout.Padding = UDim.new(0, 5)
SettingsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
SettingsListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
SettingsListLayout.FillDirection = Enum.FillDirection.Vertical
SettingsListLayout.Parent = SettingsTabContent

-- Main window drag logic
local isDraggingMain = false
local lastMousePositionMain = Vector2.new()

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMain = true
        lastMousePositionMain = UserInputService:GetMouseLocation()
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMain = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingMain and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - lastMousePositionMain
        MainFrame.Position = MainFrame.Position + UDim2.new(0, delta.X, 0, delta.Y)
        lastMousePositionMain = UserInputService:GetMouseLocation()
    end
end)

-- Mini button drag logic
local isDraggingMini = false
local lastMousePositionMini = Vector2.new()

MiniToggleButton.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMini = true
        lastMousePositionMini = UserInputService:GetMouseLocation()
    end
end)

MiniToggleButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMini = false
    end
end)

UserInputService.InputChanged:Connect(function(input, processed)
    if processed then return end
    if isDraggingMini and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = UserInputService:GetMouseLocation() - lastMousePositionMini
        MiniToggleButton.Position = MiniToggleButton.Position + UDim2.new(0, delta.X, 0, delta.Y)
        lastMousePositionMini = UserInputService:GetMouseLocation()
    end
end)

-- Function to switch tabs
local function switchTab(tabName)
    PlayerTabContent.Visible = (tabName == "Player")
    GeneralTabContent.Visible = (tabName == "Umum")
    CombatTabContent.Visible = (tabName == "Tempur")
    TeleportTabContent.Visible = (tabName == "Teleport")
    SettingsTabContent.Visible = (tabName == "Pengaturan")
    
    -- Refresh player list when switching to the Player tab
    if tabName == "Player" then
        updatePlayerList()
    end
end

-- Tab buttons
local function createTabButton(name, parent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 25) -- Ukuran tombol tab lebih kecil
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12 -- Ukuran font lebih kecil
    button.Font = Enum.Font.SourceSansSemibold
    button.Parent = parent

    local buttonUICorner = Instance.new("UICorner")
    buttonUICorner.CornerRadius = UDim.new(0, 5)
    buttonUICorner.Parent = button

    button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
    return button
end

local PlayerTabButton = createTabButton("Player", TabsFrame)
local GeneralTabButton = createTabButton("Umum", TabsFrame)
local CombatTabButton = createTabButton("Tempur", TabsFrame)
local TeleportTabButton = createTabButton("Teleport", TabsFrame)
local SettingsTabButton = createTabButton("Pengaturan", TabsFrame)

-- Function to create FOV visualization circle
local function CreateFOVCircle()
    if FOVPart then
        FOVPart:Destroy()
    end
    FOVPart = Instance.new("Part")
    FOVPart.Name = "AimbotFOV"
    FOVPart.Anchored = true
    FOVPart.CanCollide = false
    FOVPart.Transparency = 1
    FOVPart.Size = Vector3.new(0.1, 0.1, 0.1)
    FOVPart.Parent = Workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FOVGui"
    billboard.Adornee = FOVPart
    billboard.Size = UDim2.new(Settings.AimbotFOV * 2 / 50, 0, Settings.AimbotFOV * 2 / 50, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = FOVPart

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.fromRGB(0, 200, 255)
    uiStroke.Transparency = 0.2
    uiStroke.Parent = frame
end

-- Function to update FOV circle size
local function UpdateFOVCircle()
    if FOVPart and FOVPart:FindFirstChild("FOVGui") then
        FOVPart.FOVGui.Size = UDim2.new(Settings.AimbotFOV * 2 / 50, 0, Settings.AimbotFOV * 2 / 50, 0)
    end
end

-- Fly function (PC)
local function StartFly()
    if IsFlying then return end
    local character = LocalPlayer.Character
    if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then
        warn("Karakter atau komponen tidak ditemukan!")
        return
    end

    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    IsFlying = true
    humanoid.PlatformStand = true

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root

    local controls = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local lastControls = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local speed = 0

    FlyConnections[#FlyConnections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode.Name:lower()
            if key == "w" then
                controls.F = Settings.FlySpeed
            elseif key == "s" then
                controls.B = -Settings.FlySpeed
            elseif key == "a" then
                controls.L = -Settings.FlySpeed
            elseif key == "d" then
                controls.R = Settings.FlySpeed
            elseif key == "e" then
                controls.Q = Settings.FlySpeed * 2
            elseif key == "q" then
                controls.E = -Settings.FlySpeed * 2
            end
            Workspace.CurrentCamera.CameraType = Enum.CameraType.Track
        end
    end)

    FlyConnections[#FlyConnections + 1] = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode.Name:lower()
            if key == "w" then
                controls.F = 0
            elseif key == "s" then
                controls.B = 0
            elseif key == "a" then
                controls.L = 0
            elseif key == "d" then
                controls.R = 0
            elseif key == "e" then
                controls.Q = 0
            elseif key == "q" then
                controls.E = 0
            end
        end
    end)

    FlyConnections[#FlyConnections + 1] = RunService.RenderStepped:Connect(function()
        if not IsFlying then return end
        if controls.L + controls.R ~= 0 or controls.F + controls.B ~= 0 or controls.Q + controls.E ~= 0 then
            speed = 50
        else
            speed = 0
        end

        local camera = Workspace.CurrentCamera
        if (controls.L + controls.R) ~= 0 or (controls.F + controls.B) ~= 0 or (controls.Q + controls.E) ~= 0 then
            bodyVelocity.Velocity = ((camera.CFrame.LookVector * (controls.F + controls.B)) +
                ((camera.CFrame * CFrame.new(controls.L + controls.R, (controls.F + controls.B + controls.Q + controls.E) * 0.2, 0).Position) - camera.CFrame.Position)) * speed
            lastControls = {F = controls.F, B = controls.B, L = controls.L, R = controls.R, Q = controls.Q, E = controls.E}
        elseif speed ~= 0 then
            bodyVelocity.Velocity = ((camera.CFrame.LookVector * (lastControls.F + lastControls.B)) +
                ((camera.CFrame * CFrame.new(lastControls.L + lastControls.R, (lastControls.F + lastControls.B + lastControls.Q + lastControls.E) * 0.2, 0).Position) - camera.Cframe.Position)) * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        bodyGyro.CFrame = camera.CFrame
    end)
end

-- Stop fly function (PC)
local function StopFly()
    if not IsFlying then return end
    IsFlying = false
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    for _, conn in pairs(FlyConnections) do
        conn:Disconnect()
    end
    FlyConnections = {}
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        if root:FindFirstChild("FlyGyro") then
            root.FlyGyro:Destroy()
        end
        if root:FindFirstChild("FlyVelocity") then
            root.FlyVelocity:Destroy()
        end
    end
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- Fly function (Mobile)
local function StartMobileFly()
    if IsFlying then return end
    local character = LocalPlayer.Character
    if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then
        warn("Karakter atau komponen tidak ditemukan!")
        return
    end

    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    IsFlying = true
    humanoid.PlatformStand = true

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 1000
    bodyGyro.D = 50
    bodyGyro.Parent = root

    local controlModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    FlyConnections[#FlyConnections + 1] = RunService.RenderStepped:Connect(function()
        if not IsFlying then return end
        local camera = Workspace.CurrentCamera
        if not (character and root and root:FindFirstChild("FlyVelocity") and root:FindFirstChild("FlyGyro")) then
            StopMobileFly()
            return
        end
        local velocityHandler = root.FlyVelocity
        local gyroHandler = root.FlyGyro
        velocityHandler.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        gyroHandler.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gyroHandler.CFrame = camera.CFrame
        velocityHandler.Velocity = Vector3.new(0, 0, 0)

        local direction = controlModule:GetMoveVector()
        if direction.X ~= 0 then
            velocityHandler.Velocity = velocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * (Settings.FlySpeed * 50))
        end
        if direction.Z ~= 0 then
            velocityHandler.Velocity = velocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * (Settings.FlySpeed * 50))
        end
    end)

    FlyConnections[#FlyConnections + 1] = LocalPlayer.CharacterAdded:Connect(function()
        if IsFlying then
            task.wait(0.1)
            StartMobileFly()
        end
    end)
end

-- Stop fly function (Mobile)
local function StopMobileFly()
    if not IsFlying then return end
    IsFlying = false
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    for _, conn in pairs(FlyConnections) do
        conn:Disconnect()
    end
    FlyConnections = {}
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        if root:FindFirstChild("FlyGyro") then
            root.FlyGyro:Destroy()
        end
        if root:FindFirstChild("FlyVelocity") then
            root.FlyVelocity:Destroy()
        end
    end
    Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- Noclip function
local function ToggleNoclip(enabled)
    IsNoclipEnabled = enabled
    if enabled then
        task.spawn(function()
            while IsNoclipEnabled and LocalPlayer.Character do
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
                task.wait(0.1)
            end
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end)
    end
end

-- Walk speed toggle function
local function ToggleWalkSpeed(enabled)
    IsWalkSpeedEnabled = enabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if enabled then
            humanoid.WalkSpeed = Settings.WalkSpeed
        else
            humanoid.WalkSpeed = OriginalWalkSpeed
        end
    end
end

-- Fling on Touch function (DIPERBAIKI)
local function ToggleFlingOnTouch(enabled)
    IsFlingOnTouchEnabled = enabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local localHRP = LocalPlayer.Character.HumanoidRootPart
        if enabled then
            flingConnection = localHRP.Touched:Connect(function(partTouched)
                local otherCharacter = partTouched:FindFirstAncestorOfClass("Model")
                if otherCharacter and otherCharacter ~= LocalPlayer.Character then
                    local otherPlayer = Players:GetPlayerFromCharacter(otherCharacter)
                    if otherPlayer and otherCharacter:FindFirstChild("HumanoidRootPart") then
                        local otherHRP = otherCharacter.HumanoidRootPart
                        local direction = (otherHRP.Position - localHRP.Position).Unit
                        local flingForce = Vector3.new(direction.X * 150, 150, direction.Z * 150)
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bodyVelocity.Velocity = flingForce
                        bodyVelocity.Parent = otherHRP
                        game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
                    end
                end
            end)
        else
            if flingConnection then
                flingConnection:Disconnect()
                flingConnection = nil
            end
        end
    end
end

-- Kill aura function
local function ToggleKillAura(enabled)
    IsKillAuraEnabled = enabled
    if enabled then
        KillAuraConnection = RunService.Heartbeat:Connect(function()
            if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
                return
            end
            local root = LocalPlayer.Character.HumanoidRootPart
            for _, npc in pairs(Workspace:GetDescendants()) do
                if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    local npcRoot = npc.HumanoidRootPart
                    local distance = (npcRoot.Position - root.Position).Magnitude
                    if distance <= Settings.KillAuraRadius and humanoid.Health > 0 then
                        humanoid:TakeDamage(Settings.KillAuraDamage)
                    end
                end
            end
        end)
    else
        if KillAuraConnection then
            KillAuraConnection:Disconnect()
            KillAuraConnection = nil
        end
    end
end

-- Aimbot function
local function ToggleAimbot(enabled)
    IsAimbotEnabled = enabled
    if enabled then
        CreateFOVCircle()
        AimbotConnection = RunService.RenderStepped:Connect(function()
            if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Workspace.CurrentCamera) then
                return
            end
            local camera = Workspace.CurrentCamera
            local root = LocalPlayer.Character.HumanoidRootPart
            local mousePos = UserInputService:GetMouseLocation()
            local closestNPC = nil
            local closestDistance = Settings.AimbotFOV

            -- Find the closest NPC within the FOV
            for _, npc in pairs(Workspace:GetDescendants()) do
                if npc:IsA("Model") and npc ~= LocalPlayer.Character and npc:FindFirstChildOfClass("Humanoid") and npc:FindFirstChild(Settings.AimbotPart) then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if humanoid.Health <= 0 then
                        continue
                    end
                    local partPos = npc[Settings.AimbotPart].Position
                    local screenPos, onScreen = camera:WorldToViewportPoint(partPos)
                    if not onScreen then
                        continue
                    end
                    local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if distance <= closestDistance then
                        closestDistance = distance
                        closestNPC = npc
                    end
                end
            end

            AimbotTarget = closestNPC
            if AimbotTarget and AimbotTarget:FindFirstChild(Settings.AimbotPart) then
                local targetPos = AimbotTarget[Settings.AimbotPart].Position
                camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
                local humanoid = AimbotTarget:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid:TakeDamage(Settings.KillAuraDamage)
                end
            end

            -- Update FOV circle position
            if FOVPart then
                FOVPart.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0))
                FOVPart.FOVGui.Enabled = true
            end
        end)
    else
        if AimbotConnection then
            AimbotConnection:Disconnect()
            AimbotConnection = nil
        end
        AimbotTarget = nil
        if FOVPart then
            FOVPart:Destroy()
            FOVPart = nil
        end
    end
end

-- AntiFling Logic Function
local function protect_character()
	if not LocalPlayer.Character then return end
	local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
	local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if root and humanoid and antifling_enabled then
		if root.Velocity.Magnitude <= antifling_velocity_threshold then
			antifling_last_safe_cframe = root.CFrame
		end

		if root.Velocity.Magnitude > antifling_velocity_threshold then
			if antifling_last_safe_cframe then
				root.Velocity = Vector3.new(0,0,0)
				root.AssemblyLinearVelocity = Vector3.new(0,0,0)
				root.AssemblyAngularVelocity = Vector3.new(0,0,0)
				root.CFrame = antifling_last_safe_cframe
			end
		end

		if root.AssemblyAngularVelocity.Magnitude > antifling_angular_threshold then
			root.AssemblyAngularVelocity = Vector3.new(0,0,0)
		end

		if humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

-- Function to toggle anti-fling
local function ToggleAntiFling(enabled)
    antifling_enabled = enabled
    if enabled then
        if not antifling_connection then
            antifling_connection = RunService.Heartbeat:Connect(protect_character)
        end
    else
        if antifling_connection then
            antifling_connection:Disconnect()
            antifling_connection = nil
        end
    end
end

-- Function to disable all features
local function DisableAllFeatures()
    if IsFlying then
        if UserInputService.TouchEnabled then
            StopMobileFly()
        else
            StopFly()
        end
    end
    if IsWalkSpeedEnabled then
        ToggleWalkSpeed(false)
    end
    if IsNoclipEnabled then
        ToggleNoclip(false)
    end
    if IsKillAuraEnabled then
        ToggleKillAura(false)
    end
    if IsAimbotEnabled then
        ToggleAimbot(false)
    end
    if IsAutoObbyEnabled then
        ToggleAutoObby(false)
    end
    if IsInfinityJumpEnabled then
        IsInfinityJumpEnabled = false
        if infinityJumpConnection then
            infinityJumpConnection:Disconnect()
            infinityJumpConnection = nil
        end
    end
    if IsFlingOnTouchEnabled then
        ToggleFlingOnTouch(false)
    end
    if antifling_enabled then
        ToggleAntiFling(false)
    end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = OriginalWalkSpeed
    end
end

-- Function to remove the script from the game
local function CloseScript()
    DisableAllFeatures()
    ScreenGui:Destroy()
    script:Destroy()
end

-- Handle character respawn to maintain speed
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    if character:FindFirstChildOfClass("Humanoid") then
        if IsWalkSpeedEnabled then
            character.Humanoid.WalkSpeed = Settings.WalkSpeed
        else
            character.Humanoid.WalkSpeed = OriginalWalkSpeed
        end
    end
    -- reconnect fling on touch if enabled
    if IsFlingOnTouchEnabled then
        ToggleFlingOnTouch(true)
    end
    -- reconnect anti-fling if enabled
    if antifling_enabled then
        ToggleAntiFling(true)
    end
end)

-- UI for content
local function createSlider(parent, name, min, max, current, suffix, increment, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 50)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = name .. ": " .. tostring(math.floor(current * 10) / 10) .. " " .. suffix
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.Parent = sliderFrame

    local sliderBase = Instance.new("Frame")
    sliderBase.Name = "SliderBase"
    sliderBase.Size = UDim2.new(1, 0, 0, 10)
    sliderBase.Position = UDim2.new(0, 0, 0, 25)
    sliderBase.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sliderBase.BorderSizePixel = 0
    sliderBase.Parent = sliderFrame
    
    local sliderBaseUICorner = Instance.new("UICorner")
    sliderBaseUICorner.CornerRadius = UDim.new(0, 5)
    sliderBaseUICorner.Parent = sliderBase

    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    local fillWidth = (current - min) / (max - min)
    sliderFill.Size = UDim2.new(fillWidth, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBase
    
    local sliderFillUICorner = Instance.new("UICorner")
    sliderFillUICorner.CornerRadius = UDim.new(0, 5)
    sliderFillUICorner.Parent = sliderFill
    
    local sliderThumb = Instance.new("Frame")
    sliderThumb.Name = "SliderThumb"
    sliderThumb.Size = UDim2.new(0, 15, 0, 25)
    sliderThumb.Position = UDim2.new(fillWidth, -7.5, 0.5, -12.5)
    sliderThumb.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    sliderThumb.BorderSizePixel = 0
    sliderThumb.Parent = sliderBase
    
    local sliderThumbUICorner = Instance.new("UICorner")
    sliderThumbUICorner.CornerRadius = UDim.new(0, 5)
    sliderThumbUICorner.Parent = sliderThumb
    
    local UIStrokeThumb = Instance.new("UIStroke")
    UIStrokeThumb.Color = Color3.fromRGB(255, 255, 255)
    UIStrokeThumb.Thickness = 1
    UIStrokeThumb.Transparency = 0.8
    UIStrokeThumb.Parent = sliderThumb

    local isDraggingSlider = false
    local function updateSlider(input)
        local pos = input.Position.X - sliderBase.AbsolutePosition.X
        local newWidth = math.min(math.max(pos, 0), sliderBase.AbsoluteSize.X)
        local newValue = min + (newWidth / sliderBase.AbsoluteSize.X) * (max - min)
        newValue = math.floor(newValue / increment) * increment
        
        -- Update UI
        local newFillWidth = (newValue - min) / (max - min)
        sliderFill.Size = UDim2.new(newFillWidth, 0, 1, 0)
        sliderThumb.Position = UDim2.new(newFillWidth, -7.5, 0.5, -12.5)
        titleLabel.Text = name .. ": " .. tostring(math.floor(newValue * 10) / 10) .. " " .. suffix
        
        callback(newValue)
    end

    local function handleDrag(input, processed)
        if processed then return end
        if isDraggingSlider then
            updateSlider(input)
        end
    end

    sliderBase.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            updateSlider(input)
        end
    end)
    
    sliderBase.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        handleDrag(input)
    end)
    
    return sliderFrame
end

local function createToggle(parent, name, initialState, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 25)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent

    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0.8, -10, 1, 0)
    toggleLabel.Position = UDim2.new(0, 5, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = name
    toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleLabel.TextSize = 12
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Font = Enum.Font.SourceSans
    toggleLabel.Parent = toggleFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 20)
    toggleButton.Position = UDim2.new(1, -55, 0, 2.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = initialState and "ON" or "OFF"
    toggleButton.TextColor3 = initialState and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    toggleButton.TextSize = 12
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.Parent = toggleFrame

    local buttonUICorner = Instance.new("UICorner")
    buttonUICorner.CornerRadius = UDim.new(0, 5)
    buttonUICorner.Parent = toggleButton
    
    local isToggled = initialState
    toggleButton.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        toggleButton.Text = isToggled and "ON" or "OFF"
        toggleButton.TextColor3 = isToggled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        callback(isToggled)
    end)
    return toggleFrame
end

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
    
    local buttonUICorner = Instance.new("UICorner")
    buttonUICorner.CornerRadius = UDim.new(0, 5)
    buttonUICorner.Parent = button

    button.MouseButton1Click:Connect(function()
        callback()
    end)
    return button
end

local function createDropdown(parent, name, options, current, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, 0, 0, 50)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name .. ": " .. current
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.Parent = dropdownFrame

    local optionButton = Instance.new("TextButton")
    optionButton.Size = UDim2.new(1, 0, 0, 25)
    optionButton.Position = UDim2.new(0, 0, 0, 25)
    optionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    optionButton.BorderSizePixel = 0
    optionButton.Text = "Ubah Target"
    optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    optionButton.TextSize = 12
    optionButton.Font = Enum.Font.SourceSans
    optionButton.Parent = dropdownFrame

    local buttonUICorner = Instance.new("UICorner")
    buttonUICorner.CornerRadius = UDim.new(0, 5)
    buttonUICorner.Parent = optionButton

    local currentIndex = 1
    optionButton.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then
            currentIndex = 1
        end
        local newOption = options[currentIndex]
        label.Text = name .. ": " .. newOption
        callback(newOption)
    end)

    return dropdownFrame
end

-- Player Tab Header (Search and Player Count)
local playerHeaderFrame = Instance.new("Frame")
playerHeaderFrame.Size = UDim2.new(1, 0, 0, 55)
playerHeaderFrame.BackgroundTransparency = 1
playerHeaderFrame.Parent = PlayerTabContent

local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Name = "PlayerCountLabel"
playerCountLabel.Size = UDim2.new(1, 0, 0, 15)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.Text = "Pemain Online: " .. #Players:GetPlayers()
playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playerCountLabel.TextSize = 12
playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
playerCountLabel.Font = Enum.Font.SourceSansBold
playerCountLabel.Parent = playerHeaderFrame

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 25)
searchFrame.Position = UDim2.new(0, 0, 0, 20)
searchFrame.BackgroundTransparency = 1
searchFrame.Parent = playerHeaderFrame

local searchTextBox = Instance.new("TextBox")
searchTextBox.Size = UDim2.new(0.7, -10, 1, 0)
searchTextBox.Position = UDim2.new(0, 5, 0, 0)
searchTextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
searchTextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
searchTextBox.Text = "Cari Pemain..."
searchTextBox.PlaceholderText = "Cari Pemain..."
searchTextBox.TextSize = 12
searchTextBox.Font = Enum.Font.SourceSans
searchTextBox.ClearTextOnFocus = true
searchTextBox.Parent = searchFrame

local searchButton = Instance.new("TextButton")
searchButton.Size = UDim2.new(0.3, 0, 1, 0)
searchButton.Position = UDim2.new(0.7, 0, 0, 0)
searchButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
searchButton.BorderSizePixel = 0
searchButton.Text = "Cari"
searchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
searchButton.TextSize = 12
searchButton.Font = Enum.Font.SourceSansBold
searchButton.Parent = searchFrame

local searchBoxUICorner = Instance.new("UICorner")
searchBoxUICorner.CornerRadius = UDim.new(0, 5)
searchBoxUICorner.Parent = searchTextBox

local searchButtonUICorner = Instance.new("UICorner")
searchButtonUICorner.CornerRadius = UDim.new(0, 5)
searchButtonUICorner.Parent = searchButton

searchTextBox.FocusLost:Connect(function()
    CurrentPlayerFilter = searchTextBox.Text
    updatePlayerList()
end)

searchButton.MouseButton1Click:Connect(function()
    CurrentPlayerFilter = searchTextBox.Text
    updatePlayerList()
end)

-- Player Tab Functions
local function createPlayerButton(player)
    local playerFrame = Instance.new("Frame")
    playerFrame.Size = UDim2.new(1, 0, 0, 45) -- Disesuaikan untuk dua baris teks
    playerFrame.BackgroundTransparency = 1
    playerFrame.Parent = PlayerListContainer
    playerFrame.Name = player.Name

    local avatarImage = Instance.new("ImageLabel")
    avatarImage.Size = UDim2.new(0, 30, 0, 30) -- Ukuran avatar lebih besar
    avatarImage.Position = UDim2.new(0, 5, 0.5, -15)
    avatarImage.BackgroundTransparency = 1
    avatarImage.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    avatarImage.Parent = playerFrame

    local displaynameLabel = Instance.new("TextLabel")
    displaynameLabel.Size = UDim2.new(0.6, -20, 0, 20)
    displaynameLabel.Position = UDim2.new(0, 40, 0, 5)
    displaynameLabel.BackgroundTransparency = 1
    displaynameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displaynameLabel.TextYAlignment = Enum.TextYAlignment.Center
    displaynameLabel.Text = player.DisplayName
    displaynameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    displaynameLabel.TextSize = 12
    displaynameLabel.Font = Enum.Font.SourceSansSemibold
    displaynameLabel.Parent = playerFrame

    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Size = UDim2.new(0.6, -20, 0, 20)
    usernameLabel.Position = UDim2.new(0, 40, 0, 20)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.TextYAlignment = Enum.TextYAlignment.Center
    usernameLabel.Text = "@" .. player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150) -- Warna abu-abu
    usernameLabel.TextSize = 10 -- Ukuran lebih kecil
    usernameLabel.Font = Enum.Font.SourceSans
    usernameLabel.Parent = playerFrame

    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(0, 40, 0, 20)
    teleportButton.Position = UDim2.new(1, -45, 0.5, -10)
    teleportButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    teleportButton.BorderSizePixel = 0
    teleportButton.Text = "TP"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.TextSize = 10
    teleportButton.Font = Enum.Font.SourceSansBold
    teleportButton.Parent = playerFrame
    
    local teleportUICorner = Instance.new("UICorner")
    teleportUICorner.CornerRadius = UDim.new(0, 5)
    teleportUICorner.Parent = teleportButton

    teleportButton.MouseButton1Click:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
            end
        end
    end)

    return playerFrame
end

local function updatePlayerList()
    playerCountLabel.Text = "Pemain Online: " .. #Players:GetPlayers()
    
    -- Hapus semua tombol pemain yang sudah ada kecuali header
    for _, child in pairs(PlayerListContainer:GetChildren()) do
        if child.Name ~= "PlayerListLayout" then
            child:Destroy()
        end
    end

    -- Filter dan buat tombol untuk pemain yang cocok
    local numPlayersShown = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if CurrentPlayerFilter == "" or player.Name:lower():find(CurrentPlayerFilter:lower(), 1, true) or player.DisplayName:lower():find(CurrentPlayerFilter:lower(), 1, true) then
                local button = createPlayerButton(player)
                PlayerButtons[player.Name] = button
                numPlayersShown = numPlayersShown + 1
            end
        end
    end

    -- Perbarui CanvasSize
    PlayerListContainer.CanvasSize = UDim2.new(0, 0, 0, numPlayersShown * 45)
end

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- General tab UI elements
createSlider(GeneralTabContent, "Kecepatan Jalan", 0, Settings.MaxWalkSpeed, Settings.WalkSpeed, "Kecepatan", 1, function(value)
    Settings.WalkSpeed = value
    if IsWalkSpeedEnabled then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
end)

createToggle(GeneralTabContent, "Jalan", IsWalkSpeedEnabled, function(value)
    IsWalkSpeedEnabled = value
    ToggleWalkSpeed(value)
end)

createSlider(GeneralTabContent, "Kecepatan Terbang", 0, Settings.MaxFlySpeed, Settings.FlySpeed, "Kecepatan Terbang", 0.1, function(value)
    Settings.FlySpeed = value
end)

createToggle(GeneralTabContent, "Terbang", IsFlying, function(value)
    if value then
        if UserInputService.TouchEnabled then
            StartMobileFly()
        else
            StartFly()
        end
    else
        if UserInputService.TouchEnabled then
            StopMobileFly()
        else
            StopFly()
        end
    end
end)

createToggle(GeneralTabContent, "Noclip", IsNoclipEnabled, function(value)
    ToggleNoclip(value)
end)

createToggle(GeneralTabContent, "Infinity Jump", IsInfinityJumpEnabled, function(value)
    IsInfinityJumpEnabled = value
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if value then
        if humanoid then
            infinityJumpConnection = UserInputService.JumpRequest:Connect(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    else
        if infinityJumpConnection then
            infinityJumpConnection:Disconnect()
            infinityJumpConnection = nil
        end
    end
end)

createToggle(GeneralTabContent, "Fling on Touch", IsFlingOnTouchEnabled, function(value)
    ToggleFlingOnTouch(value)
end)

createToggle(GeneralTabContent, "Anti-Fling", antifling_enabled, function(value)
    ToggleAntiFling(value)
end)

-- Combat tab UI elements
createSlider(CombatTabContent, "Radius Aura Serang", 0, Settings.MaxKillAuraRadius, Settings.KillAuraRadius, "Studs", 1, function(value)
    Settings.KillAuraRadius = value
end)

createSlider(CombatTabContent, "Kerusakan", 0, Settings.MaxKillAuraDamage, Settings.KillAuraDamage, "Kerusakan", 1, function(value)
    Settings.KillAuraDamage = value
end)

createToggle(CombatTabContent, "Aura Serang", IsKillAuraEnabled, function(value)
    ToggleKillAura(value)
end)

createSlider(CombatTabContent, "FOV Aimbot", 0, Settings.MaxAimbotFOV, Settings.AimbotFOV, "Piksel", 1, function(value)
    Settings.AimbotFOV = value
    UpdateFOVCircle()
end)

createDropdown(CombatTabContent, "Bagian Target Aimbot", {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}, Settings.AimbotPart, function(value)
    Settings.AimbotPart = value
end)

createToggle(CombatTabContent, "Aimbot", IsAimbotEnabled, function(value)
    ToggleAimbot(value)
end)

-- Teleport tab UI elements
for name, position in pairs(MountainCheckpoints) do
    createButton(TeleportTabContent, "Teleport ke " .. name, function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        end
    end)
end

-- Settings tab UI elements
createButton(SettingsTabContent, "Tutup Skrip", CloseScript)

-- Show/hide main GUI
MiniToggleButton.MouseButton1Click:Connect(function()
    if MainFrame.Visible then
        MainFrame.Visible = false
        MiniToggleButton.Text = "▼"
        MiniToggleButton.BackgroundTransparency = 1
    else
        MainFrame.Visible = true
        MiniToggleButton.Text = "▲"
        MiniToggleButton.BackgroundTransparency = 0.5
        updatePlayerList() -- Perbarui daftar pemain saat GUI dibuka
    end
end)

-- Toggle fly with F key
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if not UserInputService.TouchEnabled then
            if not IsFlying then
                StartFly()
            else
                StopFly()
            end
        end
    end
end)

-- Panggil updatePlayerList saat skrip pertama kali dijalankan
updatePlayerList()
