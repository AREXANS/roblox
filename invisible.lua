--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local VERSION = 1.5
print("Made By Mohamedguguu")
print("new update fixed unload not working and fixed speed noclip addad notic and remoed = unload and addad are you sure or not sure unloading")

if _G.InvisGhostLoaded and _G.InvisGhostLoaded >= VERSION then
    return
end
_G.InvisGhostLoaded = VERSION

local Players = game:GetService("Players")
local CoreguiM = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer

local SETTINGS_FOLDER = "FeInvisibleOld"
local SETTINGS_FILE = SETTINGS_FOLDER .. "/ghostspeed.txt"

local function saveSpeed(speed)
    if isfolder and makefolder and writefile then
        if not isfolder(SETTINGS_FOLDER) then
            makefolder(SETTINGS_FOLDER)
        end
        writefile(SETTINGS_FILE, tostring(speed))
    end
end

local function loadSpeed()
    if isfile and readfile and isfile(SETTINGS_FILE) then
        local val = tonumber(readfile(SETTINGS_FILE))
        if val then
            return val
        end
    end
    return 50
end

local invisOn = false
local ghostOn = false
local noclipOn = false
local ghostSpeed = loadSpeed()
local uiHidden = false

local sg = Instance.new("ScreenGui", CoreguiM)
sg.Name = "InvisGhostUI"
sg.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 220, 0, 200)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local function makeButton(text, pos)
    local b = Instance.new("TextButton", mainFrame)
    b.Size = UDim2.new(0, 200, 0, 30)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local invisBtn = makeButton("Toggle Invisibility 👻", UDim2.new(0, 10, 0, 10))
local ghostBtn = makeButton("Toggle Ghost Speed ⚡", UDim2.new(0, 10, 0, 50))
local noclipBtn = makeButton("Toggle Noclip 🚪", UDim2.new(0, 10, 0, 90))
local unloadBtn = makeButton("Unload ❌", UDim2.new(0, 10, 0, 170))

local speedBox = Instance.new("TextBox", mainFrame)
speedBox.Size = UDim2.new(0, 200, 0, 30)
speedBox.Position = UDim2.new(0, 10, 0, 130)
speedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.Text = tostring(ghostSpeed)
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 8)

local function showNotice(txt)
    pcall(function()
        if CoreguiM:FindFirstChild("InvisGhostNotice") then
            CoreguiM.InvisGhostNotice:Destroy()
        end
    end)
    local g = Instance.new("ScreenGui", CoreguiM)
    g.Name = "InvisGhostNotice"
    g.ResetOnSpawn = false
    local lbl = Instance.new("TextLabel", g)
    lbl.Size = UDim2.new(0, 300, 0, 40)
    lbl.Position = UDim2.new(0.5, -150, 0, 20)
    lbl.BackgroundTransparency = 0.15
    lbl.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Text = txt
    lbl.TextSize = 18
    lbl.Font = Enum.Font.SourceSansSemibold
    lbl.ZIndex = 9999
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
    spawn(function()
        task.wait(2)
        pcall(function() g:Destroy() end)
    end)
end

local function setTransparency(char, val)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.Transparency = val
        end
    end
end

local function toggleInvis()
    invisOn = not invisOn
    local char = plr.Character
    if char then
        if invisOn then
            setTransparency(char, 0.5)
            local savedpos = char.HumanoidRootPart.CFrame
            task.wait()
            char:MoveTo(Vector3.new(-25.95, 84, 3537.55))
            task.wait(0.15)
            local Seat = Instance.new("Seat", workspace)
            Seat.Anchored = false
            Seat.CanCollide = false
            Seat.Name = "invischair"
            Seat.Transparency = 1
            Seat.Position = Vector3.new(-25.95, 84, 3537.55)
            local Weld = Instance.new("Weld", Seat)
            Weld.Part0 = Seat
            Weld.Part1 = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            Seat.CFrame = savedpos
            showNotice("Invisibility Enabled")
        else
            setTransparency(char, 0)
            if workspace:FindFirstChild("invischair") then
                workspace.invischair:Destroy()
            end
            showNotice("Invisibility Disabled")
        end
    end
end

local ghostEnforceConn
local function toggleGhost()
    ghostOn = not ghostOn
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if ghostOn then
            hum.WalkSpeed = ghostSpeed
            if ghostEnforceConn then
                pcall(function() ghostEnforceConn:Disconnect() end)
                ghostEnforceConn = nil
            end
            ghostEnforceConn = RunService.Stepped:Connect(function()
                if hum and hum.WalkSpeed ~= ghostSpeed then
                    pcall(function() hum.WalkSpeed = ghostSpeed end)
                end
            end)
            showNotice("Ghost Enabled: " .. tostring(ghostSpeed))
        else
            if ghostEnforceConn then
                pcall(function() ghostEnforceConn:Disconnect() end)
                ghostEnforceConn = nil
            end
            hum.WalkSpeed = 16
            showNotice("Ghost Disabled")
        end
    else
        if ghostOn then
            showNotice("Ghost Enabled: " .. tostring(ghostSpeed))
        else
            showNotice("Ghost Disabled")
        end
    end
end

local noclipConn
local function toggleNoclip()
    noclipOn = not noclipOn
    if noclipOn then
        noclipConn = game:GetService("RunService").Stepped:Connect(function()
            local char = plr.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        showNotice("Noclip Enabled")
    else
        if noclipConn then
            pcall(function() noclipConn:Disconnect() end)
            noclipConn = nil
        end
        showNotice("Noclip Disabled")
    end
end

local keybindConn
local function unload()
    if sg then
        pcall(function() sg:Destroy() end)
        sg = nil
    end
    _G.InvisGhostLoaded = nil
    if noclipConn then
        pcall(function() noclipConn:Disconnect() end)
        noclipConn = nil
    end
    if keybindConn then
        pcall(function() keybindConn:Disconnect() end)
        keybindConn = nil
    end
    if ghostEnforceConn then
        pcall(function() ghostEnforceConn:Disconnect() end)
        ghostEnforceConn = nil
    end
    local char = plr.Character
    if char then
        pcall(function()
            setTransparency(char, 0)
            if workspace:FindFirstChild("invischair") then
                workspace.invischair:Destroy()
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                if hum.JumpPower then
                    hum.JumpPower = 50
                end
            end
        end)
    end
    invisOn = false
    ghostOn = false
    noclipOn = false
    uiHidden = false
    showNotice("Invis Ghost Unloaded")
end

local function confirmUnload()
    if CoreguiM:FindFirstChild("UnloadConfirmUI") then
        CoreguiM.UnloadConfirmUI:Destroy()
    end
    local confirmGui = Instance.new("ScreenGui", CoreguiM)
    confirmGui.Name = "UnloadConfirmUI"
    confirmGui.ResetOnSpawn = false
    local frame = Instance.new("Frame", confirmGui)
    frame.Size = UDim2.new(0, 250, 0, 120)
    frame.Position = UDim2.new(0.5, -125, 0.5, -60)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 40)
    label.BackgroundTransparency = 1
    label.Text = "Are you sure to unload?"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 20
    local yesBtn = Instance.new("TextButton", frame)
    yesBtn.Size = UDim2.new(0.5, -5, 0, 40)
    yesBtn.Position = UDim2.new(0, 5, 1, -45)
    yesBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
    yesBtn.Text = "Yes"
    yesBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 8)
    local noBtn = Instance.new("TextButton", frame)
    noBtn.Size = UDim2.new(0.5, -5, 0, 40)
    noBtn.Position = UDim2.new(0.5, 0, 1, -45)
    noBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
    noBtn.Text = "No"
    noBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 8)
    yesBtn.MouseButton1Click:Connect(function()
        pcall(function() confirmGui:Destroy() end)
        unload()
    end)
    noBtn.MouseButton1Click:Connect(function()
        pcall(function() confirmGui:Destroy() end)
    end)
end

invisBtn.MouseButton1Click:Connect(toggleInvis)
ghostBtn.MouseButton1Click:Connect(toggleGhost)
noclipBtn.MouseButton1Click:Connect(toggleNoclip)
unloadBtn.MouseButton1Click:Connect(confirmUnload)

speedBox.FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            ghostSpeed = val
            saveSpeed(ghostSpeed)
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if ghostOn then
                    hum.WalkSpeed = ghostSpeed
                else
                    hum.WalkSpeed = 16
                end
            end
        else
            speedBox.Text = tostring(ghostSpeed)
        end
    end
end)

keybindConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Z then
        toggleInvis()
    elseif input.KeyCode == Enum.KeyCode.B then
        toggleGhost()
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.K then
        uiHidden = not uiHidden
        mainFrame.Visible = not uiHidden
    end
end)
--DONT SKID Llitte bro just dont its my 
--2025/9/6