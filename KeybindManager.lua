local UserInputService = game:GetService("UserInputService")

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
				self:Set(id, input.KeyCode)
				self.Changed:Fire("assigned", id, input.KeyCode)
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

return KeybindManager
