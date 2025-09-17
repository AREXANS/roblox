local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TopBar = Instance.new("Frame")
local TopBarCorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")
local ExecuteButton = Instance.new("TextButton")
local UnflingButton = Instance.new("TextButton")
local UsernameBox = Instance.new("TextBox")
local ButtonCorner = Instance.new("UICorner")
-- Add these after your existing buttons



ScreenGui.Name = "FlingUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
MainFrame.Size = UDim2.new(0, 250, 0.1, 250)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.Parent = MainFrame
UICorner.CornerRadius = UDim.new(0, 6)

TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TopBar.Size = UDim2.new(1, 0, 0, 30)

TopBarCorner.Parent = TopBar
TopBarCorner.CornerRadius = UDim.new(0, 6)

Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Fling UI by Porn Hub Production"
Title.TextColor3 = Color3.fromRGB(255, 90, 0)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

UsernameBox.Name = "UsernameBox"
UsernameBox.Parent = MainFrame
UsernameBox.BackgroundColor3 = Color3.fromRGB(255, 90, 0)
UsernameBox.Position = UDim2.new(0.5, -75, 0.3, 0)
UsernameBox.Size = UDim2.new(0, 150, 0, 30)
UsernameBox.Font = Enum.Font.GothamBold
UsernameBox.PlaceholderText = "Enter Username"
UsernameBox.Text = ""
UsernameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameBox.TextSize = 14

ExecuteButton.Name = "ExecuteButton"
ExecuteButton.Parent = MainFrame
ExecuteButton.BackgroundColor3 = Color3.fromRGB(255, 90, 0)
ExecuteButton.Position = UDim2.new(0.5, -75, 0.5, 0)
ExecuteButton.Size = UDim2.new(0, 150, 0, 40)
ExecuteButton.Font = Enum.Font.GothamBold
ExecuteButton.Text = "Fling"
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.TextSize = 16

UnflingButton.Name = "UnflingButton"
UnflingButton.Parent = MainFrame
UnflingButton.BackgroundColor3 = Color3.fromRGB(255, 90, 0)
UnflingButton.Position = UDim2.new(0.5, -75, 0.7, 0)
UnflingButton.Size = UDim2.new(0, 150, 0, 40)
UnflingButton.Font = Enum.Font.GothamBold
UnflingButton.Text = "Unfling"
UnflingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnflingButton.TextSize = 16

ButtonCorner.Parent = ExecuteButton
ButtonCorner.CornerRadius = UDim.new(0, 6)

local ButtonCorner2 = ButtonCorner:Clone()
ButtonCorner2.Parent = UnflingButton

local ButtonCorner3 = ButtonCorner:Clone()
ButtonCorner3.Parent = UsernameBox

-- Variables for fling control
local isFlingEnabled = false
local flingLoop = nil

-- Button functionality
CloseButton.MouseButton1Click:Connect(function()
    if flingLoop then
        flingLoop:Disconnect()
    end
    ScreenGui:Destroy()
end)

ExecuteButton.MouseButton1Click:Connect(function()
    if not isFlingEnabled then
        isFlingEnabled = true
        
        flingLoop = game:GetService("RunService").Heartbeat:Connect(function()
            local targetUsername = UsernameBox.Text
            if targetUsername ~= "" then
                local Players = game:GetService("Players")
                local Player = Players.LocalPlayer

                local GetPlayer = function(Name)
                    Name = Name:lower()
                    for _, x in next, Players:GetPlayers() do
                        if x ~= Player then
                            if x.Name:lower():match("^"..Name) then
                                return x
                            elseif x.DisplayName:lower():match("^"..Name) then
                                return x
                            end
                        end
                    end
                    return nil
                end

                local Message = function(_Title, _Text, Time)
                    game:GetService("StarterGui"):SetCore("SendNotification", {Title = _Title, Text = _Text, Duration = Time})
                end

                local SkidFling = function(TargetPlayer)
                    local Character = Player.Character
                    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                    local RootPart = Humanoid and Humanoid.RootPart

                    local TCharacter = TargetPlayer.Character
                    local THumanoid
                    local TRootPart
                    local THead
                    local Accessory
                    local Handle

                    if TCharacter:FindFirstChildOfClass("Humanoid") then
                        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
                    end
                    if THumanoid and THumanoid.RootPart then
                        TRootPart = THumanoid.RootPart
                    end
                    if TCharacter:FindFirstChild("Head") then
                        THead = TCharacter.Head
                    end
                    if TCharacter:FindFirstChildOfClass("Accessory") then
                        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
                    end
                    if Accessory and Accessory:FindFirstChild("Handle") then
                        Handle = Accessory.Handle
                    end

                    if Character and Humanoid and RootPart then
                        if RootPart.Velocity.Magnitude < 50 then
                            getgenv().OldPos = RootPart.CFrame
                        end
                        if THumanoid and THumanoid.Sit then
                            return Message("Error Occurred", "Target is sitting", 5)
                        end
                        if THead then
                            workspace.CurrentCamera.CameraSubject = THead
                        elseif not THead and Handle then
                            workspace.CurrentCamera.CameraSubject = Handle
                        elseif THumanoid and TRootPart then
                            workspace.CurrentCamera.CameraSubject = THumanoid
                        end
                        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
                            return
                        end
                        
                        local FPos = function(BasePart, Pos, Ang)
                            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                        end
                        
                        local SFBasePart = function(BasePart)
                            local TimeToWait = 2
                            local Time = tick()
                            local Angle = 0

                            repeat
                                if RootPart and THumanoid then
                                    if BasePart.Velocity.Magnitude < 50 then
                                        Angle = Angle + 100

                                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                                        task.wait()
                                    else
                                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                                        task.wait()
                                        
                                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                                        task.wait()

                                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                                        task.wait()
                                    end
                                else
                                    break
                                end
                            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
                        end
                        
                        workspace.FallenPartsDestroyHeight = 0/0
                        
                        local BV = Instance.new("BodyVelocity")
                        BV.Name = "EpixVel"
                        BV.Parent = RootPart
                        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
                        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
                        
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                        
                        if TRootPart and THead then
                            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                                SFBasePart(THead)
                            else
                                SFBasePart(TRootPart)
                            end
                        elseif TRootPart and not THead then
                            SFBasePart(TRootPart)
                        elseif not TRootPart and THead then
                            SFBasePart(THead)
                        elseif not TRootPart and not THead and Accessory and Handle then
                            SFBasePart(Handle)
                        else

                        end
                        
                        BV:Destroy()
                        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                        workspace.CurrentCamera.CameraSubject = Humanoid
                        
                        repeat
                            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                            Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                            Humanoid:ChangeState("GettingUp")
                            table.foreach(Character:GetChildren(), function(_, x)
                                if x:IsA("BasePart") then
                                    x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                                end
                            end)
                            task.wait()
                        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
                        workspace.FallenPartsDestroyHeight = getgenv().FPDH
                    else
                    end
                end

                local targetPlayer = GetPlayer(targetUsername)
                if targetPlayer then
                    SkidFling(targetPlayer)
                end
            end
        end)
    end
end)

UnflingButton.MouseButton1Click:Connect(function()
    if isFlingEnabled then
        isFlingEnabled = false
        if flingLoop then
            flingLoop:Disconnect()
            flingLoop = nil
        end
        
        local Player = game:GetService("Players").LocalPlayer
        local Character = Player.Character
        if Character and getgenv().OldPos then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local RootPart = Humanoid and Humanoid.RootPart
            
            if RootPart then
                RootPart.CFrame = getgenv().OldPos
                Character:SetPrimaryPartCFrame(getgenv().OldPos)
                Humanoid:ChangeState("GettingUp")
            end
        end
    end
end)
