-- LocalScript / Executor
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

-- Daftar checkpoint Gunung Daun
local checkpoints = {
    Vector3.new(-7, 13, -10),       -- Basecamp
    Vector3.new(-623, 250, -384),   -- Pos 1
    Vector3.new(-1204, 261, -488),  -- Pos 2
    Vector3.new(-1399, 578, -951),  -- Pos 3
    Vector3.new(-1701, 816, -1400), -- Pos 4
    Vector3.new(-3237, 1710, -2549) -- Puncak
}

-- Variabel kontrol
local autoTeleport = false
local teleportDelay = 1
local currentIndex = 1
local paused = false
local loopEnabled = false
local antiFallEnabled = true

-- GUI
local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
screenGui.Name = "AutoTP_GUI_"..math.random(1000,9999)

-- Frame utama GUI, awalnya tersembunyi
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,270,0,420)
frame.Position = UDim2.new(0,20,0.5,-210)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Visible = false -- Sembunyikan frame secara default
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Tombol kecil untuk menampilkan/menyembunyikan GUI
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0, 80, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.Text = "Menu"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Judul + draggable
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Gunung Daun Teleport"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

-- Tombol Minimize
local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0,30,0,25)
minBtn.Position = UDim2.new(1,-30,0,0)
minBtn.Text = "_"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0,5)

-- Tombol Close
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0,30,0,25)
closeBtn.Position = UDim2.new(1,-60,0,0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,5)

-- Fungsi tombol utama
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for i, v in pairs(frame:GetChildren()) do
        if v ~= title and v ~= minBtn and v ~= closeBtn and v ~= currentCheckpointLabel then
            v.Visible = not minimized
        end
    end
end)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- LOGIKA BARU UNTUK MENAMPILKAN/MENYEMBUNYIKAN GUI DENGAN ANIMASI
local isHidden = true -- Status awal GUI adalah tersembunyi
local startPos = frame.Position -- Simpan posisi awal

toggleBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden -- Ubah status
    if not isHidden then
        -- Tampilkan GUI dengan animasi
        frame.Visible = true
        frame.Position = startPos + UDim2.new(0, 0, 0, 20) -- Geser sedikit ke bawah untuk efek 'pop-up'
        local tweenIn = tweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = startPos})
        tweenIn:Play()
    else
        -- Sembunyikan GUI dengan animasi
        local tweenOut = tweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = startPos + UDim2.new(0, 0, 0, 20)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            frame.Visible = false
        end)
    end
end)

-- Indikator checkpoint terakhir
local currentCheckpointLabel = Instance.new("TextLabel", frame)
currentCheckpointLabel.Size = UDim2.new(1,-10,0,25)
currentCheckpointLabel.Position = UDim2.new(0,5,0,30)
currentCheckpointLabel.BackgroundTransparency = 1
currentCheckpointLabel.TextColor3 = Color3.new(1,1,0)
currentCheckpointLabel.Font = Enum.Font.SourceSansBold
currentCheckpointLabel.TextSize = 16
currentCheckpointLabel.Text = "Current Checkpoint: "..currentIndex

-- Anti-fall damage
local function preventFallDamage(state)
    if hum then
        hum:GetPropertyChangedSignal("Health"):Connect(function()
            if state and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
        hum.StateChanged:Connect(function(_, newState)
            if state and (newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.FallingDown) then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end)
    end
end

-- Teleport smooth
local function teleportTo(location)
    char = player.Character or player.CharacterAdded:Wait()
    hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    local steps = 25
    local startPos = hrp.Position
    local targetPos = location + Vector3.new(0,5,0)
    for i = 1, steps do
        hrp.CFrame = CFrame.new(startPos:Lerp(targetPos, i/steps))
        task.wait(0.05)
    end
end

-- Notifikasi kecil
local function showNotification(text)
    local notifGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    notifGui.ResetOnSpawn = false
    local frameNotif = Instance.new("Frame", notifGui)
    frameNotif.Size = UDim2.new(0,200,0,40)
    frameNotif.Position = UDim2.new(0.5,-100,0.1,0)
    frameNotif.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frameNotif.BorderSizePixel = 0
    Instance.new("UICorner", frameNotif).CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", frameNotif)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    local tween = tweenService:Create(frameNotif, TweenInfo.new(0.5), {Position = frameNotif.Position + UDim2.new(0,0,0.05,0)})
    tween:Play()
    task.delay(2, function()
        local tweenOut = tweenService:Create(frameNotif, TweenInfo.new(0.5), {Position = frameNotif.Position - UDim2.new(0,0,0.05,0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function() notifGui:Destroy() end)
    end)
end

-- Tombol kontrol
local function createButton(text,posY,callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-40,0,30)
    btn.Position = UDim2.new(0,30,0,posY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Tombol utama
createButton("Start Auto Teleport",40,function() autoTeleport = true end)
createButton("Pause Auto Teleport",75,function() paused = true end)
createButton("Resume Auto Teleport",110,function() paused = false end)
createButton("Toggle Auto Loop",145,function() loopEnabled = not loopEnabled showNotification("Auto Loop: "..(loopEnabled and "Enabled" or "Disabled")) end)
createButton("Toggle Anti-Fall",180,function() antiFallEnabled = not antiFallEnabled preventFallDamage(antiFallEnabled) showNotification("Anti-Fall: "..(antiFallEnabled and "Enabled" or "Disabled")) end)

-- Tombol checkpoint + indikator
local checkpointButtons = {}
local checkpointIndicators = {}
local checkpointStatus = {}
local posY = 220
for i,pos in ipairs(checkpoints) do
    local btn = createButton("Teleport to Pos "..i,posY,function()
        currentIndex = i
        teleportTo(pos)
        updateIndicators()
        updateCheckpointLabel()
    end)
    checkpointButtons[i] = btn
    local indicator = Instance.new("Frame", frame)
    indicator.Size = UDim2.new(0,15,0,15)
    indicator.Position = UDim2.new(0,10,0,posY+7)
    indicator.BackgroundColor3 = Color3.fromRGB(255,255,0)
    indicator.Visible = false
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0,8)
    checkpointIndicators[i] = indicator
    checkpointStatus[i] = false
    posY = posY + 35
end

-- Update indikator
function updateIndicators()
    for i, ind in ipairs(checkpointIndicators) do
        if i == currentIndex then
            ind.Visible = true
            ind.BackgroundColor3 = Color3.fromRGB(255,255,0)
        elseif checkpointStatus[i] then
            ind.Visible = true
            ind.BackgroundColor3 = Color3.fromRGB(0,255,0)
        else
            ind.Visible = false
        end
    end
end

-- Kedip indikator
spawn(function()
    while true do
        for i, ind in ipairs(checkpointIndicators) do
            if ind.Visible and ind.BackgroundColor3 == Color3.fromRGB(255,255,0) then
                ind.BackgroundTransparency = 0
                task.wait(0.3)
                ind.BackgroundTransparency = 0.7
                task.wait(0.3)
            end
        end
        task.wait(0.01)
    end
end)

-- Update label
local function updateCheckpointLabel()
    currentCheckpointLabel.Text = "Current Checkpoint: "..currentIndex
end

-- Auto teleport loop
spawn(function()
    while true do
        if autoTeleport and not paused then
            teleportTo(checkpoints[currentIndex])
            checkpointStatus[currentIndex] = true
            updateCheckpointLabel()
            updateIndicators()
            showNotification("Checkpoint "..currentIndex.." reached!")
            currentIndex += 1
            if currentIndex > #checkpoints then
                if loopEnabled then
                    for k in pairs(checkpointStatus) do checkpointStatus[k] = false end
                    currentIndex = 1
                    updateCheckpointLabel()
                    updateIndicators()
                    showNotification("Loop restarted at Basecamp!")
                else
                    autoTeleport = false
                end
            end
        end
        task.wait(teleportDelay)
    end
end)

-- Draggable GUI
local dragging = false
local dragInput, mousePos, framePos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
uis.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Auto-respawn ke checkpoint terakhir
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = char:WaitForChild("Humanoid")
    task.wait(1)
    preventFallDamage(antiFallEnabled)
    teleportTo(checkpoints[currentIndex])
end)

preventFallDamage(antiFallEnabled)
updateIndicators()
