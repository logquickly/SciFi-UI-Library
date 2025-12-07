--[[
    SCI-FI UI LIBRARY v6.0 (RGB Flow Edition)
    Updates: Rewritten Rainbow Border (True RGB Flow), Circular Picker, Intro SFX
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

-- // 全局配置
Library.Settings = {
    RainbowBorder = true,
    RainbowSpeed = 1, -- 速度倍率
    SoundEnabled = true
}

Library.Theme = {
    Background = Color3.fromRGB(10, 15, 20),
    Header = Color3.fromRGB(20, 25, 35),
    Accent = Color3.fromRGB(0, 255, 215), -- 默认青色
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
    Transparency = 0.2
}

Library.Flags = {}
Library.ThemeObjects = {} 
Library.ConfigFolder = "SciFiConfig"

-- // 预设彩虹序列 (全光谱)
local RainbowSequence = ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
}

-- // 音效系统
local Sounds = {
    Hover = 6895079960,
    Click = 6042053626,
    ToggleOn = 6042053626,
    ToggleOff = 6042053610,
    Intro = 6035688461, -- 独特的载入音
    Open = 6895079853
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
        s.Destroy(s)
    end)
end

-- // 辅助函数
local function GetParent()
    local success, parent = pcall(function() return gethui and gethui() or CoreGui end)
    return (success and parent) and parent or LocalPlayer:WaitForChild("PlayerGui")
end

local function RegisterTheme(obj, type)
    table.insert(Library.ThemeObjects, {Object = obj, Type = type})
end

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
                if obj:IsA("UIStroke") then obj.Color = Library.Theme.Accent 
                elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then obj.TextColor3 = Library.Theme.Accent 
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
    ScreenGui.DisplayOrder = 9999

    PlaySound("Intro", 1.5)

    -- 1. 边框容器 (完全透明，只显示Stroke)
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "GlowBorder"
    GlowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowFrame.Size = UDim2.new(0, 506, 0, 326)
    GlowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowFrame.BackgroundTransparency = 1
    GlowFrame.Parent = ScreenGui

    -- 2. 核心：UIStroke + UIGradient
    local GlowStroke = Instance.new("UIStroke")
    GlowStroke.Thickness = 3
    GlowStroke.Transparency = 0.1
    GlowStroke.Parent = GlowFrame
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 10)
    GlowCorner.Parent = GlowFrame

    local Gradient = Instance.new("UIGradient")
    Gradient.Rotation = 0
    Gradient.Parent = GlowStroke

    -- 3. 主界面
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Library.Theme.Background
    MainFrame.BackgroundTransparency = Library.Theme.Transparency
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    RegisterTheme(MainFrame, "MainBg")

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    -- =========================================================
    -- 🌈 重写的彩虹流光逻辑 🌈
    -- =========================================================
    local rot = 0
    RunService.RenderStepped:Connect(function(dt)
        if not ScreenGui.Parent then return end -- UI被销毁则停止

        if Library.Settings.RainbowBorder then
            -- 1. 彩虹模式：旋转全光谱 Gradient
            rot = rot + (60 * dt * Library.Settings.RainbowSpeed)
            Gradient.Rotation = rot % 360
            Gradient.Color = RainbowSequence
        else
            -- 2. 单色模式：使用 Accent Color + 呼吸效果
            local c = Library.Theme.Accent
            -- 创建一个两端深、中间亮的渐变，增加质感
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, c),
                ColorSequenceKeypoint.new(0.5, Color3.new(math.min(c.R+0.2,1), math.min(c.G+0.2,1), math.min(c.B+0.2,1))), 
                ColorSequenceKeypoint.new(1, c)
            }
            -- 慢速旋转让它看起来像在呼吸，而不是静止
            rot = rot + (10 * dt) 
            Gradient.Rotation = rot % 360
        end
    end)
    -- =========================================================

    -- 4. 标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Library.Theme.Header
    TopBar.BackgroundTransparency = Library.Theme.Transparency - 0.1
    TopBar.Parent = MainFrame
    RegisterTheme(TopBar, "HeaderBg")
    
    local TopTitle = Instance.new("TextLabel")
    TopTitle.Text = string.upper(title)
    TopTitle.Font = Enum.Font.Code
    TopTitle.TextSize = 20
    TopTitle.TextColor3 = Library.Theme.Accent
    TopTitle.Size = UDim2.new(1, -20, 1, 0)
    TopTitle.Position = UDim2.new(0, 20, 0, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    RegisterTheme(TopTitle, "Accent")

    -- 拖动
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            MainFrame.Position = newPos; GlowFrame.Position = newPos
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    -- 5. 手机悬浮球
    local MobileBtn = nil
    if UserInputService.TouchEnabled then
        MobileBtn = Instance.new("ImageButton")
        MobileBtn.Size = UDim2.new(0, 50, 0, 50)
        MobileBtn.Position = UDim2.new(0, 30, 0.4, 0)
        MobileBtn.BackgroundColor3 = Library.Theme.Background
        MobileBtn.BackgroundTransparency = 0.5
        MobileBtn.Image = "rbxassetid://10734898355"
        MobileBtn.Parent = ScreenGui
        Instance.new("UICorner", MobileBtn).CornerRadius = UDim.new(1, 0)
        local ms = Instance.new("UIStroke"); ms.Color = Library.Theme.Accent; ms.Thickness = 2; ms.Parent = MobileBtn
        RegisterTheme(ms, "Accent")
    end

    -- 6. 开关 UI
    local isVisible = true
    local function ToggleUI()
        isVisible = not isVisible
        if isVisible then
            MainFrame.Visible = true; GlowFrame.Visible = true
            PlaySound("Open")
            MainFrame.Size = UDim2.new(0, 0, 0, 20)
            TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
        else
            PlaySound("Open", 0.8)
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 20)})
            t:Play(); t.Completed:Wait()
            MainFrame.Visible = false; GlowFrame.Visible = false
        end
    end
    if MobileBtn then MobileBtn.MouseButton1Click:Connect(ToggleUI) end
    UserInputService.InputBegan:Connect(function(input) if input.KeyCode == Enum.KeyCode.RightControl then ToggleUI() end end)

    -- 7. 布局
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0, 130, 1, -45); TabContainer.Position = UDim2.new(0,0,0,45)
    TabContainer.BackgroundTransparency = 1; TabContainer.Parent = MainFrame
    local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding = UDim.new(0,5); TabLayout.Parent = TabContainer
    local TabPad = Instance.new("UIPadding"); TabPad.PaddingTop = UDim.new(0,10); TabPad.PaddingLeft = UDim.new(0,10); TabPad.Parent = TabContainer

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -130, 1, -45); PageContainer.Position = UDim2.new(0,130,0,45)
    PageContainer.BackgroundTransparency = 1; PageContainer.Parent = MainFrame

    local Div = Instance.new("Frame"); Div.Size = UDim2.new(0, 1, 1, -60); Div.Position = UDim2.new(0, 130, 0, 50)
    Div.BackgroundColor3 = Color3.fromRGB(255,255,255); Div.BackgroundTransparency = 0.9; Div.BorderSizePixel=0; Div.Parent = MainFrame

    -- 开场动画
    task.spawn(function()
        MainFrame.Size = UDim2.new(0, 0, 0, 20)
        TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
    end)

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = name; TabBtn.Size = UDim2.new(1, -10, 0, 32)
        TabBtn.BackgroundColor3 = Library.Theme.Accent; TabBtn.BackgroundTransparency = 1
        TabBtn.TextColor3 = Library.Theme.TextDim; TabBtn.Font = Enum.Font.GothamMedium; TabBtn.TextSize = 13; TabBtn.Parent = TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name.."_Page"; Page.Size = UDim2.new(1,0,1,0); Page.BackgroundTransparency=1
        Page.Visible = false; Page.ScrollBarThickness = 2; Page.Parent = PageContainer
        local PLayout = Instance.new("UIListLayout"); PLayout.Padding = UDim.new(0,8); PLayout.Parent = Page
        local PPad = Instance.new("UIPadding"); PPad.PaddingTop=UDim.new(0,10); PPad.PaddingLeft=UDim.new(0,10); PPad.PaddingRight=UDim.new(0,10); PPad.Parent = Page

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            for _,v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible=false end end
            for _,v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency=1, TextColor3=Library.Theme.TextDim}):Play() end
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundTransparency=0.85, TextColor3=Library.Theme.Accent}):Play()
        end)

        local Elements = {}

        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton"); Btn.Text=text; Btn.Size=UDim2.new(1,0,0,38)
            Btn.BackgroundColor3=Library.Theme.Header; Btn.BackgroundTransparency=Library.Theme.Transparency-0.1
            Btn.TextColor3=Library.Theme.Text; Btn.Font=Enum.Font.Gotham; Btn.TextSize=14; Btn.Parent=Page
            RegisterTheme(Btn, "HeaderBg"); Instance.new("UICorner", Btn).CornerRadius=UDim.new(0,6)
            local Stroke = Instance.new("UIStroke"); Stroke.Color=Library.Theme.Accent; Stroke.Transparency=0.8; Stroke.Parent=Btn
            RegisterTheme(Stroke, "Accent")

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click", 1.2)
                TweenService:Create(Stroke, TweenInfo.new(0.1), {Transparency=0}):Play()
                wait(0.1); TweenService:Create(Stroke, TweenInfo.new(0.5), {Transparency=0.8}):Play()
                pcall(callback)
            end)
        end

        function Elements:Toggle(text, flag, default, callback)
            local toggled = default or false; Library.Flags[flag] = toggled
            local Btn = Instance.new("TextButton"); Btn.Text=""; Btn.Size=UDim2.new(1,0,0,38)
            Btn.BackgroundColor3=Library.Theme.Header; Btn.BackgroundTransparency=Library.Theme.Transparency-0.1; Btn.Parent=Page
            RegisterTheme(Btn, "HeaderBg"); Instance.new("UICorner", Btn).CornerRadius=UDim.new(0,6)
            local Label = Instance.new("TextLabel"); Label.Text=text; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0)
            Label.BackgroundTransparency=1; Label.TextColor3=Library.Theme.Text; Label.Font=Enum.Font.Gotham; Label.TextSize=14; Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Parent=Btn
            local Box = Instance.new("Frame"); Box.Size=UDim2.new(0,20,0,20); Box.Position=UDim2.new(1,-30,0.5,-10)
            Box.BackgroundColor3=toggled and Library.Theme.Accent or Color3.fromRGB(40,40,40); Box.Parent=Btn
            Instance.new("UICorner", Box).CornerRadius=UDim.new(0,4)
            local function Update(val)
                toggled = val; Library.Flags[flag] = val
                if val then PlaySound("ToggleOn"); TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3=Library.Theme.Accent}):Play()
                else PlaySound("ToggleOff"); TweenService:Create(Box, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end
                if callback then pcall(callback, val) end
            end
            Btn.MouseButton1Click:Connect(function() Update(not toggled) end)
            Library.Flags[flag.."_Update"] = Update
        end

        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min; Library.Flags[flag] = value
            local Frame = Instance.new("Frame"); Frame.Size=UDim2.new(1,0,0,50); Frame.BackgroundColor3=Library.Theme.Header; Frame.BackgroundTransparency=Library.Theme.Transparency-0.1; Frame.Parent=Page
            RegisterTheme(Frame, "HeaderBg"); Instance.new("UICorner", Frame).CornerRadius=UDim.new(0,6)
            local Label = Instance.new("TextLabel"); Label.Text=text; Label.Size=UDim2.new(1,0,0,20); Label.Position=UDim2.new(0,10,0,5)
            Label.BackgroundTransparency=1; Label.TextColor3=Library.Theme.Text; Label.Font=Enum.Font.Gotham; Label.TextSize=14; Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Parent=Frame
            local Val = Instance.new("TextLabel"); Val.Text=tostring(value); Val.Size=UDim2.new(0,50,0,20); Val.Position=UDim2.new(1,-60,0,5)
            Val.BackgroundTransparency=1; Val.TextColor3=Library.Theme.Accent; Val.Font=Enum.Font.Code; Val.TextSize=14; Val.Parent=Frame
            RegisterTheme(Val, "Accent")
            local Bar = Instance.new("TextButton"); Bar.Text=""; Bar.Size=UDim2.new(1,-20,0,4); Bar.Position=UDim2.new(0,10,0,35)
            Bar.BackgroundColor3=Color3.fromRGB(40,40,40); Bar.Parent=Frame; Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
            local Fill = Instance.new("Frame"); Fill.Size=UDim2.new((value-min)/(max-min),0,1,0); Fill.BackgroundColor3=Library.Theme.Accent; Fill.BorderSizePixel=0; Fill.Parent=Bar
            RegisterTheme(Fill, "Accent"); Instance.new("UICorner", Fill).CornerRadius=UDim.new(1,0)
            local function Set(v)
                v = math.clamp(v, min, max); value = v; Library.Flags[flag] = v
                Val.Text = string.format("%.1f", v); Fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0)
                if callback then pcall(callback, v) end
            end
            local drag=false
            Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; Set(min+((max-min)*math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
            UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Set(min+((max-min)*math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
        end

        -- 圆形调色盘 (Circular Picker)
        function Elements:ColorPicker(text, flag, default, callback)
            local color = default or Color3.fromRGB(255, 255, 255)
            Library.Flags[flag] = color
            local isOpen = false

            local Frame = Instance.new("Frame"); Frame.Size=UDim2.new(1,0,0,40); Frame.BackgroundColor3=Library.Theme.Header; Frame.BackgroundTransparency=Library.Theme.Transparency-0.1; Frame.Parent=Page; Frame.ClipsDescendants=true
            RegisterTheme(Frame, "HeaderBg"); Instance.new("UICorner", Frame).CornerRadius=UDim.new(0,6)
            
            local Label = Instance.new("TextLabel"); Label.Text=text; Label.Size=UDim2.new(0.6,0,0,40); Label.Position=UDim2.new(0,10,0,0)
            Label.BackgroundTransparency=1; Label.TextColor3=Library.Theme.Text; Label.Font=Enum.Font.Gotham; Label.TextSize=14; Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Parent=Frame
            
            local Preview = Instance.new("TextButton"); Preview.Text=""; Preview.Size=UDim2.new(0,40,0,20); Preview.Position=UDim2.new(1,-50,0,10)
            Preview.BackgroundColor3=color; Preview.Parent=Frame; Instance.new("UICorner", Preview).CornerRadius=UDim.new(0,4)
            
            local Container = Instance.new("Frame"); Container.Size=UDim2.new(1,-20,0,150); Container.Position=UDim2.new(0,10,0,45); Container.BackgroundTransparency=1; Container.Parent=Frame
            
            -- 色轮
            local Wheel = Instance.new("ImageButton"); Wheel.Size=UDim2.new(0,100,0,100); Wheel.Position=UDim2.new(0,0,0,0); Wheel.Image="rbxassetid://6020299385"; Wheel.BackgroundTransparency=1; Wheel.Parent=Container
            local Cursor = Instance.new("ImageLabel"); Cursor.Size=UDim2.new(0,10,0,10); Cursor.Image="rbxassetid://16449174151"; Cursor.BackgroundTransparency=1; Cursor.Parent=Wheel; Cursor.AnchorPoint=Vector2.new(0.5,0.5)

            -- 预设
            local Presets = Instance.new("Frame"); Presets.Size=UDim2.new(0,100,0,100); Presets.Position=UDim2.new(1,-110,0,0); Presets.BackgroundTransparency=1; Presets.Parent=Container
            local PGrid = Instance.new("UIGridLayout"); PGrid.CellSize=UDim2.new(0,30,0,30); PGrid.CellPadding=UDim2.new(0,5,0,5); PGrid.Parent=Presets
            
            local PresetColors = {
                Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
                Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255), Color3.fromRGB(255,0,255),
                Color3.fromRGB(255,128,0), Color3.fromRGB(128,0,255), Color3.fromRGB(255,255,255)
            }

            local function UpdateColor(newCol)
                color = newCol; Library.Flags[flag] = color
                Preview.BackgroundColor3 = color
                if callback then pcall(callback, color) end
            end

            for _, pc in ipairs(PresetColors) do
                local pBtn = Instance.new("TextButton"); pBtn.Text=""; pBtn.BackgroundColor3=pc; pBtn.Parent=Presets
                Instance.new("UICorner", pBtn).CornerRadius=UDim.new(1,0)
                pBtn.MouseButton1Click:Connect(function() UpdateColor(pc) end)
            end

            local dragging=false
            local function UpdateWheel(input)
                local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize/2)
                local vector = Vector2.new(input.Position.X - center.X, input.Position.Y - center.Y)
                local angle = math.atan2(vector.Y, vector.X)
                local dist = math.min(vector.Magnitude, Wheel.AbsoluteSize.X/2)
                Cursor.Position = UDim2.new(0.5 + (math.cos(angle) * dist / Wheel.AbsoluteSize.X), 0, 0.5 + (math.sin(angle) * dist / Wheel.AbsoluteSize.Y), 0)
                local sat = dist / (Wheel.AbsoluteSize.X/2)
                local hue = (math.deg(angle) + 180) / 360
                UpdateColor(Color3.fromHSV(hue, sat, 1))
            end

            Wheel.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; UpdateWheel(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then UpdateWheel(i) end end)

            Preview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                TweenService:Create(Frame, TweenInfo.new(0.3), {Size = isOpen and UDim2.new(1,0,0,160) or UDim2.new(1,0,0,40)}):Play()
            end)
        end

        return Elements
    end

    local SetTab = WindowFuncs:Tab("Settings")

    SetTab:ColorPicker("Accent Color", "ThemeColor", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        Library:UpdateTheme()
    end)
    SetTab:Toggle("Rainbow Border", "RBConfig", true, function(v) Library.Settings.RainbowBorder = v end)
    SetTab:Slider("Border Speed", "RBSpeed", 0.1, 5, 1, function(v) Library.Settings.RainbowSpeed = v end)
    SetTab:Slider("Transparency", "TransConfig", 0, 1, 0.2, function(v) Library.Theme.Transparency = v; Library:UpdateTheme() end)
    SetTab:Toggle("UI Sounds", "SndConfig", true, function(v) Library.Settings.SoundEnabled = v end)
    SetTab:Button("Unload UI", function() ScreenGui:Destroy() end)

    return WindowFuncs
end

return Library
