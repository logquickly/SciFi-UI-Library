--[[
    CYBERPUNK / SCI-FI UI LIBRARY
    Version: 1.0.0
    Author: [你的名字]
    License: MIT
]]

local Library = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- // UI 保护与挂载位置
-- 优先尝试挂载到 CoreGui (防检测/注入器环境)，如果失败则挂载到 PlayerGui (Roblox Studio 环境)
local function GetParent()
    local success, parent = pcall(function()
        return gethui and gethui() or CoreGui
    end)
    if not success or not parent then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

-- // 主题配置
local Theme = {
    Background = Color3.fromRGB(10, 10, 15),
    Header = Color3.fromRGB(20, 20, 25),
    Accent = Color3.fromRGB(0, 255, 215), -- 赛博青
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(120, 120, 120),
    Stroke = Color3.fromRGB(40, 40, 50)
}

function Library:CreateWindow(config)
    local title = config.Name or "Sci-Fi Hub"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = GetParent()

    -- 主窗口
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- 圆角与描边
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.5
    MainStroke.Parent = MainFrame

    -- 标题栏
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Theme.Header
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 6)
    TopCorner.Parent = TopBar
    
    -- 遮盖底部圆角
    local Filler = Instance.new("Frame")
    Filler.Size = UDim2.new(1, 0, 0, 10)
    Filler.Position = UDim2.new(0, 0, 1, -10)
    Filler.BackgroundColor3 = Theme.Header
    Filler.BorderSizePixel = 0
    Filler.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextColor3 = Theme.Accent
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- 拖动功能
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(MainFrame, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end)

    -- 内容容器
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(0, 120, 1, -45)
    TabContainer.Position = UDim2.new(0, 10, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = MainFrame
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer

    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -140, 1, -45)
    PageContainer.Position = UDim2.new(0, 140, 0, 45)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    -- 快捷键隐藏
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local WindowFunctions = {}

    function WindowFunctions:Tab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Text = name
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.BackgroundTransparency = 0.95
        TabButton.TextColor3 = Theme.TextDim
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 13
        TabButton.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.Visible = false
        Page.Parent = PageContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.Parent = Page
        
        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 5)
        PagePadding.PaddingLeft = UDim.new(0, 2)
        PagePadding.Parent = Page

        -- 切换 Tab 逻辑
        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 0.95, TextColor3 = Theme.TextDim}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0.8, TextColor3 = Theme.Accent}):Play()
        end)

        local Elements = {}

        -- 创建按钮
        function Elements:Button(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Text = text
            Btn.Size = UDim2.new(1, -5, 0, 35)
            Btn.BackgroundColor3 = Theme.Header
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14
            Btn.Parent = Page
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = Btn
            
            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Theme.Stroke
            BtnStroke.Thickness = 1
            BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            BtnStroke.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                TweenService:Create(BtnStroke, TweenInfo.new(0.1), {Color = Theme.Accent}):Play()
                wait(0.1)
                TweenService:Create(BtnStroke, TweenInfo.new(0.5), {Color = Theme.Stroke}):Play()
                pcall(callback)
            end)
        end

        -- 创建开关
        function Elements:Toggle(text, default, callback)
            local toggled = default or false
            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Text = ""
            ToggleFrame.Size = UDim2.new(1, -5, 0, 35)
            ToggleFrame.BackgroundColor3 = Theme.Header
            ToggleFrame.Parent = Page
            
            local TCorner = Instance.new("UICorner"); TCorner.CornerRadius = UDim.new(0, 4); TCorner.Parent = ToggleFrame
            
            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 14
            Label.Parent = ToggleFrame
            
            local Status = Instance.new("Frame")
            Status.Size = UDim2.new(0, 20, 0, 20)
            Status.Position = UDim2.new(1, -30, 0.5, -10)
            Status.BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(50, 50, 50)
            Status.Parent = ToggleFrame
            local SCorner = Instance.new("UICorner"); SCorner.CornerRadius = UDim.new(1, 0); SCorner.Parent = Status

            ToggleFrame.MouseButton1Click:Connect(function()
                toggled = not toggled
                local targetColor = toggled and Theme.Accent or Color3.fromRGB(50, 50, 50)
                TweenService:Create(Status, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                pcall(callback, toggled)
            end)
        end

        -- 创建滑块
        function Elements:Slider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, -5, 0, 45)
            SliderFrame.BackgroundColor3 = Theme.Header
            SliderFrame.Parent = Page
            local SCorner = Instance.new("UICorner"); SCorner.CornerRadius = UDim.new(0, 4); SCorner.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Text = text
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.TextColor3 = Theme.Text
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 14
            Label.Parent = SliderFrame
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(default)
            ValueLabel.Size = UDim2.new(0, 30, 0, 20)
            ValueLabel.Position = UDim2.new(1, -40, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.TextColor3 = Theme.Accent
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 14
            ValueLabel.Parent = SliderFrame

            local Bar = Instance.new("TextButton")
            Bar.Text = ""
            Bar.Size = UDim2.new(1, -20, 0, 5)
            Bar.Position = UDim2.new(0, 10, 0, 30)
            Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Bar.Parent = SliderFrame
            local BCorner = Instance.new("UICorner"); BCorner.CornerRadius = UDim.new(1, 0); BCorner.Parent = Bar

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Bar
            local FCorner = Instance.new("UICorner"); FCorner.CornerRadius = UDim.new(1, 0); FCorner.Parent = Fill

            local dragging = false
            local function update(input)
                local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Fill.Size = UDim2.new(pos, 0, 1, 0)
                local val = math.floor(min + ((max - min) * pos))
                ValueLabel.Text = tostring(val)
                pcall(callback, val)
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)
        end

        return Elements
    end

    return WindowFunctions
end

return Library
