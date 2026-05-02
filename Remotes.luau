--!strict
-- declare all remotes here. require this on both server and client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conduit = require(ReplicatedStorage.Conduit)

Conduit.declare("Ping", "RemoteEvent")
Conduit.declare("Pong", "RemoteEvent")
Conduit.declare("GetServerTime", "RemoteFunction")

return Conduit
