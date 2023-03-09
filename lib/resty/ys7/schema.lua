
local jsonschema = require("jsonschema")
local t_clone    = require("table.clone")

local sfmt = string.format
local ssub = string.sub
local _M = { version = 0.1 }


local function validator( schema, data)
        --校验数据的完整性
        local validator = jsonschema.generate_validator(schema)
        local ok, err = validator(data)

        return ok, err
end

_M.validator = validator

--配置数据结构定义
local config_def = {
    type = "object",
    properties = {
        app_key = { type = "string"},
        secret  = { type = "string"},
        url     = { type = "string", format = "uri"},
        path    = { type = "string", format = "uri-reference" }
    },
    required = {
        "app_key", "secret" ,"url", "path"
    }
}

-- 常用数据格式定义

-- 访问密钥
local access_token_def = { type = "string" }

--数据类型
local data_type_def = {
    type = "number",
    minimum = 0 ,
    maximum = 1
}

--图片Base64数据格式
local image_base64_def = {
    description = "图片Base64数据格式",
    type = "string",
    maxLenght = 1024 * 1024 *2,
    pattern = [[^data:image/(?:gif|png|jpeg|bmp|webp)(?:;charset=utf-8)?;base64,(?:[A-Za-z0-9+/]*={0,2}$)]]
}

--Base64数据格式
local base64_def = {
    description = "Base64数据格式",
    type = "string",
    --format = "base64"
    maxLenght = 1024 * 1024 *2,
    pattern = [[^[A-Za-z0-9+/]*={0,2}$]]
    --[[[^-A-Za-z0-9+/=]|=[^=]|={3,}$]]
    --simple ^[A-Za-z0-9+/]*={0,2}$
    --       ^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$
}

--驾行证类型
local driver_license_type_def = {
    description = "驾行证类型",
    type = "string",
    menu = {
        "A1","A2","A3",
        "B1","B2",
        "C1","C2","C3","C4","C5",
        "D","E","F","M","N","P" }
}

--性别
local gender_def = {
    description = "性别",
    type = "string" ,
    emnu = {"男", "女"}
}

--日期 2022-12-22
local date_def = {
    description = "日期 YYYY-MM-DD",
    type = "string",
    format = "date"
}

--日期 20221222
local date2_def = {
    description = "日期 YYYYMMDD",
    type = "string",
    pattern = [[^\d{4}[0-1]{1}[0-9]{1}[0-3]{1}[0-9]{1}$]]
}

--身份证号码
local id_card_fmt_def = {
    description = "身份证号码",
    type = "string",
    pattern = [[^[1-9]\d{5}(18|19|([23]\d))\d{2}((0[1-9])|(10|11|12))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$]]
}


local plate_number_def = {
    description = "车牌号规则",
    type = "string",
    pattern = [[([京津沪渝冀豫云辽⿊湘皖鲁新苏浙赣鄂桂⽢晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}(([0-9]{5}[DF])|([DF]([A-HJ-NP-Z0-9])[0-9]{4})))|([京津沪渝冀豫云辽⿊湘皖鲁新苏浙赣鄂桂⽢晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}[A-HJ-NP-Z0-9]{4}[A-HJ-NP-Z0-9挂学警港澳]{1})]],
    maxLenght = 10,
    minLenght = 8,
}

local pass_number_def = {
    description = "行驶证规则",
    type = "string",
    pattern = [[\d{12}$]],
    maxLenght = 12,
    minLenght = 12,
}

local engine_no_def = {
    description = "引擎号规则",
    type = "string",
    pattern = [[^[0-9A-Za-z]{1,20}$]],
    maxLenght = 20,
    minLenght = 1,
}

local engine_number_def = {
    description = "车架号规则",
    type = "string",
    pattern = [[^[A-HJ-NPR-Z\d]{17}$]],
    maxLenght = 17
}

local words_array_def = {
    description = "识别语句数组",
    type = "array",
    minItmes = 1,
    uniqueItems = true,
    items = {
        type = "string"
    }
}

local locations_def = {
    description = "识别语句定位",
    type = "object",
    properties = {
        x      = { type = "number" },
        y      = { type = "number" },
        widht  = { type = "number" },
        height = { type = "number" }
    }
}

local locations_array_def = {
    description = "识别语句定位数组",
    type = "array",
    minItmes = 1,
    uniqueItems = true,
    items = locations_def
}

local response_data = {
    type = "object",
    properties = {
        code = { type = "string" },
        msg  = { type = "string" },
        requesitId = {
            type = "string"
        },
        data = {
            type = "object",
        },

    },
    required = { "code", "msg", "data", "requestId" }
}

_M.response_data_def = response_data

local response_data2 = {
    type = "object",
    properties = {
        code = { type = "string" },
        msg  = { type = "string" },
        requesitId = {
            type = "string"
        },
        data = {
            type = "object",
            properties = {
                words = {
                    type = "object"
                },
                locations = {
                    type = "object",
                }
            },
            required = { "words" }
        }
    },
    required = { "code", "msg", "requestId" }
}

_M.response_data2_def = response_data2

--文字识别
local generic = {
    description = "通用文字识别",
    type = "object",
    properties = {
        accessToken = access_token_def,
        dataType = data_type_def,
        image = base64_def,
        operation = {
            type = "string",
            emnu = { "rect" }
        }
    },
    required = {
        "accessToken", "dataType", "image"
    }
}

local generic_res_data = {
    description = "通用文字识别回复数据",
    type = "object",
    properties = {
        words = words_array_def,
        locations = locations_array_def
    },
    required = { "words" }
}

local generic_res_data_def = t_clone(response_data)
generic_res_data_def.properties.data = generic_res_data

_M.generic_def = generic
_M.generic_res_data_def = generic_res_data_def


local bank_card = {
    description = "银行卡识别",
    type = "object",
    properties = {
        accessToken = access_token_def,
        dataType = data_type_def,
        image = base64_def
    },
    required = {
        "accessToken", "dataType", "image"
    }
}

local bank_card_res_data = {
    description = "银行卡识别回复数据",
    type = "object",
    properties = {
        name   = { type = "string" },
        number = { type = "string" },
        type   = { type = "integer", menu = { 0,1,2} }
    },
    required = { "name", "number", "type"}
}


local bank_card_res_data_def = t_clone(response_data)
generic_res_data_def.properties.data = bank_card_res_data

_M.bank_card_def = bank_card
_M.bank_card_res_data_def = bank_card_res_data


local id_card = {
    description = "身份证识别",
    type = "object",
    properties = {
        accessToken = access_token_def,
        dataType = data_type_def,
        image = base64_def,
        front = { type = "boolean" },
        operation = {
            type = "string",
            emnu = { "rect" }
        }
    },
    required = {
        "accessToken", "dataType", "image", "front"
    }
}

local id_card_res_data = {
    description = "身份证识别回复数据",
    type = "object",
    properties = {
        ["姓名"] = { type = "string" },
        ["民族"] = { type = "string" },
        ["住址"] = { type = "string" },
        ["公民身份号码"] = id_card_fmt_def,
        ["出生"] = { type = "string" },
        ["性别"] = gender_def
    },
    required = {
        "姓名", "民族", "住址", "公民身份号码", "出生", "性别"
    }
}
local function convert(str)
    return sfmt("%s-%s-%s", ssub(str,1,4), ssub(str,5,6), ssub(str,7,8) )
end

local id_card_match_t = {
    ["姓名"]         = { key = "name" },
    ["民族"]         = { key = "ethnicity" },
    ["住址"]         = { key = "address"},
    ["公民身份号码"] = { key = "id_no" },
    ["出生"]         = { key = "date_of_birth", fn = convert },
    ["性别"]         = { key = "gender"}
}

local id_card_res_data_def = t_clone(response_data2)
id_card_res_data_def.properties.data.properties.words = id_card_res_data
local locations = {}
for k, v in pairs(id_card_res_data.properties) do
    locations[k] = locations_def
end
id_card_res_data_def.properties.data.properties.locations = {
    type = "object",
    properties = locations
}

_M.id_card_def = id_card
_M.id_card_res_data_def = id_card_res_data_def
_M.id_card_res_data_match = id_card_match_t



local driver_license  = bank_card
local driver_license_res_data  = {
    description = "驾驶证识别回复数据",
    type = "object",
    properties = {
        ["有效起始日期"] = date2_def,
        ["姓名"]         = { type = "string" },
        ["证号"]         = id_card_fmt_def,
        ["出生日期"]     = date2_def,
        ["住址"]         = { type = "string" },
        ["国籍"]         = { type = "string" },
        ["初次领证日期"] = date2_def,
        ["准驾车型"]     = driver_license_type_def,
        ["有效期限"]     = date_def,
        ["性别"]         = gender_def
    },
    required = {
        "有效起始日期", "姓名", "证号", "出生日期",
        "住址", "国籍", "初次领证日期", "准驾车型",
        "有效期限",  "性别" }
}

local driver_license_match_t  = {
    ["有效起始日期"] = { key = "valid_from" , fn = convert},
    ["姓名"]         = { key = "name"},
    ["证号"]         = { key = "id_no"},
    ["出生日期"]     = { key = "date_of_birth", fn = convert},
    ["住址"]         = { key = "address"},
    ["国籍"]         = { key = "nationality"},
    ["初次领证日期"] = { key = "date_of_frist_issue", fn= convert},
    ["准驾车型"]     = { key = "type"},
    ["有效期限"]     = { key = "valid_for"},
    ["性别"]         = { key = "gander"}
}

local driver_license_res_data_def = t_clone(response_data2)
driver_license_res_data_def.properties.data.properties.words = driver_license_res_data
--location

_M.driver_license_def  = driver_license
_M.driver_license_res_data_def = driver_license_res_data_def
_M.driver_license_res_data_match = driver_license_match_t


local vehicle_license = bank_card
local vehicle_license_res_data = {
    description = "行驶证识别回复数据",
    type = "object",
    properties = {
        ["车辆识别代号"] = engine_number_def,
        ["住址"]         = { type = "string" },
        ["品牌型号"]     = { type = "string" },
        ["发证日期"]     = date2_def,
        ["车辆类型"]     = { type = "string" },
        ["所有人"]       = { type = "string" },
        ["使用性质"]     = { type = "string" },
        ["发动机号码"]   = engine_no_def,
        ["号牌号码"]     = plate_number_def,
        ["注册日期"]     = date2_def
    },
    required = { "车辆识别代号", "住址", "品牌型号", "发证日期",
                 "车辆类型", "所有人", "使用性质", "发动机号码",
                 "号牌号码", "注册日期" }
}

local vehicle_license_match_t = {
    ["车辆识别代号"] = { key = "vin"},
    ["住址"]         = { key = "address"},
    ["品牌型号"]     = { key = "model"},
    ["发证日期"]     = { key = "issue_date", fn = convert},
    ["车辆类型"]     = { key = "register_date"},
    ["所有人"]       = { key = "owner"},
    ["使用性质"]     = { key = "use_character"},
    ["发动机号码"]   = { key = "engine_no"},
    ["号牌号码"]     = { key = "plate_number"},
    ["注册日期"]     = { key = "register_date", fn = convert},
}

local vehicle_license_res_data_def = t_clone(response_data2)
vehicle_license_res_data_def.properties.data.properties.words = vehicle_license_res_data
--location

_M.vehicle_license_def  = vehicle_license
_M.vehicle_license_res_data_def = vehicle_license_res_data_def
_M.vehicle_license_res_data_match = vehicle_license_match_t


--营业执照识别
local business_license = generic
_M.business_license_def = business_license


--通用票据识别
local receipt = generic
_M.receipt_def = receipt


local license_plate = {
    description = "车牌识别",
    type = "object",
    properties = {
        accessToken = access_token_def,
        dataType = data_type_def,
        image = base64_def,
        front = {
            anyOf = {
                { type = "boolean" },
                { type = "string" , menu = {"true", "false"} }
            }
        },
        scene = {
            type = "string",
            emnu = { "lpr" , "general" }
        }
    },
    required = {
        "accessToken", "dataType", "image"
    }
}

local license_plate_res_data = {
    description = "车牌识别回复数据",
    type = "object",
    properties = {
        number = plate_number_def,
        words = {
            type = "object",
            properties = {
                number = plate_number_def,
                color  = {
                    type = "string",
                    menu = { "blue", "green", "yellow" }
                },
                confidence = {
                    type = "array",
                    items = {
                        type = "number" },
                    minItems = 7
                },
                location = locations_array_def
            },
            required = {
                "number", "color", "confidence", "location"
            }
        }
    },
    required = { "number", "words" }
}

local license_plate_res_data_def = t_clone(response_data)
license_plate_res_data_def.properties.data = license_plate_res_data

_M.license_plate_res_data_def = license_plate_res_data_def
_M.license_plate_def = license_plate

_M.validator = validator

return _M