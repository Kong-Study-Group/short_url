--
-- Lua utils
--
local P = {}

local type = type
local string = string
local pairs = pairs
local next = next
local tonumber = tonumber
local tostring = tostring

setfenv(1, P)

function merge_table(a, b)
    c = {}
    for k,v in pairs(a) do
        c[k] = v
    end
    for k,v in pairs(b) do
        c[k] = v
    end
    return c
end

local function copy_table(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = copyTab(v)
        end
    end
    return tab
end

local function string2bool(v)
    if not v then
        return false
    end
    return tostring(v) == "1"
end

local function number2bool(v)
    if not v then
        return false
    end
    return tonumber(v) == 1
end

local function check_is_local_ip(ip)
    if type(ip) ~= "string" then return false end
    -- 内网默认为10.0.0.0/8
    i,j = string.find(ip, "^10%.")
    if i == nil and j == nil then
        return false
    end
    return true
end

local function table_is_empty(t)
    return next(t) == nil
end

local function split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

P.copy_table = copy_table
P.string2bool = string2bool
P.number2bool = number2bool
P.check_is_local_ip = check_is_local_ip
P.table_is_empty = table_is_empty
P.split = split

return P

