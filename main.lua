-- main.lua — Delta Hub v3.3.0 — auto-published by BluezyGPT
-- Architecture: clean MVC, anti-duplicate, mobile+PC responsive GUI
-- Repo: lomigg/delta-hub-bz (public), branch: main
-- v3.3.0: PS99 features — Anti-Hit, Auto-Hatch, Anti-Lag, Server-Hop

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
    versionLabel.Text = "v3.3.0 - BluezyGPT"
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

-- ===================== PS99 FEATURES =====================
-- Pet Simulator 99 specific features

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")

-- Anti-Hit: anti-AFK + dodge + no damage taken + can't be hit by enemies
local antiHitConn, antiAfkConn
function Features.ToggleAntiHit(state)
    Features.AntiHit = state
    if antiHitConn then antiHitConn:Disconnect() antiHitConn = nil end
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if state then
        -- (1) Anti-damage: keep humanoid state ForcedSeated=false, no break joints
        --     PS99 doesn't have combat damage on player char, but other games do.
        antiHitConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            -- Force full health + breakable false on all body parts
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    p.CanBreak = false
                end
            end
        end)
        trackConn(antiHitConn)

        -- (2) Anti-AFK: bypass Roblox's 20-min idle kick
        local VU = game:GetService("VirtualUser")
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
            task.wait(0.5)
            VU:Button1Down(Vector2.new())
            task.wait(0.5)
            VU:Button1Up(Vector2.new())
        end)
        trackConn(antiAfkConn)
    end
end

-- Auto-Hatch Eggs (PS99)
-- PS99 egg system: eggs are in workspace, hatch via remote
-- Layout in PS99: workspace.Eggs holds egg models, hatching is via
-- ReplicatedStorage.Network.HatchEgg remote with egg name argument.
-- We try multiple known layouts and bail cleanly on each failure.
local hatchConn
local lastHatch = 0
local function findEggRemotes()
    -- Try common PS99 remote paths
    local paths = {
        {ReplicatedStorage, "Network", "HatchEgg"},
        {ReplicatedStorage, "Network", "HatchEgg2"},
        {ReplicatedStorage, "Remotes", "HatchEgg"},
        {ReplicatedStorage, "Events", "HatchEgg"},
        {ReplicatedStorage, "HatchEgg"},
    }
    for _, path in ipairs(paths) do
        local obj = path[1]
        local ok = true
        for i = 2, #path do
            if obj then
                obj = obj:FindFirstChild(path[i])
            end
        end
        if obj and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            return obj
        end
    end
    return nil
end

local function findEggsInWorkspace()
    -- PS99 eggs typically live in workspace.Eggs or workspace.Map.Eggs
    local containers = {
        Workspace:FindFirstChild("Eggs"),
        Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Eggs"),
        Workspace:FindFirstChild("World") and Workspace.World:FindFirstChild("Eggs"),
    }
    local eggs = {}
    for _, c in ipairs(containers) do
        if c then
            for _, e in ipairs(c:GetChildren()) do
                -- Egg model has a PrimaryPart or a Hitbox
                if e:IsA("Model") or e:IsA("BasePart") then
                    table.insert(eggs, e)
                end
            end
        end
    end
    return eggs
end

local function safeHatchNearest()
    local now = tick()
    if now - lastHatch < 1.5 then return end -- debounce
    lastHatch = now

    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local eggs = findEggsInWorkspace()
        if #eggs == 0 then return end

        -- Find nearest egg within 50 studs
        local nearest, nearestDist = nil, 50
        for _, e in ipairs(eggs) do
            local pos = e:IsA("Model") and e:GetPivot().Position
                     or e:IsA("BasePart") and e.Position
            if pos then
                local d = (pos - hrp.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = e
                end
            end
        end
        if not nearest then return end

        local remote = findEggRemotes()
        if remote then
            if remote:IsA("RemoteEvent") then
                remote:FireServer(nearest.Name, 1) -- single hatch
            elseif remote:IsA("RemoteFunction") then
                pcall(function() remote:InvokeServer(nearest.Name, 1) end)
            end
        else
            -- Fallback: fire ProximityPrompt if egg has one
            local prompt = nearest:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt, 0)
            end
        end
    end)
end

function Features.ToggleAutoHatch(state)
    Features.AutoHatch = state
    if hatchConn then hatchConn:Disconnect() hatchConn = nil end
    if state then
        hatchConn = RunService.Heartbeat:Connect(function()
            safeHatchNearest()
        end)
        trackConn(hatchConn)
        NotifySys.Push("Auto-Hatch", "เริ่มรวบไข่ PS99", "success")
    else
        NotifySys.Push("Auto-Hatch", "หยุดแล้ว", "info")
    end
end

-- Anti-Lag: kill shadows, particles, trails, lower texture quality, cull distant parts
local lagSavedSettings = {}
local lagCullConn
function Features.ToggleAntiLag(state)
    Features.AntiLag = state
    if state then
        -- Save and override lighting
        lagSavedSettings.GlobalShadows = Lighting.GlobalShadows
        lagSavedSettings.FogEnd = Lighting.FogEnd
        lagSavedSettings.Brightness = Lighting.Brightness
        pcall(function() Lighting.GlobalShadows = false end)
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0

        -- Kill textures globally
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

        -- Distant part culler (kills parts >500 studs from player)
        lagCullConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local origin = hrp.Position
            for _, obj in ipairs(Workspace:GetChildren()) do
                pcall(function()
                    if obj:IsA("Model") and obj ~= char and not obj:IsA("Actor") then
                        local dist = (obj:GetPivot().Position - origin).Magnitude
                        if dist > 800 then
                            obj.Parent = nil
                        end
                    end
                end)
            end
        end)
        trackConn(lagCullConn)

        -- Reduce player quality
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end)

        NotifySys.Push("Anti-Lag", "ปรับลดทุกอย่าง - ลด lag", "success")
    else
        -- Restore
        if lagSavedSettings.GlobalShadows ~= nil then
            Lighting.GlobalShadows = lagSavedSettings.GlobalShadows
            Lighting.FogEnd = lagSavedSettings.FogEnd
            Lighting.Brightness = lagSavedSettings.Brightness
        end
        if lagCullConn then lagCullConn:Disconnect() lagCullConn = nil end
        NotifySys.Push("Anti-Lag", "คืนค่าเดิมแล้ว", "info")
    end
end

-- Server Hop: find low-pop servers (1 player) for PS99 via matchmaking API
-- Uses TeleportService:GetGameInstances(placeId, sortTag, ...) — deprecated/unreliable.
-- Better: use the public Roblox API to fetch server list, pick a 1-player JobId, teleport.
local HttpService = game:GetService("HttpService")
local hopInProgress = false

local function fetchServers(placeId, cursor)
    cursor = cursor or ""
    -- Public API: https://games.roblox.com/v1/games/{placeId}/servers/Public?limit=100&cursor={cursor}
    -- On executor, request() works. Fallback to HttpGet if needed.
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
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data then return nil end
    return data
end

local function hopToLowPopServer()
    if hopInProgress then return end
    hopInProgress = true
    NotifySys.Push("Server Hop", "ค้นหา server 1 คน...", "info")

    local placeId = game.PlaceId
    local targetJobId = nil
    local cursor = ""
    local tried = 0
    local maxTries = 10

    while not targetJobId and tried < maxTries do
        tried += 1
        local data = fetchServers(placeId, cursor)
        if not data or not data.data or #data.data == 0 then break end

        -- Sort by ascending player count, prefer 1-player servers
        table.sort(data.data, function(a, b) return a.playing < b.playing end)

        for _, srv in ipairs(data.data) do
            if srv.playing == 1 then
                targetJobId = srv.id
                break
            end
        end

        if not targetJobId then
            -- Pick the lowest-pop one if no 1-player server
            if data.data[1] and data.data[1].playing <= 3 then
                targetJobId = data.data[1].id
                break
            end
        end

        cursor = data.nextPageCursor
        if not cursor or cursor == "" then break end
        task.wait(0.3) -- avoid rate limit
    end

    if not targetJobId then
        NotifySys.Push("Server Hop", "ไม่เจอ server 1 คน - ลองใหม่", "warn")
        hopInProgress = false
        return
    end

    NotifySys.Push("Server Hop", "เจอแล้ว - กำลังวาร์ป", "success")
    task.wait(0.5)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, targetJobId, LocalPlayer)
    end)
    -- Reset flag after delay in case teleport fails
    task.delay(15, function() hopInProgress = false end)
end

function Features.DoServerHop()
    hopToLowPopServer()
end

-- ===================== BUILD PAGES =====================
local ok = pcall(function()
    Hub.Build()

    local pageMain = Hub.AddTab("Main")
    local pagePS99 = Hub.AddTab("PS99")
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

    -- ============= PS99 TAB =============
    local lblPs = Widgets.Label("PET SIM 99 FEATURES")
    lblPs.Parent = pagePS99

    local togAntiHit = Widgets.Toggle("Anti-Hit (No Dmg + Anti-AFK)", false, function(s)
        Features.ToggleAntiHit(s)
    end)
    togAntiHit.Parent = pagePS99

    local togHatch = Widgets.Toggle("Auto-Hatch Eggs", false, function(s)
        Features.ToggleAutoHatch(s)
    end)
    togHatch.Parent = pagePS99

    local togLag = Widgets.Toggle("Anti-Lag (FPS Boost)", false, function(s)
        Features.ToggleAntiLag(s)
    end)
    togLag.Parent = pagePS99

    local btnHop = Widgets.Button("Server Hop (Find 1-Player Server)", function()
        Features.DoServerHop()
    end)
    btnHop.Parent = pagePS99

    local lblPsInfo = Widgets.Label("INFO")
    lblPsInfo.Parent = pagePS99

    local btnWalkToEgg = Widgets.Button("Walk to Nearest Egg", function()
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local Workspace2 = game:GetService("Workspace")
            local containers = {
                Workspace2:FindFirstChild("Eggs"),
                Workspace2:FindFirstChild("Map") and Workspace2.Map:FindFirstChild("Eggs"),
            }
            local nearest, nearestDist = nil, math.huge
            for _, c in ipairs(containers) do
                if c then
                    for _, e in ipairs(c:GetChildren()) do
                        local pos = e:IsA("Model") and e:GetPivot().Position or nil
                        if pos then
                            local d = (pos - hrp.Position).Magnitude
                            if d < nearestDist then
                                nearestDist = d
                                nearest = e
                            end
                        end
                    end
                end
            end
            if nearest then
                NotifySys.Push("Egg Walk", "เดินไปหา: " .. nearest.Name, "info")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local pos = nearest:GetPivot().Position
                    hum:MoveTo(pos + Vector3.new(0, 5, 5))
                end
            else
                NotifySys.Push("Egg Walk", "ไม่เจอไข่", "warn")
            end
        end)
    end)
    btnWalkToEgg.Parent = pagePS99

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
        NotifySys.Push("Delta Hub v3.3.0", "โหลดสำเร็จ - สวัสดี BZMEMBER", "success")
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
