package com.dsm.websocket.message;

/**
 * WebSocket 消息类型
 */
public enum MessageType {
    /**
     * 心跳消息
     */
    HEARTBEAT,

    /**
     * 测试通知
     */
    TEST_NOTIFY,

    /**
     * 测试通知响应
     */
    TEST_NOTIFY_RESPONSE,

    /**
     * 检查安装所需的镜像
     */
    INSTALL_CHECK_IMAGES,

    /**
     * 验证安装参数
     */
    INSTALL_VALIDATE,

    /**
     * 验证安装参数结果
     */
    INSTALL_VALIDATE_RESULT,

    /**
     * 开始安装
     */
    INSTALL_START,

    /**
     * 安装日志
     */
    INSTALL_LOG,

    /**
     * 安装结果
     */
    INSTALL_START_RESULT,

    /**
     * 拉取镜像
     */
    PULL_IMAGE,

    /**
     * 拉取开始
     */
    PULL_START,

    /**
     * 拉取进度
     */
    PULL_PROGRESS,

    /**
     * 拉取完成
     */
    PULL_COMPLETE,

    /**
     * 取消拉取
     */
    CANCEL_PULL,

    /**
     * 容器列表
     */
    CONTAINER_LIST,

    /**
     * 容器详情
     */
    CONTAINER_DETAIL,

    /**
     * 容器启动
     */
    CONTAINER_START,

    /**
     * 容器停止
     */
    CONTAINER_STOP,

    /**
     * 容器重启
     */
    CONTAINER_RESTART,

    /**
     * 容器删除
     */
    CONTAINER_DELETE,

    /**
     * 容器更新
     */
    CONTAINER_UPDATE,

    /**
     * 容器创建
     */
    CONTAINER_CREATE,

    /**
     * 容器日志
     */
    CONTAINER_LOGS,

    /**
     * 容器资源使用情况
     */
    CONTAINER_STATS,

    /**
     * 容器状态变更
     */
    CONTAINER_STATE_CHANGE,

    /**
     * 错误消息
     */
    ERROR,

    /**
     * 操作结果
     */
    OPERATION_RESULT,

    /**
     * 网络列表
     */
    NETWORK_LIST,

    /**
     * 镜像列表
     */
    IMAGE_LIST,

    /**
     * 镜像详情
     */
    IMAGE_DETAIL,

    /**
     * 镜像删除
     */
    IMAGE_DELETE,

    /**
     * 镜像更新
     */
    IMAGE_UPDATE,

    /**
     * 镜像批量更新
     */
    IMAGE_BATCH_UPDATE,

    /**
     * 取消镜像拉取
     */
    IMAGE_CANCEL_PULL,

    /**
     * 检查镜像更新
     */
    IMAGE_CHECK_UPDATES,

    /**
     * 导入模板
     */
    IMPORT_TEMPLATE,

    /**
     * 导入模板结果
     */
    IMPORT_TEMPLATE_RESULT,

    /**
     * 删除模板
     */
    DELETE_TEMPLATE,

    /**
     * 删除模板结果
     */
    DELETE_TEMPLATE_RESULT,

    /**
     * 容器JSON配置
     */
    CONTAINER_JSON_CONFIG,

    /**
     * 容器JSON配置响应
     */
    CONTAINER_JSON_CONFIG_RESPONSE
} 