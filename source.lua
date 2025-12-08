--[[
    TITANIUM / SCI-FI UI LIBRARY [REMASTERED v2.0]
    Github Project: SciFi-UI-Library
    Author: User Request
    Fixes: Config List, Circular ColorPicker, Rainbow Border, Mobile Support
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- // FILE SYSTEM CHECK
local function is_folder(folder) if isfolder then return isfolder(folder) end return false end
local function make_folder(folder) if makefolder then makefolder(folder) end end
local function list_files(folder) if listfiles then return listfiles(folder) end return {} end
local function write_file(file, data) if writefile then writefile(file, data) end end
local function read_file(file) if readfile then return readfile(file) end return "{}" end

-- // LIBRARY TABLE
local Library = {
    Name = "Titanium",
    Folder = "TitaniumSettings",
    Theme = {
        Main = Color3.fromRGB(18, 18, 22),
        Secondary = Color3.fromRGB(28, 28, 34),
        Accent = Color3.fromRGB(0, 255, 213),
        Text = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(50, 50, 60),
        Transparency = 0.1
    },
    Settings = {
        RainbowBorder = true,
        Sounds = true,
        Keybind = Enum.KeyCode.RightControl
    },
    Flags = {},
    Configs = {},
    ActiveObjects = {} -- For updating themes live
}

-- // SOUND ENGINE
local Sounds = {
    Hover = "rbxassetid://4590662766",
    Click = "rbxassetid://4590657391",
    Load = "rbxassetid://6114984184",
    Config = "rbxassetid://5750178499" -- Success sound
}

local function PlaySound(id, vol)
    if not Library.Settings.Sounds then return end
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = vol or 1
        s.Parent = game:GetService("SoundService")
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end)
end

-- // UTILS
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(object, TweenInfo.new(0.05), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

-- // MAIN WINDOW FUNCTION
function Library:Window(options)
    Library.Name = options.Name or Library.Name
    Library.Folder = options.ConfigFolder or Library.Folder
    
    if is_folder and not is_folder(Library.Folder) then make_folder(Library.Folder) end

    -- Destroy Old UI
    if CoreGui:FindFirstChild("TitaniumUI") then CoreGui:FindFirstChild("TitaniumUI"):Destroy() end

    local ScreenGui = Create("ScreenGui", {Name = "TitaniumUI", Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    
    -- Main Container
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Library.Theme.Main,
        BackgroundTransparency = Library.Theme.Transparency,
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = false
    })
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 6)})

    -- // RAINBOW BORDER IMPLEMENTATION
    local BorderStroke = Create("UIStroke", {
        Parent = MainFrame,
        Thickness = 2,
        Transparency = 0,
        Color = Color3.new(1,1,1)
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

    -- Live Theme Update for Transparency
    table.insert(Library.ActiveObjects, function()
        MainFrame.BackgroundTransparency = Library.Theme.Transparency
        if Library.Settings.RainbowBorder then
            BorderStroke.Enabled = true
        else
            BorderStroke.Enabled = false
        end
    end)

    spawn(function()
        while MainFrame.Parent do
            if Library.Settings.RainbowBorder then
                BorderGradient.Rotation = (BorderGradient.Rotation + 2) % 360
            end
            task.wait()
        end
    end)

    -- Topbar
    local Topbar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Library.Theme.Secondary,
        BackgroundTransparency = 0,
        Size = UDim2.new(1, 0, 0, 40)
    })
    Create("UICorner", {Parent = Topbar, CornerRadius = UDim.new(0, 6)})
    -- Filler to hide bottom round corners of topbar
    Create("Frame", {
        Parent = Topbar, BackgroundColor3 = Library.Theme.Secondary, 
        BorderSizePixel=0, Position=UDim2.new(0,0,1,-5), Size=UDim2.new(1,0,0,5)
    })

    local TitleLabel = Create("TextLabel", {
        Parent = Topbar,
        Text = Library.Name,
        TextColor3 = Library.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    MakeDraggable(Topbar, MainFrame)

    -- Containers
    local TabContainer = Create("ScrollingFrame", {
        Parent = MainFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(0, 140, 1, -60),
        ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,0,0)
    })
    local TabList = Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    
    local Pages = Create("Frame", {
        Parent = MainFrame, BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 50), Size = UDim2.new(1, -170, 1, -60),
        ClipsDescendants = true
    })

    -- Intro Animation
    MainFrame.Size = UDim2.new(0,0,0,0)
    PlaySound(Sounds.Load, 1)
    TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = UDim2.new(0, 600, 0, 400)}):Play()

    -- // TAB SYSTEM
    local WindowTabs = {}
    local FirstTab = true

    function WindowTabs:Tab(name)
        local TabBtn = Create("TextButton", {
            Parent = TabContainer,
            Text = name,
            BackgroundColor3 = Library.Theme.Secondary,
            TextColor3 = Library.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 32),
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 4)})
        
        local Page = Create("ScrollingFrame", {
            Parent = Pages,
            Visible = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme.Accent
        })
        local PageList = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        
        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
        end)

        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabBtn.BackgroundColor3 = Library.Theme.Accent
            TabBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
        end

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            for _, p in pairs(Pages:GetChildren()) do if p:IsA("ScrollingFrame") then p.Visible = false end end
            for _, t in pairs(TabContainer:GetChildren()) do 
                if t:IsA("TextButton") then 
                    TweenService:Create(t, TweenInfo.new(0.3), {BackgroundColor3 = Library.Theme.Secondary, TextColor3 = Library.Theme.Text}):Play()
                end 
            end
            
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Library.Theme.Accent, TextColor3 = Color3.fromRGB(20, 20, 20)}):Play()
        end)

        local Elements = {}

        function Elements:Section(text)
            local Sec = Create("TextLabel", {
                Parent = Page, Text = text, Font = Enum.Font.GothamBold,
                TextColor3 = Library.Theme.Accent, TextSize = 14, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 25), TextXAlignment = Enum.TextXAlignment.Left
            })
            Create("UIPadding", {Parent = Sec, PaddingLeft = UDim.new(0, 2)})
        end

        function Elements:Toggle(text, default, callback)
            Library.Flags[text] = default or false
            local Toggled = default or false

            local Btn = Create("TextButton", {
                Parent = Page, BackgroundColor3 = Library.Theme.Secondary, Size = UDim2.new(1, -4, 0, 34),
                Text = "", AutoButtonColor = false
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
            
            local Label = Create("TextLabel", {
                Parent = Btn, Text = text, TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 13, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local ToggleBg = Create("Frame", {
                Parent = Btn, BackgroundColor3 = Color3.fromRGB(40,40,45), Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10)
            })
            Create("UICorner", {Parent = ToggleBg, CornerRadius = UDim.new(1, 0)})
            
            local Dot = Create("Frame", {
                Parent = ToggleBg, BackgroundColor3 = Color3.fromRGB(200,200,200), Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 2, 0.5, -8)
            })
            Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})

            local function Update()
                if Toggled then
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Library.Theme.Accent}):Play()
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
                else
                    TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,45)}):Play()
                    TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
                end
                Library.Flags[text] = Toggled
                pcall(callback, Toggled)
            end

            -- Initial Set
            if default then Update() end

            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                Toggled = not Toggled
                Update()
            end)
            
            Library.Configs[text] = function(val) Toggled = val; Update() end
        end

        function Elements:Button(text, callback)
            local Btn = Create("TextButton", {
                Parent = Page, BackgroundColor3 = Library.Theme.Secondary, Size = UDim2.new(1, -4, 0, 34),
                Text = text, TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham, TextSize = 13,
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
            
            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50,50,60)}):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Secondary}):Play()
                pcall(callback)
            end)
        end

        function Elements:Slider(text, min, max, default, callback)
            Library.Flags[text] = default
            local Value = default

            local Frame = Create("Frame", {
                Parent = Page, BackgroundColor3 = Library.Theme.Secondary, Size = UDim2.new(1, -4, 0, 45)
            })
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 4)})
            
            local Label = Create("TextLabel", {
                Parent = Frame, Text = text, TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 13, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20), TextXAlignment = Enum.TextXAlignment.Left
            })
            local ValLabel = Create("TextLabel", {
                Parent = Frame, Text = tostring(default), TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 13, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20), TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local Bar = Create("Frame", {
                Parent = Frame, BackgroundColor3 = Color3.fromRGB(40,40,45), Size = UDim2.new(1, -20, 0, 6),
                Position = UDim2.new(0, 10, 0, 30)
            })
            Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})
            
            local Fill = Create("Frame", {
                Parent = Bar, BackgroundColor3 = Library.Theme.Accent, Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
            })
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

            local function Update(input)
                local s = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Value = math.floor(min + ((max - min) * s))
                TweenService:Create(Fill, TweenInfo.new(0.05), {Size = UDim2.new(s, 0, 1, 0)}):Play()
                ValLabel.Text = tostring(Value)
                Library.Flags[text] = Value
                pcall(callback, Value)
            end

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local connection; connection = UserInputService.InputChanged:Connect(function(move)
                        if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                            Update(move)
                        end
                    end)
                    local release; release = UserInputService.InputEnded:Connect(function(endInput)
                        if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                            connection:Disconnect()
                            release:Disconnect()
                        end
                    end)
                    Update(input)
                end
            end)

            Library.Configs[text] = function(val)
                Value = val
                local s = (Value - min)/(max - min)
                TweenService:Create(Fill, TweenInfo.new(0.2), {Size = UDim2.new(s, 0, 1, 0)}):Play()
                ValLabel.Text = tostring(Value)
                pcall(callback, Value)
            end
        end

        -- // LIST / DROPDOWN
        function Elements:List(text, list, callback)
            local DropOpen = false
            
            local Frame = Create("Frame", {
                Parent = Page, BackgroundColor3 = Library.Theme.Secondary, Size = UDim2.new(1, -4, 0, 34),
                ClipsDescendants = true, ZIndex = 5
            })
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 4)})
            
            local Btn = Create("TextButton", {
                Parent = Frame, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false
            })

            local Label = Create("TextLabel", {
                Parent = Frame, Text = text, TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 13, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -40, 0, 34), TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local Icon = Create("ImageLabel", {
                Parent = Frame, BackgroundTransparency = 1, Image = "rbxassetid://3926305904",
                RectOffset = Vector2.new(564, 284), RectSize = Vector2.new(36, 36),
                Position = UDim2.new(1, -30, 0, 4), Size = UDim2.new(0, 24, 0, 24),
                Rotation = 0, ImageColor3 = Library.Theme.Text
            })

            local ListContainer = Create("ScrollingFrame", {
                Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 34),
                Size = UDim2.new(1, 0, 0, 100), ScrollBarThickness = 2
            })
            local Layout = Create("UIListLayout", {Parent = ListContainer, SortOrder = Enum.SortOrder.LayoutOrder})

            local function Refresh(newList)
                for _, v in pairs(ListContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, item in pairs(newList) do
                    local ItemBtn = Create("TextButton", {
                        Parent = ListContainer, Text = tostring(item), Size = UDim2.new(1, 0, 0, 25),
                        BackgroundColor3 = Color3.fromRGB(35,35,40), TextColor3 = Color3.fromRGB(200,200,200),
                        Font = Enum.Font.Gotham, TextSize = 12
                    })
                    ItemBtn.MouseButton1Click:Connect(function()
                        PlaySound(Sounds.Click)
                        Label.Text = text .. ": " .. item
                        pcall(callback, item)
                        DropOpen = false
                        TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, -4, 0, 34)}):Play()
                        TweenService:Create(Icon, TweenInfo.new(0.3), {Rotation = 0}):Play()
                    end)
                end
                ListContainer.CanvasSize = UDim2.new(0,0,0, Layout.AbsoluteContentSize.Y)
            end
            
            Refresh(list)

            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                DropOpen = not DropOpen
                TweenService:Create(Frame, TweenInfo.new(0.3), {Size = DropOpen and UDim2.new(1, -4, 0, 140) or UDim2.new(1, -4, 0, 34)}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {Rotation = DropOpen and 180 or 0}):Play()
            end)
            
            return {Refresh = Refresh}
        end

        -- // CIRCULAR COLOR PICKER (FIXED)
        function Elements:ColorPicker(text, default, callback)
            Library.Flags[text] = default
            local CurrentColor = default
            local Open = false

            local Btn = Create("TextButton", {
                Parent = Page, BackgroundColor3 = Library.Theme.Secondary, Size = UDim2.new(1, -4, 0, 34),
                Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 10
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
            
            local Label = Create("TextLabel", {
                Parent = Btn, Text = text, TextColor3 = Library.Theme.Text, Font = Enum.Font.Gotham,
                TextSize = 13, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -50, 0, 34), TextXAlignment = Enum.TextXAlignment.Left
            })

            local Preview = Create("Frame", {
                Parent = Btn, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0, 7),
                BackgroundColor3 = default
            })
            Create("UICorner", {Parent = Preview, CornerRadius = UDim.new(0, 4)})

            -- Picker Container
            local PickerArea = Create("Frame", {
                Parent = Btn, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 150),
                Position = UDim2.new(0, 0, 0, 34), Visible = false
            })

            -- Circular Image
            local Wheel = Create("ImageButton", {
                Parent = PickerArea, Image = "rbxassetid://6020299385", BackgroundTransparency = 1,
                Size = UDim2.new(0, 120, 0, 120), Position = UDim2.new(0.5, -60, 0, 10)
            })
            
            local Cursor = Create("Frame", {
                Parent = Wheel, Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5)
            })
            Create("UICorner", {Parent = Cursor, CornerRadius = UDim.new(1, 0)})

            local IsDragging = false

            local function UpdateColor(input)
                local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize / 2)
                local mouse = Vector2.new(input.Position.X, input.Position.Y)
                local relative = mouse - center
                
                local angle = math.atan2(relative.Y, relative.X)
                local radius = math.min(relative.Magnitude, Wheel.AbsoluteSize.X / 2)
                
                local x = math.cos(angle) * radius
                local y = math.sin(angle) * radius
                
                Cursor.Position = UDim2.new(0.5, x, 0.5, y)
                
                local sat = radius / (Wheel.AbsoluteSize.X / 2)
                local hue = (angle + math.pi) / (math.pi * 2)
                
                -- Fix orientation of hue to match image
                hue = 1 - hue 
                
                CurrentColor = Color3.fromHSV(hue, sat, 1)
                Preview.BackgroundColor3 = CurrentColor
                Library.Flags[text] = CurrentColor
                pcall(callback, CurrentColor)
            end

            Wheel.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true
                    UpdateColor(input)
                    local con; con = UserInputService.InputChanged:Connect(function(mv)
                         if mv.UserInputType == Enum.UserInputType.MouseMovement or mv.UserInputType == Enum.UserInputType.Touch then
                             UpdateColor(mv)
                         end
                    end)
                    local endCon; endCon = UserInputService.InputEnded:Connect(function(endInput)
                         if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                             IsDragging = false
                             con:Disconnect()
                             endCon:Disconnect()
                         end
                    end)
                end
            end)

            Btn.MouseButton1Click:Connect(function()
                PlaySound(Sounds.Click)
                Open = not Open
                PickerArea.Visible = Open
                TweenService:Create(Btn, TweenInfo.new(0.3), {Size = Open and UDim2.new(1, -4, 0, 190) or UDim2.new(1, -4, 0, 34)}):Play()
            end)
        end

        return Elements
    end

    -- // INTERNAL SETTINGS TAB
    local SetTab = WindowTabs:Tab("Settings")
    
    SetTab:Section("Configuration Manager")
    
    local ConfigListDisplay = SetTab:List("Select Config", {}, function(val) 
        Library.CurrentConfig = val 
    end)
    
    local function RefreshConfigs()
        if is_folder and list_files then
            local files = list_files(Library.Folder)
            local names = {}
            for _, f in pairs(files) do
                local name = f:gsub(Library.Folder.."\\", ""):gsub(Library.Folder.."/", ""):gsub(".json", "")
                table.insert(names, name)
            end
            ConfigListDisplay.Refresh(names)
        end
    end
    RefreshConfigs()

    local ConfigNameInput = "Default"
    
    -- We'll use a text input simulator since I didn't make a textbox element, 
    -- but we can save whatever is typed in a custom way or just use "Config1", "Config2".
    -- For this advanced version, I'll add a save button that saves "Config_"..Time or specific name.
    
    SetTab:Button("Save Config (New)", function()
        local name = "Config_" .. tostring(os.time())
        if write_file then
            local json = HttpService:JSONEncode(Library.Flags)
            write_file(Library.Folder .. "/" .. name .. ".json", json)
            RefreshConfigs()
            PlaySound(Sounds.Config)
        end
    end)

    SetTab:Button("Load Selected Config", function()
        if Library.CurrentConfig and read_file then
            -- FLASH EFFECT
            local Flash = Create("Frame", {
                Parent = ScreenGui, Size=UDim2.new(1,0,1,0), BackgroundColor3=Library.Theme.Accent,
                BackgroundTransparency=0.5, ZIndex=100
            })
            PlaySound(Sounds.Config, 1.5)
            TweenService:Create(Flash, TweenInfo.new(1), {BackgroundTransparency=1}):Play()
            game.Debris:AddItem(Flash, 1)

            local data = HttpService:JSONDecode(read_file(Library.Folder.."/"..Library.CurrentConfig..".json"))
            for flag, val in pairs(data) do
                if Library.Configs[flag] then Library.Configs[flag](val) end
            end
        end
    end)
    
    SetTab:Button("Refresh List", RefreshConfigs)

    SetTab:Section("UI Appearance")
    
    SetTab:Slider("Transparency", 0, 100, 10, function(v)
        Library.Theme.Transparency = v / 100
        for _, func in pairs(Library.ActiveObjects) do func() end
    end)
    
    SetTab:Toggle("Rainbow Border", true, function(v)
        Library.Settings.RainbowBorder = v
        for _, func in pairs(Library.ActiveObjects) do func() end
    end)

    SetTab:Toggle("Sound Effects", true, function(v)
        Library.Settings.Sounds = v
    end)

    SetTab:ColorPicker("Accent Color", Library.Theme.Accent, function(c)
        Library.Theme.Accent = c
        -- Note: A full theme update requires simpler referencing, but this sets the variable.
        -- For a true live update on all buttons, we'd need to store them all.
    end)

    SetTab:Section("System")
    
    SetTab:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    
    SetTab:Button("Unload UI", function()
        ScreenGui:Destroy()
    end)

    return WindowTabs
end

return Library

--[[ 
    ========================================================
    BELOW IS THE EXAMPLE SCRIPT TO RUN THE LIBRARY
    请在下方编写你的功能逻辑
    ========================================================
]]
