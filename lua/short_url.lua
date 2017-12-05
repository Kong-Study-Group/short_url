-- ShortURL
local ngx = require "ngx"
ngx.header.content_type = "application/json;charset=UTF-8"
local cjson = require "cjson.safe"
local bit = require("bit")

local m_gw_utils = require "gw_utils"
local m_redis_api = require "redis_api"
local m_gw_feature = require "gw_feature"

local HTTP_NOT_ALLOWED = '{"status":405, "message":"Method Not allowed - ShortURL", "more info":"请求的HTTP method不支持，请检查API设置"}'


local function get_all_args()
    local uri_args = ngx.req.get_uri_args()

    ngx.req.read_body()
    local post_args, err = ngx.req.get_post_args()
    if not post_args then
        ngx.log(ngx.WARN, string.format("[REQ] [agent] ngx.req.get_post_args():%s", err))
        post_args = {}
    else
        ngx.log(ngx.DEBUG, string.format("[REQ] [agent] post_args:%s", cjson.encode(post_args)))
    end

    return m_gw_utils.merge_table(uri_args, post_args)
end

local function http_test(url)
    --TODO: 测试网址是否有效
    return true
end


ngx.update_time()
local request_st = ngx.now()

local args = get_all_args()
ngx.log(ngx.INFO, string.format("[short_url] [REQ] args:%s", cjson.encode(args)))

local rds, err = m_redis_api.open_redis()
if not rds then
    ngx.log(ngx.WARN, "[short_url] [m_redis_api:open_redis()] redis init failed. ", err)
    ngx.say(cjson.encode({status=500, message="redis:" .. err}))
    ngx.exit(ngx.HTTP_OK)
    return
end

method = ngx.req.get_method()
if method == "GET" then
    --还原短链
    if args.tinyurl == nil then
        ngx.say(cjson.encode({status=400, message="参数错误，[tinyurl:may not be empty]"}))
        ngx.exit(ngx.HTTP_OK)
        return
    end
    local longurl,err = rds:get(args.tinyurl)
    ngx.log(ngx.DEBUG, string.format("[short_url] [get] [longurl] %s", longurl))
    local status = 200
    if not longurl or type(longurl) == "userdata" then
        status = 404
    else
        err = "成功"
    end
    local ret = {status=status, tinyurl=args.tinyurl, longurl=longurl, message=err}
    ngx.say(cjson.encode(ret))
elseif method == "POST" then
    --创建短链
    if args.longurl == nil then
        ngx.say(cjson.encode({status=400, message="参数错误，[longurl:may not be empty]"}))
        ngx.exit(ngx.HTTP_OK)
        return
    end
    --查看是否已经创建
    local existed_tinyurl,err = rds:get(args.longurl)
    ngx.log(ngx.DEBUG, string.format("[short_url] [get] [existed_tinyurl] %s", existed_tinyurl))
    if existed_tinyurl and type(existed_tinyurl) ~= "userdata" then
        local ret = {status=200, tinyurl=existed_tinyurl, longurl=args.longurl, message="成功"}
        ngx.say(cjson.encode(ret))
        ngx.exit(ngx.HTTP_OK)
        return
    end

    ok,err = http_test(args.longurl)
    if not ok then
        ngx.say(cjson.encode({status=400, message="参数错误，[longurl:website an not access]"}))
        ngx.exit(ngx.HTTP_OK)
        return
    else
        local tinyurl = m_gw_feature.generator()
        ngx.log(ngx.DEBUG, string.format("[short_url] [post] [tinyurl] %s", tinyurl))
        if tinyurl == nil then
            ngx.log(ngx.WARN, "[short_url] tinyurl is nil")
            ngx.say(cjson.encode({status=429, message="请求太快，请重试"}))
            ngx.exit(ngx.HTTP_OK)
            return
        end

        --查询tinyurl是否已经存在
        local longurl,err = rds:get(tinyurl)
        if longurl and type(longurl) ~= "userdata" then
            ngx.log(ngx.WARN, "[short_url] tinyurl was existed")
            local ret = {status=500, tinyurl=tinyurl, longurl=args.longurl, message="tinyurl已经存在，请重试"}
            ngx.say(cjson.encode(ret))
            ngx.exit(ngx.HTTP_OK)
            return
        end

        local status = 200
        --设置tinyurl -> longurl
        local ok,err = rds:set(tinyurl, args.longurl)
        if not ok then
            status = 500
        else
            ok,err = rds:expire(tinyurl, 3600*24*365*2)
            if not ok then
                status = 500
            else
                err = "成功"
            end
        end
        --设置longurl -> tinyurl
        ok,err = rds:set(args.longurl, tinyurl)
        if not ok then
            status = 500
        else
            ok,err = rds:expire(args.longurl, 3600*24*365*2)
            if not ok then
                status = 500
            else
                err = "成功"
            end
        end
        local ret = {status=status, tinyurl=tinyurl, longurl=args.longurl, message=err}
        ngx.say(cjson.encode(ret))
    end
else
    ngx.log(ngx.WARN, "[short_url] [REQ] Method Not Allowed")
    ngx.print(HTTP_NOT_ALLOWED)
end

rds:close()

ngx.update_time()
local response_st = ngx.now()
ngx.log(ngx.NOTICE, string.format("[short_url] response time:%s", response_st-request_st))

ngx.exit(ngx.HTTP_OK)
