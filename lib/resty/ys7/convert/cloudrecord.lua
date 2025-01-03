local ngx_time = ngx.time
local ngx_encode_base64 = ngx.encode_base64
local ngx_encode_args   = ngx.encode_args
local ngx_re = require("ngx.re")

local isempty = require("table.isempty")
local isarray = require("table.isarray")
local t_insert= table.insert
local t_concat= table.concat
local t_sort  = table.sort

local sha256   = require("resty.sha256")
local r_string = require("resty.string")
local to_hex   = r_string.to_hex

local cjson    = require("cjson")


--[[
字段名          类型      描述
meta            Object    返回状态码及信息
    code        String    返回状态码
    message     Integer   返回信息
    moreInfo    String    返回其他内容
data            Object    文件下载信息
    expire      Integer   过期的时间
    urls        String    图片的地址



云抓拍接口的返回数据：
{
    "meta": {
        "code": 200,
        "message": "操作成功",
        "moreInfo": null
    }，
    "data": "http://xxx.xxx.com/xxx.jpg"
}

获取文件下载/在线播放地址的返回数据：
{
    "meta": {
        "code": 200,
        "message": "操作成功",
        "moreInfo": null
    },
    "data": {
        "expire": 1673610578230,
        "urls": [
            "http://openrecord.ys7.com/VIDEO_PREVIEW_FILES/c1cbc1d4e86d49a0981f54beea95280a/111/BD3957004-1/d0015b1769e845b0a478e9ec3fc3555c_20230104T164157Z_20230104T164257Z.mp4?Expires=1673610578&OSSAccessKeyId=LTAI4G6HFM3XPqa8rBjxHJRE&Signature=0hqjto3X6uHsdIXbJMISoyzl5bI%3D&response-content-type=video%2Fmp4&auth_key=1673610578-0-085cdeb2d6f84e4a969608f2cdcb3006-de415d6a85e3465c91aadeef22999fce"
        ]
    }
}
--]]

-- 匹配HTTP或HTTPS协议
local pattern = "^https?://"

local fields = {
        code = { src = {"meta"},
                        fn = function(val)
                                return val["code"]
                            end },
        msg  = { src = {"meta"},
                        fn = function(val)
                                return val["message"]
                            end },
        data = { src = {},
                        fn = function(val)
                                local res = {}
                                if type(val["data"]) == "string"  then                                    
                                    -- 使用正则表达式匹配
                                    local match   = string.match(val["data"], pattern)
                                    if match then
                                        -- URL 是以 HTTP 或 HTTPS 开头的
                                        res.urls      = {}
                                        t_insert(res.urls, val["data"])
                                    else
                                        -- URL 不是以 HTTP 或 HTTPS 开头的
                                        res.fileid = val["data"]
                                    end
                                    return res
                                end

                                if type(val["data"]) == "table"  then
                                    return val["data"]
                                end
                             end 
                },
}


local function get_value( item, field )

    if type(field) == 'string' then
        return field
    end

    local tmp = item
    -- 遍历取值拼接
    for i, k in pairs(field.src) do
            tmp = tmp[k]
        if not tmp then
        break;
        end
    end

    local fn = field["fn"]
    local ok
    if fn then
        ok, tmp = pcall(fn, tmp)
         if not ok then
            tmp = nil
         end
    end

    return tmp

end

local _M = {}


function _M:convert(data)
    if not data then
        return nil, "not found data."
    end

    local item = {}

    for k, v in pairs(fields) do
        item[k] = get_value( data, v)
    end

    return item
end

return _M
