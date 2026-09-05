--!strict

local HttpGet = game.HttpGet
local GameId: number = game.GameId

local Games: {[number]: string} = loadstring(
    HttpGet(game, "https://raw.githubusercontent.com/BloodSecret/BloodBlox/main/GameListMobile.lua")
)() :: any

local URL: string? = Games[GameId]
if not URL then
    warn("[BloodyBlox Mobile] Game not supported (ID: " .. tostring(GameId) .. ")")
    return
end

loadstring(HttpGet(game, URL))()
