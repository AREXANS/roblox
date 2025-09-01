-- LocalScript / Executor
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local flyBodyVelocity = nil -- Kita akan menggunakan ini untuk mode terbang

-- Variabel kontrol
local isHidden = true
local isFlying = false
local originalWalkspeed = hum.WalkSpeed
local runSpeed = 100
local flySpeed = 50 
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
frame.Size = UDim2.new(0,250,0,180)
frame.Position = UDim2.new(0,20,0.5,-90)
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

-- Tombol minimize
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

-- Label kecepatan
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size = UDim2.new(1,-40,0,20)
speedLabel.Position = UDim2.new(0,20,0,30)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Walkspeed: "..runSpeed
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 16

-- Slider kecepatan
local speedSlider = Instance.new("Frame", frame)
speedSlider.Size = UDim2.new(1,-40,0,20)
speedSlider.Position = UDim2.new(0,20,0,50)
speedSlider.BackgroundColor3 = Color3.fromRGB(40,40,40)
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(0,8)

local speedSliderBar = Instance.new("Frame", speedSlider)
speedSliderBar.Size = UDim2.new(0.5,0,1,0)
speedSliderBar.Position = UDim2.new(0,0,0,0)
speedSliderBar.BackgroundColor3 = Color3.fromRGB(0,150,255)
Instance.new("UICorner", speedSliderBar).CornerRadius = UDim.new(0,8)

local speedSliderHandle = Instance.new("TextButton", speedSlider)
speedSliderHandle.Size = UDim2.new(0,20,1,0)
speedSliderHandle.Position = UDim2.new(0.5, -10, 0,0)
speedSliderHandle.BackgroundColor3 = Color3.new(1,1,1)
speedSliderHandle.Text = ""
Instance.new("UICorner", speedSliderHandle).CornerRadius = UDim.new(0,8)

-- Fungsi slider
local draggingSlider = false
local function updateSpeed(input)
    local x = input.Position.X - speedSlider.AbsolutePosition.X
    local percent = math.clamp(x / speedSlider.AbsoluteSize.X, 0, 1)
    runSpeed = 10 + percent * 400 -- Kecepatan dari 10 sampai 410
    speedSliderHandle.Position = UDim2.new(percent, -10, 0, 0)
    speedSliderBar.Size = UDim2.new(percent,0,1,0)
    speedLabel.Text = "Walkspeed: "..math.floor(runSpeed)
    if hum.WalkSpeed ~= originalWalkspeed then
        hum.WalkSpeed = runSpeed
    end
end
speedSliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
    end
end)
uis.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSpeed(input)
    end
end)
uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
    end
end)

-- Tombol toggle kecepatan
local speedBtn = createToggle("Toggle Speed", 80, function()
    if hum.WalkSpeed == originalWalkspeed then
        hum.WalkSpeed = runSpeed
        speedBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
    else
        hum.WalkSpeed = originalWalkspeed
        speedBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    end
end)

-- Tombol toggle terbang
local flyBtn = createToggle("Toggle Fly", 120, function()
    if not isFlying then
        isFlying = true
        flyBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
        
        -- Mengatur kecepatan humanoid ke 0 agar pergerakan tidak bentrok
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        
        -- Membuat BodyVelocity untuk pergerakan halus
        local hrp = char:WaitForChild("HumanoidRootPart")
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.P = 1000
        flyBodyVelocity.Parent = hrp

        -- Perulangan untuk mengontrol pergerakan terbang
        flyConnection = runService.Heartbeat:Connect(function()
            local moveVector = Vector3.new(0,0,0)
            if uis:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0,0,-1) end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0,0,1) end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(1,0,0) end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(-1,0,0) end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0,1,0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector + Vector3.new(0,-1,0) end
            
            flyBodyVelocity.Velocity = hrp.CFrame:VectorToWorldSpace(moveVector) * flySpeed
        end)
    else
        isFlying = false
        flyBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        
        -- Hapus BodyVelocity dan kembalikan kontrol ke Humanoid
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        hum.WalkSpeed = originalWalkspeed
        hum.JumpPower = 50
        hum:ChangeState(Enum.HumanoidStateType.Jumping) -- Mengembalikan keadaan normal
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
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

-- LOGIKA UNTUK MEMBUAT GUI DAPAT DIGESER
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
