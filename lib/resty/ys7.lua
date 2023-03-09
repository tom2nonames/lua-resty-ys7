local cjson  = require("cjson")
local http   = require("resty.http")

local schema = require("resty.ys7.schema")
local sfmt   = string.format

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 10)

_M._VERSION = '0.1'

local mt = { __index = _M }

local path_options = {
    ocr       = "/intelligence/ocr",
    get_token = "/token/get"
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
            local key = match[k].key
            local fn  = match[k].fn
            if fn then
                words[key] = fn(v)
            else
                words[key] = v
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

return _M
