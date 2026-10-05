-- main.lua — Delta Hub v3.4.0 — auto-published by BluezyGPT
-- Architecture: clean MVC, anti-duplicate, mobile+PC responsive GUI
-- Repo: lomigg/delta-hub-bz (public), branch: main
-- v3.4.0: Steal An Egg features (verified internals from real game scripts)

-- ===================== SERVICES =====================
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ===================== CLEANUP =====================
local HUB_ID = "BzDeltaHub_v3"
pcall(function()
    local old = CoreGui:FindFirstChild(HUB_ID)
    if old then old:Destroy() end
end)
pcall(function()
    if _G[HUB_ID .. "_Conns"] then
        for _, c in ipairs(_G[HUB_ID .. "_Conns"]) do
            pcall(function() c:Disconnect() end)
        end
    end
end)
_G[HUB_ID .. "_Conns"] = {}

local function trackConn(c)
    table.insert(_G[HUB_ID .. "_Conns"], c)
    return c
end

-- ===================== THEME =====================
local Theme = {
    Bg        = Color3.fromRGB(18, 18, 24),
    BgLight   = Color3.fromRGB(28, 28, 38),
    Accent    = Color3.fromRGB(124, 92, 255),
    AccentHv  = Color3.fromRGB(154, 122, 255),
    Text      = Color3.fromRGB(235, 235, 245),
    TextDim   = Color3.fromRGB(150, 150, 165),
    Green     = Color3.fromRGB(72, 207, 173),
    Red       = Color3.fromRGB(235, 87, 87),
    Card      = Color3.fromRGB(34, 34, 46),
    Stroke    = Color3.fromRGB(50, 50, 65),
    Success   = Color3.fromRGB(72, 207, 173),
    Warn      = Color3.fromRGB(255, 184, 108),
}

-- ===================== UTILS =====================
local Utils = {}

function Utils.Tween(obj, props, time, dir)
    dir = dir or Enum.EasingDirection.Out
    time = time or 0.18
    local info = TweenInfo.new(time, Enum.EasingStyle.Quad, dir)
    TweenService:Create(obj, info, props):Play()
end

function Utils.Round(obj, r)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, r or 8)
    corner.Parent = obj
end

function Utils.Stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

function Utils.Padding(obj, all)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, all or 8)
    p.PaddingBottom = UDim.new(0, all or 8)
    p.PaddingLeft = UDim.new(0, all or 8)
    p.PaddingRight = UDim.new(0, all or 8)
    p.Parent = obj
    return p
end

function Utils.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    trackConn(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end))
    trackConn(handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

function Utils.GetTime()
    return os.date("%H:%M:%S")
end

function Utils.IsMobile()
    return UserInputService.TouchEnabled
    and not UserInputService.MouseEnabled
end

-- ===================== NOTIFY SYSTEM =====================
local NotifySys = {}
local notifyHolder

function NotifySys.Init(parent)
    notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.new(0, 300, 1, -20)
    notifyHolder.Position = UDim2.new(1, -320, 0, 10)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = notifyHolder
end

function NotifySys.Push(title, msg, kind)
    kind = kind or "info"
    if not notifyHolder then return end

    local color = Theme.Accent
    if kind == "success" then color = Theme.Success
    elseif kind == "warn"  then color = Theme.Warn
    elseif kind == "error" then color = Theme.Red end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.Parent = notifyHolder
    Utils.Round(card, 8)
    Utils.Stroke(card, color, 1)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = card
    Utils.Round(bar, 2)

    local title_l = Instance.new("TextLabel")
    title_l.BackgroundTransparency = 1
    title_l.Position = UDim2.new(0, 12, 0, 8)
    title_l.Size = UDim2.new(1, -16, 0, 16)
    title_l.Font = Enum.Font.GothamBold
    title_l.TextSize = 13
    title_l.TextColor3 = color
    title_l.TextXAlignment = Enum.TextXAlignment.Left
    title_l.Text = title
    title_l.Parent = card

    local msg_l = Instance.new("TextLabel")
    msg_l.BackgroundTransparency = 1
    msg_l.Position = UDim2.new(0, 12, 0, 26)
    msg_l.Size = UDim2.new(1, -16, 0, 14)
    msg_l.Font = Enum.Font.Gotham
    msg_l.TextSize = 12
    msg_l.TextColor3 = Theme.TextDim
    msg_l.TextXAlignment = Enum.TextXAlignment.Left
    msg_l.Text = msg
    msg_l.Parent = card

    local bounds = TextService:GetTextSize(msg, 12, Enum.Font.Gotham,
        Vector2.new(280, math.huge))
    card.Size = UDim2.new(1, 0, 0, bounds.Y + 44)

    card.Position = UDim2.new(1, 50, 0, 0)
    card.AnchorPoint = Vector2.new(0, 1)
    card.Position = UDim2.new(1, 50, 1, 0)
    Utils.Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)

    task.delay(4, function()
        Utils.Tween(card, {BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0)}, 0.3)
        task.wait(0.35)
        card:Destroy()
    end)
end

-- ===================== WIDGETS =====================
local Widgets = {}

function Widgets.Toggle(text, default, callback)
    local state = default or false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = nil
    Utils.Round(btn, 6)
    local stroke = Utils.Stroke(btn, Theme.Stroke, 1)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 36, 0, 18)
    track.Position = UDim2.new(1, -48, 0.5, -9)
    track.BackgroundColor3 = state and Theme.Accent or Theme.Stroke
    track.BorderSizePixel = 0
    track.Parent = btn
    Utils.Round(track, 9)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = track
    Utils.Round(knob, 7)

    btn.MouseButton1Click:Connect(function()
        state = not state
        Utils.Tween(track, {BackgroundColor3 = state and Theme.Accent or Theme.Stroke})
        if state then
            Utils.Tween(knob, {Position = UDim2.new(1, -16, 0.5, -7)})
        else
            Utils.Tween(knob, {Position = UDim2.new(0, 2, 0.5, -7)})
        end
        if callback then callback(state) end
        NotifySys.Push("Toggle", text .. ": " .. (state and "ON" or "OFF"),
            state and "success" or "info")
    end)

    return btn
end

function Widgets.Button(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Theme.Card
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Theme.Text
    btn.Text = text
    btn.AutoButtonColor = false
    Utils.Round(btn, 6)
    local stroke = Utils.Stroke(btn, Theme.Stroke, 1)

    btn.MouseButton1Enter:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.Accent})
        Utils.Tween(stroke, {Color = Theme.AccentHv})
    end)
    btn.MouseButton1Leave:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.Card})
        Utils.Tween(stroke, {Color = Theme.Stroke})
    end)
    btn.MouseButton1Click:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.AccentHv}, 0.08)
        task.wait(0.08)
        Utils.Tween(btn, {BackgroundColor3 = Theme.Card})
        if callback then callback() end
    end)

    return btn
end

function Widgets.Slider(text, min, max, default, callback)
    local val = default or min

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 44)
    holder.BackgroundColor3 = Theme.Card
    holder.BorderSizePixel = 0
    Utils.Round(holder, 6)
    Utils.Stroke(holder, Theme.Stroke, 1)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 6)
    label.Size = UDim2.new(1, -24, 0, 16)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextColor3 = Theme.TextDim
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = holder

    local valLabel = Instance.new("TextLabel")
    valLabel.BackgroundTransparency = 1
    valLabel.Position = UDim2.new(1, -50, 0, 6)
    valLabel.Size = UDim2.new(0, 40, 0, 16)
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 12
    valLabel.TextColor3 = Theme.Accent
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = tostring(val)
    valLabel.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 4)
    bar.Position = UDim2.new(0, 12, 1, -12)
    bar.BackgroundColor3 = Theme.Stroke
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Utils.Round(bar, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Utils.Round(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0)
    knob.BackgroundColor3 = Theme.Text
    knob.BorderSizePixel = 0
    knob.Parent = bar
    Utils.Round(knob, 6)

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            val = math.floor(min + (max - min) * rel + 0.5)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valLabel.Text = tostring(val)
            if callback then callback(val) end
        end
    end))

    return holder
end

function Widgets.Label(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Accent
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    return lbl
end

function Widgets.Input(text, placeholder, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundColor3 = Theme.BgLight
    holder.BorderSizePixel = 0
    Utils.Round(holder, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = Theme.Text
    box.PlaceholderText = placeholder or text
    box.PlaceholderColor3 = Theme.TextDim
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Text = ""
    box.Parent = holder

    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)

    return holder
end

-- ===================== MAIN GUI =====================
local Hub = {}

function Hub.Build()
    local gui = Instance.new("ScreenGui")
    gui.Name = HUB_ID
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = PlayerGui end

    NotifySys.Init(gui)

    local isMobile = Utils.IsMobile()
    local winW = isMobile and 320 or 560
    local winH = isMobile and 420 or 360

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.Size = UDim2.new(0, winW, 0, winH)
    window.Position = UDim2.new(0.5, -winW/2, 0.5, -winH/2)
    window.BackgroundColor3 = Theme.Bg
    window.BorderSizePixel = 0
    window.Active = true
    window.Draggable = false
    window.Parent = gui
    Utils.Round(window, 10)
    Utils.Stroke(window, Theme.Stroke, 1)

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Theme.BgLight
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window
    Utils.Round(titleBar, 10)

    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(1, 0, 0, 12)
    cover.Position = UDim2.new(0, 0, 1, -12)
    cover.BackgroundColor3 = Theme.BgLight
    cover.BorderSizePixel = 0
    cover.Parent = titleBar

    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0, 16, 0, 16)
    logoFrame.Position = UDim2.new(0, 14, 0, 12)
    logoFrame.BackgroundColor3 = Theme.Accent
    logoFrame.BorderSizePixel = 0
    logoFrame.Parent = titleBar
    Utils.Round(logoFrame, 4)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 38, 0, 6)
    title.Size = UDim2.new(1, -100, 0, 18)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Text = "Delta Hub"
    title.Parent = titleBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.BackgroundTransparency = 1
    versionLabel.Position = UDim2.new(0, 38, 0, 24)
    versionLabel.Size = UDim2.new(1, -100, 0, 12)
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 10
    versionLabel.TextColor3 = Theme.TextDim
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.TextYAlignment = Enum.TextYAlignment.Center
    versionLabel.Text = "v3.4.0 - BluezyGPT"
    versionLabel.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -33, 0.5, -13)
    closeBtn.BackgroundColor3 = Theme.Red
    closeBtn.Text = ""
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    Utils.Round(closeBtn, 6)

    local closeX = Instance.new("TextLabel")
    closeX.BackgroundTransparency = 1
    closeX.Size = UDim2.new(1, 0, 1, 0)
    closeX.Font = Enum.Font.GothamBold
    closeX.TextSize = 14
    closeX.TextColor3 = Theme.Text
    closeX.Text = "X"
    closeX.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        Utils.Tween(window, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.2)
        task.wait(0.22)
        gui:Destroy()
        NotifySys.Push("Delta Hub", "Unload สำเร็จ", "success")
    end)

    Utils.MakeDraggable(window, titleBar)

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -24, 0, 32)
    tabBar.Position = UDim2.new(0, 12, 0, 50)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = window

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabBar

    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -24, 1, -94)
    contentArea.Position = UDim2.new(0, 12, 0, 88)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = window

    local pages = {}
    local tabBtns = {}

    local function switchTab(name)
        for n, page in pairs(pages) do
            page.Visible = (n == name)
        end
        for n, btn in pairs(tabBtns) do
            Utils.Tween(btn, {BackgroundColor3 = (n == name) and Theme.Accent or Theme.BgLight})
        end
    end

    function Hub.AddTab(name, icon)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = Theme.BgLight
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = Theme.Text
        btn.Text = "  " .. name .. "  "
        btn.AutoButtonColor = false
        btn.Parent = tabBar
        Utils.Round(btn, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
        pad.Parent = btn

        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        tabBtns[name] = btn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Stroke
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = page

        pages[name] = page
        return page
    end

    function Hub.GetPages() return pages end
    function Hub.SwitchTab(name) switchTab(name) end

    if isMobile then
        local floatBtn = Instance.new("TextButton")
        floatBtn.Size = UDim2.new(0, 44, 0, 44)
        floatBtn.Position = UDim2.new(0, 12, 0.5, -22)
        floatBtn.BackgroundColor3 = Theme.Accent
        floatBtn.Text = "D"
        floatBtn.Font = Enum.Font.GothamBold
        floatBtn.TextSize = 18
        floatBtn.TextColor3 = Theme.Text
        floatBtn.Parent = gui
        Utils.Round(floatBtn, 22)
        Utils.MakeDraggable(floatBtn)

        floatBtn.MouseButton1Click:Connect(function()
            window.Visible = not window.Visible
            if window.Visible then
                Utils.Tween(window, {Size = UDim2.new(0, winW, 0, winH)}, 0.2)
            end
        end)
    end

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -65, 0.5, -13)
    minBtn.BackgroundColor3 = Theme.Card
    minBtn.Text = ""
    minBtn.AutoButtonColor = false
    minBtn.Parent = titleBar
    Utils.Round(minBtn, 6)

    local minIcon = Instance.new("TextLabel")
    minIcon.BackgroundTransparency = 1
    minIcon.Size = UDim2.new(1, 0, 1, 0)
    minIcon.Font = Enum.Font.GothamBold
    minIcon.TextSize = 14
    minIcon.TextColor3 = Theme.Text
    minIcon.Text = "_"
    minIcon.Parent = minBtn

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            contentArea.Visible = false
            tabBar.Visible = false
            Utils.Tween(window, {Size = UDim2.new(0, winW, 0, 40)}, 0.2)
        else
            Utils.Tween(window, {Size = UDim2.new(0, winW, 0, winH)}, 0.2, Enum.EasingDirection.Out)
            task.wait(0.2)
            contentArea.Visible = true
            tabBar.Visible = true
        end
    end)

    return Hub
end

-- ===================== FEATURES =====================
local Features = {}

Features.Speed = 16
Features.Jump  = 50
Features.InfJump = false
Features.Noclip = false
Features.Fly = false
Features.Esp = false
Features.Aimbot = false
Features.GodMode = false

local hrpConn, flyConn, espConn, noclipConn

function Features.ApplySpeed(val)
    Features.Speed = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val
    end
end

function Features.ApplyJump(val)
    Features.Jump = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = val
    end
end

function Features.ToggleInfJump(state)
    Features.InfJump = state
    if state then
        trackConn(UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    end
end

function Features.ToggleNoclip(state)
    Features.Noclip = state
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end
        end)
        trackConn(noclipConn)
    end
end

function Features.ToggleFly(state)
    Features.Fly = state
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if state then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        flyConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            bv.Velocity = move * 50
        end)
        trackConn(flyConn)
    else
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in ipairs(hrp:GetChildren()) do
                if v:IsA("BodyVelocity") then v:Destroy() end
            end
        end
    end
end

function Features.ToggleESP(state)
    Features.Esp = state
    if espConn then espConn:Disconnect() espConn = nil end
    if state then
        espConn = RunService.RenderStepped:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and not hrp:FindFirstChild("BzEsp") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "BzEsp"
                        hl.FillColor = Theme.Accent
                        hl.OutlineColor = Theme.Text
                        hl.FillTransparency = 0.6
                        hl.Parent = hrp
                    end
                end
            end
        end)
        trackConn(espConn)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("BzEsp") then
                    hrp.BzEsp:Destroy()
                end
            end
        end
    end
end

function Features.ToggleAimbot(state)
    Features.Aimbot = state
    if state then
        trackConn(RunService.RenderStepped:Connect(function()
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.RightButton) then return end
            local closest, dist = nil, math.huge
            local cam = workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                            if d < 200 and d < dist then
                                dist = d
                                closest = hrp
                            end
                        end
                    end
                end
            end
            if closest then
                cam.CFrame = CFrame.new(cam.CFrame.Position, closest.Position)
            end
        end))
    end
end

function Features.ToggleGodMode(state)
    Features.GodMode = state
    if state then
        trackConn(RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.MaxHealth = math.huge
                    hum.Health = math.huge
                end
            end
        end))
    end
end

-- ===================== SAE FEATURES =====================
-- Steal An Egg (PlaceId 107778070777162) specific features
-- All internals verified from working free scripts:
--   miracleverytime/miraclehub-stealegg, chaocauminhlason/steal-an-egg, etc.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local HttpService2      = game:GetService("HttpService")

-- SAE PlaceId — sanity check
local SAE_PLACE_ID = 107778070777162
local isSAE = (game.PlaceId == SAE_PLACE_ID)

-- ======== Module loader (cached) ========
local function safeRequire(getModule)
    local ok, mod = pcall(getModule)
    if ok and type(mod) == "table" then return mod end
    return nil
end

-- Cached module references (lazily loaded)
local EggState_m, AreaEggSlotIdentity_m, PlotState_m, PlotCmds_m
local Network_m, EggCmds_m, AssetCmds_m, BaseUpgrade_m
local ToolGameplayGuard_m, NotificationCmds_m, Save_m

local function loadModules()
    if not isSAE then return end
    local Client = ReplicatedStorage:FindFirstChild("Client")
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    if not Client then return end

    EggState_m        = safeRequire(function() return require(Client.EggState) end)
    AreaEggSlotIdentity_m = Shared and safeRequire(function() return require(Shared.Util.AreaEggSlotIdentity) end) or nil
    PlotState_m       = safeRequire(function() return require(Client.PlotState) end)
    PlotCmds_m        = safeRequire(function() return require(Client.PlotCmds) end)
    Network_m         = safeRequire(function() return require(Client.Network) end)
    EggCmds_m         = safeRequire(function() return require(Client.EggCmds) end)
    AssetCmds_m       = safeRequire(function() return require(Client.AssetCmds) end)
    BaseUpgrade_m     = safeRequire(function() return require(Client.BaseUpgrade) end)
    ToolGameplayGuard_m = safeRequire(function() return require(Client.ToolGameplayGuard) end)
    NotificationCmds_m = safeRequire(function() return require(Client.NotificationCmds.Message) end)
    Save_m            = Shared and safeRequire(function() return require(Shared.Save) end) or nil
end

-- Run once at script load
pcall(loadModules)

-- Helper: get character, humanoid, root
local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return char, hum, root
end

-- Helper: tween to position via Humanoid.MoveTo + AssemblyLinearVelocity propulsion
local function moveTo(target, opts)
    opts = opts or {}
    local _, hum, root = getChar()
    if not (hum and root) or hum.Health <= 0 then return false end

    local speed = math.clamp(opts.speed or 200, 16, 300)
    if math.abs(hum.WalkSpeed - speed) > 1 then
        pcall(function() hum.WalkSpeed = speed end)
    end

    local arrived = false
    local timeout = ((target - root.Position).Magnitude / speed) + 8
    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        _, hum, root = getChar()
        if not (hum and root) or hum.Health <= 0 then break end
        if opts.onStep and opts.onStep() then
            pcall(function() hum:MoveTo(root.Position) end)
            return false
        end
        local delta = target - root.Position
        local flatDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
        if flatDist < 5 then
            arrived = true
            break
        end
        local dir = delta.Unit
        pcall(function() hum:MoveTo(target) end)
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(
                dir.X * speed,
                root.AssemblyLinearVelocity.Y,
                dir.Z * speed
            )
        end)
        task.wait(0.03)
    end
    return arrived
end

-- ======== Auto Steal (Anti-hit + auto egg collect) ========
-- Pipeline: find target egg -> tween to it -> CarryFieldEgg -> bring back to safe zone
local stealActive = false
local stealThread = nil
local stealStats = { stolen = 0, failed = 0 }

local function getSafeZoneTarget()
    -- Use player's plot PetArea as fallback, then SeparationLine gate
    if PlotState_m then
        local ok, plot = pcall(PlotState_m.ResolvePlot, LocalPlayer)
        if ok and type(plot) == "table" and plot.PetArea and plot.PetArea:IsA("BasePart") then
            return plot.PetArea.Position
        end
    end
    -- Fallback: SeparationLine (back side = base)
    local areas = Workspace:FindFirstChild("__OBJECTS")
    areas = areas and areas:FindFirstChild("Areas")
    local sep = areas and areas:FindFirstChild("SeparationLine")
    if sep and sep:IsA("BasePart") then
        return sep.Position - sep.CFrame.LookVector * 10
    end
    return nil
end

local function isCarryingEgg()
    if not EggState_m or not EggState_m.ReadFieldEggs then return false end
    local ok, rows = pcall(function() return EggState_m.ReadFieldEggs() end)
    if not ok or type(rows) ~= "table" then return false end
    for _, r in ipairs(rows.Records or {}) do
        if r.State == "Carried" and r.CarrierUserId == LocalPlayer.UserId then
            return true
        end
    end
    return false
end

local function findStealTarget(root)
    if not EggState_m or not EggState_m.ReadFieldEggs then return nil end
    local ok, rows = pcall(function() return EggState_m.ReadFieldEggs() end)
    if not ok or type(rows) ~= "table" then return nil end

    local best, bestD = nil, math.huge
    local bestDrop, bestDropD = nil, math.huge
    for _, r in ipairs(rows.Records or {}) do
        if (r.State == "Slot" or r.State == "Dropped") and r.BottomCFrame then
            local pos = r.BottomCFrame.Position
            local d = (pos - root.Position).Magnitude
            if r.State == "Dropped" then
                if d < bestDropD then bestDropD, bestDrop = d, r end
            elseif d < bestD then
                bestD, best = d, r
            end
        end
    end
    return bestDrop or best
end

local function safeCarryEgg(rec)
    if not EggState_m or not EggState_m.CarryFieldEgg then return false, "no_module" end
    local slotKey = nil
    if AreaEggSlotIdentity_m and rec.Uid then
        local okK, key = pcall(function()
            return AreaEggSlotIdentity_m.SlotKey(rec.AreaId, rec.NestId)
        end)
        if okK then slotKey = key end
    end
    pcall(function() LocalPlayer:SetAttribute("AreaId", rec.AreaId) end)
    task.wait(0.15)
    local result, done = nil, false
    local th = task.spawn(function()
        local success, okBool, errMsg = pcall(EggState_m.CarryFieldEgg, rec.Uid, slotKey)
        if not success then
            result = { ok = false, err = tostring(okBool) }
        else
            result = { ok = okBool == true, err = okBool == true and nil or tostring(errMsg) }
        end
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < 8 do task.wait(0.05) end
    if not done then
        pcall(task.cancel, th)
        return false, "TIMEOUT"
    end
    return result.ok, result.err
end

local function enterGameplayArea()
    local _, hum, root = getChar()
    if not (hum and root) then return false end
    local areas = Workspace:FindFirstChild("__OBJECTS")
    areas = areas and areas:FindFirstChild("Areas")
    local sep = areas and areas:FindFirstChild("SeparationLine")
    if not sep or not sep:IsA("BasePart") then return false end
    local gate = sep.Position + Vector3.new(0, 2, 0) + sep.CFrame.LookVector * 2
    local gateBack = sep.Position + Vector3.new(0, 2, 0) - sep.CFrame.LookVector * 6
    pcall(function() hum.WalkSpeed = 45 end)
    if (root.Position - gateBack).Magnitude > 3 then
        pcall(function() root.CFrame = CFrame.lookAt(gateBack, gate) end)
        task.wait(0.3)
    end
    pcall(function() hum:MoveTo(gate) end)
    local t0 = os.clock()
    while os.clock() - t0 < 6 do
        task.wait(0.05)
        local _, _, r3 = getChar()
        if not r3 then break end
        if (r3.Position - gate).Magnitude < 3 then break end
    end
    pcall(function() hum:MoveTo(gate + sep.CFrame.LookVector * 5) end)
    task.wait(0.5)
    return true
end

local function startStealLoop()
    if stealActive then return end
    if not EggState_m then
        NotifySys.Push("SAE Steal", "EggState not loaded - rejoin game", "error")
        return
    end
    stealActive = true
    stealThread = task.spawn(function()
        NotifySys.Push("SAE Steal", "Auto steal started", "success")
        while stealActive do
            pcall(function()
                local _, _, root = getChar()
                if not root then return end
                if isCarryingEgg() then
                    -- Bring egg back to safe zone
                    local sz = getSafeZoneTarget()
                    if not sz then return end
                    pcall(function()
                        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:UnequipTools() end
                    end)
                    local dropped = false
                    moveTo(sz, {
                        speed = 250,
                        onStep = function()
                            if not isCarryingEgg() then
                                dropped = true
                                return true
                            end
                            return false
                        end,
                    })
                    if dropped or not isCarryingEgg() then
                        NotifySys.Push("SAE Steal", "Egg dropped - retrying", "warn")
                        task.wait(0.3)
                    else
                        -- Wait for server claim
                        local t0 = os.clock()
                        while os.clock() - t0 < 20 do
                            if not isCarryingEgg() then break end
                            task.wait(0.1)
                        end
                        if not isCarryingEgg() then
                            stealStats.stolen = stealStats.stolen + 1
                            NotifySys.Push("SAE Steal", "Delivered! Total: " .. stealStats.stolen, "success")
                        else
                            -- Force drop
                            if EggState_m.DropFieldEgg then
                                pcall(function() EggState_m.DropFieldEgg(nil) end)
                            end
                        end
                        task.wait(0.5)
                    end
                else
                    -- Find next egg
                    local target = findStealTarget(root)
                    if not target then
                        task.wait(1.5)
                    else
                        if moveTo(target.BottomCFrame.Position, { speed = 250 }) then
                            local okC, errC = safeCarryEgg(target)
                            if okC then
                                NotifySys.Push("SAE Steal", "Egg picked: " .. tostring(target.AssetCategory or target.Uid), "info")
                            else
                                if errC and tostring(errC):find("gameplay area") then
                                    enterGameplayArea()
                                    local okC2 = safeCarryEgg(target)
                                    if not okC2 then
                                        stealStats.failed = stealStats.failed + 1
                                        task.wait(0.5)
                                    end
                                else
                                    stealStats.failed = stealStats.failed + 1
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.1)
        end
    end)
end

local function stopStealLoop()
    stealActive = false
    if stealThread then
        pcall(task.cancel, stealThread)
        stealThread = nil
    end
end

function Features.ToggleAutoSteal(state)
    Features.AutoSteal = state
    if state then startStealLoop() else stopStealLoop() end
end

-- ======== Anti-Hit (for SAE: anti-AFK + safe-zone dodge) ========
local antiHitConn, antiAfkConn, antiAfkMoveThread
function Features.ToggleAntiHit(state)
    Features.AntiHit = state
    -- Clean previous
    if antiHitConn then antiHitConn:Disconnect() antiHitConn = nil end
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if antiAfkMoveThread then pcall(task.cancel, antiAfkMoveThread) antiAfkMoveThread = nil end

    if state then
        -- (1) Anti-damage: keep humanoid full health
        antiHitConn = RunService.Heartbeat:Connect(function()
            local _, hum = getChar()
            if not hum then return end
            if hum.Health < hum.MaxHealth and hum.MaxHealth > 0 then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
            pcall(function()
                if hum.PlatformStand then hum.PlatformStand = false end
            end)
        end)
        trackConn(antiHitConn)

        -- (2) Anti-AFK via VirtualUser (idle kick bypass)
        local VU = game:GetService("VirtualUser")
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
                task.wait(0.3)
                VU:Button1Down(Vector2.new())
                task.wait(0.3)
                VU:Button1Up(Vector2.new())
            end)
        end)
        trackConn(antiAfkConn)

        -- (3) Subtle idle motion (defeat "didn't move" detection)
        antiAfkMoveThread = task.spawn(function()
            while Features.AntiHit do
                local _, _, root = getChar()
                if root then
                    local offsetX = (math.random() - 0.5) * 1.0
                    local offsetZ = (math.random() - 0.5) * 1.0
                    local targetCF = root.CFrame + Vector3.new(offsetX, 0, offsetZ)
                    pcall(function()
                        TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad),
                            { CFrame = targetCF }):Play()
                    end)
                end
                task.wait(20 + math.random() * 10)
            end
        end)
    end
end

-- ======== Anti-Lag (universal — kill particles/shadows/cull distant) ========
local lagSavedSettings = {}
local lagCullConn
function Features.ToggleAntiLag(state)
    Features.AntiLag = state
    if state then
        lagSavedSettings.GlobalShadows = Lighting.GlobalShadows
        lagSavedSettings.FogEnd = Lighting.FogEnd
        lagSavedSettings.Brightness = Lighting.Brightness
        pcall(function() Lighting.GlobalShadows = false end)
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0

        for _, m in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if m:IsA("Texture") or m:IsA("Decal") then
                    m.Transparency = 1
                elseif m:IsA("ParticleEmitter") or m:IsA("Trail") or m:IsA("Sparkles") or m:IsA("Smoke") or m:IsA("Fire") then
                    m.Enabled = false
                    m.Rate = 0
                elseif m:IsA("BasePart") then
                    m.CastShadow = false
                    if m.Material == Enum.Material.Neon or m.Material == Enum.Material.Glass then
                        m.Material = Enum.Material.SmoothPlastic
                    end
                end
            end)
        end

        lagCullConn = RunService.Heartbeat:Connect(function()
            local _, _, root = getChar()
            if not root then return end
            for _, obj in ipairs(Workspace:GetChildren()) do
                pcall(function()
                    if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                        local dist = (obj:GetPivot().Position - root.Position).Magnitude
                        if dist > 800 then obj.Parent = nil end
                    end
                end)
            end
        end)
        trackConn(lagCullConn)

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end)

        NotifySys.Push("Anti-Lag", "FPS boost ON", "success")
    else
        if lagSavedSettings.GlobalShadows ~= nil then
            Lighting.GlobalShadows = lagSavedSettings.GlobalShadows
            Lighting.FogEnd = lagSavedSettings.FogEnd
            Lighting.Brightness = lagSavedSettings.Brightness
        end
        if lagCullConn then lagCullConn:Disconnect() lagCullConn = nil end
        NotifySys.Push("Anti-Lag", "Restored", "info")
    end
end

-- ======== Server Hop (universal — find 1-player servers) ========
local hopInProgress = false
local function fetchServers(placeId, cursor)
    cursor = cursor or ""
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&cursor=" .. (cursor or "")
    local body
    if request then
        local resp = request({Url = url, Method = "GET"})
        body = resp and resp.Body
    elseif syn and syn.request then
        local resp = syn.request({Url = url, Method = "GET"})
        body = resp and resp.Body
    else
        body = game:HttpGet(url)
    end
    if not body then return nil end
    local ok, data = pcall(function() return HttpService2:JSONDecode(body) end)
    if not ok or not data then return nil end
    return data
end

local function hopToLowPopServer()
    if hopInProgress then return end
    hopInProgress = true
    NotifySys.Push("Server Hop", "Searching for 1-player server...", "info")

    local placeId = game.PlaceId
    local targetJobId = nil
    local cursor = ""
    local tried = 0

    while not targetJobId and tried < 10 do
        tried = tried + 1
        local data = fetchServers(placeId, cursor)
        if not data or not data.data or #data.data == 0 then break end

        table.sort(data.data, function(a, b) return a.playing < b.playing end)

        for _, srv in ipairs(data.data) do
            if srv.playing == 1 then
                targetJobId = srv.id
                break
            end
        end

        if not targetJobId and data.data[1] and data.data[1].playing <= 3 then
            targetJobId = data.data[1].id
            break
        end

        cursor = data.nextPageCursor
        if not cursor or cursor == "" then break end
        task.wait(0.3)
    end

    if not targetJobId then
        NotifySys.Push("Server Hop", "No 1-player server found - retry later", "warn")
        hopInProgress = false
        return
    end

    NotifySys.Push("Server Hop", "Found - teleporting...", "success")
    task.wait(0.5)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, targetJobId, LocalPlayer)
    end)
    task.delay(15, function() hopInProgress = false end)
end

function Features.DoServerHop()
    hopToLowPopServer()
end

-- ======== SAE Helper: Teleport to Base ========
function Features.TeleportToBase()
    if not PlotCmds_m then
        NotifySys.Push("SAE", "PlotCmds not loaded", "error")
        return
    end
    local ok, cf = pcall(PlotCmds_m.GetRespawnPointCFrame)
    if not ok or typeof(cf) ~= "CFrame" then
        NotifySys.Push("SAE", "No respawn point", "error")
        return
    end
    local _, _, root = getChar()
    if not root then return end
    pcall(function()
        TweenService:Create(root, TweenInfo.new(0.4, Enum.EasingStyle.Quad),
            { CFrame = cf }):Play()
    end)
    NotifySys.Push("SAE", "Teleported to base", "success")
end

-- ======== SAE Helper: Hatch Ready Eggs ========
function Features.HatchReadyEggs()
    if not EggState_m then
        NotifySys.Push("SAE", "EggState not loaded", "error")
        return 0
    end
    local myRecords = {}
    if EggState_m.ReadOwnedEggs then
        local ok, recs = pcall(function() return EggState_m.ReadOwnedEggs() end)
        if ok and type(recs) == "table" then myRecords = recs end
    end
    local hatched = 0
    for uid, _ in pairs(myRecords) do
        if EggState_m.IsReadyToHatch and EggState_m.IsReadyToHatch(uid) then
            if EggState_m.BeginHatch then
                local ok = pcall(function() EggState_m.BeginHatch(uid) end)
                if ok then hatched = hatched + 1 end
            end
        end
    end
    NotifySys.Push("SAE Hatch", "Hatched " .. hatched .. " eggs", "success")
    return hatched
end

-- ======== SAE Helper: Skip Growth All ========
function Features.SkipGrowthAll()
    if not EggState_m or not EggState_m.BeginSkipGrowth then
        NotifySys.Push("SAE", "SkipGrowth unavailable", "error")
        return 0
    end
    local myRecords = {}
    if EggState_m.ReadOwnedEggs then
        local ok, recs = pcall(function() return EggState_m.ReadOwnedEggs() end)
        if ok and type(recs) == "table" then myRecords = recs end
    end
    local skipped = 0
    for uid, _ in pairs(myRecords) do
        local ok = pcall(function() EggState_m.BeginSkipGrowth(uid) end)
        if ok then skipped = skipped + 1 end
    end
    NotifySys.Push("SAE", "Skipped growth on " .. skipped .. " eggs", "success")
    return skipped
end

-- ======== SAE Helper: Upgrade Base ========
function Features.UpgradeBase()
    if not BaseUpgrade_m or not BaseUpgrade_m.PurchaseNextTier then
        NotifySys.Push("SAE", "BaseUpgrade unavailable", "error")
        return false
    end
    local ok, res = pcall(BaseUpgrade_m.PurchaseNextTier)
    if ok and res == true then
        NotifySys.Push("SAE", "Base upgraded!", "success")
    else
        NotifySys.Push("SAE", "Upgrade failed (not enough cash?)", "warn")
    end
    return ok and res == true
end



-- ===================== BUILD PAGES =====================
local ok = pcall(function()
    Hub.Build()

    local pageMain = Hub.AddTab("Main")
    local pageSAE = Hub.AddTab("SAE")
    local pageCombat = Hub.AddTab("Combat")
    local pageVisuals = Hub.AddTab("Visuals")
    local pagePlayer = Hub.AddTab("Player")
    local pageSettings = Hub.AddTab("Settings")

    local lblMain = Widgets.Label("QUICK ACTIONS")
    lblMain.Parent = pageMain
    local btnUnload = Widgets.Button("Unload Hub", function()
        NotifySys.Push("Delta Hub", "กำลังปิด...", "warn")
        task.wait(0.3)
        local g = CoreGui:FindFirstChild(HUB_ID)
        if g then g:Destroy() end
    end)
    btnUnload.Parent = pageMain
    local btnCopyDiscord = Widgets.Button("Copy Discord", function()
        if setclipboard then setclipboard("https://discord.gg/bluezygpt") end
        NotifySys.Push("Discord", "คัดลอกแล้ว", "success")
    end)
    btnCopyDiscord.Parent = pageMain
    local btnRejoin = Widgets.Button("Rejoin Server", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end)
    btnRejoin.Parent = pageMain

    -- ============= STEAL AN EGG TAB =============
    local lblSae = Widgets.Label("STEAL AN EGG (verified)")
    lblSae.Parent = pageSAE

    local togSteal = Widgets.Toggle("Auto Steal Eggs", false, function(s)
        Features.ToggleAutoSteal(s)
    end)
    togSteal.Parent = pageSAE

    local togAntiHit = Widgets.Toggle("Anti-Hit + Anti-AFK", false, function(s)
        Features.ToggleAntiHit(s)
    end)
    togAntiHit.Parent = pageSAE

    local togLag = Widgets.Toggle("Anti-Lag (FPS Boost)", false, function(s)
        Features.ToggleAntiLag(s)
    end)
    togLag.Parent = pageSAE

    local lblSaeActions = Widgets.Label("QUICK ACTIONS")
    lblSaeActions.Parent = pageSAE

    local btnHop = Widgets.Button("Server Hop (1-Player Server)", function()
        Features.DoServerHop()
    end)
    btnHop.Parent = pageSAE

    local btnTpBase = Widgets.Button("Teleport to Base", function()
        Features.TeleportToBase()
    end)
    btnTpBase.Parent = pageSAE

    local btnHatch = Widgets.Button("Hatch Ready Eggs", function()
        Features.HatchReadyEggs()
    end)
    btnHatch.Parent = pageSAE

    local btnSkip = Widgets.Button("Skip Growth All", function()
        Features.SkipGrowthAll()
    end)
    btnSkip.Parent = pageSAE

    local btnUpgrade = Widgets.Button("Upgrade Base", function()
        Features.UpgradeBase()
    end)
    btnUpgrade.Parent = pageSAE

    local lblSaeInfo = Widgets.Label("VERIFIED INTERNALS USED")
    lblSaeInfo.Parent = pageSAE
    local lblSaeDetail = Widgets.Label("EggState, PlotState, PlotCmds, BaseUpgrade, Network")
    lblSaeDetail.Parent = pageSAE

    local lblCombat = Widgets.Label("COMBAT FEATURES")
    lblCombat.Parent = pageCombat
    local togAimbot = Widgets.Toggle("Aimbot (Right-Click FOV)", false, function(s)
        Features.ToggleAimbot(s)
    end)
    togAimbot.Parent = pageCombat
    local togGod = Widgets.Toggle("God Mode", false, function(s)
        Features.ToggleGodMode(s)
    end)
    togGod.Parent = pageCombat
    local sldAimFov = Widgets.Slider("Aimbot FOV", 50, 500, 200, function(v)
    end)
    sldAimFov.Parent = pageCombat

    local lblVis = Widgets.Label("VISUAL FEATURES")
    lblVis.Parent = pageVisuals
    local togEsp = Widgets.Toggle("Player ESP (Highlight)", false, function(s)
        Features.ToggleESP(s)
    end)
    togEsp.Parent = pageVisuals
    local togTracers = Widgets.Toggle("Tracers", false, function(s)
        if s then
            NotifySys.Push("Tracers", "เปิดแล้ว", "success")
        else
            NotifySys.Push("Tracers", "ปิดแล้ว", "info")
        end
    end)
    togTracers.Parent = pageVisuals

    local lblPlayer = Widgets.Label("PLAYER MODIFIERS")
    lblPlayer.Parent = pagePlayer
    local sldSpeed = Widgets.Slider("Walk Speed", 16, 200, 16, function(v)
        Features.ApplySpeed(v)
    end)
    sldSpeed.Parent = pagePlayer
    local sldJump = Widgets.Slider("Jump Power", 50, 300, 50, function(v)
        Features.ApplyJump(v)
    end)
    sldJump.Parent = pagePlayer
    local togInfJump = Widgets.Toggle("Infinite Jump", false, function(s)
        Features.ToggleInfJump(s)
    end)
    togInfJump.Parent = pagePlayer
    local togNoclip = Widgets.Toggle("Noclip", false, function(s)
        Features.ToggleNoclip(s)
    end)
    togNoclip.Parent = pagePlayer
    local togFly = Widgets.Toggle("Fly (WASD+Space)", false, function(s)
        Features.ToggleFly(s)
    end)
    togFly.Parent = pagePlayer

    local lblSet = Widgets.Label("INTERFACE")
    lblSet.Parent = pageSettings
    local togKeybind = Widgets.Toggle("Show Keybind (RightCtrl)", true, function(s)
    end)
    togKeybind.Parent = pageSettings
    local btnReload = Widgets.Button("Reload Hub", function()
        local g = CoreGui:FindFirstChild(HUB_ID)
        if g then g:Destroy() end
        loadstring(game:HttpGet("https://raw.githubusercontent.com/lomigg/delta-hub-bz/main/main.lua"))()
    end)
    btnReload.Parent = pageSettings

    Hub.SwitchTab("Main")

    task.spawn(function()
        task.wait(0.5)
        NotifySys.Push("Delta Hub v3.4.0", "Loaded - Hello BZMEMBER", "success")
        task.wait(2)
        NotifySys.Push("Tip", "Right-Ctrl ซ่อน/แสดง - Drag title bar", "info")
    end)

    trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            local g = CoreGui:FindFirstChild(HUB_ID)
            if g then
                local w = g:FindFirstChild("Window")
                if w then w.Visible = not w.Visible end
            end
        end
    end))

    trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        char:WaitForChild("Humanoid").WalkSpeed = Features.Speed
        char.Humanoid.JumpPower = Features.Jump
    end))
end)

if not ok then
    warn("[Delta Hub] build error - check syntax")
    error("Delta Hub failed to initialize")
end
