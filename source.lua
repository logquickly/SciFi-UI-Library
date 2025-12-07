--// Grok - Sci-Fi Rainbow UI Library 2025
--// 支持彩虹渐变边框 + 圆形调色盘 + 高级加载动画 + Config系统

local Library = {
    Theme = {
        Accent = Color3.fromHSV(0.7, 1, 1),
        RainbowSpeed = 2,
        Transparency = 0.05,
        AutoLoadConfig = false,
        ConfigName = "DefaultConfig"
    },
    Connections = {},
    Configs = {}
}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

--// 音效（科幻感拉满）
local LoadSound = Instance.new("Sound")
LoadSound.SoundId = "rbxassetid://8994201543"  -- 超清脆科技启动音
LoadSound.Volume = 0.7

local ConfigLoadSound = Instance.new("Sound")
ConfigLoadSound.SoundId = "rbxassetid://9083226380"  -- 深空能量脉冲
ConfigLoadSound.Volume = 0.8

local CloseSound = Instance.new("Sound")
CloseSound.SoundId = "rbxassetid://9112853840"    -- 关机音效
CloseSound.Volume = 0.6

--// 主GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SciFiLibrary"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 540)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -270)
MainFrame.BackgroundTransparency = Library.Theme.Transparency
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

--// 彩虹渐变边框（超级科幻）
local Border = Instance.new("Frame")
Border.Size = UDim2.new(1, 8, 1, 8)
Border.Position = UDim2.new(0, -4, 0, -4)
Border.BackgroundTransparency = 1
Border.ZIndex = 0
Border.Parent = MainFrame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
    ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
    ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
    ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
}
Gradient.Rotation = 0
Gradient.Parent = Border

local BorderImage = Instance.new("ImageLabel")
BorderImage.Size = UDim2.new(1, 0, 1, 0)
BorderImage.BackgroundTransparency = 1
BorderImage.Image = "rbxassetid://18033780023"  -- 未来科技发光边框贴图
BorderImage.ImageTransparency = 0.3
BorderImage.ZIndex = -1
BorderImage.Parent = Border

--// 标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 400, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ＧＲＯＫ ＳＣＩ－ＦＩ ＬＩＢＲＡＲＹ"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

--// 彩虹动画循环
table.insert(Library.Connections, RunService.Heartbeat:Connect(function()
    local hue = tick() * Library.Theme.RainbowSpeed % 1
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
        ColorSequenceKeypoint.new(0.16, Color3.fromHSV((hue + 0.16) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV((hue + 0.33) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue + 0.5) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV((hue + 0.66) % 1, 1, 1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV((hue + 0.83) % 1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV((hue + 1) % 1, 1, 1))
    }
    Title.TextColor3 = Color3.fromHSV(hue, 1, 1)
    Library.Theme.Accent = Color3.fromHSV(hue, 1, 1)
end))

--// 圆形调色盘（超帅）
local ColorPickerFrame = Instance.new("Frame")
ColorPickerFrame.Size = UDim2.new(0, 200, 0, 200)
ColorPickerFrame.Position = UDim2.new(1, -230, 0, 70)
ColorPickerFrame.BackgroundTransparency = 1
ColorPickerFrame.Parent = MainFrame

local Wheel = Instance.new("ImageLabel")
Wheel.Size = UDim2.new(0, 180, 0, 180)
Wheel.Position = UDim2.new(0, 10, 0, 10)
Wheel.BackgroundTransparency = 1
Wheel.Image = "rbxassetid://6020299385"  -- 经典HSV色轮
Wheel.Parent = ColorPickerFrame

local Picker = Instance.new("ImageLabel")
Picker.Size = UDim2.new(0, 20, 0, 20)
Picker.BackgroundTransparency = 1
Picker.Image = "rbxassetid://9437972419"
Picker.ZIndex = 10
Picker.Parent = Wheel

local ColorDisplay = Instance.new("Frame")
ColorDisplay.Size = UDim2.new(0, 180, 0, 30)
ColorDisplay.Position = UDim2.new(0, 10, 0, 200)
ColorDisplay.BackgroundColor3 = Library.Theme.Accent
ColorDisplay.Parent = ColorPickerFrame

--// 拖动调色盘
local dragging = false
Wheel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
end)

Wheel.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging then
        local mousePos = Vector2.new(Mouse.X - Wheel.AbsolutePosition.X, Mouse.Y - Wheel.AbsolutePosition.Y)
        local center = Vector2.new(90, 90)
        local direction = (mousePos - center)
        local distance = math.min(direction.Magnitude, 80)
        local angle = math.atan2(direction.Y, direction.X)
        
        Picker.Position = UDim2.new(0, center.X + distance * math.cos(angle) - 10, 0, center.Y + distance * math.sin(angle) - 10)
        
        local hue = (angle + math.pi) / (math.pi * 2)
        local saturation = distance / 80
        Library.Theme.Accent = Color3.fromHSV(hue, saturation, 1)
        ColorDisplay.BackgroundColor3 = Library.Theme.Accent
    end
end)

--// 预设颜色按钮
local Presets = {
    Color3.fromRGB(255, 0, 127),   -- 热粉
    Color3.fromRGB(0, 255, 255),   -- 青色
    Color3.fromRGB(255, 215, 0),   -- 金色
    Color3.fromRGB(138, 43, 226),  -- 紫罗兰
    Color3.fromRGB(0, 255, 100)    -- 春绿
}

for i, color in ipairs(Presets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(0, 10 + (i-1)*35, 0, 240)
    btn.BackgroundColor3 = color
    btn.Text = ""
    btn.Parent = ColorPickerFrame
    
    btn.MouseButton1Click:Connect(function()
        Library.Theme.Accent = color
        ColorDisplay.BackgroundColor3 = color
    end)
end

--// 高级加载动画
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 20)
LoadingFrame.ZIndex = 999
LoadingFrame.Parent = ScreenGui

local ScanLine = Instance.new("Frame")
ScanLine.Size = UDim2.new(1, 0, 0, 4)
ScanLine.BackgroundColor3 = Library.Theme.Accent
ScanLine.Position = UDim2.new(0, 0, 0, -4)
ScanLine.Parent = LoadingFrame

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 600, 0, 150)
Logo.Position = UDim2.new(0.5, -300, 0.5, -100)
Logo.BackgroundTransparency = 1
Logo.Text = "ＧＲＯＫ  ＬＩＢＲＡＲＹ"
Logo.TextColor3 = Color3.fromRGB(0, 255, 255)
Logo.Font = Enum.Font.SciFi
Logo.TextSize = 80
Logo.Parent = LoadingFrame

--// 执行加载动画
spawn(function()
    LoadSound:Play()
    for i = 1, 3 do
        TweenService:Create(ScanLine, TweenInfo.new(0.6), {Position = UDim2.new(0,0,1,0)}):Play()
        wait(0.7)
        ScanLine.Position = UDim2.new(0,0,0,-4)
    end
    wait(0.5)
    LoadingFrame:TweenPosition(UDim2.new(0,0,-1,0), "Out", "Quad", 0.8)
    wait(0.8)
    LoadingFrame:Destroy()
end)

--// 设置页面
local SettingsFrame = Instance.new("ScrollingFrame")
SettingsFrame.Size = UDim2.new(0, 420, 1, -60)
SettingsFrame.Position = UDim2.new(0, 20, 0, 60)
SettingsFrame.BackgroundTransparency = 1
SettingsFrame.ScrollBarThickness = 4
SettingsFrame.Parent = MainFrame

local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 50)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 18
    btn.Text = "  " .. text
    btn.AutoButtonColor = false
    btn.Parent = SettingsFrame
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 12)
    
    local glow = Instance.new("UIStroke", btn)
    glow.Color = Library.Theme.Accent
    glow.Thickness = 2
    glow.Transparency = 0.5
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(glow, TweenInfo.new(0.3), {Transparency = 0}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(glow, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

--// Config系统
local ConfigBox = Instance.new("TextBox")
ConfigBox.Size = UDim2.new(1, -20, 0, 50)
ConfigBox.Position = UDim2.new(0, 10, 0, 10)
ConfigBox.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
ConfigBox.PlaceholderText = "输入Config名称..."
ConfigBox.Text = Library.Theme.ConfigName
ConfigBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfigBox.Parent = SettingsFrame

local SaveBtn = CreateButton("保存当前Config", function()
    Library.Configs[ConfigBox.Text] = {
        Accent = Library.Theme.Accent,
        Transparency = Library.Theme.Transparency,
        RainbowSpeed = Library.Theme.RainbowSpeed
    }
    ConfigBox.Text = ConfigBox.Text .. " (已保存)"
    wait(1)
    ConfigBox.Text = Library.Configs[ConfigBox.Text:gsub(" %(已保存%)", "")] and ConfigBox.Text:gsub(" %(已保存%)", "") or ConfigBox.Text
end)

local LoadBtn = CreateButton("加载Config（闪烁+音效）", function()
    local config = Library.Configs[ConfigBox.Text]
    if config then
        ConfigLoadSound:Play()
        
        -- 全屏主题色闪烁
        local Flash = Instance.new("Frame")
        Flash.Size = UDim2.new(1,0,1,0)
        Flash.BackgroundColor3 = config.Accent
        Flash.ZIndex = 999
        Flash.BackgroundTransparency = 0.3
        Flash.Parent = ScreenGui
        
        TweenService:Create(Flash, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        game.Debris:AddItem(Flash, 0.3)
        
        Library.Theme.Accent = config.Accent
        Library.Theme.Transparency = config.Transparency
        Library.Theme.RainbowSpeed = config.RainbowSpeed
        
        MainFrame.BackgroundTransparency = config.Transparency
        ColorDisplay.BackgroundColor3 = config.Accent
    end
end)

CreateButton("重新加入服务器", function()
    TeleportService:Teleport(game.PlaceId, Player)
end)

CreateButton("关闭库（释放所有功能）", function()
    CloseSound:Play()
    ScreenGui:TweenPosition(UDim2.new(0.5, -340, -1, 0), "Out", "Back", 0.8)
    wait(0.9)
    ScreenGui:Destroy()
    for _, conn in pairs(Library.Connections) do
        conn:Disconnect()
    end
end)

--// 自动加载Config
if Library.Theme.AutoLoadConfig and Library.Configs[Library.Theme.ConfigName] then
    wait(2)
    LoadBtn.MouseButton1Click:Fire()
end

--// 返回库主函数
function Library:CreateWindow(name)
    local Window = {}
    local TabFrame = Instance.new("Frame")
    TabFrame.Size = UDim2.new(0, 180, 1, -60)
    TabFrame.Position = UDim2.new(0, 20, 0, 60)
    TabFrame.BackgroundTransparency = 0.9
    TabFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    TabFrame.Parent = MainFrame
    
    return Window
end

--// 拖拽功能
local dragging = false
local dragInput
local dragStart
local startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

return Library
