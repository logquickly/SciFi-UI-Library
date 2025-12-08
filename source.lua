--[[
    TITANIUM CORE V5 // MOBILE EDITION
    [Features]
    > Mobile Draggable Toggle Button
    > Responsive UI Scaling
    > Built-in System Settings (Transparency, Fonts, Audio)
    > Player Join/Leave Detection
    > Reactive Theme Engine
]]

local Titanium = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// PLATFORM DETECTION
local IsMobile = UserInputService.TouchEnabled
local Viewport = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui"))) or CoreGui

--// ASSETS & CONSTANTS
local ASSETS = {
    Fonts = { Main = Enum.Font.Gotham, Code = Enum.Font.Code, Header = Enum.Font.SciFi },
    Sounds = {
        Boot = "rbxassetid://4612375233",
        Hover = "rbxassetid://6895079853",
        Click = "rbxassetid://6042053626",
        Confirm = "rbxassetid://6227976860",
        Flash = "rbxassetid://8503531336",
        Join = "rbxassetid://5153733766", -- Subtle sci-fi notification
        Leave = "rbxassetid://5153733766"
    },
    Images = {
        Wheel = "rbxassetid://6020299385",
        MobileIcon = "rbxassetid://6031068433" -- Menu Icon
    }
}

--// THEME ENGINE (REACTIVE)
Titanium.Theme = {
    Accent = Color3.fromRGB(0, 255, 220),
    Background = Color3.fromRGB(15, 15, 20),
    Section = Color3.fromRGB(25, 25, 30),
    Text = Color3.fromRGB(240, 240, 240),
    Transparency = 0.1,
    RainbowSpeed = 0.5,
    RainbowEnabled = true
}

Titanium.Flags = {
    ["__System_JoinSound"] = false,
    ["__System_Transparency"] = 0.1
}
Titanium.Open = true
Titanium.Gui = nil

--// UTILITY FUNCTIONS
local function PlaySound(id, vol)
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = vol or 1
        s.Parent = game:GetService("SoundService")
        s:Play()
        s.Ended:Wait()
        s:Destroy()
    end)
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props) do
        if i ~= "Parent" then inst[i] = v end
    end
    if children then
        for _, c in pairs(children) do c.Parent = inst end
    end
    inst.Parent = props.Parent
    return inst
end

local function MakeDraggable(guiObject, dragTarget)
    dragTarget = dragTarget or guiObject
    local dragging, dragInput, dragStart, startPos
    
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.Position
        end
    end)
    
    guiObject.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            TweenService:Create(dragTarget, TweenInfo.new(0.05), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

--// FILE SYSTEM
local FS = {}
FS.Folder = "Titanium_Config"
FS.CanSave = (writefile and readfile) ~= nil

function FS:Save(name)
    if not FS.CanSave then return end
    if not isfolder(FS.Folder) then makefolder(FS.Folder) end
    writefile(FS.Folder.."/"..name..".json", HttpService:JSONEncode(Titanium.Flags))
end

function FS:Load(name)
    if not FS.CanSave then return end
    local path = FS.Folder.."/"..name..".json"
    if isfile(path) then return HttpService:JSONDecode(readfile(path)) end
end

--// VISUAL FX
local function TriggerFlash(color)
    PlaySound(ASSETS.Sounds.Flash, 1.5)
    local Flash = Create("Frame", {Parent=Titanium.Gui, Size=UDim2.new(1,0,1,0), BackgroundColor3=color, BackgroundTransparency=0.3, ZIndex=9999})
    TweenService:Create(Flash, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
    task.delay(0.8, function() Flash:Destroy() end)
end

--// MAIN LIBRARY LOGIC
function Titanium:Window(options)
    Titanium.Theme.Accent = options.Accent or Titanium.Theme.Accent
    local Title = options.Name or "TITANIUM"

    if Viewport:FindFirstChild("TitanUI") then Viewport:FindFirstChild("TitanUI"):Destroy() end
    local Screen = Create("ScreenGui", {Name="TitanUI", Parent=Viewport, ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Global})
    Titanium.Gui = Screen

    -- 1. MOBILE TOGGLE BUTTON
    local ToggleBtn = Create("ImageButton", {
        Name = "MobileToggle",
        Parent = Screen,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.1, 0, 0.1, 0), -- Default position
        BackgroundColor3 = Titanium.Theme.Section,
        Image = ASSETS.Images.MobileIcon,
        ImageColor3 = Titanium.Theme.Accent
    })
    Create("UICorner", {Parent=ToggleBtn, CornerRadius=UDim.new(1,0)})
    Create("UIStroke", {Parent=ToggleBtn, Color=Titanium.Theme.Accent, Thickness=2})
    MakeDraggable(ToggleBtn) -- Allow moving the icon

    -- 2. MAIN FRAME (Responsive)
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = Screen,
        Size = UDim2.new(0, 0, 0, 0), -- Intro Scale
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Titanium.Theme.Background,
        BackgroundTransparency = Titanium.Theme.Transparency,
        ClipsDescendants = false
    })
    Create("UICorner", {Parent=MainFrame, CornerRadius=UDim.new(0, 8)})

    -- Rainbow Gradient Border
    local Stroke = Create("UIStroke", {Parent=MainFrame, Thickness=2, Color=Color3.new(1,1,1)})
    local Gradient = Create("UIGradient", {
        Parent = Stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,255))
        })
    })

    -- Animation Loop
    task.spawn(function()
        local rot = 0
        while MainFrame.Parent do
            if Titanium.Theme.RainbowEnabled then
                rot = (rot + Titanium.Theme.RainbowSpeed) % 360
                Gradient.Rotation = rot
                Gradient.Enabled = true
            else
                Gradient.Enabled = false
                Stroke.Color = Titanium.Theme.Accent
            end
            RunService.Heartbeat:Wait()
        end
    end)

    -- Toggle Logic
    local function ToggleUI()
        Titanium.Open = not Titanium.Open
        MainFrame.Visible = Titanium.Open
        PlaySound(ASSETS.Sounds.Click)
    end
    ToggleBtn.MouseButton1Click:Connect(ToggleUI)
    UserInputService.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.RightControl then ToggleUI() end end)

    -- Intro Animation
    local TargetSize = IsMobile and UDim2.new(0.85, 0, 0.6, 0) or UDim2.new(0, 650, 0, 420)
    PlaySound(ASSETS.Sounds.Boot)
    TweenService:Create(MainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {Size=TargetSize}):Play()

    -- UI Structure
    local TopBar = Create("Frame", {Parent=MainFrame, Size=UDim2.new(1,0,0,40), BackgroundTransparency=1})
    MakeDraggable(TopBar, MainFrame)
    
    local TitleLbl = Create("TextLabel", {
        Parent = TopBar,
        Text = Title .. " //",
        Size = UDim2.new(0.5,0,1,0), Position=UDim2.new(0,15,0,0),
        BackgroundTransparency=1, TextColor3=Titanium.Theme.Accent,
        Font=ASSETS.Fonts.Header, TextSize=18, TextXAlignment=Enum.TextXAlignment.Left
    })

    local TabContainer = Create("ScrollingFrame", {
        Parent=MainFrame, Size=UDim2.new(0,140,1,-50), Position=UDim2.new(0,10,0,45),
        BackgroundTransparency=1, ScrollBarThickness=0
    })
    Create("UIListLayout", {Parent=TabContainer, Padding=UDim.new(0,5)})

    local PageContainer = Create("Frame", {
        Parent=MainFrame, Size=UDim2.new(1,-160,1,-50), Position=UDim2.new(0,150,0,45),
        BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.5
    })
    Create("UICorner", {Parent=PageContainer, CornerRadius=UDim.new(0,6)})

    -- Reactive Update Function (Applies settings to all existing UI)
    local function UpdateAllUI()
        MainFrame.BackgroundTransparency = Titanium.Theme.Transparency
        TitleLbl.TextColor3 = Titanium.Theme.Accent
        ToggleBtn.ImageColor3 = Titanium.Theme.Accent
        ToggleBtn.UIStroke.Color = Titanium.Theme.Accent
        
        -- Loop through buttons to update text color
        for _, obj in pairs(Screen:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if obj.Name ~= "Icon" then -- Ignore icons
                     -- Only update non-highlighted text
                     if obj.TextColor3 == Titanium.Theme.Text then 
                         -- Keep logic simple: if we add color picker for text, we map here
                     end
                end
            end
        end
    end

    local Library = {}
    
    function Library:Tab(name)
        local TabBtn = Create("TextButton", {
            Parent=TabContainer, Size=UDim2.new(1,0,0,35),
            BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.8,
            Text=name, TextColor3=Color3.fromRGB(150,150,150),
            Font=ASSETS.Fonts.Main, TextSize=14
        })
        Create("UICorner", {Parent=TabBtn, CornerRadius=UDim.new(0,4)})
        
        local Page = Create("ScrollingFrame", {
            Parent=PageContainer, Size=UDim2.new(1,0,1,0), Visible=false,
            BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=Titanium.Theme.Accent
        })
        Create("UIListLayout", {Parent=Page, Padding=UDim.new(0,5)})
        Create("UIPadding", {Parent=Page, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10)})

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(ASSETS.Sounds.Hover)
            for _,v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible=false end end
            for _,v in pairs(TabContainer:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.2), {TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=0.8}):Play()
                end 
            end
            Page.Visible=true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3=Titanium.Theme.Accent, BackgroundTransparency=0.4}):Play()
        end)

        local Elements = {}
        
        function Elements:Button(text, callback)
            local Btn = Create("TextButton", {
                Parent=Page, Size=UDim2.new(1,-10,0,38),
                BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3,
                Text=text, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Main, TextSize=14
            })
            Create("UICorner", {Parent=Btn, CornerRadius=UDim.new(0,4)})
            Btn.MouseButton1Click:Connect(function() PlaySound(ASSETS.Sounds.Click); pcall(callback) end)
        end

        function Elements:Toggle(text, default, callback)
            Titanium.Flags[text] = default
            local Cont = Create("TextButton", {
                Parent=Page, Size=UDim2.new(1,-10,0,38),
                BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3,
                Text="", AutoButtonColor=false
            })
            Create("UICorner", {Parent=Cont, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {
                Parent=Cont, Text=text, Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0,10,0,0),
                BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, TextXAlignment=0, Font=ASSETS.Fonts.Main, TextSize=14
            })
            local Status = Create("Frame", {
                Parent=Cont, Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-30,0.5,-10),
                BackgroundColor3 = default and Titanium.Theme.Accent or Color3.fromRGB(50,50,50)
            })
            Create("UICorner", {Parent=Status, CornerRadius=UDim.new(0,4)})
            
            local function Update()
                local val = Titanium.Flags[text]
                TweenService:Create(Status, TweenInfo.new(0.2), {BackgroundColor3 = val and Titanium.Theme.Accent or Color3.fromRGB(50,50,50)}):Play()
                if callback then callback(val) end
            end
            Cont.MouseButton1Click:Connect(function() 
                PlaySound(ASSETS.Sounds.Click)
                Titanium.Flags[text] = not Titanium.Flags[text]
                Update()
            end)
            function Cont:Set(v) Titanium.Flags[text] = v; Update() end
            return Cont
        end

        function Elements:Slider(text, min, max, default, callback)
            Titanium.Flags[text] = default
            local Cont = Create("Frame", {
                Parent=Page, Size=UDim2.new(1,-10,0,50),
                BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3
            })
            Create("UICorner", {Parent=Cont, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {
                Parent=Cont, Text=text, Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,10,0,5),
                BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, TextXAlignment=0, Font=ASSETS.Fonts.Main
            })
            local ValLbl = Create("TextLabel", {
                Parent=Cont, Text=tostring(default), Size=UDim2.new(0,50,0,20), Position=UDim2.new(1,-60,0,5),
                BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, TextXAlignment=2, Font=ASSETS.Fonts.Code
            })
            local Bar = Create("Frame", {Parent=Cont, Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,35), BackgroundColor3=Color3.fromRGB(10,10,10)}); Create("UICorner", {Parent=Bar, CornerRadius=UDim.new(1,0)})
            local Fill = Create("Frame", {Parent=Bar, Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3=Titanium.Theme.Accent}); Create("UICorner", {Parent=Fill, CornerRadius=UDim.new(1,0)})
            
            local dragging = false
            local function Update(input)
                local SizeX = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local Val = math.floor(min + ((max-min) * SizeX) * 10) / 10 -- 1 Decimal
                Fill.Size = UDim2.new(SizeX, 0, 1, 0)
                ValLbl.Text = tostring(Val)
                Titanium.Flags[text] = Val
                if callback then callback(Val) end
            end
            Cont.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; Update(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Update(i) end end)
        end

        function Elements:ColorPicker(text, default, callback)
            Titanium.Flags[text] = {R=default.R, G=default.G, B=default.B}
            local Cont = Create("Frame", {Parent=Page, Size=UDim2.new(1,-10,0,160), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3}); Create("UICorner", {Parent=Cont, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {Parent=Cont, Text=text, Size=UDim2.new(1,0,0,25), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, TextXAlignment=0, Font=ASSETS.Fonts.Main})
            local Wheel = Create("ImageButton", {Parent=Cont, Size=UDim2.new(0,100,0,100), Position=UDim2.new(0,10,0,30), BackgroundTransparency=1, Image=ASSETS.Images.Wheel})
            local Cursor = Create("Frame", {Parent=Wheel, Size=UDim2.new(0,10,0,10), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.new(1,1,1)}); Create("UICorner", {Parent=Cursor, CornerRadius=UDim.new(1,0)})
            local Preview = Create("Frame", {Parent=Cont, Size=UDim2.new(0,40,0,40), Position=UDim2.new(1,-60,0,30), BackgroundColor3=default}); Create("UICorner", {Parent=Preview, CornerRadius=UDim.new(0,6)})
            
            local down = false
            local function Update(i)
                local c = Wheel.AbsolutePosition+Wheel.AbsoluteSize/2; local v = Vector2.new(i.Position.X,i.Position.Y)-c
                local a = math.atan2(v.Y,v.X); local r = math.min(v.Magnitude, Wheel.AbsoluteSize.X/2)
                Cursor.Position = UDim2.new(0.5, math.cos(a)*r, 0.5, math.sin(a)*r)
                local col = Color3.fromHSV((math.deg(a)+180)/360, r/(Wheel.AbsoluteSize.X/2), 1)
                Preview.BackgroundColor3 = col
                Titanium.Flags[text] = {R=col.R, G=col.G, B=col.B}
                if callback then callback(col) end
            end
            Wheel.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=false end end)
            UserInputService.InputChanged:Connect(function(i) if down and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Update(i) end end)
        end

        return Elements
    end

    --// BUILT-IN SETTINGS TAB (System)
    local Sys = Library:Tab("System Settings")
    
    Sys:Button("Rejoin Server", function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end)
    
    Sys:Button("Close / Unload", function() Screen:Destroy() end)
    
    -- Config System
    local ConfigName = "Default"
    local CfgInput = Create("TextBox", {
        Parent=Sys.Page, Size=UDim2.new(1,-10,0,30),
        BackgroundColor3=Color3.fromRGB(40,40,45), Text="Default",
        TextColor3=Color3.new(1,1,1), PlaceholderText="Config Name"
    })
    Create("UICorner", {Parent=CfgInput, CornerRadius=UDim.new(0,4)})
    CfgInput:GetPropertyChangedSignal("Text"):Connect(function() ConfigName = CfgInput.Text end)

    Sys:Button("Save Config", function() FS:Save(ConfigName); PlaySound(ASSETS.Sounds.Confirm) end)
    Sys:Button("Load Config", function()
        local data = FS:Load(ConfigName)
        if data then
            TriggerFlash(Titanium.Theme.Accent)
            for k,v in pairs(data) do Titanium.Flags[k] = v end
            -- In a real scenario, you'd trigger callbacks here
        end
    end)
    
    -- UI Customization
    Sys:Slider("UI Transparency", 0, 1, 0.1, function(val)
        Titanium.Theme.Transparency = val
        UpdateAllUI()
    end)
    
    Sys:Toggle("Rainbow Border Mode", true, function(val)
        Titanium.Theme.RainbowEnabled = val
    end)
    
    Sys:Toggle("Player Join/Leave Sound", false, function(val)
        Titanium.Flags["__System_JoinSound"] = val
    end)

    Sys:ColorPicker("Font Color", Titanium.Theme.Text, function(col)
        Titanium.Theme.Text = col
        UpdateAllUI()
    end)

    return Library
end

--// PLAYER DETECTION LOGIC (Global)
Players.PlayerAdded:Connect(function(p)
    if Titanium.Flags["__System_JoinSound"] then
        PlaySound(ASSETS.Sounds.Join)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if Titanium.Flags["__System_JoinSound"] then
        PlaySound(ASSETS.Sounds.Leave)
    end
end)

return Titanium
