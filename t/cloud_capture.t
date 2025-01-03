# vi:ft=

use lib '.';
use t::TestYs7;

repeat_each(1);
# plan tests => 3 * blocks();
plan tests => repeat_each() * (blocks() * 3);

# no_long_string();
#no_diff();
no_shuffle();
run_tests();



__DATA__


=== TEST 1:  云抓拍---参数的验证
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)
            local accessToken, err = y:get_token()

            -- 正常的抓拍(无参数：deviceSerial)
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                channelNo    = 8,
                                projectId    = "lh_wb_01",
                            })
            say("err: ", err)


            -- 正常的抓拍(无参数：channelNo)
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                projectId    = "lh_wb_01",
                            })
            say("err: ", err)


            -- 正常的抓拍(无参数：projectId)
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 8,
                            })
            say("err: ", err)


            -- 正常的抓拍(无参数：is_sync)
            local res, err = y:cloud_capture({
                                deviceSerial = "FH0221619",
                                channelNo    = 8,
                                projectId    = "lh_wb_01",
                            })
            say("err: ", err)
        }
    }

--- request
POST /t
--- response_body
err: 参数检验出错，错误：property "deviceSerial" is required
err: 参数检验出错，错误：property "channelNo" is required
err: 参数检验出错，错误：property "projectId" is required
err: 参数检验出错，错误：property "is_sync" is required
--- timeout: 5
--- no_error_log
[error]





=== TEST 2:  云抓拍--有文件 ID
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)
            ngx.sleep(2)

            -- 正常的抓拍(有文件 ID)
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                                fileId       = "2024123109453690234",
                            })
            say("rv: ", res.code, ",", "msg: ", res.msg)
        }
    }

--- request
POST /t
--- response_body
rv: 400,msg: 文件已经存在
--- timeout: 150
--- no_error_log
[error]







=== TEST 3:  云抓拍--无文件 ID
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)
            ngx.sleep(2)

            -- 正常的抓拍(无文件 ID)
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                            })
            say("err: ", err)
            say("rv: ", res.code, ",", "msg: ", res.msg)
            say("url: ", #res.data.urls > 0)
  
        }
    }

--- request
POST /t
--- response_body
err: nil
rv: 200,msg: 操作成功
url: true
--- timeout: 150
--- no_error_log
[error]




=== TEST 4:  云抓拍--频繁请求
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)

            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                            })
                            
            local res2, err2 = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                            })
            say("rv: ", res2.code, ",", "msg: ", res2.msg)
        }
    }

--- request
POST /t
--- response_body
rv: 403,msg: 请勿在五秒内连续调用抓拍接口
--- timeout: 150
--- no_error_log
[error]







=== TEST 5:  抽帧--无文件 ID--返回文件 url
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)
            ngx.sleep(2)
                            
            local res, err = y:cloud_capture({
                                is_sync      = true,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                                captureType  = 2
                            })
            say("rv: ", res.code, ",", "msg: ", res.msg)
            say("url: ", #res.data.urls > 0)
        }
    }

--- request
POST /t
--- response_body
rv: 200,msg: 操作成功
url: true
--- timeout: 150
--- no_error_log
[error]







=== TEST 6:  抽帧--无文件 ID--返回文件 ID
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)
            ngx.sleep(2)
                            
            local res, err = y:cloud_capture({
                                is_sync      = false,
                                deviceSerial = "FH0221619",
                                channelNo    = 9,
                                projectId    = "lh_wb_01",
                                captureType  = 2
                            })
            say("rv: ", res.code, ",", "msg: ", res.msg)
            say("files_ID: ", #res.data.fileid > 0)
        }
    }

--- request
POST /t
--- response_body
rv: 200,msg: 操作成功
files_ID: true
--- timeout: 150
--- no_error_log
[error]
















=== TEST 20:  获取文件下载/在线播放地址---参数的验证
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)

            -- 获取文件下载/在线播放地址(无参数：projectId)
            local res, err = y:cloudrecord_file({
                                   fileId    = "2024123009563690111"
                            })
            say("err: ", err)


            -- 获取文件下载/在线播放地址(无参数：fileId)
            local res, err = y:cloudrecord_file({
                                projectId    = "lh_wb_01",
                            })
            say("err: ", err)
        }
    }

--- request
POST /t
--- response_body
err: 参数检验出错，错误：property "projectId" is required
err: 参数检验出错，错误：property "fileId" is required
--- timeout: 5
--- no_error_log
[error]





=== TEST 21:  获取文件下载/在线播放地址---获取成功
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)


            -- --获取文件下载/在线播放地址(正常)
            local res, err = y:cloudrecord_file({
                                projectId    = "lh_wb_01",
                                   fileId    = "2024123009563690111"
                            })
            say("rv: ", res.code,",", "msg: ",res.msg)
            say("url: ", #res.data.urls > 0)
        }
    }

--- request
POST /t
--- response_body
rv: 200,msg: 操作成功
url: true
--- timeout: 5
--- no_error_log
[error]







=== TEST 22:  获取文件下载/在线播放地址---无资源
--- config

    location /t {
        content_by_lua_block {
            local say = ngx.say

            local ys7 = require("resty.ys7")
            local cjson = require("cjson")
            local y = ys7:new()

            local conf = {
                app_key = ngx.shared.shm:get("ls:config:test:app_key"),
                secret  = ngx.shared.shm:get("ls:config:test:secret"),
                url     = 'https://open.ys7.com',
                path    = '/api/lapp'
            }

            local ok, err = y:init_config(conf)


            --获取文件下载/在线播放地址(无资源)
            local res, err = y:cloudrecord_file({
                                projectId    = "lh_wb_01",
                                   fileId    = "aaaaaaaaaaaaa"
                            })
            say("rv: ", res.code,",", "msg: ",res.msg)
        }
    }

--- request
POST /t
--- response_body
rv: 404,msg: 资源不存在
--- timeout: 5
--- no_error_log
[error]
















