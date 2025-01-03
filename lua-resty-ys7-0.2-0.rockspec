rockspec_format = "3.0"
package = "lua-resty-ys7"
version = "0.2-0"
source = {
   url = "git+https://github.com/tom2nonames/lua-resty-ys7.git"
}
description = {
   detailed = "lua-resty-ys7 - openresty client SDK for YS7",
   homepage = "https://github.com/tom2nonames/lua-resty-ys7",
   license = "BSD License 2.0",
   labels = { "ys7", "OpenResty", "SDK", "Nginx" }
}
build = {
   type = "builtin",
   modules = {
      ["resty.ys7.schema" ]  = "lib/resty/ys7/schema.lua",
      ["resty.ys7.convert"]  = "lib/resty/ys7/convert.lua",
      ["resty.ys7.convert.cloudrecord"]  = "lib/resty/ys7/convert/cloudrecord.lua",
      ["resty.ys7"] = "lib/resty/ys7.lua"
   }
}