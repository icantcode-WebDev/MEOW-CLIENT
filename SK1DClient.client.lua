local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local package = ReplicatedStorage:WaitForChild("SK1D")
local Core = package:WaitForChild("Core")
local Systems = package:WaitForChild("Systems")
local Modules = package:WaitForChild("Modules")

local SettingsManager = require(Core:WaitForChild("SettingsManager"))
local ModuleManager = require(Core:WaitForChild("ModuleManager"))
local KeybindManager = require(Core:WaitForChild("KeybindManager"))
local NotificationManager = require(Systems:WaitForChild("NotificationManager"))
local AdvancedSuite = require(Systems:WaitForChild("AdvancedSuite"))
local Visuals = require(Modules:WaitForChild("Visuals"))
local HUD = require(Modules:WaitForChild("HUD"))

local C = {
	BG = Color3.fromRGB(10, 10, 13),
	Panel = Color3.fromRGB(17, 17, 22),
	Card = Color3.fromRGB(23, 23, 29),
	Stroke = Color3.fromRGB(49, 43, 50),
	Text = Color3.fromRGB(240, 239, 244),
	Muted = Color3.fromRGB(145, 142, 153),
	Red = Color3.fromRGB(229, 53, 72),
	RedDark = Color3.fromRGB(92, 24, 37),
	Green = Color3.fromRGB(73, 205, 140),
}

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do object[key] = value end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function stroke(parent, color, transparency)
	make("UIStroke", { Color = color or C.Stroke, Transparency = transparency or 0.2, Thickness = 1 }, parent)
end

local gui = make("ScreenGui", {
	Name = "SK1D_CLIENTOOL",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local toastLayer = make("Frame", { Name = "ToastLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local notifications = NotificationManager.new(toastLayer)
local function notify(kind, message) notifications:Push(kind, message) end
local advancedSuite = AdvancedSuite.Mount({
	Player = player,
	PlayerGui = playerGui,
	Notify = notify,
})

local settings = SettingsManager.new()
local manager = ModuleManager.new(settings, notify)
local keybinds = KeybindManager.new()
Visuals.Register(manager)
HUD.Register(manager, gui)

local window = make("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(900, 570),
	BackgroundColor3 = C.BG,
	BorderSizePixel = 0,
}, gui)
corner(window, 14); stroke(window, C.RedDark, 0.05)

local scale = make("UIScale", { Scale = 1 }, window)
local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	scale.Scale = math.clamp(math.min(viewport.X / 1050, viewport.Y / 700), 0.62, 1)
end
updateScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local top = make("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, window)
corner(top, 14)
make("Frame", { Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, top)
make("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0 }, top)

local brandMark = make("Frame", { Position = UDim2.fromOffset(17, 14), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.RedDark, BorderSizePixel = 0 }, top)
corner(brandMark, 9)
make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "S", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 17 }, brandMark)
make("TextLabel", { Position = UDim2.fromOffset(57, 10), Size = UDim2.fromOffset(220, 22), BackgroundTransparency = 1, Text = "SK1D CLIENTOOL", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, top)
make("TextLabel", { Position = UDim2.fromOffset(57, 30), Size = UDim2.fromOffset(220, 15), BackgroundTransparency = 1, Text = "VISUAL CONTROL  /  CLIENT BUILD", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left }, top)

local activeCount = make("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -105, 0.5, 0), Size = UDim2.fromOffset(115, 26), BackgroundColor3 = C.Card, TextColor3 = C.Muted, Font = Enum.Font.GothamMedium, TextSize = 10, Text = "0 ACTIVE", BorderSizePixel = 0 }, top)
corner(activeCount, 7)
local advancedButton = make("TextButton", { Position = UDim2.new(1, -330, 0, 14), Size = UDim2.fromOffset(112, 27), BackgroundColor3 = C.RedDark, Text = "ADVANCED  ↗", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, top)
corner(advancedButton, 7)
advancedButton.MouseButton1Click:Connect(function() advancedSuite:Open() end)

local minimize = make("TextButton", { Position = UDim2.new(1, -76, 0, 14), Size = UDim2.fromOffset(27, 27), BackgroundColor3 = C.Card, Text = "—", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0 }, top)
corner(minimize, 7)
local close = make("TextButton", { Position = UDim2.new(1, -42, 0, 14), Size = UDim2.fromOffset(27, 27), BackgroundColor3 = C.RedDark, Text = "×", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 17, BorderSizePixel = 0 }, top)
corner(close, 7)

local sidebar = make("Frame", { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(0, 180, 1, -58), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, window)
local content = make("Frame", { Position = UDim2.fromOffset(180, 58), Size = UDim2.new(1, -180, 1, -58), BackgroundTransparency = 1 }, window)

local navList = make("Frame", { Position = UDim2.fromOffset(12, 18), Size = UDim2.new(1, -24, 1, -36), BackgroundTransparency = 1 }, sidebar)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navList)

local categories = { "Favorites", "Combat", "Movement", "Player", "Visuals", "Cosmetics", "Misc", "HUD", "Configs", "Settings" }
local selectedCategory = "Visuals"
local searchText = ""
local enabledOnly = false
local renderCards
local showConfig

local heading = make("TextLabel", { Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 28), BackgroundTransparency = 1, Text = "VISUALS", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left }, content)
local subtitle = make("TextLabel", { Position = UDim2.fromOffset(24, 46), Size = UDim2.new(1, -48, 0, 18), BackgroundTransparency = 1, Text = "Local visual adjustments and approved test-target tools.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, content)

local search = make("TextBox", { Position = UDim2.fromOffset(24, 78), Size = UDim2.new(1, -250, 0, 36), BackgroundColor3 = C.Panel, PlaceholderText = "Search modules...", PlaceholderColor3 = C.Muted, Text = "", TextColor3 = C.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, BorderSizePixel = 0 }, content)
corner(search, 8); stroke(search)
local filterButton = make("TextButton", { Position = UDim2.new(1, -205, 0, 78), Size = UDim2.fromOffset(92, 36), BackgroundColor3 = C.Panel, Text = "ALL MODULES", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, content)
corner(filterButton, 8); stroke(filterButton)
local settingsButton = make("TextButton", { Position = UDim2.new(1, -104, 0, 78), Size = UDim2.fromOffset(80, 36), BackgroundColor3 = C.RedDark, Text = "CONFIG", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, content)
corner(settingsButton, 8)

local cardScroll = make("ScrollingFrame", { Position = UDim2.fromOffset(24, 128), Size = UDim2.new(1, -48, 1, -152), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Red, CanvasSize = UDim2.fromOffset(0, 0) }, content)
local cardLayout = make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, cardScroll)
cardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	cardScroll.CanvasSize = UDim2.fromOffset(0, cardLayout.AbsoluteContentSize.Y + 8)
end)

local configPanel = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 126), Size = UDim2.fromOffset(285, 340), BackgroundColor3 = C.Panel, BorderSizePixel = 0, Visible = false, ZIndex = 10 }, content)
corner(configPanel, 12); stroke(configPanel, C.RedDark, 0.1)
local configTitle = make("TextLabel", { Position = UDim2.fromOffset(15, 13), Size = UDim2.new(1, -30, 0, 24), BackgroundTransparency = 1, Text = "MODULE SETTINGS", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 }, configPanel)
local configBody = make("Frame", { Position = UDim2.fromOffset(14, 47), Size = UDim2.new(1, -28, 1, -60), BackgroundTransparency = 1, ZIndex = 11 }, configPanel)
local configLayout = make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, configBody)

local function clearConfig()
	for _, child in ipairs(configBody:GetChildren()) do
		if child:IsA("GuiObject") and child ~= configLayout then child:Destroy() end
	end
end

showConfig = function(module)
	clearConfig()
	configPanel.Visible = true
	configTitle.Text = string.upper(module.Name) .. "  /  SETTINGS"
	local description = make("TextLabel", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = module.Description, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, configBody)
	for key, value in pairs(module.Settings) do
		if type(value) == "number" then
			local wrap = make("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = 2 }, configBody)
			make("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = key .. "  ·  " .. tostring(value), TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, wrap)
			local slider = make("TextButton", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 23), BackgroundColor3 = C.Card, Text = "−       DECREASE          INCREASE       +", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 8, BorderSizePixel = 0 }, wrap)
			corner(slider, 6)
			slider.MouseButton1Click:Connect(function()
				local nextValue = math.clamp(value + 5, 0, 200)
				module.Settings[key] = nextValue
				notify("info", key .. " set to " .. tostring(nextValue) .. ". Re-enable module to apply.")
				showConfig(module)
			end)
		end
	end
	local closeConfig = make("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.Card, Text = "CLOSE", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 99 }, configBody)
	corner(closeConfig, 6)
	closeConfig.MouseButton1Click:Connect(function() configPanel.Visible = false end)
end

local function updateCounter()
	local count = 0
	for _, module in ipairs(manager:GetAll()) do if module.Enabled then count += 1 end end
	activeCount.Text = tostring(count) .. " ACTIVE"
end

renderCards = function()
	for _, child in ipairs(cardScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local list = manager:GetAll()
	local order = 0
	for _, module in ipairs(list) do
		local categoryMatch = selectedCategory == "Favorites" and module.Favorite
			or selectedCategory == "Configs" and false
			or selectedCategory == "Settings" and false
			or selectedCategory == "Combat" and module.Category == "Combat"
			or selectedCategory == "Movement" and module.Category == "Movement"
			or selectedCategory == "Player" and module.Category == "Player"
			or selectedCategory == "Visuals" and module.Category == "Visuals"
			or selectedCategory == "Cosmetics" and module.Category == "Cosmetics"
			or selectedCategory == "Misc" and module.Category == "Misc"
			or selectedCategory == "HUD" and module.Category == "HUD"
		local queryMatch = searchText == "" or string.find(string.lower(module.Name .. " " .. module.Description), string.lower(searchText), 1, true)
		if categoryMatch and queryMatch and (not enabledOnly or module.Enabled) then
			order += 1
			local card = make("Frame", { Size = UDim2.new(1, -5, 0, 76), BackgroundColor3 = C.Card, BorderSizePixel = 0, LayoutOrder = order }, cardScroll)
			corner(card, 10); stroke(card)
			make("Frame", { Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 52), BackgroundColor3 = module.Enabled and C.Red or C.Stroke, BorderSizePixel = 0 }, card)
			make("TextLabel", { Position = UDim2.fromOffset(15, 12), Size = UDim2.new(1, -155, 0, 19), BackgroundTransparency = 1, Text = module.Name, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, card)
			make("TextLabel", { Position = UDim2.fromOffset(15, 34), Size = UDim2.new(1, -155, 0, 29), BackgroundTransparency = 1, Text = module.Description, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, card)
			local star = make("TextButton", { Position = UDim2.new(1, -112, 0, 23), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Text = module.Favorite and "★" or "☆", TextColor3 = C.Red, Font = Enum.Font.GothamBold, TextSize = 18 }, card)
			star.MouseButton1Click:Connect(function() module.Favorite = not module.Favorite; renderCards() end)
			local toggle = make("TextButton", { Position = UDim2.new(1, -76, 0, 23), Size = UDim2.fromOffset(61, 28), BackgroundColor3 = module.Enabled and C.RedDark or C.Panel, Text = module.Enabled and "ON" or "OFF", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0 }, card)
			corner(toggle, 7)
			toggle.MouseButton1Click:Connect(function() manager:Toggle(module.Id); updateCounter(); renderCards() end)
			local config = make("TextButton", { Position = UDim2.new(1, -36, 0, 23), Size = UDim2.fromOffset(24, 28), BackgroundTransparency = 1, Text = "···", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 15 }, card)
			config.MouseButton1Click:Connect(function() showConfig(module) end)
			card.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then showConfig(module) end
			end)
		end
	end
	if order == 0 then
		local empty = make("TextLabel", { Size = UDim2.new(1, -5, 0, 60), BackgroundTransparency = 1, Text = "No modules in this category yet.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 11 }, cardScroll)
	end
end

for index, category in ipairs(categories) do
	local button = make("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = category == selectedCategory and C.RedDark or Color3.fromRGB(0, 0, 0), BackgroundTransparency = category == selectedCategory and 0 or 1, Text = "   " .. string.upper(category), TextColor3 = category == selectedCategory and C.Text or C.Muted, Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = index }, navList)
	corner(button, 7)
	button.MouseButton1Click:Connect(function()
		selectedCategory = category
		heading.Text = string.upper(category)
		subtitle.Text = category == "HUD" and "Local performance readouts and overlays." or "Browse available " .. string.lower(category) .. " modules."
		for _, child in ipairs(navList:GetChildren()) do
			if child:IsA("TextButton") then
				local active = child.Text == "   " .. string.upper(category)
				child.BackgroundTransparency = active and 0 or 1
				child.BackgroundColor3 = active and C.RedDark or Color3.new(0, 0, 0)
				child.TextColor3 = active and C.Text or C.Muted
			end
		end
		configPanel.Visible = false
		renderCards()
	end)
end

search:GetPropertyChangedSignal("Text"):Connect(function() searchText = search.Text; renderCards() end)
filterButton.MouseButton1Click:Connect(function()
	enabledOnly = not enabledOnly
	filterButton.Text = enabledOnly and "ENABLED ONLY" or "ALL MODULES"
	filterButton.TextColor3 = enabledOnly and C.Red or C.Muted
	renderCards()
end)
settingsButton.MouseButton1Click:Connect(function()
	selectedCategory = "Configs"
	heading.Text = "CONFIGURATION"
	subtitle.Text = "Export or import validated settings JSON."
	clearConfig()
	configPanel.Visible = true
	configTitle.Text = "CONFIGURATION MANAGER"
	local configText = make("TextBox", { Size = UDim2.new(1, 0, 0, 145), BackgroundColor3 = C.Card, Text = "", PlaceholderText = "Exported configuration JSON appears here. Paste JSON here to import.", PlaceholderColor3 = C.Muted, TextColor3 = C.Text, Font = Enum.Font.Code, TextSize = 9, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, BorderSizePixel = 0, LayoutOrder = 1 }, configBody)
	corner(configText, 7); stroke(configText)
	local exportButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.RedDark, Text = "GENERATE EXPORT JSON", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 2 }, configBody)
	corner(exportButton, 7)
	exportButton.MouseButton1Click:Connect(function()
		local data = {}
		for _, module in ipairs(manager:GetAll()) do
			data[module.Id] = { Enabled = module.Enabled, Favorite = module.Favorite, Settings = module.Settings }
		end
		configText.Text = game:GetService("HttpService"):JSONEncode(data)
		notify("success", "Export JSON generated. Copy it from the text field.")
	end)
	local importButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Card, Text = "IMPORT JSON", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 3 }, configBody)
	corner(importButton, 7)
	importButton.MouseButton1Click:Connect(function()
		local ok, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(configText.Text)
		end)
		if not ok or type(decoded) ~= "table" then notify("error", "Invalid configuration JSON."); return end
		for id, entry in pairs(decoded) do
			local module = manager:Get(id)
			if module and type(entry) == "table" then
				if type(entry.Favorite) == "boolean" then module.Favorite = entry.Favorite end
				if type(entry.Settings) == "table" then
					for key, value in pairs(entry.Settings) do
						if module.Settings[key] ~= nil and typeof(value) == typeof(module.Settings[key]) then
							module.Settings[key] = value
						end
					end
				end
				if type(entry.Enabled) == "boolean" then manager:SetEnabled(id, entry.Enabled) end
			end
		end
		updateCounter(); renderCards()
		notify("success", "Compatible configuration values imported.")
	end)
	local info = make("TextLabel", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "Copy or paste JSON manually. Standard Roblox clients cannot write local files; persistent saves require a server-side DataStore implementation.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextWrapped = true, LayoutOrder = 4 }, configBody)
	local closeButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.Card, Text = "CLOSE", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 5 }, configBody)
	corner(closeButton, 6)
	closeButton.MouseButton1Click:Connect(function() configPanel.Visible = false end)
end)

keybinds:Set("ToggleInterface", Enum.KeyCode.RightShift)
keybinds.Changed.Event:Connect(function(action, id)
	if action == "pressed" and id == "ToggleInterface" then
		window.Visible = not window.Visible
	elseif action == "pressed" and id == "ToggleFullbright" then
		manager:Toggle("fullbright"); updateCounter(); renderCards()
	end
end)

minimize.MouseButton1Click:Connect(function()
	local target = window.Size.Y.Offset > 100 and UDim2.fromOffset(900, 58) or UDim2.fromOffset(900, 570)
	TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = target}):Play()
end)
close.MouseButton1Click:Connect(function()
	manager:Shutdown()
	advancedSuite:Destroy()
	keybinds:Destroy()
	settings:Destroy()
	gui:Destroy()
end)

-- Drag window using its title bar.
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true; dragStart = input.Position; startPos = window.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

renderCards()
updateCounter()
notify("success", "SK1D CLIENTOOL initialized. RightShift toggles the interface.")
