package t::TestYs7;

use Cwd qw(cwd);

use Test::Nginx::Socket::Lua -Base;

my $pwd = cwd();

repeat_each(1);
log_level('debug');
no_long_string();
no_shuffle();

no_root_location();

worker_connections(128);


add_block_preprocessor(sub {

    my ($block) = @_;

    my $main_config = $block->main_config // <<_EOC_;

    working_directory   $pwd;
    error_log logs/worker-error.log debug;
_EOC_
    $block->set_value("main_config", $main_config);


    my $http_config = $block->http_config // '';
    my $init_by_lua_block = $block->init_by_lua_block // 'require "resty.ys7"';

    $http_config .= <<_EOC_;

    charset utf8;

    lua_package_path "$pwd/deps/share/lua/5.1/?.lua;$pwd/deps/share/lua/5.1/?/init.lua;$pwd/app/?.lua;$pwd/app/library/?.lua;$pwd/app/?/init.lua;$pwd/?.lua;/usr/local/lor/?.lua;/usr/local/lor/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;;;";
    lua_package_cpath "$pwd/deps/lib64/lua/5.1/?.so;$pwd/deps/lib/lua/5.1/?.so;$pwd/app/library/?.so;/usr/local/lor/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;;";


    lua_code_cache on;
    lua_shared_dict shm           10m;
    resolver 8.8.8.8 114.114.114.114 ipv6=off;
    init_by_lua_block {
        local config = ngx.shared.shm
        config:set("ls:config:test:app_key", 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        config:set("ls:config:test:secret",  'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
    }

_EOC_

    $block->set_value("http_config", $http_config);

    if (!defined $block->error_log) {
        $block->set_value("no_error_log", "[error]");
    }

    if (!defined $block->request) {
        $block->set_value("request", "GET /t");
    }
});

1;