--[[
    Sci-Fi UI Library Advanced Loader
    Powered by: logquickly/SciFi-UI-Library
    Features: Advanced Loading, Config System, Rainbow Borders, Sound Effects
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

-- // 配置区域 //
local LoaderConfig = {
    ThemeColor = Color3.fromRGB(0, 255, 255), -- 默认科幻青色
    SoundEffects = true,
    Folder = "SciFi_Config_System", -- Config保存的文件夹名
    AutoLoad = false, -- 是否自动载入默认Config
    FileName = "default.json" -- 默认Config文件名
}

-- // 音效库 //
local Sounds = {
    Load = "rbxassetid://6895079853", -- 科技感启动音效
    ConfigLoad = "rbxassetid://6035677329", -- Config载入成功音效 (清脆)
    Click = "rbxassetid://6895079603" -- 点击音效
}

-- // 辅助函数: 播放声音 //
local function PlaySound(id, volume)
    if not LoaderConfig.SoundEffects then return end
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume or 1
    sound.Parent = workspace
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- // 1. 高级载入动画 (Advanced Loading Animation) //
local function PlayIntro()
    -- 创建临时的 Loading GUI
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "SciFi_Intro"
    IntroGui.Parent = CoreGui
    IntroGui.IgnoreGuiInset = true
    
    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    Background.BackgroundTransparency = 0
    Background.Parent = IntroGui
    
    -- 旋转的圆环
    local Spinner = Instance.new("ImageLabel")
    Spinner.Size = UDim2.new(0, 150, 0, 150)
    Spinner.Position = UDim2.new(0.5, -75, 0.4, -75)
    Spinner.BackgroundTransparency = 1
    Spinner.Image = "rbxassetid://6895075647" -- 一个科技感的圆环图片
    Spinner.ImageColor3 = LoaderConfig.ThemeColor
    Spinner.ImageTransparency = 1
    Spinner.Parent = Background
    
    -- 文字
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(0, 300, 0, 50)
    TextLabel.Position = UDim2.new(0.5, -150, 0.55, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 24
    TextLabel.Text = "SYSTEM INITIALIZING..."
    TextLabel.TextTransparency = 1
    TextLabel.Parent = Background

    -- 动画序列
    PlaySound(Sounds.Load, 1.5)
    
    -- 淡入
    TweenService:Create(Spinner, TweenInfo.new(1), {ImageTransparency = 0}):Play()
    TweenService:Create(TextLabel, TweenInfo.new(1), {TextTransparency = 0}):Play()
    
    -- 旋转
    local spinAnim = TweenService:Create(Spinner, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
    spinAnim:Play()
    
    wait(2.5)
    
    -- 收尾
    spinAnim:Cancel()
    TweenService:Create(Background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Spinner, TweenInfo.new(0.5), {ImageTransparency = 1, Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.4, 0)}):Play()
    TweenService:Create(TextLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    
    wait(0.5)
    IntroGui:Destroy()
end

-- 播放开场动画
PlayIntro()

-- // 2. 载入你的 UI 库 //
-- 注意：这里载入的是你提供的 GitHub 链接
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/SciFi-UI-Library/refs/heads/main/source.lua"))()

-- 假设你的库返回一个 Window 对象，或者我们需要创建一个
-- 如果你的库API不同，请在这里调整
local Window = Library:CreateWindow({
    Name = "Sci-Fi Injector",
    Themeable = {
        Info = "Sci-Fi Theme"
    }
})

-- // 3. 功能实现：彩虹边框与透明度 //
local RainbowEnabled = false
local RainbowSpeed = 0.5
local CurrentTransparency = 0.1

-- 查找主窗口 (这需要根据你库的实际生成的 GUI 结构来调整，这里假设是找到 ScreenGui 下的第一个 Frame)
local MainFrame = nil
for _, gui in pairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui:FindFirstChild("Main") then -- 假设主框架叫 Main
        MainFrame = gui.Main
        break
    end
end
-- 如果没找到，尝试通过库对象获取 (视你库的具体实现而定)

-- 彩虹逻辑 Loop
RunService.RenderStepped:Connect(function()
    if RainbowEnabled and MainFrame then
        local hue = tick() * RainbowSpeed % 1
        local color = Color3.fromHSV(hue, 1, 1)
        
        -- 假设有一个 UIStroke 或 Border
        if MainFrame:FindFirstChild("UIStroke") then
            MainFrame.UIStroke.Color = color
        else
            MainFrame.BorderColor3 = color
        end
    end
    
    if MainFrame then
        MainFrame.BackgroundTransparency = CurrentTransparency
    end
end)


-- // 4. Config 系统逻辑 (带闪烁特效) //

-- 检查文件夹
if not isfolder(LoaderConfig.Folder) then
    makefolder(LoaderConfig.Folder)
end

local function FlashScreen()
    -- 创建全屏闪烁效果
    local FlashGui = Instance.new("ScreenGui", CoreGui)
    local FlashFrame = Instance.new("Frame", FlashGui)
    FlashFrame.Size = UDim2.new(1,0,1,0)
    FlashFrame.BackgroundColor3 = LoaderConfig.ThemeColor
    FlashFrame.BackgroundTransparency = 0.6
    FlashFrame.BorderSizePixel = 0
    
    PlaySound(Sounds.ConfigLoad, 2)
    
    local tween = TweenService:Create(FlashFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Connect(function()
        FlashGui:Destroy()
    end)
end

local function SaveConfig(name)
    local path = LoaderConfig.Folder .. "/" .. name .. ".json"
    -- 这里需要获取你 UI 库中所有 Toggle/Slider 的当前值
    -- 由于我是外部脚本，我模拟一个数据
    local data = {
        RainbowBorder = RainbowEnabled,
        Transparency = CurrentTransparency,
        -- 这里你可以添加更多你想保存的变量
    }
    writefile(path, HttpService:JSONEncode(data))
end

local function LoadConfig(name)
    local path = LoaderConfig.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        local data = HttpService:JSONDecode(readfile(path))
        
        -- 应用设置
        if data.RainbowBorder ~= nil then RainbowEnabled = data.RainbowBorder end
        if data.Transparency ~= nil then CurrentTransparency = data.Transparency end
        
        -- 触发特效
        FlashScreen()
    end
end

-- // 5. 构建 UI 菜单 (Tab 和 元素) //

local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")

-- -> Main Tab 内容
MainTab:CreateSection("Visuals")

MainTab:CreateToggle({
    Name = "Rainbow Border",
    CurrentValue = false,
    Flag = "RainbowToggle",
    Callback = function(Value)
        RainbowEnabled = Value
    end
})

MainTab:CreateSlider({
    Name = "Menu Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.1,
    Flag = "TransSlider",
    Callback = function(Value)
        CurrentTransparency = Value
    end
})

-- 圆形调色盘 (如果你的库自带 ColorPicker)
MainTab:CreateColorPicker({
    Name = "Theme Color",
    Default = LoaderConfig.ThemeColor,
    Flag = "ColorPicker",
    Callback = function(Value)
        LoaderConfig.ThemeColor = Value
        -- 这里也可以写代码让 UI 的主色调变成这个颜色
    end
})

-- -> Settings Tab 内容 (Config & System)
SettingsTab:CreateSection("Configuration")

local ConfigNameInput = "default"

SettingsTab:CreateInput({
    Name = "Config Name",
    PlaceholderText = "Enter name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        ConfigNameInput = Text
    end
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        SaveConfig(ConfigNameInput)
    end
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        LoadConfig(ConfigNameInput)
    end
})

SettingsTab:CreateToggle({
    Name = "Auto Load Config",
    CurrentValue = false,
    Callback = function(Value)
        LoaderConfig.AutoLoad = Value
        -- 保存这个设置以便下次脚本启动时读取(需要额外逻辑)
    end
})

SettingsTab:CreateSection("System")

SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end
})

SettingsTab:CreateButton({
    Name = "Close UI",
    Callback = function()
        -- 销毁 UI
        if MainFrame and MainFrame.Parent then MainFrame.Parent:Destroy() end
        -- 也可以调用 Library:Destroy() 如果你的库支持
    end
})

-- // 自动载入逻辑 //
if LoaderConfig.AutoLoad then
    task.delay(1, function()
        LoadConfig(LoaderConfig.FileName)
    end)
end
