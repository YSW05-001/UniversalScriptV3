--[[
    ULTIMATE VOLT HUB
    Version: 5.0 - Elite Edition
    Theme: Dark Premium White
    WalkSpeed/Jump: ABSOLUTE VALUE (User > 0) or BASE (User = 0)
    - Value 0 = pakai base game
    - Value > 0 = pakai nilai user
    - No limit, no error, no freeze
    - Works in lobby & match
    Lock GUI: Anti Multi-Touch
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

getgenv().Settings = {
    Speed = 0,
    Jump = 0,
    FlySpeed = 200,
    AimbotFOV = 200
}

getgenv().BaseWalkSpeed = nil
getgenv().BaseJumpPower = nil

getgenv().Toggles = {
    Fly = false,
    NoClip = false,
    InfiniteJump = false,
    GodMode = false,
    Aimbot = false,
    KillAura = false,
    AutoClick = false,
    ESPPlayer = false,
    ESPOutline = false,
    FullBright = false,
    GUILock = false
}

getgenv().GuiLocked = false

local Theme = {
    Background = Color3.fromRGB(18, 18, 20),
    Secondary = Color3.fromRGB(26, 26, 30),
    Tertiary = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 170),
    Stroke = Color3.fromRGB(60, 60, 68),
    ToggleOff = Color3.fromRGB(70, 70, 78),
    ButtonDanger = Color3.fromRGB(220, 60, 60),
    ButtonSuccess = Color3.fromRGB(60, 200, 120),
    ButtonWarning = Color3.fromRGB(230, 170, 50),
    ButtonInfo = Color3.fromRGB(100, 140, 230)
}

-- ============================================
-- HELPERS
-- ============================================
local function SensorString(str)
    if not str or #str == 0 then return "***" end
    if #str <= 2 then return string.rep("*", #str) end
    local firstChar = str:sub(1, 1)
    local lastChar = str:sub(#str, #str)
    local stars = string.rep("*", math.max(1, #str - 2))
    return firstChar .. stars .. lastChar
end

local function NotifyGuiOpened(name)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = name,
            Text = "GUI opened",
            Duration = 2
        })
    end)
end

local function DetectRole(player)
    if not player or not player.Character then return "Lobby" end
    local char = player.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return "Lobby" end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        local tn = tool.Name:lower()
        if tn:find("knife") or tn:find("kill") or tn:find("weapon")
            or tn:find("blade") or tn:find("sword") or tn:find("gun") then
            return "Killer"
        end
    end

    for _, obj in pairs(char:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("killer") or n:find("murderer") or n:find("slasher") then return "Killer" end
        if n:find("survivor") or n:find("innocent") then return "Survivor" end
    end

    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in pairs(pg:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                local t = tostring(gui.Text):lower()
                if t == "killer" or t == "murderer" then return "Killer"
                elseif t == "survivor" or t == "innocent" then return "Survivor" end
            end
        end
    end
    return "Survivor"
end

local ESPColors = {
    Killer = { Username = Color3.fromRGB(255, 30, 30), Outline = Color3.fromRGB(255, 30, 30) },
    Survivor = { Username = Color3.fromRGB(0, 240, 255), Outline = Color3.fromRGB(0, 240, 255) },
    Lobby = { Username = Color3.fromRGB(255, 220, 0), Outline = Color3.fromRGB(255, 220, 0) }
}

local ESPPlayerUsernameColors = {
    Killer = Color3.fromRGB(255, 30, 30),
    Survivor = Color3.fromRGB(0, 240, 255),
    Lobby = Color3.fromRGB(255, 255, 255)
}

local GUI_WIDTH = 350
local GUI_HEIGHT = 250

-- ============================================
-- ABSOLUTE WALK/JUMP CONTROLLER
-- ============================================
local function CaptureBase(hum)
    if not hum then return end
    if not getgenv().BaseWalkSpeed or getgenv().BaseWalkSpeed <= 0 then
        local ws = hum.WalkSpeed
        if ws and ws > 0 then
            getgenv().BaseWalkSpeed = ws
        end
    end
    if not getgenv().BaseJumpPower or getgenv().BaseJumpPower <= 0 then
        local jp = hum.JumpPower
        if jp and jp > 0 then
            getgenv().BaseJumpPower = jp
        end
    end
end

local function ApplyWalkJump(hum)
    if not hum or not hum.Parent then return end
    local baseWS = getgenv().BaseWalkSpeed or 16
    local baseJP = getgenv().BaseJumpPower or 50

    local userWS = getgenv().Settings.Speed or 0
    local userJP = getgenv().Settings.Jump or 0

    -- User > 0 = pakai nilai user
    -- User = 0 = pakai base game
    local targetWS
    local targetJP

    if userWS > 0 then
        targetWS = userWS
    else
        targetWS = baseWS
    end

    if userJP > 0 then
        targetJP = userJP
    else
        targetJP = baseJP
    end

    pcall(function()
        hum.WalkSpeed = targetWS
    end)
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower = targetJP
    end)
end

-- ============================================
-- DRAG HELPER (Anti Multi-Touch)
-- ============================================
local function MakeDraggable(frame, dragArea)
    dragArea = dragArea or frame
    local activeInput = nil
    local dragStart, startPos

    local function beginDrag(input)
        if activeInput then return end
        activeInput = input
        dragStart = input.Position
        startPos = frame.Position
    end

    local function endDrag(input)
        if activeInput == input then
            activeInput = nil
        end
    end

    local function moveDrag(input)
        if activeInput ~= input then return end
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if activeInput then return end
            beginDrag(input)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            moveDrag(input)
        end
    end)

    dragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            endDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if activeInput and getgenv().GuiLocked then
            moveDrag(input)
        end
    end)
end

local function SetupMinimize(minBtn, frame, fullHeight)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(frame, TweenInfo.new(0.25), {
            Size = minimized and UDim2.new(0, frame.Size.X.Offset, 0, 24)
                                 or UDim2.new(0, frame.Size.X.Offset, 0, fullHeight)
        }):Play()
        minBtn.Text = minimized and "+" or "_"
    end)
end

-- ============================================
-- UI SYSTEM
-- ============================================
local Hub = {}

function Hub:CreateWindow()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = HttpService:GenerateGUID(false)
    ScreenGui.ResetOnSpawn = false
    if syn then syn.protect_gui(ScreenGui)
    elseif gethui then ScreenGui.Parent = gethui()
    else ScreenGui.Parent = game:GetService("CoreGui") end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT)
    Main.Position = UDim2.new(0.5, -GUI_WIDTH/2, 0.5, -GUI_HEIGHT/2)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Main

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Main

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundColor3 = Theme.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = Main

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 10)
    HeaderFix.Position = UDim2.new(0, 0, 1, -10)
    HeaderFix.BackgroundColor3 = Theme.Secondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.Position = UDim2.new(0, 0, 1, -1)
    HeaderLine.BackgroundColor3 = Theme.Stroke
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "VOLT HUB"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 20, 0, 20)
    Close.Position = UDim2.new(1, -26, 0.5, -10)
    Close.BackgroundColor3 = Theme.Tertiary
    Close.Text = "X"
    Close.TextColor3 = Theme.Text
    Close.TextSize = 11
    Close.Font = Enum.Font.GothamBold
    Close.AutoButtonColor = false
    Close.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = Close

    Close.MouseEnter:Connect(function()
        TweenService:Create(Close, TweenInfo.new(0.15), {BackgroundColor3 = Theme.ButtonDanger}):Play()
    end)
    Close.MouseLeave:Connect(function()
        TweenService:Create(Close, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
    end)
    Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local Min = Instance.new("TextButton")
    Min.Size = UDim2.new(0, 20, 0, 20)
    Min.Position = UDim2.new(1, -50, 0.5, -10)
    Min.BackgroundColor3 = Theme.Tertiary
    Min.Text = "_"
    Min.TextColor3 = Theme.Text
    Min.TextSize = 13
    Min.Font = Enum.Font.GothamBold
    Min.AutoButtonColor = false
    Min.Parent = Header

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 5)
    MinCorner.Parent = Min

    Min.MouseEnter:Connect(function()
        TweenService:Create(Min, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play()
    end)
    Min.MouseLeave:Connect(function()
        TweenService:Create(Min, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
    end)

    local minimized = false
    Min.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(Main, TweenInfo.new(0.3), {
            Size = minimized and UDim2.new(0, GUI_WIDTH, 0, 36) or UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT)
        }):Play()
        Min.Text = minimized and "+" or "_"
    end)

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0, 90, 1, -36)
    TabBar.Position = UDim2.new(0, 0, 0, 36)
    TabBar.BackgroundColor3 = Theme.Secondary
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main

    local TabBarLine = Instance.new("Frame")
    TabBarLine.Size = UDim2.new(0, 1, 1, 0)
    TabBarLine.Position = UDim2.new(1, -1, 0, 0)
    TabBarLine.BackgroundColor3 = Theme.Stroke
    TabBarLine.BorderSizePixel = 0
    TabBarLine.Parent = TabBar

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -90, 1, -36)
    Content.Position = UDim2.new(0, 90, 0, 36)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    MakeDraggable(Main, Header)

    return {ScreenGui = ScreenGui, Main = Main, TabBar = TabBar, Content = Content, Tabs = {}}
end

function Hub:CreateTab(window, name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -10, 0, 24)
    TabBtn.Position = UDim2.new(0, 5, 0, #window.Tabs * 28 + 6)
    TabBtn.BackgroundColor3 = Theme.Tertiary
    TabBtn.Text = name
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.TextSize = 10
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.AutoButtonColor = false
    TabBtn.Parent = window.TabBar

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TabBtn

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 2, 0, 14)
    Indicator.Position = UDim2.new(0, -2, 0.5, -7)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = TabBtn

    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Size = UDim2.new(1, 0, 1, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.ScrollBarThickness = 2
    TabContent.ScrollBarImageColor3 = Theme.Stroke
    TabContent.Visible = false
    TabContent.Parent = window.Content

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 5)
    Layout.Parent = TabContent

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 8)
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingBottom = UDim.new(0, 8)
    Padding.Parent = TabContent

    local Tab = {Button = TabBtn, Content = TabContent, Indicator = Indicator}

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(window.Tabs) do
            t.Button.BackgroundColor3 = Theme.Tertiary
            t.Button.TextColor3 = Theme.TextDim
            t.Content.Visible = false
            t.Indicator.Visible = false
        end
        TabBtn.BackgroundColor3 = Theme.Background
        TabBtn.TextColor3 = Theme.Text
        TabContent.Visible = true
        Indicator.Visible = true
    end)

    TabBtn.MouseEnter:Connect(function()
        if TabBtn.BackgroundColor3 ~= Theme.Background then
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 52)}):Play()
        end
    end)

    TabBtn.MouseLeave:Connect(function()
        if TabBtn.BackgroundColor3 ~= Theme.Background then
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
        end
    end)

    table.insert(window.Tabs, Tab)

    if #window.Tabs == 1 then
        TabBtn.BackgroundColor3 = Theme.Background
        TabBtn.TextColor3 = Theme.Text
        TabContent.Visible = true
        Indicator.Visible = true
    end

    return TabContent
end

function Hub:CreateToggle(parent, text, setting, color, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 28)
    Frame.BackgroundColor3 = Theme.Secondary
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 8, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 40, 0, 18)
    Toggle.Position = UDim2.new(1, -48, 0.5, -9)
    Toggle.BackgroundColor3 = Toggles[setting] and color or Theme.ToggleOff
    Toggle.Text = Toggles[setting] and "ON" or "OFF"
    Toggle.TextColor3 = Toggles[setting] and Theme.Background or Theme.Text
    Toggle.TextSize = 9
    Toggle.Font = Enum.Font.GothamBold
    Toggle.AutoButtonColor = false
    Toggle.Parent = Frame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = Toggle

    Toggle.MouseButton1Click:Connect(function()
        Toggles[setting] = not Toggles[setting]
        if Toggles[setting] then
            TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            Toggle.Text = "ON"
            Toggle.TextColor3 = Theme.Background
        else
            TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOff}):Play()
            Toggle.Text = "OFF"
            Toggle.TextColor3 = Theme.Text
        end
        if callback then pcall(callback, Toggles[setting]) end
    end)

    return Toggle
end

function Hub:CreateButton(parent, text, color, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 26)
    Btn.BackgroundColor3 = Theme.Secondary
    Btn.Text = text
    Btn.TextColor3 = Theme.Text
    Btn.TextSize = 10
    Btn.Font = Enum.Font.GothamBold
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Btn

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 2, 0, 14)
    Accent.Position = UDim2.new(0, 5, 0.5, -7)
    Accent.BackgroundColor3 = color
    Accent.BorderSizePixel = 0
    Accent.Parent = Btn

    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(1, 0)
    AccentCorner.Parent = Accent

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
    end)

    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Secondary}):Play()
    end)

    Btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return Btn
end

-- ============================================
-- SLIDER (No Limit)
-- ============================================
function Hub:CreateSlider(parent, text, setting, defaultVal, color, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 60)
    Frame.BackgroundColor3 = Theme.Secondary
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -90, 0, 16)
    Label.Position = UDim2.new(0, 8, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 10
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local DecBtn = Instance.new("TextButton")
    DecBtn.Size = UDim2.new(0, 22, 0, 22)
    DecBtn.Position = UDim2.new(0, 8, 0, 26)
    DecBtn.BackgroundColor3 = Theme.Tertiary
    DecBtn.Text = "<"
    DecBtn.TextColor3 = Theme.Text
    DecBtn.TextSize = 14
    DecBtn.Font = Enum.Font.GothamBold
    DecBtn.AutoButtonColor = false
    DecBtn.Parent = Frame

    local DecCorner = Instance.new("UICorner")
    DecCorner.CornerRadius = UDim.new(0, 4)
    DecCorner.Parent = DecBtn

    local ValueBox = Instance.new("TextBox")
    ValueBox.Size = UDim2.new(0, 80, 0, 22)
    ValueBox.Position = UDim2.new(0, 34, 0, 26)
    ValueBox.BackgroundColor3 = Theme.Tertiary
    ValueBox.BorderSizePixel = 0
    ValueBox.Text = tostring(defaultVal)
    ValueBox.TextColor3 = color
    ValueBox.TextSize = 11
    ValueBox.Font = Enum.Font.GothamBold
    ValueBox.ClearTextOnFocus = false
    ValueBox.Parent = Frame

    local ValueCorner = Instance.new("UICorner")
    ValueCorner.CornerRadius = UDim.new(0, 4)
    ValueCorner.Parent = ValueBox

    local IncBtn = Instance.new("TextButton")
    IncBtn.Size = UDim2.new(0, 22, 0, 22)
    IncBtn.Position = UDim2.new(0, 118, 0, 26)
    IncBtn.BackgroundColor3 = Theme.Tertiary
    IncBtn.Text = ">"
    IncBtn.TextColor3 = Theme.Text
    IncBtn.TextSize = 14
    IncBtn.Font = Enum.Font.GothamBold
    IncBtn.AutoButtonColor = false
    IncBtn.Parent = Frame

    local IncCorner = Instance.new("UICorner")
    IncCorner.CornerRadius = UDim.new(0, 4)
    IncCorner.Parent = IncBtn

    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(1, -152, 0, 22)
    ApplyBtn.Position = UDim2.new(0, 144, 0, 26)
    ApplyBtn.BackgroundColor3 = color
    ApplyBtn.Text = "SET"
    ApplyBtn.TextColor3 = Theme.Background
    ApplyBtn.TextSize = 10
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.AutoButtonColor = false
    ApplyBtn.Parent = Frame

    local ApplyCorner = Instance.new("UICorner")
    ApplyCorner.CornerRadius = UDim.new(0, 4)
    ApplyCorner.Parent = ApplyBtn

    local function formatValue(v)
        if v == math.floor(v) then
            return tostring(math.floor(v))
        else
            return string.format("%.1f", v)
        end
    end

    local function applyValue(value)
        local num = tonumber(value)
        if not num then return end
        if num ~= num or num == math.huge or num == -math.huge then return end

        -- Minimum 0 (tidak boleh negatif)
        if num < 0 then num = 0 end

        -- Round
        if num < 1 then
            num = math.floor(num * 10 + 0.5) / 10
        else
            num = math.floor(num)
        end

        Settings[setting] = num
        getgenv().Settings[setting] = num
        ValueBox.Text = formatValue(num)

        if callback then pcall(callback, num) end
    end

    DecBtn.MouseButton1Click:Connect(function()
        local current = Settings[setting] or 0
        local newVal = current - 1
        if newVal < 0 then newVal = 0 end
        applyValue(newVal)
    end)

    IncBtn.MouseButton1Click:Connect(function()
        local current = Settings[setting] or 0
        applyValue(current + 1)
    end)

    ValueBox.FocusLost:Connect(function(enterPressed)
        local txt = ValueBox.Text
        if txt and txt ~= "" then
            applyValue(txt)
        end
    end)

    ApplyBtn.MouseButton1Click:Connect(function()
        local txt = ValueBox.Text
        if txt and txt ~= "" then
            applyValue(txt)
        end
    end)

    DecBtn.MouseEnter:Connect(function()
        TweenService:Create(DecBtn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    DecBtn.MouseLeave:Connect(function()
        TweenService:Create(DecBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
    end)
    IncBtn.MouseEnter:Connect(function()
        TweenService:Create(IncBtn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    IncBtn.MouseLeave:Connect(function()
        TweenService:Create(IncBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
    end)
end

-- ============================================
-- MODULAR FEATURES
-- ============================================

local FlyFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = RunService.Heartbeat:Connect(function()
            if not Toggles.Fly then return end
            if not HRP or not HRP.Parent then return end
            local cam = Workspace.CurrentCamera
            local move = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            if move.Magnitude > 0 then
                HRP.Velocity = move.Unit * Settings.FlySpeed
            else
                HRP.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        if HRP and HRP.Parent then pcall(function() HRP.Velocity = Vector3.new(0, 0, 0) end) end
    end
}

local NoClipFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = RunService.Stepped:Connect(function()
            if not Toggles.NoClip then return end
            if not Character or not Character.Parent then return end
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
    end
}

local GodModeFeature = {
    active = false, connection = nil, healthConnection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        if not Humanoid or not Humanoid.Parent then return end

        self.connection = RunService.Heartbeat:Connect(function()
            if not Toggles.GodMode then return end
            if not Humanoid or not Humanoid.Parent then return end
            pcall(function()
                if Humanoid.MaxHealth < 100 then Humanoid.MaxHealth = 100 end
                if Humanoid.Health < Humanoid.MaxHealth then Humanoid.Health = Humanoid.MaxHealth end
            end)
        end)

        self.healthConnection = Humanoid.HealthChanged:Connect(function(newHealth)
            if not Toggles.GodMode then return end
            if not Humanoid or not Humanoid.Parent then return end
            pcall(function()
                if newHealth < Humanoid.MaxHealth then Humanoid.Health = Humanoid.MaxHealth end
            end)
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
        if self.healthConnection then self.healthConnection:Disconnect(); self.healthConnection = nil end
    end
}

local InfiniteJumpFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = UserInputService.JumpRequest:Connect(function()
            if Toggles.InfiniteJump and Humanoid and Humanoid.Parent then
                pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
    end
}

local ESPPlayerFeature = {
    active = false, folder = nil, cache = {},
    CreateESP = function(self, player)
        if not player or player == LocalPlayer then return end
        if not player.Character then return end
        local head = player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
        if not head then return end

        if self.cache[player] then
            pcall(function() self.cache[player]:Destroy() end)
            self.cache[player] = nil
        end

        local role = DetectRole(player)
        local color = ESPPlayerUsernameColors[role] or ESPPlayerUsernameColors.Lobby

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 120, 0, 20)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = head
        billboard.Parent = self.folder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = color
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.3
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard

        self.cache[player] = billboard
    end,
    Refresh = function(self)
        if not self.active then return end
        for player, gui in pairs(self.cache) do
            if not player.Parent or not player.Character then
                pcall(function() gui:Destroy() end)
                self.cache[player] = nil
            end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    self:CreateESP(player)
                else
                    if self.cache[player] then
                        pcall(function() self.cache[player]:Destroy() end)
                        self.cache[player] = nil
                    end
                end
            end
        end
    end,
    Start = function(self)
        if self.active then return end
        self.active = true
        if not self.folder or not self.folder.Parent then
            self.folder = Instance.new("Folder")
            self.folder.Name = "ESPPlayer_Folder"
            self.folder.Parent = Workspace
        end
        self:Refresh()
    end,
    Stop = function(self)
        self.active = false
        for player, gui in pairs(self.cache) do pcall(function() gui:Destroy() end) end
        self.cache = {}
        if self.folder then pcall(function() self.folder:Destroy() end); self.folder = nil end
    end
}

local ESPOutlineFeature = {
    active = false, folder = nil, cache = {},
    CreateESP = function(self, player)
        if not player or player == LocalPlayer then return end
        if not player.Character then return end
        local char = player.Character
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not head then return end

        if self.cache[player] then
            pcall(function()
                if self.cache[player].highlight then self.cache[player].highlight:Destroy() end
                if self.cache[player].billboard then self.cache[player].billboard:Destroy() end
            end)
            self.cache[player] = nil
        end

        local role = DetectRole(player)
        local colors = ESPColors[role] or ESPColors.Lobby

        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0
        highlight.OutlineColor = colors.Outline
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = self.folder

        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 140, 0, 22)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = math.huge
        billboard.Adornee = head
        billboard.Parent = self.folder

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.Name
        label.TextColor3 = colors.Username
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard

        self.cache[player] = {highlight = highlight, billboard = billboard, label = label}
    end,
    Refresh = function(self)
        if not self.active then return end
        for player, data in pairs(self.cache) do
            if not player.Parent or not player.Character then
                pcall(function()
                    if data.highlight then data.highlight:Destroy() end
                    if data.billboard then data.billboard:Destroy() end
                end)
                self.cache[player] = nil
            end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    self:CreateESP(player)
                else
                    if self.cache[player] then
                        local data = self.cache[player]
                        pcall(function()
                            if data.highlight then data.highlight:Destroy() end
                            if data.billboard then data.billboard:Destroy() end
                        end)
                        self.cache[player] = nil
                    end
                end
            end
        end
    end,
    Start = function(self)
        if self.active then return end
        self.active = true
        if not self.folder or not self.folder.Parent then
            self.folder = Instance.new("Folder")
            self.folder.Name = "ESPOutline_Folder"
            self.folder.Parent = Workspace
        end
        self:Refresh()
    end,
    Stop = function(self)
        self.active = false
        for player, data in pairs(self.cache) do
            pcall(function()
                if data.highlight then data.highlight:Destroy() end
                if data.billboard then data.billboard:Destroy() end
            end)
        end
        self.cache = {}
        if self.folder then pcall(function() self.folder:Destroy() end); self.folder = nil end
    end
}

local AimbotFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = RunService.RenderStepped:Connect(function()
            if not Toggles.Aimbot then return end
            local closest, minDist = nil, Settings.AimbotFOV
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local mouseLoc = UserInputService:GetMouseLocation()
                                local dist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                                if dist < minDist then minDist = dist; closest = hrp end
                            end
                        end
                    end
                end
            end
            if closest and Workspace.CurrentCamera then
                Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, closest.Position)
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
    end
}

local KillAuraFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = RunService.Heartbeat:Connect(function()
            if not Toggles.KillAura then return end
            if not HRP or not HRP.Parent then return end
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj ~= Character then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and not Players:FindFirstChild(obj.Name) then
                        if (hrp.Position - HRP.Position).Magnitude < 50 then
                            pcall(function()
                                HRP.CFrame = CFrame.new(HRP.Position, hrp.Position)
                                if mouse1click then mouse1click() end
                            end)
                        end
                    end
                end
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
    end
}

local AutoClickFeature = {
    active = false, connection = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.connection = RunService.Heartbeat:Connect(function()
            if Toggles.AutoClick then
                pcall(function() if mouse1click then mouse1click() end end)
            end
        end)
    end,
    Stop = function(self)
        self.active = false
        if self.connection then self.connection:Disconnect(); self.connection = nil end
    end
}

local FullBrightFeature = {
    active = false, savedBrightness = nil, savedShadows = nil, savedFogEnd = nil,
    Start = function(self)
        if self.active then return end
        self.active = true
        self.savedBrightness = Lighting.Brightness
        self.savedShadows = Lighting.GlobalShadows
        self.savedFogEnd = Lighting.FogEnd
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 999999
    end,
    Stop = function(self)
        self.active = false
        if self.savedBrightness then Lighting.Brightness = self.savedBrightness end
        if self.savedShadows ~= nil then Lighting.GlobalShadows = self.savedShadows end
        if self.savedFogEnd then Lighting.FogEnd = self.savedFogEnd end
    end
}

local JumpButtonController = {
    hidden = false, originalState = true,
    Hide = function(self)
        self.hidden = true
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local touchGui = pg:FindFirstChild("TouchGui")
                if touchGui then
                    local frame = touchGui:FindFirstChild("TouchControlFrame")
                    if frame then
                        local jump = frame:FindFirstChild("JumpButton")
                        if jump then
                            self.originalState = jump.Visible
                            jump.Visible = false
                        end
                    end
                end
            end
        end)
        pcall(function() StarterGui:SetCore("SetJumpButtonVisible", false) end)
    end,
    Show = function(self)
        self.hidden = false
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local touchGui = pg:FindFirstChild("TouchGui")
                if touchGui then
                    local frame = touchGui:FindFirstChild("TouchControlFrame")
                    if frame then
                        local jump = frame:FindFirstChild("JumpButton")
                        if jump then
                            jump.Visible = self.originalState ~= false
                        end
                    end
                end
            end
        end)
        pcall(function() StarterGui:SetCore("SetJumpButtonVisible", true) end)
    end
}

local FeatureManager = {
    Sync = function(self)
        if Toggles.Fly and not FlyFeature.active then FlyFeature:Start()
        elseif not Toggles.Fly and FlyFeature.active then FlyFeature:Stop() end

        if Toggles.NoClip and not NoClipFeature.active then NoClipFeature:Start()
        elseif not Toggles.NoClip and NoClipFeature.active then NoClipFeature:Stop() end

        if Toggles.GodMode and not GodModeFeature.active then GodModeFeature:Start()
        elseif not Toggles.GodMode and GodModeFeature.active then GodModeFeature:Stop() end

        if Toggles.InfiniteJump and not InfiniteJumpFeature.active then InfiniteJumpFeature:Start()
        elseif not Toggles.InfiniteJump and InfiniteJumpFeature.active then InfiniteJumpFeature:Stop() end

        if Toggles.ESPPlayer and not ESPPlayerFeature.active then ESPPlayerFeature:Start()
        elseif not Toggles.ESPPlayer and ESPPlayerFeature.active then ESPPlayerFeature:Stop() end

        if Toggles.ESPOutline and not ESPOutlineFeature.active then ESPOutlineFeature:Start()
        elseif not Toggles.ESPOutline and ESPOutlineFeature.active then ESPOutlineFeature:Stop() end

        if Toggles.Aimbot and not AimbotFeature.active then AimbotFeature:Start()
        elseif not Toggles.Aimbot and AimbotFeature.active then AimbotFeature:Stop() end

        if Toggles.KillAura and not KillAuraFeature.active then KillAuraFeature:Start()
        elseif not Toggles.KillAura and KillAuraFeature.active then KillAuraFeature:Stop() end

        if Toggles.AutoClick and not AutoClickFeature.active then AutoClickFeature:Start()
        elseif not Toggles.AutoClick and AutoClickFeature.active then AutoClickFeature:Stop() end

        if Toggles.FullBright and not FullBrightFeature.active then FullBrightFeature:Start()
        elseif not Toggles.FullBright and FullBrightFeature.active then FullBrightFeature:Stop() end
    end
}

-- ============================================
-- BUILD UI
-- ============================================
local Window = Hub:CreateWindow()

local PlayerTab = Hub:CreateTab(Window, "Player")
local CombatTab = Hub:CreateTab(Window, "Combat")
local VisualTab = Hub:CreateTab(Window, "Visual")
local ServerTab = Hub:CreateTab(Window, "Server")
local MiscTab = Hub:CreateTab(Window, "Misc")

-- PLAYER TAB
Hub:CreateToggle(PlayerTab, "Fly", "Fly", Theme.Accent)
Hub:CreateToggle(PlayerTab, "No Clip", "NoClip", Theme.Accent)
Hub:CreateToggle(PlayerTab, "Infinite Jump", "InfiniteJump", Theme.Accent)
Hub:CreateToggle(PlayerTab, "God Mode", "GodMode", Theme.Accent)

Hub:CreateSlider(PlayerTab, "Walk Speed", "Speed", 0, Theme.Accent, function(value)
    if Humanoid and Humanoid.Parent then
        pcall(function()
            if value > 0 then
                Humanoid.WalkSpeed = value
            else
                Humanoid.WalkSpeed = getgenv().BaseWalkSpeed or 16
            end
        end)
    end
end)

Hub:CreateSlider(PlayerTab, "Jump Height", "Jump", 0, Theme.Accent, function(value)
    if Humanoid and Humanoid.Parent then
        pcall(function()
            Humanoid.UseJumpPower = true
            if value > 0 then
                Humanoid.JumpPower = value
            else
                Humanoid.JumpPower = getgenv().BaseJumpPower or 50
            end
        end)
    end
end)

Hub:CreateButton(PlayerTab, "Hide Jump Button", Theme.ButtonWarning, function()
    JumpButtonController:Hide()
end)

Hub:CreateButton(PlayerTab, "Show Jump Button", Theme.ButtonSuccess, function()
    JumpButtonController:Show()
end)

-- PROFILE INFO
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Size = UDim2.new(1, 0, 0, 60)
ProfileFrame.BackgroundColor3 = Theme.Secondary
ProfileFrame.BorderSizePixel = 0
ProfileFrame.Parent = PlayerTab

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(0, 6)
ProfileCorner.Parent = ProfileFrame

local ProfileStroke = Instance.new("UIStroke")
ProfileStroke.Color = Theme.Stroke
ProfileStroke.Thickness = 1
ProfileStroke.Parent = ProfileFrame

local ProfileTitle = Instance.new("TextLabel")
ProfileTitle.Size = UDim2.new(1, -16, 0, 16)
ProfileTitle.Position = UDim2.new(0, 8, 0, 4)
ProfileTitle.BackgroundTransparency = 1
ProfileTitle.Text = "Profile Player"
ProfileTitle.TextColor3 = Theme.Text
ProfileTitle.TextSize = 10
ProfileTitle.Font = Enum.Font.GothamBold
ProfileTitle.TextXAlignment = Enum.TextXAlignment.Left
ProfileTitle.Parent = ProfileFrame

local ProfileBody = Instance.new("TextLabel")
ProfileBody.Size = UDim2.new(1, -16, 1, -22)
ProfileBody.Position = UDim2.new(0, 8, 0, 22)
ProfileBody.BackgroundTransparency = 1
ProfileBody.Text = "Username: " .. SensorString(LocalPlayer.Name) .. "\nDisplayName: " .. SensorString(LocalPlayer.DisplayName)
ProfileBody.TextColor3 = Theme.TextDim
ProfileBody.TextSize = 9
ProfileBody.Font = Enum.Font.Gotham
ProfileBody.TextXAlignment = Enum.TextXAlignment.Left
ProfileBody.TextYAlignment = Enum.TextYAlignment.Top
ProfileBody.TextWrapped = true
ProfileBody.Parent = ProfileFrame

spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            ProfileBody.Text = "Username: " .. SensorString(LocalPlayer.Name) .. "\nDisplayName: " .. SensorString(LocalPlayer.DisplayName)
        end)
    end
end)

-- COMBAT TAB
Hub:CreateToggle(CombatTab, "Aimbot", "Aimbot", Theme.Accent)
Hub:CreateToggle(CombatTab, "Kill Aura", "KillAura", Theme.Accent)
Hub:CreateToggle(CombatTab, "Auto Click", "AutoClick", Theme.Accent)
Hub:CreateSlider(CombatTab, "Aimbot FOV", "AimbotFOV", 200, Theme.Accent)

-- VISUAL TAB
Hub:CreateToggle(VisualTab, "ESP Player", "ESPPlayer", Theme.Accent)
Hub:CreateToggle(VisualTab, "ESP Outline Player", "ESPOutline", Theme.Accent)
Hub:CreateToggle(VisualTab, "Full Bright", "FullBright", Theme.Accent)
Hub:CreateToggle(VisualTab, "Lock GUI (Anti Multi-Touch)", "GUILock", Theme.Accent, function(state)
    getgenv().GuiLocked = state
end)
Hub:CreateButton(VisualTab, "Remove Fog", Theme.ButtonWarning, function()
    Lighting.FogEnd = 999999
end)

-- ============================================
-- TELEPORT TO PLAYER (250x150)
-- ============================================
Hub:CreateButton(ServerTab, "Teleport To Player", Theme.ButtonSuccess, function()
    local TeleportGui = Instance.new("ScreenGui")
    TeleportGui.ResetOnSpawn = false
    if syn then syn.protect_gui(TeleportGui)
    elseif gethui then TeleportGui.Parent = gethui()
    else TeleportGui.Parent = game:GetService("CoreGui") end

    local FULL_W, FULL_H = 250, 150

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
    Frame.Position = UDim2.new(0.5, -FULL_W/2, 0.5, -FULL_H/2)
    Frame.BackgroundColor3 = Theme.Background
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = TeleportGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 22)
    Header.BackgroundColor3 = Theme.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = Frame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 8)
    HeaderFix.Position = UDim2.new(0, 0, 1, -8)
    HeaderFix.BackgroundColor3 = Theme.Secondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.55, 0, 1, 0)
    Title.Position = UDim2.new(0, 6, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Teleport To Player"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 9
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 14, 0, 14)
    MinBtn.Position = UDim2.new(1, -50, 0.5, -7)
    MinBtn.BackgroundColor3 = Theme.Tertiary
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Theme.Text
    MinBtn.TextSize = 11
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Header

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 3)
    MinCorner.Parent = MinBtn

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 14, 0, 14)
    Close.Position = UDim2.new(1, -20, 0.5, -7)
    Close.BackgroundColor3 = Theme.Tertiary
    Close.Text = "X"
    Close.TextColor3 = Theme.Text
    Close.TextSize = 8
    Close.Font = Enum.Font.GothamBold
    Close.AutoButtonColor = false
    Close.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 3)
    CloseCorner.Parent = Close

    Close.MouseButton1Click:Connect(function() TeleportGui:Destroy() end)
    SetupMinimize(MinBtn, Frame, FULL_H)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -8, 1, -30)
    Content.Position = UDim2.new(0, 4, 0, 26)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, 0, 0, 16)
    SearchBox.Position = UDim2.new(0, 0, 0, 0)
    SearchBox.BackgroundColor3 = Theme.Secondary
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "Search..."
    SearchBox.Text = ""
    SearchBox.TextColor3 = Theme.Text
    SearchBox.PlaceholderColor3 = Theme.TextDim
    SearchBox.TextSize = 8
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.Parent = Content

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 3)
    SearchCorner.Parent = SearchBox

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -20)
    Scroll.Position = UDim2.new(0, 0, 0, 20)
    Scroll.BackgroundColor3 = Theme.Secondary
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = Theme.Stroke
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.Parent = Content

    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 4)
    ScrollCorner.Parent = Scroll

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 2)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Scroll

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 3)
    Padding.PaddingLeft = UDim.new(0, 3)
    Padding.PaddingRight = UDim.new(0, 3)
    Padding.Parent = Scroll

    local function refreshPlayerList(filter)
        for _, child in pairs(Scroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local count = 0
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local name = player.Name
                if filter and filter ~= "" then
                    if not name:lower():find(filter:lower()) then continue end
                end
                count = count + 1

                local role = DetectRole(player)
                local roleColor = ESPPlayerUsernameColors[role] or Theme.Text

                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(1, -6, 0, 18)
                Btn.BackgroundColor3 = Theme.Tertiary
                Btn.Text = ""
                Btn.AutoButtonColor = false
                Btn.Parent = Scroll

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 3)
                BtnCorner.Parent = Btn

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Size = UDim2.new(0.85, 0, 1, 0)
                NameLabel.Position = UDim2.new(0, 4, 0, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = name .. " [" .. role .. "]"
                NameLabel.TextColor3 = roleColor
                NameLabel.TextSize = 8
                NameLabel.Font = Enum.Font.GothamBold
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                NameLabel.Parent = Btn

                local DotLabel = Instance.new("TextLabel")
                DotLabel.Size = UDim2.new(0.15, -4, 1, 0)
                DotLabel.Position = UDim2.new(0.85, 0, 0, 0)
                DotLabel.BackgroundTransparency = 1
                DotLabel.Text = player.Character and "In" or "No"
                DotLabel.TextColor3 = player.Character and Theme.ButtonSuccess or Theme.ButtonDanger
                DotLabel.TextSize = 7
                DotLabel.Font = Enum.Font.Gotham
                DotLabel.TextXAlignment = Enum.TextXAlignment.Right
                DotLabel.Parent = Btn

                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 52)}):Play()
                end)
                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
                end)

                Btn.MouseButton1Click:Connect(function()
                    if player.Character then
                        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and HRP then
                            HRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                        end
                    end
                end)
            end
        end

        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 6)

        if count == 0 then
            local NoPlayer = Instance.new("TextLabel")
            NoPlayer.Size = UDim2.new(1, -6, 0, 18)
            NoPlayer.BackgroundTransparency = 1
            NoPlayer.Text = "No players"
            NoPlayer.TextColor3 = Theme.TextDim
            NoPlayer.TextSize = 8
            NoPlayer.Font = Enum.Font.Gotham
            NoPlayer.Parent = Scroll
        end
    end

    refreshPlayerList("")
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshPlayerList(SearchBox.Text)
    end)

    spawn(function()
        while TeleportGui.Parent do
            wait(2)
            if TeleportGui.Parent then refreshPlayerList(SearchBox.Text) end
        end
    end)

    MakeDraggable(Frame, Header)
    NotifyGuiOpened("Teleport To Player")
end)

-- ============================================
-- TELEPORT TO BASE/LOBBY
-- ============================================
Hub:CreateButton(ServerTab, "Teleport To Base/Lobby", Theme.ButtonSuccess, function()
    local BaseGui = Instance.new("ScreenGui")
    BaseGui.ResetOnSpawn = false
    if syn then syn.protect_gui(BaseGui)
    elseif gethui then BaseGui.Parent = gethui()
    else BaseGui.Parent = game:GetService("CoreGui") end

    local HEADER_H = 24
    local ROW_H = 22
    local ROW_PAD = 3
    local FRAME_PAD = 8
    local INFO_H = 16

    local spawnList = {}

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawnList, {
                name = "Spawn: " .. obj.Name,
                position = obj.Position + Vector3.new(0, 5, 0)
            })
        end
    end

    for _, obj in pairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("lobby") or n:find("spawn") or n:find("base") or n:find("start") then
            if obj:IsA("BasePart") then
                table.insert(spawnList, {
                    name = "BasePart: " .. obj.Name,
                    position = obj.Position + Vector3.new(0, 5, 0)
                })
            elseif obj:IsA("Model") then
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                if primary then
                    table.insert(spawnList, {
                        name = "Model: " .. obj.Name,
                        position = primary.Position + Vector3.new(0, 5, 0)
                    })
                end
            end
        end
    end

    for _, team in pairs(Teams:GetTeams()) do
        local spawn = team:FindFirstChildWhichIsA("SpawnLocation", true)
        if spawn then
            table.insert(spawnList, {
                name = "Team: " .. team.Name,
                position = spawn.Position + Vector3.new(0, 5, 0)
            })
        end
    end

    if #spawnList == 0 then
        table.insert(spawnList, {
            name = "Fallback: Respawn Character",
            position = nil
        })
    end

    local longestSpawn = "Pilih spawn/lobby:"
    for _, spawn in pairs(spawnList) do
        if #spawn.name > #longestSpawn then
            longestSpawn = spawn.name
        end
    end

    local estimatedTextWidth = math.max(#longestSpawn * 5.5 + 40, 150)
    local FULL_W = math.clamp(estimatedTextWidth, 180, 300)

    local visibleRows = math.min(#spawnList, 5)
    local CONTENT_H = INFO_H + (visibleRows * (ROW_H + ROW_PAD)) + FRAME_PAD
    local FULL_H = HEADER_H + CONTENT_H

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
    Frame.Position = UDim2.new(0.5, -FULL_W/2, 0.5, -FULL_H/2)
    Frame.BackgroundColor3 = Theme.Background
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = BaseGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, HEADER_H)
    Header.BackgroundColor3 = Theme.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = Frame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 8)
    HeaderFix.Position = UDim2.new(0, 0, 1, -8)
    HeaderFix.BackgroundColor3 = Theme.Secondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 8, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Teleport To Base/Lobby"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 10
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.Parent = Header

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 16, 0, 16)
    MinBtn.Position = UDim2.new(1, -56, 0.5, -8)
    MinBtn.BackgroundColor3 = Theme.Tertiary
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Theme.Text
    MinBtn.TextSize = 12
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Header

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 4)
    MinCorner.Parent = MinBtn

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 16, 0, 16)
    Close.Position = UDim2.new(1, -20, 0.5, -8)
    Close.BackgroundColor3 = Theme.Tertiary
    Close.Text = "X"
    Close.TextColor3 = Theme.Text
    Close.TextSize = 9
    Close.Font = Enum.Font.GothamBold
    Close.AutoButtonColor = false
    Close.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = Close

    Close.MouseButton1Click:Connect(function() BaseGui:Destroy() end)
    SetupMinimize(MinBtn, Frame, FULL_H)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -8, 1, -(HEADER_H + 4))
    Content.Position = UDim2.new(0, 4, 0, HEADER_H + 2)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, 0, 0, 14)
    InfoLabel.Position = UDim2.new(0, 2, 0, 0)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "Pilih spawn/lobby:"
    InfoLabel.TextColor3 = Theme.TextDim
    InfoLabel.TextSize = 8
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = Content

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -INFO_H)
    Scroll.Position = UDim2.new(0, 0, 0, INFO_H)
    Scroll.BackgroundColor3 = Theme.Secondary
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = Theme.Stroke
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.Parent = Content

    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 4)
    ScrollCorner.Parent = Scroll

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, ROW_PAD)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Scroll

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 3)
    Padding.PaddingLeft = UDim.new(0, 3)
    Padding.PaddingRight = UDim.new(0, 3)
    Padding.PaddingBottom = UDim.new(0, 3)
    Padding.Parent = Scroll

    for _, spawn in pairs(spawnList) do
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -6, 0, ROW_H)
        Btn.BackgroundColor3 = Theme.Tertiary
        Btn.Text = ""
        Btn.AutoButtonColor = false
        Btn.Parent = Scroll

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = Btn

        local BtnLabel = Instance.new("TextLabel")
        BtnLabel.Size = UDim2.new(1, -8, 1, 0)
        BtnLabel.Position = UDim2.new(0, 6, 0, 0)
        BtnLabel.BackgroundTransparency = 1
        BtnLabel.Text = spawn.name
        BtnLabel.TextColor3 = Theme.Text
        BtnLabel.TextSize = 9
        BtnLabel.Font = Enum.Font.Gotham
        BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
        BtnLabel.TextTruncate = Enum.TextTruncate.AtEnd
        BtnLabel.Parent = Btn

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 52)}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Tertiary}):Play()
        end)

        Btn.MouseButton1Click:Connect(function()
            if spawn.position and HRP then
                pcall(function()
                    HRP.CFrame = CFrame.new(spawn.position)
                end)
            else
                pcall(function()
                    if Humanoid and Humanoid.Parent then
                        Humanoid.Health = 0
                    end
                end)
            end
        end)
    end

    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 6)

    MakeDraggable(Frame, Header)
    NotifyGuiOpened("Teleport To Base/Lobby")
end)

-- ============================================
-- GET PLAYER INFO (250x150)
-- ============================================
Hub:CreateButton(ServerTab, "Get Player Info", Theme.ButtonInfo, function()
    local InfoGui = Instance.new("ScreenGui")
    InfoGui.ResetOnSpawn = false
    if syn then syn.protect_gui(InfoGui)
    elseif gethui then InfoGui.Parent = gethui()
    else InfoGui.Parent = game:GetService("CoreGui") end

    local FULL_W, FULL_H = 250, 150

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, FULL_W, 0, FULL_H)
    Frame.Position = UDim2.new(0.5, -FULL_W/2, 0.5, -FULL_H/2)
    Frame.BackgroundColor3 = Theme.Background
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = InfoGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 22)
    Header.BackgroundColor3 = Theme.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = Frame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 8)
    HeaderFix.Position = UDim2.new(0, 0, 1, -8)
    HeaderFix.BackgroundColor3 = Theme.Secondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.5, 0, 1, 0)
    Title.Position = UDim2.new(0, 6, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Player Info"
    Title.TextColor3 = Theme.Text
    Title.TextSize = 9
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Size = UDim2.new(0, 40, 0, 14)
    RefreshBtn.Position = UDim2.new(1, -102, 0.5, -7)
    RefreshBtn.BackgroundColor3 = Theme.ButtonInfo
    RefreshBtn.Text = "REFRESH"
    RefreshBtn.TextColor3 = Theme.Background
    RefreshBtn.TextSize = 7
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.AutoButtonColor = false
    RefreshBtn.Parent = Header

    local RefreshCorner = Instance.new("UICorner")
    RefreshCorner.CornerRadius = UDim.new(0, 3)
    RefreshCorner.Parent = RefreshBtn

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 14, 0, 14)
    MinBtn.Position = UDim2.new(1, -58, 0.5, -7)
    MinBtn.BackgroundColor3 = Theme.Tertiary
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Theme.Text
    MinBtn.TextSize = 11
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Header

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 3)
    MinCorner.Parent = MinBtn

    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 14, 0, 14)
    Close.Position = UDim2.new(1, -20, 0.5, -7)
    Close.BackgroundColor3 = Theme.Tertiary
    Close.Text = "X"
    Close.TextColor3 = Theme.Text
    Close.TextSize = 8
    Close.Font = Enum.Font.GothamBold
    Close.AutoButtonColor = false
    Close.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 3)
    CloseCorner.Parent = Close

    Close.MouseButton1Click:Connect(function() InfoGui:Destroy() end)
    SetupMinimize(MinBtn, Frame, FULL_H)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -8, 1, -28)
    Content.Position = UDim2.new(0, 4, 0, 24)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.Position = UDim2.new(0, 0, 0, 0)
    Scroll.BackgroundColor3 = Theme.Secondary
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 2
    Scroll.ScrollBarImageColor3 = Theme.Stroke
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.Parent = Content

    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 4)
    ScrollCorner.Parent = Scroll

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 3)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Scroll

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 4)
    Padding.PaddingLeft = UDim.new(0, 4)
    Padding.PaddingRight = UDim.new(0, 4)
    Padding.PaddingBottom = UDim.new(0, 4)
    Padding.Parent = Scroll

    local function GetMembershipName(mem)
        if mem == Enum.MembershipType.Premium then return "Premium"
        elseif mem == Enum.MembershipType.BuildersClub then return "BC"
        elseif mem == Enum.MembershipType.TurboBuildersClub then return "TBC"
        elseif mem == Enum.MembershipType.OutrageousBuildersClub then return "OBC"
        else return "None" end
    end

    local function BuildCompactInfo(player)
        local role = DetectRole(player)
        local lines = {}
        table.insert(lines, "@" .. player.Name)
        table.insert(lines, player.DisplayName)
        table.insert(lines, "UID: " .. player.UserId)
        table.insert(lines, "Age: " .. player.AccountAge .. "d | " .. GetMembershipName(player.MembershipType))
        table.insert(lines, "Role: " .. role)

        local ping = "N/A"
        pcall(function()
            ping = math.floor(player:GetNetworkPing() * 1000) .. "ms"
        end)
        table.insert(lines, "Ping: " .. ping)

        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hum then
                table.insert(lines, "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. " (" .. (hum.Health > 0 and "Alive" or "Dead") .. ")")
            end
            if hrp and HRP then
                local dist = math.floor((hrp.Position - HRP.Position).Magnitude)
                table.insert(lines, "Dist: " .. dist .. " studs")
            end
        else
            table.insert(lines, "Status: No Char")
        end

        return table.concat(lines, "\n")
    end

    local function RefreshInfo()
        for _, child in pairs(Scroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local players = Players:GetPlayers()
        table.sort(players, function(a, b) return a.Name:lower() < b.Name:lower() end)

        for _, player in pairs(players) do
            local isLocal = player == LocalPlayer
            local role = DetectRole(player)
            local roleColor = ESPPlayerUsernameColors[role] or Theme.Text

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -6, 0, 90)
            card.BackgroundColor3 = Theme.Tertiary
            card.BorderSizePixel = 0
            card.Parent = Scroll

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 4)
            cardCorner.Parent = card

            local cardStroke = Instance.new("UIStroke")
            cardStroke.Color = isLocal and Theme.ButtonSuccess or Theme.Stroke
            cardStroke.Thickness = isLocal and 1.5 or 1
            cardStroke.Parent = card

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -8, 0, 13)
            nameLbl.Position = UDim2.new(0, 4, 0, 3)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = player.DisplayName .. (isLocal and " [YOU]" or "")
            nameLbl.TextColor3 = roleColor
            nameLbl.TextSize = 8
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = card

            local body = Instance.new("TextLabel")
            body.Size = UDim2.new(1, -8, 1, -18)
            body.Position = UDim2.new(0, 4, 0, 16)
            body.BackgroundTransparency = 1
            body.Text = BuildCompactInfo(player)
            body.TextColor3 = Theme.TextDim
            body.TextSize = 7
            body.Font = Enum.Font.Gotham
            body.TextXAlignment = Enum.TextXAlignment.Left
            body.TextYAlignment = Enum.TextYAlignment.Top
            body.TextWrapped = true
            body.Parent = card
        end

        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 8)
    end

    RefreshInfo()
    RefreshBtn.MouseButton1Click:Connect(function() RefreshInfo() end)

    spawn(function()
        while InfoGui.Parent do
            wait(3)
            if InfoGui.Parent then pcall(RefreshInfo) end
        end
    end)

    MakeDraggable(Frame, Header)
    NotifyGuiOpened("Get Player Info")
end)

-- MISC TAB
Hub:CreateButton(MiscTab, "Rejoin Server", Theme.ButtonInfo, function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
Hub:CreateButton(MiscTab, "Server Hop", Theme.ButtonInfo, function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
Hub:CreateButton(MiscTab, "Destroy Hub", Theme.ButtonDanger, function()
    Window.ScreenGui:Destroy()
end)

-- ============================================
-- MAIN SYNC LOOP
-- ============================================
spawn(function()
    while wait(0.2) do
        FeatureManager:Sync()
        if Toggles.ESPPlayer then ESPPlayerFeature:Refresh() end
        if Toggles.ESPOutline then ESPOutlineFeature:Refresh() end
    end
end)

-- PERMANENT ANTI-DAMAGE GUARD
spawn(function()
    while true do
        task.wait(0.05)
        if Toggles.GodMode and Humanoid and Humanoid.Parent then
            pcall(function()
                if Humanoid.Health < Humanoid.MaxHealth then
                    Humanoid.Health = Humanoid.MaxHealth
                end
                if Humanoid.MaxHealth < 100 then
                    Humanoid.MaxHealth = 100
                end
            end)
        end
    end
end)

-- ============================================
-- WALK/JUMP: ABSOLUTE VALUE
-- ============================================
task.wait(0.5)
if Humanoid and Humanoid.Parent then
    CaptureBase(Humanoid)
    ApplyWalkJump(Humanoid)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")

    getgenv().BaseWalkSpeed = nil
    getgenv().BaseJumpPower = nil

    task.wait(0.3)
    if Humanoid and Humanoid.Parent then
        CaptureBase(Humanoid)
        ApplyWalkJump(Humanoid)
    end

    if Toggles.GodMode then
        GodModeFeature:Stop()
        task.wait(0.1)
        GodModeFeature:Start()
    end
end)

spawn(function()
    while true do
        task.wait(0.15)
        if Humanoid and Humanoid.Parent then
            if not getgenv().BaseWalkSpeed or getgenv().BaseWalkSpeed <= 0 then
                local ws = Humanoid.WalkSpeed
                if ws > 0 then
                    getgenv().BaseWalkSpeed = ws
                end
            end
            if not getgenv().BaseJumpPower or getgenv().BaseJumpPower <= 0 then
                local jp = Humanoid.JumpPower
                if jp > 0 then
                    getgenv().BaseJumpPower = jp
                end
            end

            local userSpeed = Settings.Speed or 0
            local userJump = Settings.Jump or 0

            local targetWS
            local targetJP

            if userSpeed > 0 then
                targetWS = userSpeed
            else
                targetWS = getgenv().BaseWalkSpeed or 16
            end

            if userJump > 0 then
                targetJP = userJump
            else
                targetJP = getgenv().BaseJumpPower or 50
            end

            if Humanoid.WalkSpeed ~= targetWS then
                pcall(function() Humanoid.WalkSpeed = targetWS end)
            end
            if Humanoid.JumpPower ~= targetJP then
                pcall(function()
                    Humanoid.UseJumpPower = true
                    Humanoid.JumpPower = targetJP
                end)
            end
        end
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Ultimate Volt Hub",
        Text = "Loaded Successfully!",
        Duration = 5
    })
end)

print("Ultimate Volt Hub Loaded")