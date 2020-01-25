# dictation-ruby
英语单词听写-命令行 dictation

# requirement
- http proxy
- ruby
- 播放器 mplayer
- 单词数据库 sqlite

```
git config --global http.https://github.com.proxy http://127.0.0.1:10809
```
# TODO
- 选择单词范围
- 错误日志
- 今日听写数据统计，导出 JSON 或 Marshal
- 数据库增加字段，音标，美式发音url，
- 句子发音填空
- 错词本
    - 错误次数统计入库
- final drill
- spaced repetition 时间间隔 3, 5, 7, 15,  
- 中文解释（collins 5,4,3 星级 不需要）
- 听写模式
    - 随机听写
    - 顺序听写
    - 保留上次进度

- 修改为 Web 版本，用 JS 重写