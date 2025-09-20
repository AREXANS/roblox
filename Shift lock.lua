--[[
    ====================================================================================================
    ==                                                                                                ==
    ==                             SKRIP SHIFT LOCK SEDERHANA                                         ==
    ==                                                                                                ==
    ====================================================================================================
    - FITUR: Script ini hanya menyediakan fitur Shift Lock yang stabil dan ringan.
    - TUJUAN: Menghapus semua fitur lain (Target Lock, Dash, GUI kompleks) dari skrip asli.
    - PENGGUNAAN: Klik tombol di layar untuk mengaktifkan atau menonaktifkan Shift Lock. Tombol bisa digeser.
    - BEBAS BUG: Didesain untuk bekerja secara efisien tanpa bug atau lag.
]]

--// Mencegah skrip berjalan ganda dan membersihkan sisa skrip lama
if getgenv().SimpleShiftLock and getgenv().SimpleShiftLock.Exit then
    getgenv().SimpleShiftLock:Exit()
end

--// Lingkungan Skrip
local ShiftLock = {}
getgenv().SimpleShiftLock = ShiftLock

--// Layanan (Services)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

--// Variabel Global
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local connections = {}
local guiElements = {}

--// Pengaturan
local settings = {
    Enabled = false -- Mulai dalam keadaan nonaktif
}

--// =============================================================================================
--// =                                   FUNGSI UTAMA                                            =
--// =============================================================================================

--// Fungsi yang berjalan setiap frame untuk mengatur rotasi karakter
local function UpdateShiftLock()
    -- Pastikan karakter valid dan hidup
    if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
        return
    end

    if settings.Enabled then
        -- Nonaktifkan rotasi otomatis bawaan Roblox
        humanoid.AutoRotate = false
        
        -- Buat karakter menghadap ke arah kamera (hanya pada sumbu horizontal)
        local cameraLookVector = Camera.CFrame.LookVector
        local lookAtPosition = rootPart.Position + Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z)
        
        -- Atur CFrame karakter agar melihat ke posisi tersebut
        rootPart.CFrame = CFrame.new(rootPart.Position, lookAtPosition)
    else
        -- Jika dinonaktifkan, kembalikan rotasi otomatis ke pengaturan default
        if humanoid.AutoRotate == false then
            humanoid.AutoRotate = true
        end
    end
end

--// =============================================================================================
--// =                                   PEMBUATAN GUI                                           =
--// =============================================================================================

--// Fungsi untuk membuat tombol toggle
function ShiftLock:CreateGUI()
    -- Hapus GUI lama jika ada
    if guiElements.ScreenGui then
        guiElements.ScreenGui:Destroy()
    end

    -- Buat ScreenGui
    local ScreenGui = Instance.new("ScreenGui", CoreGui or LocalPlayer:WaitForChild("PlayerGui"))
    ScreenGui.Name = "SimpleShiftLockGUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.ResetOnSpawn = false
    guiElements.ScreenGui = ScreenGui

    -- Buat Tombol Toggle
    local ToggleButton = Instance.new("TextButton", ScreenGui)
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 130, 0, 40)
    ToggleButton.Position = UDim2.new(0.5, -65, 1, -60)
    ToggleButton.Font = Enum.Font.GothamSemibold
    ToggleButton.TextSize = 16
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.AutoButtonColor = false
    ToggleButton.Active = true
    ToggleButton.Draggable = true -- Agar bisa digeser

    local corner = Instance.new("UICorner", ToggleButton)
    corner.CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", ToggleButton)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    
    guiElements.ToggleButton = ToggleButton

    -- Fungsi untuk memperbarui tampilan tombol
    local function updateButtonVisuals()
        if settings.Enabled then
            ToggleButton.Text = "Shift Lock: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(88, 175, 96) -- Hijau (ON)
        else
            ToggleButton.Text = "Shift Lock: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(227, 76, 76) -- Merah (OFF)
        end
    end
    
    -- Inisialisasi tampilan tombol
    updateButtonVisuals()

    -- Event saat tombol diklik
    ToggleButton.MouseButton1Click:Connect(function()
        settings.Enabled = not settings.Enabled
        updateButtonVisuals()
    end)
end

--// =============================================================================================
--// =                                   KONEKSI & PEMBERSIHAN                                   =
--// =============================================================================================

--// Fungsi untuk membersihkan semua koneksi dan GUI saat tidak diperlukan lagi
function ShiftLock:Exit()
    -- Kembalikan autorotate ke default jika karakter ada
    if humanoid then
        pcall(function() humanoid.AutoRotate = true end)
    end
    
    -- Putuskan semua koneksi event
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}

    -- Hancurkan GUI
    if guiElements.ScreenGui then
        guiElements.ScreenGui:Destroy()
    end
    guiElements = {}
    
    -- Hapus dari environment global
    getgenv().SimpleShiftLock = nil
end

--// Fungsi untuk menangani saat karakter pemain respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    
    -- Atur ulang keadaan AutoRotate jika diperlukan
    if humanoid and not settings.Enabled then
        humanoid.AutoRotate = true
    end
end

--// Hubungkan semua event yang diperlukan
connections.RenderStepped = RunService.RenderStepped:Connect(UpdateShiftLock)
connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

--// Buat GUI saat skrip pertama kali dijalankan
ShiftLock:CreateGUI()