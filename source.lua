--[[
    🚀 Sci-Fi UI Library - Advanced Loader / Injector
    Project: https://github.com/logquickly/SciFi-UI-Library
    Features: Rainbow Border, Transparency Control, Config System, SFX
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

-- // 1. 全局配置与变量 //
local LoaderConfig = {
    Folder = "SciFi_Injector_Config", -- 配置文件保存在 workspace 的文件夹名
    ThemeColor = Color3.fromRGB(0, 255, 255), -- 默认科技青
    SoundEnabled = true,
    CurrentTransparency = 0.1,
    RainbowBorder = false,
    RainbowSpeed = 0.5,
    AutoLoad = false,
    DefaultConfigName = "default"
}

-- 音效 ID
local Sounds = {
    Boot = "rbxassetid://6895079853",      -- 启动音效
    ConfigLoad = "rbxassetid://6035677329", -- 配置读取成功 (清脆)
    Click = "rbxassetid://6895079603"       -- 点击
}

-- // 2. 辅助工具函数 //
local function PlaySound(id, volume)
    if not LoaderConfig.SoundEnabled then return end
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = volume or 1
    sound.Parent = workspace
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
end

-- // 3. 高级载入动画 (Intro Animation) //
local function PlayIntro()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "SciFi_Loader_Intro"
    IntroGui.Parent = CoreGui
    IntroGui.IgnoreGuiInset = true
    
    local BG = Instance.new("Frame", IntroGui)
    BG.Size = UDim2.fromScale(1, 1)
    BG.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    BG.BorderSizePixel = 0
    
    -- 旋转圆环
    local Spinner = Instance.new("ImageLabel", BG)
    Spinner.Size = UDim2.fromOffset(120, 120)
    Spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    Spinner.Position = UDim2.fromScale(0.5, 0.45)
    Spinner.BackgroundTransparency = 1
    Spinner.Image = "rbxassetid://3642330698" -- 科技圆环素材
    Spinner.ImageColor3 = LoaderConfig.ThemeColor
    Spinner.ImageTransparency = 1
    
    -- 文字
    local Text = Instance.new("TextLabel", BG)
    Text.Size = UDim2.fromOffset(200, 50)
    Text.AnchorPoint = Vector2.new(0.5, 0.5)
    Text.Position = UDim2.fromScale(0.5, 0.6)
    Text.BackgroundTransparency = 1
    Text.TextColor3 = Color3.new(1,1,1)
    Text.Font = Enum.Font.GothamBold
    Text.TextSize = 18
    Text.Text = "INITIALIZING SYSTEM..."
    Text.TextTransparency = 1
    
    -- 动画序列
    PlaySound(Sounds.Boot, 1.5)
    
    TweenService:Create(Spinner, TweenInfo.new(0.8), {ImageTransparency = 0}):Play()
    TweenService:Create(Text, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
    
    -- 旋转循环
    local SpinTween = TweenService:Create(Spinner, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
    SpinTween:Play()
    
    task.wait(2.2) -- 等待时间
    
    -- 结束动画
    SpinTween:Cancel()
    TweenService:Create(BG, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Spinner, TweenInfo.new(0.4), {ImageTransparency = 1, Size = UDim2.fromOffset(0,0)}):Play()
    TweenService:Create(Text, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    
    task.wait(0.5)
    IntroGui:Destroy()
end

-- 播放动画
PlayIntro()

-- // 4. 载入核心 UI 库 //
-- 这里调用你的 GitHub 源码
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/logquickly/SciFi-UI-Library/refs/heads/main/source.lua"))()

-- 创建窗口 (请根据你的库API调整这里)
local Window = Library:CreateWindow({
    Name = "SCI-FI INJECTOR",
    Themeable = {Info = "Made by logquickly"}
})

-- // 5. 视觉控制系统 (彩虹边框 & 透明度) //
local MainFrame = nil

-- 尝试自动寻找 UI 的 MainFrame
-- ⚠️ 如果你的库生成的 Frame 名字不是 "Main"，请手动在这里修改或在库源码里命名
task.spawn(function()
    while not MainFrame do
        task.wait(0.1)
        for _, gui in pairs(CoreGui:GetChildren()) do
            -- 假设你的库生成的 ScreenGui 名字包含 "SciFi" 或者就是默认名
            if gui:FindFirstChild("Main") then 
                MainFrame = gui.Main
                break
            elseif gui:FindFirstChild("Frame") then -- 有些库主框架叫 Frame
                MainFrame = gui.Frame
                break
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not MainFrame then return end
    
    -- 彩虹边框逻辑
    if LoaderConfig.RainbowBorder then
        local hue = tick() * LoaderConfig.RainbowSpeed % 1
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        
        if MainFrame:FindFirstChild("UIStroke") then
            MainFrame.UIStroke.Color = rainbowColor
        else
            MainFrame.BorderColor3 = rainbowColor
        end
    else
        -- 恢复主题色 (如果关闭彩虹)
        if MainFrame:FindFirstChild("UIStroke") then
            MainFrame.UIStroke.Color = LoaderConfig.ThemeColor
        end
    end
    
    -- 透明度逻辑
    MainFrame.BackgroundTransparency = LoaderConfig.CurrentTransparency
end)

-- // 6. Config 系统 (带闪烁特效) //

if not isfolder(LoaderConfig.Folder) then makefolder(LoaderConfig.Folder) end

local function FlashEffect()
    -- 创建全屏闪烁
    local FlashGui = Instance.new("ScreenGui", CoreGui)
    local FlashFrame = Instance.new("Frame", FlashGui)
    FlashFrame.Size = UDim2.fromScale(1, 1)
    FlashFrame.BackgroundColor3 = LoaderConfig.ThemeColor -- 使用当前主题色
    FlashFrame.BackgroundTransparency = 0.5
    FlashFrame.BorderSizePixel = 0
    
    PlaySound(Sounds.ConfigLoad, 2)
    
    local t = TweenService:Create(FlashFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1})
    t:Play()
    t.Completed:Connect(function() FlashGui:Destroy() end)
end

local function SaveConfig(name)
    local path = LoaderConfig.Folder .. "/" .. name .. ".json"
    local data = {
        ThemeR = LoaderConfig.ThemeColor.R,
        ThemeG = LoaderConfig.ThemeColor.G,
        ThemeB = LoaderConfig.ThemeColor.B,
        Rainbow = LoaderConfig.RainbowBorder,
        Trans = LoaderConfig.CurrentTransparency,
        -- 这里可以添加更多需要在 Config 中保存的游戏功能开关状态
    }
    writefile(path, HttpService:JSONEncode(data))
end

local function LoadConfig(name)
    local path = LoaderConfig.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        
        if success and result then
            -- 应用设置
            if result.ThemeR then 
                LoaderConfig.ThemeColor = Color3.new(result.ThemeR, result.ThemeG, result.ThemeB) 
            end
            if result.Rainbow ~= nil then LoaderConfig.RainbowBorder = result.Rainbow end
            if result.Trans then LoaderConfig.CurrentTransparency = result.Trans end
            
            -- 刷新 UI 组件状态 (如果你的库支持 SetValue，在这里调用)
            -- 触发特效
            FlashEffect()
        end
    end
end

-- // 7. 菜单构建 (Tabs & Elements) //
-- 请根据你的库 API 修改下面的 CreateTab, CreateButton 等名称

local MainTab = Window:CreateTab("Main")
local SettingsTab = Window:CreateTab("Settings")

-- ==> Main Tab <==
MainTab:CreateSection("Visuals")

-- 圆形调色盘 (这里假设库自带 ColorPicker，我们用来改变 Config 的主题色)
MainTab:CreateColorPicker({
    Name = "Theme Color",
    Default = LoaderConfig.ThemeColor,
    Callback = function(Value)
        LoaderConfig.ThemeColor = Value
    end
})

MainTab:CreateToggle({
    Name = "Rainbow Border",
    CurrentValue = false,
    Callback = function(Value)
        LoaderConfig.RainbowBorder = Value
    end
})

MainTab:CreateSlider({
    Name = "Transparency",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.1,
    Callback = function(Value)
        LoaderConfig.CurrentTransparency = Value
    end
})

-- ==> Settings Tab <==
SettingsTab:CreateSection("Configuration")

local inputConfigName = "default"

SettingsTab:CreateInput({
    Name = "Config Name",
    PlaceholderText = "Type name...",
    Callback = function(Text)
        inputConfigName = Text
    end
})

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        SaveConfig(inputConfigName)
    end
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        LoadConfig(inputConfigName)
    end
})

SettingsTab:CreateToggle({
    Name = "Auto Load Default",
    CurrentValue = false,
    Callback = function(Value)
        -- 保存是否自动加载的设置到单独的文件
        writefile(LoaderConfig.Folder.."/autoload.txt", tostring(Value))
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
    Name = "Close / Unload",
    Callback = function()
        if MainFrame and MainFrame.Parent then MainFrame.Parent:Destroy() end
    end
})

-- // 8. 自动加载逻辑 //
if isfile(LoaderConfig.Folder.."/autoload.txt") then
    if readfile(LoaderConfig.Folder.."/autoload.txt") == "true" then
        task.delay(1, function()
            LoadConfig("default")
        end)
    end
end
