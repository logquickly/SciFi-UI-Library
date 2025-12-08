--[[
    --------------------------------------------------------------------
    TITAN CORE // SCI-FI UI LIBRARY
    Version: 2.0 (Redux)
    Theme: Cyberpunk / Futuristic
    Features: Circular Color Picker, Rainbow Borders, Config Flash, AutoLoad
    --------------------------------------------------------------------
]]

local Titan = {}

--// Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

--// Environment Check & Protection
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Viewport = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui"))) or CoreGui

--// Constants & Assets
local ASSETS = {
    Font = Enum.Font.Code,
    Icons = {
        Close = "rbxassetid://6031094678",
        Config = "rbxassetid://6031091004",
        Paint = "rbxassetid://6020299385" -- Color Wheel
    },
    Sounds = {
        Intro = "rbxassetid://4612375233", -- Cyber startup
        Hover = "rbxassetid://6895079853", -- UI Hover
        Click = "rbxassetid://6042053626", -- Crisp Click
        ConfigLoad = "rbxassetid://6227976860", -- Heavy Sci-Fi Confirm
        Error = "rbxassetid://4835664238"
    }
}

--// Library Settings
Titan.Settings = {
    Name = "TITAN HUB",
    Theme = {
        Main = Color3.fromRGB(0, 255, 220), -- Cyan Neon
        Background = Color3.fromRGB(15, 15, 20),
        Header = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(240, 240, 240),
        Transparency = 0.1, -- 0-1
        RainbowSpeed = 0.5
    },
    Folder = "TitanConfig"
}

Titan.Flags = {}
Titan.Open = true

--// Utility Functions
local function PlaySound(id, vol)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 1
    s.PlayOnRemove = true
    s.Parent = game:GetService("SoundService")
    s:Destroy()
end

local function Create(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    return inst
end

local function MakeDraggable(topbarObject, object)
    local dragging, dragInput, dragStart, startPos
    topbarObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = object.Position
        end
    end)
    topbarObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            TweenService:Create(object, TweenInfo.new(0.05), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

--// Config System Implementation
local function SaveToFile(name, data)
    if not writefile then return end
    local json = HttpService:JSONEncode(data)
    if not isfolder(Titan.Settings.Folder) then makefolder(Titan.Settings.Folder) end
    writefile(Titan.Settings.Folder .. "/" .. name .. ".json", json)
end

local function LoadFromFile(name)
    if not readfile then return nil end
    local path = Titan.Settings.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

local function TriggerConfigFlash(color)
    -- This creates a full screen flashbang effect
    PlaySound(ASSETS.Sounds.ConfigLoad, 2)
    
    local Flash = Create("Frame", {
        Name = "FlashBang",
        Parent = Viewport:FindFirstChild("TitanGui") or Viewport,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.3,
        ZIndex = 99999
    })
    
    local Correction = Create("ColorCorrectionEffect", {
        Parent = game:GetService("Lighting"),
        TintColor = color,
        Brightness = 0.5
    })

    TweenService:Create(Flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Correction, TweenInfo.new(0.6), {TintColor = Color3.new(1,1,1), Brightness = 0}):Play()
    
    task.delay(0.6, function() 
        Flash:Destroy()
        Correction:Destroy()
    end)
end

--// Main Window Creator
function Titan:Window(options)
    options = options or {}
    Titan.Settings.Name = options.Name or Titan.Settings.Name
    Titan.Settings.Theme.Main = options.ThemeColor or Titan.Settings.Theme.Main
    
    local ConfigSystem = {} -- Forward declaration

    -- GUI Base
    local ScreenGui = Create("ScreenGui", {
        Name = "TitanGui",
        Parent = Viewport,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })

    local MainFrame = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 0, 0, 0), -- Start small for animation
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Titan.Settings.Theme.Background,
        BackgroundTransparency = Titan.Settings.Theme.Transparency,
        ClipsDescendants = false, -- Allow glow
        Parent = ScreenGui
    })
    
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})

    -- Rainbow Border Logic
    local Stroke = Create("UIStroke", {
        Parent = MainFrame,
        Thickness = 2,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.new(1,1,1) -- Placeholder
    })
    
    local Gradient = Create("UIGradient", {
        Parent = Stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
        })
    })

    -- Animate Rainbow
    task.spawn(function()
        local rot = 0
        while MainFrame.Parent do
            rot = (rot + Titan.Settings.Theme.RainbowSpeed) % 360
            Gradient.Rotation = rot
            RunService.Heartbeat:Wait()
        end
    end)

    -- Intro Animation
    local IntroText = Create("TextLabel", {
        Parent = ScreenGui,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Titan.Settings.Theme.Main,
        TextSize = 30,
        Font = ASSETS.Font
    })

    PlaySound(ASSETS.Sounds.Intro)
    
    -- Decode Effect
    local targetText = "INITIALIZING " .. string.upper(Titan.Settings.Name) .. "..."
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*"
    for i = 1, #targetText do
        IntroText.Text = string.sub(targetText, 1, i) .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
        task.wait(0.02)
    end
    IntroText.Text = targetText
    task.wait(0.5)
    
    TweenService:Create(IntroText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.3)
    IntroText:Destroy()
    
    -- Open Window
    TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 650, 0, 420)
    }):Play()

    -- Elements Container
    local TopBar = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1
    })
    MakeDraggable(TopBar, MainFrame)

    local Title = Create("TextLabel", {
        Parent = TopBar,
        Text = Titan.Settings.Name .. " <font color=\"#888\">//</font> V2",
        RichText = true,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Titan.Settings.Theme.Main,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = ASSETS.Font,
        TextSize = 16
    })

    local ContentArea = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = Color3.fromRGB(10, 10, 12),
        BackgroundTransparency = 0.5
    })
    Create("UICorner", {Parent = ContentArea, CornerRadius = UDim.new(0, 6)})

    -- Tab System
    local TabContainer = Create("ScrollingFrame", {
        Parent = ContentArea,
        Size = UDim2.new(0, 130, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0
    })
    local TabList = Create("UIListLayout", {Parent = TabContainer, Padding = UDim.new(0, 5)})
    
    local PageContainer = Create("Frame", {
        Parent = ContentArea,
        Size = UDim2.new(1, -145, 1, -10),
        Position = UDim2.new(0, 140, 0, 5),
        BackgroundTransparency = 1
    })

    -- Toggle UI Keybind
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            Titan.Open = not Titan.Open
            MainFrame.Visible = Titan.Settings.Open
            if Titan.Open then
                TweenService:Create(MainFrame, TweenInfo.new(0.3), {BackgroundTransparency = Titan.Settings.Theme.Transparency}):Play()
            end
        end
    end)

    local Tabs = {}
    local FirstTab = true

    function Tabs:Tab(name)
        -- Tab Button
        local TabBtn = Create("TextButton", {
            Parent = TabContainer,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Titan.Settings.Theme.Header,
            BackgroundTransparency = 0.8,
            Text = name,
            TextColor3 = Color3.fromRGB(150, 150, 150),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 4)})
        
        -- Tab Page
        local Page = Create("ScrollingFrame", {
            Parent = PageContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Titan.Settings.Theme.Main
        })
        Create("UIListLayout", {Parent = Page, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6)})

        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabBtn.TextColor3 = Titan.Settings.Theme.Main
            TabBtn.BackgroundTransparency = 0.5
        end

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(ASSETS.Sounds.Hover)
            for _, v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, TextColor3 = Color3.fromRGB(150,150,150)}):Play()
                end 
            end
            Page.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5, TextColor3 = Titan.Settings.Theme.Main}):Play()
        end)

        local Elements = {}

        -- BUTTON
        function Elements:Button(text, callback)
            local Btn = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Titan.Settings.Theme.Header,
                BackgroundTransparency = 0.3,
                Text = text,
                TextColor3 = Titan.Settings.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 14
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
            
            Btn.MouseButton1Click:Connect(function()
                PlaySound(ASSETS.Sounds.Click)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Titan.Settings.Theme.Main, TextColor3 = Color3.new(0,0,0)}):Play()
                task.delay(0.1, function()
                    TweenService:Create(Btn, TweenInfo.new(0.3), {BackgroundColor3 = Titan.Settings.Theme.Header, TextColor3 = Titan.Settings.Theme.Text}):Play()
                end)
                pcall(callback)
            end)
        end

        -- TOGGLE
        function Elements:Toggle(text, default, callback)
            local toggled = default or false
            Titan.Flags[text] = toggled

            local Frame = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Titan.Settings.Theme.Header,
                BackgroundTransparency = 0.3,
                Text = "",
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 4)})

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = text,
                Size = UDim2.new(0.7, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Titan.Settings.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.Gotham,
                TextSize = 14
            })

            local Indicator = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0.5, -10),
                BackgroundColor3 = toggled and Titan.Settings.Theme.Main or Color3.fromRGB(60,60,60)
            })
            Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})

            Frame.MouseButton1Click:Connect(function()
                PlaySound(ASSETS.Sounds.Click)
                toggled = not toggled
                Titan.Flags[text] = toggled
                
                TweenService:Create(Indicator, TweenInfo.new(0.2), {
                    BackgroundColor3 = toggled and Titan.Settings.Theme.Main or Color3.fromRGB(60,60,60)
                }):Play()
                
                if callback then callback(toggled) end
            end)
            
            -- Allow external updates for config loading
            function Frame:Set(val)
                toggled = val
                Titan.Flags[text] = toggled
                Indicator.BackgroundColor3 = toggled and Titan.Settings.Theme.Main or Color3.fromRGB(60,60,60)
                if callback then callback(toggled) end
            end
            
            return Frame
        end

        -- CIRCULAR COLOR PICKER
        function Elements:ColorPicker(text, default, callback)
            default = default or Color3.fromRGB(255, 255, 255)
            Titan.Flags[text] = {R=default.R, G=default.G, B=default.B}

            local Frame = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 180), -- Taller for picker
                BackgroundColor3 = Titan.Settings.Theme.Header,
                BackgroundTransparency = 0.3
            })
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 4)})

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = text,
                Size = UDim2.new(1, -10, 0, 30),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Titan.Settings.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.Gotham,
                TextSize = 14
            })

            local CurrentColor = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 30, 0, 30),
                Position = UDim2.new(1, -40, 0, 5),
                BackgroundColor3 = default
            })
            Create("UICorner", {Parent = CurrentColor, CornerRadius = UDim.new(0, 6)})

            -- The Wheel
            local Wheel = Create("ImageButton", {
                Parent = Frame,
                Size = UDim2.new(0, 120, 0, 120),
                Position = UDim2.new(0, 20, 0, 40),
                BackgroundTransparency = 1,
                Image = ASSETS.Icons.Paint
            })

            local Cursor = Create("Frame", {
                Parent = Wheel,
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.new(1,1,1),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0) -- Center default
            })
            Create("UICorner", {Parent = Cursor, CornerRadius = UDim.new(1,0)})
            Create("UIStroke", {Parent = Cursor, Thickness = 1})

            -- Hex Input
            local HexBox = Create("TextBox", {
                Parent = Frame,
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(0.6, 0, 0.5, 0),
                BackgroundColor3 = Color3.fromRGB(40,40,45),
                Text = "#" .. default:ToHex(),
                TextColor3 = Color3.new(1,1,1),
                Font = Enum.Font.Code,
                TextSize = 14
            })
            Create("UICorner", {Parent = HexBox, CornerRadius = UDim.new(0,4)})
            
            local dragging = false

            local function UpdateColorFromWheel(input)
                local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize/2)
                local vector = Vector2.new(input.Position.X, input.Position.Y) - center
                local angle = math.atan2(vector.Y, vector.X)
                local radius = math.min(vector.Magnitude, Wheel.AbsoluteSize.X/2)
                
                -- Reposition Cursor
                local cursorX = math.cos(angle) * radius
                local cursorY = math.sin(angle) * radius
                Cursor.Position = UDim2.new(0.5, cursorX, 0.5, cursorY)

                -- Calculate HSV
                local hue = (math.deg(angle) + 180) / 360 -- Adjusted for Roblox rotation
                local sat = radius / (Wheel.AbsoluteSize.X/2)
                local val = 1 -- Simplified V handling
                
                local color = Color3.fromHSV(1 - hue, sat, val)
                
                CurrentColor.BackgroundColor3 = color
                HexBox.Text = "#" .. color:ToHex()
                Titan.Flags[text] = {R=color.R, G=color.G, B=color.B}
                if callback then callback(color) end
            end

            Wheel.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateColorFromWheel(i)
                end
            end)

            HexBox.FocusLost:Connect(function()
                pcall(function()
                    local col = Color3.fromHex(HexBox.Text)
                    CurrentColor.BackgroundColor3 = col
                    if callback then callback(col) end
                end)
            end)
        end

        return Elements
    end

    --// SETTINGS & CONFIG TAB
    local SettingsTab = Tabs:Tab("Settings")
    
    SettingsTab:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    
    SettingsTab:Button("Unload & Close", function()
        PlaySound(ASSETS.Sounds.Click)
        ScreenGui:Destroy()
    end)

    -- Config Section
    local ConfigName = "Default"
    local ConfigBox = Create("TextBox", {
        Parent = SettingsTab.Page, -- Hacky access to page
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40,40,45),
        Text = "ConfigName",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Parent = nil -- Will add via custom method if needed, but for now we append manually
    })
    
    -- Need to manually add the text box to the settings page since our Button function doesn't return the page
    -- Adding a custom Textbox element for Config Name
    local NameInput = Create("TextBox", {
        Parent = SettingsTab.Page, -- Internal access
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Titan.Settings.Theme.Header,
        Text = "default",
        TextColor3 = Color3.new(1,1,1),
        PlaceholderText = "Config Name...",
        Font = Enum.Font.Gotham
    })
    Create("UICorner", {Parent = NameInput, CornerRadius = UDim.new(0,4)})
    
    NameInput:GetPropertyChangedSignal("Text"):Connect(function()
        ConfigName = NameInput.Text
    end)

    local AutoLoadToggle = SettingsTab:Toggle("Auto Load This Config", false, function(val)
        if val and writefile then
            writefile(Titan.Settings.Folder .. "/autoload.txt", ConfigName)
        elseif not val and isfile(Titan.Settings.Folder .. "/autoload.txt") then
            delfile(Titan.Settings.Folder .. "/autoload.txt")
        end
    end)

    SettingsTab:Button("Save Config", function()
        -- Collect Flags
        SaveToFile(ConfigName, Titan.Flags)
        PlaySound(ASSETS.Sounds.Click)
    end)

    SettingsTab:Button("Load Config", function()
        local data = LoadFromFile(ConfigName)
        if data then
            -- Flash Effect
            TriggerConfigFlash(Titan.Settings.Theme.Main)
            
            -- Apply Data (This is a simplified apply, in real usage you bind this to elements)
            -- For demonstration, we just update the stored flags
            for k,v in pairs(data) do
                Titan.Flags[k] = v
                -- In a full system, you would iterate elements and call :Set(v)
            end
        else
            PlaySound(ASSETS.Sounds.Error)
        end
    end)

    -- Auto Load Logic
    task.delay(1, function()
        if isfile and isfile(Titan.Settings.Folder .. "/autoload.txt") then
            local autoName = readfile(Titan.Settings.Folder .. "/autoload.txt")
            NameInput.Text = autoName
            ConfigName = autoName
            
            local data = LoadFromFile(autoName)
            if data then
                TriggerConfigFlash(Titan.Settings.Theme.Main)
                AutoLoadToggle:Set(true)
            end
        end
    end)

    return Tabs
end

return Titan
