local SettingsManager=(
function()
local HttpService = game:GetService("HttpService")
local SettingsManager = {} SettingsManager.__index = SettingsManager
function SettingsManager.new()
return setmetatable({ Values = {}, Changed = Instance.new("BindableEvent"), }, SettingsManager)
end
function SettingsManager:Set(key, value) self.Values[key] = value self.Changed:Fire(key, value)
end
function SettingsManager:Get(key, fallback)
local value = self.Values[key]
if value == nil then
return fallback
end
return value
end
function SettingsManager:Export()
return HttpService:JSONEncode(self.Values)
end
function SettingsManager:Import(jsonText) assert(type(jsonText) == "string" and #jsonText <= 100000, "Invalid configuration size")
local decoded = HttpService:JSONDecode(jsonText) assert(type(decoded) == "table", "Configuration must be an object")
local clean = {}
for key, value in pairs(decoded) do
if type(key) == "string" and #key <= 80 then
local kind = typeof(value)
if kind == "string" or kind == "number" or kind == "boolean" then clean[key] = value
elseif kind == "table" then
local safe = {}
local count = 0
for subKey, subValue in pairs(value) do count += 1
if count > 100 then break
end
if (type(subKey) == "string" or type(subKey) == "number") and (type(subValue) == "string" or type(subValue) == "number" or type(subValue) == "boolean") then safe[subKey] = subValue
end
end clean[key] = safe
end
end
end self.Values = clean self.Changed:Fire("*", clean)
return true
end
function SettingsManager:Destroy() self.Changed:Destroy() table.clear(self.Values)
end
return SettingsManagerend)()

;
local ModuleManager=(
function()
local ModuleManager = {} ModuleManager.__index = ModuleManager
function ModuleManager.new(settingsManager, notify)
return setmetatable({ Modules = {}, SettingsManager = settingsManager, Notify = notify or
function()
end, }, ModuleManager)
end
function ModuleManager:Register(definition) assert(type(definition) == "table", "Module definition required") assert(type(definition.Id) == "string", "Module Id required") assert(not self.Modules[definition.Id], "Duplicate module: " .. definition.Id) assert(type(definition.Enable) == "function", "Enable callback required")
local module = { Id = definition.Id, Name = definition.Name or definition.Id, Description = definition.Description or "", Category = definition.Category or "Misc", Settings = definition.Settings or {}, Enabled = false, Favorite = false, Cleanup = nil, Enable = definition.Enable, } self.Modules[module.Id] = module
return module
end
function ModuleManager:Get(id)
return self.Modules[id]
end
function ModuleManager:GetAll()
local result = {}
for _, module in pairs(self.Modules) do table.insert(result, module)
end table.sort(result,
function(a, b)
return a.Name < b.Name
end)
return result
end
function ModuleManager:SetEnabled(id, enabled)
local module = self.Modules[id]
if not module then
return false, "Unknown module"
end enabled = enabled == true
if module.Enabled == enabled then
return true
end
if enabled then
local ok, cleanupOrError = pcall(module.Enable, module.Settings, self.SettingsManager)
if not ok then module.Enabled = false self.Notify("error", module.Name .. " failed: " .. tostring(cleanupOrError))
return false, cleanupOrError
end module.Cleanup = type(cleanupOrError) == "function" and cleanupOrError or nil module.Enabled = true self.Notify("success", module.Name .. " enabled")
else
if module.Cleanup then
local ok, err = pcall(module.Cleanup)
if not ok then warn("[SK1D] Cleanup error:", err)
end
end module.Cleanup = nil module.Enabled = false self.Notify("info", module.Name .. " disabled")
end
return true
end
function ModuleManager:Toggle(id)
local module = self.Modules[id]
if not module then
return false
end
return self:SetEnabled(id, not module.Enabled)
end
function ModuleManager:Shutdown()
for id, module in pairs(self.Modules) do
if module.Enabled then self:SetEnabled(id, false)
end
end
end
return ModuleManagerend)()

;
local KeybindManager=(
function()
local UserInputService = game:GetService("UserInputService")
local KeybindManager = {} KeybindManager.__index = KeybindManager
function KeybindManager.new()
local self = setmetatable({ Bindings = {}, WaitingFor = nil, Changed = Instance.new("BindableEvent"), }, KeybindManager) self.Connection = UserInputService.InputBegan:Connect(
function(input, processed)
if self.WaitingFor then
if input.KeyCode == Enum.KeyCode.Escape then
local id = self.WaitingFor self.WaitingFor = nil self.Changed:Fire("cancel", id)
return
end
if input.UserInputType == Enum.UserInputType.Keyboard then
local id = self.WaitingFor self.WaitingFor = nil self:Set(id, input.KeyCode) self.Changed:Fire("assigned", id, input.KeyCode)
end
return
end
if processed then
return
end
for id, keyCode in pairs(self.Bindings) do
if input.KeyCode == keyCode then self.Changed:Fire("pressed", id)
end
end
end)
return self
end
function KeybindManager:Set(id, keyCode)
for otherId, otherKey in pairs(self.Bindings) do
if otherId ~= id and otherKey == keyCode then
return false, "Key already assigned to " .. otherId
end
end self.Bindings[id] = keyCode
return true
end
function KeybindManager:BeginCapture(id) self.WaitingFor = id self.Changed:Fire("capturing", id)
end
function KeybindManager:Destroy()
if self.Connection then self.Connection:Disconnect()
end self.Changed:Destroy() table.clear(self.Bindings)
end
return KeybindManagerend)()

;
local NotificationManager=(
function()
local TweenService = game:GetService("TweenService")
local NotificationManager = {} NotificationManager.__index = NotificationManager
function NotificationManager.new(parent)
return setmetatable({ Parent = parent, Items = {} }, NotificationManager)
end
function NotificationManager:Push(kind, message)
local colors = { success = Color3.fromRGB(65, 210, 135), info = Color3.fromRGB(100, 165, 255), warning = Color3.fromRGB(255, 190, 75), error = Color3.fromRGB(255, 75, 85), }
local frame = Instance.new("Frame") frame.Name = "Notification" frame.Size = UDim2.fromOffset(270, 54) frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) frame.BackgroundTransparency = 0.08 frame.BorderSizePixel = 0 frame.Parent = self.Parent
local corner = Instance.new("UICorner");
 corner.CornerRadius = UDim.new(0, 10);
 corner.Parent = frame
local stroke = Instance.new("UIStroke");
 stroke.Color = colors[kind] or colors.info;
 stroke.Transparency = 0.25;
 stroke.Parent = frame
local label = Instance.new("TextLabel") label.BackgroundTransparency = 1 label.Position = UDim2.fromOffset(13, 0) label.Size = UDim2.new(1, -24, 1, 0) label.Font = Enum.Font.GothamMedium label.Text = tostring(message) label.TextColor3 = Color3.fromRGB(240, 240, 245) label.TextSize = 12 label.TextWrapped = true label.TextXAlignment = Enum.TextXAlignment.Left label.Parent = frame table.insert(self.Items, frame)
for index, item in ipairs(self.Items) do item.Position = UDim2.new(1, -286, 0, 18 + (index - 1) * 62)
end frame.Position = UDim2.new(1, 20, 0, 18 + (#self.Items - 1) * 62) TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, -286, 0, 18 + (#self.Items - 1) * 62) }):Play() task.delay(3.2,
function()
if not frame.Parent then
return
end
local tween = TweenService:Create(frame, TweenInfo.new(0.2), {Position = frame.Position + UDim2.fromOffset(30, 0), BackgroundTransparency = 1}) tween:Play();
 tween.Completed:Wait()
for i, item in ipairs(self.Items) do
if item == frame then table.remove(self.Items, i);
 break
end
end frame:Destroy()
for index, item in ipairs(self.Items) do TweenService:Create(item, TweenInfo.new(0.18), {Position = UDim2.new(1, -286, 0, 18 + (index - 1) * 62)}):Play()
end
end)
end
return NotificationManagerend)()

;
local AdvancedSuite=(
function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local AdvancedSuite = {}
local C = { BG = Color3.fromRGB(10, 10, 13), Panel = Color3.fromRGB(17, 17, 22), Card = Color3.fromRGB(25, 25, 32), Stroke = Color3.fromRGB(55, 48, 57), Text = Color3.fromRGB(241, 239, 245), Muted = Color3.fromRGB(148, 144, 155), Red = Color3.fromRGB(229, 53, 72), RedDark = Color3.fromRGB(92, 24, 37), Green = Color3.fromRGB(73, 205, 140), }
local
function make(className, props, parent)
local object = Instance.new(className)
for key, value in pairs(props or {}) do object[key] = value
end object.Parent = parent
return object
end
local
function round(object, radius) make("UICorner", { CornerRadius = UDim.new(0, radius or 9) }, object)
end
local
function outline(object, color) make("UIStroke", { Color = color or C.Stroke, Transparency = 0.18, Thickness = 1 }, object)
end
local
function label(parent, text, size, position, fontSize, color, align)
return make("TextLabel", { BackgroundTransparency = 1, Position = position or UDim2.fromOffset(0, 0), Size = size, Text = text, TextColor3 = color or C.Text, Font = Enum.Font.Gotham, TextSize = fontSize or 11, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, }, parent)
end
local
function button(parent, text, size, position, callback, accent)
local b = make("TextButton", { Size = size, Position = position, BackgroundColor3 = accent and C.RedDark or C.Card, BorderSizePixel = 0, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = true, }, parent) round(b, 7) b.MouseButton1Click:Connect(callback)
return b
end
local
function getHumanoid(character)
return character and character:FindFirstChildOfClass("Humanoid")
end
local
function getPing()
local ok, value = pcall(
function()
local item = Stats.Network.ServerStatsItem["Data Ping"]
return item:GetValue()
end)
return ok and tonumber(value) or nil
end
function AdvancedSuite.Mount(context)
local player = context.Player or Players.LocalPlayer
local playerGui = context.PlayerGui or player:WaitForChild("PlayerGui")
local notify = context.Notify or
function()
end
local module = {}
local alive = true
local connections = {}
local featureGui = make("Frame", { Name = "SK1D_AdvancedSuite", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 510), BackgroundColor3 = C.BG, BorderSizePixel = 0, Visible = false, ZIndex = 30, }, playerGui) round(featureGui, 13);
 outline(featureGui, C.RedDark)
local top = make("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, featureGui) round(top, 13) make("Frame", { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, top) label(top, "SK1D  /  ADVANCED SYSTEMS", UDim2.new(1, -120, 1, 0), UDim2.fromOffset(16, 0), 12, C.Text).ZIndex = 32
local close = button(top, "CLOSE  ×", UDim2.fromOffset(78, 28), UDim2.new(1, -91, 0, 10),
function() featureGui.Visible = false
end, false) close.ZIndex = 33
local tabs = make("Frame", { Position = UDim2.fromOffset(12, 60), Size = UDim2.new(0, 132, 1, -72), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, featureGui) round(tabs, 10)
local body = make("Frame", { Position = UDim2.fromOffset(156, 60), Size = UDim2.new(1, -168, 1, -72), BackgroundTransparency = 1, ZIndex = 31 }, featureGui)
local pageTitle = label(body, "COSMETICS CATALOG", UDim2.new(1, -10, 0, 25), UDim2.fromOffset(0, 0), 15, C.Text) pageTitle.Font = Enum.Font.GothamBold
local pageSubtitle = label(body, "Local-only avatar appearance preview. No inventory or ownership changes.", UDim2.new(1, -10, 0, 20), UDim2.fromOffset(0, 26), 9, C.Muted)
local pages = {}
local
function newPage(id)
local page = make("Frame", { Name = id, Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1, Visible = false, ZIndex = 32, }, body) pages[id] = page
return page
end
local tabNames = { {"Cosmetics", "CATALOG"}, {"HUD Editor", "HUD EDITOR"}, {"Emote Wheel", "EMOTES"}, {"Performance", "PERFORMANCE"}, }
local currentPage = "Cosmetics"
local
function showPage(name) currentPage = name
for id, page in pairs(pages) do page.Visible = id == name
end pageTitle.Text = string.upper(name)
local descriptions = { ["Cosmetics"] = "Local-only avatar appearance preview. No inventory or ownership changes.", ["HUD Editor"] = "Drag widgets, resize them, snap to grid, and save or reset their layout.", ["Emote Wheel"] = "Open with G while playing. Emotes depend on the current experience and avatar rig.", ["Performance"] = "Live client-side frame-rate, frame-time, and available ping estimates.", } pageSubtitle.Text = descriptions[name] or ""
for _, child in ipairs(tabs:GetChildren()) do
if child:IsA("TextButton") then
local active = child.Name == name child.BackgroundColor3 = active and C.RedDark or C.Card child.TextColor3 = active and C.Text or C.Muted
end
end
end
for index, tab in ipairs(tabNames) do
local b = button(tabs, tab[2], UDim2.new(1, -14, 0, 34), UDim2.fromOffset(7, 8 + (index - 1) * 41),
function() showPage(tab[1])
end, index == 1) b.Name = tab[1] b.ZIndex = 32
end
local cosmetics = newPage("Cosmetics")
local viewport = make("ViewportFrame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0.53, -8, 1, 0), BackgroundColor3 = Color3.fromRGB(14, 14, 19), BorderSizePixel = 0, Ambient = Color3.fromRGB(190, 190, 205), LightColor = Color3.fromRGB(255, 255, 255), ZIndex = 33, }, cosmetics) round(viewport, 10);
 outline(viewport)
local world = Instance.new("WorldModel");
 world.Parent = viewport
local camera = Instance.new("Camera");
 camera.FieldOfView = 38;
 camera.Parent = viewport viewport.CurrentCamera = camera
local previewModel
local yaw, zoom = math.rad(180), 8
local previewBusy = false
local
function positionCamera()
if not previewModel then
return
end
local pivot = previewModel:GetPivot()
local focus = pivot.Position + Vector3.new(0, 2.5, 0)
local direction = Vector3.new(math.sin(yaw), 0.12, math.cos(yaw)) camera.CFrame = CFrame.lookAt(focus + direction * zoom, focus)
end
local
function clearPreview()
if previewModel then previewModel:Destroy();
 previewModel = nil
end
end
local
function buildPreview(description)
if previewBusy or not description then
return
end previewBusy = true
local descriptionCopy = description:Clone() task.spawn(
function()
local ok, modelOrError = pcall(
function()
return Players:CreateHumanoidModelFromDescriptionAsync(descriptionCopy, Enum.HumanoidRigType.R15)
end) descriptionCopy:Destroy()
if not alive then
if ok and modelOrError then modelOrError:Destroy()
end previewBusy = false
return
end
if ok and modelOrError then clearPreview() previewModel = modelOrError previewModel.Name = "SK1D_AvatarPreview" previewModel.Parent = world previewModel:PivotTo(CFrame.new(0, 0, 0)) yaw, zoom = math.rad(180), 8 positionCamera() notify("success", "Avatar preview refreshed.")
else notify("error", "Avatar preview failed: " .. tostring(modelOrError))
end previewBusy = false
end)
end
local baseDescription task.spawn(
function()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = getHumanoid(character)
if humanoid then
local ok, description = pcall(
function()
return humanoid:GetAppliedDescription()
end)
if ok and description then baseDescription = description buildPreview(description)
else notify("warning", "Could not read the current avatar description.")
end
end
end)
local dragStart viewport.InputBegan:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart = input.Position
end
end) viewport.InputChanged:Connect(
function(input)
if dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - dragStart yaw += delta.X * 0.012 dragStart = input.Position positionCamera()
elseif input.UserInputType == Enum.UserInputType.MouseWheel then zoom = math.clamp(zoom - input.Position.Z * 0.65, 4, 14) positionCamera()
end
end) viewport.InputEnded:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart = nil
end
end)
local catalog = make("Frame", { Position = UDim2.new(0.53, 4, 0, 0), Size = UDim2.new(0.47, -4, 1, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, cosmetics) round(catalog, 10);
 outline(catalog) label(catalog, "APPEARANCE CATALOG", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 8), 11, C.Text).Font = Enum.Font.GothamBold label(catalog, "Enter a valid Roblox catalog asset ID.", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 31), 8, C.Muted)
local assetBox = make("TextBox", { Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 31), BackgroundColor3 = C.Card, BorderSizePixel = 0, Text = "", PlaceholderText = "Catalog asset ID", PlaceholderColor3 = C.Muted, TextColor3 = C.Text, Font = Enum.Font.Gotham, TextSize = 10, ClearTextOnFocus = false }, catalog) round(assetBox, 7)
local categoryChoice = "HatAccessory"
local categoryButton categoryButton = button(catalog, "CATEGORY: HAT  ▾", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 94),
function()
local choices = { {"HatAccessory", "HAT"}, {"HairAccessory", "HAIR"}, {"FaceAccessory", "FACE"}, {"NeckAccessory", "NECK"}, {"ShouldersAccessory", "SHOULDER"}, {"FrontAccessory", "FRONT"}, {"BackAccessory", "BACK"}, {"WaistAccessory", "WAIST"}, }
local index = 1
for i, item in ipairs(choices) do
if item[1] == categoryChoice then index = i
end
end
local nextItem = choices[index % #choices + 1] categoryChoice = nextItem[1] categoryButton.Text = "CATEGORY: " .. nextItem[2] .. "  ▾"
end, false)
local applyButton = button(catalog, "ADD TO LOCAL PREVIEW", UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 132),
function()
if not baseDescription then notify("warning", "Avatar description is not ready yet.");

return
end
local id = assetBox.Text:match("^%s*(%d+)%s*$")
if not id then notify("error", "Enter a numeric catalog asset ID.");

return
end
local desc = baseDescription:Clone()
local old = desc[categoryChoice]
local ids = {}
if type(old) == "string" and old ~= "" then
for token in string.gmatch(old, "[^,]+") do table.insert(ids, token)
end
end
if #ids >= 10 then notify("warning", "This accessory slot already has 10 entries.");
 desc:Destroy();

return
end table.insert(ids, id) desc[categoryChoice] = table.concat(ids, ",") buildPreview(desc) desc:Destroy()
end, true)
local resetButton = button(catalog, "RESET AVATAR PREVIEW", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 170),
function()
if baseDescription then buildPreview(baseDescription)
end
end, false)
local rotateHint = label(catalog, "DRAG TO ROTATE  ·  SCROLL TO ZOOM", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 210), 8, C.Muted) rotateHint.TextWrapped = true
local note = label(catalog, "Preview only. This does not grant ownership, purchase items, or change your live avatar.", UDim2.new(1, -20, 0, 62), UDim2.fromOffset(10, 240), 9, C.Muted) note.TextWrapped = true note.TextYAlignment = Enum.TextYAlignment.Top
local hudPage = newPage("HUD Editor")
local hudCanvas = make("Frame", { Size = UDim2.new(1, 0, 1, -70), BackgroundColor3 = Color3.fromRGB(13, 13, 18), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 33 }, hudPage) round(hudCanvas, 10);
 outline(hudCanvas)
local hudToolbar = make("Frame", { Position = UDim2.new(0, 0, 1, -62), Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, hudPage) round(hudToolbar, 9)
local snapEnabled = true
local snapSize = 10
local selectedWidget
local savedLayout = {}
local hudWidgets = {}
local
function snap(value)
if not snapEnabled then
return value
end
return math.floor(value / snapSize + 0.5) * snapSize
end
local
function makeWidget(name, text, pos, size)
local widget = make("TextLabel", { Name = name, Position = pos, Size = size, BackgroundColor3 = C.Card, BackgroundTransparency = 0.12, Text = text, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0, Active = true, Selectable = true, ZIndex = 35, }, hudCanvas) round(widget, 6);
 outline(widget, C.RedDark) hudWidgets[name] = widget
local handle = make("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(15, 15), BackgroundColor3 = C.Red, Text = "↘", TextColor3 = C.Text, TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 36 }, widget) round(handle, 4)
local moving, origin, startPosition = false, nil, nil widget.InputBegan:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then selectedWidget = widget moving = true;
 origin = input.Position;
 startPosition = widget.Position widget.BackgroundColor3 = C.RedDark
end
end)
local moveConnection = UserInputService.InputChanged:Connect(
function(input)
if moving and input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - origin
local x = snap(startPosition.X.Offset + delta.X)
local y = snap(startPosition.Y.Offset + delta.Y) widget.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, hudCanvas.AbsoluteSize.X - widget.AbsoluteSize.X)), math.clamp(y, 0, math.max(0, hudCanvas.AbsoluteSize.Y - widget.AbsoluteSize.Y)))
end
end)
local endConnection = UserInputService.InputEnded:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then moving = false;
 widget.BackgroundColor3 = C.Card
end
end) table.insert(connections, moveConnection) table.insert(connections, endConnection) handle.MouseButton1Down:Connect(
function()
if selectedWidget == widget then widget.Size = UDim2.fromOffset(math.clamp(widget.AbsoluteSize.X + 20, 70, 260), math.clamp(widget.AbsoluteSize.Y + 8, 24, 80))
end
end)
return widget
end makeWidget("Watermark", "SK1D CLIENTOOL", UDim2.fromOffset(12, 12), UDim2.fromOffset(145, 28)) makeWidget("Session", "SESSION  ·  LOCAL", UDim2.fromOffset(12, 48), UDim2.fromOffset(145, 28)) makeWidget("Clock", os.date("%H:%M:%S"), UDim2.fromOffset(12, 84), UDim2.fromOffset(105, 28)) makeWidget("Keybinds", "RIGHT SHIFT  ·  MENU", UDim2.fromOffset(12, 120), UDim2.fromOffset(160, 28))
local hudClockConnection = RunService.Heartbeat:Connect(
function()
if hudWidgets.Clock then hudWidgets.Clock.Text = os.date("%H:%M:%S")
end
end) table.insert(connections, hudClockConnection)
local snapButton snapButton = button(hudToolbar, "SNAP: ON", UDim2.fromOffset(90, 30), UDim2.fromOffset(8, 11),
function() snapEnabled = not snapEnabled snapButton.Text = snapEnabled and "SNAP: ON" or "SNAP: OFF"
end, false)
local saveButton = button(hudToolbar, "SAVE LAYOUT", UDim2.fromOffset(100, 30), UDim2.fromOffset(106, 11),
function() savedLayout = {}
for name, widget in pairs(hudWidgets) do savedLayout[name] = { X = widget.Position.X.Offset, Y = widget.Position.Y.Offset, W = widget.Size.X.Offset, H = widget.Size.Y.Offset, }
end notify("success", "HUD layout saved for this session.")
end, true)
local resetHudButton = button(hudToolbar, "RESET", UDim2.fromOffset(70, 30), UDim2.fromOffset(214, 11),
function()
local defaults = { Watermark = {12, 12, 145, 28}, Session = {12, 48, 145, 28}, Clock = {12, 84, 105, 28}, Keybinds = {12, 120, 160, 28}, }
for name, values in pairs(defaults) do
local widget = hudWidgets[name]
if widget then widget.Position = UDim2.fromOffset(values[1], values[2]) widget.Size = UDim2.fromOffset(values[3], values[4])
end
end notify("info", "HUD layout reset.")
end, false)
local exportHudButton = button(hudToolbar, "EXPORT", UDim2.fromOffset(76, 30), UDim2.fromOffset(292, 11),
function()
local ok, result = pcall(
function()
return HttpService:JSONEncode(savedLayout)
end)
if ok then notify("info", "HUD layout JSON generated (" .. tostring(#result) .. " chars).")
end
end, false)
local restoreHudButton = button(hudToolbar, "RESTORE SAVED", UDim2.fromOffset(104, 30), UDim2.fromOffset(376, 11),
function()
if not next(savedLayout) then notify("warning", "Save a layout first.");

return
end
for name, values in pairs(savedLayout) do
local widget = hudWidgets[name]
if widget then widget.Position = UDim2.fromOffset(values.X, values.Y) widget.Size = UDim2.fromOffset(values.W, values.H)
end
end notify("success", "Saved HUD layout restored.")
end, false)
local hudHint = label(hudPage, "Select and drag a widget. Use its bottom-right handle to resize. Layout is session-local in this client build.", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 8, C.Muted)
local emotePage = newPage("Emote Wheel")
local emoteWheel = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromOffset(340, 340), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 34 }, emotePage) round(emoteWheel, 170);
 outline(emoteWheel, C.RedDark)
local emoteCenter = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(104, 104), BackgroundColor3 = C.RedDark, BorderSizePixel = 0, ZIndex = 35 }, emoteWheel) round(emoteCenter, 52) label(emoteCenter, "EMOTE\nSELECT", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 12, C.Text, Enum.TextXAlignment.Center).ZIndex = 36
local emotes = {"wave", "point", "cheer", "laugh", "dance"}
local emoteButtons = {}
for index, emote in ipairs(emotes) do
local angle = (index - 1) * (math.pi * 2 / #emotes) - math.pi / 2
local x = 170 + math.cos(angle) * 116 - 43
local y = 170 + math.sin(angle) * 116 - 17
local b = button(emoteWheel, string.upper(emote), UDim2.fromOffset(86, 34), UDim2.fromOffset(x, y),
function()
local humanoid = getHumanoid(player.Character)
if not humanoid then notify("warning", "Character is not ready.");

return
end
local ok, result = pcall(
function()
return humanoid:PlayEmote(emote)
end)
if ok and result then notify("success", "Requested emote: " .. emote)
else notify("warning", "This emote is unavailable in the current experience/avatar.")
end
end, false) b.ZIndex = 36 emoteButtons[emote] = b
end label(emotePage, "HOLD G TO OPEN THE IN-GAME RADIAL SELECTOR. CLICK AN EMOTE TO REQUEST IT.", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 1, -24), 8, C.Muted, Enum.TextXAlignment.Center)
local wheelOverlay = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, playerGui)
local wheelOpen = false
local
function requestEmote(emote)
local humanoid = getHumanoid(player.Character)
if not humanoid then notify("warning", "Character is not ready.");

return
end
local ok, result = pcall(
function()
return humanoid:PlayEmote(emote)
end)
if ok and result then notify("success", "Requested emote: " .. emote)
else notify("warning", "This emote is unavailable in the current experience/avatar.")
end
end
local
function setWheel(open) wheelOpen = open wheelOverlay.Visible = open wheelOverlay:ClearAllChildren()
if open then
local center = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(100, 100), BackgroundColor3 = C.RedDark, BorderSizePixel = 0, ZIndex = 51 }, wheelOverlay) round(center, 50) label(center, "SK1D\nEMOTES", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 12, C.Text, Enum.TextXAlignment.Center).ZIndex = 52
for index, emote in ipairs(emotes) do
local angle = (index - 1) * (math.pi * 2 / #emotes) - math.pi / 2
local x = 170 + math.cos(angle) * 116 - 43
local y = 170 + math.sin(angle) * 116 - 17
local b = button(wheelOverlay, string.upper(emote), UDim2.fromOffset(86, 34), UDim2.fromOffset(x, y),
function() requestEmote(emote) setWheel(false)
end, false) b.ZIndex = 52
end
end
end
local emoteInputBegan = UserInputService.InputBegan:Connect(
function(input, processed)
if not processed and input.KeyCode == Enum.KeyCode.G then setWheel(true)
end
end)
local emoteInputEnded = UserInputService.InputEnded:Connect(
function(input)
if input.KeyCode == Enum.KeyCode.G then setWheel(false)
end
end) table.insert(connections, emoteInputBegan) table.insert(connections, emoteInputEnded)
local performance = newPage("Performance")
local metricCards = make("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1, ZIndex = 33 }, performance)
local
function metricCard(x, title)
local card = make("Frame", { Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0.32, -5, 1, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, metricCards) round(card, 9);
 outline(card) label(card, title, UDim2.new(1, -16, 0, 18), UDim2.fromOffset(9, 8), 8, C.Muted)
local value = label(card, "--", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(9, 31), 19, C.Text) value.Font = Enum.Font.GothamBold
return value
end
local fpsValue = metricCard(0, "CURRENT FPS")
local frameValue = metricCard(0.34, "FRAME TIME")
local pingValue = metricCard(0.68, "DATA PING")
local graphPanel = make("Frame", { Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 1, -130), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, performance) round(graphPanel, 10);
 outline(graphPanel)
local graphTitle = label(graphPanel, "FPS HISTORY  ·  LAST 30 SAMPLES", UDim2.new(1, -155, 0, 22), UDim2.fromOffset(12, 8), 9, C.Muted)
local graphMode = "FPS"
local graphModeButton graphModeButton = button(graphPanel, "VIEW: FPS  ▾", UDim2.fromOffset(112, 25), UDim2.new(1, -124, 0, 6),
function()
local modes = {"FPS", "FRAME TIME", "PING"}
local index = 1
for i, mode in ipairs(modes) do
if mode == graphMode then index = i
end
end graphMode = modes[index % #modes + 1] graphModeButton.Text = "VIEW: " .. graphMode .. "  ▾" graphTitle.Text = graphMode .. " HISTORY  ·  LAST 30 SAMPLES"
end, false)
local graph = make("Frame", { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 1, -52), BackgroundColor3 = Color3.fromRGB(12, 12, 16), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 34 }, graphPanel) round(graph, 6)
local bars = {}
for i = 1, 30 do
local bar = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / 30, 1, 1, -4), Size = UDim2.new(1 / 30, -3, 0, 4), BackgroundColor3 = C.Red, BorderSizePixel = 0, ZIndex = 35 }, graph) round(bar, 3) bars[i] = bar
end
local history = {}
local fpsHistory, frameHistory, pingHistory = {}, {}, {}
local fpsSamples, frameSamples = {}, {}
local accumulator, sampleElapsed, frameCount = 0, 0, 0
local perfConnection = RunService.RenderStepped:Connect(
function(dt)
if not alive then
return
end accumulator += dt sampleElapsed += dt frameCount += 1
if accumulator >= 0.5 then
local fps = frameCount / sampleElapsed
local frameMs = (sampleElapsed / math.max(frameCount, 1)) * 1000
local ping = getPing() table.insert(history, fps)
if #history > 30 then table.remove(history, 1)
end
local
function pushSample(target, value) table.insert(target, value or 0)
if #target > 30 then table.remove(target, 1)
end
end pushSample(fpsHistory, fps) pushSample(frameHistory, frameMs) pushSample(pingHistory, ping) table.insert(fpsSamples, fps);

if #fpsSamples > 60 then table.remove(fpsSamples, 1)
end table.insert(frameSamples, frameMs);

if #frameSamples > 60 then table.remove(frameSamples, 1)
end fpsValue.Text = string.format("%d", math.floor(fps + 0.5)) frameValue.Text = string.format("%.1f ms", frameMs) pingValue.Text = ping and string.format("%.0f ms", ping) or "--"
local selectedHistory = graphMode == "FPS" and fpsHistory or (graphMode == "FRAME TIME" and frameHistory or pingHistory)
local ceiling = graphMode == "FPS" and 144 or (graphMode == "FRAME TIME" and 50 or 250)
for i, bar in ipairs(bars) do
local value = selectedHistory[i] or 0
local height = math.clamp(value / ceiling, 0.04, 1) bar.Size = UDim2.new(1 / 30, -3, height, -3)
local warning = (graphMode == "FPS" and value < 30) or (graphMode == "FRAME TIME" and value > 33) bar.BackgroundColor3 = warning and Color3.fromRGB(235, 75, 75) or C.Red
end accumulator, sampleElapsed, frameCount = 0, 0, 0
end
end) table.insert(connections, perfConnection)
local avgLabel = label(performance, "AVERAGE FPS: --     AVERAGE FRAME TIME: --", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -20), 9, C.Muted)
local avgConnection = RunService.Heartbeat:Connect(
function()
if #fpsSamples > 0 then
local totalFps, totalFrame = 0, 0
for i = 1, #fpsSamples do totalFps += fpsSamples[i]
end
for i = 1, #frameSamples do totalFrame += frameSamples[i]
end avgLabel.Text = string.format("AVERAGE FPS: %.0f     AVERAGE FRAME TIME: %.1f ms", totalFps / #fpsSamples, totalFrame / #frameSamples)
end
end) table.insert(connections, avgConnection) showPage("Cosmetics") module.Gui = featureGui
function module:Open() featureGui.Visible = true showPage("Cosmetics")
end
function module:Destroy() alive = false
for _, connection in ipairs(connections) do
if connection and connection.Connected then connection:Disconnect()
end
end
if wheelOverlay then wheelOverlay:Destroy()
end clearPreview()
if baseDescription then baseDescription:Destroy()
end
if featureGui then featureGui:Destroy()
end
end
return module
end
return AdvancedSuiteend)()

;
local Visuals=(
function()
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Visuals = {}
local
function register(manager) manager:Register({ Id = "fullbright", Name = "Fullbright", Category = "Visuals", Description = "Locally adjusts lighting for clearer visibility.", Settings = { Brightness = 2, Ambient = Color3.fromRGB(170, 170, 185) }, Enable =
function(settings)
local old = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows, } Lighting.Brightness = settings.Brightness Lighting.Ambient = settings.Ambient Lighting.OutdoorAmbient = settings.Ambient Lighting.GlobalShadows = false
return
function() Lighting.Brightness = old.Brightness Lighting.Ambient = old.Ambient Lighting.OutdoorAmbient = old.OutdoorAmbient Lighting.GlobalShadows = old.GlobalShadows
end
end, }) manager:Register({ Id = "fov", Name = "FOV Changer", Category = "Visuals", Description = "Sets the local camera field of view.", Settings = { Value = 85 }, Enable =
function(settings)
local camera = Workspace.CurrentCamera
if not camera then
return
end
local old = camera.FieldOfView camera.FieldOfView = math.clamp(settings.Value, 50, 110)
return
function()
if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = old
end
end
end, }) manager:Register({ Id = "fog", Name = "Fog Remover", Category = "Visuals", Description = "Temporarily reduces legacy fog on the client.", Settings = {}, Enable =
function()
local oldStart, oldEnd = Lighting.FogStart, Lighting.FogEnd Lighting.FogStart, Lighting.FogEnd = 0, 100000
return
function() Lighting.FogStart, Lighting.FogEnd = oldStart, oldEnd
end
end, }) manager:Register({ Id = "bloom", Name = "Bloom", Category = "Visuals", Description = "Adds a configurable local bloom effect.", Settings = { Intensity = 0.35, Size = 24, Threshold = 1.2 }, Enable =
function(settings)
local effect = Instance.new("BloomEffect") effect.Name = "SK1D_LocalBloom" effect.Intensity = math.clamp(settings.Intensity, 0, 2) effect.Size = math.clamp(settings.Size, 0, 56) effect.Threshold = math.clamp(settings.Threshold, 0, 2) effect.Parent = Lighting
return
function() effect:Destroy()
end
end, }) manager:Register({ Id = "test_highlights", Name = "Test Target Highlights", Category = "Visuals", Description = "Highlights only models tagged SK1D_VisualTarget in your own experience.", Settings = { Fill = Color3.fromRGB(235, 65, 85), Outline = Color3.fromRGB(255, 255, 255) }, Enable =
function(settings)
local made = {}
local
function add(instance)
if not instance:IsA("Model") then
return
end
local highlight = Instance.new("Highlight") highlight.Name = "SK1D_TestHighlight" highlight.FillColor = settings.Fill highlight.OutlineColor = settings.Outline highlight.DepthMode = Enum.HighlightDepthMode.Occluded highlight.Parent = instance made[instance] = highlight
end
for _, instance in ipairs(CollectionService:GetTagged("SK1D_VisualTarget")) do add(instance)
end
local added = CollectionService:GetInstanceAddedSignal("SK1D_VisualTarget"):Connect(add)
local removed = CollectionService:GetInstanceRemovedSignal("SK1D_VisualTarget"):Connect(
function(instance)
if made[instance] then made[instance]:Destroy();
 made[instance] = nil
end
end)
return
function() added:Disconnect();
 removed:Disconnect()
for _, highlight in pairs(made) do highlight:Destroy()
end table.clear(made)
end
end, })
end Visuals.Register = register
return Visualsend)()

;
local HUD=(
function()
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HUD = {}
function HUD.Register(manager, screenGui) manager:Register({ Id = "fps_hud", Name = "FPS Counter", Category = "HUD", Description = "Displays a lightweight client FPS estimate.", Settings = { Position = UDim2.fromOffset(18, 90) }, Enable =
function(settings)
local label = Instance.new("TextLabel") label.Name = "SK1D_FPS" label.Size = UDim2.fromOffset(150, 25) label.Position = settings.Position label.BackgroundColor3 = Color3.fromRGB(15, 15, 19) label.BackgroundTransparency = 0.2 label.TextColor3 = Color3.fromRGB(235, 235, 240) label.Font = Enum.Font.GothamMedium label.TextSize = 12 label.Parent = screenGui
local corner = Instance.new("UICorner");
 corner.CornerRadius = UDim.new(0, 7);
 corner.Parent = label
local elapsed, frames = 0, 0
local connection = RunService.RenderStepped:Connect(
function(dt) elapsed += dt;
 frames += 1
if elapsed >= 0.5 then label.Text = string.format("FPS  %d", math.floor(frames / elapsed + 0.5)) elapsed, frames = 0, 0
end
end)
return
function() connection:Disconnect();
 label:Destroy()
end
end, }) manager:Register({ Id = "ping_hud", Name = "Ping Counter", Category = "HUD", Description = "Displays the client-reported Data Ping statistic when available.", Settings = { Position = UDim2.fromOffset(18, 120) }, Enable =
function(settings)
local label = Instance.new("TextLabel") label.Name = "SK1D_Ping" label.Size = UDim2.fromOffset(150, 25) label.Position = settings.Position label.BackgroundColor3 = Color3.fromRGB(15, 15, 19) label.BackgroundTransparency = 0.2 label.TextColor3 = Color3.fromRGB(235, 235, 240) label.Font = Enum.Font.GothamMedium label.TextSize = 12 label.Text = "PING  --" label.Parent = screenGui
local corner = Instance.new("UICorner");
 corner.CornerRadius = UDim.new(0, 7);
 corner.Parent = label
local elapsed = 0
local connection = RunService.Heartbeat:Connect(
function(dt) elapsed += dt
if elapsed >= 1 then elapsed = 0
local ok, value = pcall(
function()
return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
end) label.Text = "PING  " .. (ok and tostring(value) or "--")
end
end)
return
function() connection:Disconnect();
 label:Destroy()
end
end, })
end
return HUDend)()

;
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = { BG = Color3.fromRGB(10, 10, 13), Panel = Color3.fromRGB(17, 17, 22), Card = Color3.fromRGB(23, 23, 29), Stroke = Color3.fromRGB(49, 43, 50), Text = Color3.fromRGB(240, 239, 244), Muted = Color3.fromRGB(145, 142, 153), Red = Color3.fromRGB(229, 53, 72), RedDark = Color3.fromRGB(92, 24, 37), Green = Color3.fromRGB(73, 205, 140), }
local
function make(className, props, parent)
local object = Instance.new(className)
for key, value in pairs(props or {}) do object[key] = value
end object.Parent = parent
return object
end
local
function corner(parent, radius) make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end
local
function stroke(parent, color, transparency) make("UIStroke", { Color = color or C.Stroke, Transparency = transparency or 0.2, Thickness = 1 }, parent)
end
local gui = make("ScreenGui", { Name = "SK1D_CLIENTOOL", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, }, playerGui)
local toastLayer = make("Frame", { Name = "ToastLayer", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local notifications = NotificationManager.new(toastLayer)
local
function notify(kind, message) notifications:Push(kind, message)
end
local advancedSuite = AdvancedSuite.Mount({ Player = player, PlayerGui = playerGui, Notify = notify, })
local settings = SettingsManager.new()
local manager = ModuleManager.new(settings, notify)
local keybinds = KeybindManager.new() Visuals.Register(manager) HUD.Register(manager, gui)
local window = make("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 570), BackgroundColor3 = C.BG, BorderSizePixel = 0, }, gui) corner(window, 14);
 stroke(window, C.RedDark, 0.05)
local scale = make("UIScale", { Scale = 1 }, window)
local
function updateScale()
local camera = workspace.CurrentCamera
if not camera then
return
end
local viewport = camera.ViewportSize scale.Scale = math.clamp(math.min(viewport.X / 1050, viewport.Y / 700), 0.62, 1)
end updateScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end
local top = make("Frame", { Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, window) corner(top, 14) make("Frame", { Position = UDim2.new(0, 0, 1, -14), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, top) make("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0 }, top)
local brandMark = make("Frame", { Position = UDim2.fromOffset(17, 14), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.RedDark, BorderSizePixel = 0 }, top) corner(brandMark, 9) make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "S", TextColor3 = C.Text, Font = Enum.Font.GothamBlack, TextSize = 17 }, brandMark) make("TextLabel", { Position = UDim2.fromOffset(57, 10), Size = UDim2.fromOffset(220, 22), BackgroundTransparency = 1, Text = "SK1D CLIENTOOL", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, top) make("TextLabel", { Position = UDim2.fromOffset(57, 30), Size = UDim2.fromOffset(220, 15), BackgroundTransparency = 1, Text = "VISUAL CONTROL  /  CLIENT BUILD", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left }, top)
local activeCount = make("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -105, 0.5, 0), Size = UDim2.fromOffset(115, 26), BackgroundColor3 = C.Card, TextColor3 = C.Muted, Font = Enum.Font.GothamMedium, TextSize = 10, Text = "0 ACTIVE", BorderSizePixel = 0 }, top) corner(activeCount, 7)
local advancedButton = make("TextButton", { Position = UDim2.new(1, -330, 0, 14), Size = UDim2.fromOffset(112, 27), BackgroundColor3 = C.RedDark, Text = "ADVANCED  ↗", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, top) corner(advancedButton, 7) advancedButton.MouseButton1Click:Connect(
function() advancedSuite:Open()
end)
local minimize = make("TextButton", { Position = UDim2.new(1, -76, 0, 14), Size = UDim2.fromOffset(27, 27), BackgroundColor3 = C.Card, Text = "—", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0 }, top) corner(minimize, 7)
local close = make("TextButton", { Position = UDim2.new(1, -42, 0, 14), Size = UDim2.fromOffset(27, 27), BackgroundColor3 = C.RedDark, Text = "×", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 17, BorderSizePixel = 0 }, top) corner(close, 7)
local sidebar = make("Frame", { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(0, 180, 1, -58), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }, window)
local content = make("Frame", { Position = UDim2.fromOffset(180, 58), Size = UDim2.new(1, -180, 1, -58), BackgroundTransparency = 1 }, window)
local navList = make("Frame", { Position = UDim2.fromOffset(12, 18), Size = UDim2.new(1, -24, 1, -36), BackgroundTransparency = 1 }, sidebar) make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navList)
local categories = { "Favorites", "Combat", "Movement", "Player", "Visuals", "Cosmetics", "Misc", "HUD", "Configs", "Settings" }
local selectedCategory = "Visuals"
local searchText = ""
local enabledOnly = false
local renderCards
local showConfig
local heading = make("TextLabel", { Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -48, 0, 28), BackgroundTransparency = 1, Text = "VISUALS", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left }, content)
local subtitle = make("TextLabel", { Position = UDim2.fromOffset(24, 46), Size = UDim2.new(1, -48, 0, 18), BackgroundTransparency = 1, Text = "Local visual adjustments and approved test-target tools.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, content)
local search = make("TextBox", { Position = UDim2.fromOffset(24, 78), Size = UDim2.new(1, -250, 0, 36), BackgroundColor3 = C.Panel, PlaceholderText = "Search modules...", PlaceholderColor3 = C.Muted, Text = "", TextColor3 = C.Text, Font = Enum.Font.Gotham, TextSize = 11, ClearTextOnFocus = false, BorderSizePixel = 0 }, content) corner(search, 8);
 stroke(search)
local filterButton = make("TextButton", { Position = UDim2.new(1, -205, 0, 78), Size = UDim2.fromOffset(92, 36), BackgroundColor3 = C.Panel, Text = "ALL MODULES", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, content) corner(filterButton, 8);
 stroke(filterButton)
local settingsButton = make("TextButton", { Position = UDim2.new(1, -104, 0, 78), Size = UDim2.fromOffset(80, 36), BackgroundColor3 = C.RedDark, Text = "CONFIG", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0 }, content) corner(settingsButton, 8)
local cardScroll = make("ScrollingFrame", { Position = UDim2.fromOffset(24, 128), Size = UDim2.new(1, -48, 1, -152), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Red, CanvasSize = UDim2.fromOffset(0, 0) }, content)
local cardLayout = make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, cardScroll) cardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
function() cardScroll.CanvasSize = UDim2.fromOffset(0, cardLayout.AbsoluteContentSize.Y + 8)
end)
local configPanel = make("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 126), Size = UDim2.fromOffset(285, 340), BackgroundColor3 = C.Panel, BorderSizePixel = 0, Visible = false, ZIndex = 10 }, content) corner(configPanel, 12);
 stroke(configPanel, C.RedDark, 0.1)
local configTitle = make("TextLabel", { Position = UDim2.fromOffset(15, 13), Size = UDim2.new(1, -30, 0, 24), BackgroundTransparency = 1, Text = "MODULE SETTINGS", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 }, configPanel)
local configBody = make("Frame", { Position = UDim2.fromOffset(14, 47), Size = UDim2.new(1, -28, 1, -60), BackgroundTransparency = 1, ZIndex = 11 }, configPanel)
local configLayout = make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, configBody)
local
function clearConfig()
for _, child in ipairs(configBody:GetChildren()) do
if child:IsA("GuiObject") and child ~= configLayout then child:Destroy()
end
end
end showConfig =
function(module) clearConfig() configPanel.Visible = true configTitle.Text = string.upper(module.Name) .. "  /  SETTINGS"
local description = make("TextLabel", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Text = module.Description, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, configBody)
for key, value in pairs(module.Settings) do
if type(value) == "number" then
local wrap = make("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = 2 }, configBody) make("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = key .. "  ·  " .. tostring(value), TextColor3 = C.Text, Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, wrap)
local slider = make("TextButton", { Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 23), BackgroundColor3 = C.Card, Text = "−       DECREASE          INCREASE       +", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 8, BorderSizePixel = 0 }, wrap) corner(slider, 6) slider.MouseButton1Click:Connect(
function()
local nextValue = math.clamp(value + 5, 0, 200) module.Settings[key] = nextValue notify("info", key .. " set to " .. tostring(nextValue) .. ". Re-enable module to apply.") showConfig(module)
end)
end
end
local closeConfig = make("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.Card, Text = "CLOSE", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 99 }, configBody) corner(closeConfig, 6) closeConfig.MouseButton1Click:Connect(
function() configPanel.Visible = false
end)
end
local
function updateCounter()
local count = 0
for _, module in ipairs(manager:GetAll()) do
if module.Enabled then count += 1
end
end activeCount.Text = tostring(count) .. " ACTIVE"
end renderCards =
function()
for _, child in ipairs(cardScroll:GetChildren()) do
if child:IsA("Frame") then child:Destroy()
end
end
local list = manager:GetAll()
local order = 0
for _, module in ipairs(list) do
local categoryMatch = selectedCategory == "Favorites" and module.Favorite or selectedCategory == "Configs" and false or selectedCategory == "Settings" and false or selectedCategory == "Combat" and module.Category == "Combat" or selectedCategory == "Movement" and module.Category == "Movement" or selectedCategory == "Player" and module.Category == "Player" or selectedCategory == "Visuals" and module.Category == "Visuals" or selectedCategory == "Cosmetics" and module.Category == "Cosmetics" or selectedCategory == "Misc" and module.Category == "Misc" or selectedCategory == "HUD" and module.Category == "HUD"
local queryMatch = searchText == "" or string.find(string.lower(module.Name .. " " .. module.Description), string.lower(searchText), 1, true)
if categoryMatch and queryMatch and (not enabledOnly or module.Enabled) then order += 1
local card = make("Frame", { Size = UDim2.new(1, -5, 0, 76), BackgroundColor3 = C.Card, BorderSizePixel = 0, LayoutOrder = order }, cardScroll) corner(card, 10);
 stroke(card) make("Frame", { Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(3, 52), BackgroundColor3 = module.Enabled and C.Red or C.Stroke, BorderSizePixel = 0 }, card) make("TextLabel", { Position = UDim2.fromOffset(15, 12), Size = UDim2.new(1, -155, 0, 19), BackgroundTransparency = 1, Text = module.Name, TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, card) make("TextLabel", { Position = UDim2.fromOffset(15, 34), Size = UDim2.new(1, -155, 0, 29), BackgroundTransparency = 1, Text = module.Description, TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, card)
local star = make("TextButton", { Position = UDim2.new(1, -112, 0, 23), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, Text = module.Favorite and "★" or "☆", TextColor3 = C.Red, Font = Enum.Font.GothamBold, TextSize = 18 }, card) star.MouseButton1Click:Connect(
function() module.Favorite = not module.Favorite;
 renderCards()
end)
local toggle = make("TextButton", { Position = UDim2.new(1, -76, 0, 23), Size = UDim2.fromOffset(61, 28), BackgroundColor3 = module.Enabled and C.RedDark or C.Panel, Text = module.Enabled and "ON" or "OFF", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 10, BorderSizePixel = 0 }, card) corner(toggle, 7) toggle.MouseButton1Click:Connect(
function() manager:Toggle(module.Id);
 updateCounter();
 renderCards()
end)
local config = make("TextButton", { Position = UDim2.new(1, -36, 0, 23), Size = UDim2.fromOffset(24, 28), BackgroundTransparency = 1, Text = "···", TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 15 }, card) config.MouseButton1Click:Connect(
function() showConfig(module)
end) card.InputBegan:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton2 then showConfig(module)
end
end)
end
end
if order == 0 then
local empty = make("TextLabel", { Size = UDim2.new(1, -5, 0, 60), BackgroundTransparency = 1, Text = "No modules in this category yet.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 11 }, cardScroll)
end
end
for index, category in ipairs(categories) do
local button = make("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = category == selectedCategory and C.RedDark or Color3.fromRGB(0, 0, 0), BackgroundTransparency = category == selectedCategory and 0 or 1, Text = "   " .. string.upper(category), TextColor3 = category == selectedCategory and C.Text or C.Muted, Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = index }, navList) corner(button, 7) button.MouseButton1Click:Connect(
function() selectedCategory = category heading.Text = string.upper(category) subtitle.Text = category == "HUD" and "Local performance readouts and overlays." or "Browse available " .. string.lower(category) .. " modules."
for _, child in ipairs(navList:GetChildren()) do
if child:IsA("TextButton") then
local active = child.Text == "   " .. string.upper(category) child.BackgroundTransparency = active and 0 or 1 child.BackgroundColor3 = active and C.RedDark or Color3.new(0, 0, 0) child.TextColor3 = active and C.Text or C.Muted
end
end configPanel.Visible = false renderCards()
end)
end search:GetPropertyChangedSignal("Text"):Connect(
function() searchText = search.Text;
 renderCards()
end) filterButton.MouseButton1Click:Connect(
function() enabledOnly = not enabledOnly filterButton.Text = enabledOnly and "ENABLED ONLY" or "ALL MODULES" filterButton.TextColor3 = enabledOnly and C.Red or C.Muted renderCards()
end) settingsButton.MouseButton1Click:Connect(
function() selectedCategory = "Configs" heading.Text = "CONFIGURATION" subtitle.Text = "Export or import validated settings JSON." clearConfig() configPanel.Visible = true configTitle.Text = "CONFIGURATION MANAGER"
local configText = make("TextBox", { Size = UDim2.new(1, 0, 0, 145), BackgroundColor3 = C.Card, Text = "", PlaceholderText = "Exported configuration JSON appears here. Paste JSON here to import.", PlaceholderColor3 = C.Muted, TextColor3 = C.Text, Font = Enum.Font.Code, TextSize = 9, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, MultiLine = true, BorderSizePixel = 0, LayoutOrder = 1 }, configBody) corner(configText, 7);
 stroke(configText)
local exportButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.RedDark, Text = "GENERATE EXPORT JSON", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 2 }, configBody) corner(exportButton, 7) exportButton.MouseButton1Click:Connect(
function()
local data = {}
for _, module in ipairs(manager:GetAll()) do data[module.Id] = { Enabled = module.Enabled, Favorite = module.Favorite, Settings = module.Settings }
end configText.Text = game:GetService("HttpService"):JSONEncode(data) notify("success", "Export JSON generated. Copy it from the text field.")
end)
local importButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.Card, Text = "IMPORT JSON", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 3 }, configBody) corner(importButton, 7) importButton.MouseButton1Click:Connect(
function()
local ok, decoded = pcall(
function()
return game:GetService("HttpService"):JSONDecode(configText.Text)
end)
if not ok or type(decoded) ~= "table" then notify("error", "Invalid configuration JSON.");

return
end
for id, entry in pairs(decoded) do
local module = manager:Get(id)
if module and type(entry) == "table" then
if type(entry.Favorite) == "boolean" then module.Favorite = entry.Favorite
end
if type(entry.Settings) == "table" then
for key, value in pairs(entry.Settings) do
if module.Settings[key] ~= nil and typeof(value) == typeof(module.Settings[key]) then module.Settings[key] = value
end
end
end
if type(entry.Enabled) == "boolean" then manager:SetEnabled(id, entry.Enabled)
end
end
end updateCounter();
 renderCards() notify("success", "Compatible configuration values imported.")
end)
local info = make("TextLabel", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "Copy or paste JSON manually. Standard Roblox clients cannot write local files; persistent saves require a server-side DataStore implementation.", TextColor3 = C.Muted, Font = Enum.Font.Gotham, TextSize = 9, TextWrapped = true, LayoutOrder = 4 }, configBody)
local closeButton = make("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.Card, Text = "CLOSE", TextColor3 = C.Text, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0, LayoutOrder = 5 }, configBody) corner(closeButton, 6) closeButton.MouseButton1Click:Connect(
function() configPanel.Visible = false
end)
end) keybinds:Set("ToggleInterface", Enum.KeyCode.RightShift) keybinds.Changed.Event:Connect(
function(action, id)
if action == "pressed" and id == "ToggleInterface" then window.Visible = not window.Visible
elseif action == "pressed" and id == "ToggleFullbright" then manager:Toggle("fullbright");
 updateCounter();
 renderCards()
end
end) minimize.MouseButton1Click:Connect(
function()
local target = window.Size.Y.Offset > 100 and UDim2.fromOffset(900, 58) or UDim2.fromOffset(900, 570) TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Size = target}):Play()
end) close.MouseButton1Click:Connect(
function() manager:Shutdown() advancedSuite:Destroy() keybinds:Destroy() settings:Destroy() gui:Destroy()
end)
local dragging, dragStart, startPos top.InputBegan:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true;
 dragStart = input.Position;
 startPos = window.Position
end
end) UserInputService.InputChanged:Connect(
function(input)
if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - dragStart window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end) UserInputService.InputEnded:Connect(
function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false
end
end) renderCards() updateCounter() notify("success", "SK1D CLIENTOOL initialized. RightShift toggles the interface.")
