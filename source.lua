--!strict
---------------------------------------------------------------------
-- SciFiUILib.lua
-- 科幻风格 Roblox UI 库（窗口 / Tab / 彩虹边框 / 圆形调色盘 / Config 管理）
-- 仅使用 Roblox 官方 API，可在普通游戏中使用，不依赖任何“注入器”功能
---------------------------------------------------------------------

local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- 底层工具
---------------------------------------------------------------------
local Util = {}

function Util:Create(className, props, children)
    local obj = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    if children then
        for _,child in ipairs(children) do
            child.Parent = obj
        end
    end
    return obj
end

function Util:Tween(obj, info, props)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function Util:Lerp(a, b, t)
    return a + (b - a) * t
end

function Util:ColorSequenceFromTable(tbl)
    local keypoints = {}
    for _,entry in ipairs(tbl) do
        table.insert(keypoints, ColorSequenceKeypoint.new(entry[1], entry[2]))
    end
    return ColorSequence.new(keypoints)
end

function Util:Round(num, decimals)
    local power = 10 ^ (decimals or 0)
    return math.floor(num * power + 0.5) / power
end

function Util:HexToColor3(hex)
    hex = hex:gsub("#","")
    if #hex ~= 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2),16) or 255
    local g = tonumber(hex:sub(3,4),16) or 255
    local b = tonumber(hex:sub(5,6),16) or 255
    return Color3.fromRGB(r,g,b)
end

function Util:Color3ToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Util:ConnectInput(obj, onDown, onUp, button)
    button = button or Enum.UserInputType.MouseButton1
    local dn, up = nil, nil
    dn = obj.InputBegan:Connect(function(input)
        if input.UserInputType == button then
            if onDown then onDown(input) end
        end
    end)
    up = obj.InputEnded:Connect(function(input)
        if input.UserInputType == button then
            if onUp then onUp(input) end
        end
    end)
    return {dn, up}
end

function Util:MakeDraggable(handle, dragObj)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragObj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            dragObj.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

---------------------------------------------------------------------
-- 声音管理
---------------------------------------------------------------------
local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new(parentGui : ScreenGui)
    local self = setmetatable({}, SoundManager)
    self.Folder = Util:Create("Folder", {Name="SciFi_Sounds", Parent = parentGui})
    -- 这些 SoundId 请换成你喜欢的音效
    self.Sounds = {
        Intro      = "rbxassetid://9118823101",   -- 载入动画音效（清脆感）
        Click      = "rbxassetid://9118823101",
        ConfigLoad = "rbxassetid://12222005",     -- 载入 config 时独特音效
        Hover      = "rbxassetid://9118823101",
    }
    self.Instances = {}
    for key,id in pairs(self.Sounds) do
        local s = Instance.new("Sound")
        s.Name = key
        s.SoundId = id
        s.Volume = 0.4
        s.PlayOnRemove = false
        s.Parent = self.Folder
        self.Instances[key] = s
    end
    return self
end

function SoundManager:Play(name)
    local s = self.Instances[name]
    if s then
        s:Play()
    end
end

---------------------------------------------------------------------
-- 彩虹边框管理
---------------------------------------------------------------------
local RainbowBorder = {}
RainbowBorder.__index = RainbowBorder

function RainbowBorder.new(frame : Frame, options)
    local self = setmetatable({}, RainbowBorder)
    options = options or {}
    self.Frame = frame
    self.Speed = options.Speed or 0.1
    self.Enabled = options.Enabled ~= false
    self.Connections = {}

    -- 使用一个内层 Frame + UICorner + UIGradient 模拟“发光边框”
    local borderFrame = Util:Create("Frame", {
        Name = "RainbowBorder",
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,4,1,4),
        Position = UDim2.new(0,-2,0,-2),
        ZIndex = frame.ZIndex - 1,
    })
    local corner = Util:Create("UICorner", {CornerRadius = UDim.new(0,10)}, {parent=nil})
    corner.Parent = borderFrame

    local stroke = Util:Create("UIStroke", {
        Parent = borderFrame,
        Thickness = 2,
        Transparency = 0.1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    local grad = Util:Create("UIGradient", {
        Parent = stroke,
        Rotation = 0,
        Color = Util:ColorSequenceFromTable({
            {0.00, Color3.fromRGB(255, 0, 0)},
            {0.16, Color3.fromRGB(255, 127, 0)},
            {0.33, Color3.fromRGB(255, 255, 0)},
            {0.50, Color3.fromRGB(0, 255, 0)},
            {0.66, Color3.fromRGB(0, 255, 255)},
            {0.83, Color3.fromRGB(0, 0, 255)},
            {1.00, Color3.fromRGB(255, 0, 255)},
        })
    })

    self.Gradient = grad
    self.Offset = 0

    self.Connections.Animate = RunService.RenderStepped:Connect(function(dt)
        if not self.Enabled then return end
        self.Offset = (self.Offset + dt * self.Speed) % 1
        grad.Offset = Vector2.new(self.Offset, 0)
    end)

    return self
end

function RainbowBorder:SetEnabled(enabled : boolean)
    self.Enabled = enabled
end

function RainbowBorder:SetSpeed(speed : number)
    self.Speed = speed
end

function RainbowBorder:SetColorSequence(seq : ColorSequence)
    if self.Gradient then
        self.Gradient.Color = seq
    end
end

function RainbowBorder:Destroy()
    for _,con in pairs(self.Connections) do
        if typeof(con) == "RBXScriptConnection" then
            con:Disconnect()
        end
    end
    if self.Gradient and self.Gradient.Parent then
        self.Gradient.Parent.Parent:Destroy()
    end
end

---------------------------------------------------------------------
-- 圆形调色盘（ColorPicker）
---------------------------------------------------------------------
local ColorPicker = {}
ColorPicker.__index = ColorPicker

export type ColorPickerOptions = {
    Title : string?,
    DefaultColor : Color3?,
    Presets : {Color3}?,
    OnChanged : ((Color3) -> ())?,
}

function ColorPicker.new(parent : Instance, options : ColorPickerOptions, sound : SoundManager)
    local self = setmetatable({}, ColorPicker)
    options = options or {}
    self.OnChanged = options.OnChanged
    self.Sound = sound
    self.Value = options.DefaultColor or Color3.fromRGB(0,255,200)

    -- 主容器
    local holder = Util:Create("Frame", {
        Name = "ColorPicker",
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(7, 10, 20),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 160),
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,8)}, {parent=nil}).Parent = holder
    Util:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = Color3.fromRGB(40, 200, 255),
        Thickness = 1,
        Transparency = 0.4,
        Parent = holder,
    })

    local titleLabel = Util:Create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,4),
        Size = UDim2.new(1,-16,0,18),
        Font = Enum.Font.GothamSemibold,
        Text = options.Title or "Color Picker",
        TextColor3 = Color3.fromRGB(200, 220, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- 左侧圆形色轮
    local wheelHolder = Util:Create("Frame", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,26),
        Size = UDim2.new(0,100,0,100),
        ClipsDescendants = true,
    })
    local wheel = Util:Create("ImageButton", {
        Parent = wheelHolder,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Image = "rbxassetid://6020299385", -- 一个标准 HSV 色轮贴图，可替换
    })
    local wheelCorner = Util:Create("UICorner", {CornerRadius = UDim.new(1,0)}, {parent=nil})
    wheelCorner.Parent = wheel

    -- 亮度滑条
    local valueBar = Util:Create("Frame", {
        Parent = holder,
        BackgroundColor3 = Color3.fromRGB(20,20,25),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0,120,0,26),
        Size = UDim2.new(0,16,0,100),
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,8)}, {parent=nil}).Parent = valueBar

    local valueGrad = Util:Create("UIGradient", {
        Parent = valueBar,
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0)),
    })

    local valueSlider = Util:Create("Frame", {
        Parent = valueBar,
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        Size = UDim2.new(1,4,0,3),
        Position = UDim2.new(0,-2,0,0),
        BorderSizePixel = 0,
    })

    -- 当前颜色预览
    local preview = Util:Create("Frame", {
        Parent = holder,
        BackgroundColor3 = self.Value,
        BorderSizePixel = 0,
        Position = UDim2.new(0,150,0,26),
        Size = UDim2.new(0,40,0,40),
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,8)}, {parent=nil}).Parent = preview
    Util:Create("UIStroke", {
        Parent = preview,
        Color = Color3.fromRGB(255,255,255),
        Thickness = 1,
        Transparency = 0.5
    })

    -- 预设颜色
    local presetsHolder = Util:Create("Frame", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,150,0,72),
        Size = UDim2.new(1,-158,0,54),
    })
    local presetsLayout = Util:Create("UIGridLayout", {
        Parent = presetsHolder,
        CellPadding = UDim2.new(0,4,0,4),
        CellSize = UDim2.new(0,18,0,18),
        FillDirectionMaxCells = 4,
        StartCorner = Enum.StartCorner.TopLeft,
    })
    local presetColors : {Color3} = options.Presets or {
        Color3.fromRGB(0,255,200),
        Color3.fromRGB(0,150,255),
        Color3.fromRGB(255,0,80),
        Color3.fromRGB(255,170,0),
        Color3.fromRGB(140,0,255),
        Color3.fromRGB(80,255,0),
        Color3.fromRGB(255,255,255),
        Color3.fromRGB(30,30,40),
    }
    for _,c in ipairs(presetColors) do
        local btn = Util:Create("TextButton", {
            Parent = presetsHolder,
            Text = "",
            BackgroundColor3 = c,
            AutoButtonColor = false,
            BorderSizePixel = 0,
        })
        Util:Create("UICorner", {CornerRadius = UDim.new(0,4)}, {parent=nil}).Parent = btn
        Util:Create("UIStroke", {
            Parent = btn,
            Color = Color3.fromRGB(0,0,0),
            Thickness = 1,
            Transparency = 0.5,
        })
        btn.MouseButton1Click:Connect(function()
            self:SetColor(c, true)
        end)
    end

    -- HEX 输入
    local hexBox = Util:Create("TextBox", {
        Parent = holder,
        BackgroundColor3 = Color3.fromRGB(10,16,30),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(1,-110,0,26),
        Size = UDim2.new(0,96,0,24),
        ClearTextOnFocus = false,
        Font = Enum.Font.Code,
        Text = Util:Color3ToHex(self.Value),
        TextColor3 = Color3.fromRGB(220, 240, 255),
        TextSize = 14,
        PlaceholderText = "#RRGGBB",
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,6)}, {parent=nil}).Parent = hexBox
    Util:Create("UIStroke", {
        Parent = hexBox,
        Color = Color3.fromRGB(40,200,255),
        Thickness = 1,
        Transparency = 0.6,
    })

    local hexLabel = Util:Create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(1,-110,0,52),
        Size = UDim2.new(0,96,0,18),
        Font = Enum.Font.Gotham,
        Text = "HEX",
        TextColor3 = Color3.fromRGB(120,140,170),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    self.Root = holder
    self.Wheel = wheel
    self.ValueBar = valueBar
    self.ValueSlider = valueSlider
    self.Preview = preview
    self.HexBox = hexBox

    self._h = 0
    self._s = 0
    self._v = 1

    -- 初始化 HS(V) 值
    do
        local h,s,v = self.Value:ToHSV()
        self._h, self._s, self._v = h,s,v
    end

    local function updatePreview()
        local color = Color3.fromHSV(self._h, self._s, self._v)
        self.Value = color
        preview.BackgroundColor3 = color
        hexBox.Text = Util:Color3ToHex(color)
        if self.OnChanged then
            self.OnChanged(color)
        end
    end

    -- 更新亮度条的渐变（基于当前 H,S）
    local function updateValueGradient()
        local fullBright = Color3.fromHSV(self._h, self._s, 1)
        valueGrad.Color = ColorSequence.new(fullBright, Color3.new(0,0,0))
    end

    updateValueGradient()
    updatePreview()

    local pickingWheel = false
    local pickingValue = false

    local function updateFromWheel(inputPos)
        local rel = wheel.AbsolutePosition
        local size = wheel.AbsoluteSize
        local center = rel + size / 2
        local offset = Vector2.new(inputPos.X - center.X, inputPos.Y - center.Y)
        local dist = offset.Magnitude
        local radius = size.X/2
        if dist > radius then dist = radius end
        local s = dist / radius
        local angle = math.atan2(offset.Y, offset.X)
        local h = (angle / (2*math.pi)) + 0.5
        if h < 0 then h = h + 1 end
        self._h = h
        self._s = s
        updateValueGradient()
        updatePreview()
    end

    local function updateFromValueBar(inputPos)
        local rel = valueBar.AbsolutePosition
        local size = valueBar.AbsoluteSize
        local y = math.clamp(inputPos.Y - rel.Y, 0, size.Y)
        local t = y / size.Y
        self._v = 1 - t
        valueSlider.Position = UDim2.new(0,-2,0,t*size.Y - valueSlider.Size.Y.Offset/2)
        updatePreview()
    end

    wheel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pickingWheel = true
            if self.Sound then self.Sound:Play("Click") end
            updateFromWheel(input.Position)
        end
    end)

    wheel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pickingWheel = false
        end
    end)

    valueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pickingValue = true
            if self.Sound then self.Sound:Play("Click") end
            updateFromValueBar(input.Position)
        end
    end)

    valueBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pickingValue = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if pickingWheel then
                updateFromWheel(input.Position)
            elseif pickingValue then
                updateFromValueBar(input.Position)
            end
        end
    end)

    hexBox.FocusLost:Connect(function(enterPressed)
        if not enterPressed then return end
        local c = Util:HexToColor3(hexBox.Text)
        self:SetColor(c, true)
    end)

    return self
end

function ColorPicker:SetColor(color : Color3, playSound : boolean?)
    self.Value = color
    local h,s,v = color:ToHSV()
    self._h,self._s,self._v = h,s,v
    self.Preview.BackgroundColor3 = color
    self.HexBox.Text = Util:Color3ToHex(color)
    if playSound and self.Sound then
        self.Sound:Play("Click")
    end
    if self.OnChanged then
        self.OnChanged(color)
    end
end

function ColorPicker:GetColor() : Color3
    return self.Value
end

function ColorPicker:GetState()
    return Util:Color3ToHex(self.Value)
end

function ColorPicker:SetState(hex : string)
    local c = Util:HexToColor3(hex)
    self:SetColor(c, false)
end

---------------------------------------------------------------------
-- Config 管理（仅内存，方便你基于此接入持久化）
---------------------------------------------------------------------
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.Configs = {}         -- name -> data(table)
    self.Components = {}      -- id -> {GetState, SetState}
    self.AutoLoadConfigName = nil
    return self
end

function ConfigManager:RegisterComponent(id : string, getter, setter)
    self.Components[id] = {Get = getter, Set = setter}
end

function ConfigManager:SaveConfig(name : string)
    local data = {}
    for id,comp in pairs(self.Components) do
        local ok, val = pcall(comp.Get)
        if ok then
            data[id] = val
        end
    end
    self.Configs[name] = data
end

function ConfigManager:LoadConfig(name : string)
    local data = self.Configs[name]
    if not data then return false end
    for id,val in pairs(data) do
        local comp = self.Components[id]
        if comp and comp.Set then
            pcall(comp.Set, val)
        end
    end
    return true
end

function ConfigManager:DeleteConfig(name : string)
    self.Configs[name] = nil
end

function ConfigManager:GetConfigNames()
    local names = {}
    for n,_ in pairs(self.Configs) do
        table.insert(names, n)
    end
    table.sort(names)
    return names
end

---------------------------------------------------------------------
-- 控件：Toggle / Button（为 config 提供示例）
---------------------------------------------------------------------
local Controls = {}

function Controls.CreateToggle(parent, text, default, sound, onChanged)
    local holder = Util:Create("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 26),
    })
    local label = Util:Create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,-60,1,0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = Color3.fromRGB(200,220,255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local btn = Util:Create("TextButton", {
        Parent = holder,
        AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1,0,0.5,0),
        Size = UDim2.new(0,42,0,18),
        BackgroundColor3 = Color3.fromRGB(20,30,40),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(1,0)}, {parent=nil}).Parent = btn
    local dot = Util:Create("Frame", {
        Parent = btn,
        AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.new(0,2,0.5,0),
        Size = UDim2.new(0,14,0,14),
        BackgroundColor3 = Color3.fromRGB(120,130,150),
        BorderSizePixel = 0,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(1,0)}, {parent=nil}).Parent = dot

    local value = default and true or false
    local function refresh(animated)
        local targetPos = value and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0)
        local targetColor = value and Color3.fromRGB(0,255,200) or Color3.fromRGB(120,130,150)
        if animated then
            Util:Tween(dot, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = targetPos,
                BackgroundColor3 = targetColor,
            })
        else
            dot.Position = targetPos
            dot.BackgroundColor3 = targetColor
        end
    end
    refresh(false)

    btn.MouseButton1Click:Connect(function()
        value = not value
        refresh(true)
        if sound then sound:Play("Click") end
        if onChanged then onChanged(value) end
    end)

    local toggleObj = {}
    function toggleObj:Get()
        return value
    end
    function toggleObj:Set(v)
        value = v and true or false
        refresh(false)
        if onChanged then onChanged(value) end
    end
    return toggleObj
end

function Controls.CreateButton(parent, text, sound, callback)
    local btn = Util:Create("TextButton", {
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(10,16,30),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Size = UDim2.new(1,-10,0,26),
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = Color3.fromRGB(200,220,255),
        TextSize = 14,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,6)}, {parent=nil}).Parent = btn
    Util:Create("UIStroke", {
        Parent = btn,
        Color = Color3.fromRGB(40,200,255),
        Thickness = 1,
        Transparency = 0.7,
    })
    btn.MouseButton1Click:Connect(function()
        if sound then sound:Play("Click") end
        if callback then callback() end
    end)
    return btn
end

function Controls.CreateTextBox(parent, placeholder, sound, onCommit)
    local box = Util:Create("TextBox", {
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(10,16,30),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1,-10,0,26),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = placeholder,
        TextColor3 = Color3.fromRGB(220,240,255),
        PlaceholderColor3 = Color3.fromRGB(90,110,140),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,6)}, {parent=nil}).Parent = box
    Util:Create("UIStroke", {
        Parent = box,
        Color = Color3.fromRGB(40,200,255),
        Thickness = 1,
        Transparency = 0.6,
    })
    box.FocusLost:Connect(function(enter)
        if enter and onCommit then
            if sound then sound:Play("Click") end
            onCommit(box.Text)
        end
    end)
    return box
end

---------------------------------------------------------------------
-- Tab 系统 & 主窗口
---------------------------------------------------------------------
local Tab = {}
Tab.__index = Tab

function Tab.new(lib, name, pageFrame)
    local self = setmetatable({}, Tab)
    self.Library = lib
    self.Name = name
    self.Page = pageFrame
    self.ControlsY = 8
    return self
end

function Tab:_nextY(height)
    local y = self.ControlsY
    self.ControlsY = self.ControlsY + height + 6
    return y
end

function Tab:AddSection(title)
    local y = self:_nextY(22)
    local label = Util:Create("TextLabel", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,y),
        Size = UDim2.new(1,-16,0,22),
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = Color3.fromRGB(150,180,220),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return label
end

function Tab:AddToggle(id, text, default)
    local y = self:_nextY(26)
    local container = Util:Create("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,y),
        Size = UDim2.new(1,-16,0,26),
    })
    local toggle = Controls.CreateToggle(container, text, default, self.Library.Sound, nil)
    -- 注册 config
    self.Library.ConfigManager:RegisterComponent(id, function()
        return toggle:Get()
    end, function(v)
        toggle:Set(v)
    end)
    return toggle
end

function Tab:AddButton(text, callback)
    local y = self:_nextY(26)
    local container = Util:Create("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,y),
        Size = UDim2.new(1,-16,0,26),
    })
    local btn = Controls.CreateButton(container, text, self.Library.Sound, callback)
    return btn
end

function Tab:AddTextBox(id, placeholder)
    local y = self:_nextY(26)
    local container = Util:Create("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,y),
        Size = UDim2.new(1,-16,0,26),
    })
    local value = ""
    local box = Controls.CreateTextBox(container, placeholder, self.Library.Sound, function(text)
        value = text
    end)
    self.Library.ConfigManager:RegisterComponent(id, function()
        return value
    end, function(v)
        value = tostring(v or "")
        box.Text = value
    end)
    return box
end

function Tab:AddColorPicker(id, title, default)
    local y = self:_nextY(160)
    local container = Util:Create("Frame", {
        Parent = self.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,y),
        Size = UDim2.new(1,-16,0,160),
    })
    local val = default or Color3.fromRGB(0,255,200)
    local picker = ColorPicker.new(container, {
        Title = title or "Theme Color",
        DefaultColor = val,
    }, self.Library.Sound)
    self.Library.ConfigManager:RegisterComponent(id, function()
        return picker:GetState()
    end, function(v)
        picker:SetState(v)
    end)
    return picker
end

---------------------------------------------------------------------
-- 主窗口对象
---------------------------------------------------------------------
local MainWindow = {}
MainWindow.__index = MainWindow

function MainWindow.new(lib, rootFrame, contentFrame, tabButtonsFrame)
    local self = setmetatable({}, MainWindow)
    self.Library = lib
    self.Root = rootFrame
    self.Content = contentFrame
    self.TabButtonsFrame = tabButtonsFrame
    self.Tabs = {}
    self.CurrentTab = nil
    self.Rainbow = RainbowBorder.new(rootFrame, {
        Speed = lib.Config.RainbowSpeed or 0.4,
        Enabled = lib.Config.EnableRainbowBorder ~= false,
    })
    return self
end

function MainWindow:CreateTab(name : string)
    local page = Util:Create("Frame", {
        Parent = self.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Visible = false,
    })

    local btn = Util:Create("TextButton", {
        Parent = self.TabButtonsFrame,
        BackgroundColor3 = Color3.fromRGB(10,16,30),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(0,80,1,0),
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Color3.fromRGB(180,200,230),
        TextSize = 14,
    })
    Util:Create("UIStroke", {
        Parent = btn,
        Color = Color3.fromRGB(40,200,255),
        Thickness = 1,
        Transparency = 0.7,
    })

    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.1
        self.Library.Sound:Play("Hover")
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.3
    end)
    btn.MouseButton1Click:Connect(function()
        self:ShowTab(name)
        self.Library.Sound:Play("Click")
    end)

    local tabObj = Tab.new(self.Library, name, page)
    self.Tabs[name] = tabObj

    if not self.CurrentTab then
        self:ShowTab(name)
    end

    return tabObj
end

function MainWindow:ShowTab(name : string)
    local target = self.Tabs[name]
    if not target then return end
    for tabName,tab in pairs(self.Tabs) do
        tab.Page.Visible = (tabName == name)
    end
    self.CurrentTab = target
end

function MainWindow:SetTransparency(alpha : number)
    self.Root.BackgroundTransparency = alpha
end

function MainWindow:SetThemeColor(c : Color3)
    -- 这里可以扩展，把主题色应用到更多控件
    local stroke = self.Root:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = c
    end
end

function MainWindow:Destroy()
    if self.Rainbow then
        self.Rainbow:Destroy()
    end
    if self.Root then
        self.Root:Destroy()
    end
end

---------------------------------------------------------------------
-- SciFiUI Library 主体
---------------------------------------------------------------------
local SciFiUI = {}
SciFiUI.__index = SciFiUI

function SciFiUI:CreateLibrary(config)
    local self = setmetatable({}, SciFiUI)
    self.Config = config or {}
    self.Config.WindowTitle = self.Config.WindowTitle or "Sci-Fi Script Hub"
    self.Config.ThemeColor  = self.Config.ThemeColor  or Color3.fromRGB(0,255,200)
    self.Config.MenuTransparency = self.Config.MenuTransparency or 0.2
    self.Config.RainbowSpeed = self.Config.RainbowSpeed or 0.4
    self.Config.EnableRainbowBorder = (self.Config.EnableRainbowBorder ~= false)

    self.Gui = Util:Create("ScreenGui", {
        Name = "SciFi_ScriptHub",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui,
    })

    self.Sound = SoundManager.new(self.Gui)
    self.ConfigManager = ConfigManager.new()
    self.MainWindow = nil
    self.Enabled = true

    self:_createIntroAnimation()
    return self
end

---------------------------------------------------------------------
-- 载入动画（高级 + 科幻风 + 音效）
---------------------------------------------------------------------
function SciFiUI:_createIntroAnimation()
    local overlay = Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        ZIndex = 1000,
    })
    local center = Util:Create("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(0,220,0,80),
        BackgroundColor3 = Color3.fromRGB(5,10,20),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,12)}, {parent=nil}).Parent = center
    Util:Create("UIStroke", {
        Parent = center,
        Color = self.Config.ThemeColor,
        Thickness = 2,
        Transparency = 0.2,
    })
    local glow = Util:Create("UIGradient", {
        Parent = center,
        Color = ColorSequence.new(self.Config.ThemeColor, Color3.fromRGB(0,0,0)),
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.5),
            NumberSequenceKeypoint.new(0.5,0),
            NumberSequenceKeypoint.new(1,0.5),
        }),
    })

    local title = Util:Create("TextLabel", {
        Parent = center,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,26),
        Position = UDim2.new(0,0,0,10),
        Font = Enum.Font.GothamBlack,
        Text = self.Config.WindowTitle,
        TextColor3 = Color3.fromRGB(220,240,255),
        TextSize = 20,
    })
    local subtitle = Util:Create("TextLabel", {
        Parent = center,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,18),
        Position = UDim2.new(0,0,0,40),
        Font = Enum.Font.Gotham,
        Text = "INITIALIZING MODULES...",
        TextColor3 = Color3.fromRGB(120,160,210),
        TextSize = 12,
    })

    local ring = Util:Create("ImageLabel", {
        Parent = center,
        AnchorPoint = Vector2.new(0.5,1),
        Position = UDim2.new(0.5,0,1,-6),
        Size = UDim2.new(0,64,0,64),
        BackgroundTransparency = 1,
        Image = "rbxassetid://572547092", -- 一个圆环贴图，可替换
        ImageColor3 = self.Config.ThemeColor,
        ImageTransparency = 0.2,
    })

    overlay.BackgroundTransparency = 1
    center.Size = UDim2.new(0,40,0,40)
    center.BackgroundTransparency = 1
    title.TextTransparency = 1
    subtitle.TextTransparency = 1
    ring.ImageTransparency = 1

    self.Sound:Play("Intro")

    Util:Tween(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.3,
    })
    Util:Tween(center, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,220,0,80),
        BackgroundTransparency = 0.2,
    })
    wait(0.15)
    Util:Tween(title, TweenInfo.new(0.25), {TextTransparency = 0})
    wait(0.05)
    Util:Tween(subtitle, TweenInfo.new(0.25), {TextTransparency = 0})
    wait(0.05)
    Util:Tween(ring, TweenInfo.new(0.25), {ImageTransparency = 0.2})

    -- 旋转环
    spawn(function()
        local t = 0
        while overlay.Parent do
            t = t + RunService.RenderStepped:Wait()
            ring.Rotation = (t * 180) % 360
        end
    end)

    wait(1.1)
    Util:Tween(overlay, TweenInfo.new(0.35), {BackgroundTransparency = 1})
    Util:Tween(center, TweenInfo.new(0.35), {BackgroundTransparency = 1})
    Util:Tween(title, TweenInfo.new(0.25), {TextTransparency = 1})
    Util:Tween(subtitle, TweenInfo.new(0.25), {TextTransparency = 1})
    Util:Tween(ring, TweenInfo.new(0.25), {ImageTransparency = 1})
    wait(0.4)
    overlay:Destroy()
end

---------------------------------------------------------------------
-- 创建主窗口（含手机适配）
---------------------------------------------------------------------
function SciFiUI:CreateMainWindow()
    if self.MainWindow then
        return self.MainWindow
    end
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    local size = isMobile and UDim2.new(0.9,0,0.75,0) or UDim2.new(0,520,0,360)
    local pos  = UDim2.new(0.5,-size.X.Offset/2,0.5,-size.Y.Offset/2)
    if isMobile then
        pos = UDim2.new(0.5,0,0.5,0)
    end

    local root = Util:Create("Frame", {
        Parent = self.Gui,
        Name = "MainWindow",
        BackgroundColor3 = Color3.fromRGB(5,8,16),
        BackgroundTransparency = self.Config.MenuTransparency,
        BorderSizePixel = 0,
        Size = size,
        Position = pos,
        AnchorPoint = isMobile and Vector2.new(0.5,0.5) or Vector2.new(0,0),
        ZIndex = 50,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,10)}, {parent=nil}).Parent = root
    Util:Create("UIStroke", {
        Parent = root,
        Color = self.Config.ThemeColor,
        Thickness = 2,
        Transparency = 0.3,
    })

    local topBar = Util:Create("Frame", {
        Parent = root,
        BackgroundColor3 = Color3.fromRGB(7,10,22),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,30),
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,10)}, {parent=nil}).Parent = topBar

    local titleLabel = Util:Create("TextLabel", {
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,10,0,0),
        Size = UDim2.new(0.5,0,1,0),
        Font = Enum.Font.GothamSemibold,
        Text = self.Config.WindowTitle,
        TextColor3 = Color3.fromRGB(200,220,255),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local closeBtn = Util:Create("TextButton", {
        Parent = topBar,
        AnchorPoint = Vector2.new(1,0.5),
        Position = UDim2.new(1,-6,0.5,0),
        Size = UDim2.new(0,22,0,22),
        BackgroundColor3 = Color3.fromRGB(40,0,20),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBlack,
        Text = "×",
        TextColor3 = Color3.fromRGB(255,100,160),
        TextSize = 16,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(1,0)}, {parent=nil}).Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:CloseAll()
    end)

    if not isMobile then
        Util:MakeDraggable(topBar, root)
    end

    local tabBar = Util:Create("Frame", {
        Parent = root,
        BackgroundColor3 = Color3.fromRGB(7,10,22),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,0,30),
        Size = UDim2.new(1,0,0,30),
    })

    local tabButtonsFrame = Util:Create("Frame", {
        Parent = tabBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,4),
        Size = UDim2.new(1,-16,0,22),
    })

    local tabButtonsLayout = Util:Create("UIListLayout", {
        Parent = tabButtonsFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0,6),
    })

    local content = Util:Create("Frame", {
        Parent = root,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,60),
        Size = UDim2.new(1,0,1,-60),
        ClipsDescendants = true,
    })

    self.MainWindow = MainWindow.new(self, root, content, tabButtonsFrame)

    -- 自动创建“Settings” 标签页，并填充功能
    self:_buildSettingsTab()

    return self.MainWindow
end

---------------------------------------------------------------------
-- 设置页（Config / 自动载入 / Rejoin / Close）
---------------------------------------------------------------------
function SciFiUI:_buildSettingsTab()
    local wnd = self.MainWindow or self:CreateMainWindow()
    local tab = wnd:CreateTab("Settings")

    tab:AddSection("Config 管理")

    local nameBox = tab:AddTextBox("config_name_temp", "Config 名称（输入后回车）")
    local currentName = ""

    -- 因为 TextBox 控件只在 Enter 时更新 value，这里额外监听 TextChanged
    nameBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentName = nameBox.Text
    end)

    local refreshDropdown -- 前置声明

    tab:AddButton("保存 / 覆盖当前 Config", function()
        if currentName == "" then return end
        self.ConfigManager:SaveConfig(currentName)
        refreshDropdown()
    end)

    tab:AddButton("删除当前 Config", function()
        if currentName == "" then return end
        self.ConfigManager:DeleteConfig(currentName)
        refreshDropdown()
    end)

    tab:AddSection("现有 Config")

    local dropdownValue = ""
    local dropdownY = tab.ControlsY
    local dropdownFrame = Util:Create("Frame", {
        Parent = tab.Page,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,8,0,dropdownY),
        Size = UDim2.new(1,-16,0,26),
    })
    tab.ControlsY = tab.ControlsY + 26 + 6

    local dropdownBtn = Util:Create("TextButton", {
        Parent = dropdownFrame,
        BackgroundColor3 = Color3.fromRGB(10,16,30),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0),
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "选择要加载的 Config",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(200,220,255),
        TextSize = 14,
        ClipsDescendants = true,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,6)}, {parent=nil}).Parent = dropdownBtn
    Util:Create("UIStroke", {
        Parent = dropdownBtn,
        Color = Color3.fromRGB(40,200,255),
        Thickness = 1,
        Transparency = 0.6,
    })

    local listHolder = Util:Create("Frame", {
        Parent = dropdownBtn,
        BackgroundColor3 = Color3.fromRGB(5,8,16),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,0),
        Size = UDim2.new(1,0,0,0),
        Visible = false,
        ClipsDescendants = true,
    })
    Util:Create("UICorner", {CornerRadius = UDim.new(0,6)}, {parent=nil}).Parent = listHolder
    local listLayout = Util:Create("UIListLayout", {
        Parent = listHolder,
        Padding = UDim.new(0,2),
    })

    local function setDropdown(text)
        dropdownValue = text
        dropdownBtn.Text = text == "" and "选择要加载的 Config" or text
    end

    local listOpen = false

    dropdownBtn.MouseButton1Click:Connect(function()
        listOpen = not listOpen
        listHolder.Visible = true
        if listOpen then
            local target = UDim2.new(1,0,0,#listHolder:GetChildren()*20+4)
            Util:Tween(listHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = target
            })
        else
            Util:Tween(listHolder, TweenInfo.new(0.18), {
                Size = UDim2.new(1,0,0,0)
            }).Completed:Connect(function()
                listHolder.Visible = false
            end)
        end
    end)

    function refreshDropdown()
        for _,child in ipairs(listHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local names = self.ConfigManager:GetConfigNames()
        for _,name in ipairs(names) do
            local btn = Util:Create("TextButton", {
                Parent = listHolder,
                BackgroundColor3 = Color3.fromRGB(10,16,30),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(1,-4,0,20),
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = name,
                TextColor3 = Color3.fromRGB(200,220,255),
                TextSize = 14,
            })
            btn.MouseButton1Click:Connect(function()
                setDropdown(name)
            end)
        end
    end

    tab:AddButton("载入选中 Config（闪屏 + 音效）", function()
        if dropdownValue == "" then return end
        local ok = self.ConfigManager:LoadConfig(dropdownValue)
        if ok then
            self:_flashThemeScreen()
            self.Sound:Play("ConfigLoad")
        end
    end)

    tab:AddSection("自动载入 Config")

    local autoToggle = Controls.CreateToggle(
        Util:Create("Frame", {
            Parent = tab.Page,
            BackgroundTransparency = 1,
            Position = UDim2.new(0,8,0,tab.ControlsY),
            Size = UDim2.new(1,-16,0,26),
        }),
        "使用上方选中 Config 作为自动载入",
        false,
        self.Sound,
        function(v)
            if v then
                self.ConfigManager.AutoLoadConfigName = dropdownValue ~= "" and dropdownValue or nil
            else
                self.ConfigManager.AutoLoadConfigName = nil
            end
        end
    )
    tab.ControlsY = tab.ControlsY + 26 + 6

    tab:AddSection("系统")

    tab:AddButton("Rejoin 当前游戏", function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)

    tab:AddButton("Close：关闭所有功能 / UI", function()
        self:CloseAll()
    end)

    -- 启动时，如有自动载入
    if self.ConfigManager.AutoLoadConfigName then
        if self.ConfigManager:LoadConfig(self.ConfigManager.AutoLoadConfigName) then
            self:_flashThemeScreen()
            self.Sound:Play("ConfigLoad")
        end
    end
end

---------------------------------------------------------------------
-- 载入 Config 时整屏闪烁（主题色）
---------------------------------------------------------------------
function SciFiUI:_flashThemeScreen()
    local flash = Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = self.Config.ThemeColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        ZIndex = 999,
    })
    Util:Tween(flash, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.2
    }).Completed:Connect(function()
        Util:Tween(flash, TweenInfo.new(0.18), {
            BackgroundTransparency = 1
        }).Completed:Connect(function()
            flash:Destroy()
        end)
    end)
end

---------------------------------------------------------------------
-- Close：关闭所有功能
---------------------------------------------------------------------
function SciFiUI:CloseAll()
    self.Enabled = false
    if self.MainWindow then
        self.MainWindow:Destroy()
        self.MainWindow = nil
    end
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

---------------------------------------------------------------------
-- 返回模块（供 require）
---------------------------------------------------------------------
local Module = {}
function Module:CreateLibrary(config)
    return SciFiUI:CreateLibrary(config)
end

return Module
