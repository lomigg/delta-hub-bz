-- main.lua — Delta Hub v3.2.0 — auto-published by BluezyGPT
-- Architecture: clean MVC, anti-duplicate, mobile+PC responsive GUI
-- Repo: BZMEMBER/delta-hub (private), branch: main

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
    btn.BackgroundColor3 = Theme.BgLight
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = nil
    Utils.Round(btn, 6)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
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
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Theme.BgLight
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Theme.Text
    btn.Text = text
    btn.AutoButtonColor = false
    Utils.Round(btn, 6)

    btn.MouseButton1Enter:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.Card})
    end)
    btn.MouseButton1Leave:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.BgLight})
    end)
    btn.MouseButton1Click:Connect(function()
        Utils.Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.08)
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
    holder.BackgroundColor3 = Theme.BgLight
    holder.BorderSizePixel = 0
    Utils.Round(holder, 6)

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

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Δ Delta Hub"
    title.Parent = titleBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.BackgroundTransparency = 1
    versionLabel.Position = UDim2.new(0, 14, 0, 22)
    versionLabel.Size = UDim2.new(1, -100, 0, 12)
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.TextSize = 10
    versionLabel.TextColor3 = Theme.TextDim
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.Text = "v3.2.0 · by BluezyGPT for BZMEMBER"
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
    closeX.Text = "×"
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
        btn.Size = UDim2.new(0, 80, 1, 0)
        btn.BackgroundColor3 = Theme.BgLight
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.TextColor3 = Theme.Text
        btn.Text = (icon or "□") .. "  " .. name
        btn.AutoButtonColor = false
        btn.Parent = tabBar
        Utils.Round(btn, 6)

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
        floatBtn.Text = "Δ"
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
    minIcon.Text = "—"
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

-- ===================== BUILD PAGES =====================
local ok = pcall(function()
    Hub.Build()

    local pageMain = Hub.AddTab("Main", "■")
    local pageCombat = Hub.AddTab("Combat", "⚔")
    local pageVisuals = Hub.AddTab("Visuals", "👁")
    local pagePlayer = Hub.AddTab("Player", "⚽")
    local pageSettings = Hub.AddTab("Settings", "⚙")

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
        loadstring(game:HttpGet("RAW_URL_PLACEHOLDER/main.lua"))()
    end)
    btnReload.Parent = pageSettings

    Hub.SwitchTab("Main")

    task.spawn(function()
        task.wait(0.5)
        NotifySys.Push("Delta Hub v3.2.0", "โหลดสำเร็จ — สวัสดี BZMEMBER", "success")
        task.wait(2)
        NotifySys.Push("Tip", "Right-Ctrl ซ่อน/แสดง · Drag title bar", "info")
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
    warn("[Delta Hub] build error — check syntax")
    error("Delta Hub failed to initialize")
end
