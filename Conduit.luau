--!strict
-- networking wrapper

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()
local WAIT_TIMEOUT = 15

export type RemoteClass = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
export type Interceptor = (player: Player?, name: string, ...any) -> boolean?

local Conduit = {}
Conduit.intercept = nil :: Interceptor?

local remotesRoot = if isServer
    then (function()
        local f = ReplicatedStorage:FindFirstChild("ConduitRemotes")
        if f and f:IsA("Folder") then return f end
        local folder = Instance.new("Folder")
        folder.Name = "ConduitRemotes"
        folder.Parent = ReplicatedStorage
        return folder
    end)()
    else (ReplicatedStorage:WaitForChild("ConduitRemotes", WAIT_TIMEOUT) :: Folder)

assert(remotesRoot, "ConduitRemotes folder not found")

-- declare a remote so both sides agree it exists before anything fires
function Conduit.declare(name: string, class: RemoteClass)
    if isServer then
        if not remotesRoot:FindFirstChild(name) then
            local obj = Instance.new(class)
            obj.Name = name
            obj.Parent = remotesRoot
        end
    else
        remotesRoot:WaitForChild(name, WAIT_TIMEOUT)
    end
end

local function get(name: string): Instance
    local obj = remotesRoot:FindFirstChild(name)
    assert(obj, `remote "{name}" has not been declared, call Conduit.declare first`)
    return obj
end

-- wraps inbound handlers so the intercept hook runs first
local function wrap(name: string, handler: (...any) -> ...any, isInboundFromClient: boolean): (...any) -> ...any
    return function(...: any): ...any
        if Conduit.intercept then
            local player = if isInboundFromClient then (select(1, ...)) else nil
            local args = if isInboundFromClient then { select(2, ...) } else { ... }
            local ok, allow = pcall(Conduit.intercept, player, name, table.unpack(args))
            if ok and allow == false then return end
        end
        return handler(...)
    end
end

-- client to server
function Conduit.fireServer(name: string, ...: any)
    assert(isClient, "fireServer is client-only");
    (get(name) :: RemoteEvent):FireServer(...)
end

function Conduit.fireServerUnreliable(name: string, ...: any)
    assert(isClient, "fireServerUnreliable is client-only");
    (get(name) :: UnreliableRemoteEvent):FireServer(...)
end

function Conduit.invokeServer(name: string, ...: any): ...any
    assert(isClient, "invokeServer is client-only")
    return (get(name) :: RemoteFunction):InvokeServer(...)
end

-- server to client
function Conduit.fireClient(name: string, player: Player, ...: any)
    assert(isServer, "fireClient is server-only");
    (get(name) :: RemoteEvent):FireClient(player, ...)
end

function Conduit.fireAllClients(name: string, ...: any)
    assert(isServer, "fireAllClients is server-only");
    (get(name) :: RemoteEvent):FireAllClients(...)
end

function Conduit.fireClients(name: string, players: { Player }, ...: any)
    assert(isServer, "fireClients is server-only")
    local remote = get(name) :: RemoteEvent
    for _, player in players do
        remote:FireClient(player, ...)
    end
end

function Conduit.invokeClient(name: string, player: Player, ...: any): ...any
    assert(isServer, "invokeClient is server-only")
    return (get(name) :: RemoteFunction):InvokeClient(player, ...)
end

-- handlers
function Conduit.onServerEvent(name: string, handler: (player: Player, ...any) -> ()): RBXScriptConnection
    assert(isServer, "onServerEvent is server-only")
    return (get(name) :: RemoteEvent).OnServerEvent:Connect(wrap(name, handler, true))
end

function Conduit.onServerEventUnreliable(name: string, handler: (player: Player, ...any) -> ()): RBXScriptConnection
    assert(isServer, "onServerEventUnreliable is server-only")
    return (get(name) :: UnreliableRemoteEvent).OnServerEvent:Connect(wrap(name, handler, true))
end

function Conduit.onClientEvent(name: string, handler: (...any) -> ()): RBXScriptConnection
    assert(isClient, "onClientEvent is client-only")
    return (get(name) :: RemoteEvent).OnClientEvent:Connect(wrap(name, handler, false))
end

function Conduit.handleServerInvoke(name: string, handler: (player: Player, ...any) -> ...any)
    assert(isServer, "handleServerInvoke is server-only");
    (get(name) :: RemoteFunction).OnServerInvoke = wrap(name, handler, true)
end

function Conduit.handleClientInvoke(name: string, handler: (...any) -> ...any)
    assert(isClient, "handleClientInvoke is client-only");
    (get(name) :: RemoteFunction).OnClientInvoke = wrap(name, handler, false)
end

return Conduit
