local HttpService = game:GetService("HttpService")

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
	-- Only accept JSON-compatible primitive values and shallow tables.
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

return SettingsManager
