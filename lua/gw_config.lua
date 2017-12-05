--
-- config
--
local P = {}

setfenv(1, P)

-- Redis
P.redis = {}
P.redis.host = "127.0.0.1"
P.redis.port = "6379"


-- 短链服务序列号[0|1|2|3]
P.worker_id = 0

return P

