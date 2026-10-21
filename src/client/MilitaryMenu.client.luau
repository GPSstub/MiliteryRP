--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local MobileUIRules=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MobileUIRules"))
local player = Players.LocalPlayer
local function isAdmin(): boolean
    -- Presentation only. The server never trusts this replicated attribute for
    -- permission checks; it uses a private GroupService rank cache.
    return player:GetAttribute("CanUseAdminCommands")==true
end
local gui = Instance.new("ScreenGui")
gui.Name = "MilitaryMenu"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10
local INK = Color3.fromRGB(23, 29, 26)
local PAPER = Color3.fromRGB(238, 237, 224)
local MUTED = Color3.fromRGB(163, 174, 157)
local ACCENT = Color3.fromRGB(192, 210, 150)
local function corner(object: GuiObject, radius: number)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
end
local function label(parent: Instance, name: string, text: string, size: number, color: Color3): TextLabel
    local t = Instance.new("TextLabel")
    t.Name = name; t.Text = text; t.TextSize = size
    t.Font = Enum.Font.GothamMedium; t.TextColor3 = color
    t.BackgroundTransparency = 1; t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end
local function button(parent: Instance, name: string, text: string): TextButton
    local b = Instance.new("TextButton")
    b.Name = name; b.Text = text; b.Font = Enum.Font.GothamBold; b.TextSize = 16
    b.TextColor3 = PAPER; b.BackgroundColor3 = INK; b.BorderSizePixel = 0
    b.AutoButtonColor = false; b.Selectable = true
    corner(b, 12)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(47, 59, 46)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = INK}):Play() end)
    b.Parent = parent
    return b
end
local toggle = button(gui, "MenuButton", "       메뉴")
for i = 1, 3 do
    local bar = Instance.new("Frame")
    bar.Name = "MenuIcon" .. i
    bar.Position = UDim2.fromOffset(24, 16 + (i - 1) * 7)
    bar.Size = UDim2.fromOffset(16, 2)
    bar.BackgroundColor3 = PAPER; bar.BorderSizePixel = 0; bar.Parent = toggle
end
toggle.AnchorPoint = Vector2.new(0, 1)
toggle.Position = UDim2.new(0, 20, 1, -20)
toggle.Size = UDim2.fromOffset(132, 48)
local toggleScale=Instance.new("UIScale")
toggleScale.Name="MobileDensity"
toggleScale.Parent=toggle
local flyout = Instance.new("Frame")
flyout.Name = "Navigation"; flyout.AnchorPoint = Vector2.new(0, 1)
flyout.Position = UDim2.new(0, 20, 1, -80)
flyout.Size = UDim2.fromOffset(224, if isAdmin() then 248 else 190)
flyout.BackgroundColor3 = INK; flyout.BorderSizePixel = 0; flyout.Visible = false
corner(flyout, 16); flyout.Parent = gui
local flyoutScale=Instance.new("UIScale")
flyoutScale.Name="MobileDensity"
flyoutScale.Parent=flyout
local eyebrow = label(flyout, "Eyebrow", "PERSONAL MENU", 11, MUTED)
eyebrow.Position = UDim2.fromOffset(18, 14); eyebrow.Size = UDim2.new(1, -36, 0, 20)
local shop = button(flyout, "ShopButton", "상점                       →")
shop.Position = UDim2.fromOffset(12, 46); shop.Size = UDim2.new(1, -24, 0, 52)
local passes = button(flyout, "GamePassButton", "게임패스                    →")
passes.Position=UDim2.fromOffset(12,104); passes.Size=UDim2.new(1,-24,0,52)
local admin = button(flyout, "AdminButton", "운영진 패널                  →")
admin.Position = UDim2.fromOffset(12, 162); admin.Size = UDim2.new(1, -24, 0, 52)
admin.Visible = isAdmin()
local adminNote = label(flyout, "AdminNote", "● Roblox 그룹 운영진", 11, ACCENT)
adminNote.Position = UDim2.fromOffset(18, 221); adminNote.Size = UDim2.new(1, -36, 0, 16)
adminNote.Visible = isAdmin()
local panel = Instance.new("Frame")
panel.Name = "ContentPanel"; panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5); panel.Size = UDim2.fromScale(0.88, 0.72)
panel.BackgroundColor3 = INK; panel.BorderSizePixel = 0; panel.Visible = false
corner(panel, 20); panel.Parent = gui
local cap = Instance.new("UISizeConstraint"); cap.MaxSize = Vector2.new(600, 400); cap.Parent = panel
local panelScale=Instance.new("UIScale")
panelScale.Name="MobileDensity"
panelScale.Parent=panel
local accent = Instance.new("Frame"); accent.Name = "Accent"
accent.Position = UDim2.fromOffset(24, 25); accent.Size = UDim2.fromOffset(4, 40)
accent.BackgroundColor3 = ACCENT; accent.BorderSizePixel = 0; corner(accent, 2); accent.Parent = panel
local section = label(panel, "Section", "SUPPLY STORE", 10, MUTED)
section.Position = UDim2.fromOffset(40, 23); section.Size = UDim2.new(1, -112, 0, 16)
local heading = label(panel, "Heading", "상점", 24, PAPER)
heading.Position = UDim2.fromOffset(40, 42); heading.Size = UDim2.new(1, -112, 0, 32)
local close = button(panel, "CloseButton", "×")
close.Position = UDim2.new(1, -62, 0, 18); close.Size = UDim2.fromOffset(44, 44); close.TextSize = 28
local line = Instance.new("Frame"); line.Position = UDim2.fromOffset(24, 90)
line.Size = UDim2.new(1, -48, 0, 1); line.BackgroundColor3 = MUTED; line.BackgroundTransparency = 0.8; line.BorderSizePixel = 0; line.Parent = panel
local empty = label(panel, "EmptyTitle", "아직 진열된 상품이 없어요", 20, PAPER)
empty.Position = UDim2.new(0, 24, 0.5, -10); empty.Size = UDim2.new(1, -48, 0, 52)
empty.TextXAlignment = Enum.TextXAlignment.Center; empty.TextWrapped = true
local subtitle = label(panel, "EmptyDescription", "새로운 보급품을 준비하고 있어요.", 14, MUTED)
subtitle.Position = UDim2.new(0, 24, 0.5, 48); subtitle.Size = UDim2.new(1, -48, 0, 48)
subtitle.TextXAlignment = Enum.TextXAlignment.Center; subtitle.TextWrapped = true
local footer = label(panel, "Footer", "MILITARY RP  /  STORE", 10, MUTED)
footer.Position = UDim2.new(0, 24, 1, -34); footer.Size = UDim2.new(1, -48, 0, 16)
local passCard=Instance.new("ScrollingFrame")
passCard.BorderSizePixel=0;passCard.ScrollBarThickness=4
passCard.CanvasSize=UDim2.fromOffset(0,202);passCard.ScrollingDirection=Enum.ScrollingDirection.Y
passCard.Name="GamePassCard"; passCard.BackgroundTransparency=1
passCard.Position=UDim2.fromOffset(24,106); passCard.Size=UDim2.new(1,-48,1,-152)
passCard.Visible=false; passCard.Parent=panel
local passTitle=label(passCard,"PassTitle","HK총 · HK416",22,PAPER)
passTitle.Size=UDim2.new(1,0,0,34)
local passDescription=label(passCard,"Description","HK416 영구 사용권\n30발 탄창 · 재장전 · 예비 탄약 무제한",14,MUTED)
passDescription.Position=UDim2.fromOffset(0,44); passDescription.Size=UDim2.new(1,0,0,68)
passDescription.TextWrapped=true
local buy=button(passCard,"BuyGamePass","확인 중…")
buy.AnchorPoint=Vector2.zero; buy.Position=UDim2.fromOffset(0,142); buy.Size=UDim2.new(1,0,0,48)
local passId=0
local sale=false
local price: number?=nil
local purchaseBusy=false
local function updatePass()
    local owned=player:GetAttribute("TrainingRifleOwned")==true
    local status=player:GetAttribute("TrainingRifleOwnershipStatus")
    local ready=passId>0 and sale and not owned and not purchaseBusy
    buy.Active=ready; buy.Selectable=ready
    buy.Text=if owned then "✓ 보유 중" elseif purchaseBusy then "구매 창 여는 중…"
        elseif passId<=0 then "상품 확인 중…" elseif not sale then "현재 판매하지 않는 상품입니다"
        else "구매하기"..(if price then " · "..tostring(price).." Robux" else "")
    if status=="error" and not owned then buy.Text="구매하기 · 소유 여부 확인 지연" end
end
local function loadPass()
    local id=ReplicatedStorage:GetAttribute("TrainingRifleGamePassId")
    if type(id)~="number" or id<=0 then return end
    passId=id
    task.spawn(function()
        local ok,info=pcall(function()
            return MarketplaceService:GetProductInfoAsync(id,Enum.InfoType.GamePass)
        end)
        if id~=passId then return end
        sale=ok and info.IsForSale==true
        price=if ok and type(info.PriceInRobux)=="number" then info.PriceInRobux else nil
        if ok then passTitle.Text=tostring(info.Name).." · HK416" end
        updatePass()
        if not ok then buy.Text="상품을 불러오지 못했습니다 · 탭을 다시 열어 주세요" end
    end)
end
buy.Activated:Connect(function()
    if purchaseBusy or not sale or passId<=0 or player:GetAttribute("TrainingRifleOwned")==true then return end
    purchaseBusy=true;updatePass()
    local ok=pcall(function() MarketplaceService:PromptGamePassPurchase(player,passId) end)
    purchaseBusy=false;updatePass()
    if not ok then buy.Text="구매 창을 열지 못했습니다 · 다시 시도" end
end)
player:GetAttributeChangedSignal("TrainingRifleOwned"):Connect(updatePass)
player:GetAttributeChangedSignal("TrainingRifleOwnershipStatus"):Connect(updatePass)
ReplicatedStorage:GetAttributeChangedSignal("TrainingRifleGamePassId"):Connect(loadPass)
loadPass()
local function layoutMenu()
    local size=gui.AbsoluteSize
    local density=MobileUIRules.forViewport(size.X,size.Y,UserInputService.TouchEnabled)
    local compact=density.compact
    local management=panel:GetAttribute("Page")=="admin"
    panelScale.Scale=density.scale
    toggleScale.Scale=if compact then density.scale else 1
    flyoutScale.Scale=if compact then density.scale else 1
    if compact then
        -- Keep margins on phone screens while shrinking every descendant
        -- (including admin buttons and scrolling content) by the same factor.
        panel.Size=UDim2.fromOffset(
            math.max(220,size.X*density.widthCoverage/density.scale),
            math.max(220,size.Y*density.heightCoverage/density.scale)
        )
        cap.MaxSize=Vector2.new(1500,1500)
    else
        panel.Size=if management then UDim2.fromScale(0.94,0.9) else UDim2.fromScale(0.88,0.72)
        cap.MaxSize=if management then Vector2.new(1024,760) else Vector2.new(600,400)
    end
    local touch=UserInputService.TouchEnabled and compact
    toggle.AnchorPoint=if touch then Vector2.zero else Vector2.new(0,1)
    toggle.Position=if touch then UDim2.fromOffset(8,8) else UDim2.new(0,20,1,-20)
    toggle.Size=UDim2.fromOffset(if touch then 112 else 132,48)
    flyout.AnchorPoint=if touch then Vector2.zero else Vector2.new(0,1)
    flyout.Position=if touch then UDim2.fromOffset(8,64) else UDim2.new(0,20,1,-80)
    local short=compact and size.Y<420
    local row=if short then 44 else 52
    shop.Position=UDim2.fromOffset(12,if short then 8 else 46)
    passes.Position=UDim2.fromOffset(12,if short then 56 else 104)
    admin.Position=UDim2.fromOffset(12,if short then 104 else 162)
    for _,b in {shop,passes,admin} do b.Size=UDim2.new(1,-24,0,row) end
    eyebrow.Visible=not short;adminNote.Visible=isAdmin() and not short
    flyout.Size=UDim2.fromOffset(math.min(224,(size.X-16)/flyoutScale.Scale),if short then (if isAdmin() then 156 else 108) else (if isAdmin() then 248 else 190))
    local shortHeader=compact and management
    heading.Position=UDim2.fromOffset(24,if shortHeader then 16 else 42)
    heading.TextSize=if shortHeader then 18 else 24
    section.Visible=not shortHeader;accent.Visible=not shortHeader
    line.Position=UDim2.fromOffset(24,if shortHeader then 63 else 90)
    footer.Visible=not shortHeader
    passCard.Size=UDim2.new(1,-48,1,if compact then -122 else -152)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutMenu)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(layoutMenu)
local adminMount: ((boolean)->())?=nil
local function showAdmin(visible: boolean)
    if not visible then
        if adminMount then adminMount(false) end
        return
    end
    if not isAdmin() then return end
    if not adminMount then
        adminMount=require(script.Parent:WaitForChild("AdminPanel")).mount(panel)
    end
    adminMount(true)
end
local function selectForGamepad(object: GuiObject?)
    if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then GuiService.SelectedObject = object end
end
local function dismiss()
    panel.Visible = false; flyout.Visible = false; showAdmin(false)
    toggle.Text = "       메뉴"
    selectForGamepad(toggle)
end
local function openPage(page: string)
    if page == "admin" and not isAdmin() then return end
    flyout.Visible = false; panel.Visible = true; toggle.Text = "       메뉴"
    local management = page == "admin"
    showAdmin(management)
    empty.Visible = page=="shop"; subtitle.Visible = page=="shop"
    passCard.Visible=page=="passes"
    if page=="passes" then loadPass();updatePass() end
    cap.MaxSize = if management then Vector2.new(1024, 760) else Vector2.new(600, 400)
    panel.Size = if management then UDim2.fromScale(0.94, 0.9) else UDim2.fromScale(0.88, 0.72)
    panel:SetAttribute("Page", page)
    heading.Text = if management then "어드민 패널" elseif page=="passes" then "게임패스" else "상점"
    section.Text = if management then "GROUP  /  OPERATIONS" else "SUPPLY STORE"
    empty.Text = if management then "관리 기능 준비 중" else "아직 진열된 상품이 없어요"
    subtitle.Text = if management then "필요한 관리 기능을 여기에 추가할 예정이에요." else "새로운 보급품을 준비하고 있어요."
    footer.Text = if management then "MILITARY RP  /  GROUP OPERATIONS" else "MILITARY RP  /  STORE"
    layoutMenu()
    selectForGamepad(close)
end
toggle.Activated:Connect(function()
    local opening = not flyout.Visible
    panel.Visible = false; flyout.Visible = opening; showAdmin(false)
    toggle.Text = if opening then "×   닫기" else "       메뉴"
    selectForGamepad(if opening then shop else toggle)
end)
shop.Activated:Connect(function() openPage("shop") end)
passes.Activated:Connect(function() openPage("passes") end)
admin.Activated:Connect(function() openPage("admin") end)
local function updateAdminAccess()
    local can=isAdmin()
    admin.Visible=can
    adminNote.Visible=can
    flyout.Size=UDim2.fromOffset(224,if can then 248 else 190)
    layoutMenu()
    if not can and panel.Visible and panel:GetAttribute("Page")=="admin" then
        dismiss()
    end
end
player:GetAttributeChangedSignal("CanUseAdminCommands"):Connect(updateAdminAccess)
updateAdminAccess()
close.Activated:Connect(dismiss)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.ButtonB and (panel.Visible or flyout.Visible) then dismiss() end
end)
-- Admin actions are validated separately by AdminService on the server.
gui.Parent = player:WaitForChild("PlayerGui")
layoutMenu()
