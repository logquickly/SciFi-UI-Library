--[[
    SCI-FI UI LIBRARY v4.0 (Ultimate Edition)
    Updates: RGB Picker, Intro Anim, Glass Glow fix, Mobile fix, New Sounds
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

-- // 状态管理
Library.Flags = {}
Library.ThemeObjects = {} 
Library.ConfigFolder = "SciFiConfig"
Library.CurrentConfig = "Default"

-- // 默认主题
Library.Theme = {
    Background = Color3.fromRGB(10, 15, 20),
    Header = Color3.fromRGB(20, 25, 30),
    Accent = Color3.fromRGB(0, 255, 230), -- 默认青色
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
    Transparency = 0.3, -- 默认半透明
    SoundEnabled = true
}

-- // 新版科幻音效 ID
local Sounds = {
    Hover = 6895079960,     -- 轻微的电子滴声
    Click = 6042053626,     -- 清脆的点击
    ToggleOn = 6042053626,  
    ToggleOff = 6042053610, -- 低沉点击
    Intro = 6895079853,     -- 系统启动音效
    Notification = 6542053626
}

local function PlaySound(name, pitch, vol)
    if not Library.Theme.SoundEnabled then return end
    local id = Sounds[name]
    if not id then return end
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. id
        s.Volume = vol or 0.5
        s.Pitch = pitch or 1
        s.Parent = SoundService
        s.PlayOnRemove = true
        s.Destroy(s)
    end)
end

-- // 辅助：获取父级
local function GetParent()
    local success, parent = pcall(function() return gethui and gethui() or CoreGui end)
    return (success and parent) and parent or LocalPlayer:WaitForChild("PlayerGui")
end

-- // 主题系统
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
            elseif type == "AccentGradient" then
                 -- 渐变色更新
                obj.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Library.Theme.Accent),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255 - Library.Theme.Accent.R*255, 255 - Library.Theme.Accent.G*255, 255 - Library.Theme.Accent.B*255)),
                    ColorSequenceKeypoint.new(1, Library.Theme.Accent)
                }
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
    ScreenGui.DisplayOrder = 999

    -- 1. 发光边框层 (Glow Frame) - 修复为透明背景
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "GlowFrame"
    GlowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowFrame.Size = UDim2.new(0, 504, 0, 324)
    GlowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowFrame.BackgroundColor3 = Color3.new(0,0,0)
    GlowFrame.BackgroundTransparency = 1 -- 关键修复：完全透明
    GlowFrame.Parent = ScreenGui

    local GlowStroke = Instance.new("UIStroke")
    GlowStroke.Thickness = 3
    GlowStroke.Transparency = 0.3
    GlowStroke.Parent = GlowFrame
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 10)
    GlowCorner.Parent = GlowFrame

    local Gradient = Instance.new("UIGradient")
    Gradient.Rotation = 45
    Gradient.Parent = GlowStroke -- 渐变只作用于边框
    RegisterTheme(Gradient, "AccentGradient")

    -- 2. 主界面
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

    -- 动态呼吸灯效果
    task.spawn(function()
        local rot = 0
        while ScreenGui.Parent do
            rot = rot + 1
            Gradient.Rotation = rot % 360
            task.wait(0.02)
        end
    end)

    -- 3. 标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Library.Theme.Header
    TopBar.BackgroundTransparency = Library.Theme.Transparency - 0.1
    TopBar.Parent = MainFrame
    RegisterTheme(TopBar, "HeaderBg")
    
    local TopTitle = Instance.new("TextLabel")
    TopTitle.Text = title
    TopTitle.Font = Enum.Font.Code
    TopTitle.TextSize = 20
    TopTitle.TextColor3 = Library.Theme.Accent
    TopTitle.Size = UDim2.new(1, -20, 1, 0)
    TopTitle.Position = UDim2.new(0, 15, 0, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    RegisterTheme(TopTitle, "Accent")

    -- 拖动逻辑
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
            MainFrame.Position = newPos
            GlowFrame.Position = newPos -- 边框跟随
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    -- 4. 手机按钮 (独立于 MainFrame)
    local MobileToggle = nil
    if UserInputService.TouchEnabled then
        MobileToggle = Instance.new("ImageButton")
        MobileToggle.Name = "MobileToggle"
        MobileToggle.Size = UDim2.new(0, 50, 0, 50)
        MobileToggle.Position = UDim2.new(0, 30, 0.3, 0)
        MobileToggle.BackgroundColor3 = Library.Theme.Background
        MobileToggle.BackgroundTransparency = 0.5
        MobileToggle.Image = "rbxassetid://10709791437"
        MobileToggle.Parent = ScreenGui -- 放在 ScreenGui 下，而不是 MainFrame
        Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(1, 0)
        
        local mStroke = Instance.new("UIStroke")
        mStroke.Color = Library.Theme.Accent
        mStroke.Thickness = 2
        mStroke.Parent = MobileToggle
        RegisterTheme(mStroke, "Accent")
    end

    -- 5. 显示/隐藏逻辑 (修复按钮消失问题)
    local isVisible = true
    local function ToggleUI()
        isVisible = not isVisible
        if isVisible then
            MainFrame.Visible = true
            GlowFrame.Visible = true
            PlaySound("Intro", 1.2)
            -- 展开动画
            MainFrame.Size = UDim2.new(0, 0, 0, 320)
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
        else
            PlaySound("ToggleOff")
            local t = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 320)})
            t:Play()
            t.Completed:Wait()
            MainFrame.Visible = false
            GlowFrame.Visible = false
        end
    end

    if MobileToggle then MobileToggle.MouseButton1Click:Connect(ToggleUI) end
    UserInputService.InputBegan:Connect(function(input) if input.KeyCode == Enum.KeyCode.RightControl then ToggleUI() end end)

    -- 6. 内容区域
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0, 130, 1, -45); TabContainer.Position = UDim2.new(0,0,0,45)
    TabContainer.BackgroundTransparency = 1; TabContainer.Parent = MainFrame
    local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding = UDim.new(0,5); TabLayout.Parent = TabContainer
    local TabPad = Instance.new("UIPadding"); TabPad.PaddingTop = UDim.new(0,10); TabPad.PaddingLeft = UDim.new(0,10); TabPad.Parent = TabContainer

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -130, 1, -45); PageContainer.Position = UDim2.new(0,130,0,45)
    PageContainer.BackgroundTransparency = 1; PageContainer.Parent = MainFrame

    -- 分隔线
    local Div = Instance.new("Frame"); Div.Size = UDim2.new(0, 1, 1, -60); Div.Position = UDim2.new(0, 130, 0, 52)
    Div.BackgroundColor3 = Color3.fromRGB(255,255,255); Div.BackgroundTransparency = 0.9; Div.BorderSizePixel=0; Div.Parent = MainFrame

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = name
        TabBtn.Size = UDim2.new(1, -10, 0, 32)
        TabBtn.BackgroundColor3 = Library.Theme.Accent
        TabBtn.BackgroundTransparency = 1
        TabBtn.TextColor3 = Library.Theme.TextDim
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.Parent = TabContainer
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
            local Btn = Instance.new("TextButton")
            Btn.Text = text; Btn.Size = UDim2.new(1,0,0,38)
            Btn.BackgroundColor3 = Library.Theme.Header; Btn.BackgroundTransparency = Library.Theme.Transparency-0.1
            Btn.TextColor3 = Library.Theme.Text; Btn.Font = Enum.Font.Gotham; Btn.TextSize = 14; Btn.Parent = Page
            RegisterTheme(Btn, "HeaderBg")
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
            local Stroke = Instance.new("UIStroke"); Stroke.Color=Library.Theme.Accent; Stroke.Transparency=0.8; Stroke.Parent=Btn
            RegisterTheme(Stroke, "Accent")

            Btn.MouseButton1Click:Connect(function()
                PlaySound("Click", 1.2)
                TweenService:Create(Stroke, TweenInfo.new(0.1), {Transparency=0}):Play()
                wait(0.1)
                TweenService:Create(Stroke, TweenInfo.new(0.5), {Transparency=0.8}):Play()
                pcall(callback)
            end)
        end

        function Elements:Toggle(text, flag, default, callback)
            local toggled = default or false
            Library.Flags[flag] = toggled
            
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
                Val.Text = string.format("%.1f", v)
                Fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0)
                if callback then pcall(callback, v) end
            end
            
            local dragging=false
            Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; Set(min+((max-min)*math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Set(min+((max-min)*math.clamp((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,0,1))) end end)
        end

        -- // 新功能：RGB 调色盘
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
            
            -- 展开后的容器
            local Pickers = Instance.new("Frame"); Pickers.Size=UDim2.new(1,-20,0,100); Pickers.Position=UDim2.new(0,10,0,45); Pickers.BackgroundTransparency=1; Pickers.Parent=Frame

            local function UpdateColor(newCol)
                color = newCol; Library.Flags[flag] = color
                Preview.BackgroundColor3 = color
                if callback then pcall(callback, color) end
            end

            -- 创建 RGB 滑块辅助函数
            local function CreateRGB(type, yPos)
                local Bar = Instance.new("TextButton"); Bar.Text=""; Bar.Size=UDim2.new(1,0,0,4); Bar.Position=UDim2.new(0,0,0,yPos)
                Bar.BackgroundColor3=Color3.fromRGB(40,40,40); Bar.Parent=Pickers; Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
                local Fill = Instance.new("Frame"); Fill.Size=UDim2.new(type=="R" and color.R or (type=="G" and color.G or color.B),0,1,0)
                Fill.BackgroundColor3=type=="R" and Color3.new(1,0,0) or (type=="G" and Color3.new(0,1,0) or Color3.new(0,0,1)); Fill.BorderSizePixel=0; Fill.Parent=Bar
                
                local drag=false
                local function Set(v)
                    v=math.clamp(v,0,1); Fill.Size=UDim2.new(v,0,1,0)
                    local r,g,b = (type=="R" and v or color.R), (type=="G" and v or color.G), (type=="B" and v or color.B)
                    UpdateColor(Color3.new(r,g,b))
                end
                Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; Set((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X) end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
                UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Set((i.Position.X-Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X) end end)
            end
            
            CreateRGB("R", 10); CreateRGB("G", 40); CreateRGB("B", 70)

            Preview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                TweenService:Create(Frame, TweenInfo.new(0.3), {Size = isOpen and UDim2.new(1,0,0,130) or UDim2.new(1,0,0,40)}):Play()
            end)
        end

        return Elements
    end

    -- // 7. Settings
    local SetTab = WindowFuncs:Tab("Settings")

    SetTab:Slider("Transparency", "ConfigTrans", 0, 1, Library.Theme.Transparency, function(v)
        Library.Theme.Transparency = v
        Library:UpdateTheme()
    end)
    
    -- RGB 调色盘
    SetTab:ColorPicker("Theme Color", "ConfigColor", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        Library:UpdateTheme()
        -- 更新渐变色
        if Gradient then 
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, c),
                ColorSequenceKeypoint.new(1, c)
            } 
        end
    end)

    SetTab:Toggle("UI Sounds", "ConfigSound", true, function(v) Library.Theme.SoundEnabled = v end)

    SetTab:Button("Save Config", function()
        if writefile then 
            writefile(Library.ConfigFolder.."/config.json", HttpService:JSONEncode({
                Color = {R=Library.Theme.Accent.R, G=Library.Theme.Accent.G, B=Library.Theme.Accent.B},
                Trans = Library.Theme.Transparency
            }))
            PlaySound("ToggleOn")
        end
    end)

    -- // 启动动画
    task.spawn(function()
        PlaySound("Intro", 1)
        MainFrame.Visible = true
        GlowFrame.Visible = true
        MainFrame.Size = UDim2.new(0,0,0,20) -- 初始状态扁平
        MainFrame.BackgroundTransparency = 1
        
        -- 阶段1: 横向展开
        local t1 = TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 20), BackgroundTransparency = 0.5})
        t1:Play(); t1.Completed:Wait()
        
        -- 阶段2: 纵向展开
        local t2 = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320), BackgroundTransparency = Library.Theme.Transparency})
        t2:Play()
    end)

    return WindowFuncs
end

return Library
