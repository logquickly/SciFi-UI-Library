--[[
    NEON CORE UI LIBRARY v7.0
    Style: 全息霓虹舱 / 顶部 Tab / RGB 流光边框 / 圆形调色盘 / 高级启动动画
    API:
        local Library = loadstring(game:HttpGet("URL"))()
        local Window  = Library:CreateWindow({ Name = "MY HUB" })
        local Tab     = Window:Tab("Main")
        Tab:Button(text, callback)
        Tab:Toggle(text, flag, default, callback)
        Tab:Slider(text, flag, min, max, default, callback)
        Tab:ColorPicker(text, flag, defaultColor3, callback)
]]

local Library         = {}
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")
local SoundService    = game:GetService("SoundService")
local Players         = game:GetService("Players")
local LocalPlayer     = Players.LocalPlayer
local CoreGui         = game:GetService("CoreGui")

-- ================== 全局状态 ==================

Library.Settings = {
    RainbowBorder = true,
    RainbowSpeed  = 0.8,   -- 彩虹旋转速度倍率
    SoundEnabled  = true,
}

Library.Theme = {
    Background   = Color3.fromRGB(8, 12, 24),
    Panel        = Color3.fromRGB(16, 20, 36),
    Header       = Color3.fromRGB(18, 26, 48),
    Accent       = Color3.fromRGB(0, 255, 215),
    Text         = Color3.fromRGB(240, 240, 255),
    TextDim      = Color3.fromRGB(150, 160, 190),
    Transparency = 0.18,   -- 主面板半透明
}

Library.Flags        = {}
Library.ThemeObjects = {}

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

-- ================== 音效 ==================

local Sounds = {
    Hover     = 6895079960,  -- 轻微电流
    Click     = 6042053626,  -- 清脆点击
    ToggleOn  = 6042053626,  -- 开启
    ToggleOff = 6042053610,  -- 关闭
    Intro     = 6035688461,  -- 独特系统启动
    Open      = 6895079853,  -- 全息展开
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

-- ================== 工具函数 ==================

local function GetParent()
    local ok, parent = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if ok and parent then
        return parent
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function RegisterTheme(obj, t)
    table.insert(Library.ThemeObjects, {Object = obj, Type = t})
end

function Library:UpdateTheme()
    for _, item in ipairs(Library.ThemeObjects) do
        local obj  = item.Object
        local t    = item.Type
        if obj then
            if t == "MainBg" then
                obj.BackgroundColor3   = Library.Theme.Panel
                obj.BackgroundTransparency = Library.Theme.Transparency
            elseif t == "HeaderBg" then
                obj.BackgroundColor3   = Library.Theme.Header
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

-- ================== 核心：创建窗口 ==================

function Library:CreateWindow(cfg)
    local title = (cfg and cfg.Name) or "NEON CORE"

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name          = "NeonCoreUI"
    ScreenGui.IgnoreGuiInset= true
    ScreenGui.DisplayOrder  = 9999
    ScreenGui.Parent        = GetParent()

    -- 独特载入音效
    PlaySound("Intro", 1.3)

    -- ========= 高级载入动画层（全屏） =========
    local Intro = Instance.new("Frame")
    Intro.Name = "IntroOverlay"
    Intro.Size = UDim2.new(1,0,1,0)
    Intro.BackgroundColor3   = Color3.fromRGB(0,0,0)
    Intro.BackgroundTransparency = 0
    Intro.Parent = ScreenGui

    -- 渐变背景
    local IntroGrad = Instance.new("UIGradient")
    IntroGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 8, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    IntroGrad.Rotation = 90
    IntroGrad.Parent   = Intro

    -- 中央标题
    local IntroTitle = Instance.new("TextLabel")
    IntroTitle.Size   = UDim2.new(0, 600, 0, 60)
    IntroTitle.Position = UDim2.new(0.5, -300, 0.45, -30)
    IntroTitle.BackgroundTransparency = 1
    IntroTitle.Font   = Enum.Font.RobotoMono
    IntroTitle.Text   = "BOOTING NEON CORE"
    IntroTitle.TextSize = 32
    IntroTitle.TextColor3 = Color3.fromRGB(0, 255, 215)
    IntroTitle.TextXAlignment = Enum.TextXAlignment.Center
    IntroTitle.TextYAlignment = Enum.TextYAlignment.Center
    IntroTitle.Parent = Intro

    -- 子标题
    local IntroSub = Instance.new("TextLabel")
    IntroSub.Size   = UDim2.new(0, 600, 0, 30)
    IntroSub.Position = UDim2.new(0.5, -300, 0.5, 10)
    IntroSub.BackgroundTransparency = 1
    IntroSub.Font   = Enum.Font.RobotoMono
    IntroSub.Text   = "SCANNING CLIENT ENVIRONMENT..."
    IntroSub.TextSize = 18
    IntroSub.TextColor3 = Color3.fromRGB(150, 180, 255)
    IntroSub.TextXAlignment = Enum.TextXAlignment.Center
    IntroSub.TextYAlignment = Enum.TextYAlignment.Center
    IntroSub.Parent = Intro

    -- 扫描线
    local ScanLine = Instance.new("Frame")
    ScanLine.Size  = UDim2.new(1,0,0,2)
    ScanLine.Position = UDim2.new(0,0,0,0)
    ScanLine.BackgroundColor3 = Color3.fromRGB(0,255,215)
    ScanLine.BorderSizePixel  = 0
    ScanLine.BackgroundTransparency = 0.4
    ScanLine.Parent = Intro

    local ScanGrad = Instance.new("UIGradient")
    ScanGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,215)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    }
    ScanGrad.Parent = ScanLine

    -- ========= 主 UI 外层：发光边框 =========
    local BorderFrame = Instance.new("Frame")
    BorderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    BorderFrame.Size   = UDim2.new(0, 520, 0, 340)
    BorderFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    BorderFrame.BackgroundTransparency = 1
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

    -- ========= 主面板 =========
    local MainFrame = Instance.new("Frame")
    MainFrame.Name  = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size  = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Library.Theme.Panel
    MainFrame.BackgroundTransparency = Library.Theme.Transparency
    MainFrame.BorderSizePixel  = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent           = ScreenGui
    MainFrame.Visible          = false
    RegisterTheme(MainFrame, "MainBg")

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent       = MainFrame

    -- 顶部标题条
    local Header = Instance.new("Frame")
    Header.Size  = UDim2.new(1, 0, 0, 46)
    Header.BackgroundColor3   = Library.Theme.Header
    Header.BackgroundTransparency = Library.Theme.Transparency - 0.05
    Header.Parent = MainFrame
    RegisterTheme(Header, "HeaderBg")

    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size  = UDim2.new(1, 0, 0, 2)
    HeaderLine.Position = UDim2.new(0,0,1,-2)
    HeaderLine.BackgroundColor3 = Color3.fromRGB(0,255,215)
    HeaderLine.BackgroundTransparency = 0.5
    HeaderLine.BorderSizePixel = 0
    HeaderLine.Parent = Header
    RegisterTheme(HeaderLine, "Accent")

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size  = UDim2.new(0.6, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.RobotoMono
    TitleLabel.Text = string.upper(title)
    TitleLabel.TextSize = 20
    TitleLabel.TextColor3 = Library.Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header
    RegisterTheme(TitleLabel, "Text")

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size  = UDim2.new(0.4, -16, 1, 0)
    StatusLabel.Position = UDim2.new(0.6, 0, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.RobotoMono
    StatusLabel.Text = "[ ONLINE ]"
    StatusLabel.TextSize = 16
    StatusLabel.TextColor3 = Library.Theme.TextDim
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatusLabel.Parent = Header
    RegisterTheme(StatusLabel, "TextDim")

    -- 拖动
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
            local delta   = input.Position - dragStart
            local newPos  = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            MainFrame.Position  = newPos
            BorderFrame.Position= newPos
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- 顶部 Tab 栏
    local TabBar = Instance.new("Frame")
    TabBar.Size  = UDim2.new(1, 0, 0, 32)
    TabBar.Position = UDim2.new(0, 0, 0, 46)
    TabBar.BackgroundColor3   = Color3.fromRGB(8,12,24)
    TabBar.BackgroundTransparency = 0.4
    TabBar.Parent = MainFrame

    local TabLine = Instance.new("Frame")
    TabLine.Size   = UDim2.new(1, 0, 0, 1)
    TabLine.Position = UDim2.new(0, 0, 1, -1)
    TabLine.BackgroundColor3 = Color3.fromRGB(40,50,80)
    TabLine.BorderSizePixel  = 0
    TabLine.Parent = TabBar

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size  = UDim2.new(1, -16, 1, 0)
    TabScroll.Position = UDim2.new(0,8,0,0)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 0
    TabScroll.Parent = TabBar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection   = Enum.FillDirection.Horizontal
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.Padding         = UDim.new(0, 6)
    TabLayout.Parent          = TabScroll

    -- 内容区域
    local PageContainer = Instance.new("Frame")
    PageContainer.Size  = UDim2.new(1, 0, 1, -78)
    PageContainer.Position = UDim2.new(0, 0, 0, 78)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    -- 手机悬浮按钮
    local MobileBtn
    if UserInputService.TouchEnabled then
        MobileBtn = Instance.new("ImageButton")
        MobileBtn.Size = UDim2.new(0, 48, 0, 48)
        MobileBtn.Position = UDim2.new(0, 24, 0.35, 0)
        MobileBtn.BackgroundColor3 = Library.Theme.Panel
        MobileBtn.BackgroundTransparency = 0.3
        MobileBtn.Image = "rbxassetid://10734898355"
        MobileBtn.Parent = ScreenGui
        local mbCorner = Instance.new("UICorner"); mbCorner.CornerRadius = UDim.new(1,0); mbCorner.Parent = MobileBtn
        local mbStroke = Instance.new("UIStroke"); mbStroke.Color = Library.Theme.Accent; mbStroke.Thickness=2; mbStroke.Parent=MobileBtn
        RegisterTheme(mbStroke, "Accent")
    end

    -- 彩虹边框动画
    task.spawn(function()
        local rot = 0
        while ScreenGui.Parent do
            if Library.Settings.RainbowBorder then
                BorderGradient.Color = RainbowSequence
                rot = rot + (60 * Library.Settings.RainbowSpeed * RunService.Heartbeat:Wait())
            else
                local c = Library.Theme.Accent
                BorderGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(0.5, Color3.new(math.min(c.R+0.2,1), math.min(c.G+0.2,1), math.min(c.B+0.2,1))),
                    ColorSequenceKeypoint.new(1, c)
                }
                rot = rot + (15 * RunService.Heartbeat:Wait())
            end
            BorderGradient.Rotation = rot % 360
        end
    end)

    -- UI 显隐 / 高级开关动画
    local visible = true
    local function ToggleUI()
        visible = not visible
        if visible then
            PlaySound("Open")
            MainFrame.Visible  = true
            BorderFrame.Visible= true
            MainFrame.Size     = UDim2.new(0, 0, 0, 40)
            TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 500, 0, 320)}):Play()
        else
            PlaySound("Open", 0.8)
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 0, 0, 40)})
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

    -- ========= 高级启动动画序列 =========
    task.spawn(function()
        -- 扫描线从上到下
        local scanTween = TweenService:Create(ScanLine, TweenInfo.new(0.8, Enum.EasingStyle.Linear),
            {Position = UDim2.new(0,0,1,0)})
        scanTween:Play()
        wait(0.4)
        IntroSub.Text = "LINKING VISUAL INTERFACE..."
        wait(0.4)
        IntroSub.Text = "SYSTEM ONLINE"

        -- 渐隐 Intro
        local fade = TweenService:Create(Intro, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1})
        fade:Play()
        TweenService:Create(IntroTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(IntroSub,   TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        fade.Completed:Wait()
        Intro:Destroy()

        -- UI 出现 & 外框可见
        BorderFrame.Visible = true
        MainFrame.Visible   = true
        MainFrame.Size      = UDim2.new(0, 0, 0, 40)
        PlaySound("Open", 1)
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 500, 0, 320)}):Play()
    end)

    -- ================== 元素 API ==================

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        -- 顶部 Tab 按钮
        local TabButton = Instance.new("TextButton")
        TabButton.Text  = name
        TabButton.AutoButtonColor = false
        TabButton.Size  = UDim2.new(0, 90, 1, 0)
        TabButton.BackgroundTransparency = 1
        TabButton.TextColor3 = Library.Theme.TextDim
        TabButton.Font       = Enum.Font.GothamMedium
        TabButton.TextSize   = 13
        TabButton.Parent     = TabScroll
        RegisterTheme(TabButton, "TextDim")

        local TabSelect = Instance.new("Frame")
        TabSelect.Size  = UDim2.new(1, 0, 0, 2)
        TabSelect.Position = UDim2.new(0,0,1,-2)
        TabSelect.BackgroundColor3 = Library.Theme.Accent
        TabSelect.BackgroundTransparency = 1
        TabSelect.BorderSizePixel = 0
        TabSelect.Parent = TabButton
        RegisterTheme(TabSelect, "Accent")

        -- 对应页面
        local Page = Instance.new("ScrollingFrame")
        Page.Name   = name .. "_Page"
        Page.Size   = UDim2.new(1,0,1,0)
        Page.CanvasSize = UDim2.new(0,0,0,0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness    = 3
        Page.ScrollBarImageColor3  = Color3.fromRGB(40,120,255)
        Page.Visible = false
        Page.Parent  = PageContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0,8)
        PageLayout.Parent  = Page

        local PagePad = Instance.new("UIPadding")
        PagePad.PaddingTop    = UDim.new(0,10)
        PagePad.PaddingLeft   = UDim.new(0,12)
        PagePad.PaddingRight  = UDim.new(0,12)
        PagePad.Parent        = Page

        -- Tab 点击逻辑
        TabButton.MouseButton1Click:Connect(function()
            PlaySound("Click")
            -- 隐藏所有页面
            for _, v in ipairs(PageContainer:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            -- 重置所有 Tab 样式
            for _, v in ipairs(TabScroll:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.25), {TextColor3 = Library.Theme.TextDim}):Play()
                    local sel = v:FindFirstChild("Frame")
                    if sel then
                        TweenService:Create(sel, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                    end
                end
            end
            -- 激活当前
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.25), {TextColor3 = Library.Theme.Accent}):Play()
            TweenService:Create(TabSelect, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        end)

        -- 第一个 Tab 默认激活
        if #PageContainer:GetChildren() == 1 then
            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Accent
            TabSelect.BackgroundTransparency = 0
        end

        local Elements = {}

        -- ---------- Button ----------
        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Text  = text
            Btn.AutoButtonColor = false
            Btn.Size  = UDim2.new(1,0,0,38)
            Btn.BackgroundColor3 = Library.Theme.Panel
            Btn.BackgroundTransparency = Library.Theme.Transparency
            Btn.TextColor3 = Library.Theme.Text
            Btn.Font       = Enum.Font.Gotham
            Btn.TextSize   = 14
            Btn.Parent     = Page
            RegisterTheme(Btn, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Btn
            local s = Instance.new("UIStroke"); s.Color=Library.Theme.Accent; s.Transparency=0.8; s.Parent=Btn
            RegisterTheme(s, "Accent")

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click", 1.2)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundTransparency = Library.Theme.Transparency + 0.1}):Play()
                TweenService:Create(s,   TweenInfo.new(0.1), {Transparency = 0}):Play()
                task.wait(0.12)
                TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundTransparency = Library.Theme.Transparency}):Play()
                TweenService:Create(s,   TweenInfo.new(0.3), {Transparency = 0.8}):Play()
                pcall(callback)
            end)
        end

        -- ---------- Toggle ----------
        function Elements:Toggle(text, flag, default, callback)
            local val = default or false
            Library.Flags[flag] = val

            local Btn = Instance.new("TextButton")
            Btn.Text  = ""
            Btn.AutoButtonColor = false
            Btn.Size  = UDim2.new(1,0,0,38)
            Btn.BackgroundColor3 = Library.Theme.Panel
            Btn.BackgroundTransparency = Library.Theme.Transparency
            Btn.Parent = Page
            RegisterTheme(Btn, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Btn

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.7,0,1,0)
            Label.Position = UDim2.new(0,10,0,0)
            Label.BackgroundTransparency = 1
            Label.Font      = Enum.Font.Gotham
            Label.Text      = text
            Label.TextSize  = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.Parent = Btn
            RegisterTheme(Label, "Text")

            local Box = Instance.new("Frame")
            Box.Size  = UDim2.new(0,38,0,18)
            Box.Position = UDim2.new(1,-52,0.5,-9)
            Box.BackgroundColor3 = Color3.fromRGB(24,32,48)
            Box.Parent = Btn
            local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,9); bc.Parent=Box
            local bs = Instance.new("UIStroke"); bs.Color=Color3.fromRGB(60,80,120); bs.Thickness=1.2; bs.Parent=Box

            local Dot = Instance.new("Frame")
            Dot.Size  = UDim2.new(0,16,0,16)
            Dot.Position = UDim2.new(0,2,0.5,-8)
            Dot.BackgroundColor3 = Color3.fromRGB(110,120,140)
            Dot.Parent = Box
            local dc = Instance.new("UICorner"); dc.CornerRadius=UDim.new(1,0); dc.Parent=Dot

            local function Apply(v)
                val = v
                Library.Flags[flag] = v
                if v then
                    PlaySound("ToggleOn")
                    TweenService:Create(Dot, TweenInfo.new(0.2), {
                        Position          = UDim2.new(1,-18,0.5,-8),
                        BackgroundColor3 = Library.Theme.Accent
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(24,48,72)
                    }):Play()
                else
                    PlaySound("ToggleOff")
                    TweenService:Create(Dot, TweenInfo.new(0.2), {
                        Position          = UDim2.new(0,2,0.5,-8),
                        BackgroundColor3 = Color3.fromRGB(110,120,140)
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(24,32,48)
                    }):Play()
                end
                if callback then pcall(callback, v) end
            end

            if val then Apply(true) end

            Btn.MouseButton1Click:Connect(function()
                Apply(not val)
            end)

            Library.Flags[flag.."_Update"] = Apply
        end

        -- ---------- Slider ----------
        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min
            Library.Flags[flag] = value

            local Frame = Instance.new("Frame")
            Frame.Size  = UDim2.new(1,0,0,56)
            Frame.BackgroundColor3   = Library.Theme.Panel
            Frame.BackgroundTransparency = Library.Theme.Transparency
            Frame.Parent = Page
            RegisterTheme(Frame, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Frame

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.7,0,0,22)
            Label.Position = UDim2.new(0,10,0,6)
            Label.BackgroundTransparency = 1
            Label.Font      = Enum.Font.Gotham
            Label.Text      = text
            Label.TextSize  = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.Parent = Frame
            RegisterTheme(Label, "Text")

            local Val = Instance.new("TextLabel")
            Val.Size  = UDim2.new(0.3,-20,0,22)
            Val.Position = UDim2.new(0.7,0,0,6)
            Val.BackgroundTransparency = 1
            Val.Font      = Enum.Font.Code
            Val.Text      = tostring(value)
            Val.TextSize  = 14
            Val.TextXAlignment = Enum.TextXAlignment.Right
            Val.TextColor3 = Library.Theme.Accent
            Val.Parent = Frame
            RegisterTheme(Val, "Accent")

            local Bar = Instance.new("TextButton")
            Bar.Text  = ""
            Bar.AutoButtonColor = false
            Bar.Size  = UDim2.new(1,-22,0,4)
            Bar.Position = UDim2.new(0,11,0,34)
            Bar.BackgroundColor3 = Color3.fromRGB(32,40,60)
            Bar.Parent = Frame
            local bc2 = Instance.new("UICorner"); bc2.CornerRadius=UDim.new(1,0); bc2.Parent=Bar

            local Fill = Instance.new("Frame")
            Fill.Size  = UDim2.new((value-min)/(max-min),0,1,0)
            Fill.BackgroundColor3 = Library.Theme.Accent
            Fill.BorderSizePixel  = 0
            Fill.Parent = Bar
            RegisterTheme(Fill, "Accent")
            local fc2 = Instance.new("UICorner"); fc2.CornerRadius=UDim.new(1,0); fc2.Parent=Fill

            local dragging = false
            local function SetFromPos(posX)
                local rel = math.clamp((posX - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                local v   = min + (max-min)*rel
                v         = math.floor(v*10+0.5)/10
                value     = v
                Library.Flags[flag] = v
                Fill.Size  = UDim2.new((v-min)/(max-min),0,1,0)
                Val.Text   = tostring(v)
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
                Fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
                Val.Text  = tostring(v)
                if callback then pcall(callback, v) end
            end
        end

        -- ---------- 圆形调色盘 + 预设 ----------
        function Elements:ColorPicker(text, flag, default, callback)
            local col = default or Color3.fromRGB(255,255,255)
            Library.Flags[flag] = col
            local open = false

            local Frame = Instance.new("Frame")
            Frame.Size  = UDim2.new(1,0,0,42)
            Frame.BackgroundColor3   = Library.Theme.Panel
            Frame.BackgroundTransparency = Library.Theme.Transparency
            Frame.ClipsDescendants  = true
            Frame.Parent = Page
            RegisterTheme(Frame, "MainBg")
            local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Frame

            local Label = Instance.new("TextLabel")
            Label.Size  = UDim2.new(0.6,0,0,42)
            Label.Position = UDim2.new(0,10,0,0)
            Label.BackgroundTransparency = 1
            Label.Font      = Enum.Font.Gotham
            Label.Text      = text
            Label.TextSize  = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextColor3 = Library.Theme.Text
            Label.Parent = Frame
            RegisterTheme(Label, "Text")

            local Preview = Instance.new("TextButton")
            Preview.Size  = UDim2.new(0,40,0,20)
            Preview.Position = UDim2.new(1,-52,0,11)
            Preview.BackgroundColor3 = col
            Preview.Text      = ""
            Preview.AutoButtonColor = false
            Preview.Parent = Frame
            local pc = Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,6); pc.Parent=Preview

            local Container = Instance.new("Frame")
            Container.Size  = UDim2.new(1,-20,0,150)
            Container.Position = UDim2.new(0,10,0,44)
            Container.BackgroundTransparency = 1
            Container.Parent = Frame

            -- 色轮
            local Wheel = Instance.new("ImageButton")
            Wheel.Size  = UDim2.new(0,100,0,100)
            Wheel.Position = UDim2.new(0,0,0,0)
            Wheel.BackgroundTransparency = 1
            Wheel.Image = "rbxassetid://6020299385" -- HSV 色轮贴图
            Wheel.Parent = Container

            local Cursor = Instance.new("ImageLabel")
            Cursor.Size  = UDim2.new(0,10,0,10)
            Cursor.AnchorPoint = Vector2.new(0.5,0.5)
            Cursor.BackgroundTransparency = 1
            Cursor.Image = "rbxassetid://16449174151"
            Cursor.Parent = Wheel

            -- 预设颜色
            local Presets = Instance.new("Frame")
            Presets.Size  = UDim2.new(0,100,0,100)
            Presets.Position = UDim2.new(1,-100,0,0)
            Presets.BackgroundTransparency = 1
            Presets.Parent = Container

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize    = UDim2.new(0,28,0,28)
            Grid.CellPadding = UDim2.new(0,4,0,4)
            Grid.Parent      = Presets

            local PresetColors = {
                Color3.fromRGB(255,  0,  0),
                Color3.fromRGB(  0,255,  0),
                Color3.fromRGB(  0,  0,255),
                Color3.fromRGB(255,255,  0),
                Color3.fromRGB(  0,255,255),
                Color3.fromRGB(255,  0,255),
                Color3.fromRGB(255,128,  0),
                Color3.fromRGB(128,  0,255),
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
                sw.Parent = Presets
                local sc = Instance.new("UICorner"); sc.CornerRadius=UDim.new(1,0); sc.Parent=sw
                sw.MouseButton1Click:Connect(function()
                    PlaySound("Click",1.1)
                    ApplyColor(c3)
                end)
            end

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
                ApplyColor(Color3.fromHSV(hue, sat, 1))
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
                    {Size = open and UDim2.new(1,0,0,190) or UDim2.new(1,0,0,42)}):Play()
            end)
        end

        return Elements
    end

    -- ========== 内建 Settings 标签 ==========
    local SettingsTab = WindowFuncs:Tab("Settings")

    SettingsTab:ColorPicker("Accent Color", "ThemeAccent", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        Library:UpdateTheme()
    end)

    SettingsTab:Toggle("Rainbow Border", "RBFlag", true, function(v)
        Library.Settings.RainbowBorder = v
    end)

    SettingsTab:Slider("Border Speed", "RBSpeed", 0.2, 3, Library.Settings.RainbowSpeed, function(v)
        Library.Settings.RainbowSpeed = v
    end)

    SettingsTab:Slider("Panel Transparency", "TransFlag", 0, 0.6, Library.Theme.Transparency, function(v)
        Library.Theme.Transparency = v
        Library:UpdateTheme()
    end)

    SettingsTab:Toggle("UI Sounds", "SoundFlag", true, function(v)
        Library.Settings.SoundEnabled = v
    end)

    SettingsTab:Button("Unload UI", function()
        ScreenGui:Destroy()
    end)

    return WindowFuncs
end

return Library
