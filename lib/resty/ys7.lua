local cjson  = require("cjson")
local http   = require("resty.http")

local schema = require("resty.ys7.schema")
local convert_model  = require("resty.ys7.convert")

local sfmt   = string.format

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 10)

_M._VERSION = '0.2'

local mt = { __index = _M }

local path_options = {
    ocr         = "/intelligence/ocr",
    get_token   = "/token/get",
    device      = "/device",
    camera      = "/camera",
    video       = "/video",
}

function _M.new(self)
    local cwrap = {
        config = nil
    }
    return setmetatable(cwrap, mt)
end

function _M.init_config(self, config)
    local schema_def = schema.config_def
    local validator =  schema.validator

    local ok, err = validator(schema_def,config)

    if ok then
        self.config = config
    end

    return ok, err
end

function _M.get_token(self)

    local shm = ngx.shared.shm

    if shm then
        local expireTime, flags = shm:get("ls:ys7:expireTime")

        local nowtime = ngx.now()*1000
        if expireTime and expireTime > nowtime then
            local accessToken, flags = shm:set("ls:ys7:accessToken")
            return accessToken
        end
    end

    local url = sfmt( "%s%s%s",
                      self.config.url,
                      self.config.path,
                      path_options.get_token )

    local body = {
        appKey    = self.config.app_key,
        appSecret = self.config.secret
    }

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }

    local params = {
        method  = "POST",
        headers = headers,
        body    = ngx.encode_args(body),
        ssl_verify        = false,
        keepalive_timeout = 600,
        keepalive_pool    = 50
    }

    local httpc = http.new()
          httpc:set_timeout(10000)
    local res, err = httpc:request_uri(url, params)

    if not res or err then
        return nil, err
    end

    local status_code = res.status
    local body        = res.body
    local headers     = res.headers

    if status_code ~= 200 then
        return nil, "错误: ", body
    end

    local res = cjson.decode(body)

    if res.code == 200 then
        local ok, err, forcible = shm:set("ls:ys7:accessToken", res.data.accessToken)
        local ok, err, forcible = shm:set("ls:ys7:expireTime",  res.data.expireTime)
    end

    return res.data.accessToken
end

function _M.http_exec(self, url, method, headers, body)
    local params = {}
    if method == "GET" then
        params = {
            method  = method,
            headers = headers,
            query   = body,
            ssl_verify        = false,
            keepalive_timeout = 600,
            keepalive_pool    = 50
        }
    end
    if method == "POST" then
        params = {
            method  = method,
            headers = headers,
            body    = ngx.encode_args(body),
            ssl_verify        = false,
            keepalive_timeout = 600,
            keepalive_pool    = 50
        }
    end


    local httpc = http.new()
    httpc:set_timeout(10000)
    local res, err = httpc:request_uri(url, params)

    if not res or err then
        return nil, err
    end

    local status_code = res.status
    local body = res.body
    -- local headers = res.headers

    if status_code ~= 200 then
        return nil, body
    end

    local res = cjson.decode(body)

    return res, err
end

--[[
    {
    "msg": "操作成功",
    "code": "200",
    "data": {
        "words": {
            "姓名": "万科",
            "民族": "汉",
            "住址": "广东省深圳市宝安区福永金菊下路福侨花园5栋丽嘉阁201房",
            "公民身份号码": "422101197812220417",
            "性别": "男",
            "出生": "19781222"
        },
        "locations": null
    },
    "requestId": "bdedfbe7dc6d4baabfc32481426905bb"
    }

    {
        "msg": "操作成功",
        "code": "200",
        "data": {
            "words": {
                "有效起始日期": "20220201",
                "姓名": "赵红雷",
                "证号": "130533198308212019",
                "出生日期": "19830821",
                "住址": "河北省邢台市威县章台镇大章台村283号",
                "国籍": "中国/CHN",
                "初次领证日期": "20160201",
                "准驾车型": "C1",
                "有效期限": "2022-02-01",
                "性别": "男"
            }
        },
        "requestId": "7596e55ae69c49ecb2ccb1c4818f8c5d"
    }

    {
    "msg": "操作成功",
    "code": "200",
    "data": {
        "words": {
            "车辆识别代号": "LFNAFUKMXH1E36771",
            "住址": "江苏省苏州市昆山市千灯镇鹤峰路183号",
            "品牌型号": "解放牌CA5160CCYP62K1L4",
            "发证日期": "20220307",
            "车辆类型": "重型仓栅式货车",
            "所有人": "昆山市千灯镇雅宏木制品加工厂",
            "号牌号码": "苏ELF735",
            "发动机号码": "60401183",
            "使用性质": "营转非",
            "注册日期": "20180205"
        }
    },
    "requestId": "6d567dbe995a41fbbc5a8e1772bf9a8f"
}
    --]]

function _M.ocr(self, type, opts)
    local img_max_size      = 1024 * 1024 * 2
    local minimum_288       = {  288, 288 }
    local minimum_800_600   = {  800, 600 }
    local maximum_4096      = { 4096, 4096}
    local maximum_4096_2160 = { 4096, 2160}

    local ocr_type_t = {
        generic = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.generic_def,
            res_schema = schema.generic_res_data_def
        },
        bankCard = {
            size    = img_max_size,
            minimum = minimum_800_600,
            maximum = maximum_4096_2160,
            schema  = schema.bank_card_def,
            res_schema = schema.bank_card_res_data_def
        },
        idCard = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.id_card_def,
            res_schema = schema.id_card_res_data_def,
            match = schema.id_card_res_data_match
        },
        driverLicense = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.driver_license_def,
            res_schema = schema.driver_license_res_data_def,
            match = schema.driver_license_res_data_match
        },
        vehicleLicense = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.vehicle_license_def,
            res_schema = schema.vehicle_license_res_data_def,
            match = schema.vehicle_license_res_data_match
        },
        businessLicense = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.business_license_def
        },
        receipt = {
            size    = img_max_size,
            minimum = minimum_800_600,
            maximum = maximum_4096_2160,
            schema  = schema.receipt_def
        },
        licensePlate = {
            size    = img_max_size,
            minimum = minimum_288,
            maximum = maximum_4096,
            schema  = schema.license_plate_def,
            res_schema = schema.license_plate_res_data_def
        }
    }

    local accessToken = opts.accessToken or self:get_token()
    local dataType    = opts.dataType    or 1

    opts.accessToken = accessToken
    opts.dataType    = dataType


    local ocr_chk = ocr_type_t[type]
    if not ocr_chk then
        return nil, "不能识别的证件类型。"
    end

    local ok, err =  schema.validator(ocr_chk.schema, opts)

    if not ok then
        return nil, "参数检验出错，错误：" .. err
    end

    local url = sfmt( "%s%s%s/%s", self.config.url,
                      self.config.path, path_options.ocr, type )
    local body = ngx.encode_args(opts)
    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }

    local params = {
        method  = "POST",
        headers = headers,
        body    = body,
        ssl_verify        = false,
        keepalive_timeout = 600,
        keepalive_pool    = 50
    }


    local httpc = http.new()
    httpc:set_timeout(10000)
    local res, err = httpc:request_uri(url, params)

    if not res or err then
        return nil, err
    end

    local status_code = res.status
    local body = res.body
    local headers = res.headers

    if status_code ~= 200 then
        return nil, body
    end

    local res = cjson.decode(body)

    if  tonumber(res.code) ~= 200 then
        return nil, res.msg
    end

    local match = ocr_chk.match
    local data  = res.data
    if match then
        local words , locations = {} , {}
        for k,v in pairs(data.words) do
            if not match[k] then
                words[k] = v
            else
                local key = match[k].key
                local fn  = match[k].fn
                if fn then
                    words[key] = fn(v)
                else
                    words[key] = v
                end
            end
        end
        data.words = words

        if not data.locations or data.locations == ngx.null then
            return data
        end

        for k,v in pairs(data.locations) do
            local key = match[k].key
            locations[key] = v
        end
        data.locations = locations
    end

    return data
end


-- 获取设备信息
-- accessToken    授权过程获取的access_token
-- deviceSerial   设备序列号,存在英文字母的设备序列号，字母需为大写
-- channel        通道号,默认为1
function _M.device(self,  type, opts)
    local accessToken = opts.accessToken or self:get_token()
    if not accessToken then   
        return nil, "access_token不能为空！"
    end

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }


    local action_t = {
        list                = {  uri = "list",       method = "POST", params = { } },
        info                = {  uri = "info",       method = "POST", params = { "deviceSerial"} },
        get_channel_info    = {  uri = "status/get", method = "POST", params = { "deviceSerial"} } ,
        get_channels_status = {  path = "/api/v3/open",
                                 uri = "metadata/channel/status", 
                                                     method = "GET",  params = { "deviceSerial"} } ,
        capacity            = {  uri = "capacity",   method = "POST", params = { "deviceSerial"} } ,
        camera_list         = {  uri = "camera/list",method = "POST", params = { "deviceSerial"} } ,
        basic_info          = {  path = "/api/v3",
                                 uri = "searchDeviceInfo",
                                                     method = "POST", params = { "deviceSerial"} } ,
        protocol            = {  uri = "support/ezviz",
                                                     method = "POST", params = { "appKey", "model", "version" } } ,
    }

    local action = action_t[type]
    if not action then
        return nil, "不能识别的操作类型。"
    end
    local url_method = action.method
    if action and action.uri == "metadata/channel/status" then
        headers.accessToken = accessToken
        headers.deviceSerial = opts.deviceSerial
    end

    for k,v in pairs(action.params) do
        if not opts[v] then
            return nil, "参数："..v.."不能为空！"
        end
    end

    local body = opts 
    body.accessToken    = accessToken


    -- 调用的接口路径
    local url = sfmt( "%s%s%s/%s", self.config.url, (action.path or self.config.path),  path_options.device, action.uri )

    local res, err = self:http_exec(url, url_method, headers, body)
    return res, err

end

function _M.camera(self, type, opts)
    local accessToken = opts.accessToken or self:get_token()
    if not accessToken then   
        return nil, "access_token不能为空！"
    end

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }

    local action_t = {
        list                = {  uri = "list",       method = "POST", params = { } },
    }

    local action = action_t[type]
    local url_method = action.method
    if not action then
        return nil, "不能识别的操作类型。"
    end

    for k,v in pairs(action.params) do
        if not opts[v] then
            return nil, "参数："..v.."不能为空！"
        end
    end

    local body = opts 
    body.accessToken    = accessToken


    -- 调用的接口路径
    local url = sfmt( "%s%s%s/%s", self.config.url, (action.path or self.config.path),  path_options.camera, action.uri )

    local res, err = self:http_exec(url, url_method, headers, body)
    return res, err

end

function _M.video(self, type, opts) 
    local accessToken = opts.accessToken or self:get_token()
    if not accessToken then   
        return nil, "access_token不能为空！"
    end

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded"
    }

    local action_t = {
        by_time                = {  uri = "by/time",  method = "POST", params = { "deviceSerial" } },
    }

    local action = action_t[type]
    local url_method = action.method
    if not action then
        return nil, "不能识别的操作类型。"
    end

    for k,v in pairs(action.params) do
        if not opts[v] then
            return nil, "参数："..v.."不能为空！"
        end
    end

    local body = opts 
    body.accessToken    = accessToken


    -- 调用的接口路径
    local url = sfmt( "%s%s%s/%s", self.config.url, (action.path or self.config.path),  path_options.video, action.uri )

    local res, err = self:http_exec(url, url_method, headers, body)
    return res, err
end


-- 获取文件下载/在线播放地址                                        
-- projectId      (必须)     项目ID，项目的唯一标识，需输入已创建的项目ID                      
-- fileId         (必须)     文件ID，项目下文件的唯一标识，需输入已录制的文件ID	      
-- contentType    (非必须)   文件在线播放参数，填写对应的文件格式后可以在线播放文件，可填写的参数有：video/flv,image/png,video/mp4,image/jpg,image/jpeg，一般云录制视频文件为MP4格式，图片文件为jpeg格式   
-- expireSeconds  (非必须)   过期时间，单位秒,默认7200，【60-604800】
function _M.cloudrecord_file(self,  opts)
    local accessToken  = opts.accessToken or self:get_token()
    if not accessToken then   
        return nil, "access_token不能为空！"
    end

    -- 参数验证
    local ok, err =  schema.validator(schema.upload_cloudrecord_file, opts)
    if not ok then
        return nil, "参数检验出错，错误：" .. err
    end

    local headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["accessToken"]  = accessToken
    }
    local body = opts 
    local url = sfmt("%s%s", self.config.url, "/api/service/cloudrecord/file/official/download")


    --查看设备是否支持抓图
    local res, err = self:http_exec(url, "GET", headers, body)
    if res  then
        res["header"] = {}
        res["header"]["type"] = "cloudrecord"
        local rexs = convert_model.convert(self, res)
        return rexs, err
    end
    return res, err
end


-- 云抓拍接口
-- 使用图片抓拍接口前，需要先确认设备是否具备抓图能力集：support_capture=1则设备支持抓拍，若为0则不支持抓拍。可以通过设备序列号查询设备能力集，点击查看能力集查询接口。
-- 设备抓图能力有限，建议两次抓拍间隔在4秒以上
-- accessToken    (必须)     授权过程获取的access_token                                   
-- deviceSerial   (必须)     设备序列号                 
-- channelNo      (必须)     通道号                                          
-- projectId      (必须)     已创建的项目编号，填写后文件会存储至该项目中                      
-- fileId         (必须)     文件 ID，项目下文件的唯一标识。当captureType=1时需自定义文件 ID；当captureType=2时， 如果没传或传空，程序自动生成，如果传了则使用传入的值	      
-- captureType    (非必须)   选择采集图片的方式：1.下发设备抓拍指令 2. 使用抽帧获取设备图片，默认值为1      
-- validateCode   (非必须)   抽帧方式采集图片时，需要填写。输入视频解密密钥，且设备视频加密情况下必需填写该字段，否则无法获取到图片
-- devProto       (非必须)   抽帧方式采集图片时，需要填写。默认值为空值。1.值为空时：设备通过萤石协议接入，对应萤石和海康设备；2.值为gb28181:设备通过国标协议接入，对应国标设备；3.值为jt808:设备通过交通部标协议接入，对应部标设备
-- streamType     (非必须)   抽帧方式采集图片时，需要填写。码流类型，实时抽帧可以选择1：高清（主码流）2：标清（子码流）需注意若设备为变码率，或者视频清晰度不高的情况下，可能获取的图片不够高清，此时需要使用萤石工作室或4200客户端，修改视频为定码率或调整合适的视频清晰度
-- is_sync        (必须)     是否同步，false：异步，true：同步。默认值为false，异步，异步情况下，接口会立即返回，文件存储在云平台，异步情况下，文件存储在云平台，若文件存储失败，接口返回的文件ID为空，需要调用文件下载接口获取文件
-- wait_sec       (非必须)   等待时间，单位秒，默认3秒
function _M.cloud_capture(self,  opts)

    local body = opts 

    local accessToken  = opts.accessToken or self:get_token()
    if not accessToken then   
        return nil, "access_token不能为空！"
    end

    -- 参数验证
    local ok, err =  schema.validator(schema.cloud_capture_data, opts)
    if not ok then
        return nil, "参数检验出错，错误：" .. err
    end

    local capacity_body = {
        accessToken    = accessToken,
        deviceSerial   = opts.deviceSerial
    }
    --查看设备是否支持抓图
    local device_res, device_msg = self:device("capacity", capacity_body)
    local is_support_capture = false

    if device_res and device_res.code == "200" then
        is_support_capture = device_res.data.support_capture == "1"
    end
    -- 使用图片抓拍接口前，需要先确认设备是否具备抓图能力集：support_capture=1则设备支持抓拍，若为0则不支持抓拍。
    -- 可以通过设备序列号查询设备能力集
    if not is_support_capture then
        return nil, "设备不支持抓图！"
    end



   
    body.accessToken = accessToken
    body.captureType = body.captureType or 1
    local is_sync    = body.is_sync  or false
    local wait_sec   = body.wait_sec or 3
    
    if not body.fileId then
        -- 文件的默认格式 
        local seq_seed = string.reverse(string.sub(os.time(), -10))
        math.randomseed(tonumber(seq_seed))
        local file_id = os.date("%Y%m%d%H%M%S", os.time())..math.random(10000, 99999)
        body.fileId = file_id    
    end
    if body.captureType == 2 and body.validateCode and #body.validateCode == 0 then
        return nil, "抽帧方式采集图片时,视频解密密钥不能为空！"
    end 

    -- 调用抓拍的接口
    local headers_capt = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["accessToken"]  = accessToken,
    }

    local url_capt = sfmt("%s%s", self.config.url, "/api/open/cloud/v1/capture/save")

    --查看设备是否支持抓图
    local capture_res, capture_msg = self:http_exec(url_capt, "POST", headers_capt, body)
    if capture_res  then
        -- 有同步的标签并且是抽帧的情况
        if is_sync and body.captureType == 2 then
            local parame = {
                projectId     = body.projectId,
                fileId        = capture_res.data
            }
            -- 等待wait_sec秒(默认3秒.小于3秒获取不到数据)
            ngx.sleep(wait_sec)
            local file_res, file_msg = self:cloudrecord_file(parame)
            if file_res and file_res.code == 200 then
                return file_res, file_msg
            end
        end
        capture_res["header"] = {}
        capture_res["header"]["type"] = "cloudrecord"
        local rexs = convert_model.convert(self, capture_res)
        return rexs, capture_msg
    end

    return capture_res, capture_msg
end






return _M
