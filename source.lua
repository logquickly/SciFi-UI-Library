--[[
    TITANIUM CORE V6 // STABLE
    [Changelog]
    > Fixed Config not saving Theme/UI settings
    > Added UI Resizing (UIScale)
    > Added working Font Color Picker
    > Moved Player Detection to separate Tab
]]

local Titanium = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

--// PLATFORM & SAFE GUI
local Viewport = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(Instance.new("ScreenGui"))) or CoreGui
local IsMobile = UserInputService.TouchEnabled

--// ASSETS
local ASSETS = {
    Fonts = { Main = Enum.Font.Gotham, Code = Enum.Font.Code, Header = Enum.Font.SciFi },
    Sounds = {
        Boot = "rbxassetid://4612375233", Click = "rbxassetid://6042053626",
        Confirm = "rbxassetid://6227976860", Flash = "rbxassetid://8503531336",
        Join = "rbxassetid://5153733766", Leave = "rbxassetid://5153733766"
    },
    Images = { Wheel = "rbxassetid://6020299385", MobileIcon = "rbxassetid://6031068433" }
}

--// THEME ENGINE
Titanium.Theme = {
    Accent = Color3.fromRGB(0, 255, 220),
    Background = Color3.fromRGB(15, 15, 20),
    Section = Color3.fromRGB(25, 25, 30),
    Text = Color3.fromRGB(240, 240, 240), -- Main Text Color
    Transparency = 0.1,
    RainbowSpeed = 0.5,
    RainbowEnabled = true,
    Scale = 1.0 -- UI Size
}

Titanium.Flags = {
    ["__System_JoinSound"] = false,
    ["__System_LeaveSound"] = false
}
Titanium.Open = true
Titanium.Gui = nil
Titanium.MainFrame = nil -- Reference for scaling

--// UTILITY
local function PlaySound(id, vol)
    task.spawn(function()
        local s = Instance.new("Sound")
        s.SoundId = id; s.Volume = vol or 1; s.Parent = game:GetService("SoundService")
        s:Play(); s.Ended:Wait(); s:Destroy()
    end)
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props) do if i ~= "Parent" then inst[i] = v end end
    if children then for _, c in pairs(children) do c.Parent = inst end end
    inst.Parent = props.Parent
    return inst
end

local function MakeDraggable(guiObject, dragTarget)
    dragTarget = dragTarget or guiObject
    local dragging, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = dragTarget.Position
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
            dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// FILE SYSTEM (FIXED TO SAVE THEME)
local FS = {}
FS.Folder = "Titanium_Config"
FS.CanSave = (writefile and readfile) ~= nil

function FS:Save(name)
    if not FS.CanSave then return end
    if not isfolder(FS.Folder) then makefolder(FS.Folder) end
    
    local Data = {
        Flags = Titanium.Flags,
        Theme = Titanium.Theme -- Now saves UI settings
    }
    
    writefile(FS.Folder.."/"..name..".json", HttpService:JSONEncode(Data))
end

function FS:Load(name)
    if not FS.CanSave then return nil end
    local path = FS.Folder.."/"..name..".json"
    if isfile(path) then 
        return HttpService:JSONDecode(readfile(path)) 
    end
    return nil
end

--// UI UPDATER
local function UpdateUIAppearance()
    if not Titanium.MainFrame then return end
    
    -- Update Scale
    local Scaler = Titanium.MainFrame:FindFirstChild("UIScale")
    if Scaler then Scaler.Scale = Titanium.Theme.Scale end
    
    -- Update Transparency
    Titanium.MainFrame.BackgroundTransparency = Titanium.Theme.Transparency
    
    -- Update Font Colors (Smart Update)
    for _, obj in pairs(Titanium.MainFrame:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            -- We tag specific elements to NOT update (like Headers or Accents)
            if not obj:GetAttribute("IgnoreTheme") then
                 -- Check if it looks like body text (simplified check)
                 if obj.Font == ASSETS.Fonts.Main then
                    obj.TextColor3 = Titanium.Theme.Text
                 end
            end
        end
    end
end

--// MAIN WINDOW
function Titanium:Window(options)
    Titanium.Theme.Accent = options.Accent or Titanium.Theme.Accent
    local Title = options.Name or "TITANIUM V6"

    if Viewport:FindFirstChild("TitanUI") then Viewport:FindFirstChild("TitanUI"):Destroy() end
    local Screen = Create("ScreenGui", {Name="TitanUI", Parent=Viewport, ResetOnSpawn=false, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Global})
    Titanium.Gui = Screen

    -- 1. MOBILE TOGGLE
    local ToggleBtn = Create("ImageButton", {
        Name = "MobileToggle", Parent = Screen, Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.05, 0, 0.15, 0), BackgroundColor3 = Titanium.Theme.Section,
        Image = ASSETS.Images.MobileIcon, ImageColor3 = Titanium.Theme.Accent
    })
    Create("UICorner", {Parent=ToggleBtn, CornerRadius=UDim.new(1,0)})
    Create("UIStroke", {Parent=ToggleBtn, Color=Titanium.Theme.Accent, Thickness=2})
    MakeDraggable(ToggleBtn)

    -- 2. MAIN FRAME
    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = Screen, Size = UDim2.new(0, 650, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Titanium.Theme.Background, BackgroundTransparency = Titanium.Theme.Transparency,
        ClipsDescendants = false
    })
    Create("UICorner", {Parent=MainFrame, CornerRadius=UDim.new(0, 8)})
    Create("UIScale", {Parent=MainFrame, Scale=Titanium.Theme.Scale}) -- SCALER ADDED
    Titanium.MainFrame = MainFrame

    -- Rainbow Border
    local Stroke = Create("UIStroke", {Parent=MainFrame, Thickness=2, Color=Color3.new(1,1,1)})
    local Gradient = Create("UIGradient", {
        Parent = Stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,255))
        })
    })
    task.spawn(function()
        local r=0
        while MainFrame.Parent do
            if Titanium.Theme.RainbowEnabled then
                r=(r+1)%360; Gradient.Rotation=r; Gradient.Enabled=true
            else
                Gradient.Enabled=false; Stroke.Color=Titanium.Theme.Accent
            end
            RunService.Heartbeat:Wait()
        end
    end)

    -- Intro
    MainFrame.Size = UDim2.new(0,0,0,0)
    PlaySound(ASSETS.Sounds.Boot)
    local TargetSize = IsMobile and UDim2.new(0, 500, 0, 350) or UDim2.new(0, 650, 0, 420)
    TweenService:Create(MainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back), {Size=TargetSize}):Play()

    -- Toggle Logic
    local function ToggleUI()
        Titanium.Open = not Titanium.Open
        MainFrame.Visible = Titanium.Open
    end
    ToggleBtn.MouseButton1Click:Connect(ToggleUI)
    UserInputService.InputBegan:Connect(function(i) if i.KeyCode==Enum.KeyCode.RightControl then ToggleUI() end end)

    -- UI Layout
    local TopBar = Create("Frame", {Parent=MainFrame, Size=UDim2.new(1,0,0,40), BackgroundTransparency=1})
    MakeDraggable(TopBar, MainFrame)
    local TitleLbl = Create("TextLabel", {
        Parent=TopBar, Text=Title.." //", Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,15,0,0),
        BackgroundTransparency=1, TextColor3=Titanium.Theme.Accent, Font=ASSETS.Fonts.Header, TextSize=18, TextXAlignment=0
    })
    TitleLbl:SetAttribute("IgnoreTheme", true) -- Protect Header Color

    local TabCont = Create("ScrollingFrame", {Parent=MainFrame, Size=UDim2.new(0,140,1,-50), Position=UDim2.new(0,10,0,45), BackgroundTransparency=1, ScrollBarThickness=0})
    Create("UIListLayout", {Parent=TabCont, Padding=UDim.new(0,5)})
    local PageCont = Create("Frame", {Parent=MainFrame, Size=UDim2.new(1,-160,1,-50), Position=UDim2.new(0,150,0,45), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.5})
    Create("UICorner", {Parent=PageCont, CornerRadius=UDim.new(0,6)})

    -- ELEMENTS BUILDER
    local Lib = {}
    function Lib:Tab(name)
        local TabBtn = Create("TextButton", {
            Parent=TabCont, Size=UDim2.new(1,0,0,35), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.8,
            Text=name, TextColor3=Color3.fromRGB(150,150,150), Font=ASSETS.Fonts.Main, TextSize=14
        })
        Create("UICorner", {Parent=TabBtn, CornerRadius=UDim.new(0,4)})
        TabBtn:SetAttribute("IgnoreTheme", true) -- Protect Tab Colors

        local Page = Create("ScrollingFrame", {Parent=PageCont, Size=UDim2.new(1,0,1,0), Visible=false, BackgroundTransparency=1, ScrollBarThickness=2})
        Create("UIListLayout", {Parent=Page, Padding=UDim.new(0,5)}); Create("UIPadding", {Parent=Page, PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10)})

        TabBtn.MouseButton1Click:Connect(function()
            PlaySound(ASSETS.Sounds.Click)
            for _,v in pairs(PageCont:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible=false end end
            for _,v in pairs(TabCont:GetChildren()) do 
                if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.2), {TextColor3=Color3.fromRGB(150,150,150), BackgroundTransparency=0.8}):Play() end 
            end
            Page.Visible=true
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3=Titanium.Theme.Accent, BackgroundTransparency=0.4}):Play()
        end)

        local Elems = {}
        function Elems:Button(txt, cb)
            local b = Create("TextButton", {
                Parent=Page, Size=UDim2.new(1,-10,0,38), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3,
                Text=txt, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Main, TextSize=14
            })
            Create("UICorner", {Parent=b, CornerRadius=UDim.new(0,4)})
            b.MouseButton1Click:Connect(function() PlaySound(ASSETS.Sounds.Click); pcall(cb) end)
        end
        function Elems:Toggle(txt, def, cb)
            Titanium.Flags[txt]=def
            local t = Create("TextButton", {Parent=Page, Size=UDim2.new(1,-10,0,38), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3, Text="", AutoButtonColor=false}); Create("UICorner", {Parent=t, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {Parent=t, Text=txt, Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Main, TextSize=14, TextXAlignment=0})
            local st = Create("Frame", {Parent=t, Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-30,0.5,-10), BackgroundColor3=def and Titanium.Theme.Accent or Color3.fromRGB(50,50,50)}); Create("UICorner", {Parent=st, CornerRadius=UDim.new(0,4)})
            
            local function Upd() TweenService:Create(st, TweenInfo.new(0.2), {BackgroundColor3=Titanium.Flags[txt] and Titanium.Theme.Accent or Color3.fromRGB(50,50,50)}):Play() end
            t.MouseButton1Click:Connect(function() PlaySound(ASSETS.Sounds.Click); Titanium.Flags[txt]=not Titanium.Flags[txt]; Upd(); if cb then cb(Titanium.Flags[txt]) end end)
            function t:Set(v) Titanium.Flags[txt]=v; Upd(); if cb then cb(v) end end
            return t
        end
        function Elems:Slider(txt, min, max, def, cb)
            Titanium.Flags[txt]=def
            local f = Create("Frame", {Parent=Page, Size=UDim2.new(1,-10,0,50), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3}); Create("UICorner", {Parent=f, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {Parent=f, Text=txt, Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,10,0,5), BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Main, TextXAlignment=0})
            local val = Create("TextLabel", {Parent=f, Text=tostring(def), Size=UDim2.new(0,50,0,20), Position=UDim2.new(1,-60,0,5), BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Code, TextXAlignment=2})
            local bar = Create("Frame", {Parent=f, Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,35), BackgroundColor3=Color3.fromRGB(10,10,10)}); Create("UICorner", {Parent=bar, CornerRadius=UDim.new(1,0)})
            local fill = Create("Frame", {Parent=bar, Size=UDim2.new((def-min)/(max-min),0,1,0), BackgroundColor3=Titanium.Theme.Accent}); Create("UICorner", {Parent=fill, CornerRadius=UDim.new(1,0)})
            
            local down=false
            local function Upd(i)
                local p = math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
                local v = math.floor(min+((max-min)*p)*10)/10
                fill.Size=UDim2.new(p,0,1,0); val.Text=tostring(v); Titanium.Flags[txt]=v; if cb then cb(v) end
            end
            f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=true; Upd(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=false end end)
            UserInputService.InputChanged:Connect(function(i) if down and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Upd(i) end end)
            
            -- Set Function for external update
            function f:Set(val)
                val = math.clamp(val, min, max)
                local p = (val - min) / (max - min)
                fill.Size=UDim2.new(p,0,1,0); val.Text=tostring(val); Titanium.Flags[txt]=val
            end
            return f
        end
        function Elems:ColorPicker(txt, def, cb)
            Titanium.Flags[txt]={R=def.R,G=def.G,B=def.B}
            local f = Create("Frame", {Parent=Page, Size=UDim2.new(1,-10,0,160), BackgroundColor3=Titanium.Theme.Section, BackgroundTransparency=0.3}); Create("UICorner", {Parent=f, CornerRadius=UDim.new(0,4)})
            Create("TextLabel", {Parent=f, Text=txt, Size=UDim2.new(1,0,0,25), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, TextColor3=Titanium.Theme.Text, Font=ASSETS.Fonts.Main, TextXAlignment=0})
            local w = Create("ImageButton", {Parent=f, Size=UDim2.new(0,100,0,100), Position=UDim2.new(0,10,0,30), BackgroundTransparency=1, Image=ASSETS.Images.Wheel})
            local c = Create("Frame", {Parent=w, Size=UDim2.new(0,10,0,10), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.new(1,1,1)}); Create("UICorner", {Parent=c, CornerRadius=UDim.new(1,0)})
            local p = Create("Frame", {Parent=f, Size=UDim2.new(0,40,0,40), Position=UDim2.new(1,-60,0,30), BackgroundColor3=def}); Create("UICorner", {Parent=p, CornerRadius=UDim.new(0,6)})
            
            local down=false
            local function Upd(i)
                local cp = w.AbsolutePosition+w.AbsoluteSize/2; local v = Vector2.new(i.Position.X,i.Position.Y)-cp
                local a = math.atan2(v.Y,v.X); local r = math.min(v.Magnitude, w.AbsoluteSize.X/2)
                c.Position = UDim2.new(0.5,math.cos(a)*r,0.5,math.sin(a)*r)
                local col = Color3.fromHSV((math.deg(a)+180)/360, r/(w.AbsoluteSize.X/2), 1)
                p.BackgroundColor3=col; Titanium.Flags[txt]={R=col.R,G=col.G,B=col.B}; if cb then cb(col) end
            end
            w.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=true end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then down=false end end)
            UserInputService.InputChanged:Connect(function(i) if down and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Upd(i) end end)
            
            function f:Set(col)
               p.BackgroundColor3=col; Titanium.Flags[txt]={R=col.R,G=col.G,B=col.B}
            end
            return f
        end
        return Elems
    end

    --// 3. PLAYERS TAB (SEPARATE)
    local PlayerTab = Lib:Tab("Players")
    PlayerTab:Toggle("Sound on Join", false, function(v) Titanium.Flags["__System_JoinSound"] = v end)
    PlayerTab:Toggle("Sound on Leave", false, function(v) Titanium.Flags["__System_LeaveSound"] = v end)
    PlayerTab:Button("Copy Player List", function()
        local list = ""
        for _, p in pairs(Players:GetPlayers()) do list = list .. p.Name .. "\n" end
        setclipboard(list)
    end)

    --// 4. UI SETTINGS TAB
    local Sys = Lib:Tab("UI Settings")
    
    local CfgName="Default"
    local Input = Create("TextBox", {Parent=Sys.Page, Size=UDim2.new(1,-10,0,30), BackgroundColor3=Color3.fromRGB(40,40,45), Text="Default", TextColor3=Color3.new(1,1,1)}); Create("UICorner", {Parent=Input, CornerRadius=UDim.new(0,4)})
    Input:GetPropertyChangedSignal("Text"):Connect(function() CfgName=Input.Text end)
    
    Sys:Button("Save Config (Includes UI)", function() FS:Save(CfgName); PlaySound(ASSETS.Sounds.Confirm) end)
    Sys:Button("Load Config", function()
        local Data = FS:Load(CfgName)
        if Data then
            PlaySound(ASSETS.Sounds.Flash)
            
            -- LOAD FLAGS
            if Data.Flags then
                for k,v in pairs(Data.Flags) do Titanium.Flags[k] = v end
            end
            
            -- LOAD THEME
            if Data.Theme then
                for k,v in pairs(Data.Theme) do Titanium.Theme[k] = v end
                UpdateUIAppearance() -- Force UI Update
            end
        else
            PlaySound(ASSETS.Sounds.Error)
        end
    end)
    
    local SizeSlide = Sys:Slider("UI Size (Scale)", 0.5, 1.5, 1.0, function(v)
        Titanium.Theme.Scale = v
        UpdateUIAppearance()
    end)
    
    local TransSlide = Sys:Slider("Background Transparency", 0, 1, 0.1, function(v)
        Titanium.Theme.Transparency = v
        UpdateUIAppearance()
    end)
    
    local FontPick = Sys:ColorPicker("Font Color", Titanium.Theme.Text, function(v)
        Titanium.Theme.Text = v
        UpdateUIAppearance()
    end)
    
    Sys:Toggle("Rainbow Borders", true, function(v) Titanium.Theme.RainbowEnabled = v end)
    Sys:Button("Unload / Close", function() Screen:Destroy() end)

    return Lib
end

--// GLOBAL EVENTS
Players.PlayerAdded:Connect(function() if Titanium.Flags["__System_JoinSound"] then PlaySound(ASSETS.Sounds.Join) end end)
Players.PlayerRemoving:Connect(function() if Titanium.Flags["__System_LeaveSound"] then PlaySound(ASSETS.Sounds.Leave) end end)

return Titanium
