# 短链服务

1. nginx + lua + redis   单进程模型（原因是序列号需要唯一）
1. 44bit整形表示的短链   10bit(串号) + 4bit(worker id)  + 30bit(timestamp)
1. 串号进程内自增长  key(时间)，value(串号)，单进程最大支持每秒2^10
1. worker id在lua配置文件中指定

## API文档

### 创建短链

* 请求方法
  * POST /short_url/v1/short_urls

* POST参数
  * longurl = "http://www.baidu.com"
* 返回
  * {"status":0,"tinyurl":"AbCDe","longurl":"http://www.baidu.com""err_msg":""}

### 还原短链

* 请求方法
  * GET /short_url/v1/short_urls?tinyurl=AbCDe
* 返回
  * {"status":0,"longurl":"http://www.baidu.com","tinyurl":"AbCDe"}
