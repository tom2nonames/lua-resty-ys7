Name
====

lua-resty-ys7 - Lua module for cloud snapshot

Table of Contents
=================

* [Name](#name)
* [Synopsis](#synopsis)
* [Functions](#functions)
* [Memo](#memo)

Synopsis
========
* 使用设备抓拍能力或者即时抽帧的方式采集图片，若设备是萤石/海康设备，且具有抓图能力集，则可以使用抓拍能力采集图片；若设备不具备抓拍能力（如国标设备等）则可以使用即时抽帧的方式采集图片
* 获取文件下载/在线播放地址接口


Functions
=========

* 云抓拍接口
```lua
local ys7   = require("resty.ys7")
local cjson = require("cjson")
local y     = ys7:new()

local conf  = {
    app_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    -- 替换为您的app_key
    secret  = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    -- 替换为您的secret
    url     = "https://open.ys7.com",
    path    = "/api/lapp"
}

local ok, err  = y:init_config(conf)

local res, err = y:cloud_capture({
                    is_sync      = false,
                    deviceSerial = "FH0221619",
                    channelNo    = 9,
                    projectId    = "lh_wb_01",
                    captureType  = 2
                })

print(cjson.encode(res))

-- 打印结果
-- {"code":200,"msg":"操作成功","data":{"fileid":"2025010311175476873"}}

```

* 获取文件下载/在线播放地址
```lua
local ys7   = require("resty.ys7")
local cjson = require("cjson")
local y     = ys7:new()

local conf  = {
    app_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    -- 替换为您的app_key
    secret  = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    -- 替换为您的secret
    url     = "https://open.ys7.com",
    path    = "/api/lapp"
}

local ok, err  = y:init_config(conf)

local res, err = y:cloudrecord_file({
                 projectId    = "lh_wb_01",
                    fileId    = "2024122411260168616"
                })

print(cjson.encode(res))

-- 打印结果(示例)
-- {"code":200,"msg":"操作成功","data":{"urls":["http://openrecord.ys7.com/VIDEO_FRAME_IMMEDIATE_FILES/75bc000ccdb54c3a947ba63642952fa7/lh_wb_01/FR0246821-9/2024122411260168616_1735010761.jpeg?Expires=1735889966&OSSAccessKeyId=LTAI4G6HFM3XPqa8rBjxHJRE&Signature=XYnvOtTWdM5N1kmikpDfDlsyHZg%3D&response-content-type=image%2Fjpg&auth_key=1735889966-0-e4376f6fca7e4c7bb25bb3bd3bf5ec96-8e0ba5804467c2b3d292b63da4f85a9d"],"expire":1735889966125}}

```

Memo
=========

#### 云抓拍接口注意事项
*    使用图片抓拍接口前，需要先确认设备是否具备抓图能力集：support_capture=1则设备支持抓拍，若为0则不支持抓拍。可以通过设备序列号查询设备能力集，
*    设备抓图能力有限，建议两次抓拍间隔在4秒以上

#### 单元测试
*    使用前把 t/TestYs7.pm 中的 app_key和secret替换成为自己的
*    使用 make test 命令进行单元测试






