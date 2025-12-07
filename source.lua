--[[
    SCI-FI UI LIBRARY v7.0
    - 全新外观（中置全息卡片 + 侧边导航）
    - 彩虹边框（可开关 & 调速）
    - 圆形调色盘 + 预设颜色
    - 手机悬浮按钮 + PC 右Ctrl 显示/隐藏
    - 高级启动动画 + 独特启动音效
    Author: logquickly (AI Assistant)
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

--=========================
-- 全局配置 & 主题
--=========================

Library.Settings = {
    RainbowBorder = true,   -- 彩虹边框开关
    RainbowSpeed  = 1,      -- 彩虹速度
    SoundEnabled  = true,   -- UI 音效总开关
}

Library.Theme = {
    Background   = Color3.fromRGB(8, 10, 18),   -- 主面板背景
    Header       = Color3.fromRGB(18, 22, 32),  -- 头部/模块背景
    Accent       = Color3.fromRGB(0, 255, 215), -- 默认高亮青色
    Text         = Color3.fromRGB(245, 245, 245),
    TextDim      = Color3.fromRGB(140, 140, 160),
    Transparency = 0.22,                        -- 面板透明度（0=不透明，1=全透）
}

Library.Flags        = {}   -- 保存 Toggle / Slider / ColorPicker 的状态
Library.ThemeObjects = {}   -- 需要跟随主题变化的 UI 对象

-- 彩虹颜色序列（完整光谱）
local RainbowSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255,   0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(  0,   0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0))
}

-- 音效表（可按喜好换 ID）
local Sounds = {
    Hover     = 6895079960, -- 轻微滴声
    Click     = 6042053626, -- 清脆按键
    ToggleOn  = 6042053626,
    ToggleOff = 6042053610,
    Intro     = 6035688461, -- 启动音效（独特）
    Open      = 6895079853,
}

local function PlaySound(name, vol)
    if not Library.Settings.SoundEnabled then return end
    local id = Sounds[name]
    if not id then return end

    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. id
        s.Volume = vol or 0.6
        s.Parent = SoundService
        s.PlayOnRemove = true
        s:Destroy()
    end)
end

local function GetParent()
    local ok, gui = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if ok and gui then
        return gui
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function RegisterTheme(obj, kind)
    table.insert(Library.ThemeObjects, {Object = obj, Kind = kind})
end

function Library:UpdateTheme()
    for _, entry in ipairs(Library.ThemeObjects) do
        local obj, kind = entry.Object, entry.Kind
        if not obj or not obj.Parent then continue end

        if kind == "MainBg" then
            obj.BackgroundColor3   = Library.Theme.Background
            obj.BackgroundTransparency = Library.Theme.Transparency
        elseif kind == "HeaderBg" then
            obj.BackgroundColor3   = Library.Theme.Header
            obj.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.08, 0, 1)
        elseif kind == "Accent" then
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

--=========================
-- 创建主窗口
--=========================

function Library:CreateWindow(cfg)
    local title = (cfg and cfg.Name) or "NEURAL HUB"

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SciFi_UI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder   = 9999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetParent()

    --=========================
    -- 全屏启动遮罩 & 动画
    --=========================

    local BootOverlay = Instance.new("Frame")
    BootOverlay.Size = UDim2.new(1, 0, 1, 0)
    BootOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
    BootOverlay.BackgroundTransparency = 0
    BootOverlay.Parent = ScreenGui
    BootOverlay.ZIndex = 200

    local BootGradient = Instance.new("UIGradient")
    BootGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 15, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 15, 40))
    }
    BootGradient.Rotation = 90
    BootGradient.Parent = BootOverlay

    local BootCard = Instance.new("Frame")
    BootCard.AnchorPoint = Vector2.new(0.5, 0.5)
    BootCard.Size = UDim2.new(0, 360, 0, 140)
    BootCard.Position = UDim2.new(0.5, 0, 0.5, 0)
    BootCard.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    BootCard.BackgroundTransparency = 0.15
    BootCard.Parent = BootOverlay
    BootCard.ZIndex = 210
    local BootCorner = Instance.new("UICorner", BootCard)
    BootCorner.CornerRadius = UDim.new(0, 10)

    local BootStroke = Instance.new("UIStroke")
    BootStroke.Thickness = 2
    BootStroke.Color = Color3.fromRGB(0, 255, 215)
    BootStroke.Transparency = 0.5
    BootStroke.Parent = BootCard

    local BootTitle = Instance.new("TextLabel")
    BootTitle.Size = UDim2.new(1, -40, 0, 40)
    BootTitle.Position = UDim2.new(0, 20, 0, 18)
    BootTitle.BackgroundTransparency = 1
    BootTitle.Font = Enum.Font.Code
    BootTitle.TextSize = 24
    BootTitle.TextColor3 = Color3.fromRGB(0, 255, 215)
    BootTitle.TextXAlignment = Enum.TextXAlignment.Left
    BootTitle.Text = ""
    BootTitle.ZIndex = 211
    BootTitle.Parent = BootCard

    local BootSub = Instance.new("TextLabel")
    BootSub.Size = UDim2.new(1, -40, 0, 20)
    BootSub.Position = UDim2.new(0, 20, 0, 60)
    BootSub.BackgroundTransparency = 1
    BootSub.Font = Enum.Font.Gotham
    BootSub.TextSize = 14
    BootSub.TextColor3 = Color3.fromRGB(180, 180, 200)
    BootSub.TextXAlignment = Enum.TextXAlignment.Left
    BootSub.Text = "INITIALIZING SUBSYSTEMS..."
    BootSub.ZIndex = 211
    BootSub.Parent = BootCard

    local BootBarBg = Instance.new("Frame")
    BootBarBg.Size = UDim2.new(1, -40, 0, 4)
    BootBarBg.Position = UDim2.new(0, 20, 1, -30)
    BootBarBg.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
    BootBarBg.BorderSizePixel = 0
    BootBarBg.ZIndex = 211
    BootBarBg.Parent = BootCard
    local BootBarCorner = Instance.new("UICorner", BootBarBg)
    BootBarCorner.CornerRadius = UDim.new(1, 0)

    local BootBarFill = Instance.new("Frame")
    BootBarFill.Size = UDim2.new(0, 0, 1, 0)
    BootBarFill.Position = UDim2.new(0, 0, 0, 0)
    BootBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 215)
    BootBarFill.BorderSizePixel = 0
    BootBarFill.ZIndex = 212
    BootBarFill.Parent = BootBarBg
    local BootBarFillCorner = Instance.new("UICorner", BootBarFill)
    BootBarFillCorner.CornerRadius = UDim.new(1, 0)

    --=========================
    -- 彩虹边框底层
    --=========================

    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "GlowBorder"
    GlowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowFrame.Size = UDim2.new(0, 540, 0, 360)
    GlowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowFrame.BackgroundTransparency = 1
    GlowFrame.Parent = ScreenGui

    local GlowStroke = Instance.new("UIStroke")
    GlowStroke.Thickness = 3
    GlowStroke.Transparency = 0.08
    GlowStroke.Parent = GlowFrame

    local GlowCorner = Instance.new("UICorner", GlowFrame)
    GlowCorner.CornerRadius = UDim.new(0, 12)

    local GlowGradient = Instance.new("UIGradient")
    GlowGradient.Rotation = 0
    GlowGradient.Parent = GlowStroke

    --=========================
    -- 主容器 + 内层玻璃卡片
    --=========================

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 520, 0, 340)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local Shell = Instance.new("Frame")
    Shell.Name = "Shell"
    Shell.Size = UDim2.new(1, -24, 1, -24)
    Shell.Position = UDim2.new(0, 12, 0, 12)
    Shell.BackgroundColor3 = Library.Theme.Background
    Shell.BackgroundTransparency = Library.Theme.Transparency
    Shell.Parent = MainFrame
    local ShellCorner = Instance.new("UICorner", Shell)
    ShellCorner.CornerRadius = UDim.new(0, 10)
    RegisterTheme(Shell, "MainBg")

    local ShellStroke = Instance.new("UIStroke")
    ShellStroke.Thickness = 1
    ShellStroke.Transparency = 0.7
    ShellStroke.Color = Color3.fromRGB(70, 80, 100)
    ShellStroke.Parent = Shell

    -- 顶部信息条
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = Library.Theme.Header
    TopBar.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.08, 0, 1)
    TopBar.Parent = Shell
    RegisterTheme(TopBar, "HeaderBg")

    local TopCorner = Instance.new("UICorner", TopBar)
    TopCorner.CornerRadius = UDim.new(0, 10)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.Code
    TitleLabel.TextSize = 20
    TitleLabel.Text = string.upper(title)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextColor3 = Library.Theme.Accent
    TitleLabel.Parent = TopBar
    RegisterTheme(TitleLabel, "Accent")

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0.4, -16, 1, 0)
    StatusLabel.Position = UDim2.new(0.6, 0, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 12
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatusLabel.TextColor3 = Library.Theme.TextDim
    StatusLabel.Text = "NEURAL LINK • ONLINE"
    StatusLabel.Parent = TopBar

    -- 拖动逻辑（拖 Shell/TopBar 即可）
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            MainFrame.Position = newPos
            GlowFrame.Position = newPos
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    --=========================
    -- 左侧导航 / 右侧内容
    --=========================

    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -46)
    Body.Position = UDim2.new(0, 0, 0, 46)
    Body.BackgroundTransparency = 1
    Body.Parent = Shell

    local TabsFrame = Instance.new("Frame")
    TabsFrame.Size = UDim2.new(0, 140, 1, 0)
    TabsFrame.Position = UDim2.new(0, 0, 0, 0)
    TabsFrame.BackgroundTransparency = 1
    TabsFrame.Parent = Body

    local TabsBg = Instance.new("Frame")
    TabsBg.Size = UDim2.new(1, -12, 1, -16)
    TabsBg.Position = UDim2.new(0, 8, 0, 8)
    TabsBg.BackgroundColor3 = Library.Theme.Header
    TabsBg.BackgroundTransparency = math.clamp(Library.Theme.Transparency, 0.1, 0.8)
    TabsBg.Parent = TabsFrame
    local TabsCorner = Instance.new("UICorner", TabsBg)
    TabsCorner.CornerRadius = UDim.new(0, 8)
    RegisterTheme(TabsBg, "HeaderBg")

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(1, -12, 1, -16)
    TabScroll.Position = UDim2.new(0, 6, 0, 8)
    TabScroll.BackgroundTransparency = 1
    TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScroll.ScrollBarThickness = 2
    TabScroll.Parent = TabsBg

    local TabLayout = Instance.new("UIListLayout", TabScroll)
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local TabPad = Instance.new("UIPadding", TabScroll)
    TabPad.PaddingTop = UDim.new(0, 4)

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -152, 1, -16)
    ContentFrame.Position = UDim2.new(0, 148, 0, 8)
    ContentFrame.BackgroundColor3 = Library.Theme.Header
    ContentFrame.BackgroundTransparency = math.clamp(Library.Theme.Transparency, 0.08, 0.75)
    ContentFrame.Parent = Body
    local ContentCorner = Instance.new("UICorner", ContentFrame)
    ContentCorner.CornerRadius = UDim.new(0, 8)
    RegisterTheme(ContentFrame, "HeaderBg")

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -16, 1, -16)
    PageContainer.Position = UDim2.new(0, 8, 0, 8)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = ContentFrame

    --=========================
    -- 手机悬浮按钮 + PC 按键
    --=========================

    local MobileBtn
    if UserInputService.TouchEnabled then
        MobileBtn = Instance.new("ImageButton")
        MobileBtn.Size = UDim2.new(0, 56, 0, 56)
        MobileBtn.Position = UDim2.new(0, 30, 0.35, 0)
        MobileBtn.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
        MobileBtn.BackgroundTransparency = 0.3
        MobileBtn.Image = "rbxassetid://10734898355"
        MobileBtn.Parent = ScreenGui
        local mbCorner = Instance.new("UICorner", MobileBtn)
        mbCorner.CornerRadius = UDim.new(1, 0)
        local mbStroke = Instance.new("UIStroke", MobileBtn)
        mbStroke.Thickness = 2
        mbStroke.Color = Library.Theme.Accent
        RegisterTheme(mbStroke, "Accent")
    end

    local isVisible = true
    local function ToggleUI()
        isVisible = not isVisible
        if isVisible then
            MainFrame.Visible = true
            GlowFrame.Visible = true
            PlaySound("Open")
            MainFrame.Size = UDim2.new(0, 0, 0, 40)
            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 520, 0, 340)}
            ):Play()
        else
            PlaySound("Open", 0.8)
            local t = TweenService:Create(
                MainFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 0, 0, 40)}
            )
            t:Play()
            t.Completed:Wait()
            MainFrame.Visible = false
            GlowFrame.Visible = false
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

    --=========================
    -- 彩虹边框循环（重写且稳定）
    --=========================

    task.spawn(function()
        local rot = 0
        while ScreenGui.Parent do
            if Library.Settings.RainbowBorder then
                GlowGradient.Color = RainbowSequence
                rot = (rot + RunService.RenderStepped:Wait() * 60 * Library.Settings.RainbowSpeed) % 360
                GlowGradient.Rotation = rot
            else
                -- 单色模式：使用 Accent 做柔和渐变
                local c = Library.Theme.Accent
                GlowGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(
                        math.clamp(c.R * 255 + 40, 0, 255),
                        math.clamp(c.G * 255 + 40, 0, 255),
                        math.clamp(c.B * 255 + 40, 0, 255)
                    )),
                    ColorSequenceKeypoint.new(1, c)
                }
                rot = (rot + RunService.RenderStepped:Wait() * 12) % 360
                GlowGradient.Rotation = rot
            end
        end
    end)

    --=========================
    -- 启动动画：文字打字 + 进度条 + 主窗展开
    --=========================

    PlaySound("Intro", 1.4)

    task.spawn(function()
        local txt = "NEURAL LINK: ONLINE"
        for i = 1, #txt do
            BootTitle.Text = string.sub(txt, 1, i)
            BootTitle.TextTransparency = 0
            task.wait(0.03)
        end
        -- 模拟加载进度
        TweenService:Create(
            BootBarFill,
            TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 1, 0)}
        ):Play()
        task.wait(0.85)

        -- 同时淡出遮罩、点亮主UI
        MainFrame.Size = UDim2.new(0, 0, 0, 40)
        GlowFrame.Visible = true
        MainFrame.Visible = true

        local fade = TweenService:Create(
            BootOverlay,
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        local cardFade = TweenService:Create(
            BootCard,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        )
        local mainExpand = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 520, 0, 340)}
        )

        fade:Play()
        cardFade:Play()
        mainExpand:Play()
        mainExpand.Completed:Wait()
        BootOverlay:Destroy()
    end)

    --=========================
    -- UI 元素 API 实现
    --=========================

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, -6, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TabButton.BackgroundTransparency = 1
        TabButton.TextColor3 = Library.Theme.TextDim
        TabButton.Font = Enum.Font.GothamMedium
        TabButton.TextSize = 13
        TabButton.Text = name
        TabButton.Parent = TabScroll

        local TabBtnBg = Instance.new("Frame")
        TabBtnBg.Size = UDim2.new(1, 0, 1, 0)
        TabBtnBg.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
        TabBtnBg.BackgroundTransparency = 0.8
        TabBtnBg.Parent = TabButton
        local tCorner = Instance.new("UICorner", TabBtnBg)
        tCorner.CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = false
        Page.Parent = PageContainer

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local PagePad = Instance.new("UIPadding", Page)
        PagePad.PaddingTop = UDim.new(0, 8)
        PagePad.PaddingLeft = UDim.new(0, 4)
        PagePad.PaddingRight = UDim.new(0, 4)

        TabButton.MouseButton1Click:Connect(function()
            PlaySound("Click")
            for _, child in ipairs(PageContainer:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end
            for _, child in ipairs(TabScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = Library.Theme.TextDim
                    if child:FindFirstChildOfClass("Frame") then
                        TweenService:Create(
                            child.Frame,
                            TweenInfo.new(0.2),
                            {BackgroundTransparency = 0.8}
                        ):Play()
                    end
                end
            end

            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Accent
            TweenService:Create(
                TabBtnBg,
                TweenInfo.new(0.2),
                {BackgroundTransparency = 0.2}
            ):Play()
        end)

        -- 默认激活第一个 Tab
        if #TabScroll:GetChildren() == 1 then
            Page.Visible = true
            TabButton.TextColor3 = Library.Theme.Accent
            TabBtnBg.BackgroundTransparency = 0.2
        end

        local Elements = {}

        -- 按钮
        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -4, 0, 36)
            Btn.BackgroundColor3 = Library.Theme.Header
            Btn.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.05, 0, 1)
            Btn.TextColor3 = Library.Theme.Text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.Text = text
            Btn.AutoButtonColor = false
            Btn.Parent = Page
            RegisterTheme(Btn, "HeaderBg")

            local bCorner = Instance.new("UICorner", Btn)
            bCorner.CornerRadius = UDim.new(0, 6)

            local Stroke = Instance.new("UIStroke")
            Stroke.Thickness = 1
            Stroke.Transparency = 0.7
            Stroke.Color = Library.Theme.Accent
            Stroke.Parent = Btn
            RegisterTheme(Stroke, "Accent")

            Btn.MouseEnter:Connect(function()
                PlaySound("Hover", 0.3)
                TweenService:Create(Stroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
            end)

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click", 1.1)
                local t1 = TweenService:Create(Btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -8, 0, 34)})
                t1:Play()
                t1.Completed:Wait()
                TweenService:Create(Btn, TweenInfo.new(0.08), {Size = UDim2.new(1, -4, 0, 36)}):Play()
                if callback then
                    pcall(callback)
                end
            end)
        end

        -- 开关
        function Elements:Toggle(text, flag, default, callback)
            local state = default or false
            Library.Flags[flag] = state

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -4, 0, 36)
            Btn.BackgroundColor3 = Library.Theme.Header
            Btn.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.05, 0, 1)
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = Page
            RegisterTheme(Btn, "HeaderBg")
            local bCorner = Instance.new("UICorner", Btn)
            bCorner.CornerRadius = UDim.new(0, 6)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextColor3 = Library.Theme.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Text = text
            Label.Parent = Btn

            local Box = Instance.new("Frame")
            Box.Size = UDim2.new(0, 22, 0, 22)
            Box.Position = UDim2.new(1, -30, 0.5, -11)
            Box.BackgroundColor3 = state and Library.Theme.Accent or Color3.fromRGB(50, 50, 60)
            Box.Parent = Btn
            local BoxCorner = Instance.new("UICorner", Box)
            BoxCorner.CornerRadius = UDim.new(0, 4)

            local function SetState(v)
                state = v
                Library.Flags[flag] = v
                if v then
                    PlaySound("ToggleOn", 1.1)
                else
                    PlaySound("ToggleOff", 0.9)
                end
                TweenService:Create(
                    Box,
                    TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {BackgroundColor3 = v and Library.Theme.Accent or Color3.fromRGB(50, 50, 60)}
                ):Play()
                if callback then
                    pcall(callback, v)
                end
            end

            Btn.MouseButton1Click:Connect(function()
                SetState(not state)
            end)

            Library.Flags[flag .. "_Update"] = SetState
        end

        -- 滑块
        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min
            Library.Flags[flag] = value

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -4, 0, 52)
            Frame.BackgroundColor3 = Library.Theme.Header
            Frame.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.05, 0, 1)
            Frame.Parent = Page
            RegisterTheme(Frame, "HeaderBg")
            local fCorner = Instance.new("UICorner", Frame)
            fCorner.CornerRadius = UDim.new(0, 6)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.7, 0, 0, 22)
            Label.Position = UDim2.new(0, 10, 0, 4)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextColor3 = Library.Theme.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Text = text
            Label.Parent = Frame

            local Val = Instance.new("TextLabel")
            Val.Size = UDim2.new(0.3, -10, 0, 22)
            Val.Position = UDim2.new(0.7, 0, 0, 4)
            Val.BackgroundTransparency = 1
            Val.Font = Enum.Font.Code
            Val.TextSize = 14
            Val.TextColor3 = Library.Theme.Accent
            Val.TextXAlignment = Enum.TextXAlignment.Right
            Val.Text = tostring(value)
            Val.Parent = Frame
            RegisterTheme(Val, "Accent")

            local Bar = Instance.new("TextButton")
            Bar.Size = UDim2.new(1, -20, 0, 4)
            Bar.Position = UDim2.new(0, 10, 0, 34)
            Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Bar.Text = ""
            Bar.AutoButtonColor = false
            Bar.Parent = Frame
            local bCorner = Instance.new("UICorner", Bar)
            bCorner.CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Library.Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Bar
            local f2 = Instance.new("UICorner", Fill)
            f2.CornerRadius = UDim.new(1, 0)
            RegisterTheme(Fill, "Accent")

            local function SetValue(v)
                v = math.clamp(v, min, max)
                value = v
                Library.Flags[flag] = v
                Val.Text = string.format("%.1f", v)
                Fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
                if callback then
                    pcall(callback, v)
                end
            end

            local dragging = false
            local function HandleInput(input)
                local rel = math.clamp(
                    (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
                    0, 1
                )
                SetValue(min + (max - min) * rel)
            end

            Bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    HandleInput(i)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                    HandleInput(i)
                end
            end)
        end

        -- 圆形调色盘 + 预设
        function Elements:ColorPicker(text, flag, default, callback)
            local color = default or Color3.fromRGB(255, 255, 255)
            Library.Flags[flag] = color
            local isOpen = false

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -4, 0, 40)
            Frame.BackgroundColor3 = Library.Theme.Header
            Frame.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.05, 0, 1)
            Frame.ClipsDescendants = true
            Frame.Parent = Page
            RegisterTheme(Frame, "HeaderBg")
            local fCorner = Instance.new("UICorner", Frame)
            fCorner.CornerRadius = UDim.new(0, 6)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.TextColor3 = Library.Theme.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Text = text
            Label.Parent = Frame

            local Preview = Instance.new("TextButton")
            Preview.Size = UDim2.new(0, 32, 0, 20)
            Preview.Position = UDim2.new(1, -42, 0.5, -10)
            Preview.BackgroundColor3 = color
            Preview.Text = ""
            Preview.AutoButtonColor = false
            Preview.Parent = Frame
            local pCorner = Instance.new("UICorner", Preview)
            pCorner.CornerRadius = UDim.new(0, 6)

            local PickerArea = Instance.new("Frame")
            PickerArea.Size = UDim2.new(1, -20, 0, 150)
            PickerArea.Position = UDim2.new(0, 10, 0, 45)
            PickerArea.BackgroundTransparency = 1
            PickerArea.Parent = Frame

            -- 左：色轮
            local Wheel = Instance.new("ImageButton")
            Wheel.Size = UDim2.new(0, 100, 0, 100)
            Wheel.Position = UDim2.new(0, 0, 0, 0)
            Wheel.BackgroundTransparency = 1
            Wheel.Image = "rbxassetid://6020299385" -- HSV 色轮贴图
            Wheel.Parent = PickerArea

            local Cursor = Instance.new("ImageLabel")
            Cursor.Size = UDim2.new(0, 10, 0, 10)
            Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            Cursor.BackgroundTransparency = 1
            Cursor.Image = "rbxassetid://16449174151"
            Cursor.Parent = Wheel

            -- 右：预设颜色
            local PresetFrame = Instance.new("Frame")
            PresetFrame.Size = UDim2.new(0, 110, 0, 100)
            PresetFrame.Position = UDim2.new(1, -110, 0, 0)
            PresetFrame.BackgroundTransparency = 1
            PresetFrame.Parent = PickerArea

            local PGrid = Instance.new("UIGridLayout", PresetFrame)
            PGrid.CellSize = UDim2.new(0, 30, 0, 30)
            PGrid.CellPadding = UDim2.new(0, 6, 0, 6)

            local PresetColors = {
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 0, 255),
                Color3.fromRGB(255, 128, 0),
                Color3.fromRGB(128, 0, 255),
                Color3.fromRGB(255, 255, 255),
            }

            local function ApplyColor(c)
                color = c
                Library.Flags[flag] = c
                Preview.BackgroundColor3 = c
                if callback then
                    pcall(callback, c)
                end
            end

            for _, pc in ipairs(PresetColors) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 30, 0, 30)
                btn.BackgroundColor3 = pc
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = PresetFrame
                local cCorner = Instance.new("UICorner", btn)
                cCorner.CornerRadius = UDim.new(1, 0)
                btn.MouseButton1Click:Connect(function()
                    PlaySound("Click", 1.1)
                    ApplyColor(pc)
                end)
            end

            local dragging = false
            local function UpdateFromWheel(input)
                local center = Wheel.AbsolutePosition + Wheel.AbsoluteSize / 2
                local delta  = Vector2.new(input.Position.X - center.X, input.Position.Y - center.Y)
                local dist   = math.min(delta.Magnitude, Wheel.AbsoluteSize.X / 2)
                local angle  = math.atan2(delta.Y, delta.X)

                Cursor.Position = UDim2.new(
                    0.5 + (math.cos(angle) * dist / Wheel.AbsoluteSize.X),
                    0,
                    0.5 + (math.sin(angle) * dist / Wheel.AbsoluteSize.Y),
                    0
                )

                local sat = dist / (Wheel.AbsoluteSize.X / 2)
                local hue = (math.deg(angle) + 180) / 360
                local newColor = Color3.fromHSV(hue, sat, 1)
                ApplyColor(newColor)
            end

            Wheel.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromWheel(i)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromWheel(i)
                end
            end)

            Preview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                TweenService:Create(
                    Frame,
                    TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {Size = isOpen and UDim2.new(1, -4, 0, 170) or UDim2.new(1, -4, 0, 40)}
                ):Play()
            end)
        end

        return Elements
    end

    --=========================
    -- 自动注入 Settings 页
    --=========================

    local S = WindowFuncs:Tab("Settings")

    -- 主题高亮色
    S:ColorPicker("Accent Color", "ThemeAccent", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        Library:UpdateTheme()
    end)

    -- 彩虹边框控制
    S:Toggle("Rainbow Border", "RainbowBorder", true, function(v)
        Library.Settings.RainbowBorder = v
    end)

    S:Slider("Border Speed", "RainbowSpeed", 0.2, 4, 1, function(v)
        Library.Settings.RainbowSpeed = v
    end)

    -- 透明度
    S:Slider("Panel Opacity", "PanelAlpha", 0, 1, Library.Theme.Transparency, function(v)
        Library.Theme.Transparency = v
        Library:UpdateTheme()
    end)

    -- 声音总开关
    S:Toggle("UI Sounds", "UISound", true, function(v)
        Library.Settings.SoundEnabled = v
    end)

    -- 卸载
    S:Button("Unload UI", function()
        ScreenGui:Destroy()
    end)

    -- 初始应用主题
    Library:UpdateTheme()

    return WindowFuncs
end

return Library
