local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")


local KeybindManager = {}
KeybindManager.__index = KeybindManager

function KeybindManager.new()
	local self = setmetatable({
		Bindings = {},
		WaitingFor = nil,
		Changed = Instance.new("BindableEvent"),
	}, KeybindManager)

	self.Connection = UserInputService.InputBegan:Connect(function(input, processed)
		if self.WaitingFor then
			if input.KeyCode == Enum.KeyCode.Escape then
				local id = self.WaitingFor
				self.WaitingFor = nil
				self.Changed:Fire("cancel", id)
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local id = self.WaitingFor
				self.WaitingFor = nil
				local ok, reason = self:Set(id, input.KeyCode)
				if ok then
					self.Changed:Fire("assigned", id, input.KeyCode)
				else
					self.Changed:Fire("conflict", id, input.KeyCode, reason)
				end
			end
			return
		end
		if processed then return end
		for id, keyCode in pairs(self.Bindings) do
			if input.KeyCode == keyCode then self.Changed:Fire("pressed", id) end
		end
	end)
	return self
end

function KeybindManager:Set(id, keyCode)
	for otherId, otherKey in pairs(self.Bindings) do
		if otherId ~= id and otherKey == keyCode then
			return false, "Key already assigned to " .. otherId
		end
	end
	self.Bindings[id] = keyCode
	return true
end

function KeybindManager:BeginCapture(id)
	self.WaitingFor = id
	self.Changed:Fire("capturing", id)
end

function KeybindManager:Destroy()
	if self.Connection then self.Connection:Disconnect() end
	self.Changed:Destroy()
	table.clear(self.Bindings)
end


local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new()
	return setmetatable({
		Values = {},
		Changed = Instance.new("BindableEvent"),
	}, SettingsManager)
end

function SettingsManager:Set(key, value)
	self.Values[key] = value
	self.Changed:Fire(key, value)
end

function SettingsManager:Get(key, fallback)
	local value = self.Values[key]
	if value == nil then return fallback end
	return value
end

function SettingsManager:Export()
	return HttpService:JSONEncode(self.Values)
end

function SettingsManager:Import(jsonText)
	assert(type(jsonText) == "string" and #jsonText <= 100000, "Invalid configuration size")
	local decoded = HttpService:JSONDecode(jsonText)
	assert(type(decoded) == "table", "Configuration must be an object")

	local clean = {}
	for key, value in pairs(decoded) do
		if type(key) == "string" and #key <= 80 then
			local kind = typeof(value)
			if kind == "string" or kind == "number" or kind == "boolean" then
				clean[key] = value
			elseif kind == "table" then
				local safe = {}
				local count = 0
				for subKey, subValue in pairs(value) do
					count += 1
					if count > 100 then break end
					if (type(subKey) == "string" or type(subKey) == "number")
						and (type(subValue) == "string" or type(subValue) == "number" or type(subValue) == "boolean") then
						safe[subKey] = subValue
					end
				end
				clean[key] = safe
			end
		end
	end
	self.Values = clean
	self.Changed:Fire("*", clean)
	return true
end

function SettingsManager:Destroy()
	self.Changed:Destroy()
	table.clear(self.Values)
end


local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(parent)
	return setmetatable({ Parent = parent, Items = {} }, NotificationManager)
end

function NotificationManager:Push(kind, message)
	local colors = {
		success = Color3.fromRGB(65, 210, 135),
		info = Color3.fromRGB(100, 165, 255),
		warning = Color3.fromRGB(255, 190, 75),
		error = Color3.fromRGB(255, 75, 85),
	}
	local frame = Instance.new("Frame")
	frame.Name = "Notification"
	frame.Size = UDim2.fromOffset(270, 54)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = self.Parent
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = frame
	local stroke = Instance.new("UIStroke"); stroke.Color = colors[kind] or colors.info; stroke.Transparency = 0.25; stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(13, 0)
	label.Size = UDim2.new(1, -24, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.Text = tostring(message)
	label.TextColor3 = Color3.fromRGB(240, 240, 245)
	label.TextSize = 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	table.insert(self.Items, frame)
	for index, item in ipairs(self.Items) do
		item.Position = UDim2.new(1, -286, 0, 18 + (index - 1) * 62)
	end
	frame.Position = UDim2.new(1, 20, 0, 18 + (#self.Items - 1) * 62)
	TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -286, 0, 18 + (#self.Items - 1) * 62)
	}):Play()
	task.delay(3.2, function()
		if not frame.Parent then return end
		local tween = TweenService:Create(frame, TweenInfo.new(0.2), {Position = frame.Position + UDim2.fromOffset(30, 0), BackgroundTransparency = 1})
		tween:Play(); tween.Completed:Wait()
		for i, item in ipairs(self.Items) do if item == frame then table.remove(self.Items, i); break end end
		frame:Destroy()
		for index, item in ipairs(self.Items) do
			TweenService:Create(item, TweenInfo.new(0.18), {Position = UDim2.new(1, -286, 0, 18 + (index - 1) * 62)}):Play()
		end
	end)
end


local ModuleManager = {}
ModuleManager.__index = ModuleManager

function ModuleManager.new(settingsManager, notify)
	return setmetatable({
		Modules = {},
		SettingsManager = settingsManager,
		Notify = notify or function() end,
	}, ModuleManager)
end

function ModuleManager:Register(definition)
	assert(type(definition) == "table", "Module definition required")
	assert(type(definition.Id) == "string", "Module Id required")
	assert(not self.Modules[definition.Id], "Duplicate module: " .. definition.Id)
	assert(type(definition.Enable) == "function", "Enable callback required")

	local module = {
		Id = definition.Id,
		Name = definition.Name or definition.Id,
		Description = definition.Description or "",
		Category = definition.Category or "Misc",
		Settings = definition.Settings or {},
		Enabled = false,
		Favorite = false,
		Cleanup = nil,
		Enable = definition.Enable,
	}
	self.Modules[module.Id] = module
	return module
end

function ModuleManager:Get(id)
	return self.Modules[id]
end

function ModuleManager:GetAll()
	local result = {}
	for _, module in pairs(self.Modules) do table.insert(result, module) end
	table.sort(result, function(a, b) return a.Name < b.Name end)
	return result
end

function ModuleManager:SetEnabled(id, enabled)
	local module = self.Modules[id]
	if not module then return false, "Unknown module" end
	enabled = enabled == true
	if module.Enabled == enabled then return true end

	if enabled then
		local ok, cleanupOrError = pcall(module.Enable, module.Settings, self.SettingsManager)
		if not ok then
			module.Enabled = false
			self.Notify("error", module.Name .. " failed: " .. tostring(cleanupOrError))
			return false, cleanupOrError
		end
		module.Cleanup = type(cleanupOrError) == "function" and cleanupOrError or nil
		module.Enabled = true
		self.Notify("success", module.Name .. " enabled")
	else
		if module.Cleanup then
			local ok, err = pcall(module.Cleanup)
			if not ok then warn("[MEOW] Cleanup error:", err) end
		end
		module.Cleanup = nil
		module.Enabled = false
		self.Notify("info", module.Name .. " disabled")
	end
	return true
end

function ModuleManager:Toggle(id)
	local module = self.Modules[id]
	if not module then return false end
	return self:SetEnabled(id, not module.Enabled)
end

function ModuleManager:Shutdown()
	for id, module in pairs(self.Modules) do
		if module.Enabled then self:SetEnabled(id, false) end
	end
end


local HUD = {}

function HUD.Register(manager, screenGui)
	manager:Register({
		Id = "fps_hud", Name = "FPS Counter", Category = "HUD",
		Description = "Displays a lightweight client FPS estimate.",
		Settings = { Position = UDim2.fromOffset(18, 90) },
		Enable = function(settings)
			local label = Instance.new("TextLabel")
			label.Name = "MEOW_FPS"
			label.Size = UDim2.fromOffset(150, 25)
			label.Position = settings.Position
			label.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
			label.BackgroundTransparency = 0.2
			label.TextColor3 = Color3.fromRGB(235, 235, 240)
			label.Font = Enum.Font.GothamMedium
			label.TextSize = 12
			label.Parent = screenGui
			local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 7); corner.Parent = label
			local elapsed, frames = 0, 0
			local connection = RunService.RenderStepped:Connect(function(dt)
				elapsed += dt; frames += 1
				if elapsed >= 0.5 then
					label.Text = string.format("FPS  %d", math.floor(frames / elapsed + 0.5))
					elapsed, frames = 0, 0
				end
			end)
			return function() connection:Disconnect(); label:Destroy() end
		end,
	})

	manager:Register({
		Id = "ping_hud", Name = "Ping Counter", Category = "HUD",
		Description = "Displays the client-reported Data Ping statistic when available.",
		Settings = { Position = UDim2.fromOffset(18, 120) },
		Enable = function(settings)
			local label = Instance.new("TextLabel")
			label.Name = "MEOW_Ping"
			label.Size = UDim2.fromOffset(150, 25)
			label.Position = settings.Position
			label.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
			label.BackgroundTransparency = 0.2
			label.TextColor3 = Color3.fromRGB(235, 235, 240)
			label.Font = Enum.Font.GothamMedium
			label.TextSize = 12
			label.Text = "PING  --"
			label.Parent = screenGui
			local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 7); corner.Parent = label
			local elapsed = 0
			local connection = RunService.Heartbeat:Connect(function(dt)
				elapsed += dt
				if elapsed >= 1 then
					elapsed = 0
					local ok, value = pcall(function()
						return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
					end)
					label.Text = "PING  " .. (ok and tostring(value) or "--")
				end
			end)
			return function() connection:Disconnect(); label:Destroy() end
		end,
	})
end


local Visuals = {}

local function registerVisuals(manager)
	manager:Register({
		Id = "fullbright", Name = "Fullbright", Category = "Visuals",
		Description = "Locally adjusts lighting for clearer visibility.",
		Settings = { Brightness = 2, Ambient = Color3.fromRGB(170, 170, 185) },
		Enable = function(settings)
			local old = {
				Brightness = Lighting.Brightness,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				GlobalShadows = Lighting.GlobalShadows,
			}
			Lighting.Brightness = settings.Brightness
			Lighting.Ambient = settings.Ambient
			Lighting.OutdoorAmbient = settings.Ambient
			Lighting.GlobalShadows = false
			return function()
				Lighting.Brightness = old.Brightness
				Lighting.Ambient = old.Ambient
				Lighting.OutdoorAmbient = old.OutdoorAmbient
				Lighting.GlobalShadows = old.GlobalShadows
			end
		end,
	})

	manager:Register({
		Id = "fov", Name = "FOV Changer", Category = "Visuals",
		Description = "Sets the local camera field of view.",
		Settings = { Value = 85 },
		Enable = function(settings)
			local camera = Workspace.CurrentCamera
			if not camera then return end
			local old = camera.FieldOfView
			camera.FieldOfView = math.clamp(settings.Value, 50, 110)
			return function()
				if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = old end
			end
		end,
	})

	manager:Register({
		Id = "fog", Name = "Fog Remover", Category = "Visuals",
		Description = "Temporarily reduces legacy fog on the client.",
		Settings = {},
		Enable = function()
			local oldStart, oldEnd = Lighting.FogStart, Lighting.FogEnd
			Lighting.FogStart, Lighting.FogEnd = 0, 100000
			return function()
				Lighting.FogStart, Lighting.FogEnd = oldStart, oldEnd
			end
		end,
	})

	manager:Register({
		Id = "bloom", Name = "Bloom", Category = "Visuals",
		Description = "Adds a configurable local bloom effect.",
		Settings = { Intensity = 0.35, Size = 24, Threshold = 1.2 },
		Enable = function(settings)
			local effect = Instance.new("BloomEffect")
			effect.Name = "MEOW_LocalBloom"
			effect.Intensity = math.clamp(settings.Intensity, 0, 2)
			effect.Size = math.clamp(settings.Size, 0, 56)
			effect.Threshold = math.clamp(settings.Threshold, 0, 2)
			effect.Parent = Lighting
			return function() effect:Destroy() end
		end,
	})

	manager:Register({
		Id = "test_highlights", Name = "Test Target Highlights", Category = "Visuals",
		Description = "Highlights only models tagged MEOW_VisualTarget in your own experience.",
		Settings = { Fill = Color3.fromRGB(235, 65, 85), Outline = Color3.fromRGB(255, 255, 255) },
		Enable = function(settings)
			local made = {}
			local function add(instance)
				if not instance:IsA("Model") then return end
				local highlight = Instance.new("Highlight")
				highlight.Name = "MEOW_TestHighlight"
				highlight.FillColor = settings.Fill
				highlight.OutlineColor = settings.Outline
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.Parent = instance
				made[instance] = highlight
			end
			for _, instance in ipairs(CollectionService:GetTagged("MEOW_VisualTarget")) do add(instance) end
			local added = CollectionService:GetInstanceAddedSignal("MEOW_VisualTarget"):Connect(add)
			local removed = CollectionService:GetInstanceRemovedSignal("MEOW_VisualTarget"):Connect(function(instance)
				if made[instance] then made[instance]:Destroy(); made[instance] = nil end
			end)
			return function()
				added:Disconnect(); removed:Disconnect()
				for _, highlight in pairs(made) do highlight:Destroy() end
				table.clear(made)
			end
		end,
	})
end

Visuals.Register = registerVisuals


local AdvancedSuite = {}

local C = {
	BG = Color3.fromRGB(10, 10, 13),
	Panel = Color3.fromRGB(17, 17, 22),
	Card = Color3.fromRGB(25, 25, 32),
	Stroke = Color3.fromRGB(55, 48, 57),
	Text = Color3.fromRGB(241, 239, 245),
	Muted = Color3.fromRGB(148, 144, 155),
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

local function round(object, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 9) }, object)
end

local function outline(object, color)
	make("UIStroke", { Color = color or C.Stroke, Transparency = 0.18, Thickness = 1 }, object)
end

local function label(parent, text, size, position, fontSize, color, align)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Position = position or UDim2.fromOffset(0, 0),
		Size = size,
		Text = text,
		TextColor3 = color or C.Text,
		Font = Enum.Font.Gotham,
		TextSize = fontSize or 11,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function button(parent, text, size, position, callback, accent)
	local b = make("TextButton", {
		Size = size,
		Position = position,
		BackgroundColor3 = accent and C.RedDark or C.Card,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = C.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		AutoButtonColor = true,
	}, parent)
	round(b, 7)
	b.MouseButton1Click:Connect(callback)
	return b
end

local function getHumanoid(character)
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getPing()
	local ok, value = pcall(function()
		local item = Stats.Network.ServerStatsItem["Data Ping"]
		return item:GetValue()
	end)
	return ok and tonumber(value) or nil
end

function AdvancedSuite.Mount(context)
	local player = context.Player or Players.LocalPlayer
	local playerGui = context.PlayerGui or player:WaitForChild("PlayerGui")
	local advancedScreen = make("ScreenGui", { Name = "MeowAdvancedSuite", IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 41 }, playerGui)
	local notify = context.Notify or function() end
	local module = {}
	local alive = true
	local connections = {}
	local featureGui = make("Frame", {
		Name = "MEOW_AdvancedSuite",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 510),
		BackgroundColor3 = C.BG,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, advancedScreen)
	round(featureGui, 13); outline(featureGui, C.RedDark)

	local top = make("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, featureGui)
	round(top, 13)
	make("Frame", { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, top)
	label(top, "MEOW  /  ADVANCED SYSTEMS", UDim2.new(1, -120, 1, 0), UDim2.fromOffset(16, 0), 12, C.Text).ZIndex = 32
	local close = button(top, "CLOSE  ×", UDim2.fromOffset(78, 28), UDim2.new(1, -91, 0, 10), function()
		featureGui.Visible = false
	end, false)
	close.ZIndex = 33

	local tabs = make("Frame", { Position = UDim2.fromOffset(12, 60), Size = UDim2.new(0, 132, 1, -72), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 31 }, featureGui)
	round(tabs, 10)
	local body = make("Frame", { Position = UDim2.fromOffset(156, 60), Size = UDim2.new(1, -168, 1, -72), BackgroundTransparency = 1, ZIndex = 31 }, featureGui)
	local pageTitle = label(body, "COSMETICS CATALOG", UDim2.new(1, -10, 0, 25), UDim2.fromOffset(0, 0), 15, C.Text)
	pageTitle.Font = Enum.Font.GothamBold
	local pageSubtitle = label(body, "Local-only avatar appearance preview. No inventory or ownership changes.", UDim2.new(1, -10, 0, 20), UDim2.fromOffset(0, 26), 9, C.Muted)

	local pages = {}
	local function newPage(id)
		local page = make("Frame", {
			Name = id,
			Position = UDim2.fromOffset(0, 54),
			Size = UDim2.new(1, 0, 1, -54),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 32,
		}, body)
		pages[id] = page
		return page
	end

	local tabNames = {
		{"Cosmetics", "CATALOG"},
		{"HUD Editor", "HUD EDITOR"},
		{"Emote Wheel", "EMOTES"},
		{"Performance", "PERFORMANCE"},
	}
	local currentPage = "Cosmetics"
	local function showPage(name)
		currentPage = name
		for id, page in pairs(pages) do page.Visible = id == name end
		pageTitle.Text = string.upper(name)
		local descriptions = {
			["Cosmetics"] = "Local-only avatar appearance preview. No inventory or ownership changes.",
			["HUD Editor"] = "Drag widgets, resize them, snap to grid, and save or reset their layout.",
			["Emote Wheel"] = "Open with G while playing. Emotes depend on the current experience and avatar rig.",
			["Performance"] = "Live client-side frame-rate, frame-time, and available ping estimates.",
		}
		pageSubtitle.Text = descriptions[name] or ""
		for _, child in ipairs(tabs:GetChildren()) do
			if child:IsA("TextButton") then
				local active = child.Name == name
				child.BackgroundColor3 = active and C.RedDark or C.Card
				child.TextColor3 = active and C.Text or C.Muted
			end
		end
	end

	for index, tab in ipairs(tabNames) do
		local b = button(tabs, tab[2], UDim2.new(1, -14, 0, 34), UDim2.fromOffset(7, 8 + (index - 1) * 41), function()
			showPage(tab[1])
		end, index == 1)
		b.Name = tab[1]
		b.ZIndex = 32
	end


	local cosmetics = newPage("Cosmetics")
	local viewport = make("ViewportFrame", {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0.53, -8, 1, 0),
		BackgroundColor3 = Color3.fromRGB(14, 14, 19),
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(190, 190, 205),
		LightColor = Color3.fromRGB(255, 255, 255),
		ZIndex = 33,
	}, cosmetics)
	round(viewport, 10); outline(viewport)
	local world = Instance.new("WorldModel"); world.Parent = viewport
	local camera = Instance.new("Camera"); camera.FieldOfView = 38; camera.Parent = viewport
	viewport.CurrentCamera = camera
	local previewModel
	local yaw, zoom = math.rad(180), 8
	local previewBusy = false
	local function positionCamera()
		if not previewModel then return end
		local pivot = previewModel:GetPivot()
		local focus = pivot.Position + Vector3.new(0, 2.5, 0)
		local direction = Vector3.new(math.sin(yaw), 0.12, math.cos(yaw))
		camera.CFrame = CFrame.lookAt(focus + direction * zoom, focus)
	end
	local function clearPreview()
		if previewModel then previewModel:Destroy(); previewModel = nil end
	end
	local function buildPreview(description)
		if previewBusy or not description then return end
		previewBusy = true
		local descriptionCopy = description:Clone()
		task.spawn(function()
			local ok, modelOrError = pcall(function()
				return Players:CreateHumanoidModelFromDescriptionAsync(descriptionCopy, Enum.HumanoidRigType.R15)
			end)
			descriptionCopy:Destroy()
			if not alive then
				if ok and modelOrError then modelOrError:Destroy() end
				previewBusy = false
				return
			end
			if ok and modelOrError then
				clearPreview()
				previewModel = modelOrError
				previewModel.Name = "MEOW_AvatarPreview"
				previewModel.Parent = world
				previewModel:PivotTo(CFrame.new(0, 0, 0))
				yaw, zoom = math.rad(180), 8
				positionCamera()
				notify("success", "Avatar preview refreshed.")
			else
				notify("error", "Avatar preview failed: " .. tostring(modelOrError))
			end
			previewBusy = false
		end)
	end

	local baseDescription
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = getHumanoid(character)
		if humanoid then
			local ok, description = pcall(function() return humanoid:GetAppliedDescription() end)
			if ok and description then
				baseDescription = description
				buildPreview(description)
			else
				notify("warning", "Could not read the current avatar description.")
			end
		end
	end)

	local dragStart
	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = input.Position
		end
	end)
	viewport.InputChanged:Connect(function(input)
		if dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			yaw += delta.X * 0.012
			dragStart = input.Position
			positionCamera()
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			zoom = math.clamp(zoom - input.Position.Z * 0.65, 4, 14)
			positionCamera()
		end
	end)
	viewport.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = nil
		end
	end)

	local catalog = make("Frame", { Position = UDim2.new(0.53, 4, 0, 0), Size = UDim2.new(0.47, -4, 1, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, cosmetics)
	round(catalog, 10); outline(catalog)
	label(catalog, "APPEARANCE CATALOG", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 8), 11, C.Text).Font = Enum.Font.GothamBold
	label(catalog, "Enter a valid Roblox catalog asset ID.", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 31), 8, C.Muted)
	local assetBox = make("TextBox", { Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 31), BackgroundColor3 = C.Card, BorderSizePixel = 0, Text = "", PlaceholderText = "Catalog asset ID", PlaceholderColor3 = C.Muted, TextColor3 = C.Text, Font = Enum.Font.Gotham, TextSize = 10, ClearTextOnFocus = false }, catalog)
	round(assetBox, 7)
	local categoryChoice = "HatAccessory"
	local categoryButton
	categoryButton = button(catalog, "CATEGORY: HAT  ▾", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 94), function()
		local choices = {
			{"HatAccessory", "HAT"}, {"HairAccessory", "HAIR"}, {"FaceAccessory", "FACE"},
			{"NeckAccessory", "NECK"}, {"ShouldersAccessory", "SHOULDER"},
			{"FrontAccessory", "FRONT"}, {"BackAccessory", "BACK"}, {"WaistAccessory", "WAIST"},
		}
		local index = 1
		for i, item in ipairs(choices) do if item[1] == categoryChoice then index = i end end
		local nextItem = choices[index % #choices + 1]
		categoryChoice = nextItem[1]
		categoryButton.Text = "CATEGORY: " .. nextItem[2] .. "  ▾"
	end, false)
	local applyButton = button(catalog, "ADD TO LOCAL PREVIEW", UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 132), function()
		if not baseDescription then notify("warning", "Avatar description is not ready yet."); return end
		local id = assetBox.Text:match("^%s*(%d+)%s*$")
		if not id then notify("error", "Enter a numeric catalog asset ID."); return end
		local desc = baseDescription:Clone()
		local old = desc[categoryChoice]
		local ids = {}
		if type(old) == "string" and old ~= "" then
			for token in string.gmatch(old, "[^,]+") do table.insert(ids, token) end
		end
		if #ids >= 10 then notify("warning", "This accessory slot already has 10 entries."); desc:Destroy(); return end
		table.insert(ids, id)
		desc[categoryChoice] = table.concat(ids, ",")
		buildPreview(desc)
		desc:Destroy()
	end, true)
	local resetButton = button(catalog, "RESET AVATAR PREVIEW", UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 170), function()
		if baseDescription then buildPreview(baseDescription) end
	end, false)
	local rotateHint = label(catalog, "DRAG TO ROTATE  ·  SCROLL TO ZOOM", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(10, 210), 8, C.Muted)
	rotateHint.TextWrapped = true
	local note = label(catalog, "Preview only. This does not grant ownership, purchase items, or change your live avatar.", UDim2.new(1, -20, 0, 62), UDim2.fromOffset(10, 240), 9, C.Muted)
	note.TextWrapped = true
	note.TextYAlignment = Enum.TextYAlignment.Top

	-- ADVANCED HUD EDITOR
	local hudPage = newPage("HUD Editor")
	local hudCanvas = make("Frame", { Size = UDim2.new(1, 0, 1, -70), BackgroundColor3 = Color3.fromRGB(13, 13, 18), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 33 }, hudPage)
	round(hudCanvas, 10); outline(hudCanvas)
	local hudToolbar = make("Frame", { Position = UDim2.new(0, 0, 1, -62), Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, hudPage)
	round(hudToolbar, 9)
	local snapEnabled = true
	local snapSize = 10
	local selectedWidget
	local savedLayout = {}
	local hudWidgets = {}
	local function snap(value)
		if not snapEnabled then return value end
		return math.floor(value / snapSize + 0.5) * snapSize
	end
	local function makeWidget(name, text, pos, size)
		local widget = make("TextLabel", {
			Name = name, Position = pos, Size = size, BackgroundColor3 = C.Card,
			BackgroundTransparency = 0.12, Text = text, TextColor3 = C.Text,
			Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0,
			Active = true, Selectable = true, ZIndex = 35,
		}, hudCanvas)
		round(widget, 6); outline(widget, C.RedDark)
		hudWidgets[name] = widget
		local handle = make("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(15, 15), BackgroundColor3 = C.Red, Text = "↘", TextColor3 = C.Text, TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 36 }, widget)
		round(handle, 4)
		local moving, origin, startPosition = false, nil, nil
		widget.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				selectedWidget = widget
				moving = true; origin = input.Position; startPosition = widget.Position
				widget.BackgroundColor3 = C.RedDark
			end
		end)
		local moveConnection = UserInputService.InputChanged:Connect(function(input)
			if moving and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - origin
				local x = snap(startPosition.X.Offset + delta.X)
				local y = snap(startPosition.Y.Offset + delta.Y)
				widget.Position = UDim2.fromOffset(math.clamp(x, 0, math.max(0, hudCanvas.AbsoluteSize.X - widget.AbsoluteSize.X)), math.clamp(y, 0, math.max(0, hudCanvas.AbsoluteSize.Y - widget.AbsoluteSize.Y)))
			end
		end)
		local endConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then moving = false; widget.BackgroundColor3 = C.Card end
		end)
		table.insert(connections, moveConnection)
		table.insert(connections, endConnection)
		handle.MouseButton1Down:Connect(function()
			if selectedWidget == widget then
				widget.Size = UDim2.fromOffset(math.clamp(widget.AbsoluteSize.X + 20, 70, 260), math.clamp(widget.AbsoluteSize.Y + 8, 24, 80))
			end
		end)
		return widget
	end

	makeWidget("Watermark", "MEOW CLIENTOOL", UDim2.fromOffset(12, 12), UDim2.fromOffset(145, 28))
	makeWidget("Session", "SESSION  ·  LOCAL", UDim2.fromOffset(12, 48), UDim2.fromOffset(145, 28))
	makeWidget("Clock", os.date("%H:%M:%S"), UDim2.fromOffset(12, 84), UDim2.fromOffset(105, 28))
	makeWidget("Keybinds", "RIGHT SHIFT  ·  MENU", UDim2.fromOffset(12, 120), UDim2.fromOffset(160, 28))
	local hudClockConnection = RunService.Heartbeat:Connect(function()
		if hudWidgets.Clock then hudWidgets.Clock.Text = os.date("%H:%M:%S") end
	end)
	table.insert(connections, hudClockConnection)

	local snapButton
	snapButton = button(hudToolbar, "SNAP: ON", UDim2.fromOffset(90, 30), UDim2.fromOffset(8, 11), function()
		snapEnabled = not snapEnabled
		snapButton.Text = snapEnabled and "SNAP: ON" or "SNAP: OFF"
	end, false)
	local saveButton = button(hudToolbar, "SAVE LAYOUT", UDim2.fromOffset(100, 30), UDim2.fromOffset(106, 11), function()
		savedLayout = {}
		for name, widget in pairs(hudWidgets) do
			savedLayout[name] = {
				X = widget.Position.X.Offset, Y = widget.Position.Y.Offset,
				W = widget.Size.X.Offset, H = widget.Size.Y.Offset,
			}
		end
		notify("success", "HUD layout saved for this session.")
	end, true)
	local resetHudButton = button(hudToolbar, "RESET", UDim2.fromOffset(70, 30), UDim2.fromOffset(214, 11), function()
		local defaults = {
			Watermark = {12, 12, 145, 28}, Session = {12, 48, 145, 28},
			Clock = {12, 84, 105, 28}, Keybinds = {12, 120, 160, 28},
		}
		for name, values in pairs(defaults) do
			local widget = hudWidgets[name]
			if widget then
				widget.Position = UDim2.fromOffset(values[1], values[2])
				widget.Size = UDim2.fromOffset(values[3], values[4])
			end
		end
		notify("info", "HUD layout reset.")
	end, false)
	local exportHudButton = button(hudToolbar, "EXPORT", UDim2.fromOffset(76, 30), UDim2.fromOffset(292, 11), function()
		local ok, result = pcall(function() return HttpService:JSONEncode(savedLayout) end)
		if ok then
			notify("info", "HUD layout JSON generated (" .. tostring(#result) .. " chars).")
		end
	end, false)
	local restoreHudButton = button(hudToolbar, "RESTORE SAVED", UDim2.fromOffset(104, 30), UDim2.fromOffset(376, 11), function()
		if not next(savedLayout) then notify("warning", "Save a layout first."); return end
		for name, values in pairs(savedLayout) do
			local widget = hudWidgets[name]
			if widget then
				widget.Position = UDim2.fromOffset(values.X, values.Y)
				widget.Size = UDim2.fromOffset(values.W, values.H)
			end
		end
		notify("success", "Saved HUD layout restored.")
	end, false)
	local hudHint = label(hudPage, "Select and drag a widget. Use its bottom-right handle to resize. Layout is session-local in this client build.", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 1, -16), 8, C.Muted)


	local emotePage = newPage("Emote Wheel")
	local emoteWheel = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromOffset(340, 340), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 34 }, emotePage)
	round(emoteWheel, 170); outline(emoteWheel, C.RedDark)
	local emoteCenter = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(104, 104), BackgroundColor3 = C.RedDark, BorderSizePixel = 0, ZIndex = 35 }, emoteWheel)
	round(emoteCenter, 52)
	label(emoteCenter, "EMOTE\nSELECT", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 12, C.Text, Enum.TextXAlignment.Center).ZIndex = 36
	local emotes = {"wave", "point", "cheer", "laugh", "dance"}
	local emoteButtons = {}
	for index, emote in ipairs(emotes) do
		local angle = (index - 1) * (math.pi * 2 / #emotes) - math.pi / 2
		local x = 170 + math.cos(angle) * 116 - 43
		local y = 170 + math.sin(angle) * 116 - 17
		local b = button(emoteWheel, string.upper(emote), UDim2.fromOffset(86, 34), UDim2.fromOffset(x, y), function()
			local humanoid = getHumanoid(player.Character)
			if not humanoid then notify("warning", "Character is not ready."); return end
			local ok, result = pcall(function() return humanoid:PlayEmote(emote) end)
			if ok and result then notify("success", "Requested emote: " .. emote)
			else notify("warning", "This emote is unavailable in the current experience/avatar.") end
		end, false)
		b.ZIndex = 36
		emoteButtons[emote] = b
	end
	label(emotePage, "HOLD G TO OPEN THE IN-GAME RADIAL SELECTOR. CLICK AN EMOTE TO REQUEST IT.", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 1, -24), 8, C.Muted, Enum.TextXAlignment.Center)
	local wheelOverlay = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, advancedScreen)
	local wheelOpen = false
	local function requestEmote(emote)
		local humanoid = getHumanoid(player.Character)
		if not humanoid then notify("warning", "Character is not ready."); return end
		local ok, result = pcall(function() return humanoid:PlayEmote(emote) end)
		if ok and result then notify("success", "Requested emote: " .. emote)
		else notify("warning", "This emote is unavailable in the current experience/avatar.") end
	end
	local function setWheel(open)
		wheelOpen = open
		wheelOverlay.Visible = open
		wheelOverlay:ClearAllChildren()
		if open then
			local center = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(100, 100), BackgroundColor3 = C.RedDark, BorderSizePixel = 0, ZIndex = 51 }, wheelOverlay)
			round(center, 50)
			label(center, "MEOW\nEMOTES", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 12, C.Text, Enum.TextXAlignment.Center).ZIndex = 52
			for index, emote in ipairs(emotes) do
				local angle = (index - 1) * (math.pi * 2 / #emotes) - math.pi / 2
				local x = 170 + math.cos(angle) * 116 - 43
				local y = 170 + math.sin(angle) * 116 - 17
				local b = button(wheelOverlay, string.upper(emote), UDim2.fromOffset(86, 34), UDim2.fromOffset(x, y), function()
					requestEmote(emote)
					setWheel(false)
				end, false)
				b.ZIndex = 52
			end
		end
	end
	local emoteInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.G then setWheel(true) end
	end)
	local emoteInputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.G then setWheel(false) end
	end)
	table.insert(connections, emoteInputBegan)
	table.insert(connections, emoteInputEnded)

	
	local performance = newPage("Performance")
	local metricCards = make("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1, ZIndex = 33 }, performance)
	local function metricCard(x, title)
		local card = make("Frame", { Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0.32, -5, 1, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, metricCards)
		round(card, 9); outline(card)
		label(card, title, UDim2.new(1, -16, 0, 18), UDim2.fromOffset(9, 8), 8, C.Muted)
		local value = label(card, "--", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(9, 31), 19, C.Text)
		value.Font = Enum.Font.GothamBold
		return value
	end
	local fpsValue = metricCard(0, "CURRENT FPS")
	local frameValue = metricCard(0.34, "FRAME TIME")
	local pingValue = metricCard(0.68, "DATA PING")
	local graphPanel = make("Frame", { Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 1, -130), BackgroundColor3 = C.Panel, BorderSizePixel = 0, ZIndex = 33 }, performance)
	round(graphPanel, 10); outline(graphPanel)
	local graphTitle = label(graphPanel, "FPS HISTORY  ·  LAST 30 SAMPLES", UDim2.new(1, -155, 0, 22), UDim2.fromOffset(12, 8), 9, C.Muted)
	local graphMode = "FPS"
	local graphModeButton
	graphModeButton = button(graphPanel, "VIEW: FPS  ▾", UDim2.fromOffset(112, 25), UDim2.new(1, -124, 0, 6), function()
		local modes = {"FPS", "FRAME TIME", "PING"}
		local index = 1
		for i, mode in ipairs(modes) do if mode == graphMode then index = i end end
		graphMode = modes[index % #modes + 1]
		graphModeButton.Text = "VIEW: " .. graphMode .. "  ▾"
		graphTitle.Text = graphMode .. " HISTORY  ·  LAST 30 SAMPLES"
	end, false)
	local graph = make("Frame", { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 1, -52), BackgroundColor3 = Color3.fromRGB(12, 12, 16), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 34 }, graphPanel)
	round(graph, 6)
	local bars = {}
	for i = 1, 30 do
		local bar = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / 30, 1, 1, -4), Size = UDim2.new(1 / 30, -3, 0, 4), BackgroundColor3 = C.Red, BorderSizePixel = 0, ZIndex = 35 }, graph)
		round(bar, 3)
		bars[i] = bar
	end
	local history = {}
	local fpsHistory, frameHistory, pingHistory = {}, {}, {}
	local fpsSamples, frameSamples = {}, {}
	local accumulator, sampleElapsed, frameCount = 0, 0, 0
	local perfConnection = RunService.RenderStepped:Connect(function(dt)
		if not alive then return end
		accumulator += dt
		sampleElapsed += dt
		frameCount += 1
		if accumulator >= 0.5 then
			local fps = frameCount / sampleElapsed
			local frameMs = (sampleElapsed / math.max(frameCount, 1)) * 1000
			local ping = getPing()
			table.insert(history, fps)
			if #history > 30 then table.remove(history, 1) end
			local function pushSample(target, value)
				table.insert(target, value or 0)
				if #target > 30 then table.remove(target, 1) end
			end
			pushSample(fpsHistory, fps)
			pushSample(frameHistory, frameMs)
			pushSample(pingHistory, ping)
			table.insert(fpsSamples, fps); if #fpsSamples > 60 then table.remove(fpsSamples, 1) end
			table.insert(frameSamples, frameMs); if #frameSamples > 60 then table.remove(frameSamples, 1) end
			fpsValue.Text = string.format("%d", math.floor(fps + 0.5))
			frameValue.Text = string.format("%.1f ms", frameMs)
			pingValue.Text = ping and string.format("%.0f ms", ping) or "--"
			local selectedHistory = graphMode == "FPS" and fpsHistory or (graphMode == "FRAME TIME" and frameHistory or pingHistory)
			local ceiling = graphMode == "FPS" and 144 or (graphMode == "FRAME TIME" and 50 or 250)
			for i, bar in ipairs(bars) do
				local value = selectedHistory[i] or 0
				local height = math.clamp(value / ceiling, 0.04, 1)
				bar.Size = UDim2.new(1 / 30, -3, height, -3)
				local warning = (graphMode == "FPS" and value < 30) or (graphMode == "FRAME TIME" and value > 33)
				bar.BackgroundColor3 = warning and Color3.fromRGB(235, 75, 75) or C.Red
			end
			accumulator, sampleElapsed, frameCount = 0, 0, 0
		end
	end)
	table.insert(connections, perfConnection)
	local avgLabel = label(performance, "AVERAGE FPS: --     AVERAGE FRAME TIME: --", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -20), 9, C.Muted)
	local avgConnection = RunService.Heartbeat:Connect(function()
		if #fpsSamples > 0 then
			local totalFps, totalFrame = 0, 0
			for i = 1, #fpsSamples do totalFps += fpsSamples[i] end
			for i = 1, #frameSamples do totalFrame += frameSamples[i] end
			avgLabel.Text = string.format("AVERAGE FPS: %.0f     AVERAGE FRAME TIME: %.1f ms", totalFps / #fpsSamples, totalFrame / #frameSamples)
		end
	end)
	table.insert(connections, avgConnection)

	showPage("Cosmetics")
	module.Gui = featureGui
	function module:Open()
		featureGui.Visible = true
		showPage("Cosmetics")
	end
	function module:Destroy()
		alive = false
		for _, connection in ipairs(connections) do
			if connection and connection.Connected then connection:Disconnect() end
		end
		if wheelOverlay then wheelOverlay:Destroy() end
		clearPreview()
		if baseDescription then baseDescription:Destroy() end
		if advancedScreen then advancedScreen:Destroy() end
	end
	return module
end


local Bundle = {
	KeybindManager = KeybindManager,
	SettingsManager = SettingsManager,
	NotificationManager = NotificationManager,
	ModuleManager = ModuleManager,
	HUD = HUD,
	Visuals = Visuals,
	AdvancedSuite = AdvancedSuite,
}



local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    warn("[Meow Client] LocalPlayer is unavailable. Run this as a LocalScript.")
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("MeowClient")
if oldGui then
    oldGui:Destroy()
end

local Palette = {
    Background = Color3.fromRGB(8, 8, 11),
    Panel = Color3.fromRGB(16, 16, 21),
    Card = Color3.fromRGB(24, 24, 31),
    CardHover = Color3.fromRGB(34, 24, 31),
    Stroke = Color3.fromRGB(57, 43, 51),
    Text = Color3.fromRGB(244, 240, 244),
    Muted = Color3.fromRGB(155, 146, 155),
    Accent = Color3.fromRGB(236, 55, 86),
    AccentDark = Color3.fromRGB(87, 21, 39),
    Green = Color3.fromRGB(77, 213, 146),
    Amber = Color3.fromRGB(255, 190, 76),
    Blue = Color3.fromRGB(104, 166, 255),
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 9) }, object)
end

local function stroke(object, color, transparency)
    return create("UIStroke", {
        Color = color or Palette.Stroke,
        Transparency = transparency == nil and 0.18 or transparency,
        Thickness = 1,
    }, object)
end

local function label(parent, text, size, position, textSize, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Size = size,
        Position = position,
        Text = text or "",
        TextColor3 = color or Palette.Text,
        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
    }, parent)
end

local function button(parent, text, size, position, callback, accent)
    local control = create("TextButton", {
        Size = size,
        Position = position,
        BackgroundColor3 = accent and Palette.AccentDark or Palette.Card,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Palette.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = true,
    }, parent)
    round(control, 7)
    control.Activated:Connect(callback)
    return control
end

local screenGui = create("ScreenGui", {
    Name = "MeowClient",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 40,
}, playerGui)

local toastLayer = create("Frame", {
    Name = "ToastLayer",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(0, 0),
}, screenGui)

local notifications = Bundle.NotificationManager.new(toastLayer)
local function notify(kind, message)
    notifications:Push(kind, message)
end

local settingsManager = Bundle.SettingsManager.new()
local moduleManager = Bundle.ModuleManager.new(settingsManager, notify)
local keybindManager = Bundle.KeybindManager.new()
Bundle.Visuals.Register(moduleManager)
Bundle.HUD.Register(moduleManager, screenGui)


local advancedSuite = Bundle.AdvancedSuite.Mount({
    Player = player,
    PlayerGui = playerGui,
    Notify = notify,
})

local window = create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(850, 550),
    BackgroundColor3 = Palette.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, screenGui)
round(window, 14)
stroke(window, Palette.AccentDark, 0.05)

local uiScale = create("UIScale", { Scale = 1 }, window)
local function updateScale()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    uiScale.Scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 610), 0.43, 1)
end
updateScale()
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local topbar = create("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, 57),
    BackgroundColor3 = Palette.Panel,
    BorderSizePixel = 0,
}, window)
round(topbar, 14)
create("Frame", {
    Position = UDim2.new(0, 0, 1, -13),
    Size = UDim2.new(1, 0, 0, 13),
    BackgroundColor3 = Palette.Panel,
    BorderSizePixel = 0,
}, topbar)
create("Frame", {
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Palette.Stroke,
    BorderSizePixel = 0,
}, topbar)

local logo = create("Frame", {
    Position = UDim2.fromOffset(15, 13),
    Size = UDim2.fromOffset(31, 31),
    BackgroundColor3 = Palette.AccentDark,
    BorderSizePixel = 0,
}, topbar)
round(logo, 9)
label(logo, "M", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 17, Palette.Text, Enum.Font.GothamBlack).TextXAlignment = Enum.TextXAlignment.Center
label(topbar, "MEOW CLIENT", UDim2.fromOffset(230, 22), UDim2.fromOffset(56, 9), 15, Palette.Text, Enum.Font.GothamBold)
label(topbar, "VISUAL LAB  /  LOCAL CLIENT BUILD", UDim2.fromOffset(255, 16), UDim2.fromOffset(57, 30), 9, Palette.Muted)

local activeCount = create("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -273, 0.5, 0),
    Size = UDim2.fromOffset(98, 27),
    BackgroundColor3 = Palette.Card,
    BorderSizePixel = 0,
    Text = "0 ACTIVE",
    TextColor3 = Palette.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
}, topbar)
round(activeCount, 7)

local advancedButton = button(topbar, "ADVANCED  ↗", UDim2.fromOffset(98, 28), UDim2.new(1, -259, 0, 14), function()
    advancedSuite:Open()
end, true)
local minimizeButton = button(topbar, "—", UDim2.fromOffset(28, 28), UDim2.new(1, -119, 0, 14), function()
    
end, false)
local closeButton = button(topbar, "×", UDim2.fromOffset(28, 28), UDim2.new(1, -82, 0, 14), function()
    window.Visible = false
    notify("info", "Meow Client hidden. Use RightShift or the floating M button to reopen it.")
end, true)


local bubble
bubble = button(screenGui, "M", UDim2.fromOffset(44, 44), UDim2.new(1, -60, 0.5, 0), function()
    window.Visible = true
    bubble.Visible = false
end, true)
bubble.Name = "ReopenBubble"
bubble.TextSize = 15
bubble.Visible = false
round(bubble, 22)
stroke(bubble, Palette.Accent, 0.05)

local sidebar = create("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(0, 57),
    Size = UDim2.new(0, 165, 1, -57),
    BackgroundColor3 = Palette.Panel,
    BorderSizePixel = 0,
}, window)
local content = create("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(165, 57),
    Size = UDim2.new(1, -165, 1, -57),
    BackgroundTransparency = 1,
}, window)

label(sidebar, "WORKSPACE", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(12, 14), 9, Palette.Muted, Enum.Font.GothamBold)
local nav = create("Frame", {
    Position = UDim2.fromOffset(10, 40),
    Size = UDim2.new(1, -20, 1, -52),
    BackgroundTransparency = 1,
}, sidebar)
create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, nav)

local categories = { "Favorites", "Visuals", "HUD", "Cosmetics", "Misc", "Settings" }
local selectedCategory = "Visuals"
local searchText = ""
local enabledOnly = false
local navButtons = {}
local renderCards
local refreshActiveCount
local showConfigPanel
local menuKeyButton, fullbrightKeyButton

local pageTitle = label(content, "VISUALS", UDim2.new(1, -48, 0, 28), UDim2.fromOffset(22, 15), 19, Palette.Text, Enum.Font.GothamBold)
local pageSubtitle = label(content, "Local visual adjustments and HUD modules.", UDim2.new(1, -48, 0, 18), UDim2.fromOffset(23, 43), 10, Palette.Muted)

local searchBox = create("TextBox", {
    Name = "ModuleSearch",
    Position = UDim2.fromOffset(22, 73),
    Size = UDim2.new(1, -238, 0, 34),
    BackgroundColor3 = Palette.Panel,
    BorderSizePixel = 0,
    PlaceholderText = "Search modules...",
    PlaceholderColor3 = Palette.Muted,
    Text = "",
    TextColor3 = Palette.Text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
}, content)
round(searchBox, 8)
stroke(searchBox)
local filterButton
filterButton = button(content, "ALL MODULES", UDim2.fromOffset(93, 34), UDim2.new(1, -204, 0, 73), function()
    enabledOnly = not enabledOnly
    filterButton.Text = enabledOnly and "ENABLED" or "ALL MODULES"
    filterButton.TextColor3 = enabledOnly and Palette.Accent or Palette.Muted
    renderCards()
end, false)
local configButton = button(content, "CONFIG", UDim2.fromOffset(83, 34), UDim2.new(1, -103, 0, 73), function()
    showConfigPanel()
end, true)

local cardScroll = create("ScrollingFrame", {
    Name = "ModuleList",
    Position = UDim2.fromOffset(22, 119),
    Size = UDim2.new(1, -44, 1, -140),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Palette.Accent,
    CanvasSize = UDim2.fromOffset(0, 0),
}, content)
local cardLayout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, cardScroll)
cardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cardScroll.CanvasSize = UDim2.fromOffset(0, cardLayout.AbsoluteContentSize.Y + 8)
end)

local configPanel = create("Frame", {
    Name = "ConfigPanel",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 116),
    Size = UDim2.fromOffset(310, 365),
    BackgroundColor3 = Palette.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, content)
round(configPanel, 11)
stroke(configPanel, Palette.AccentDark, 0.08)
label(configPanel, "CONFIGURATION  /  JSON", UDim2.new(1, -30, 0, 24), UDim2.fromOffset(15, 10), 11, Palette.Text, Enum.Font.GothamBold).ZIndex = 11
label(configPanel, "Export or import module preferences.", UDim2.new(1, -30, 0, 18), UDim2.fromOffset(15, 33), 9, Palette.Muted).ZIndex = 11
local configText = create("TextBox", {
    Position = UDim2.fromOffset(12, 58),
    Size = UDim2.new(1, -24, 1, -150),
    BackgroundColor3 = Palette.Card,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Export JSON appears here. Paste JSON to import.",
    PlaceholderColor3 = Palette.Muted,
    TextColor3 = Palette.Text,
    Font = Enum.Font.Code,
    TextSize = 9,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    MultiLine = true,
    ZIndex = 11,
}, configPanel)
round(configText, 7)
stroke(configText)
local exportButton = button(configPanel, "GENERATE JSON", UDim2.new(0.48, -4, 0, 29), UDim2.new(0, 12, 1, -78), function()
    local encoded = {}
    for _, module in ipairs(moduleManager:GetAll()) do
        local safeSettings = {}
        for key, value in pairs(module.Settings) do
            local kind = typeof(value)
            if kind == "number" or kind == "string" or kind == "boolean" then
                safeSettings[key] = value
            elseif kind == "Color3" then
                safeSettings[key] = { __type = "Color3", r = value.R, g = value.G, b = value.B }
            elseif kind == "UDim2" then
                safeSettings[key] = {
                    __type = "UDim2", xs = value.X.Scale, xo = value.X.Offset,
                    ys = value.Y.Scale, yo = value.Y.Offset,
                }
            end
        end
        encoded[module.Id] = {
            Enabled = module.Enabled,
            Favorite = module.Favorite,
            Settings = safeSettings,
        }
    end
    local keybinds = {}
    for id, keyCode in pairs(keybindManager.Bindings) do
        keybinds[id] = keyCode.Name
    end
    local ok, json = pcall(function()
        return HttpService:JSONEncode({ App = "Meow Client", Version = "1.0.1", Keybinds = keybinds, Modules = encoded })
    end)
    if ok then
        configText.Text = json
        notify("success", "JSON generated. Copy it from the text field.")
    else
        notify("error", "Could not encode this configuration: " .. tostring(json))
    end
end, true)
exportButton.ZIndex = 12
local importButton = button(configPanel, "IMPORT JSON", UDim2.new(0.48, -4, 0, 29), UDim2.new(0.52, 0, 1, -78), function()
    if #configText.Text > 100000 then
        notify("error", "Configuration exceeds the 100 KB limit.")
        return
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(configText.Text)
    end)
    if not ok or type(decoded) ~= "table" then
        notify("error", "Invalid configuration JSON.")
        return
    end
    if type(decoded.Keybinds) == "table" then
        for id, keyName in pairs(decoded.Keybinds) do
            if (id == "ToggleInterface" or id == "ToggleFullbright") and type(keyName) == "string" then
                local keyCode = Enum.KeyCode[keyName]
                if keyCode and keyCode ~= Enum.KeyCode.Unknown then
                    local assigned = keybindManager:Set(id, keyCode)
                    if not assigned then
                        notify("warning", "A keybind conflict was skipped: " .. id)
                    end
                end
            end
        end
        menuKeyButton.Text = "MENU KEY  ·  " .. keybindManager.Bindings.ToggleInterface.Name
        fullbrightKeyButton.Text = "FULLBRIGHT KEY  ·  " .. keybindManager.Bindings.ToggleFullbright.Name
    end
    local source = type(decoded.Modules) == "table" and decoded.Modules or decoded
    for id, entry in pairs(source) do
        local module = moduleManager:Get(id)
        if module and type(entry) == "table" then
            local wasEnabled = module.Enabled
            if wasEnabled and type(entry.Settings) == "table" then
                moduleManager:SetEnabled(id, false)
            end
            if type(entry.Favorite) == "boolean" then
                module.Favorite = entry.Favorite
            end
            if type(entry.Settings) == "table" then
                for key, rawValue in pairs(entry.Settings) do
                    if module.Settings[key] ~= nil then
                        local currentType = typeof(module.Settings[key])
                        local nextValue = rawValue
                        if type(rawValue) == "table" and rawValue.__type == "Color3" and currentType == "Color3" then
                            if type(rawValue.r) == "number" and type(rawValue.g) == "number" and type(rawValue.b) == "number" then
                                nextValue = Color3.new(math.clamp(rawValue.r, 0, 1), math.clamp(rawValue.g, 0, 1), math.clamp(rawValue.b, 0, 1))
                            end
                        elseif type(rawValue) == "table" and rawValue.__type == "UDim2" and currentType == "UDim2" then
                            if type(rawValue.xs) == "number" and type(rawValue.xo) == "number" and type(rawValue.ys) == "number" and type(rawValue.yo) == "number" then
                                nextValue = UDim2.new(rawValue.xs, rawValue.xo, rawValue.ys, rawValue.yo)
                            end
                        end
                        if typeof(nextValue) == currentType then
                            module.Settings[key] = nextValue
                        end
                    end
                end
            end
            local desiredEnabled = wasEnabled
            if type(entry.Enabled) == "boolean" then
                desiredEnabled = entry.Enabled
            end
            moduleManager:SetEnabled(id, desiredEnabled)
        end
    end
    refreshActiveCount()
    renderCards()
    notify("success", "Compatible configuration values imported.")
end, false)
importButton.ZIndex = 12

local configClose = button(configPanel, "CLOSE", UDim2.new(1, -24, 0, 25), UDim2.new(0, 12, 1, -39), function()
    configPanel.Visible = false
end, false)
configClose.ZIndex = 12

showConfigPanel = function(module)
    configPanel.Visible = true
    if module then
        configText.Text = "-- Settings for " .. module.Name .. "\n-- Use the module card's settings control to edit numeric options."
    end
end

local function switchCategory(category)
    selectedCategory = category
    pageTitle.Text = string.upper(category)
    local descriptions = {
        Favorites = "Your starred modules, gathered in one place.",
        Visuals = "Client-side lighting, camera, and atmosphere effects.",
        HUD = "Lightweight FPS and ping readouts.",
        Cosmetics = "Local avatar preview, emotes, and HUD editor in Advanced.",
        Misc = "Additional local utility modules.",
        Settings = "Keybinds and manual JSON configuration tools.",
    }
    pageSubtitle.Text = descriptions[category] or "Browse available modules."
    configPanel.Visible = category == "Settings"
    for name, navButton in pairs(navButtons) do
        local active = name == category
        navButton.BackgroundColor3 = active and Palette.AccentDark or Palette.Panel
        navButton.TextColor3 = active and Palette.Text or Palette.Muted
    end
    renderCards()
end

for index, category in ipairs(categories) do
    local navButton = button(nav, "   " .. string.upper(category), UDim2.new(1, 0, 0, 32), UDim2.new(), function()
        switchCategory(category)
        if category == "Cosmetics" then advancedSuite:Open() end
    end, category == selectedCategory)
    navButton.LayoutOrder = index
    navButton.TextXAlignment = Enum.TextXAlignment.Left
    navButton.TextSize = 9
    navButtons[category] = navButton
end

local function describeModuleSettings(module)
    local settings = module.Settings
    local count = 0
    for key, value in pairs(settings) do
        if typeof(value) == "number" then count += 1 end
    end
    return count
end

local function openModuleSettings(module)
    configPanel.Visible = true
    local safeSettings = {}
    for key, value in pairs(module.Settings) do
        local kind = typeof(value)
        if kind == "number" or kind == "string" or kind == "boolean" then
            safeSettings[key] = value
        elseif kind == "Color3" then
            safeSettings[key] = { __type = "Color3", r = value.R, g = value.G, b = value.B }
        elseif kind == "UDim2" then
            safeSettings[key] = { __type = "UDim2", xs = value.X.Scale, xo = value.X.Offset, ys = value.Y.Scale, yo = value.Y.Offset }
        end
    end
    local payload = {
        [module.Id] = {
            Enabled = module.Enabled,
            Favorite = module.Favorite,
            Settings = safeSettings,
        },
    }
    local ok, json = pcall(function() return HttpService:JSONEncode(payload) end)
    configText.Text = ok and json or "{}"
    notify("info", "Edit the JSON values for " .. module.Name .. ", then press IMPORT JSON.")
end

renderCards = function()
    for _, child in ipairs(cardScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    local list = moduleManager:GetAll()
    local order = 0
    for _, module in ipairs(list) do
        local categoryMatch =
            (selectedCategory == "Favorites" and module.Favorite)
            or (selectedCategory == "Visuals" and module.Category == "Visuals")
            or (selectedCategory == "HUD" and module.Category == "HUD")
            or (selectedCategory == "Misc" and module.Category ~= "Visuals" and module.Category ~= "HUD")
            or (selectedCategory == "Cosmetics" and false)
            or (selectedCategory == "Settings" and false)
        local query = string.lower(searchText)
        local queryMatch = query == "" or string.find(string.lower(module.Name .. " " .. module.Description .. " " .. module.Category), query, 1, true) ~= nil
        if categoryMatch and queryMatch and (not enabledOnly or module.Enabled) then
            order += 1
            local card = create("Frame", {
                Size = UDim2.new(1, -5, 0, 76),
                BackgroundColor3 = Palette.Card,
                BorderSizePixel = 0,
                LayoutOrder = order,
            }, cardScroll)
            round(card, 9)
            stroke(card)
            create("Frame", {
                Position = UDim2.fromOffset(0, 12),
                Size = UDim2.fromOffset(3, 52),
                BackgroundColor3 = module.Enabled and Palette.Accent or Palette.Stroke,
                BorderSizePixel = 0,
            }, card)
            label(card, module.Name, UDim2.new(1, -190, 0, 20), UDim2.fromOffset(14, 10), 11, Palette.Text, Enum.Font.GothamBold)
            local description = label(card, module.Description, UDim2.new(1, -190, 0, 30), UDim2.fromOffset(14, 33), 9, Palette.Muted)
            description.TextWrapped = true
            description.TextYAlignment = Enum.TextYAlignment.Top

            local favoriteButton = button(card, module.Favorite and "★" or "☆", UDim2.fromOffset(28, 28), UDim2.new(1, -155, 0, 23), function()
                module.Favorite = not module.Favorite
                renderCards()
            end, false)
            favoriteButton.TextColor3 = Palette.Accent
            favoriteButton.TextSize = 17
            local settings = button(card, "···", UDim2.fromOffset(28, 28), UDim2.new(1, -122, 0, 23), function()
                openModuleSettings(module)
            end, false)
            settings.TextSize = 14
            local toggle = button(card, module.Enabled and "ON" or "OFF", UDim2.fromOffset(56, 28), UDim2.new(1, -88, 0, 23), function()
                moduleManager:Toggle(module.Id)
                refreshActiveCount()
                renderCards()
            end, module.Enabled)
            toggle.TextColor3 = module.Enabled and Palette.Green or Palette.Muted
        end
    end
    if order == 0 then
        local empty = label(cardScroll, selectedCategory == "Cosmetics" and "Use ADVANCED to open the local cosmetics catalog." or "No matching modules. Try another category or search.", UDim2.new(1, -8, 0, 54), UDim2.fromOffset(0, 4), 10, Palette.Muted)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    end
end

refreshActiveCount = function()
    local count = 0
    for _, module in ipairs(moduleManager:GetAll()) do
        if module.Enabled then count += 1 end
    end
    activeCount.Text = tostring(count) .. " ACTIVE"
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchText = searchBox.Text
    renderCards()
end)


local settingsNote = label(content, "KEYBINDS", UDim2.new(1, -50, 0, 18), UDim2.fromOffset(22, 114), 9, Palette.Muted, Enum.Font.GothamBold)
settingsNote.Visible = false
menuKeyButton = button(content, "MENU KEY  ·  RIGHTSHIFT", UDim2.fromOffset(190, 30), UDim2.fromOffset(22, 141), function()
    keybindManager:BeginCapture("ToggleInterface")
    notify("info", "Press a keyboard key to set the menu toggle. Escape cancels.")
end, false)
menuKeyButton.Visible = false
fullbrightKeyButton = button(content, "FULLBRIGHT KEY  ·  F8", UDim2.fromOffset(190, 30), UDim2.fromOffset(22, 179), function()
    keybindManager:BeginCapture("ToggleFullbright")
    notify("info", "Press a keyboard key to set the Fullbright toggle. Escape cancels.")
end, false)
fullbrightKeyButton.Visible = false
local resetKeybindsButton = button(content, "RESET DEFAULTS", UDim2.fromOffset(190, 28), UDim2.fromOffset(22, 217), function()
    keybindManager:Set("ToggleInterface", Enum.KeyCode.RightShift)
    keybindManager:Set("ToggleFullbright", Enum.KeyCode.F8)
    menuKeyButton.Text = "MENU KEY  ·  RIGHTSHIFT"
    fullbrightKeyButton.Text = "FULLBRIGHT KEY  ·  F8"
    notify("success", "Keybinds reset to defaults.")
end, false)
resetKeybindsButton.Visible = false

local baseRenderCards = renderCards
renderCards = function()
    baseRenderCards()
    local isSettings = selectedCategory == "Settings"
    settingsNote.Visible = isSettings
    menuKeyButton.Visible = isSettings
    fullbrightKeyButton.Visible = isSettings
    resetKeybindsButton.Visible = isSettings
    if isSettings then
        cardScroll.Visible = false
        searchBox.Visible = false
        filterButton.Visible = false
        configButton.Visible = true
        showConfigPanel()
    else
        cardScroll.Visible = true
        searchBox.Visible = true
        filterButton.Visible = true
        configButton.Visible = true
    end
end

keybindManager:Set("ToggleInterface", Enum.KeyCode.RightShift)
keybindManager:Set("ToggleFullbright", Enum.KeyCode.F8)
keybindManager.Changed.Event:Connect(function(action, id, keyCode)
    if action == "pressed" and id == "ToggleInterface" then
        window.Visible = not window.Visible
        bubble.Visible = not window.Visible
    elseif action == "pressed" and id == "ToggleFullbright" then
        moduleManager:Toggle("fullbright")
        refreshActiveCount()
        renderCards()
    elseif action == "assigned" and id == "ToggleInterface" then
        menuKeyButton.Text = "MENU KEY  ·  " .. keyCode.Name
        notify("success", "Menu toggle assigned to " .. keyCode.Name .. ".")
    elseif action == "assigned" and id == "ToggleFullbright" then
        fullbrightKeyButton.Text = "FULLBRIGHT KEY  ·  " .. keyCode.Name
        notify("success", "Fullbright toggle assigned to " .. keyCode.Name .. ".")
    elseif action == "conflict" then
        menuKeyButton.Text = "MENU KEY  ·  " .. keybindManager.Bindings.ToggleInterface.Name
        fullbrightKeyButton.Text = "FULLBRIGHT KEY  ·  " .. keybindManager.Bindings.ToggleFullbright.Name
        notify("warning", tostring(keyCode.Name) .. " is already assigned. Choose another key.")
    elseif action == "cancel" then
        notify("info", "Keybind change cancelled.")
    elseif action == "capturing" then
        if id == "ToggleInterface" then
            menuKeyButton.Text = "PRESS A KEY..."
        elseif id == "ToggleFullbright" then
            fullbrightKeyButton.Text = "PRESS A KEY..."
        end
    end
end)


local dragging = false
local dragInput
local dragStart
local startPosition
local moveConnection
local function beginDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
        dragInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end
topbar.InputBegan:Connect(beginDrag)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

local minimized = false
minimizeButton.Activated:Connect(function()
    minimized = not minimized
    if minimized then
        window.Size = UDim2.fromOffset(850, 57)
        sidebar.Visible = false
        content.Visible = false
    else
        window.Size = UDim2.fromOffset(850, 550)
        sidebar.Visible = true
        content.Visible = true
    end
end)
closeButton.Activated:Connect(function()
    window.Visible = false
    bubble.Visible = true
end)


local unloadButton = button(content, "UNLOAD MEOW CLIENT", UDim2.fromOffset(190, 30), UDim2.fromOffset(22, 218), function()
    moduleManager:Shutdown()
    advancedSuite:Destroy()
    keybindManager:Destroy()
    settingsManager:Destroy()
    screenGui:Destroy()
    if notifications then
     
    end
end, true)
unloadButton.Visible = false
local baseSettingsRenderCards = renderCards
renderCards = function()
    baseSettingsRenderCards()
    unloadButton.Visible = selectedCategory == "Settings"
end



switchCategory("Visuals")
refreshActiveCount()
renderCards()
notify("success", "Meow Client ready. RightShift toggles the interface; F8 toggles Fullbright.")

-- If the player respawns, this GUI is intentionally retained because ResetOnSpawn=false.
