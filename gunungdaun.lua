-- LocalScript / Executor
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local coreGui = game:GetService("CoreGui")

-- Variabel kontrol
local isHidden = true
local isFlying = false
local originalWalkspeed = hum.WalkSpeed
local runSpeed = 100
local flySpeed = 50 
local flyConnection = nil

-- GUI
local screenGui = Instance.new("ScreenGui", coreGui)
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

-- Tombol hapus (X)
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0,25,0,25)
closeBtn.Position = UDim2.new(1,-25,0,0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,5)

-- Tombol minimize
local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0,30,0,25)
minBtn.Position = UDim2.new(1,-55,0,0)
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
speedLabel.Text = "Walkspeed:"
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 16

-- Kotak input teks untuk kecepatan
local speedInput = Instance.new("TextBox", frame)
speedInput.Size = UDim2.new(1,-40,0,30)
speedInput.Position = UDim2.new(0,20,0,50)
speedInput.PlaceholderText = "Masukkan kecepatan..."
speedInput.Text = tostring(runSpeed)
speedInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
speedInput.TextColor3 = Color3.new(1,1,1)
speedInput.Font = Enum.Font.SourceSans
speedInput.TextSize = 16
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0,8)

-- Tombol untuk menerapkan kecepatan baru
local applySpeedBtn = Instance.new("TextButton", frame)
applySpeedBtn.Size = UDim2.new(1, -40, 0, 30)
applySpeedBtn.Position = UDim2.new(0, 20, 0, 85)
applySpeedBtn.Text = "Apply Speed"
applySpeedBtn.TextColor3 = Color3.new(1, 1, 1)
applySpeedBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
applySpeedBtn.Font = Enum.Font.SourceSans
applySpeedBtn.TextSize = 16
Instance.new("UICorner", applySpeedBtn).CornerRadius = UDim.new(0, 8)

applySpeedBtn.MouseButton1Click:Connect(function()
    local newSpeed = tonumber(speedInput.Text)
    if newSpeed and newSpeed > 0 then
        runSpeed = newSpeed
        hum.WalkSpeed = runSpeed
    else
        warn("Kecepatan yang dimasukkan tidak valid.")
    end
end)

-- Tombol toggle terbang
local flyBtn = createToggle("Toggle Fly", 125, function()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    if not isFlying then
        isFlying = true
        flyBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
        
        -- Matikan gravitasi, atur kecepatan humanoid ke 0
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.PlatformStand = true
        
        flyConnection = runService.RenderStepped:Connect(function()
            local moveVector = Vector3.new(0,0,0)
            local yDir = 0
            
            if uis:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0,0,-1) end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0,0,1) end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(1,0,0) end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(-1,0,0) end
            
            if uis:IsKeyDown(Enum.KeyCode.Space) then yDir = yDir + 1 end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then yDir = yDir - 1 end
            
            -- Pergerakan CFrame yang halus
            local movement = hrp.CFrame:VectorToWorldSpace(moveVector) * flySpeed + Vector3.new(0, yDir * flySpeed, 0)
            hrp.CFrame = hrp.CFrame + movement * runService.RenderStepped:GetDt()
        end)
    else
        isFlying = false
        flyBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        
        -- Aktifkan kembali gravitasi dan kembalikan kontrol ke Humanoid
        hum.WalkSpeed = runSpeed
        hum.JumpPower = 50
        hum.PlatformStand = false
        
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

-- Tombol hapus
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Logika minimize
minBtn.MouseButton1Click:Connect(function()
    for i, v in pairs(frame:GetChildren()) do
        if v ~= title and v ~= minBtn and v ~= closeBtn then
            v.Visible = not v.Visible
        end
    end
end)
