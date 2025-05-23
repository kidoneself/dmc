CREATE TABLE IF NOT EXISTS users
(
    id
    INTEGER
    PRIMARY
    KEY
    AUTOINCREMENT,
    username
    TEXT
    NOT
    NULL
    UNIQUE,
    password
    TEXT
    NOT
    NULL,
    level
    TEXT
    NOT
    NULL
    DEFAULT
    'free'
    CHECK (
    level
    IN
(
    'free',
    'pro'
)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

INSERT
OR IGNORE INTO users (username, password, level)
SELECT 'admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 'free'
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');
-- 镜像状态表
CREATE TABLE IF NOT EXISTS image_status
(
    id
    INTEGER
    PRIMARY
    KEY
    AUTOINCREMENT,
    name
    TEXT
    NOT
    NULL, -- 仓库名，如 jxxghp/moviepilot-v2
    tag
    TEXT
    NOT
    NULL, -- 镜像标签，如 latest、v1.0.0
    local_create_time
    TEXT, -- 本地镜像创建时间
    remote_create_time
    TEXT, -- 远程镜像创建时间
    need_update
    INTEGER
    DEFAULT
    0,    -- 0 表示 false，1 表示 true
    last_checked
    TEXT
    DEFAULT (
    datetime
(
    'now'
)), -- 检查时间，ISO8601格式
    created_at TEXT DEFAULT
(
    datetime
(
    'now'
)),
    updated_at TEXT DEFAULT
(
    datetime
(
    'now'
)),
    UNIQUE
(
    name,
    tag
)
    );
CREATE TABLE IF NOT EXISTS system_settings
(
    setting_key
    VARCHAR
(
    100
) PRIMARY KEY,
    setting_value TEXT
    );



CREATE TABLE IF NOT EXISTS application_templates
(
    id
    TEXT
    PRIMARY
    KEY,               -- 主键ID，应用模板的唯一标识
    name
    TEXT
    NOT
    NULL,              -- 应用名称，用于显示
    category
    TEXT,              -- 应用分类，用于分类展示
    version
    TEXT,              -- 应用版本号
    description
    TEXT,              -- 应用描述
    icon_url
    TEXT,              -- 应用图标URL
    template
    TEXT
    NOT
    NULL,              -- 应用模板数据，使用JSON格式存储完整的模板配置
    created_at
    TIMESTAMP
    DEFAULT
    CURRENT_TIMESTAMP, -- 创建时间
    updated_at
    TIMESTAMP
    DEFAULT
    CURRENT_TIMESTAMP, -- 更新时间
    sort_weight
    INTEGER
    DEFAULT
    0                  -- 排序权重
);

CREATE TABLE IF NOT EXISTS logs
(
    id
    INTEGER
    PRIMARY
    KEY
    AUTOINCREMENT,
    type
    TEXT
    NOT
    NULL,             -- 日志类型：OPERATION-操作日志，SYSTEM-系统日志
    level
    TEXT
    NOT
    NULL,             -- 日志级别：INFO, ERROR, WARN
    content
    TEXT
    NOT
    NULL,             -- 日志内容
    create_time
    DATETIME
    DEFAULT
    CURRENT_TIMESTAMP -- 创建时间
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_logs_type ON logs(type);
CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_create_time ON logs(create_time);

-- -- 插入初始应用模板数据
-- INSERT
-- OR IGNORE INTO application_templates (id, name, category, version, description, icon_url, template, created_at, updated_at, sort_weight)
-- VALUES ('2fe73d6b-6f82-4e19-b90b-1ed3b8b305ae', '家庭影院', '媒体', '1.0', '一套强大的媒体管理应用，包括MP，EMBY，QB，附带所有软件配置，一键式部署无需担心配置', 'https://raw.githubusercontent.com/jxxghp/MoviePilot-Frontend/main/public/logo.png', '{"services":[{"id":"moviepilot","name":"MoviePilot","template":{"name":"naspt-mpv2","image":"ccr.ccs.tencentyun.com/naspt/moviepilot-v2:latest","env":{"MOVIEPILOT_AUTO_UPDATE":"true","ICC2022_UID":"24730","SUPERUSER":"admin","API_TOKEN":"nasptnasptnasptnasptnaspt","AUTO_UPDATE_RESOURCE":"true","LEAVES_UID":"10971","LEAVES_PASSKEY":"e0405a9d0de9e3b112ef78ac3d9c7975","TZ":"Asia/Shanghai","AUTH_SITE":"icc2022,leaves","ICC2022_PASSKEY":"49c421073514d4d981a0cbc4174f4b23","PATH":"/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","LANG":"C.UTF-8","GPG_KEY":"7169605F62C751356D054A26A821E680E5FA6305","PYTHON_VERSION":"3.12.8","PYTHON_SHA256":"c909157bb25ec114e5869124cc2a9c4a4d4c1e957ca4ff553f1edc692101154e","HOME":"/moviepilot","CONFIG_DIR":"/config","TERM":"xterm","DISPLAY":":987","PUID":"0","PGID":"0","UMASK":"000","PORT":"3001","NGINX_PORT":"3000","PROXY_HOST":"http://naspt:naspt@10.10.10.2:7890"},"ports":{"3000/tcp":"{{MP_PORT}}"},"volumes":{"{{DOCKER_PATH}}/naspt-mpv2/config":"/config","{{MEDIA_PATH}}":"/media","{{DOCKER_PATH}}/naspt-mpv2/core":"/moviepilot/.cache/ms-playwright"},"restartPolicy":"always"}},{"id":"Qbittorrent","name":"Qbittorrent","template":{"name":"naspt-qb","image":"ccr.ccs.tencentyun.com/naspt/qbittorrent:4.6.4","env":{"UMASK":"022","TZ":"Asia/Shanghai","SavePatch":"/media/downloads","TempPatch":"/media/downloads","WEBUI_PORT":"9000","PUID":"0","PGID":"0","PATH":"/lsiopy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","HOME":"/config","TERM":"xterm","S6_CMD_WAIT_FOR_SERVICES_MAXTIME":"0","PS1=$(whoami)@$(hostname)":"$(pwd)\\$","S6_VERBOSITY":"1","S6_STAGE2_HOOK":"/docker-mods","VIRTUAL_ENV":"/lsiopy","LSIO_FIRST_PARTY":"true","XDG_CONFIG_HOME":"/config","XDG_DATA_HOME":"/config"},"ports":{"9000/tcp":"{{QB_PORT}}"},"volumes":{"{{MEDIA_PATH}}":"/media","{{DOCKER_PATH}}/naspt-qb/config":"/config"},"restartPolicy":"always"}},{"id":"Emby","name":"Emby","template":{"name":"naspt-emby","image":"ccr.ccs.tencentyun.com/naspt/embyserver:latest","env":{"UID":"0","GID":"0","UMASK":"022","PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin","LANG":"en_US.UTF-8","HOME":"/tmp","AMDGPU_IDS":"/share/libdrm/amdgpu.ids","FONTCONFIG_PATH":"/etc/fonts","LD_LIBRARY_PATH":"/lib:/system","LIBVA_DRIVERS_PATH":"/lib/dri","OCL_ICD_VENDORS":"/etc/OpenCL/vendors","PCI_IDS_PATH":"/share/hwdata/pci.ids","SSL_CERT_FILE":"/etc/ssl/certs/ca-certificates.crt","GIDLIST":"0","NVIDIA_VISIBLE_DEVICES":"all","NVIDIA_DRIVER_CAPABILITIES":"compute,video,utility","IGNORE_VAAPI_ENABLED_FLAG":"false","XDG_CACHE_HOME":"/config/cache"},"ports":{"8096/tcp":"{{EB_PORT}}"},"volumes":{"{{MEDIA_PATH}}":"/media","{{DOCKER_PATH}}/naspt-emby/config":"/config"},"restartPolicy":"always"}}],"parameters":[{"key":"DOCKER_PATH","name":"Docker配置路径","value":"/volume1/docker"},{"key":"MEDIA_PATH","name":"媒体文件路径","value":"/volume2/media"},{"key":"QB_PORT","name":"Qbittorrent端口","value":"9000"},{"key":"MP_PORT","name":"MoviePilot端口","value":"3000"},{"key":"EB_PORT","name":"Emby端口","value":"8096"}],"configs":[{"target":"{{DOCKER_PATH}}","urls":["https://docker-template.oss-cn-shanghai.aliyuncs.com/Downloads/naspt-mpv2.tgz","https://docker-template.oss-cn-shanghai.aliyuncs.com/Downloads/naspt-qb.tgz","https://docker-template.oss-cn-shanghai.aliyuncs.com/Downloads/naspt-emby.tgz"]}]}', '2025-05-04T13:57:45.651798', '2025-05-04T13:57:45.651881', 0);

-- INSERT
-- OR IGNORE INTO application_templates (id, name, category, version, description, icon_url, template, created_at, updated_at, sort_weight)
-- VALUES ('2b6f4520-975e-404d-8770-7b1d8c66ec29', '代理工具', '工具', '1.0', 'clash代理工具，提供强大的留学功能', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqJzLuADqLVH5nVeqZkZmQ1Pke3tmN_n32wQ&s', '{"services":[{"id":"clash","name":"clash","template":{"name":"naspt-clash","image":"ccr.ccs.tencentyun.com/naspt/clash-and-dashboard:latest","env":{"PUID":"0","PGID":"0","UMASK":"022","PATH":"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"},"ports":{"7890/tcp":"{{PROXY_PORT}}","8080/tcp":"{{CLASH_PORT}}"},"volumes":{"{{DOCKER_PATH}}/clash":"/root/.config/clash"},"restartPolicy":"always"}}],"parameters":[{"key":"DOCKER_PATH","name":"Docker配置路径","value":"/volume1/docker"},{"key":"CLASH_PORT","name":"WEB端口","value":"9999"},{"key":"PROXY_PORT","name":"代理端口","value":"7890"}],"configs":[{"target":"{{DOCKER_PATH}}","urls":["https://docker-template.oss-cn-shanghai.aliyuncs.com/Downloads/naspt-cl.tgz"]}]}', '2025-05-05T21:23:36.695338', '2025-05-05T21:23:36.695398', 0);

-- Web服务表
CREATE TABLE IF NOT EXISTS web_servers
(
    id
    TEXT
    PRIMARY
    KEY, -- UUID 主键
    name
    VARCHAR
(
    100
) NOT NULL, -- 服务器名称
    icon TEXT, -- 图标URL
    internal_url TEXT, -- 内网访问地址
    external_url TEXT, -- 外网访问地址
    description TEXT, -- 描述信息
    category TEXT DEFAULT '默认分类', -- 分类名称
    item_sort INTEGER DEFAULT 0, -- 应用排序
    created_at TEXT DEFAULT
(
    datetime
(
    'now'
)), -- 创建时间
    updated_at TEXT DEFAULT
(
    datetime
(
    'now'
)) -- 更新时间
    );
