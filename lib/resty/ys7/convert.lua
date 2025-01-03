local cjson  = require("cjson")
local msg_t = {
    ["cloudrecord"]         = "resty.ys7.convert.cloudrecord",
}


local _M = {}

function _M:convert(data)
    local msg_mod = msg_t[data.header.type]
    if not msg_mod then
        return nil, "not match msg type."
    end
    local msg = require(msg_mod)

    return msg:convert(data)
end

return _M
