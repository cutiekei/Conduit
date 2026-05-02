# Conduit

networking wrapper for roblox. declare remotes once in a shared file, fire/invoke from anywhere without touching RemoteEvents directly.

```lua
-- Remotes.luau (ReplicatedStorage, required by both sides)
local Conduit = require(ReplicatedStorage.Conduit)

Conduit.declare("Ping", "RemoteEvent")
Conduit.declare("GetData", "RemoteFunction")

return Conduit
```

```lua
-- server
local Conduit = require(ReplicatedStorage.Remotes)

Conduit.onServerEvent("Ping", function(player, msg)
    Conduit.fireClient("Ping", player, "pong!")
end)

Conduit.handleServerInvoke("GetData", function(player)
    return { coins = 100 }
end)
```

```lua
-- client
local Conduit = require(ReplicatedStorage.Remotes)

Conduit.onClientEvent("Ping", function(msg)
    print(msg)
end)

Conduit.fireServer("Ping", "hey")

local data = Conduit.invokeServer("GetData")
```

remotes must be declared before use. if you forget, you'll get a clear error telling you which one.

## install

drop `Conduit.luau` into `ReplicatedStorage`. create a `Remotes.luau` next to it for your declarations.

## api

```lua
Conduit.declare(name, class) -- "RemoteEvent", "RemoteFunction", or "UnreliableRemoteEvent"

-- client → server
Conduit.fireServer(name, ...)
Conduit.fireServerUnreliable(name, ...)
Conduit.invokeServer(name, ...) → ...

-- server → client
Conduit.fireClient(name, player, ...)
Conduit.fireAllClients(name, ...)
Conduit.fireClients(name, players, ...)
Conduit.invokeClient(name, player, ...) → ...

-- handlers
Conduit.onServerEvent(name, handler) → RBXScriptConnection
Conduit.onServerEventUnreliable(name, handler) → RBXScriptConnection
Conduit.onClientEvent(name, handler) → RBXScriptConnection
Conduit.handleServerInvoke(name, handler)
Conduit.handleClientInvoke(name, handler)

-- optional global intercept (runs before every inbound handler)
Conduit.intercept = function(player, name, ...) → boolean?
    -- return false to block
end
```

## license

MIT
