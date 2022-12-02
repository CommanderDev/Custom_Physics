--!strict

--[[

	Knit.CreateController(controller): Controller
	Knit.AddControllers(folder): Controller[]
	Knit.AddControllersDeep(folder): Controller[]
	Knit.GetService(serviceName): Service
	Knit.GetController(controllerName): Controller
	Knit.Start(): Promise<void>
	Knit.OnStart(): Promise<void>

--]]

local DEBUG: boolean = false
local function DebugPrint( ... )
	if ( DEBUG ) then
		print( ... )
	end
end


type ControllerDef = {
	Name: string,
	[any]: any,
}

type Controller = {
	Name: string,
	[any]: any,
}

type Service = {
	[any]: any,
}


local KnitClient = {}

KnitClient.Version = script.Parent:WaitForChild("GameVersion").Value
KnitClient.KnitVersion = script.Parent:WaitForChild("KnitVersion").Value
KnitClient.Player = game:GetService("Players").LocalPlayer
KnitClient.Controllers = {} :: {[string]: Controller}
KnitClient.Util = script.Parent:WaitForChild("Util")

local Promise = require(KnitClient.Util.Promise)
local Loader = require(KnitClient.Util.Loader)
local Ser = require(KnitClient.Util.Ser)
local ClientRemoteSignal = require(KnitClient.Util.Remote.ClientRemoteSignal)
local ClientRemoteProperty = require(KnitClient.Util.Remote.ClientRemoteProperty)
local TableUtil = require(KnitClient.Util.TableUtil)

local services: {[string]: Service} = {}
local servicesFolder = script.Parent:WaitForChild("Services")

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function BuildService(serviceName: string, folder: Instance): Service
	DebugPrint( "Building", serviceName )
	local service = {}
	local rfFolder = folder:FindFirstChild("RF")
	local reFolder = folder:FindFirstChild("RE")
	local rpFolder = folder:FindFirstChild("RP")
	if rfFolder then
		for _,rf in ipairs(rfFolder:GetChildren()) do
			if rf:IsA("RemoteFunction") then
				local function StandardRemote(_self, ...)
					return Ser.DeserializeArgsAndUnpack(rf:InvokeServer(Ser.SerializeArgsAndUnpack(...)))
				end
				local function PromiseRemote(_self, ...)
					local args = Ser.SerializeArgs(...)
					return Promise.new(function(resolve)
						resolve(Ser.DeserializeArgsAndUnpack(rf:InvokeServer(table.unpack(args, 1, args.n))))
					end)
				end
				service[rf.Name] = StandardRemote
				service[rf.Name .. "Promise"] = PromiseRemote
			end
		end
	end
	if reFolder then
		for _,re in ipairs(reFolder:GetChildren()) do
			if re:IsA("RemoteEvent") then
				service[re.Name] = ClientRemoteSignal.new(re)
			end
		end
	end
	if rpFolder then
		for _,rp in ipairs(rpFolder:GetChildren()) do
			if rp:IsA("ValueBase") or rp:IsA("RemoteEvent") then
				service[rp.Name] = ClientRemoteProperty.new(rp)
			end
		end
	end
	services[serviceName] = service
	DebugPrint( "Built:", serviceName )
	return service
end


local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = KnitClient.Controllers[controllerName]
	return ( controller ~= nil ) and ( not controller._temporaryController )
end


function KnitClient.CreateTemporaryController( controllerName: string ): ( {} )
	local temporaryController = { _temporaryController = true; }
	KnitClient.Controllers[ controllerName ] = temporaryController
	return temporaryController
end


function KnitClient.InjectTable( targetTable: {}, tableToInject: {} ): ()
	for index, value in pairs( tableToInject ) do
		targetTable[ index ] = value
	end
end


function KnitClient.CreateController(controllerDef: ControllerDef): Controller
	assert(type(controllerDef) == "table", "Controller must be a table; got " .. type(controllerDef))
	assert(type(controllerDef.Name) == "string", "Controller.Name must be a string; got " .. type(controllerDef.Name))
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), "Controller \"" .. controllerDef.Name .. "\" already exists")

	DebugPrint( "Building Controller", controllerDef.Name )

	local controller: Controller|{} = KnitClient.Controllers[ controllerDef.Name ] or {}

	-- Remove any temporary data
	controller._temporaryController = nil

	-- Inject knit members
	KnitClient.InjectTable( controller, {
		_knit_is_controller = true;
	} )

	-- Inject controllerDef
	KnitClient.InjectTable( controller, controllerDef )

	KnitClient.Controllers[ controller.Name ] = controller

	DebugPrint( "Finishing Building", controllerDef.Name )

	return controller
end


function KnitClient.AddControllers(folder: Instance): {any}
	return Loader.LoadChildren(folder)
end


function KnitClient.AddControllersDeep(folder: Instance): {any}
	return Loader.LoadDescendants(folder)
end


function KnitClient.GetService(serviceName: string): Service
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder: Instance? = servicesFolder:FindFirstChild(serviceName)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder :: Instance)
end


function KnitClient.GetController(controllerName: string): Controller|{}?
	assert(type(controllerName) == "string", "ServiceName must be a string; got " .. type(controllerName))

	local foundController = KnitClient.Controllers[ controllerName ] or KnitClient.CreateTemporaryController( controllerName )

	return assert( foundController, "Could not find Controller \"" .. controllerName .. "\"" ) :: Controller | {}?
end


function KnitClient.Start()

	if started then
		return Promise.Reject("Knit already started")
	end

	started = true

	local controllers = KnitClient.Controllers

	return Promise.new(function(resolve)

		-- Init:
		local promisesStartControllers = {}
		for _,controller in pairs(controllers) do
			if type(controller.KnitInit) == "function" then
				table.insert(promisesStartControllers, Promise.new(function(r)
					controller:KnitInit()
					r()
				end))
			end
		end

		resolve(Promise.all(promisesStartControllers))

	end):andThen(function()

		-- Start:
		for _,controller in pairs(controllers) do
			if type(controller.KnitStart) == "function" then
				task.spawn(controller.KnitStart, controller)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

		-- Let user know of any uninitilized temporary controllers
		local temporaryControllerNames = {}
		for serviceName: string, controller: Controller|{} in pairs( controllers ) do
			if ( controller._temporaryController ) then
				table.insert( temporaryControllerNames, serviceName )
			end
		end
		if ( #temporaryControllerNames > 0 ) then
			warn( "[KnitClient] Some referenced controllers were never initialized:", table.concat(temporaryControllerNames, ", ") )
		end
	end)

end


function KnitClient.OnStart()
	if startedComplete then
		return Promise.Resolve()
	else
		return Promise.FromEvent(onStartedComplete.Event)
	end
end


return KnitClient
