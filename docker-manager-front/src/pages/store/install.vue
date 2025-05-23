<template>
  <div class="install-container">
    <t-card :bordered="false">
      <!-- 新手引导按钮 -->
      <div class="guide-button">
        <t-button @click="handleGuideClick">新手引导</t-button>
      </div>
      
      <!-- 应用信息 -->
      <div class="app-info">
        <div class="app-header">
          <h2 class="app-title">{{ appDetail?.name }}</h2>
          <p class="app-description">{{ appDetail?.description }}</p>
        </div>
      </div>

      <!-- 主要内容区域 -->
      <div class="main-content">
        <!-- 左侧参数配置 -->
        <div class="parameters-section">
          <div class="section-card">
            <h3 class="section-title">参数配置</h3>
            <t-alert theme="info" title="配置说明" class="config-alert">
              <template #message>
                <p>1. 当前显示的是默认参数配置，您可以根据需要修改</p>
                <p>2. 参数修改后请点击"校验参数"按钮进行验证</p>
                <p>3. 校验通过后即可开始安装</p>
              </template>
            </t-alert>

            <!-- 镜像信息 -->
            <div class="images-section">
              <h4 class="subsection-title">所需镜像</h4>
              <div class="images-list">
                <div v-for="service in appDetail?.services" :key="service.id" class="image-item">
                  <div class="image-info">
                    <span class="service-name">{{ service.name }}</span>
                    <t-tag theme="primary" variant="light" size="small">{{ service.template.image }}</t-tag>
                    <t-tag
                      :theme="imageCheckStatus[service.template.image] ? 'success' : 'warning'"
                      variant="light"
                      size="small"
                    >
                      {{ imageCheckStatus[service.template.image] ? '已存在' : '未存在' }}
                    </t-tag>
                    <template v-if="!imageCheckStatus[service.template.image]">
                      <t-button
                        v-if="!imagePullStates[service.template.image]?.status"
                        theme="primary"
                        size="small"
                        :disabled="isAnyImagePulling"
                        @click="handlePullImage(service.template.image)"
                      >
                        拉取
                      </t-button>
                      <div v-else class="pull-progress">
                        <t-progress
                          :percentage="imagePullStates[service.template.image]?.progress || 0"
                          :label="false"
                          size="small"
                        />
                        <span class="progress-text">{{ imagePullStates[service.template.image]?.progress || 0 }}%</span>
                      </div>
                    </template>
                  </div>
                </div>
              </div>
            </div>

            <t-form ref="form" :data="formData" :rules="rules" class="parameters-form">
              <div class="parameters-grid">
                <div v-for="param in appDetail?.parameters" :key="param.key" class="parameter-card">
                  <div class="parameter-header">
                    <span class="parameter-label">{{ param.name }}</span>
                    <t-tag theme="primary" variant="light" size="small">{{ param.key }}</t-tag>
                  </div>
                  <t-input v-model="formData[param.key]" :placeholder="param.value" class="parameter-input" />
                  <!-- 显示校验结果 -->
                  <div v-if="validationResults[`${param.key}`]" class="validation-result">
                    <t-tag
                      :theme="validationResults[`${param.key}`].valid ? 'success' : 'danger'"
                      variant="light"
                      size="small"
                    >
                      {{ validationResults[`${param.key}`].message }}
                    </t-tag>
                  </div>
                </div>
              </div>

              <!-- 操作按钮 -->
              <div class="action-buttons">
                <t-space size="large">
                  <t-button
                    theme="default"
                    size="large"
                    :loading="isValidating"
                    :disabled="isValidating"
                    @click="validateParams"
                  >
                    校验参数
                  </t-button>
                  <t-button
                    v-if="!isInstalling && !isInstallComplete"
                    theme="primary"
                    size="large"
                    :disabled="!isValidated"
                    @click="handleInstall"
                  >
                    开始安装
                  </t-button>
                  <t-button v-else-if="!showLogDialog" theme="primary" size="large" @click="reopenLogDialog">
                    {{ isInstallComplete ? '查看结果' : '查看日志' }}
                  </t-button>
                  <t-button
                    v-if="!isInstalling && !isInstallComplete"
                    theme="default"
                    size="large"
                    @click="handleCancel"
                  >
                    取消
                  </t-button>
                </t-space>
              </div>
            </t-form>
          </div>
        </div>
      </div>

      <!-- 校验结果 -->
      <div v-if="validationResult" class="validation-result">
        <t-alert :theme="validationResult.success ? 'success' : 'error'" :message="validationResult.message" />
      </div>

      <!-- 安装日志弹出框 -->
      <t-dialog
        v-model:visible="showLogDialog"
        :header="'安装日志'"
        :footer="isInstallComplete"
        :close-on-overlay-click="!isInstalling"
        :close-on-esc-keydown="!isInstalling"
        width="800px"
        class="install-log-dialog"
      >
        <div class="log-content" ref="logContentRef">
          <div v-for="(log, index) in installLogs" :key="index" class="log-item">
            <t-icon :name="getLogIcon(log.type)" :class="['log-icon', log.type]" />
            <span class="log-message">{{ log.message }}</span>
            <span class="log-time">{{ log.time }}</span>
          </div>
        </div>
        <template #footer>
          <t-space>
            <t-button theme="primary" @click="handleConfirm">确定</t-button>
          </t-space>
        </template>
      </t-dialog>

      <!-- 新手引导组件 -->
      <t-guide
        v-model="currentGuideStep"
        :steps="guideSteps"
        @change="handleGuideChange"
        @prev-step-click="handleGuidePrevStep"
        @next-step-click="handleGuideNextStep"
        @finish="handleGuideFinish"
        @skip="handleGuideSkip"
      />
    </t-card>
  </div>
</template>

<script lang="ts" setup>
import { nextTick, onMounted, onUnmounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { MessagePlugin } from 'tdesign-vue-next';
import { getAppDetail } from '@/api/appStoreApi';
import type { AppStoreAppDetail } from '@/api/model/appStoreModel';
import {
  checkImages,
  pullImage,
  removeInstallLogHandler,
  startInstall,
  validateParams as validateParamsApi,
  addInstallLogHandler
} from '@/api/websocket/container';

const route = useRoute();
const router = useRouter();

// 应用详情
const appDetail = ref<AppStoreAppDetail>();
const formData = ref<Record<string, any>>({});
const isValidated = ref(false);
const validationResult = ref<{ success: boolean; message: string } | null>(null);

// 安装状态
const isInstalling = ref(false);
const isValidating = ref(false);

// 安装日志
const installLogs = ref<
  Array<{
    type: 'info' | 'success' | 'warning' | 'error';
    message: string;
    time: string;
  }>
>([]);

// 表单校验规则
const rules = {
  // 动态生成校验规则
};

// 镜像检查状态
const imageCheckStatus = ref<Record<string, boolean>>({});
const isCheckingImages = ref(false);

// 镜像拉取状态
interface ImagePullState {
  status: boolean; // 是否正在拉取
  progress: number; // 拉取进度
  taskId: string | null; // 任务ID
}

const imagePullStates = ref<Record<string, ImagePullState>>({});
const isAnyImagePulling = ref(false); // 是否有镜像正在拉取

// 初始化镜像状态
const initImageState = (imageName: string) => {
  if (!imagePullStates.value[imageName]) {
    imagePullStates.value[imageName] = {
      status: false,
      progress: 0,
      taskId: null,
    };
  }
};

// 获取应用详情
const fetchAppDetail = async () => {
  try {
    const id = route.params.id as string;
    const res = await getAppDetail(id);

    if (res.code === 0) {
      appDetail.value = res.data;
      // 初始化表单数据
      if (appDetail.value?.parameters) {
        appDetail.value.parameters.forEach((param) => {
          formData.value[param.key] = param.value;
        });
      }
    } else {
      MessagePlugin.error(res.message || '获取应用详情失败');
    }
  } catch (error) {
    console.error('获取应用详情失败:', error);
    MessagePlugin.error('获取应用详情失败');
  }
};

// 参数校验状态
const validationResults = ref<Record<string, { valid: boolean; message: string }>>({});

// 验证参数
const validateParams = async () => {
  isValidating.value = true;
  try {
    const result = await validateParamsApi(formData.value);
    if (result.success) {
      MessagePlugin.success('参数验证通过');
      isValidated.value = true;
    } else {
      MessagePlugin.error(result.message || '参数验证失败');
    }
  } catch (error) {
    MessagePlugin.error('参数验证失败');
  } finally {
    isValidating.value = false;
  }
};

// 修改日志添加逻辑
const addLog = (type: 'info' | 'success' | 'warning' | 'error', message: string) => {
  console.log('添加日志:', { type, message });
  installLogs.value.push({
    type,
    message,
    time: new Date().toLocaleTimeString(),
  });
  scrollToBottom();
};

// 开始安装
const handleInstall = async () => {
  console.log('开始安装流程');
  isInstalling.value = true;
  showLogDialog.value = true;

  installLogs.value = [
    {
      type: 'info',
      message: '开始安装...',
      time: new Date().toLocaleTimeString(),
    },
  ];

  try {
    console.log('发送安装请求');
    const result = await startInstall({
      appId: route.params.id as string,
      params: formData.value,
    });
    if (result.success) {
      addLog('success', '安装成功');
      handleInstallComplete();
    } else {
      addLog('error', result.message || '安装失败');
      isInstalling.value = false;
    }
  } catch (error) {
    console.error('安装过程出错:', error);
    addLog('error', '安装失败');
    isInstalling.value = false;
  }
};

// 检查镜像
const checkAppImages = async () => {
  if (!appDetail.value?.services) return;

  isCheckingImages.value = true;
  imageCheckStatus.value = {};

  // 初始化所有镜像的状态
  appDetail.value.services.forEach((service) => {
    const imageName = service.template.image;
    imageCheckStatus.value[imageName] = false;
    initImageState(imageName);
  });

  try {
    // 收集所有需要检查的镜像
    const imagesToCheck = appDetail.value.services.map((service) => {
      const imageName = service.template.image;
      const [name, tag = 'latest'] = imageName.split(':');
      return { name, tag };
    });

    const result = await checkImages(imagesToCheck);
    if (result.success && result.data) {
      result.data.forEach((result: any) => {
        const fullImageName = `${result.name}:${result.tag}`;
        imageCheckStatus.value[fullImageName] = result.exists;
      });
    }
  } catch (error) {
    console.error('检查镜像失败:', error);
    addLog('error', `检查镜像失败: ${error}`);
  } finally {
    isCheckingImages.value = false;
  }
};

// 拉取镜像
const handlePullImage = async (image: string) => {
  try {
    await pullImage(
      { imageName: image },
      {
        onProgress: ({ progress }) => {
          imagePullStates.value[image] = {
            status: true,
            progress,
            taskId: null,
          };
        },
        onComplete: () => {
          imagePullStates.value[image] = {
            status: false,
            progress: 100,
            taskId: null,
          };
          imageCheckStatus.value[image] = true;
        },
        onError: (error) => {
          console.error('拉取镜像失败:', error);
          addLog('error', `拉取镜像失败: ${error}`);
        },
      },
    );
  } catch (error) {
    console.error('拉取镜像失败:', error);
    addLog('error', `拉取镜像失败: ${error}`);
  }
};

// 添加弹出框控制
const showLogDialog = ref(false);

// 添加日志容器引用
const logContentRef = ref<HTMLElement | null>(null);

// 滚动到底部的函数
const scrollToBottom = async () => {
  await nextTick();
  if (logContentRef.value) {
    logContentRef.value.scrollTop = logContentRef.value.scrollHeight;
  }
};

// 添加安装完成状态
const isInstallComplete = ref(false);

// 重新打开日志框
const reopenLogDialog = () => {
  showLogDialog.value = true;
};

// 处理安装完成
const handleInstallComplete = () => {
  isInstallComplete.value = true;
  isInstalling.value = false;
};

// 处理确定按钮点击
const handleConfirm = () => {
  router.push('/docker/containers');
};

// 取消安装
const handleCancel = () => {
  // 只返回上一页，不进行其他操作
  router.back();
};

// 获取日志图标
const getLogIcon = (type: string) => {
  const icons: Record<string, string> = {
    info: 'info-circle',
    success: 'check-circle',
    warning: 'warning',
    error: 'error-circle',
  };
  return icons[type] || 'info-circle';
};

// 新手引导相关
const currentGuideStep = ref(-1);
const guideSteps = [
  {
    element: '.app-info',
    title: '应用信息',
    description: '这里显示应用的基本信息，包括名称和描述',
    placement: 'bottom' as const,
  },
  {
    element: '.images-section',
    title: '镜像管理',
    description: '在这里可以查看和管理应用所需的 Docker 镜像',
    placement: 'bottom' as const,
  },
  {
    element: '.parameters-form',
    title: '参数配置',
    description: '在这里配置应用的运行参数，配置完成后需要点击"校验参数"按钮进行验证',
    placement: 'bottom' as const,
  },
  {
    element: '.action-buttons',
    title: '操作按钮',
    description: '在这里可以执行参数校验、开始安装等操作',
    placement: 'top' as const,
  },
];

const handleGuideClick = () => {
  currentGuideStep.value = 0;
};

const handleGuideChange = (current: number, { e, total }: any) => {
  console.log('引导步骤变更:', current, e, total);
  // 添加自动滚动功能
  nextTick(() => {
    const currentStep = guideSteps[current];
    if (currentStep) {
      const element = document.querySelector(currentStep.element);
      if (element) {
        element.scrollIntoView({
          behavior: 'smooth',
          block: 'center'
        });
        
        // 等待滚动动画完成后再更新遮罩层位置
        setTimeout(() => {
          // 强制更新当前步骤，触发遮罩层重新计算位置
          const temp = currentGuideStep.value;
          currentGuideStep.value = -1;
          nextTick(() => {
            currentGuideStep.value = temp;
          });
        }, 300); // 300ms 是滚动动画的持续时间
      }
    }
  });
};

const handleGuidePrevStep = ({ e, prev, current, total }: any) => {
  console.log('上一步:', e, prev, current, total);
};

const handleGuideNextStep = ({ e, next, current, total }: any) => {
  console.log('下一步:', e, next, current, total);
};

const handleGuideFinish = ({ e, current, total }: any) => {
  console.log('引导完成:', e, current, total);
  currentGuideStep.value = -1;
};

const handleGuideSkip = ({ e, current, total }: any) => {
  console.log('跳过引导:', e, current, total);
  currentGuideStep.value = -1;
};

// 在组件挂载时检查镜像
onMounted(() => {
  console.log('组件挂载');
  // 注册安装日志处理器
  addInstallLogHandler((message) => {
    console.log('收到安装日志:', message);
    if (message.type === 'INSTALL_LOG') {
      console.log('处理 INSTALL_LOG 消息:', message.data);
      const { level, message: logMessage } = message.data;
      console.log('解析后的日志:', { level, logMessage });
      addLog(level as 'info' | 'success' | 'warning' | 'error', logMessage);
    } else if (message.type === 'ERROR') {
      console.log('处理 ERROR 消息:', message.data);
      addLog('error', message.data);
    }
  });
  
  fetchAppDetail().then(() => {
    checkAppImages();
  });
});

// 在组件卸载时清理
onUnmounted(() => {
  console.log('组件卸载');
  // 移除安装日志处理器
  removeInstallLogHandler();
});
</script>

<style scoped>
.install-container {
  padding: 24px;
  height: 100%;
  width: 100%;
  background-color: var(--td-bg-color-page);
  display: flex;
  flex-direction: column;
}

.install-container :deep(.t-card) {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.install-container :deep(.t-card__body) {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 24px;
  overflow-y: auto;
}

.app-info {
  border-bottom: 1px solid var(--td-component-stroke);
  padding-bottom: 16px;
}

.app-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.app-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0;
}

.app-description {
  color: var(--td-text-color-secondary);
  margin: 0;
  flex: 1;
}

.main-content {
  display: flex;
  gap: 24px;
  min-height: 0;
}

.parameters-section {
  flex: 1;
  min-width: 0;
}

.section-card {
  background-color: var(--td-bg-color-container);
  border-radius: 8px;
  padding: 16px;
  box-shadow: var(--td-shadow-1);
  height: 100%;
  display: flex;
  flex-direction: column;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 16px;
}

.parameters-form {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.parameters-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 24px;
}

.parameter-card {
  background-color: var(--td-bg-color-secondarycontainer);
  border-radius: 6px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  position: relative;
}

.parameter-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.parameter-label {
  font-weight: 500;
  color: var(--td-text-color-primary);
  font-size: 14px;
}

.parameter-input {
  width: 100%;
}

.parameter-input :deep(.t-input) {
  background-color: var(--td-bg-color-container);
  height: 32px;
}

.parameter-input :deep(.t-input__inner) {
  font-size: 13px;
}

.action-buttons {
  display: flex;
  justify-content: center;
  margin-top: 24px;
  padding-top: 24px;
  border-top: 1px solid var(--td-component-stroke);
}

.action-buttons :deep(.t-button) {
  min-width: 120px;
  height: 40px;
  font-size: 14px;
  border-radius: 4px;
}

.action-buttons :deep(.t-space) {
  gap: 16px;
}

.validation-result {
  margin-top: 4px;
  font-size: 12px;
}

.install-log-dialog :deep(.t-dialog__body) {
  padding: 0;
}

.install-log-dialog :deep(.t-dialog__header) {
  padding: 16px 24px;
  border-bottom: 1px solid var(--td-component-stroke);
}

.log-content {
  max-height: 500px;
  overflow-y: auto;
  padding: 16px;
  background-color: var(--td-bg-color-secondarycontainer);
  font-family: monospace;
}

.log-item {
  display: flex;
  align-items: center;
  padding: 4px 0;
  font-size: 13px;
  line-height: 1.5;
}

.log-icon {
  margin-right: 8px;
  font-size: 16px;
}

.log-icon.info {
  color: var(--td-brand-color);
}

.log-icon.success {
  color: var(--td-success-color);
}

.log-icon.warning {
  color: var(--td-warning-color);
}

.log-icon.error {
  color: var(--td-error-color);
}

.log-message {
  flex: 1;
  white-space: pre-wrap;
  word-break: break-all;
}

.log-time {
  color: var(--td-text-color-secondary);
  font-size: 12px;
  margin-left: 16px;
}

/* 自定义滚动条样式 */
.log-content::-webkit-scrollbar {
  width: 6px;
}

.log-content::-webkit-scrollbar-thumb {
  background-color: var(--td-text-color-disabled);
  border-radius: 3px;
}

.log-content::-webkit-scrollbar-track {
  background-color: transparent;
}

/* 响应式调整 */
@media screen and (max-width: 768px) {
  .main-content {
    flex-direction: column;
  }

  .parameters-form {
    padding: 16px;
  }

  .app-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}

.config-alert {
  margin-bottom: 16px;
}

.config-alert :deep(.t-alert__message) {
  font-size: 13px;
  line-height: 1.6;
}

.config-alert :deep(.t-alert__message p) {
  margin: 4px 0;
}

.images-section {
  margin-bottom: 24px;
  padding: 16px;
  background-color: var(--td-bg-color-secondarycontainer);
  border-radius: 6px;
}

.subsection-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--td-text-color-primary);
  margin: 0 0 12px;
}

.images-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.image-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background-color: var(--td-bg-color-container);
  border-radius: 4px;
}

.image-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.service-name {
  font-weight: 500;
  color: var(--td-text-color-primary);
}

.t-tag {
  margin-left: 8px;
}

.t-button {
  margin-left: 8px;
}

.pull-progress {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: 8px;
  width: 120px;
}

.progress-text {
  font-size: 12px;
  color: var(--td-text-color-secondary);
}

.guide-button {
  position: absolute;
  top: 24px;
  right: 24px;
  z-index: 100;
}
</style>
