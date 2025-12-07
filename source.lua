--[[
    NEON SCI-FI UI LIBRARY v1.0
    Features:
      - 科幻风格 UI
      - 彩虹渐变边框(可切换真彩虹/单色渐变，单色可自定义颜色)
      - 圆形调色盘 (预设颜色 + Hex 颜色码输入)
      - 高级载入动画 (全屏序列 + 扫描线 + 清脆音效)
      - Config 系统：自定义名称 / 存读 / 自动载入 / 载入时闪屏+独特音效
      - Settings: Rejoin / Close All（重置所有功能）
    API:
      local Library = loadstring(game:HttpGet("URL"))()
      local Window  = Library:CreateWindow({ Name = "MY HUB" })
      local Tab     = Window:Tab("Main")
      Tab:Button(text, callback)
      Tab:Toggle(text, flag, default, callback)
      Tab:Slider(text, flag, min, max, default, callback)
      Tab:ColorPicker(text, flag, defaultColor3, callback)
]]

local Library          = {}
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local TeleportService  = game:GetService("TeleportService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local CoreGui          = game:GetService("CoreGui")

--==================== 全局状态 ====================--

Library.Settings = {
    RainbowBorder = true,  -- 真彩虹边框开关
    RainbowSpeed  = 1,     -- 边框旋转速度倍率
    SoundEnabled  = true,  -- 总音效开关
}

Library.Theme = {
    Background   = Color3.fromRGB(8, 10, 18),
    Panel        = Color3.fromRGB(14, 18, 30),
    Header       = Color3.fromRGB(18, 24, 42),
    Accent       = Color3.fromRGB(0, 255, 220), -- 主题色
    Text         = Color3.fromRGB(235, 240, 255),
    TextDim      = Color3.fromRGB(150, 160, 190),
    Transparency = 0.22,  -- 面板半透明
}

Library.BorderColor = Color3.fromRGB(0, 255, 220) -- 非彩虹模式下的边框主色

Library.Flags    = {} -- 当前各控件值
Library.Defaults = {} -- 每个Flag的默认值
Library.ThemeObjects = {} -- 主题刷新对象
Library.ConfigFolder = "NeonSciFiConfigs"

-- 全光谱彩虹序列
local RainbowSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0))
}

--==================== 音效 ====================--

local Sounds = {
    Hover       = 6895079960, -- 轻微电流
    Click       = 6042053626, -- 清脆点击
    ToggleOn    = 6042053626,
    ToggleOff   = 6042053610,
    Intro       = 6035688461, -- 独特载入音效
    Open        = 6895079853, -- 全息展开
    ConfigLoad  = 9118823107, -- 配置载入专用音
}

local function PlaySound(name, vol)
    if not Library.Settings.SoundEnabled then return end
    local id = Sounds[name]
    if not id then return end
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. id
        s.Volume  = vol or 0.7
        s.Parent  = SoundService
        s.PlayOnRemove = true
        s:Destroy()
    end)
end

--==================== 工具函数 ====================--

local function GetParent()
    local ok, parent = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if ok and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function RegisterTheme(obj, t)
    table.insert(Library.ThemeObjects, {Object = obj, Type = t})
end

function Library:UpdateTheme()
    for _, item in ipairs(Library.ThemeObjects) do
        local obj, t = item.Object, item.Type
        if obj then
            if t == "MainBg" then
                obj.BackgroundColor3 = Library.Theme.Panel
                obj.BackgroundTransparency = Library.Theme.Transparency
            elseif t == "HeaderBg" then
                obj.BackgroundColor3 = Library.Theme.Header
                obj.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.08, 0, 1)
            elseif t == "Text" then
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    obj.TextColor3 = Library.Theme.Text
                end
            elseif t == "TextDim" then
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    obj.TextColor3 = Library.Theme.TextDim
                end
            elseif t == "Accent" then
                if obj:IsA("UIStroke") then
                    obj.Color = Library.Theme.Accent
                elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    obj.TextColor3 = Library.Theme.Accent
                elseif obj:IsA("Frame") or obj:IsA("ImageLabel") then
                    obj.BackgroundColor3 = Library.Theme.Accent
                end
            end
        end
    end
end

-- 解析hex颜色 #RRGGBB -> Color3
local function HexToColor3(hex)
    hex = hex:gsub("#","")
    if #hex ~= 6 or not hex:match("^%x%x%x%x%x%x$") then return nil end
    local r = tonumber(hex:sub(1,2), 16)/255
    local g = tonumber(hex:sub(3,4), 16)/255
    local b = tonumber(hex:sub(5,6), 16)/255
    return Color3.new(r,g,b)
end

local function Color3ToHex(c)
    local r = math.floor(c.R*255+0.5)
    local g = math.floor(c.G*255+0.5)
    local b = math.floor(c.B*255+0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

--==================== CreateWindow ====================--

function Library:CreateWindow(cfg)
    local title = (cfg and cfg.Name) or "NEON CORE"

    -- 确保Config文件夹存在
    local hasFS = (writefile and readfile and (isfile or isfile == nil) and makefolder)
    if hasFS and makefolder then
        pcall(function()
            if not (isfolder and isfolder(Library.ConfigFolder)) then
                makefolder(Library.ConfigFolder)
            end
        end)
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "NeonSciFiUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder   = 9999
    ScreenGui.Parent         = GetParent()

    -- 全局闪屏层（Config载入用）
    local FlashFrame = Instance.new("Frame")
    FlashFrame.Size  = UDim2.new(1,0,1,0)
    FlashFrame.BackgroundColor3 = Library.Theme.Accent
    FlashFrame.BackgroundTransparency = 1
    FlashFrame.BorderSizePixel = 0
    FlashFrame.ZIndex = 50
    FlashFrame.Parent = ScreenGui

    local function FlashTheme()
        FlashFrame.BackgroundColor3 = Library.Theme.Accent
        FlashFrame.BackgroundTransparency = 1
        FlashFrame.Visible = true
        local t1 = TweenService:Create(FlashFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4})
        t1:Play()
        t1.Completed:Wait()
        TweenService:Create(FlashFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
    end

    --==================== 高级载入动画 ====================--

    PlaySound("Intro", 1.3)

    local Intro = Instance.new("Frame")
    Intro.Size  = UDim2.new(1,0,1,0)
    Intro.BackgroundColor3 = Color3.new(0,0,0)
    Intro.BackgroundTransparency = 0
    Intro.BorderSizePixel = 0
    Intro.ZIndex = 40
    Intro.Parent = ScreenGui

    local IntroGrad = Instance.new("UIGradient")
    IntroGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 5, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    IntroGrad.Rotation = 90
    IntroGrad.Parent   = Intro

    local IntroTitle = Instance.new("TextLabel")
    IntroTitle.Size    = UDim2.new(0, 600, 0, 60)
    IntroTitle.Position= UDim2.new(0.5,-300,0.45,-30)
    IntroTitle.BackgroundTransparency = 1
    IntroTitle.Font    = Enum.Font.RobotoMono
    IntroTitle.Text    = "INITIALIZING NEON CORE"
    IntroTitle.TextSize= 30
    IntroTitle.TextColor3 = Color3.fromRGB(0,255,220)
    IntroTitle.TextXAlignment = Enum.TextXAlignment.Center
    IntroTitle.ZIndex = 41
    IntroTitle.Parent = Intro

    local IntroSub = Instance.new("TextLabel")
    IntroSub.Size    = UDim2.new(0, 600, 0, 30)
    IntroSub.Position= UDim2.new(0.5,-300,0.5,5)
    IntroSub.BackgroundTransparency = 1
    IntroSub.Font    = Enum.Font.RobotoMono
    IntroSub.Text    = "SCANNING CLIENT ENVIRONMENT..."
    IntroSub.TextSize= 18
    IntroSub.TextColor3 = Color3.fromRGB(150,180,255)
    IntroSub.TextXAlignment = Enum.TextXAlignment.Center
    IntroSub.ZIndex = 41
    IntroSub.Parent = Intro

    local ScanLine = Instance.new("Frame")
    ScanLine.Size   = UDim2.new(1,0,0,2)
    ScanLine.Position = UDim2.new(0,0,0,0)
    ScanLine.BackgroundColor3 = Color3.fromRGB(0,255,220)
    ScanLine.BackgroundTransparency = 0.5
    ScanLine.BorderSizePixel = 0
    ScanLine.ZIndex = 42
    ScanLine.Parent = Intro

    local ScanGrad = Instance.new("UIGradient")
    ScanGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    }
    ScanGrad.Parent = ScanLine

    --==================== 外层彩虹边框 ====================--

    local BorderFrame = Instance.new("Frame")
    BorderFrame.AnchorPoint = Vector2.new(0.5,0.5)
    BorderFrame.Size   = UDim2.new(0, 520, 0, 340)
    BorderFrame.Position = UDim2.new(0.5,0,0.5,0)
    BorderFrame.BackgroundTransparency = 1
    BorderFrame.BorderSizePixel = 0
    BorderFrame.ZIndex = 10
    BorderFrame.Parent = ScreenGui
    BorderFrame.Visible = false

    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Thickness    = 3
    BorderStroke.Transparency = 0.15
    BorderStroke.Parent       = BorderFrame

    local BorderCorner = Instance.new("UICorner")
    BorderCorner.CornerRadius = UDim.new(0, 14)
    BorderCorner.Parent       = BorderFrame

    local BorderGradient = Instance.new("UIGradient")
    BorderGradient.Rotation = 0
    BorderGradient.Color    = RainbowSequence
    BorderGradient.Parent   = BorderStroke

    --==================== 主面板 ====================--

    local MainFrame = Instance.new("Frame")
    MainFrame.Name  = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
    MainFrame.Size  = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5,0,0.5,0)
    MainFrame.BackgroundColor3 = Library.Theme.Panel
    MainFrame.BackgroundTransparency = Library.Theme.Transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 11
    MainFrame.Parent = ScreenGui
    MainFrame.Visible = false
    RegisterTheme(MainFrame, "MainBg")

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent       = MainFrame

    -- 顶部 Header
    local Header = Instance.new("Frame")
    Header.Size  = UDim2.new(1,0,0,46)
    Header.BackgroundColor3 = Library.Theme.Header
    Header.BackgroundTransparency = Library.Theme.Transparency - 0.08
    Header.BorderSizePixel = 0
    Header.ZIndex = 12
    Header.Parent = MainFrame
    RegisterTheme(Header, "HeaderBg")

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size  = UDim2.new(1,0,0,2)
    HeaderLine.Position = UDim2.new(0,0,1,-2)
    HeaderLine.BackgroundColor3 = Library.Theme.Accent
    HeaderLine.BackgroundTransparency = 0.4
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 12
    HeaderLine.Parent = Header
    RegisterTheme(HeaderLine, "Accent")

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size  = UDim2.new(0.6,0,1,0)
    TitleLabel.Position = UDim2.new(0,16,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font   = Enum.Font.RobotoMono
    TitleLabel.Text   = string.upper(title)
    TitleLabel.TextSize = 20
    TitleLabel.TextColor3 = Library.Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 13
    TitleLabel.Parent = Header
    RegisterTheme(TitleLabel, "Text")

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size  = UDim2.new(0.4,-16,1,0)
    StatusLabel.Position = UDim2.new(0.6,0,0,0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font   = Enum.Font.RobotoMono
    StatusLabel.Text   = "[ ONLINE ]"
    StatusLabel.TextSize = 16
    StatusLabel.TextColor3 = Library.Theme.TextDim
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatusLabel.ZIndex = 13
    StatusLabel.Parent = Header
    RegisterTheme(StatusLabel, "TextDim")

    -- 拖动
    do
        local dragging, dragStart, startPos
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = input.Position
                startPos  = MainFrame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                MainFrame.Position  = newPos
                BorderFrame.Position= newPos
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- 顶部 Tab 栏
    local TabBar = Instance.new("Frame")
    TabBar.Size  = UDim2.new(1,0,0,32)
    TabBar.Position = UDim2.new(0,0,0,46)
    TabBar.BackgroundColor3 = Color3.fromRGB(8,12,24)
    TabBar.BackgroundTransparency = 0.4
    TabBar.BorderSizePixel = 0
    TabBar.ZIndex = 12
    TabBar.Parent = MainFrame

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size  = UDim2.new(1,-12,1,0)
    TabScroll.Position = UDim2.new(0,6,0,0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 0
    TabScroll.ZIndex = 12
    TabScroll.Parent = TabBar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.Padding = UDim.new(0,6)
    TabLayout.Parent   = TabScroll

    -- 内容区域
    local PageContainer = Instance.new("Frame")
    PageContainer.Size  = UDim2.new(1,0,1,-78)
    PageContainer.Position = UDim2.new(0,0,0,78)
    PageContainer.BackgroundTransparency = 1
    PageContainer.ZIndex = 11
    PageContainer.Parent = MainFrame

    -- 手机悬浮按钮
    local MobileBtn
    if UserInputService.TouchEnabled then
        MobileBtn = Instance.new("ImageButton")
        MobileBtn.Size = UDim2.new(0,46,0,46)
        MobileBtn.Position = UDim2.new(0,24,0.35,0)
        MobileBtn.BackgroundColor3 = Library.Theme.Panel
        MobileBtn.BackgroundTransparency = 0.3
        MobileBtn.Image = "rbxassetid://10734898355"
        MobileBtn.ZIndex = 20
        MobileBtn.Parent = ScreenGui
        local mbC = Instance.new("UICorner"); mbC.CornerRadius = UDim.new(1,0); mbC.Parent = MobileBtn
        local mbS = Instance.new("UIStroke"); mbS.Color = Library.Theme.Accent; mbS.Thickness = 2; mbS.Parent = MobileBtn
        RegisterTheme(mbS, "Accent")
    end

    -- 彩虹/单色渐变边框动画
    task.spawn(function()
        local rot = 0
        while ScreenGui.Parent do
            local dt = RunService.Heartbeat:Wait()
            if Library.Settings.RainbowBorder then
                BorderGradient.Color = RainbowSequence
            else
                local c = Library.BorderColor
                local comp = Color3.new(1-c.R,1-c.G,1-c.B)
                BorderGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(0.5, comp),
                    ColorSequenceKeypoint.new(1, c)
                }
            end
            rot = rot + 60 * Library.Settings.RainbowSpeed * dt
            BorderGradient.Rotation = rot % 360
        end
    end)

    -- UI 显隐
    local visible = true
    local function ToggleUI()
        visible = not visible
        if visible then
            PlaySound("Open")
            MainFrame.Visible  = true
            BorderFrame.Visible= true
            MainFrame.Size     = UDim2.new(0,0,0,40)
            TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0,500,0,320)}):Play()
        else
            PlaySound("Open",0.8)
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Size = UDim2.new(0,0,0,40)})
            t:Play()
            t.Completed:Wait()
            MainFrame.Visible   = false
            BorderFrame.Visible = false
        end
    end

    if MobileBtn then
        MobileBtn.MouseButton1Click:Connect(ToggleUI)
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            ToggleUI()
        end
    end)

    -- 启动动画：扫描线 + 渐隐 + UI出现
    task.spawn(function()
        local scanTween = TweenService:Create(ScanLine, TweenInfo.new(0.8, Enum.EasingStyle.Linear),
            {Position = UDim2.new(0,0,1,0)})
        scanTween:Play()
        task.wait(0.4)
        IntroSub.Text = "LINKING VISUAL INTERFACE..."
        task.wait(0.4)
        IntroSub.Text = "SYSTEM ONLINE"

        local fade = TweenService:Create(Intro, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1})
        TweenService:Create(IntroTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(IntroSub,   TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        fade:Play()
        fade.Completed:Wait()
        Intro:Destroy()

        BorderFrame.Visible = true
        MainFrame.Visible   = true
        MainFrame.Size      = UDim2.new(0,0,0,40)
        PlaySound("Open",1)
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0,500,0,320)}):Play()
    end)

    --==================== Tab & 元素 API ====================--

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        -- 顶部Tab按钮
        local TabButton = Instance.new("TextButton")
        TabButton.Text  = name
        TabButton.AutoButtonColor = false
        TabButton.Size  = UDim2.new(0,90,1,0)
        TabButton.BackgroundTransparency = 1
        TabButton.Font  = Enum.Font.GothamMedium
        TabButton.TextSize = 13
        TabButton.TextColor3 = Library.Theme.TextDim
        TabButton.ZIndex = 12
        TabButton.Parent = TabScroll
        RegisterTheme(TabButton, "TextDim")

        local TabSelect = Instance.new("Frame")
        TabSelect.Size  = UDim2.new(1,0,0,2)
        TabSelect.Position = UDim2.new(0,0,1,-2)
        TabSelect.BackgroundColor3 = Library.Theme.Accent
        TabSelect.BackgroundTransparency = 1
        TabSelect.BorderSizePixel = 0
        TabSelect.ZIndex = 13
        TabSelect.Parent = TabButton
        RegisterTheme(TabSelect, "Accent")

        -- 对应页面
        local Page = Instance.new("ScrollingFrame")
        Page.Name  = name .. "_Page"
        Page.Size  = UDim2.new(1,0,1,0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0,0,0,0)
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(40,100,255)
        Page.ZIndex = 11
        Page.Parent = PageContainer
        Page.Visible = false

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0,8)
        PageLayout.Parent  = Page

        local PagePad = Instance.new("UIPadding")
        PagePad.PaddingTop   = UDim.new(0,10)
        PagePad.PaddingLeft  = UDim.new(0,12)
        PagePad.PaddingRight = UDim.new(0,12)
        PagePad.Parent       = Page

        -- Tab 切换
        TabButton.MouseButton1Click:Connect(function()
            PlaySound("Click")
            for _, v in ipairs(PageContainer:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            for _, v in ipairs(TabScroll:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.25), {TextColor3 = Library.Theme.TextDim}):Play()
                    local sel = v:FindFirstChildOfClass("Frame")
                    if sel then
                        TweenService:Create(sel, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                    end
                end
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.25), {TextColor3 = Library.Theme.Accent}):Play()
            TweenService:Create(TabSelect, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        end)

        -- 第一个Tab默认激活
        if #PageContainer:GetChildren() == 1 then
            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Accent
            TabSelect.BackgroundTransparency = 0
        end

        local Elements = {}

        -- Button
        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size  = UDim2.new(1,0,0,38)
            Btn.BackgroundColor3 = Library.Theme.Panel
            Btn.BackgroundTransparency = Library.Theme.Transparency
            Btn.AutoButtonColor = false
            Btn.Text  = text
            Btn.Font  = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.TextColor3 = Library.Theme.Text
            Btn.ZIndex = 11
            Btn.Parent = Page
            RegisterTheme(Btn, "MainBg")

            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Btn
            local s = Instance.new("UIStroke"); s.Color=Library.Theme.Accent; s.Transparency=0.8; s.Parent=Btn
            RegisterTheme(s, "Accent")

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click",1.2)
                TweenService:Create(s, TweenInfo.new(0.1), {Transparency = 0}):Play()
                task.wait(0.1)
                TweenService:Create(s, TweenInfo.new(0.4), {Transparency = 0.8}):Play()
                if callback then pcall(callback) end
            end)
        end

        -- Toggle
        function Elements:Toggle(text, flag, default, callback)
            local val = default or false
            Library.Flags[flag]    = val
            Library.Defaults[flag] = default or false

            local Btn = Instance.new("TextButton")
            Btn.Size  = UDim2.new(1,0,0,38)
            Btn.BackgroundColor3 = Library.Theme.Panel
            Btn.BackgroundTransparency = Library.Theme.Transparency
            Btn.AutoButtonColor = false
            Btn.Text  = ""
            Btn.ZIndex = 11
            Btn.Parent = Page
            RegisterTheme(Btn, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Btn

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.7,0,1,0)
            Label.Position = UDim2.new(0,10,0,0)
            Label.BackgroundTransparency = 1
            Label.Font  = Enum.Font.Gotham
            Label.Text  = text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.ZIndex = 12
            Label.Parent = Btn
            RegisterTheme(Label, "Text")

            local Box = Instance.new("Frame")
            Box.Size  = UDim2.new(0,38,0,18)
            Box.Position = UDim2.new(1,-52,0.5,-9)
            Box.BackgroundColor3 = Color3.fromRGB(24,32,48)
            Box.ZIndex = 12
            Box.Parent = Btn
            local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,9); bc.Parent=Box
            local bs = Instance.new("UIStroke"); bs.Color=Color3.fromRGB(60,80,120); bs.Thickness=1.2; bs.Parent=Box

            local Dot = Instance.new("Frame")
            Dot.Size  = UDim2.new(0,16,0,16)
            Dot.Position = UDim2.new(0,2,0.5,-8)
            Dot.BackgroundColor3 = Color3.fromRGB(110,120,140)
            Dot.ZIndex = 13
            Dot.Parent = Box
            local dc = Instance.new("UICorner"); dc.CornerRadius=UDim.new(1,0); dc.Parent=Dot

            local function Apply(v)
                val = v
                Library.Flags[flag] = v
                if v then
                    PlaySound("ToggleOn")
                    TweenService:Create(Dot, TweenInfo.new(0.2), {
                        Position = UDim2.new(1,-18,0.5,-8),
                        BackgroundColor3 = Library.Theme.Accent
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(24,48,72)
                    }):Play()
                else
                    PlaySound("ToggleOff")
                    TweenService:Create(Dot, TweenInfo.new(0.2), {
                        Position = UDim2.new(0,2,0.5,-8),
                        BackgroundColor3 = Color3.fromRGB(110,120,140)
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(24,32,48)
                    }):Play()
                end
                if callback then pcall(callback, v) end
            end

            if val then
                Apply(true)
            end

            Btn.MouseButton1Click:Connect(function()
                Apply(not val)
            end)

            Library.Flags[flag.."_Update"] = Apply
        end

        -- Slider
        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min
            Library.Flags[flag]    = value
            Library.Defaults[flag] = default or min

            local Frame = Instance.new("Frame")
            Frame.Size  = UDim2.new(1,0,0,56)
            Frame.BackgroundColor3 = Library.Theme.Panel
            Frame.BackgroundTransparency = Library.Theme.Transparency
            Frame.ZIndex = 11
            Frame.Parent = Page
            RegisterTheme(Frame, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Frame

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.6,0,0,22)
            Label.Position = UDim2.new(0,10,0,6)
            Label.BackgroundTransparency = 1
            Label.Font  = Enum.Font.Gotham
            Label.Text  = text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.ZIndex = 12
            Label.Parent = Frame
            RegisterTheme(Label, "Text")

            local Val = Instance.new("TextLabel")
            Val.Size  = UDim2.new(0.4,-20,0,22)
            Val.Position = UDim2.new(0.6,0,0,6)
            Val.BackgroundTransparency = 1
            Val.Font  = Enum.Font.Code
            Val.Text  = tostring(value)
            Val.TextSize = 14
            Val.TextXAlignment = Enum.TextXAlignment.Right
            Val.TextColor3 = Library.Theme.Accent
            Val.ZIndex = 12
            Val.Parent = Frame
            RegisterTheme(Val, "Accent")

            local Bar = Instance.new("TextButton")
            Bar.Text  = ""
            Bar.AutoButtonColor = false
            Bar.Size  = UDim2.new(1,-22,0,4)
            Bar.Position = UDim2.new(0,11,0,34)
            Bar.BackgroundColor3 = Color3.fromRGB(32,40,60)
            Bar.ZIndex = 12
            Bar.Parent = Frame
            local bc2 = Instance.new("UICorner"); bc2.CornerRadius=UDim.new(1,0); bc2.Parent=Bar

            local Fill = Instance.new("Frame")
            Fill.Size  = UDim2.new((value-min)/(max-min),0,1,0)
            Fill.BackgroundColor3 = Library.Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 13
            Fill.Parent = Bar
            RegisterTheme(Fill, "Accent")
            local fc2 = Instance.new("UICorner"); fc2.CornerRadius=UDim.new(1,0); fc2.Parent=Fill

            local dragging = false
            local function SetFromPos(x)
                local rel = math.clamp((x - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                local v   = min + (max-min)*rel
                v = math.floor(v*10+0.5)/10
                value = v
                Library.Flags[flag] = v
                Fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
                Val.Text  = tostring(v)
                if callback then pcall(callback, v) end
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    SetFromPos(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    SetFromPos(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            Library.Flags[flag.."_Update"] = function(v)
                value = v
                Library.Flags[flag] = v
                Fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
                Val.Text  = tostring(v)
                if callback then pcall(callback, v) end
            end
        end

        -- 圆形调色盘 ColorPicker
        function Elements:ColorPicker(text, flag, default, callback)
            local col = default or Color3.fromRGB(255,255,255)
            Library.Flags[flag]    = col
            Library.Defaults[flag] = default or col
            local open = false

            local Frame = Instance.new("Frame")
            Frame.Size  = UDim2.new(1,0,0,44)
            Frame.BackgroundColor3 = Library.Theme.Panel
            Frame.BackgroundTransparency = Library.Theme.Transparency
            Frame.ClipsDescendants = true
            Frame.ZIndex = 11
            Frame.Parent = Page
            RegisterTheme(Frame, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Frame

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.6,0,1,0)
            Label.Position = UDim2.new(0,10,0,0)
            Label.BackgroundTransparency = 1
            Label.Font  = Enum.Font.Gotham
            Label.Text  = text
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.ZIndex = 12
            Label.Parent = Frame
            RegisterTheme(Label, "Text")

            local Preview = Instance.new("TextButton")
            Preview.Size  = UDim2.new(0,40,0,20)
            Preview.Position = UDim2.new(1,-52,0,12)
            Preview.BackgroundColor3 = col
            Preview.Text  = ""
            Preview.AutoButtonColor = false
            Preview.ZIndex = 12
            Preview.Parent = Frame
            local pc = Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,6); pc.Parent=Preview

            local Container = Instance.new("Frame")
            Container.Size  = UDim2.new(1,-20,0,160)
            Container.Position = UDim2.new(0,10,0,46)
            Container.BackgroundTransparency = 1
            Container.ZIndex = 11
            Container.Parent = Frame

            -- 色轮
            local Wheel = Instance.new("ImageButton")
            Wheel.Size  = UDim2.new(0,100,0,100)
            Wheel.Position = UDim2.new(0,0,0,0)
            Wheel.BackgroundTransparency = 1
            Wheel.Image = "rbxassetid://6020299385" -- HSV 色轮
            Wheel.ZIndex = 12
            Wheel.Parent = Container

            local Cursor = Instance.new("ImageLabel")
            Cursor.Size  = UDim2.new(0,10,0,10)
            Cursor.AnchorPoint = Vector2.new(0.5,0.5)
            Cursor.BackgroundTransparency = 1
            Cursor.Image = "rbxassetid://16449174151"
            Cursor.ZIndex = 13
            Cursor.Parent = Wheel

            -- 预设颜色
            local Presets = Instance.new("Frame")
            Presets.Size  = UDim2.new(0,100,0,72)
            Presets.Position = UDim2.new(1,-100,0,0)
            Presets.BackgroundTransparency = 1
            Presets.ZIndex = 12
            Presets.Parent = Container

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize    = UDim2.new(0,28,0,28)
            Grid.CellPadding = UDim2.new(0,4,0,4)
            Grid.Parent      = Presets

            local PresetColors = {
                Color3.fromRGB(255,0,0),
                Color3.fromRGB(0,255,0),
                Color3.fromRGB(0,0,255),
                Color3.fromRGB(255,255,0),
                Color3.fromRGB(0,255,255),
                Color3.fromRGB(255,0,255),
                Color3.fromRGB(255,128,0),
                Color3.fromRGB(128,0,255),
                Color3.fromRGB(255,255,255),
            }

            local function ApplyColor(c3)
                col = c3
                Library.Flags[flag] = c3
                Preview.BackgroundColor3 = c3
                if callback then pcall(callback, c3) end
            end

            for _, c3 in ipairs(PresetColors) do
                local sw = Instance.new("TextButton")
                sw.Text  = ""
                sw.AutoButtonColor = false
                sw.BackgroundColor3 = c3
                sw.ZIndex = 13
                sw.Parent = Presets
                local sc = Instance.new("UICorner"); sc.CornerRadius=UDim.new(1,0); sc.Parent=sw
                sw.MouseButton1Click:Connect(function()
                    PlaySound("Click",1.1)
                    ApplyColor(c3)
                end)
            end

            -- Hex 输入
            local HexBox = Instance.new("TextBox")
            HexBox.Size  = UDim2.new(0,100,0,22)
            HexBox.Position = UDim2.new(0,0,0,110)
            HexBox.BackgroundColor3 = Color3.fromRGB(18,24,40)
            HexBox.Text  = Color3ToHex(col)
            HexBox.PlaceholderText = "#RRGGBB"
            HexBox.Font  = Enum.Font.Code
            HexBox.TextSize = 14
            HexBox.TextColor3 = Library.Theme.Text
            HexBox.ClearTextOnFocus = false
            HexBox.ZIndex = 12
            HexBox.Parent = Container
            RegisterTheme(HexBox, "Text")
            local hc = Instance.new("UICorner"); hc.CornerRadius=UDim.new(0,6); hc.Parent=HexBox
            local hs = Instance.new("UIStroke"); hs.Color=Library.Theme.Accent; hs.Transparency=0.7; hs.Parent=HexBox
            RegisterTheme(hs, "Accent")

            HexBox.FocusLost:Connect(function(enter)
                if not enter then return end
                local c3 = HexToColor3(HexBox.Text or "")
                if c3 then
                    PlaySound("Click",1.1)
                    ApplyColor(c3)
                    HexBox.Text = Color3ToHex(c3)
                else
                    HexBox.Text = Color3ToHex(col)
                end
            end)

            -- 色轮拖动
            local dragging = false
            local function UpdateFromInput(input)
                local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize/2)
                local vec    = Vector2.new(input.Position.X - center.X, input.Position.Y - center.Y)
                local dist   = math.min(vec.Magnitude, Wheel.AbsoluteSize.X/2)
                local angle  = math.atan2(vec.Y, vec.X)
                Cursor.Position = UDim2.new(
                    0.5 + math.cos(angle)*dist/Wheel.AbsoluteSize.X,
                    0,
                    0.5 + math.sin(angle)*dist/Wheel.AbsoluteSize.Y,
                    0
                )
                local sat = dist / (Wheel.AbsoluteSize.X/2)
                local hue = (math.deg(angle)+180)/360
                local c3  = Color3.fromHSV(hue, sat, 1)
                ApplyColor(c3)
                HexBox.Text = Color3ToHex(c3)
            end

            Wheel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromInput(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                open = not open
                PlaySound("Click",1)
                TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Size = open and UDim2.new(1,0,0,210) or UDim2.new(1,0,0,44)}):Play()
            end)

            Library.Flags[flag.."_Update"] = ApplyColor
        end

        return Elements
    end

    --================ Config 相关函数（本窗口作用域） ================--

    local function SaveConfig(name)
        if not hasFS then
            warn("SaveConfig: 当前环境不支持文件操作(writefile/readfile)")
            return
        end
        if not name or name == "" then
            warn("SaveConfig: 配置名称为空")
            return
        end
        local data = {
            Flags    = {},
            Theme    = {
                Accent       = {Library.Theme.Accent.R, Library.Theme.Accent.G, Library.Theme.Accent.B},
                Transparency = Library.Theme.Transparency,
            },
            Settings = {
                RainbowBorder = Library.Settings.RainbowBorder,
                RainbowSpeed  = Library.Settings.RainbowSpeed,
                SoundEnabled  = Library.Settings.SoundEnabled,
                BorderColor   = {Library.BorderColor.R, Library.BorderColor.G, Library.BorderColor.B},
            }
        }
        for k,v in pairs(Library.Flags) do
            if not k:find("_Update$") then
                data.Flags[k] = v
            end
        end
        local json = HttpService:JSONEncode(data)
        local path = string.format("%s/%s.json", Library.ConfigFolder, name)
        writefile(path, json)
    end

    local function LoadConfig(name)
        if not hasFS then
            warn("LoadConfig: 当前环境不支持文件操作")
            return
        end
        if not name or name == "" then
            warn("LoadConfig: 配置名称为空")
            return
        end
        local path = string.format("%s/%s.json", Library.ConfigFolder, name)
        if (isfile and not isfile(path)) then
            warn("LoadConfig: 文件不存在 - ", path)
            return
        end
        local ok, content = pcall(readfile, path)
        if not ok then
            warn("LoadConfig: 读取失败 - ", content)
            return
        end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
        if not ok2 then
            warn("LoadConfig: JSON解析失败 - ", data)
            return
        end

        -- Flags
        if data.Flags then
            for k,v in pairs(data.Flags) do
                local upd = Library.Flags[k.."_Update"]
                if upd then
                    upd(v)
                else
                    Library.Flags[k] = v
                end
            end
        end

        -- Theme
        if data.Theme and data.Theme.Accent then
            local a = data.Theme.Accent
            Library.Theme.Accent = Color3.new(a[1],a[2],a[3])
            if data.Theme.Transparency then
                Library.Theme.Transparency = data.Theme.Transparency
            end
            Library:UpdateTheme()
        end

        -- Settings
        if data.Settings then
            if data.Settings.RainbowBorder ~= nil then
                Library.Settings.RainbowBorder = data.Settings.RainbowBorder
            end
            if data.Settings.RainbowSpeed then
                Library.Settings.RainbowSpeed = data.Settings.RainbowSpeed
            end
            if data.Settings.SoundEnabled ~= nil then
                Library.Settings.SoundEnabled = data.Settings.SoundEnabled
            end
            if data.Settings.BorderColor then
                local bc = data.Settings.BorderColor
                Library.BorderColor = Color3.new(bc[1],bc[2],bc[3])
            end
        end

        -- 载入时闪屏 + 独特声音
        FlashTheme()
        PlaySound("ConfigLoad", 1.2)
    end

    local function SaveAutoConfig(name, enabled)
        if not hasFS then return end
        local path = string.format("%s/_auto.json", Library.ConfigFolder)
        local data = {Name = name or "", Enabled = enabled and true or false}
        local json = HttpService:JSONEncode(data)
        writefile(path, json)
    end

    local function TryAutoLoad()
        if not hasFS then return end
        local path = string.format("%s/_auto.json", Library.ConfigFolder)
        if isfile and not isfile(path) then return end
        local ok, content = pcall(readfile, path)
        if not ok then return end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, content)
        if not ok2 then return end
        if data.Enabled and data.Name and data.Name ~= "" then
            LoadConfig(data.Name)
        end
    end

    --================ 内置 Settings 标签页 ====================--

    local SettingsTab = WindowFuncs:Tab("Settings")

    -- Config 名称输入
    local currentConfigName = "default"

    do
        -- 简单的文本输入 + 标签
        local Frame = Instance.new("Frame")
        Frame.Size  = UDim2.new(1,0,0,40)
        Frame.BackgroundColor3 = Library.Theme.Panel
        Frame.BackgroundTransparency = Library.Theme.Transparency
        Frame.ZIndex = 11
        Frame.Parent = PageContainer:FindFirstChild("Settings_Page")
        RegisterTheme(Frame, "MainBg")
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Frame

        local Label = Instance.new("TextLabel")
        Label.Size  = UDim2.new(0.3,0,1,0)
        Label.Position = UDim2.new(0,10,0,0)
        Label.BackgroundTransparency = 1
        Label.Font  = Enum.Font.Gotham
        Label.Text  = "Config Name"
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextColor3 = Library.Theme.Text
        Label.ZIndex = 12
        Label.Parent = Frame
        RegisterTheme(Label, "Text")

        local Box = Instance.new("TextBox")
        Box.Size  = UDim2.new(0.6,-20,0,24)
        Box.Position = UDim2.new(0.35,0,0.5,-12)
        Box.BackgroundColor3 = Color3.fromRGB(18,24,40)
        Box.Text  = currentConfigName
        Box.Font  = Enum.Font.Code
        Box.TextSize = 14
        Box.TextColor3 = Library.Theme.Text
        Box.ClearTextOnFocus = false
        Box.ZIndex = 12
        Box.Parent = Frame
        RegisterTheme(Box, "Text")
        local bc2 = Instance.new("UICorner"); bc2.CornerRadius=UDim.new(0,6); bc2.Parent=Box
        local bs2 = Instance.new("UIStroke"); bs2.Color=Library.Theme.Accent; bs2.Transparency=0.7; bs2.Parent=Box
        RegisterTheme(bs2, "Accent")

        Box.FocusLost:Connect(function()
            local t = Box.Text
            if t and t ~= "" then
                currentConfigName = t
            else
                Box.Text = currentConfigName
            end
        end)

        -- 将 Frame 放到 Settings_Page 顶部
        Frame.Parent = PageContainer:FindFirstChild("Settings_Page")
        Frame.LayoutOrder = -100
    end

    SettingsTab:ColorPicker("Accent Color", "ThemeAccentFlag", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        Library:UpdateTheme()
    end)

    SettingsTab:ColorPicker("Border Color (Non-Rainbow)", "BorderColorFlag", Library.BorderColor, function(c)
        Library.BorderColor = c
    end)

    SettingsTab:Toggle("Rainbow Border", "RB_Flag", true, function(v)
        Library.Settings.RainbowBorder = v
    end)

    SettingsTab:Slider("Border Speed", "RB_Speed", 0.2, 3, Library.Settings.RainbowSpeed, function(v)
        Library.Settings.RainbowSpeed = v
    end)

    SettingsTab:Slider("Panel Transparency", "Trans_Flag", 0, 0.6, Library.Theme.Transparency, function(v)
        Library.Theme.Transparency = v
        Library:UpdateTheme()
    end)

    SettingsTab:Toggle("UI Sounds", "Sound_Flag", true, function(v)
        Library.Settings.SoundEnabled = v
    end)

    SettingsTab:Button("Save Config", function()
        SaveConfig(currentConfigName)
        PlaySound("Click",1.2)
    end)

    SettingsTab:Button("Load Config", function()
        LoadConfig(currentConfigName)
    end)

    -- Auto Load Toggle
    SettingsTab:Toggle("Auto-Load This Config", "AutoConfig_Flag", false, function(v)
        if hasFS then
            SaveAutoConfig(currentConfigName, v)
        end
    end)

    -- Rejoin
    SettingsTab:Button("Rejoin", function()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        if not ok then warn("Rejoin failed:", err) end
    end)

    -- Close All：重置所有功能到默认
    SettingsTab:Button("Close All (Reset Features)", function()
        for flag, def in pairs(Library.Defaults) do
            local upd = Library.Flags[flag.."_Update"]
            if upd then
                upd(def)
            else
                Library.Flags[flag] = def
            end
        end
    end)

    -- 启动时尝试自动载入配置
    task.spawn(TryAutoLoad)

    return WindowFuncs
end

return Library
