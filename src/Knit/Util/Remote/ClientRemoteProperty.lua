-- ClientRemoteProperty
-- Stephen Leitnick
-- January 07, 2021

--[[

	remoteProperty = ClientRemoteProperty.new(valueObject: Instance)

	remoteProperty:Get(): any
	remoteProperty:Destroy(): void

	remoteProperty.Changed(newValue: any): Connection

--]]


local HttpService = game:GetService("HttpService")
local IS_SERVER = game:GetService("RunService"):IsServer()
local Signal = require(script.Parent.Parent.Signal)

local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty


function ClientRemoteProperty.new(object)

	assert(not IS_SERVER, "ClientRemoteProperty can only be created on the client")

	object.Parent = nil

	local self = setmetatable({
		_guid = HttpService:GenerateGUID( false );
		_object = object;
		_value = nil;
		_isTable = object:IsA("RemoteEvent");
		Changed = Signal.new();
	}, ClientRemoteProperty)

	local function SetValue(v)
		self._value = v
		self.Changed:Fire( object.Value )
	end

	if self._isTable then
		self._change = object.OnClientEvent:Connect(function(tbl)
			SetValue(tbl)
		end)
		SetValue(object.TableRequest:InvokeServer())
	else
		SetValue(object.Value)
		self._change = object.Changed:Connect(function()
			SetValue( object.Value )
		end)
	end

	return self

end


function ClientRemoteProperty:Get()
	return self._value
end


function ClientRemoteProperty:Destroy()
	self._change:Disconnect()
	self.Changed:Destroy()
end


return ClientRemoteProperty
