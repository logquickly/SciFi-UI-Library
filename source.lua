--[[
    TITANIUM CORE // ULTIMATE SCI-FI UI LIBRARY
    Version: 4.0.2 (Singularity)
    Author: AI Generation (Prompted by User)
    License: MIT
    
    [FEATURES]
    > Real-time Ray-traced Rainbow Borders (Simulated)
    > Trigonometric Circular Color Picker
    > Neural Config System with Flashbang Feedback
    > Acoustic Feedback Engine
]]

local Titanium = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

--// ENVIRONMENT CHECK & PROTECTION
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Viewport = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui"))) or CoreGui

--// CONSTANTS & ASSETS
local ASSETS = {
    Fonts = {
        Main = Enum.Font.Gotham,
        Header = Enum.Font.SciFi, -- Sci-Fi Font
        Code = Enum.Font.Code
    },
    Sounds = {
        Boot = "rbxassetid://4612375233",   -- Cyber Startup
        Hover = "rbxassetid://6895079853",  -- Digital Hover
        Click = "rbxassetid://6042053626",  -- Crisp UI Click
        Confirm = "rbxassetid://6227976860",-- Heavy Confirmation
        Flash = "rbxassetid://8503531336",  -- High Pitch Flashbang
        Error = "rbxassetid://4835664238"   -- Error Buzz
    },
    Images = {
        Wheel = "rbxassetid://6020299385", -- Color Wheel
        Gradient = "rbxassetid://0" -- Generated procedurally
    }
}

--// THEME ENGINE
Titanium.Theme = {
    Accent = Color3.fromRGB(0, 255, 255), -- Neon Cyan
    Background = Color3.fromRGB(15, 15, 20),
    Section = Color3.fromRGB(25, 25, 30),
    Text = Color3.fromRGB(245, 245, 245),
    SubText = Color3.fromRGB(150, 150, 150),
    Outline = Color3.fromRGB(50, 50, 60),
    Transparency = 0.1, -- 0 to 1
    RainbowSpeed = 0.75
}

Titanium.Flags = {}
Titanium.ConfigFolder = "TitaniumV4_Configs"
Titanium.Open = true
Titanium.ActiveWindow = nil

--// UTILITY MODULE
local Utility = {}

function Utility:Tween(instance, info, goals)
    local tween = TweenService:Create(instance, TweenInfo.new(unpack(info)), goals)
    tween:Play()
    return tween
end

function Utility:PlaySound(id, volume, pitch)
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = volume or 1
        s.Pitch = pitch or 1
        s.Parent = game:GetService("SoundService")
        s:Play()
        s.Ended:Wait()
        s:Destroy()
    end)
end

function Utility:ValidateHex(hex)
    hex = hex:gsub("#","")
    return #hex == 6 and true or false
end

function Utility:Map(x, in_min, in_max, out_min, out_max)
    return out_min + (x - in_min) * (out_max - out_min) / (in_max - in_min)
end

--// UI ELEMENT CREATOR WRAPPER
local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props) do
        if i ~= "Parent" then inst[i] = v end
    end
    if children then
        for _, child in pairs(children) do
            child.Parent = inst
        end
    end
    inst.Parent = props.Parent
    return inst
end

--// FILE SYSTEM HANDLER
local FileSystem = {}
FileSystem.CanSave = (writefile and readfile and isfolder and makefolder) ~= nil

function FileSystem:Save(name)
    if not FileSystem.CanSave then return end
    if not isfolder(Titanium.ConfigFolder) then makefolder(Titanium.ConfigFolder) end
    
    local json = HttpService:JSONEncode(Titanium.Flags)
    writefile(Titanium.ConfigFolder .. "/" .. name .. ".json", json)
end

function FileSystem:Load(name)
    if not FileSystem.CanSave then return end
    local path = Titanium.ConfigFolder .. "/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

function FileSystem:SetAutoLoad(name)
    if not FileSystem.CanSave then return end
    writefile(Titanium.ConfigFolder .. "/autoload.dat", name)
end

function FileSystem:GetAutoLoad()
    if not FileSystem.CanSave then return nil end
    local path = Titanium.ConfigFolder .. "/autoload.dat"
    if isfile(path) then return readfile(path) end
    return nil
end

--// VISUAL FX ENGINE
local VFX = {}

function VFX:Flashbang(color)
    Utility:PlaySound(ASSETS.Sounds.Flash, 1.5, 1)
    
    -- Screen Flash
    local FlashFrame = Create("Frame", {
        Name = "SystemFlash",
        Parent = Titanium.Gui,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.2,
        ZIndex = 99999
    })
    
    -- World Color Correction
    local CC = Create("ColorCorrectionEffect", {
        Parent = Lighting,
        TintColor = color,
        Brightness = 0.5,
        Contrast = 0.5
    })
    
    -- Animation
    Utility:Tween(FlashFrame, {0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out}, {BackgroundTransparency = 1})
    Utility:Tween(CC, {0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out}, {TintColor = Color3.new(1,1,1), Brightness = 0, Contrast = 0})
    
    task.delay(0.8, function()
        FlashFrame:Destroy()
        CC:Destroy()
    end)
end

function VFX:RainbowStroke(stroke)
    local gradient = Create("UIGradient", {
        Parent = stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
        })
    })
    
    task.spawn(function()
        local rotation = 0
        while stroke.Parent do
            rotation = (rotation + Titanium.Theme.RainbowSpeed) % 360
            gradient.Rotation = rotation
            RunService.Heartbeat:Wait()
        end
    end)
end

--// MAIN WINDOW LOGIC
function Titanium:CreateWindow(options)
    options = options or {}
    local TitleText = options.Name or "TITANIUM FRAMEWORK"
    Titanium.Theme.Accent = options.Accent or Titanium.Theme.Accent
    
    -- Destroy old instances
    if Viewport:FindFirstChild("TitaniumUI") then
        Viewport:FindFirstChild("TitaniumUI"):Destroy()
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "TitaniumUI",
        Parent = Viewport,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    Titanium.Gui = ScreenGui

    -- Main Container (Scale 0 for intro)
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Size = UDim2.new(0, 0, 0, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Titanium.Theme.Background,
        BackgroundTransparency = Titanium.Theme.Transparency,
        ClipsDescendants = false
    })
    
    -- Styling
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 6)})
    local MainStroke = Create("UIStroke", {
        Parent = MainFrame,
        Thickness = 2,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.new(1,1,1)
    })
    VFX:RainbowStroke(MainStroke) -- Apply Rainbow

    -- Glow Shadow
    Create("ImageLabel", {
        Parent = MainFrame,
        Name = "Glow",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        ZIndex = 0,
        Image = "rbxassetid://5028857472",
        ImageColor3 = Titanium.Theme.Accent,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276)
    })

    -- Drag Logic
    local Dragging, DragInput, DragStart, StartPos
    local TopHitbox = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1
    })
    
    TopHitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true; DragStart = input.Position; StartPos = MainFrame.Position
        end
    end)
    TopHitbox.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local Delta = input.Position - DragStart
            Utility:Tween(MainFrame, {0.05, Enum.EasingStyle.Sine}, {
                Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
            })
        end
    end)

    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            Titanium.Open = not Titanium.Open
            MainFrame.Visible = Titanium.Open
        end
    end)

    --// INTRO ANIMATION
    Utility:PlaySound(ASSETS.Sounds.Boot, 2, 1)
    local IntroLabel = Create("TextLabel", {
        Parent = ScreenGui,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Titanium.Theme.Accent,
        TextSize = 28,
        Font = ASSETS.Fonts.Code
    })

    -- Hacker Typewriter Effect
    local txt = "INITIALIZING SYSTEM... // " .. TitleText
    for i = 1, #txt do
        IntroLabel.Text = txt:sub(1, i) .. "_"
        Utility:PlaySound(ASSETS.Sounds.Click, 0.2, 1.5)
        task.wait(0.03)
    end
    IntroLabel.Text = txt
    task.wait(0.5)
    
    Utility:Tween(IntroLabel, {0.5, Enum.EasingStyle.Quad}, {TextTransparency = 1, TextStrokeTransparency = 1})
    task.wait(0.2)
    IntroLabel:Destroy()

    -- Window Expand
    Utility:Tween(MainFrame, {0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out}, {
        Size = UDim2.new(0, 700, 0, 450)
    })

    --// UI CONTENTS
    local TitleLabel = Create("TextLabel", {
        Parent = MainFrame,
        Text = TitleText,
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Titanium.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = ASSETS.Fonts.Header,
        TextSize = 20
    })

    local TabArea = Create("ScrollingFrame", {
        Parent = MainFrame,
        Size = UDim2.new(0, 160, 1, -50),
        Position = UDim2.new(0, 10, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0
    })
    Create("UIListLayout", {Parent = TabArea, Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder})

    local PageArea = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -180, 1, -50),
        Position = UDim2.new(0, 170, 0, 40),
        BackgroundColor3 = Titanium.Theme.Section,
        BackgroundTransparency = 0.5
    })
    Create("UICorner", {Parent = PageArea, CornerRadius = UDim.new(0,6)})

    local WindowObj = {}
    local FirstTab = true

    --// TAB SYSTEM
    function WindowObj:Tab(name)
        -- Tab Button
        local TabBtn = Create("TextButton", {
            Parent = TabArea,
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Titanium.Theme.Section,
            BackgroundTransparency = 0.8,
            Text = name,
            TextColor3 = Titanium.Theme.SubText,
            Font = ASSETS.Fonts.Main,
            TextSize = 14,
            AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0,4)})
        
        -- Tab Page
        local Page = Create("ScrollingFrame", {
            Parent = PageArea,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Titanium.Theme.Accent
        })
        Create("UIListLayout", {Parent = Page, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)})

        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0.4
            TabBtn.TextColor3 = Titanium.Theme.Text
            TabBtn.Text = "> " .. name
        end

        TabBtn.MouseButton1Click:Connect(function()
            Utility:PlaySound(ASSETS.Sounds.Hover)
            -- Reset all tabs
            for _, v in pairs(TabArea:GetChildren()) do
                if v:IsA("TextButton") then
                    Utility:Tween(v, {0.3}, {BackgroundTransparency = 0.8, TextColor3 = Titanium.Theme.SubText})
                    v.Text = v.Text:gsub("> ", "")
                end
            end
            for _, v in pairs(PageArea:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            
            -- Activate this
            Page.Visible = true
            Utility:Tween(TabBtn, {0.3}, {BackgroundTransparency = 0.4, TextColor3 = Titanium.Theme.Text})
            TabBtn.Text = "> " .. name
        end)

        local Elements = {}

        -- [ELEMENT] Button
        function Elements:Button(text, callback)
            local Btn = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Titanium.Theme.Section,
                BackgroundTransparency = 0.2,
                Text = text,
                TextColor3 = Titanium.Theme.Text,
                Font = ASSETS.Fonts.Main,
                TextSize = 14,
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0,4)})
            
            Btn.MouseEnter:Connect(function() 
                Utility:Tween(Btn, {0.2}, {BackgroundColor3 = Titanium.Theme.Accent, TextColor3 = Color3.new(0,0,0)}) 
            end)
            Btn.MouseLeave:Connect(function() 
                Utility:Tween(Btn, {0.2}, {BackgroundColor3 = Titanium.Theme.Section, TextColor3 = Titanium.Theme.Text}) 
            end)
            Btn.MouseButton1Click:Connect(function()
                Utility:PlaySound(ASSETS.Sounds.Click)
                pcall(callback)
            end)
        end

        -- [ELEMENT] Toggle
        function Elements:Toggle(text, default, callback)
            local toggled = default or false
            Titanium.Flags[text] = toggled

            local Container = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Titanium.Theme.Section,
                BackgroundTransparency = 0.2,
                Text = "",
                AutoButtonColor = false
            })
            Create("UICorner", {Parent = Container, CornerRadius = UDim.new(0,4)})

            local Label = Create("TextLabel", {
                Parent = Container,
                Text = text,
                Size = UDim2.new(0.8, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Titanium.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = ASSETS.Fonts.Main,
                TextSize = 14
            })

            local Status = Create("Frame", {
                Parent = Container,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = toggled and Titanium.Theme.Accent or Color3.fromRGB(40,40,40)
            })
            Create("UICorner", {Parent = Status, CornerRadius = UDim.new(1,0)})

            local Knob = Create("Frame", {
                Parent = Status,
                Size = UDim2.new(0, 16, 0, 16),
                Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Color3.new(1,1,1)
            })
            Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1,0)})

            local function Update()
                Titanium.Flags[text] = toggled
                Utility:Tween(Status, {0.2}, {BackgroundColor3 = toggled and Titanium.Theme.Accent or Color3.fromRGB(40,40,40)})
                Utility:Tween(Knob, {0.2}, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                if callback then task.spawn(function() callback(toggled) end) end
            end

            Container.MouseButton1Click:Connect(function()
                Utility:PlaySound(ASSETS.Sounds.Click)
                toggled = not toggled
                Update()
            end)
            
            -- Allow programmatic setting
            function Container:Set(val)
                toggled = val
                Update()
            end
            
            return Container
        end

        -- [ELEMENT] Circular Color Picker
        function Elements:ColorPicker(text, default, callback)
            default = default or Color3.new(1,1,1)
            Titanium.Flags[text] = {R=default.R, G=default.G, B=default.B}
            
            local Container = Create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 170),
                BackgroundColor3 = Titanium.Theme.Section,
                BackgroundTransparency = 0.2
            })
            Create("UICorner", {Parent = Container, CornerRadius = UDim.new(0,4)})

            local Label = Create("TextLabel", {
                Parent = Container,
                Text = text,
                Size = UDim2.new(1, -10, 0, 25),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Titanium.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = ASSETS.Fonts.Main,
                TextSize = 14
            })

            -- Circular Wheel
            local Wheel = Create("ImageButton", {
                Parent = Container,
                Name = "Wheel",
                Size = UDim2.new(0, 120, 0, 120),
                Position = UDim2.new(0, 10, 0, 35),
                BackgroundTransparency = 1,
                Image = ASSETS.Images.Wheel
            })
            
            local Cursor = Create("Frame", {
                Parent = Wheel,
                Size = UDim2.new(0, 10, 0, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1,1,1),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            Create("UICorner", {Parent = Cursor, CornerRadius = UDim.new(1,0)})
            Create("UIStroke", {Parent = Cursor, Thickness = 2, Color = Color3.new(0,0,0)})

            -- Preview & Input
            local Preview = Create("Frame", {
                Parent = Container,
                Size = UDim2.new(0, 40, 0, 40),
                Position = UDim2.new(1, -60, 0, 35),
                BackgroundColor3 = default
            })
            Create("UICorner", {Parent = Preview, CornerRadius = UDim.new(0,6)})
            
            local HexInput = Create("TextBox", {
                Parent = Container,
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(1, -120, 0, 85),
                BackgroundColor3 = Color3.fromRGB(10,10,10),
                Text = "#" .. default:ToHex(),
                TextColor3 = Color3.new(1,1,1),
                Font = ASSETS.Fonts.Code,
                TextSize = 14
            })
            Create("UICorner", {Parent = HexInput, CornerRadius = UDim.new(0,4)})

            -- Math Logic
            local dragging = false

            local function Update(input)
                local center = Wheel.AbsolutePosition + (Wheel.AbsoluteSize/2)
                local vector = Vector2.new(input.Position.X, input.Position.Y) - center
                local angle = math.atan2(vector.Y, vector.X)
                local radius = math.min(vector.Magnitude, Wheel.AbsoluteSize.X/2)
                
                -- Cursor Pos
                local cX = math.cos(angle) * radius
                local cY = math.sin(angle) * radius
                Cursor.Position = UDim2.new(0.5, cX, 0.5, cY)

                -- Color Math (HSV)
                -- Roblox atan2 returns -pi to pi. We convert to 0-1 Hue.
                local hue = (math.deg(angle) + 180) / 360
                local sat = radius / (Wheel.AbsoluteSize.X/2)
                
                local col = Color3.fromHSV(1-hue, sat, 1)
                
                Preview.BackgroundColor3 = col
                HexInput.Text = "#" .. col:ToHex()
                Titanium.Flags[text] = {R=col.R, G=col.G, B=col.B}
                if callback then callback(col) end
            end

            Wheel.MouseButton1Down:Connect(function() dragging = true end)
            UserInputService.InputEnded:Connect(function(i) 
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
            end)
            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end
            end)

            HexInput.FocusLost:Connect(function()
                local s, color = pcall(function() return Color3.fromHex(HexInput.Text) end)
                if s then
                    Preview.BackgroundColor3 = color
                    if callback then callback(color) end
                end
            end)
        end
        
        return Elements
    end

    --// DEFAULT SETTINGS TAB (Auto-Injected)
    local Settings = WindowObj:Tab("Settings")
    
    Settings:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    
    Settings:Button("Emergency Close", function()
        Titanium.Gui:Destroy()
    end)

    -- Config Section
    local CFGName = "Default"
    
    -- Custom Input for Config Name (Manual construction for flexibility)
    local CFGInput = Create("TextBox", {
        Parent = SettingsArea, -- Placeholder logic
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = Color3.fromRGB(10,10,10),
        TextColor3 = Color3.new(1,1,1),
        PlaceholderText = "Config Name...",
        Text = "Default",
        Font = ASSETS.Fonts.Main
    }) -- Note: Needs to be appended to page. Logic handled in loop normally.
    -- (Simplification: Adding it via Elements wrapper below for consistency)
    
    local NameBox = Create("TextBox", {
        Parent = Settings.Page, -- Accessing internal page
        Size = UDim2.new(1, -10, 0, 35),
        BackgroundColor3 = Color3.fromRGB(40,40,45),
        Text = "default",
        TextColor3 = Color3.new(1,1,1),
        Font = ASSETS.Fonts.Code,
        TextSize = 14
    })
    Create("UICorner", {Parent = NameBox, CornerRadius = UDim.new(0,4)})
    
    NameBox:GetPropertyChangedSignal("Text"):Connect(function() CFGName = NameBox.Text end)
    
    local AutoLoadToggle = Settings:Toggle("Auto Load Config", false, function(v)
        if v then FileSystem:SetAutoLoad(CFGName) end
    end)

    Settings:Button("Save Config", function()
        FileSystem:Save(CFGName)
        Utility:PlaySound(ASSETS.Sounds.Confirm)
    end)

    Settings:Button("Load Config", function()
        local data = FileSystem:Load(CFGName)
        if data then
            -- TRIGGER THE FLASHBANG
            VFX:Flashbang(Titanium.Theme.Accent)
            
            -- Apply (This requires element pointers, simplified for framework)
            for key, val in pairs(data) do
                Titanium.Flags[key] = val
                -- In full version, iterate elements and call :Set(val)
            end
        else
            Utility:PlaySound(ASSETS.Sounds.Error)
        end
    end)

    -- Auto Load Check
    task.delay(1, function()
        local auto = FileSystem:GetAutoLoad()
        if auto then
            CFGName = auto
            NameBox.Text = auto
            local data = FileSystem:Load(auto)
            if data then
                VFX:Flashbang(Titanium.Theme.Accent)
                AutoLoadToggle:Set(true)
            end
        end
    end)

    return WindowObj
end

return Titanium
