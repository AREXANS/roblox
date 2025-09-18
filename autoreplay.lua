--[[
    Nama Skrip: AutoReplay.lua (Versi 3)
    Deskripsi: Merekam dan memutar ulang pergerakan karakter dengan antarmuka yang modern.
    Perbaikan v3:
    - Perekaman kini mencakup data animasi (AnimationId dan TimePosition) yang sedang berjalan.
    - Pemutaran ulang menyinkronkan CFrame dan Animasi secara bersamaan untuk gerakan yang sangat halus dan tidak kaku.
    - Logika pemutaran ulang dirombak total menggunakan RunService.Heartbeat untuk presisi tinggi.
]]

-- Mencegah GUI dibuat berulang kali jika skrip dieksekusi lebih dari sekali.
if game:GetService("CoreGui"):FindFirstChild("AutoReplayGUI") then
    game:GetService("CoreGui"):FindFirstChild("AutoReplayGUI"):Destroy()
end

-- ====================================================================
-- == LAYANAN DAN VARIABEL GLOBAL                                    ==
-- ====================================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Variabel Status
local isRecording = false
local isPlaying = false
local recordingConnection = nil
local playbackConnection = nil

-- Penyimpanan Data
local savedRecordings = {}
local currentRecordingData = {}
local loadedRecordingName = nil

-- ====================================================================
-- == FUNGSI BANTUAN (UTILITIES)                                     ==
-- ====================================================================

-- Fungsi untuk membuat jendela GUI dapat digeser
local function MakeDraggable(guiObject, dragHandle)
    local isDragging = false
    local dragStartMousePos, startObjectPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartMousePos = input.Position
            startObjectPos = guiObject.Position

            local inputChangedConnection, inputEndedConnection
            inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInput)
                if changedInput.UserInputType == input.UserInputType and isDragging then
                    local delta = changedInput.Position - dragStartMousePos
                    guiObject.Position = UDim2.new(startObjectPos.X.Scale, startObjectPos.X.Offset + delta.X, startObjectPos.Y.Scale, startObjectPos.Y.Offset + delta.Y)
                end
            end)
            inputEndedConnection = UserInputService.InputEnded:Connect(function(endedInput)
                if endedInput.UserInputType == input.UserInputType then
                    isDragging = false
                    if inputChangedConnection then inputChangedConnection:Disconnect() end
                    if inputEndedConnection then inputEndedConnection:Disconnect() end
                end
            end)
        end
    end)
end

-- ====================================================================
-- == PEMBUATAN ANTARMUKA PENGGUNA (GUI)                             ==
-- ====================================================================

local RecordingsListFrame, StatusLabel

local function updateRecordingsList()
    for _, child in ipairs(RecordingsListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local sortedNames = {}
    for name in pairs(savedRecordings) do table.insert(sortedNames, name) end
    table.sort(sortedNames)

    for _, recName in ipairs(sortedNames) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Name = recName
        itemFrame.Size = UDim2.new(1, 0, 0, 28)
        itemFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        itemFrame.BackgroundTransparency = (loadedRecordingName == recName) and 0 or 0.3
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = RecordingsListFrame
        local itemCorner = Instance.new("UICorner", itemFrame); itemCorner.CornerRadius = UDim.new(0, 4)

        local itemLayout = Instance.new("UIListLayout", itemFrame)
        itemLayout.FillDirection = Enum.FillDirection.Horizontal
        itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        itemLayout.Padding = UDim.new(0, 5)

        local nameButton = Instance.new("TextButton")
        nameButton.Size = UDim2.new(1, -65, 1, 0)
        nameButton.BackgroundTransparency = 1
        nameButton.Font = (loadedRecordingName == recName) and Enum.Font.SourceSansBold or Enum.Font.SourceSans
        nameButton.Text = recName
        nameButton.TextColor3 = (loadedRecordingName == recName) and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(220, 220, 220)
        nameButton.TextSize = 13
        nameButton.TextXAlignment = Enum.TextXAlignment.Left
        nameButton.Parent = itemFrame
        local namePadding = Instance.new("UIPadding", nameButton); namePadding.PaddingLeft = UDim.new(0, 8)

        local renameButton = Instance.new("TextButton")
        renameButton.Size = UDim2.new(0, 25, 0, 22)
        renameButton.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
        renameButton.Font = Enum.Font.SourceSansBold
        renameButton.Text = "✏️"
        renameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        renameButton.TextSize = 14
        renameButton.Parent = itemFrame
        local renameCorner = Instance.new("UICorner", renameButton); renameCorner.CornerRadius = UDim.new(0, 4)

        local deleteButton = Instance.new("TextButton")
        deleteButton.Size = UDim2.new(0, 25, 0, 22)
        deleteButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        deleteButton.Font = Enum.Font.SourceSansBold
        deleteButton.Text = "🗑️"
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteButton.TextSize = 14
        deleteButton.Parent = itemFrame
        local deleteCorner = Instance.new("UICorner", deleteButton); deleteCorner.CornerRadius = UDim.new(0, 4)

        nameButton.MouseButton1Click:Connect(function()
            loadedRecordingName = recName
            StatusLabel.Text = "Memuat: " .. recName
            updateRecordingsList()
        end)
        
        renameButton.MouseButton1Click:Connect(function()
            local box = Instance.new("TextBox")
            box.Text = recName
            box.ClearTextOnFocus = false
            
            game.StarterGui:SetCore("SendNotification", {
                Title = "Ganti Nama", Text = "Masukkan nama baru:", Duration = 15, Button1 = "Simpan", Button2 = "Batal",
                Callback = function(action)
                    if action == "Button1" then
                        local newName = box.Text
                        if newName and newName ~= "" and not savedRecordings[newName] then
                            savedRecordings[newName] = savedRecordings[recName]
                            savedRecordings[recName] = nil
                            if loadedRecordingName == recName then loadedRecordingName = newName end
                            StatusLabel.Text = "Nama diubah menjadi " .. newName
                            updateRecordingsList()
                        else
                            StatusLabel.Text = "Nama tidak valid atau sudah ada."
                        end
                    end
                end,
                TextBox = box
            })
        end)
        
        deleteButton.MouseButton1Click:Connect(function()
            savedRecordings[recName] = nil
            if loadedRecordingName == recName then loadedRecordingName = nil end
            StatusLabel.Text = "Menghapus: " .. recName
            updateRecordingsList()
        end)
    end
end

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoReplayGUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 280, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.5
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    local MainCorner = Instance.new("UICorner", MainFrame); MainCorner.CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = Color3.fromRGB(0, 150, 255); MainStroke.Thickness = 2; MainStroke.Transparency = 0.5

    local TitleBar = Instance.new("TextButton")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    TitleBar.Text = ""
    TitleBar.AutoButtonColor = false
    TitleBar.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Text = "Auto Replay"
    TitleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Parent = TitleBar
    
    MakeDraggable(MainFrame, TitleBar)

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -40)
    ContentFrame.Position = UDim2.new(0, 10, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    local ContentLayout = Instance.new("UIListLayout", ContentFrame); ContentLayout.Padding = UDim.new(0, 10); ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local ControlButtonsFrame = Instance.new("Frame")
    ControlButtonsFrame.Name = "ControlButtonsFrame"
    ControlButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
    ControlButtonsFrame.BackgroundTransparency = 1
    ControlButtonsFrame.LayoutOrder = 1
    ControlButtonsFrame.Parent = ContentFrame
    local ControlLayout = Instance.new("UIListLayout", ControlButtonsFrame)
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.Padding = UDim.new(0, 5)

    local RecordButton = Instance.new("TextButton", ControlButtonsFrame)
    RecordButton.Name = "RecordButton"; RecordButton.Size = UDim2.new(0.33, -5, 1, 0); RecordButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50); RecordButton.Font = Enum.Font.SourceSansBold
    RecordButton.Text = "Rekam"; RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255); RecordButton.TextSize = 13
    local recCorner = Instance.new("UICorner", RecordButton); recCorner.CornerRadius = UDim.new(0, 5)

    local StopButton = Instance.new("TextButton", ControlButtonsFrame)
    StopButton.Name = "StopButton"; StopButton.Size = UDim2.new(0.33, -5, 1, 0); StopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50); StopButton.Font = Enum.Font.SourceSansBold
    StopButton.Text = "Stop"; StopButton.TextColor3 = Color3.fromRGB(255, 255, 255); StopButton.TextSize = 13
    local stopCorner = Instance.new("UICorner", StopButton); stopCorner.CornerRadius = UDim.new(0, 5)

    local PlayButton = Instance.new("TextButton", ControlButtonsFrame)
    PlayButton.Name = "PlayButton"; PlayButton.Size = UDim2.new(0.33, -5, 1, 0); PlayButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255); PlayButton.Font = Enum.Font.SourceSansBold
    PlayButton.Text = "Putar"; PlayButton.TextColor3 = Color3.fromRGB(255, 255, 255); PlayButton.TextSize = 13
    local playCorner = Instance.new("UICorner", PlayButton); playCorner.CornerRadius = UDim.new(0, 5)

    local ReplayOptionsFrame = Instance.new("Frame")
    ReplayOptionsFrame.Name = "ReplayOptionsFrame"; ReplayOptionsFrame.Size = UDim2.new(1, 0, 0, 25); ReplayOptionsFrame.BackgroundTransparency = 1
    ReplayOptionsFrame.LayoutOrder = 2; ReplayOptionsFrame.Parent = ContentFrame
    local ReplayOptionsLayout = Instance.new("UIListLayout", ReplayOptionsFrame); ReplayOptionsLayout.FillDirection = Enum.FillDirection.Horizontal; ReplayOptionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local ReplayLabel = Instance.new("TextLabel", ReplayOptionsFrame)
    ReplayLabel.Name = "ReplayLabel"; ReplayLabel.Size = UDim2.new(0.7, -5, 1, 0); ReplayLabel.BackgroundTransparency = 1; ReplayLabel.Font = Enum.Font.SourceSans
    ReplayLabel.Text = "Jumlah Ulang (kosong/0 = ∞):"; ReplayLabel.TextColor3 = Color3.fromRGB(200, 200, 200); ReplayLabel.TextSize = 12; ReplayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ReplayCountBox = Instance.new("TextBox", ReplayOptionsFrame)
    ReplayCountBox.Name = "ReplayCountBox"; ReplayCountBox.Size = UDim2.new(0.3, 0, 1, 0); ReplayCountBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35); ReplayCountBox.Font = Enum.Font.SourceSans
    ReplayCountBox.Text = "1"; ReplayCountBox.PlaceholderText = "1"; ReplayCountBox.TextColor3 = Color3.fromRGB(220, 220, 220); ReplayCountBox.TextSize = 12; ReplayCountBox.ClearTextOnFocus = false
    local boxCorner = Instance.new("UICorner", ReplayCountBox); boxCorner.CornerRadius = UDim.new(0, 4)
    ReplayCountBox:GetPropertyChangedSignal("Text"):Connect(function() ReplayCountBox.Text = ReplayCountBox.Text:gsub("%D", "") end)

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"; StatusLabel.Size = UDim2.new(1, 0, 0, 20); StatusLabel.BackgroundTransparency = 1; StatusLabel.Font = Enum.Font.SourceSansItalic
    StatusLabel.Text = "Siap."; StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180); StatusLabel.TextSize = 12; StatusLabel.LayoutOrder = 3; StatusLabel.Parent = ContentFrame

    RecordingsListFrame = Instance.new("ScrollingFrame")
    RecordingsListFrame.Name = "RecordingsListFrame"; RecordingsListFrame.Size = UDim2.new(1, 0, 1, -135); RecordingsListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    RecordingsListFrame.BackgroundTransparency = 0.5; RecordingsListFrame.BorderSizePixel = 0; RecordingsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    RecordingsListFrame.ScrollBarThickness = 6; RecordingsListFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255); RecordingsListFrame.LayoutOrder = 4; RecordingsListFrame.Parent = ContentFrame
    
    local listLayout = Instance.new("UIListLayout", RecordingsListFrame); listLayout.Padding = UDim.new(0, 5); listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; listLayout.SortOrder = Enum.SortOrder.Name
    local listPadding = Instance.new("UIPadding", RecordingsListFrame); listPadding.PaddingTop = UDim.new(0, 5); listPadding.PaddingBottom = UDim.new(0, 5)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() RecordingsListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10) end)

    return RecordButton, StopButton, PlayButton, ReplayCountBox
end

-- ====================================================================
-- == FUNGSI INTI (REKAM & PUTAR ULANG)                              ==
-- ====================================================================

function startRecording()
    if isRecording then return end
    if isPlaying then StatusLabel.Text = "Tidak bisa merekam saat memutar ulang."; return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and humanoid) then StatusLabel.Text = "Karakter/Humanoid tidak ditemukan."; return end

    isRecording = true
    currentRecordingData = {}
    local startTime = tick()
    StatusLabel.Text = "Merekam... 🔴"

    recordingConnection = RunService.Heartbeat:Connect(function()
        if not isRecording then return end
        
        local playingAnims = {}
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            table.insert(playingAnims, {
                id = track.Animation.AnimationId,
                time = track.TimePosition
            })
        end

        table.insert(currentRecordingData, {
            time = tick() - startTime,
            cframe = hrp.CFrame,
            anims = playingAnims
        })
    end)
end

function stopActions()
    if isRecording then
        isRecording = false
        if recordingConnection then recordingConnection:Disconnect(); recordingConnection = nil end

        if #currentRecordingData > 1 then
            local newName, i = "Rekaman 1", 1
            while savedRecordings[newName] do i += 1; newName = "Rekaman " .. i end
            savedRecordings[newName] = currentRecordingData
            StatusLabel.Text = "Rekaman disimpan sebagai: " .. newName
            updateRecordingsList()
        else
            StatusLabel.Text = "Perekaman dibatalkan (terlalu singkat)."
        end
        currentRecordingData = {}
    end

    if isPlaying then
        isPlaying = false
        if playbackConnection then playbackConnection:Disconnect(); playbackConnection = nil end
        -- Pembersihan akan dilakukan oleh koneksi itu sendiri saat isPlaying = false
        StatusLabel.Text = "Pemutaran ulang dihentikan."
    end
end

function playRecording(replayCountBox)
    if isPlaying then return end
    if isRecording then StatusLabel.Text = "Hentikan perekaman terlebih dahulu."; return end
    if not loadedRecordingName or not savedRecordings[loadedRecordingName] then StatusLabel.Text = "Pilih rekaman untuk diputar."; return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and humanoid) then StatusLabel.Text = "Karakter/Humanoid tidak ditemukan."; return end

    local recording = savedRecordings[loadedRecordingName]
    if #recording < 2 then StatusLabel.Text = "Rekaman tidak valid."; return end

    local countText = replayCountBox.Text
    local replayCount = tonumber(countText)
    if countText == "" or countText == "0" then replayCount = math.huge
    elseif not replayCount or replayCount < 1 then replayCount = 1 end

    isPlaying = true
    local originalPlatformStand = humanoid.PlatformStand
    humanoid.PlatformStand = true -- Kunci untuk menimpa animasi

    local animationCache = {}
    local currentLoop = 1
    local loopStartTime = tick()
    local recordingDuration = recording[#recording].time
    local lastFrameIndex = 1

    playbackConnection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            humanoid.PlatformStand = originalPlatformStand
            for _, track in pairs(animationCache) do track:Stop(0.1) end
            playbackConnection:Disconnect()
            playbackConnection = nil
            return
        end

        local elapsedTime = tick() - loopStartTime
        if elapsedTime > recordingDuration then
            currentLoop = currentLoop + 1
            if currentLoop > replayCount then
                isPlaying = false -- Ini akan memicu pembersihan pada frame berikutnya
                StatusLabel.Text = "Pemutaran selesai."
                return
            end
            loopStartTime = tick()
            elapsedTime = 0
            lastFrameIndex = 1
            StatusLabel.Text = string.format("Memutar: %s (%d/%s)", loadedRecordingName, currentLoop, tostring(replayCount) == "inf" and "∞" or replayCount)
        end

        -- Cari frame saat ini
        local currentFrame, nextFrame
        for i = lastFrameIndex, #recording do
            if recording[i].time >= elapsedTime then
                nextFrame = recording[i]
                currentFrame = recording[i-1] or recording[1]
                lastFrameIndex = i
                break
            end
        end
        if not nextFrame then return end -- Akhir dari data

        -- Interpolasi CFrame
        local alpha = (elapsedTime - currentFrame.time) / (nextFrame.time - currentFrame.time)
        alpha = math.clamp(alpha, 0, 1)
        hrp.CFrame = currentFrame.cframe:Lerp(nextFrame.cframe, alpha)
        
        -- Kelola Animasi
        local requiredAnims = {}
        for _, animData in ipairs(currentFrame.anims) do
            requiredAnims[animData.id] = animData.time
            if not animationCache[animData.id] then
                local anim = Instance.new("Animation")
                anim.AnimationId = animData.id
                animationCache[animData.id] = humanoid:LoadAnimation(anim)
            end
            local track = animationCache[animData.id]
            if not track.IsPlaying then track:Play(0.1, 1, 1) end
            track:AdjustSpeed(1)
            -- Menyesuaikan TimePosition secara paksa memastikan sinkronisasi
            track.TimePosition = animData.time
        end

        -- Hentikan animasi yang tidak diperlukan lagi
        for id, track in pairs(animationCache) do
            if not requiredAnims[id] and track.IsPlaying then
                track:Stop(0.1)
            end
        end
    end)
end

-- ====================================================================
-- == INISIALISASI                                                   ==
-- ====================================================================

local recordBtn, stopBtn, playBtn, replayCount = createGUI()
recordBtn.MouseButton1Click:Connect(startRecording)
stopBtn.MouseButton1Click:Connect(stopActions)
playBtn.MouseButton1Click:Connect(function() playRecording(replayCount) end)
