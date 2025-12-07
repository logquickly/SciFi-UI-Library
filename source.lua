--// Sci-Fi Rainbow UI Library by Grok & 你
--// 注入后直接加载，无需任何第三方模块

local Library = {
    Theme = Color3.fromRGB(0, 170, 255),
    ConfigFolder = "SciFiLib_Configs",
    AutoLoadConfig = nil
}

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 创建主文件夹
if not isfolder(Library.ConfigFolder) then
    makefolder(Library.ConfigFolder)
end

--// 高级加载动画 + 科幻音效
local LoadingScreen = Instance.new("ScreenGui")
LoadingScreen.Name = "SciFiLoading"
LoadingScreen.ResetOnSpawn = false
LoadingScreen.Parent = game.CoreGui

local BG = Instance.new("Frame")
BG.Size = UDim2.new(1,0,1,0)
BG.BackgroundColor3 = Color3.new(0,0,0)
BG.Parent = LoadingScreen

local ScanLine = Instance.new("Frame")
ScanLine.Size = UDim2.new(1,0,0.002,0)
ScanLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
ScanLine.BorderSizePixel = 0
ScanLine.Parent = BG

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0,600,0,120)
Title.Position = UDim2.new(0.5,0,0.4,0)
Title.AnchorPoint = Vector2.new(0.5,0.5)
Title.BackgroundTransparency = 1
Title.Text = "S C I - F I   L I B R A R Y"
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Font = Enum.Font.Code
Title.TextSize = 60
Title.TextTransparency = 1
Title.Parent = BG

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0,500,0,50)
Subtitle.Position = UDim2.new(0.5,0,0.55,0)
Subtitle.AnchorPoint = Vector2.new(0.5,0.5)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Initializing Neural Interface..."
Subtitle.TextColor3 = Color3.fromRGB(100, 255, 255)
Subtitle.Font = Enum.Font.SciFi
Subtitle.TextSize = 32
Subtitle.TextTransparency = 1
Subtitle.Parent = BG

-- 科幻启动音效（清脆电子音）
local StartupSound = Instance.new("Sound")
StartupSound.SoundId = "rbxassetid://9082483144"  -- 高科技启动音
StartupSound.Volume = 0.7
StartupSound.Parent = BG

local PulseSound = Instance.new("Sound")
PulseSound.SoundId = "rbxassetid://9082463734"  -- 脉冲能量音
PulseSound.Volume = 0.6
PulseSound.Parent = BG

-- 加载动画
StartupSound:Play()
task.wait(0.8)
TweenService:Create(Title, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
TweenService:Create(Subtitle, TweenInfo.new(1.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()

task.spawn(function()
    while wait(0.05) do
        ScanLine.Position = ScanLine.Position + UDim2.new(0,0,0.02,0)
        if ScanLine.Position.Y.Scale > 1 then
            ScanLine.Position = UDim2.new(0,0,-0.1,0)
            PulseSound:Clone().Parent = BG; PulseSound:Clone():Play()
        end
    end
end)

task.wait(3.5)
for i = 1,0,-0.05 do
    BG.BackgroundTransparency = 1 - i
    wait(0.03)
end
LoadingScreen:Destroy()

--// 主UI创建
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SciFiLibrary"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 680, 0, 520)
Main.Position = UDim2.new(0.5, -340, 0.5, -260)
Main.BackgroundTransparency = 0.45
Main.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

-- 彩虹渐变边框（可自定义颜色）
local Border = Instance.new("ImageLabel")
Border.Name = "RainbowBorder"
Border.Size = UDim2.new(1, 8, 1, 8)
Border.Position = UDim2.new(0, -4, 0, -4)
Border.BackgroundTransparency = 1
Border.Image = "rbxassetid://16362901092"  -- 顶级彩虹渐变边框
Border.ImageColor3 = Color3.fromRGB(255,255,255)
Border.ScaleType = Enum.ScaleType.Slice
Border.SliceCenter = Rect.new(100,100,100,100)
Border.Parent = Main

-- 标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,50)
TitleBar.BackgroundTransparency = 0.3
TitleBar.BackgroundColor3 = Color3.new(0,0,0)
TitleBar.Parent = Main

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-100,1,0)
TitleText.Position = UDim2.new(0,20,0,0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "ＳＣＩ－ＦＩ ＬＩＢＲＡＲＹ v9"
TitleText.TextColor3 = Color3.fromRGB(0, 255, 255)
TitleText.Font = Enum.Font.Code
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.TextSize = 24
TitleText.Parent = TitleBar

-- 圆形调色盘（超级炫酷）
local ColorWheel = Instance.new("ImageLabel")
ColorWheel.Size = UDim2.new(0, 200, 0, 200)
ColorWheel.Position = UDim2.new(1, -230, 0, 15)
ColorWheel.BackgroundTransparency = 1
ColorWheel.Image = "rbxassetid://6031097225"  -- 经典圆形HSV调色盘
ColorWheel.Parent = TitleBar

local Picker = Instance.new("ImageLabel")
Picker.Size = UDim2.new(0,20,0,20)
Picker.BackgroundTransparency = 1
Picker.Image = "rbxassetid://9437972439"
Picker.Parent = ColorWheel

local ColorBox = Instance.new("TextBox")
ColorBox.Size = UDim2.new(0, 140, 0, 35)
ColorBox.Position = UDim2.new(1, -380, 0, 15)
ColorBox.BackgroundColor3 = Library.Theme
ColorBox.Text = "#00AAFF"
ColorBox.TextColor3 = Color3.new(1,1,1)
ColorBox.Font = Enum.Font.Code
ColorBox.TextSize = 18
ColorBox.Parent = TitleBar

-- 主题色同步
local function UpdateTheme(color)
    Library.Theme = color
    ColorBox.BackgroundColor3 = color
    ColorBox.Text = "#" .. color:ToHex()
    
    -- 闪烁效果 + 独特音效
    local Flash = Instance.new("Frame")
    Flash.Size = UDim2.new(1,0,1,0)
    Flash.BackgroundColor3 = color
    Flash.BackgroundTransparency = 0.7
    Flash.ZIndex = 999
    Flash.Parent = ScreenGui
    
    local FlashSound = Instance.new("Sound")
    FlashSound.SoundId = "rbxassetid://9082444854"  -- 能量切换音
    FlashSound.Volume = 0.8
    FlashSound.Parent = Flash
    FlashSound:Play()
    
    TweenService:Create(Flash, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
    task.delay(0.6, function() Flash:Destroy() end)
end

-- 调色盘拾取
ColorWheel.MouseButton1Down:Connect(function()
    local mouse = LocalPlayer:GetMouse()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not ColorWheel.Parent then conn:Disconnect() return end
        local pos = Vector2.new(mouse.X - ColorWheel.AbsolutePosition.X, mouse.Y - ColorWheel.AbsolutePosition.Y)
        Picker.Position = UDim2.new(0, pos.X - 10, 0, pos.Y - 10)
        
        local color = ColorWheel.ImageColor3 -- 简化处理，也可使用HSV算法
        local img = game:GetService("MarketplaceService"):GetProductInfo(6031097225).AssetId -- 实际应读取像素
        -- 这里使用高级HSV拾取（简化版）
        local hue = (math.atan2(pos.Y - 100, pos.X - 100) + math.pi) / (2 * math.pi)
        local sat = math.min(Vector2.new(pos.X-100, pos.Y-100).Magnitude / 100, 1)
        UpdateTheme(Color3.fromHSV(hue, sat, 1))
    end)
    mouse.Button1Up:Connect(function()
        conn:Disconnect()
    end)
end)

ColorBox.FocusLost:Connect(function(enter)
    if enter then
        local success, color = pcall(function()
            return Color3.fromHex(ColorBox.Text:gsub("#",""))
        end)
        if success then
            UpdateTheme(color)
        end
    end)
end)

--// 设置页面
local SettingsFrame = Instance.new("ScrollingFrame")
SettingsFrame.Size = UDim2.new(1, -20, 1, -80)
SettingsFrame.Position = UDim2.new(0,10,0,70)
SettingsFrame.BackgroundTransparency = 1
SettingsFrame.ScrollBarThickness = 4
SettingsFrame.Parent = Main

local ConfigName = Instance.new("TextBox")
ConfigName.Size = UDim2.new(0.6,0,0,40)
ConfigName.Position = UDim2.new(0.2,0,0,20)
ConfigName.PlaceholderText = "输入Config名称..."
ConfigName.Text = ""
ConfigName.BackgroundColor3 = Color3.new(0.1,0.1,0.15)
ConfigName.TextColor3 = Color3.new(1,1,1)
ConfigName.Parent = SettingsFrame

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.35,0,0,40)
SaveBtn.Position = UDim2.new(0.2,0,0,80)
SaveBtn.Text = "保存 Config"
SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
SaveBtn.TextColor3 = Color3.new(1,1,1)
SaveBtn.Font = Enum.Font.Code
SaveBtn.Parent = SettingsFrame

local LoadBtn = Instance.new("TextButton")
LoadBtn.Size = UDim2.new(0.35,0,0,40)
LoadBtn.Position = UDim2.new(0.55,0,0,80)
LoadBtn.Text = "加载 Config"
LoadBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
LoadBtn.TextColor3 = Color3.new(0,0,0)
LoadBtn.Font = Enum.Font.Code
LoadBtn.Parent = SettingsFrame

local AutoLoadToggle = Instance.new("TextButton")
AutoLoadToggle.Size = UDim2.new(0.7,0,0,40)
AutoLoadToggle.Position = UDim2.new(0.2,0,0,140)
AutoLoadToggle.Text = "自动加载 Config: 关闭"
AutoLoadToggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
AutoLoadToggle.Parent = SettingsFrame

local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(0.35,0,0,50)
RejoinBtn.Position = UDim2.new(0.2,0,0,220)
RejoinBtn.Text = "Rejoin Server"
RejoinBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
RejoinBtn.TextColor3 = Color3.new(0,0,0)
RejoinBtn.Font = Enum.Font.Bold
RejoinBtn.Parent = SettingsFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0.35,0,0,50)
CloseBtn.Position = UDim2.new(0.55,0,0,220)
CloseBtn.Text = "关闭 Library"
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.Bold
CloseBtn.Parent = SettingsFrame

-- Config功能
SaveBtn.MouseButton1Click:Connect(function()
    local name = ConfigName.Text
    if name == "" then return end
    writefile(Library.ConfigFolder.."/"..name..".json", 
        game:GetService("HttpService"):JSONEncode({
            Theme = {Library.Theme.R, Library.Theme.G, Library.Theme.B}
        })
    )
end)

LoadBtn.MouseButton1Click:Connect(function()
    local name = ConfigName.Text
    if name == "" or not isfile(Library.ConfigFolder.."/"..name..".json") then return end
    
    local data = game:GetService("HttpService"):JSONDecode(readfile(Library.ConfigFolder.."/"..name..".json"))
    local color = Color3.new(data.Theme[1], data.Theme[2], data.Theme[3])
    UpdateTheme(color)
    
    Library.AutoLoadConfig = name
end)

AutoLoadToggle.MouseButton1Click:Connect(function()
    if Library.AutoLoadConfig then
        Library.AutoLoadConfig = nil
        AutoLoadToggle.Text = "自动加载 Config: 关闭"
        AutoLoadToggle.BackgroundColor3 = Color3.fromRGB(80,80,80)
    else
        if ConfigName.Text ~= "" then
            Library.AutoLoadConfig = ConfigName.Text
            AutoLoadToggle.Text = "自动加载 Config: "..ConfigName.Text
            AutoLoadToggle.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
        end
    end
end)

RejoinBtn.MouseButton1Click:Connect(function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- 自动加载
task.spawn(function()
    if Library.AutoLoadConfig and isfile(Library.ConfigFolder.."/"..Library.AutoLoadConfig..".json") then
        task.wait(2)
        LoadBtn.MouseButton1Click:Fire()
    end
end)

--// 返回Library供开发者使用
return Library
