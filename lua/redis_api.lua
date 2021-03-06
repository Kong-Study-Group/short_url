--
-- Redis utils
--

local ngx = require "ngx"
local redis = require "resty.redis"
local m_gw_config = require "gw_config"

local P = {}

local function open_redis()
    local rds, err, ok
    rds, err = redis:new()
    if not rds then
       return rds, err
    end

    rds:set_timeout(1000)

    -- TODO 需要使用UNIX DOMAIN
    --local ok, err = rds:connect(m_gw_config.redis.unix)
    ok, err = rds:connect(m_gw_config.redis.host, m_gw_config.redis.port)
    if ok then
        return rds, err
    else
        return nil, err
    end
end

P.open_redis = open_redis

return P

