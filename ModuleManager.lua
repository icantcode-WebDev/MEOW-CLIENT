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
			if not ok then warn("[SK1D] Cleanup error:", err) end
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

return ModuleManager
