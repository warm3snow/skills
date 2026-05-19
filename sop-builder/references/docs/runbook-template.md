# 运维操作手册

## 健康检查
curl http://localhost:8080/health  # 预期：{"status":"ok"}

## 关键日志关键词
| 关键词 | 含义 | 处理方式 |
|--------|------|----------|
| FATAL | 服务崩溃 | 查看 panic 堆栈 |
| db connect failed | DB连接失败 | 检查配置和网络 |
| timeout | 下游超时 | 检查下游服务 |

## 常见问题排查
### 服务启动失败
1. ls config/config.yaml
2. telnet [db-host] [db-port]
3. tail -f logs/app.log

### 接口超时
1. 查慢查询日志
2. 检查下游服务健康状态
3. 查DB连接池使用情况

## 告警处理
| 告警名 | 触发条件 | 处理步骤 |
|--------|----------|----------|
| [告警名] | [条件] | [步骤] |
