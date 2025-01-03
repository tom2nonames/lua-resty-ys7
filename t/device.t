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

=== TEST 1:  设备信息--设备不存在
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

            -- 设备列表
            local res, err = y:device("capacity", {deviceSerial = "GY2262381"})
            say("rv: ", res.code,",", "msg: ",res.msg)
        }
    }

--- request
POST /t
--- response_body
rv: 20002,msg: 设备不存在
--- timeout: 5
--- no_error_log
[error]




=== TEST 2:  设备信息--不是定义的类型
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

            -- 设备列表
            local res, err = y:device("basic", {deviceSerial = "FH0221621"})
            say("err: ", err)
        }
    }

--- request
POST /t
--- response_body
err: 不能识别的操作类型。
--- timeout: 5
--- no_error_log
[error]





=== TEST 3:  设备信息--传的参数不对
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

            -- 设备列表---传的参数不对
            local res, err = y:device("info", {})
            say("err: ", err)

            -- 设备列表---传的参数不对
            local res, err = y:device("get_channel_info", {})
            say("err: ", err)

            -- 设备列表---传的参数不对
            local res, err = y:device("get_channels_status", {})
            say("err: ", err)

            -- 设备列表---传的参数不对
            local res, err = y:device("capacity", {})
            say("err: ", err)

            -- 设备列表---传的参数不对
            local res, err = y:device("camera_list", {})
            say("err: ", err)

            -- 设备列表---传的参数不对
            local res, err = y:device("basic_info", {})
            say("err: ", err)
        }
    }

--- request
POST /t
--- response_body
err: 参数：deviceSerial不能为空！
err: 参数：deviceSerial不能为空！
err: 参数：deviceSerial不能为空！
err: 参数：deviceSerial不能为空！
err: 参数：deviceSerial不能为空！
err: 参数：deviceSerial不能为空！
--- timeout: 5
--- no_error_log
[error]






=== TEST 11:  设备信息
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

            -- 设备列表
            local res,  err = y:device("list", {})
            say("rv: ", res.code,",", "msg: ",res.msg)

            local res1, err = y:device("info", {deviceSerial = "FH0221621"})
            say("rv: ", res1.code,",", "msg: ",res1.msg)

            local res2, err = y:device("get_channel_info", {deviceSerial = "FH0221621"})
            say("rv: ", res2.code,",", "msg: ",res2.msg)

            local res3, err = y:device("get_channels_status", {deviceSerial = "FH0221621"})
            say("rv: ", res3.result.code,",", "msg: ",res3.result.msg)

            local res4, err = y:device("capacity", {deviceSerial = "FH0221621"})
            say("rv: ", res4.code,",", "msg: ",res4.msg)

            local res5, err = y:device("camera_list", {deviceSerial = "FH0221621"})
            say("rv: ", res5.code,",", "msg: ",res5.msg)

            local res6, err = y:device("basic_info", {deviceSerial = "FH0221621"})
            say("rv: ", res6.result.code,",", "msg: ",res6.result.msg)


            local res7,  err = y:camera("list", {deviceSerial = "FH0221621"})
            say("rv: ", res7.code,",", "msg: ",res7.msg)

            local res8,  err = y:video("by_time", {deviceSerial = "FH0221621"})
            say("rv: ", res8.code,",", "msg: ",res8.msg)
        }
    }

--- request
POST /t
--- response_body
rv: 200,msg: Operation succeeded
rv: 200,msg: Operation succeeded
rv: 200,msg: 操作成功
rv: 200,msg: 操作成功
rv: 200,msg: 操作成功!
rv: 200,msg: 操作成功!
rv: 20020,msg: 设备在线，已经被自己添加
rv: 200,msg: 操作成功
rv: 200,msg: 操作成功!
--- timeout: 5
--- no_error_log
[error]

























