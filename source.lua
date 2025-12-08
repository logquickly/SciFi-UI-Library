--[[ 
    TITANIUM SCI-FI UI LIBRARY V4.0
    Created for User Request (GitHub Project)
    Style: Sci-Fi / Cyberpunk
    Features: RGB Borders, Config System, Advanced Animations, Mobile Support, Sound Engine
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local Library = {
    Settings = {
        Name = "Titanium Hub",
        Theme = {
            Main = Color3.fromRGB(25, 25, 35),
            Secondary = Color3.fromRGB(35, 35, 45),
            Accent = Color3.fromRGB(0, 255, 213), -- Neon Cyan default
            Text = Color3.fromRGB(240, 240, 240),
            Outline = Color3.fromRGB(50, 50, 60),
            Transparency = 0.2
        },
        RainbowBorder = true,
        Keybind = Enum.KeyCode.RightControl
    },
    ConfigFolder = "TitaniumConfigs",
    Opened = true,
    Flags = {},
    Signal = {},
    Elements = {}
}

-- -------------------------------------------------------------------------
-- // SOUND ENGINE (音效系统)
-- -------------------------------------------------------------------------

local SoundFolder = Instance.new("Folder")
SoundFolder.Name = "TitaniumSounds"
SoundFolder.Parent = game:GetService("SoundService")

local function PlaySound(id, vol, pitch)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. tostring(id)
    s.Volume = vol or 1
    s.Pitch = pitch or 1
    s.Parent = SoundFolder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local Sounds = {
    Hover = function() PlaySound(4590662766, 0.5, 1.2) end,
    Click = function() PlaySound(4590657391, 0.8, 1) end,
    Load = function() PlaySound(6114984184, 1, 1) end, -- Sci-Fi Startup
    ConfigLoad = function() PlaySound(5750178499, 1.5, 1) end -- Unique Config Sound
}

-- -------------------------------------------------------------------------
-- // UTILITY FUNCTIONS (工具函数)
-- -------------------------------------------------------------------------

local function MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

local function Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function AddRipple(Button)
    Button.ClipsDescendants = true
    Button.MouseButton1Click:Connect(function()
        spawn(function()
            local Ripple = Instance.new("ImageLabel")
            Ripple.Name = "Ripple"
            Ripple.Parent = Button
            Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Ripple.BackgroundTransparency = 1
            Ripple.BorderSizePixel = 0
            Ripple.Image = "rbxassetid://2708891598"
            Ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
            Ripple.ImageTransparency = 0.8
            Ripple.Position = UDim2.new(0, Mouse.X - Button.AbsolutePosition.X, 0, Mouse.Y - Button.AbsolutePosition.Y)
            Ripple.Size = UDim2.new(0, 0, 0, 0)
            Ripple.AnchorPoint = Vector2.new(0.5, 0.5)

            local Tween = TweenService:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 300), ImageTransparency = 1})
            Tween:Play()
            Tween.Completed:Wait()
            Ripple:Destroy()
        end)
    end)
end

-- -------------------------------------------------------------------------
-- // UI CONSTRUCTOR (UI 构建核心)
-- -------------------------------------------------------------------------

function Library:Window(options)
    local WindowName = options.Name or "Titanium Hub"
    Library.Settings.Name = WindowName

    -- Main ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "TitaniumLib",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- Intro Animation Frame
    local IntroFrame = Create("Frame", {
        Name = "IntroFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Color3.fromRGB(10, 10, 15),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 9999
    })

    local IntroText = Create("TextLabel", {
        Parent = IntroFrame,
        Text = "INITIALIZING SYSTEM...",
        TextColor3 = Library.Settings.Theme.Accent,
        TextSize = 24,
        Font = Enum.Font.Code,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextTransparency = 1
    })

    -- Background Blur
    local Blur = Create("BlurEffect", {
        Parent = game:GetService("Lighting"),
        Size = 0,
        Name = "TitaniumBlur"
    })

    -- Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Library.Settings.Theme.Main,
        BackgroundTransparency = Library.Settings.Theme.Transparency,
        Position = UDim2.new(0.5, -325, 0.5, -200),
        Size = UDim2.new(0, 650, 0, 450),
        ClipsDescendants = false,
        Visible = false -- Hidden until intro done
    })

    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 6)})

    -- Rainbow Border Logic
    local BorderStroke = Create("UIStroke", {
        Parent = MainFrame,
        Thickness = 2,
        Transparency = 0
    })
    
    local BorderGradient = Create("UIGradient", {
        Parent = BorderStroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
        })
    })

    -- Rainbow Loop
    spawn(function()
        while Library.Settings.RainbowBorder do
            local dt = RunService.RenderStepped:Wait()
            BorderGradient.Rotation = (BorderGradient.Rotation + 1) % 360
        end
    end)

    -- Topbar
    local Topbar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Library.Settings.Theme.Secondary,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 40),
        Name = "Topbar"
    })
    Create("UICorner", {Parent = Topbar, CornerRadius = UDim.new(0, 6)})
    
    -- Fix bottom corners of topbar
    local TopbarFiller = Create("Frame", {
        Parent = Topbar,
        BackgroundColor3 = Library.Settings.Theme.Secondary,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -5),
        Size = UDim2.new(1, 0, 0, 5)
    })

    local Title = Create("TextLabel", {
        Parent = Topbar,
        Text = WindowName,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Library.Settings.Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    MakeDraggable(Topbar, MainFrame)

    -- Container for Tabs and Elements
    local TabContainer = Create("ScrollingFrame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 150, 1, -60),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto scale
    })
    local TabListLayout = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    local PagesContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 170, 0, 50),
        Size = UDim2.new(1, -180, 1, -60),
        ClipsDescendants = true
    })

    -- ---------------------------------------------------------------------
    -- INTRO ANIMATION EXECUTION
    -- ---------------------------------------------------------------------
    Sounds.Load()
    TweenService:Create(IntroText, TweenInfo.new(1), {TextTransparency = 0}):Play()
    wait(1.5)
    TweenService:Create(IntroText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(Blur, TweenInfo.new(1), {Size = 15}):Play()
    wait(0.5)
    IntroFrame:Destroy()
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, 650, 0, 450)}):Play()
    
    -- ---------------------------------------------------------------------
    -- TABS
    -- ---------------------------------------------------------------------
    local Tabs = {}
    local FirstTab = true

    function Tabs:Tab(name, iconId)
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            BackgroundColor3 = Library.Settings.Theme.Secondary,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, 0, 0, 35),
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextColor3 = Library.Settings.Theme.Text,
            TextSize = 14,
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabButton, CornerRadius = UDim.new(0, 4)})

        local Page = Create("ScrollingFrame", {
            Parent = PagesContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Settings.Theme.Accent,
            Visible = false
        })
        local PageLayout = Create("UIListLayout", {
            Parent = Page,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })
        
        -- Auto Resize Canvas
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabButton.BackgroundColor3 = Library.Settings.Theme.Accent
            TabButton.TextColor3 = Color3.fromRGB(20, 20, 20)
        end

        TabButton.MouseButton1Click:Connect(function()
            Sounds.Click()
            -- Hide all pages
            for _, p in pairs(PagesContainer:GetChildren()) do
                if p:IsA("ScrollingFrame") then p.Visible = false end
            end
            -- Reset all tab buttons
            for _, t in pairs(TabContainer:GetChildren()) do
                if t:IsA("TextButton") then
                    TweenService:Create(t, TweenInfo.new(0.3), {BackgroundColor3 = Library.Settings.Theme.Secondary, TextColor3 = Library.Settings.Theme.Text}):Play()
                end
            end
            -- Show current
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundColor3 = Library.Settings.Theme.Accent, TextColor3 = Color3.fromRGB(20, 20, 20)}):Play()
        end)

        local Elements = {}

        -- SECTION
        function Elements:Section(text)
            local SectionLabel = Create("TextLabel", {
                Parent = Page,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextColor3 = Library.Settings.Theme.Accent,
                TextSize = 14,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 25),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            Create("UIPadding", {Parent = SectionLabel, PaddingLeft = UDim.new(0, 5)})
        end

        -- BUTTON
        function Elements:Button(text, callback)
            callback = callback or function() end
            
            local ButtonFrame = Create("TextButton", {
                Parent = Page,
                BackgroundColor3 = Library.Settings.Theme.Secondary,
                Size = UDim2.new(1, -5, 0, 32),
                Text = text,
                Font = Enum.Font.Gotham,
                TextColor3 = Library.Settings.Theme.Text,
                TextSize = 14,
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = ButtonFrame, CornerRadius = UDim.new(0, 4)})
            Create("UIStroke", {Parent = ButtonFrame, Color = Library.Settings.Theme.Outline, Thickness = 1})
            AddRipple(ButtonFrame)

            ButtonFrame.MouseEnter:Connect(function()
                Sounds.Hover()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
            end)
            ButtonFrame.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TweenInfo.new(0.2), {BackgroundColor3 = Library.Settings.Theme.Secondary}):Play()
            end)
            
            ButtonFrame.MouseButton1Click:Connect(function()
                Sounds.Click()
                pcall(callback)
            end)
        end

        -- TOGGLE
        function Elements:Toggle(text, default, callback)
            callback = callback or function() end
            local Toggled = default or false
            Library.Flags[text] = Toggled

            local ToggleFrame = Create("TextButton", {
                Parent = Page,
                BackgroundColor3 = Library.Settings.Theme.Secondary,
                Size = UDim2.new(1, -5, 0, 32),
                Text = "",
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 4)})
            Create("UIStroke", {Parent = ToggleFrame, Color = Library.Settings.Theme.Outline, Thickness = 1})

            local Label = Create("TextLabel", {
                Parent = ToggleFrame,
                Text = text,
                Font = Enum.Font.Gotham,
                TextColor3 = Library.Settings.Theme.Text,
                TextSize = 14,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Switch = Create("Frame", {
                Parent = ToggleFrame,
                BackgroundColor3 = Toggled and Library.Settings.Theme.Accent or Color3.fromRGB(60, 60, 60),
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10)
            })
            Create("UICorner", {Parent = Switch, CornerRadius = UDim.new(1, 0)})

            local Circle = Create("Frame", {
                Parent = Switch,
                BackgroundColor3 = Color3.new(1,1,1),
                Size = UDim2.new(0, 16, 0, 16),
                Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            })
            Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})

            ToggleFrame.MouseButton1Click:Connect(function()
                Sounds.Click()
                Toggled = not Toggled
                Library.Flags[text] = Toggled
                
                TweenService:Create(Switch, TweenInfo.new(0.2), {
                    BackgroundColor3 = Toggled and Library.Settings.Theme.Accent or Color3.fromRGB(60, 60, 60)
                }):Play()
                
                TweenService:Create(Circle, TweenInfo.new(0.2), {
                    Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()

                pcall(callback, Toggled)
            end)
            
            -- 用于Config加载时更新UI
            Library.Signal[text] = function(value)
                Toggled = value
                Library.Flags[text] = value
                TweenService:Create(Switch, TweenInfo.new(0.2), {
                    BackgroundColor3 = Toggled and Library.Settings.Theme.Accent or Color3.fromRGB(60, 60, 60)
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), {
                    Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()
                pcall(callback, Toggled)
            end
        end

        -- SLIDER
        function Elements:Slider(text, min, max, default, callback)
            callback = callback or function() end
            default = default or min
            Library.Flags[text] = default

            local SliderFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.Settings.Theme.Secondary,
                Size = UDim2.new(1, -5, 0, 45)
            })
            Create("UICorner", {Parent = SliderFrame, CornerRadius = UDim.new(0, 4)})
            Create("UIStroke", {Parent = SliderFrame, Color = Library.Settings.Theme.Outline, Thickness = 1})

            local Label = Create("TextLabel", {
                Parent = SliderFrame,
                Text = text,
                Font = Enum.Font.Gotham,
                TextColor3 = Library.Settings.Theme.Text,
                TextSize = 14,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame,
                Text = tostring(default),
                Font = Enum.Font.Gotham,
                TextColor3 = Library.Settings.Theme.Text,
                TextSize = 14,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local SliderBar = Create("Frame", {
                Parent = SliderFrame,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 30)
            })
            Create("UICorner", {Parent = SliderBar, CornerRadius = UDim.new(1, 0)})

            local Fill = Create("Frame", {
                Parent = SliderBar,
                BackgroundColor3 = Library.Settings.Theme.Accent,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            })
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

            local IsDragging = false

            local function Update(input)
                local SizeX = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local Value = math.floor(min + ((max - min) * SizeX))
                
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(SizeX, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(Value)
                Library.Flags[text] = Value
                pcall(callback, Value)
            end

            SliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true
                    Update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

            Library.Signal[text] = function(value)
                local SizeX = (value - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(SizeX, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(value)
                Library.Flags[text] = value
                pcall(callback, value)
            end
        end

        -- CIRCULAR COLOR PICKER (Advanced Logic)
        function Elements:ColorPicker(text, default, callback)
            callback = callback or function() end
            default = default or Color3.fromRGB(255, 255, 255)
            Library.Flags[text] = default

            local Open = false
            local PickerFrame = Create("TextButton", {
                Parent = Page,
                BackgroundColor3 = Library.Settings.Theme.Secondary,
                Size = UDim2.new(1, -5, 0, 32),
                Text = "",
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = PickerFrame, CornerRadius = UDim.new(0, 4)})
            Create("UIStroke", {Parent = PickerFrame, Color = Library.Settings.Theme.Outline, Thickness = 1})

            local Label = Create("TextLabel", {
                Parent = PickerFrame,
                Text = text,
                Font = Enum.Font.Gotham,
                TextColor3 = Library.Settings.Theme.Text,
                TextSize = 14,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -50, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Preview = Create("Frame", {
                Parent = PickerFrame,
                BackgroundColor3 = default,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0.5, -10)
            })
            Create("UICorner", {Parent = Preview, CornerRadius = UDim.new(0, 4)})

            -- The Popup
            local CPContainer = Create("Frame", {
                Parent = PickerFrame,
                BackgroundColor3 = Color3.fromRGB(30, 30, 40),
                Size = UDim2.new(1, 0, 0, 170),
                Position = UDim2.new(0, 0, 1, 5),
                Visible = false,
                ZIndex = 5
            })
            Create("UICorner", {Parent = CPContainer, CornerRadius = UDim.new(0, 6)})
            Create("UIStroke", {Parent = CPContainer, Color = Library.Settings.Theme.Outline, Thickness = 1})

            -- Circular Wheel (Using Image)
            local Wheel = Create("ImageButton", {
                Parent = CPContainer,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(0, 120, 0, 120),
                Image = "rbxassetid://2849458409", -- Color Wheel Asset
                ZIndex = 6
            })
            
            local WheelCursor = Create("ImageLabel", {
                Parent = Wheel,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 14, 0, 14),
                Image = "rbxassetid://12224424362", -- Ring
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                ZIndex = 7
            })

            -- Value Slider (V)
            local ValueFrame = Create("Frame", {
                Parent = CPContainer,
                Position = UDim2.new(0, 140, 0, 10),
                Size = UDim2.new(0, 20, 0, 120),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 6
            })
            local ValueGradient = Create("UIGradient", {
                Parent = ValueFrame,
                Rotation = 90,
                Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0))
            })
            
            -- Hex Input
            local HexInput = Create("TextBox", {
                Parent = CPContainer,
                BackgroundColor3 = Color3.fromRGB(20, 20, 25),
                Size = UDim2.new(1, -20, 0, 25),
                Position = UDim2.new(0, 10, 1, -35),
                Text = "#FFFFFF",
                Font = Enum.Font.Gotham,
                TextColor3 = Color3.new(1,1,1),
                TextSize = 14,
                ZIndex = 6
            })
            Create("UICorner", {Parent = HexInput, CornerRadius = UDim.new(0, 4)})

            -- Logic Variables
            local h, s, v = Color3.toHSV(default)
            local draggingWheel = false
            local draggingValue = false

            local function UpdateColor()
                local newColor = Color3.fromHSV(h, s, v)
                Preview.BackgroundColor3 = newColor
                ValueFrame.BackgroundColor3 = Color3.fromHSV(h, s, 1) -- Keep hue visual
                Library.Flags[text] = newColor
                pcall(callback, newColor)
                
                -- Update Hex
                local r, g, b = math.floor(newColor.R*255), math.floor(newColor.G*255), math.floor(newColor.B*255)
                HexInput.Text = string.format("#%02X%02X%02X", r, g, b)
            end

            Wheel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingWheel = true
                end
            end)
            
            ValueFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingValue = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingWheel = false
                    draggingValue = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if draggingWheel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local objectPosition = Wheel.AbsolutePosition + (Wheel.AbsoluteSize / 2)
                    local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
                    local relativePosition = mousePosition - objectPosition
                    
                    local angle = math.atan2(relativePosition.Y, relativePosition.X) + math.pi
                    h = 1 - (angle / (2 * math.pi))
                    
                    local distance = math.clamp(relativePosition.Magnitude, 0, Wheel.AbsoluteSize.X / 2)
                    s = distance / (Wheel.AbsoluteSize.X / 2)
                    
                    -- Update Cursor Pos
                    local x = math.cos(angle - math.pi) * distance
                    local y = math.sin(angle - math.pi) * distance
                    WheelCursor.Position = UDim2.new(0.5, x, 0.5, y)
                    
                    UpdateColor()
                elseif draggingValue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                     local mouseY = input.Position.Y - ValueFrame.AbsolutePosition.Y
                     local clampedY = math.clamp(mouseY, 0, ValueFrame.AbsoluteSize.Y)
                     v = 1 - (clampedY / ValueFrame.AbsoluteSize.Y)
                     UpdateColor()
                end
            end)
            
            -- Hex Input Logic
            HexInput.FocusLost:Connect(function()
                pcall(function()
                    local succ, col = pcall(function() return Color3.fromHex(HexInput.Text) end)
                    if succ then
                        local nh, ns, nv = Color3.toHSV(col)
                        h, s, v = nh, ns, nv
                        UpdateColor()
                    end
                end)
            end)

            PickerFrame.MouseButton1Click:Connect(function()
                Sounds.Click()
                Open = not Open
                CPContainer.Visible = Open
                TweenService:Create(PickerFrame, TweenInfo.new(0.3), {Size = Open and UDim2.new(1, -5, 0, 205) or UDim2.new(1, -5, 0, 32)}):Play()
            end)
        end

        return Elements
    end

    -- ---------------------------------------------------------------------
    -- SETTINGS & CONFIG SYSTEM (配置系统)
    -- ---------------------------------------------------------------------
    local SettingsTab = Tabs:Tab("Settings")

    SettingsTab:Section("Configuration")

    local ConfigName = "Default"
    local ConfigList = {}
    
    local ConfigInput = Create("TextBox", {
        Parent = PagesContainer:FindFirstChild("Settings", true), -- Quick Ref hack
        BackgroundColor3 = Color3.fromRGB(40,40,50),
        Size = UDim2.new(1, -10, 0, 30),
        Text = "Config Name...",
        TextColor3 = Color3.fromRGB(200,200,200)
    })
    -- (Proper implementation inside standard elements usually, but doing raw for structure)
    
    SettingsTab:Button("Save Config", function()
        if not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
        local json = HttpService:JSONEncode(Library.Flags)
        writefile(Library.ConfigFolder .. "/" .. ConfigName .. ".json", json)
    end)

    SettingsTab:Button("Load Config", function()
        if isfile(Library.ConfigFolder .. "/" .. ConfigName .. ".json") then
            -- VISUAL FEEDBACK (Screen Flash)
            local Flash = Create("Frame", {
                Parent = ScreenGui,
                BackgroundColor3 = Library.Settings.Theme.Accent,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0.5,
                ZIndex = 10000
            })
            Sounds.ConfigLoad()
            TweenService:Create(Flash, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
            game:GetService("Debris"):AddItem(Flash, 1)

            -- LOAD DATA
            local json = readfile(Library.ConfigFolder .. "/" .. ConfigName .. ".json")
            local data = HttpService:JSONDecode(json)
            
            for flag, value in pairs(data) do
                if Library.Signal[flag] then
                    Library.Signal[flag](value)
                end
            end
        end
    end)
    
    -- Custom Input for Config Name
    local ConfigBoxFrame = Create("Frame", {
        Parent = PagesContainer:GetChildren()[#PagesContainer:GetChildren()], -- Get last page (Settings)
        BackgroundColor3 = Library.Settings.Theme.Secondary,
        Size = UDim2.new(1, -5, 0, 35)
    })
    Create("UICorner", {Parent = ConfigBoxFrame, CornerRadius = UDim.new(0, 4)})
    local ConfigBox = Create("TextBox", {
        Parent = ConfigBoxFrame,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = "Enter Config Name",
        TextColor3 = Library.Settings.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14
    })
    ConfigBox.FocusLost:Connect(function()
        ConfigName = ConfigBox.Text
    end)

    SettingsTab:Section("System")
    
    SettingsTab:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)

    SettingsTab:Button("Close UI", function()
        ScreenGui:Destroy()
        Blur:Destroy()
        SoundFolder:Destroy()
    end)
    
    SettingsTab:Toggle("Auto Load Config", false, function(v) 
        -- Logic handled by saving a separate "AutoLoad" file usually, 
        -- simplified here for demo.
    end)

    return Tabs
end

-- -------------------------------------------------------------------------
-- // EXAMPLE USAGE (示例用法)
-- -------------------------------------------------------------------------
-- 下面的代码展示了如何调用这个库。
-- 在实际项目中，删除下面的代码，只保留上面的 Library 定义，然后 require 使用。

local Window = Library:Window({Name = "Titanium Script Hub"})

local MainTab = Window:Tab("Main")
local VisualsTab = Window:Tab("Visuals")

MainTab:Section("Player")
MainTab:Toggle("God Mode", false, function(v)
    print("God Mode:", v)
end)

MainTab:Slider("WalkSpeed", 16, 200, 16, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

MainTab:Button("Kill Aura", function()
    print("Kill aura activated")
end)

MainTab:Section("Combat")
MainTab:Toggle("Silent Aim", false, function(v)
    print("Silent aim:", v)
end)

VisualsTab:Section("ESP Settings")
VisualsTab:ColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(c)
    print("Color Changed:", c)
end)

VisualsTab:Toggle("Box ESP", true, function(v) end)

-- Initial Config Load Check (Simulated)
-- if isfile(Library.ConfigFolder .. "/AutoLoad.txt") then ... end
