--[[
    CYBERPUNK UI LIBRARY v2.0 (Mobile & Config Support)
    Author: logquickly (AI Assistant)
    License: MIT
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- // 状态管理
Library.Flags = {}      -- 存储所有组件的值
Library.ConfigFolder = "SciFiConfig" -- 配置文件夹名称
Library.CurrentConfig = "Default"

-- // UI 挂载检测
local function GetParent()
    local success, parent = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if not success or not parent then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

-- // 检查是否为手机
local isMobile = UserInputService.TouchEnabled

-- // 主题配置
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Header = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(0, 255, 215),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
}

function Library:CreateWindow(config)
    local title = config.Name or "Sci-Fi Hub"
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetParent()

    -- 1. 渐变发光背景 (用于模拟边框)
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "GlowBorder"
    GlowFrame.Size = UDim2.new(0, 504, 0, 324) -- 比主窗口稍大
    GlowFrame.Position = UDim2.new(0.5, -252, 0.5, -162)
    GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GlowFrame.BorderSizePixel = 0
    GlowFrame.Parent = ScreenGui

    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 8)
    GlowCorner.Parent = GlowFrame

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 215)), -- 青色
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 0, 255)), -- 紫色
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 215)) -- 青色
    }
    Gradient.Rotation = 45
    Gradient.Parent = GlowFrame

    -- 2. 主窗口
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160) -- 居中对齐 GlowFrame
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame

    -- 3. 渐变动画循环
    local gradientSpeed = 1
    local isRainbow = false
    local rotation = 0
    
    RunService.RenderStepped:Connect(function(dt)
        if ScreenGui.Enabled then
            rotation = rotation + (gradientSpeed * 60 * dt)
            Gradient.Rotation = rotation % 360
            
            if isRainbow then
                local hue = (tick() % 5) / 5
                local color = Color3.fromHSV(hue, 1, 1)
                Gradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, color),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV((hue + 0.5) % 1, 1, 1))
                }
            end
        end
    end)

    -- 4. 标题栏与拖动
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Theme.Header
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 6)
    
    -- 遮挡底部圆角
    local Filler = Instance.new("Frame")
    Filler.Size = UDim2.new(1, 0, 0, 10); Filler.Position = UDim2.new(0,0,1,-10)
    Filler.BackgroundColor3 = Theme.Header; Filler.BorderSizePixel=0; Filler.Parent=TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.Code
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- 拖动逻辑 (兼容手机)
    local dragging, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        MainFrame.Position = newPos
        GlowFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - 2, newPos.Y.Scale, newPos.Y.Offset - 2)
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    -- 5. 手机端打开/关闭按钮
    if isMobile then
        local ToggleBtn = Instance.new("ImageButton")
        ToggleBtn.Name = "MobileToggle"
        ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
        ToggleBtn.Position = UDim2.new(0, 50, 0.2, 0) -- 屏幕左侧
        ToggleBtn.BackgroundColor3 = Theme.Background
        ToggleBtn.Image = "rbxassetid://10709791437" -- 类似于菜单的图标
        ToggleBtn.Parent = ScreenGui
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(1, 0) -- 圆形
        ToggleCorner.Parent = ToggleBtn
        
        local ToggleStroke = Instance.new("UIStroke")
        ToggleStroke.Color = Theme.Accent
        ToggleStroke.Thickness = 2
        ToggleStroke.Parent = ToggleBtn
        
        -- 按钮也可拖动
        local tDragging, tDragStart, tStartPos
        ToggleBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                tDragging = true; tDragStart = input.Position; tStartPos = ToggleBtn.Position
            end
        end)
        ToggleBtn.InputChanged:Connect(function(input)
            if tDragging and input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - tDragStart
                ToggleBtn.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y)
            end
        end)
        ToggleBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then 
                tDragging = false 
                -- 简单的点击判定 (如果移动很小则视为点击)
                if (input.Position - tDragStart).Magnitude < 10 then
                    MainFrame.Visible = not MainFrame.Visible
                    GlowFrame.Visible = MainFrame.Visible
                end
            end
        end)
    end

    -- 键盘控制隐藏
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            MainFrame.Visible = not MainFrame.Visible
            GlowFrame.Visible = MainFrame.Visible
        end
    end)

    -- 6. 内容区域
    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(0, 120, 1, -50); TabScroll.Position = UDim2.new(0,10,0,45)
    TabScroll.BackgroundTransparency=1; TabScroll.ScrollBarThickness=0; TabScroll.Parent=MainFrame
    local TabLayout = Instance.new("UIListLayout"); TabLayout.Padding=UDim.new(0,5); TabLayout.Parent=TabScroll

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -140, 1, -50); PageContainer.Position = UDim2.new(0,140,0,45)
    PageContainer.BackgroundTransparency=1; PageContainer.Parent=MainFrame

    local WindowFuncs = {}

    function WindowFuncs:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = name
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = Theme.Header
        TabBtn.TextColor3 = Theme.TextDim
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.Parent = TabScroll
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 2
        Page.Parent = PageContainer
        
        local PageLayout = Instance.new("UIListLayout"); PageLayout.Padding = UDim.new(0,6); PageLayout.Parent=Page
        local PagePad = Instance.new("UIPadding"); PagePad.PaddingTop=UDim.new(0,5); PagePad.PaddingLeft=UDim.new(0,2); PagePad.Parent=Page

        TabBtn.MouseButton1Click:Connect(function()
            for _,v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible=false end end
            for _,v in pairs(TabScroll:GetChildren()) do if v:IsA("TextButton") then 
                TweenService:Create(v, TweenInfo.new(0.3), {TextColor3=Theme.TextDim, BackgroundTransparency=0}):Play()
            end end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3=Theme.Accent, BackgroundTransparency=0.8}):Play()
        end)

        local Elements = {}

        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Text = text
            Btn.Size = UDim2.new(1, -5, 0, 36)
            Btn.BackgroundColor3 = Theme.Header
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.Parent = Page
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
            
            Btn.MouseButton1Click:Connect(function()
                local t = TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3=Theme.Accent, TextColor3=Theme.Background})
                t:Play(); t.Completed:Wait()
                TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3=Theme.Header, TextColor3=Theme.Text}):Play()
                pcall(callback)
            end)
        end

        function Elements:Toggle(text, flag, default, callback)
            local toggled = default or false
            Library.Flags[flag] = toggled -- 保存到全局Flag
            
            local Btn = Instance.new("TextButton")
            Btn.Text = ""
            Btn.Size = UDim2.new(1, -5, 0, 36)
            Btn.BackgroundColor3 = Theme.Header
            Btn.Parent = Page
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 14
            Label.Parent = Btn

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 20, 0, 20)
            Indicator.Position = UDim2.new(1, -30, 0.5, -10)
            Indicator.BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(50,50,50)
            Indicator.Parent = Btn
            Instance.new("UICorner", Indicator).CornerRadius = UDim.new(0, 4)

            local function UpdateState(val)
                toggled = val
                Library.Flags[flag] = val
                TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = val and Theme.Accent or Color3.fromRGB(50,50,50)}):Play()
                if callback then pcall(callback, val) end
            end

            Btn.MouseButton1Click:Connect(function() UpdateState(not toggled) end)
            
            -- 用于加载配置时更新UI
            Library.Flags[flag.."_Update"] = UpdateState
        end

        function Elements:Slider(text, flag, min, max, default, callback)
            local value = default or min
            Library.Flags[flag] = value

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -5, 0, 45)
            Frame.BackgroundColor3 = Theme.Header
            Frame.Parent = Page
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)

            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, 0, 0, 20); Label.Position=UDim2.new(0,10,0,5)
            Label.BackgroundTransparency=1; Label.TextColor3=Theme.Text
            Label.Font=Enum.Font.Gotham; Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=14
            Label.Parent = Frame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(value)
            ValueLabel.Size = UDim2.new(0,40,0,20); ValueLabel.Position=UDim2.new(1,-50,0,5)
            ValueLabel.BackgroundTransparency=1; ValueLabel.TextColor3=Theme.Accent
            ValueLabel.Font=Enum.Font.Code; ValueLabel.TextSize=14
            ValueLabel.Parent = Frame

            local SlideBg = Instance.new("TextButton")
            SlideBg.Text=""; SlideBg.Size=UDim2.new(1,-20,0,6); SlideBg.Position=UDim2.new(0,10,0,30)
            SlideBg.BackgroundColor3=Color3.fromRGB(40,40,40); SlideBg.Parent=Frame
            Instance.new("UICorner", SlideBg).CornerRadius=UDim.new(1,0)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value-min)/(max-min), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent; Fill.BorderSizePixel=0; Fill.Parent=SlideBg
            Instance.new("UICorner", Fill).CornerRadius=UDim.new(1,0)

            local function SetValue(val)
                val = math.clamp(val, min, max)
                value = val
                Library.Flags[flag] = val
                ValueLabel.Text = tostring(math.floor(val))
                Fill.Size = UDim2.new((val-min)/(max-min), 0, 1, 0)
                if callback then pcall(callback, val) end
            end

            local dragging = false
            SlideBg.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    dragging = true
                    local pos = math.clamp((input.Position.X - SlideBg.AbsolutePosition.X) / SlideBg.AbsoluteSize.X, 0, 1)
                    SetValue(min + ((max-min)*pos))
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                    local pos = math.clamp((input.Position.X - SlideBg.AbsolutePosition.X) / SlideBg.AbsoluteSize.X, 0, 1)
                    SetValue(min + ((max-min)*pos))
                end
            end)
            
            Library.Flags[flag.."_Update"] = SetValue
        end

        return Elements
    end

    -- // 7. 自动注入 Settings 标签页
    local SettingsTab = WindowFuncs:Tab("Settings")
    
    SettingsTab:Button("Save Config", function()
        if writefile then
            local json = HttpService:JSONEncode(Library.Flags)
            writefile(Library.ConfigFolder .. "/" .. Library.CurrentConfig .. ".json", json)
            print("Config saved!")
        else
            print("Save Config (Not Supported in Studio):", HttpService:JSONEncode(Library.Flags))
        end
    end)
    
    SettingsTab:Button("Load Config", function()
        if readfile and isfile and isfile(Library.ConfigFolder .. "/" .. Library.CurrentConfig .. ".json") then
            local json = readfile(Library.ConfigFolder .. "/" .. Library.CurrentConfig .. ".json")
            local data = HttpService:JSONDecode(json)
            for flag, value in pairs(data) do
                if Library.Flags[flag.."_Update"] then
                    Library.Flags[flag.."_Update"](value) -- 更新UI和回调
                end
            end
            print("Config loaded!")
        else
            print("Load Config: No file found or not supported.")
        end
    end)

    SettingsTab:Slider("Border Speed", "GradientSpeed", 0, 10, 1, function(v)
        gradientSpeed = v
    end)

    SettingsTab:Slider("Border Rotation", "GradientRot", 0, 360, 45, function(v)
        if gradientSpeed == 0 then -- 如果速度为0，允许手动设置角度
            rotation = v
            Gradient.Rotation = v
        end
    end)

    SettingsTab:Toggle("Rainbow Border", "RainbowMode", false, function(v)
        isRainbow = v
        if not v then
            -- 恢复默认渐变
            Gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 215)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 215))
            }
        end
    end)

    -- 如果有 writefile，确保文件夹存在
    if makefolder and not isfolder(Library.ConfigFolder) then
        makefolder(Library.ConfigFolder)
    end

    return WindowFuncs
end

return Library
