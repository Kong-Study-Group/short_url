--
-- 短链随机码生成器
--

local bit = require("bit")
local math = require("math")
local m_gw_config = require "gw_config"


local P = {}

local function tocast(n, base_num)
    local base_dict = {
        [0] = "0","1","2","3","4","5","6","7","8","9",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
    }

    if n == 0 then
        return "0"
    end
    if base_num == 0 then
        return nil
    end

    local temp = ""
    while n ~= 0 do
        m =  n % base_num
        temp = base_dict[m] .. temp
        n = math.floor(n / base_num)
    end
    return temp
end


--每秒计数器
shared_cache_serial = {}

local function generator()
    local t = bit.band(os.time(), 0x3FFFFFFF)
    local work_id = m_gw_config.worker_id

    for k,v in pairs(shared_cache_serial) do
        if t > (tonumber(k, 10) + 1) then
            shared_cache_serial[k] = nil
        end
    end

    if shared_cache_serial[tostring(t)] == nil then
        math.randomseed(t)
        rand = math.ceil(math.random()*1022) + 1
        shared_cache_serial[tostring(t)] = {start=rand, cur=rand}
        ngx.log(ngx.INFO, string.format("[short_url] [generator] serial_number is restart"))
    end

    local serial_number = shared_cache_serial[tostring(t)].cur
    serial_number = (serial_number + 1 ) % 2^10
    if serial_number == 0 then
        serial_number = 1
    end

    ngx.log(ngx.DEBUG, string.format("[short_url] [generator] serial_number:%s", serial_number))

    if serial_number == shared_cache_serial[tostring(t)].start then
        ngx.log(ngx.INFO, string.format("[short_url] [generator] serial_number is loop, serial_number:%s, timestamp:%s",
            serial_number, t+2^30))
        return nil
    end

    local longbit = serial_number * 2^34 + work_id * 2^30 + t
    local rand_str = tocast(longbit, 62)

    shared_cache_serial[tostring(t)].cur = serial_number

    return rand_str
end

P.tocast = tocast
P.generator = generator



return P

--[[
print("Test -----")
print(tocast(9999, 32) == "9of")
print(tocast(9999, 25) == "foo")
print(tocast(9999, 19) == "18d5")
print(tocast(9999, 16) == "270f")
print(tocast(9999, 8) == "23417")
print(tocast(9999, 0) == nil)

print(tocast(0, 0) == "0")

print(tocast(62^0, 62) == "1")
print(tocast(62^1, 62) == "10")
print(tocast(62^2, 62) == "100")
print(tocast(62^3, 62) == "1000")
print(tocast(62^4, 62) == "10000")
print(tocast(62^5, 62) == "100000")
print(tocast(62^6, 62) == "1000000")
print(tocast(62^7, 62) == "10000000")
print(tocast(62^8, 62) == "100000000")

print("End -----")
]]
