--[[
    SCI-FI UI LIBRARY v3.0 (Ultimate Edition)
    Features: Mobile, Config, Sounds, Holographic Anim, Glassmorphism
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

-- // 状态与存储
Library.Flags = {}
Library.ThemeObjects = {} -- 存储所有UI对象以便实时更新主题
Library.ConfigFolder = "SciFiConfig"
Library.CurrentConfig = "Default"

-- // 默认主题配置
Library.Theme = {
    Background = Color3.fromRGB(10, 12, 18),
    Header = Color3.fromRGB(20, 22, 28),
    Accent = Color3.fromRGB(0, 255, 230), -- 默认青色
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(140, 140, 140),
    Transparency = 0.2, -- 默认半透明 (0=不透明, 1=全透)
    SoundEnabled = true
}

-- // 音效库 (Roblox ID)
local Sounds = {
    Hover = 4590662766,
    Click = 4590657391, 
    ToggleOn = 3398620867,
    ToggleOff = 3398620867,
    Open = 2865227271, -- 全息展开音效
}

-- // 辅助函数：播放声音
local function PlaySound(name, pitch)
    if not Library.Theme.SoundEnabled then return end
    local id = Sounds[name]
    if not id then return end
    
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. id
        s.Volume = 0.5
        s.Pitch = pitch or 1
        s.Parent = SoundService
        s.PlayOnRemove = true
        s.Destroy(s)
    end)
end

-- // 辅助函数：获取挂载点
local function GetParent()
    local success, parent = pcall(function() return gethui and gethui() or CoreGui end)
    return (success and parent) and parent or LocalPlayer:WaitForChild("PlayerGui")
end

-- // 辅助函数：注册对象到主题系统
local function RegisterTheme(obj, propType)
    table.insert(Library.ThemeObjects, {Object = obj, Type = propType})
end

-- // 核心：更新所有UI外观
function Library:UpdateTheme()
    for _, item in ipairs(Library.ThemeObjects) do
        local obj = item.Object
        local type = item.Type
        
        if obj then
            if type == "MainBg" then
                obj.BackgroundColor3 = Library.Theme.Background
                obj.BackgroundTransparency = Library.Theme.Transparency
            elseif type == "HeaderBg" then
                obj.BackgroundColor3 = Library.Theme.Header
                obj.BackgroundTransparency = math.clamp(Library.Theme.Transparency - 0.1, 0, 1)
            elseif type == "Accent" then
                -- 某些对象只改变颜色
                if obj:IsA("UIStroke") then obj.Color = Library.Theme.Accent 
                elseif obj:IsA("TextLabel") then obj.TextColor3 = Library.Theme.Accent 
                elseif obj:IsA("Frame") or obj:IsA("ImageLabel") then obj.BackgroundColor3 = Library.Theme.Accent end
            end
        end
    end
end

function Library:CreateWindow(config)
    local title = config.Name or "Sci-Fi Hub"
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetParent()
    ScreenGui.DisplayOrder = 100

    -- 1. 全息边框 (Glow)
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "HoloGlow"
    GlowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowFrame.Size = UDim2.new(0, 506, 0, 326)
    GlowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GlowFrame.BackgroundTransparency = 0
    GlowFrame.BorderSizePixel = 0
    GlowFrame.Parent = ScreenGui

    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 10)
    GlowCorner.Parent = GlowFrame

    local Gradient = Instance.new("UIGradient")
    Gradient.Rotation = 45
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Library.Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
        ColorSequenceKeypoint.new(1, Library.Theme.Accent)
    }
    Gradient.Parent = GlowFrame
    RegisterTheme(Gradient, "AccentGradient") -- 稍后处理复杂渐变

    -- 2. 主容器 (用于缩放动画)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Library.Theme.Background
    MainFrame.BackgroundTransparency = Library.Theme.Transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    RegisterTheme(MainFrame, "MainBg")

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    -- 3. 动态渐变逻辑
    local rot = 0
    RunService.RenderStepped:Connect(function(dt)
        if ScreenGui.Enabled then
            rot = rot + (60 * dt)
            Gradient.Rotation = rot % 360
            -- 实时更新渐变色的首尾，以匹配Accent
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Library.Theme.Accent),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255 - Library.Theme.Accent.R*255, 255 - Library.Theme.Accent.G*255, 255 - Library.Theme.Accent.B*255)), -- 补色
                ColorSequenceKeypoint.new(1, Library.Theme.Accent)
            }
        end
    end)

    -- 4. 标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Library.Theme.Header
    TopBar.BackgroundTransparency = Library.Theme.Transparency - 0.1
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    RegisterTheme(TopBar, "HeaderBg")

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Text = string.upper(title)
    TopTitle.Font = Enum.Font.SciFi
    TopTitle.TextSize = 20
    TopTitle.TextColor3 = Library.Theme.Accent
    TopTitle.Size = UDim2.new(1, -20, 1, 0)
    TopTitle.Position = UDim2.new(0, 20, 0, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    RegisterTheme(TopTitle, "Accent")

    -- 拖动逻辑
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = GlowFrame.Position -- 拖动GlowFrame，MainFrame跟随
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            GlowFrame.Position = newPos
            MainFrame.Position = newPos
        end
    end)

    -- 5. 动画控制 (Open/Close)
    local isOpen = true
    local function ToggleUI()
        isOpen = not isOpen
        if isOpen then
            ScreenGui.Enabled = true
            PlaySound("Open", 1)
            -- 全息展开动画
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            GlowFrame.Size = UDim2.new(0, 0, 0, 0)
            GlowFrame.Visible = true
            
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
            TweenService:Create(GlowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 506, 0, 326)}):Play()
        else
            PlaySound("Open", 0.8)
            -- 收缩动画
            local t1 = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            local t2 = TweenService:Create(GlowFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            t1:Play(); t2:Play()
            t1.Completed:Wait()
            ScreenGui.Enabled = false
            GlowFrame.Visible = false
        end
    end

    -- 手机按钮
    if UserInputService.TouchEnabled then
        local MobileBtn = Instance.new("ImageButton")
        MobileBtn.Size = UDim2.new(0, 50, 0, 50)
        MobileBtn.Position = UDim2.new(0, 30, 0.4, 0)
        MobileBtn.BackgroundColor3 = Library.Theme.Background
        MobileBtn.BackgroundTransparency = 0.5
        MobileBtn.Image = "rbxassetid://10734898355" -- SciFi Icon
        MobileBtn.Parent = ScreenGui
        Instance.new("UICorner", MobileBtn).CornerRadius = UDim.new(1, 0)
        
        local mStroke = Instance.new("UIStroke"); mStroke.Color = Library.Theme.Accent; mStroke.Thickness = 2; mStroke.Parent = MobileBtn
        RegisterTheme(mStroke, "Accent")

        MobileBtn.MouseButton1Click:Connect(ToggleUI)
    end
    
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then ToggleUI() end
    end)

    -- 6. 页面布局
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0, 130, 1, -45)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = MainFrame

    local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding = UDim.new(0, 5); TabLayout.Parent = TabContainer
    local TabPad = Instance.new("UIPadding"); TabPad.PaddingTop = UDim.new(0, 10); TabPad.PaddingLeft = UDim.new(0, 10); TabPad.Parent = TabContainer

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -130, 1, -45)
    PageContainer.Position = UDim2.new(0, 130, 0, 45)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    -- 分割线
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(0, 1, 1, -45)
    Div.Position = UDim2.new(0, 130, 0, 45)
    Div.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Div.BackgroundTransparency = 0.9
    Div.BorderSizePixel = 0
    Div.Parent = MainFrame

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = name
        TabBtn.Size = UDim2.new(1, -10, 0, 35)
        TabBtn.BackgroundColor3 = Library.Theme.Accent
        TabBtn.BackgroundTransparency = 1 -- 默认未选中
        TabBtn.TextColor3 = Library.Theme.TextDim
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.Parent = TabContainer
        
        local tCorner = Instance.new("UICorner"); tCorner.CornerRadius = UDim.new(0, 6); tCorner.Parent = TabBtn

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 2
        Page.Parent = PageContainer
        
        local pLayout = Instance.new("UIListLayout"); pLayout.Padding = UDim.new(0, 8); pLayout.Parent = Page
        local pPad = Instance.new("UIPadding"); pPad.PaddingTop = UDim.new(0, 10); pPad.PaddingLeft = UDim.new(0, 10); pPad.PaddingRight = UDim.new(0, 10); pPad.Parent = Page

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            for _,v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _,v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Library.Theme.TextDim}):Play()
                end 
            end
            Page.Visible = true
            -- 选中动画
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundTransparency = 0.85, TextColor3 = Library.Theme.Accent}):Play()
        end)

        local Elements = {}

        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Text = text
            Btn.Size = UDim2.new(1, 0, 0, 38)
            Btn.BackgroundColor3 = Library.Theme.Header
            Btn.BackgroundTransparency = Library.Theme.Transparency - 0.1
            Btn.TextColor3 = Library.Theme.Text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.Parent = Page
            RegisterTheme(Btn, "HeaderBg")
            
            local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 6); bCorner.Parent = Btn
            local bStroke = Instance.new("UIStroke"); bStroke.Color = Library.Theme.Accent; bStroke.Thickness = 1; bStroke.Transparency = 0.8; bStroke.Parent = Btn
            RegisterTheme(bStroke, "Accent")

            Btn.MouseEnter:Connect(function() 
                PlaySound("Hover")
                TweenService:Create(bStroke, TweenInfo.new(0.2), {Transparency = 0}):Play() 
            end)
            Btn.MouseLeave:Connect(function() TweenService:Create(bStroke, TweenInfo.new(0.2), {Transparency = 0.8}):Play() end)

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click", 1.2)
                local ripple = TweenService:Create(Btn, TweenInfo.new(0.1), {TextSize = 12})
                ripple:Play()
                ripple.Completed:Wait()
                TweenService:Create(Btn, TweenInfo.new(0.1), {TextSize = 14}):Play()
                pcall(callback)
            end)
        end

        function Elements:Toggle(text, flag, default, callback)
            local toggled = default or false
            Library.Flags[flag] = toggled

            local Btn = Instance.new("TextButton")
            Btn.Text = ""
            Btn.Size = UDim2.new(1, 0, 0, 38)
            Btn.BackgroundColor3 = Library.Theme.Header
            Btn.BackgroundTransparency = Library.Theme.Transparency - 0.1
            Btn.Parent = Page
            RegisterTheme(Btn, "HeaderBg")
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Library.Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 14
            Label.Parent = Btn

            local Switch = Instance.new("Frame")
            Switch.Size = UDim2.new(0, 40, 0, 20)
            Switch.Position = UDim2.new(1, -50, 0.5, -10)
            Switch.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Switch.Parent = Btn
            Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
            
            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 16, 0, 16)
            Dot.Position = UDim2.new(0, 2, 0.5, -8)
            Dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            Dot.Parent = Switch
            Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

            local function Update(val)
                toggled = val
                Library.Flags[flag] = val
                
                if val then
                    PlaySound("ToggleOn", 1.1)
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Library.Theme.Accent}):Play()
                    TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
                else
                    PlaySound("ToggleOff", 0.9)
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
                    TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end
                if callback then pcall(callback, val) end
            end
            
            -- 初始化
            if default then Update(true) end

            Btn.MouseButton1Click:Connect(function() Update(not toggled) end)
            Library.Flags[flag.."_Update"] = Update
        end

        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min
            Library.Flags[flag] = value

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 50)
            Frame.BackgroundColor3 = Library.Theme.Header
            Frame.BackgroundTransparency = Library.Theme.Transparency - 0.1
            Frame.Parent = Page
            RegisterTheme(Frame, "HeaderBg")
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, 0, 0, 20); Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1; Label.TextColor3 = Library.Theme.Text
            Label.Font = Enum.Font.Gotham; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.TextSize = 14
            Label.Parent = Frame

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Text = tostring(value)
            ValLabel.Size = UDim2.new(0, 50, 0, 20); ValLabel.Position = UDim2.new(1, -60, 0, 5)
            ValLabel.BackgroundTransparency = 1; ValLabel.TextColor3 = Library.Theme.Accent
            ValLabel.Font = Enum.Font.Code; ValLabel.TextSize = 14
            ValLabel.Parent = Frame
            RegisterTheme(ValLabel, "Accent")

            local Bar = Instance.new("TextButton")
            Bar.Text = ""; Bar.Size = UDim2.new(1, -20, 0, 4); Bar.Position = UDim2.new(0, 10, 0, 35)
            Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Bar.Parent = Frame
            Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
            Fill.BackgroundColor3 = Library.Theme.Accent; Fill.BorderSizePixel = 0; Fill.Parent = Bar
            RegisterTheme(Fill, "Accent")
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            local function Set(val)
                val = math.clamp(val, min, max)
                value = val
                Library.Flags[flag] = val
                ValLabel.Text = string.format("%.1f", val) -- 支持小数显示
                Fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
                if callback then pcall(callback, val) end
            end

            local dragging = false
            Bar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true; Set(min+((max-min)*math.clamp((inp.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
            UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
            UserInputService.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then Set(min+((max-min)*math.clamp((inp.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
        end

        return Elements
    end

    -- // 7. 自动注入 Settings 页
    local SetTab = WindowFuncs:Tab("Settings")

    -- 透明度调节
    SetTab:Slider("Transparency", "ThemeTrans", 0, 1, Library.Theme.Transparency, function(v)
        Library.Theme.Transparency = v
        Library:UpdateTheme()
    end)

    -- 主色调调节 (Hue)
    SetTab:Slider("Accent Hue", "ThemeHue", 0, 1, 0.5, function(v)
        Library.Theme.Accent = Color3.fromHSV(v, 1, 1)
        Library:UpdateTheme()
    end)
    
    -- 音效开关
    SetTab:Toggle("UI Sounds", "ThemeSound", true, function(v)
        Library.Theme.SoundEnabled = v
    end)

    SetTab:Button("Save Config", function()
        if writefile then
            writefile(Library.ConfigFolder .. "/config.json", HttpService:JSONEncode(Library.Flags))
            PlaySound("ToggleOn")
        end
    end)
    
    SetTab:Button("Load Config", function()
        if readfile and isfile(Library.ConfigFolder .. "/config.json") then
            local data = HttpService:JSONDecode(readfile(Library.ConfigFolder .. "/config.json"))
            for k,v in pairs(data) do
                if Library.Flags[k.."_Update"] then Library.Flags[k.."_Update"](v) end
            end
            PlaySound("ToggleOn")
        end
    end)

    PlaySound("Open") -- 初始打开音效
    return WindowFuncs
end

return Library
