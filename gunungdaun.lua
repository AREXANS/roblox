-- LocalScript / Executor
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")

-- Variabel kontrol
local isHidden = true
local isFlying = false
local flySpeed = 50 -- Atur kecepatan terbang di sini
local originalWalkspeed = hum.WalkSpeed -- Simpan kecepatan lari asli
local flyConnection = nil

-- GUI
local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
screenGui.Name = "Simple_GUI_"..math.random(1000,9999)

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

-- Frame utama GUI, awalnya tersembunyi
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,250,0,120)
frame.Position = UDim2.new(0,20,0.5,-60)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Judul + draggable
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Simple Cheats"
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

-- Fungsi tombol
local function createToggle(text, posY, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-40,0,30)
    btn.Position = UDim2.new(0,20,0,posY)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Tombol Kecepatan Lari
createToggle("Toggle Speed", 40, function()
    if hum.WalkSpeed == originalWalkspeed then
        hum.WalkSpeed = 100 -- Atur kecepatan lari yang diinginkan di sini
    else
        hum.WalkSpeed = originalWalkspeed
    end
end)

-- Fungsi untuk terbang
local function toggleFly()
    if not isFlying then
        isFlying = true
        hum.WalkSpeed = flySpeed
        hum.JumpPower = 0
        hum:ChangeState(Enum.HumanoidStateType.Flying)
        flyConnection = uis.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
                char.PrimaryPart.CFrame = char.PrimaryPart.CFrame + char.PrimaryPart.CFrame.lookVector * flySpeed * 0.1
            end
        end)
    else
        isFlying = false
        hum.WalkSpeed = originalWalkspeed
        hum.JumpPower = 50 -- Atur ulang kekuatan lompat asli
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
end

-- Tombol Terbang
createToggle("Toggle Fly", 80, function()
    toggleFly()
end)

-- LOGIKA UNTUK MENAMPILKAN/MENYEMBUNYIKAN GUI
local startPos = frame.Position
toggleBtn.MouseButton1Click:Connect(function()
    isHidden = not isHidden
    if not isHidden then
        frame.Visible = true
        frame.Position = startPos + UDim2.new(0, 0, 0, 20)
        local tweenIn = tweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = startPos})
        tweenIn:Play()
    else
        local tweenOut = tweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = startPos + UDim2.new(0, 0, 0, 20)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            frame.Visible = false
        end)
    end
end)

-- LOGIKA BARU UNTUK MEMBUAT GUI DAPAT DIGESER
local dragging = false
local dragInput, mousePos, framePos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = frame.Position
    end
end)
title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
uis.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Logika minimize
minBtn.MouseButton1Click:Connect(function()
    for i, v in pairs(frame:GetChildren()) do
        if v ~= title and v ~= minBtn then
            v.Visible = not v.Visible
        end
    end
end)
