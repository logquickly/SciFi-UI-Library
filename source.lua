--[[
    NEON-NEXUS: UNIVERSAL SCI-FI SCRIPT HUB
    Version: 2.0 (Stable / Config Fixed / Mobile Ready)
    
    [ Instructions ]
    1. Copy all code.
    2. Paste into your executor (Synapse, KRNL, Fluxus, Delta, etc.).
    3. Execute.
    
    [ Features ]
    - Advanced OOP UI Library
    - Auto-Save/Load Configuration System
    - Rainbow Border & Text logic
    - High-Performance ESP Engine
    - Mobile Support (Draggable Toggle Button)
]]

--// SERVICES //--
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// EXPLOIT COMPATIBILITY //--
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local writefile = writefile or function(...) end 
local readfile = readfile or function(...) end
local isfolder = isfolder or function(...) return false end
local makefolder = makefolder or function(...) end
local listfiles = listfiles or function(...) return {} end

--// PROTECTION //--
local function ProtectGui(gui)
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = CoreGui
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = CoreGui
    end
end

--// UTILITIES //--
local function RandomString(len)
    local ret = ""
    for i = 1, len do ret = ret .. string.char(math.random(97, 122)) end
    return ret
end

local function PlaySound(id, vol)
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = vol or 1
        s.Parent = game:GetService("SoundService")
        s.PlayOnRemove = true
        s:Destroy()
    end)
end

--// SOUND IDS //--
local Sounds = {
    Click = "rbxassetid://6895079853",
    Hover = "rbxassetid://6895076301",
    Load = "rbxassetid://6326651859",
    ConfigLoad = "rbxassetid://4612376169",
}

--=============================================================================
--[[ 
    LIBRARY CORE 
    (The Engine)
]]
--=============================================================================

local Library = {
    Flags = {},
    Items = {}, -- Registry for updating UI from Config
    Theme = {
        MainColor = Color3.fromRGB(0, 255, 255),
        SecondaryColor = Color3.fromRGB(20, 20, 25),
        BackgroundColor = Color3.fromRGB(10, 10, 15),
        TextColor = Color3.fromRGB(240, 240, 240),
        Transparency = 0.1,
        Rainbow = false
    },
    Folder = "NeonNexusData"
}

-- Global Rainbow Loop
local RainbowColor = Color3.new(1,0,0)
RunService.Heartbeat:Connect(function()
    RainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
    if Library.Theme.Rainbow then
        Library.Theme.MainColor = RainbowColor
    end
end)

function Library:CreateWindow(options)
    local Name = options.Name or "NEON NEXUS"
    
    -- Cleanup Old GUI
    for _, v in pairs(CoreGui:GetChildren()) do
        if v.Name == "NeonNexus_UI" then v:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeonNexus_UI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ProtectGui(ScreenGui)

    -- Mobile Toggle Button
    if UserInputService.TouchEnabled then
        local MobBtn = Instance.new("TextButton")
        MobBtn.Name = "MobileToggle"
        MobBtn.Parent = ScreenGui
        MobBtn.BackgroundColor3 = Library.Theme.SecondaryColor
        MobBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
        MobBtn.Size = UDim2.new(0, 50, 0, 50)
        MobBtn.Text = ""
        
        local MobCorner = Instance.new("UICorner")
        MobCorner.CornerRadius = UDim.new(1, 0)
        MobCorner.Parent = MobBtn
        
        local MobStroke = Instance.new("UIStroke")
        MobStroke.Parent = MobBtn
        MobStroke.Color = Library.Theme.MainColor
        MobStroke.Thickness = 2
        
        local Icon = Instance.new("ImageLabel")
        Icon.Parent = MobBtn
        Icon.Image = "rbxassetid://3926305904" -- Menu Icon
        Icon.Size = UDim2.new(0.6, 0, 0.6, 0)
        Icon.Position = UDim2.new(0.2, 0, 0.2, 0)
        Icon.BackgroundTransparency = 1
        Icon.ImageColor3 = Color3.new(1,1,1)

        -- Mobile Drag Logic
        local dragging, dragInput, dragStart, startPos
        MobBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = MobBtn.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        MobBtn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                MobBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        RunService.Heartbeat:Connect(function()
            if Library.Theme.Rainbow then MobStroke.Color = RainbowColor else MobStroke.Color = Library.Theme.MainColor end
        end)
        
        MobBtn.MouseButton1Click:Connect(function()
            Library.Hidden = not Library.Hidden
            local Main = ScreenGui:FindFirstChild("MainFrame")
            if Main then
                Main.Visible = not Library.Hidden
            end
        end)
    end

    -- Main Container
    local MainFrame = Instance.new("CanvasGroup")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Library.Theme.BackgroundColor
    MainFrame.BackgroundTransparency = Library.Theme.Transparency
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.GroupTransparency = 1 -- Start Hidden for animation
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame
    
    -- Rainbow Border
    local BorderFrame = Instance.new("Frame")
    BorderFrame.Parent = MainFrame
    BorderFrame.BackgroundTransparency = 1
    BorderFrame.Size = UDim2.new(1, 0, 1, 0)
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Parent = BorderFrame
    MainStroke.Color = Library.Theme.MainColor
    MainStroke.Thickness = 2
    
    RunService.Heartbeat:Connect(function()
        if Library.Theme.Rainbow then MainStroke.Color = RainbowColor else MainStroke.Color = Library.Theme.MainColor end
        MainFrame.BackgroundTransparency = Library.Theme.Transparency
    end)
    
    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Library.Theme.SecondaryColor
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BorderSizePixel = 0
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 6)
    SidebarCorner.Parent = Sidebar
    
    local SidebarFix = Instance.new("Frame") -- Makes right side flat
    SidebarFix.Parent = Sidebar
    SidebarFix.BackgroundColor3 = Library.Theme.SecondaryColor
    SidebarFix.BorderSizePixel = 0
    SidebarFix.Position = UDim2.new(1, -10, 0, 0)
    SidebarFix.Size = UDim2.new(0, 10, 1, 0)
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Parent = Sidebar
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 20)
    Title.Size = UDim2.new(0, 130, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = Name
    Title.TextColor3 = Library.Theme.TextColor
    Title.TextSize = 20
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Tabs Container
    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Parent = Sidebar
    TabScroll.BackgroundTransparency = 1
    TabScroll.Position = UDim2.new(0, 0, 0, 70)
    TabScroll.Size = UDim2.new(1, 0, 1, -80)
    TabScroll.ScrollBarThickness = 0
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Parent = TabScroll
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 5)

    -- Pages Container
    local Pages = Instance.new("Frame")
    Pages.Parent = MainFrame
    Pages.BackgroundTransparency = 1
    Pages.Position = UDim2.new(0, 170, 0, 10)
    Pages.Size = UDim2.new(1, -180, 1, -20)

    -- PC Drag Logic
    local dragFrame = Instance.new("Frame")
    dragFrame.Parent = Sidebar
    dragFrame.BackgroundTransparency = 1
    dragFrame.Size = UDim2.new(1, 0, 0, 70)
    
    local dragging, dragInput, dragStart, startPos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(MainFrame, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end)
    
    -- Toggle Key (Right Control)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
            Library.Hidden = not Library.Hidden
            MainFrame.Visible = not Library.Hidden
        end
    end)

    -- Intro Animation
    if options.IntroEnabled then
        PlaySound(Sounds.Load)
        local IntroFrame = Instance.new("Frame")
        IntroFrame.Parent = ScreenGui
        IntroFrame.BackgroundColor3 = Color3.fromRGB(5,5,5)
        IntroFrame.Size = UDim2.new(1,0,1,0)
        IntroFrame.ZIndex = 999
        
        local IntroText = Instance.new("TextLabel")
        IntroText.Parent = IntroFrame
        IntroText.Size = UDim2.new(1,0,1,0)
        IntroText.BackgroundTransparency = 1
        IntroText.TextColor3 = Library.Theme.MainColor
        IntroText.TextSize = 24
        IntroText.Font = Enum.Font.Code
        IntroText.Text = ""
        
        local txt = "SYSTEM_INITIALIZED // " .. Name
        for i = 1, #txt do
            IntroText.Text = txt:sub(1, i)
            PlaySound(Sounds.Click, 2)
            task.wait(0.04)
        end
        
        task.wait(0.4)
        TweenService:Create(IntroFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(IntroText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
        task.wait(0.5)
        IntroFrame:Destroy()
    else
        MainFrame.GroupTransparency = 0
    end

    local Window = {}
    local FirstTab = true

    function Window:Tab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = TabScroll
        TabBtn.BackgroundTransparency = 1
        TabBtn.Size = UDim2.new(1, 0, 0, 35)
        TabBtn.Text = name
        TabBtn.Font = Enum.Font.Gotham
        TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabBtn.TextSize = 14
        
        local Indicator = Instance.new("Frame")
        Indicator.Parent = TabBtn
        Indicator.BackgroundColor3 = Library.Theme.MainColor
        Indicator.Position = UDim2.new(0, 0, 0, 8)
        Indicator.Size = UDim2.new(0, 3, 0, 19)
        Indicator.Transparency = 1
        
        RunService.Heartbeat:Connect(function() if Library.Theme.Rainbow then Indicator.BackgroundColor3 = RainbowColor else Indicator.BackgroundColor3 = Library.Theme.MainColor end end)
        
        local PageScroll = Instance.new("ScrollingFrame")
        PageScroll.Parent = Pages
        PageScroll.BackgroundTransparency = 1
        PageScroll.Size = UDim2.new(1, 0, 1, 0)
        PageScroll.ScrollBarThickness = 2
        PageScroll.Visible = false
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = PageScroll
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 5)
        
        local PagePad = Instance.new("UIPadding")
        PagePad.Parent = PageScroll
        PagePad.PaddingTop = UDim.new(0, 5)
        PagePad.PaddingLeft = UDim.new(0, 5)

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            for _, v in pairs(Pages:GetChildren()) do v.Visible = false end
            for _, v in pairs(TabScroll:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150,150,150)}):Play()
                    TweenService:Create(v.Frame, TweenInfo.new(0.3), {Transparency = 1}):Play()
                end
            end
            
            PageScroll.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
            TweenService:Create(Indicator, TweenInfo.new(0.3), {Transparency = 0}):Play()
        end)
        
        if FirstTab then
            FirstTab = false
            PageScroll.Visible = true
            TabBtn.TextColor3 = Color3.fromRGB(255,255,255)
            Indicator.Transparency = 0
        end

        local Elements = {}
        
        function Elements:Section(text)
            local SecFrame = Instance.new("Frame")
            SecFrame.Parent = PageScroll
            SecFrame.BackgroundTransparency = 1
            SecFrame.Size = UDim2.new(1, -10, 0, 25)
            
            local SecLabel = Instance.new("TextLabel")
            SecLabel.Parent = SecFrame
            SecLabel.BackgroundTransparency = 1
            SecLabel.Size = UDim2.new(1, 0, 1, 0)
            SecLabel.Text = text
            SecLabel.Font = Enum.Font.GothamBold
            SecLabel.TextSize = 14
            SecLabel.TextColor3 = Library.Theme.MainColor
            SecLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            RunService.Heartbeat:Connect(function() if Library.Theme.Rainbow then SecLabel.TextColor3 = RainbowColor else SecLabel.TextColor3 = Library.Theme.MainColor end end)
        end

        function Elements:Button(text, callback)
            callback = callback or function() end
            local BtnFrame = Instance.new("Frame")
            BtnFrame.Parent = PageScroll
            BtnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            BtnFrame.Size = UDim2.new(1, -10, 0, 35)
            
            local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 4); Corner.Parent = BtnFrame
            local Stroke = Instance.new("UIStroke"); Stroke.Parent = BtnFrame; Stroke.Color = Library.Theme.MainColor; Stroke.Transparency = 0.5; Stroke.Thickness = 1
            
            local Btn = Instance.new("TextButton")
            Btn.Parent = BtnFrame
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = text
            Btn.Font = Enum.Font.Gotham
            Btn.TextColor3 = Color3.fromRGB(240, 240, 240)
            Btn.TextSize = 14
            
            Btn.MouseEnter:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
                if Library.Theme.Rainbow then Stroke.Color = RainbowColor else Stroke.Color = Library.Theme.MainColor end
                TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
                PlaySound(Sounds.Hover)
            end)
            
            Btn.MouseLeave:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
                TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
            end)
            
            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                local Ripple = Instance.new("ImageLabel")
                Ripple.Parent = BtnFrame
                Ripple.Image = "rbxassetid://266543268"
                Ripple.ImageTransparency = 0.6
                Ripple.BackgroundTransparency = 1
                Ripple.Position = UDim2.new(0, Mouse.X - BtnFrame.AbsolutePosition.X, 0, Mouse.Y - BtnFrame.AbsolutePosition.Y)
                Ripple.Size = UDim2.new(0,0,0,0)
                Ripple.ZIndex = 5
                TweenService:Create(Ripple, TweenInfo.new(0.5), {Size = UDim2.new(0,200,0,200), ImageTransparency = 1}):Play()
                game.Debris:AddItem(Ripple, 0.5)
                callback()
            end)
        end

        function Elements:Toggle(text, default, callback)
            local ToggleVal = default or false
            callback = callback or function() end
            
            local TogFrame = Instance.new("Frame")
            TogFrame.Parent = PageScroll
            TogFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            TogFrame.Size = UDim2.new(1, -10, 0, 35)
            
            local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 4); Corner.Parent = TogFrame
            
            local Label = Instance.new("TextLabel")
            Label.Parent = TogFrame
            Label.BackgroundTransparency = 1
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextColor3 = Color3.fromRGB(240, 240, 240)
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local CheckBox = Instance.new("Frame")
            CheckBox.Parent = TogFrame
            CheckBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            CheckBox.Position = UDim2.new(1, -30, 0.5, -10)
            CheckBox.Size = UDim2.new(0, 20, 0, 20)
            
            local CheckCorner = Instance.new("UICorner"); CheckCorner.CornerRadius = UDim.new(0, 4); CheckCorner.Parent = CheckBox
            local CheckStroke = Instance.new("UIStroke"); CheckStroke.Parent = CheckBox; CheckStroke.Color = Color3.fromRGB(60,60,70)
            
            local Indicator = Instance.new("Frame")
            Indicator.Parent = CheckBox
            Indicator.BackgroundColor3 = Library.Theme.MainColor
            Indicator.Position = UDim2.new(0.5, -8, 0.5, -8)
            Indicator.Size = UDim2.new(0, 16, 0, 16)
            Indicator.BackgroundTransparency = 1
            local IndCorner = Instance.new("UICorner"); IndCorner.CornerRadius = UDim.new(0, 3); IndCorner.Parent = Indicator
            
            local Btn = Instance.new("TextButton")
            Btn.Parent = TogFrame
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Text = ""
            
            local function Set(value)
                ToggleVal = value
                Library.Flags[text] = ToggleVal
                
                if ToggleVal then
                    TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
                    if Library.Theme.Rainbow then Indicator.BackgroundColor3 = RainbowColor else Indicator.BackgroundColor3 = Library.Theme.MainColor end
                else
                    TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                end
                
                pcall(callback, ToggleVal)
            end
            
            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                Set(not ToggleVal)
            end)
            
            RunService.Heartbeat:Connect(function()
                if ToggleVal then
                    if Library.Theme.Rainbow then Indicator.BackgroundColor3 = RainbowColor else Indicator.BackgroundColor3 = Library.Theme.MainColor end
                end
            end)
            
            Library.Items[text] = { Type = "Toggle", Set = Set }
            Set(default)
        end

        function Elements:Slider(text, min, max, default, callback)
            local SliderVal = default or min
            callback = callback or function() end
            
            local SliFrame = Instance.new("Frame")
            SliFrame.Parent = PageScroll
            SliFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            SliFrame.Size = UDim2.new(1, -10, 0, 50)
            local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 4); Corner.Parent = SliFrame
            
            local Label = Instance.new("TextLabel")
            Label.Parent = SliFrame
            Label.BackgroundTransparency = 1
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextColor3 = Color3.fromRGB(240, 240, 240)
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local ValLabel = Instance.new("TextLabel")
            ValLabel.Parent = SliFrame
            ValLabel.BackgroundTransparency = 1
            ValLabel.Position = UDim2.new(1, -60, 0, 5)
            ValLabel.Size = UDim2.new(0, 50, 0, 20)
            ValLabel.Text = tostring(SliderVal)
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextColor3 = Color3.new(1,1,1)
            ValLabel.TextSize = 14
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            local Bar = Instance.new("Frame")
            Bar.Parent = SliFrame
            Bar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
            Bar.Position = UDim2.new(0, 10, 0, 30)
            Bar.Size = UDim2.new(1, -20, 0, 6)
            local BarCorner = Instance.new("UICorner"); BarCorner.CornerRadius = UDim.new(0, 3); BarCorner.Parent = Bar
            
            local Fill = Instance.new("Frame")
            Fill.Parent = Bar
            Fill.BackgroundColor3 = Library.Theme.MainColor
            Fill.Size = UDim2.new(0, 0, 1, 0)
            local FillCorner = Instance.new("UICorner"); FillCorner.CornerRadius = UDim.new(0, 3); FillCorner.Parent = Fill
            
            local Knob = Instance.new("Frame")
            Knob.Parent = Fill
            Knob.BackgroundColor3 = Color3.new(1,1,1)
            Knob.Position = UDim2.new(1, -4, 0.5, -6)
            Knob.Size = UDim2.new(0, 12, 0, 12)
            local KnobCorner = Instance.new("UICorner"); KnobCorner.CornerRadius = UDim.new(1, 0); KnobCorner.Parent = Knob
            local KnobStroke = Instance.new("UIStroke"); KnobStroke.Parent = Knob; KnobStroke.Color = Library.Theme.MainColor
            
            RunService.Heartbeat:Connect(function()
                local c = Library.Theme.Rainbow and RainbowColor or Library.Theme.MainColor
                Fill.BackgroundColor3 = c
                KnobStroke.Color = c
            end)
            
            local function Set(value)
                local clamped = math.clamp(value, min, max)
                SliderVal = clamped
                Library.Flags[text] = SliderVal
                ValLabel.Text = tostring(SliderVal)
                
                local percent = (SliderVal - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
                pcall(callback, SliderVal)
            end
            
            local isDragging = false
            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = true
                    local sizeX = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    Set(math.floor(min + ((max - min) * sizeX)))
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local sizeX = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    Set(math.floor(min + ((max - min) * sizeX)))
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                end
            end)
            
            Library.Items[text] = { Type = "Slider", Set = Set }
            Set(default)
        end

        function Elements:ColorPicker(text, default, callback)
            local ColorVal = default or Color3.fromRGB(255,255,255)
            callback = callback or function() end
            
            local PickerFrame = Instance.new("Frame")
            PickerFrame.Parent = PageScroll
            PickerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            PickerFrame.Size = UDim2.new(1, -10, 0, 35)
            PickerFrame.ClipsDescendants = true
            local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 4); Corner.Parent = PickerFrame
            
            local Label = Instance.new("TextLabel")
            Label.Parent = PickerFrame
            Label.BackgroundTransparency = 1
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.Size = UDim2.new(0.6, 0, 0, 35)
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextColor3 = Color3.fromRGB(240, 240, 240)
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            
            local Preview = Instance.new("TextButton")
            Preview.Parent = PickerFrame
            Preview.Position = UDim2.new(1, -50, 0, 5)
            Preview.Size = UDim2.new(0, 40, 0, 25)
            Preview.Text = ""
            Preview.BackgroundColor3 = ColorVal
            local PCorner = Instance.new("UICorner"); PCorner.CornerRadius = UDim.new(0, 4); PCorner.Parent = Preview
            local PStroke = Instance.new("UIStroke"); PStroke.Parent = Preview; PStroke.Color = Color3.new(1,1,1)
            
            local Container = Instance.new("Frame")
            Container.Parent = PickerFrame
            Container.BackgroundTransparency = 1
            Container.Position = UDim2.new(0, 0, 0, 40)
            Container.Size = UDim2.new(1, 0, 0, 110)
            
            -- Simple HSV Spectrum (Square style for reliability)
            local HsvMap = Instance.new("ImageButton")
            HsvMap.Parent = Container
            HsvMap.Position = UDim2.new(0, 10, 0, 10)
            HsvMap.Size = UDim2.new(0, 100, 0, 90)
            HsvMap.Image = "rbxassetid://4155801252"
            
            local Cursor = Instance.new("Frame")
            Cursor.Parent = HsvMap
            Cursor.Size = UDim2.new(0, 6, 0, 6)
            Cursor.BackgroundColor3 = Color3.new(1,1,1)
            Cursor.BorderColor3 = Color3.new(0,0,0)
            
            -- Helper to serialize Color3
            local function PackColor(c) return {R=c.R, G=c.G, B=c.B} end
            
            local function Set(color)
                ColorVal = color
                Preview.BackgroundColor3 = color
                Library.Flags[text] = PackColor(color)
                pcall(callback, color)
            end
            
            local draggingPicker = false
            HsvMap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingPicker = true
                    local x = math.clamp((input.Position.X - HsvMap.AbsolutePosition.X) / HsvMap.AbsoluteSize.X, 0, 1)
                    local y = math.clamp((input.Position.Y - HsvMap.AbsolutePosition.Y) / HsvMap.AbsoluteSize.Y, 0, 1)
                    Cursor.Position = UDim2.new(x, -3, y, -3)
                    Set(Color3.fromHSV(x, 1-y, 1))
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingPicker and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local x = math.clamp((input.Position.X - HsvMap.AbsolutePosition.X) / HsvMap.AbsoluteSize.X, 0, 1)
                    local y = math.clamp((input.Position.Y - HsvMap.AbsolutePosition.Y) / HsvMap.AbsoluteSize.Y, 0, 1)
                    Cursor.Position = UDim2.new(x, -3, y, -3)
                    Set(Color3.fromHSV(x, 1-y, 1))
                end
            end)
            UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingPicker = false end end)

            -- Presets
            local PresetFrame = Instance.new("Frame")
            PresetFrame.Parent = Container
            PresetFrame.BackgroundTransparency = 1
            PresetFrame.Position = UDim2.new(0.5, 0, 0, 10)
            PresetFrame.Size = UDim2.new(0.45, 0, 0.8, 0)
            
            local Grid = Instance.new("UIGridLayout")
            Grid.Parent = PresetFrame
            Grid.CellSize = UDim2.new(0, 25, 0, 25)
            Grid.CellPadding = UDim2.new(0, 5, 0, 5)
            
            local Colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(0,255,255), Color3.fromRGB(255,0,255)}
            for _, c in pairs(Colors) do
                local pBtn = Instance.new("TextButton")
                pBtn.Parent = PresetFrame
                pBtn.BackgroundColor3 = c
                pBtn.Text = ""
                local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(1, 0); pC.Parent = pBtn
                pBtn.MouseButton1Click:Connect(function() Set(c) end)
            end

            local isOpen = false
            Preview.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                TweenService:Create(PickerFrame, TweenInfo.new(0.3), {Size = isOpen and UDim2.new(1, -10, 0, 150) or UDim2.new(1, -10, 0, 35)}):Play()
            end)
            
            Library.Items[text] = { Type = "ColorPicker", Set = Set }
            Set(default)
        end
        
        return Elements
    end
    
    -- Config Tab Built-in
    local SettingsTab = Window:Tab("Settings")
    SettingsTab:Section("Configuration")
    
    local ConfigName = ""
    local CFG_Frame = Instance.new("Frame")
    CFG_Frame.Parent = Pages:FindFirstChild("Settings") and Pages.Settings.ScrollingFrame or Pages:GetChildren()[#Pages:GetChildren()]
    CFG_Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    CFG_Frame.Size = UDim2.new(1, -10, 0, 35)
    local CFG_Corner = Instance.new("UICorner"); CFG_Corner.CornerRadius = UDim.new(0, 4); CFG_Corner.Parent = CFG_Frame
    
    local CFG_Box = Instance.new("TextBox")
    CFG_Box.Parent = CFG_Frame
    CFG_Box.BackgroundTransparency = 1
    CFG_Box.Size = UDim2.new(1, -10, 1, 0)
    CFG_Box.Position = UDim2.new(0, 5, 0, 0)
    CFG_Box.TextColor3 = Color3.new(1,1,1)
    CFG_Box.PlaceholderText = "Config Name..."
    CFG_Box.Font = Enum.Font.Gotham
    CFG_Box.TextSize = 14
    CFG_Box.FocusLost:Connect(function() ConfigName = CFG_Box.Text end)
    
    local function Flash()
        local F = Instance.new("Frame", ScreenGui)
        F.Size, F.BackgroundColor3, F.BackgroundTransparency, F.ZIndex = UDim2.new(1,0,1,0), Library.Theme.MainColor, 0.5, 9999
        PlaySound(Sounds.ConfigLoad)
        TweenService:Create(F, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        task.wait(0.5)
        F:Destroy()
    end
    
    SettingsTab:Button("Save Config", function()
        if ConfigName == "" then return end
        if not isfolder(Library.Folder) then makefolder(Library.Folder) end
        writefile(Library.Folder .. "/" .. ConfigName .. ".json", HttpService:JSONEncode(Library.Flags))
        PlaySound(Sounds.Click)
    end)
    
    SettingsTab:Button("Load Config", function()
        if ConfigName == "" then return end
        local path = Library.Folder .. "/" .. ConfigName .. ".json"
        if pcall(readfile, path) then
            local data = HttpService:JSONDecode(readfile(path))
            for flag, val in pairs(data) do
                local item = Library.Items[flag]
                if item then
                    if item.Type == "ColorPicker" then
                        item.Set(Color3.new(val.R, val.G, val.B))
                    else
                        item.Set(val)
                    end
                end
            end
            Flash()
        end
    end)
    
    SettingsTab:Section("UI Options")
    SettingsTab:Toggle("Rainbow Mode", false, function(v) Library.Theme.Rainbow = v end)
    SettingsTab:Slider("Transparency", 0, 100, 10, function(v) Library.Theme.Transparency = v/100 end)
    SettingsTab:ColorPicker("Accent Color", Library.Theme.MainColor, function(c) Library.Theme.MainColor = c end)
    
    SettingsTab:Section("Danger Zone")
    SettingsTab:Button("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    SettingsTab:Button("Unload & Close", function() ScreenGui:Destroy() end)

    return Window
end

--=============================================================================
--[[ 
    SCRIPT HUB LOGIC 
    (The Features)
]]
--=============================================================================

local State = {
    Speed = 16,
    Jump = 50,
    Noclip = false,
    InfJump = false,
    ESP = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    Fullbright = false
}

--// WINDOW SETUP
local Window = Library:CreateWindow({
    Name = "NEON NEXUS // HUB",
    IntroEnabled = true
})

--// TAB 1: LOCAL PLAYER
local PlayerTab = Window:Tab("Local Player")

PlayerTab:Section("Movement Attributes")

PlayerTab:Slider("Walk Speed", 16, 250, 16, function(v)
    State.Speed = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

PlayerTab:Slider("Jump Power", 50, 350, 50, function(v)
    State.Jump = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)

-- Loop to keep stats active on respawn
task.spawn(function()
    while task.wait(0.5) do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if LocalPlayer.Character.Humanoid.WalkSpeed ~= State.Speed then
                LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
            end
            if LocalPlayer.Character.Humanoid.JumpPower ~= State.Jump then
                LocalPlayer.Character.Humanoid.UseJumpPower = true
                LocalPlayer.Character.Humanoid.JumpPower = State.Jump
            end
        end
    end
end)

PlayerTab:Section("Physics Manipulation")

PlayerTab:Toggle("Noclip (Walk Through Walls)", false, function(v)
    State.Noclip = v
end)

RunService.Stepped:Connect(function()
    if State.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

PlayerTab:Toggle("Infinite Jump", false, function(v)
    State.InfJump = v
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

--// TAB 2: VISUALS
local VisualTab = Window:Tab("Visuals")

VisualTab:Section("ESP Settings")

VisualTab:Toggle("Enabled ESP", false, function(v)
    State.ESP = v
    if not v then
        -- Cleanup
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("NeonESP") then
                p.Character.NeonESP:Destroy()
            end
        end
    end
end)

VisualTab:ColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(c)
    State.ESPColor = c
end)

-- Efficient ESP Loop
RunService.Heartbeat:Connect(function()
    if State.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local H = p.Character:FindFirstChild("NeonESP")
                if not H then
                    H = Instance.new("Highlight")
                    H.Name = "NeonESP"
                    H.Parent = p.Character
                    H.FillTransparency = 0.5
                    H.OutlineTransparency = 0
                end
                
                if H.FillColor ~= State.ESPColor then
                    H.FillColor = State.ESPColor
                    H.OutlineColor = State.ESPColor
                end
            else
                -- Remove if invalid
                if p.Character and p.Character:FindFirstChild("NeonESP") then
                    p.Character.NeonESP:Destroy()
                end
            end
        end
    end
end)

VisualTab:Section("World Render")

VisualTab:Toggle("Fullbright", false, function(v)
    State.Fullbright = v
    if v then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.new(0,0,0) -- Reset approximate
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end)

VisualTab:Slider("Time of Day", 0, 24, 14, function(v)
    Lighting.ClockTime = v
end)

--// TAB 3: MISC
local MiscTab = Window:Tab("Misc")

MiscTab:Section("Character")

MiscTab:Button("Reset Character", function()
    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
end)

MiscTab:Button("Force Rejoin", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- End of script
print("NEON NEXUS LOADED SUCCESSFULLY")
