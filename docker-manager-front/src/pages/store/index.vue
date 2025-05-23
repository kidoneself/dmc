<template>
  <div class="store-container">
    <div class="store-wrapper">
      <h1 class="store-title">应用商店</h1>
      <!-- 应用列表 -->
      <div class="app-list">
        <t-row :gutter="[12, 12]">
          <t-col v-for="app in apps" :key="app.id" :xs="12" :sm="8" :md="5" :lg="4" :xl="4">
            <div class="app-card" @click="handleCardClick(app)">
              <div class="app-icon-container">
                <img :src="app.iconUrl" class="app-icon" :alt="app.name" />
              </div>
              <div class="app-content">
                <div class="app-header">
                  <h3 class="app-title">{{ app.name }}</h3>
                  <span class="app-category">{{ getCategoryName(app.category) }}</span>
                </div>
                <p class="app-description">{{ app.description }}</p>
                <div class="app-footer">
                  <t-button theme="primary" size="small" @click.stop="handleInstall(app)">
                    安装
                  </t-button>
                  <t-popconfirm
                    content="确认删除该应用吗？此操作不可恢复"
                    :confirm-btn="{ theme: 'danger' }"
                    @confirm="handleDelete(app)"
                  >
                    <t-button theme="danger" size="small" @click.stop>删除</t-button>
                  </t-popconfirm>
                </div>
              </div>
            </div>
          </t-col>
        </t-row>
      </div>

      <!-- 分页和操作栏 -->
      <div class="pagination-container">
        <t-button theme="primary" @click="handleImportTemplate">
          <template #icon><t-icon name="upload" /></template>
          导入模板
        </t-button>
        <t-pagination
          v-model="current"
          :total="total"
          :page-size="pageSize"
          @change="handlePageChange"
          :loading="loading"
        />
      </div>
    </div>

    <!-- 导入模板对话框 -->
    <t-dialog
      v-model:visible="showImportDialog"
      header="导入模板"
      :footer="false"
      width="800px"
      class="import-dialog"
    >
      <div class="import-content">
        <div class="import-tabs">
          <t-tabs v-model="importTab">
            <t-tab-panel value="base64" label="从Base64导入">
              <div class="base64-input-area">
                <t-textarea
                  v-model="base64Content"
                  placeholder="请输入Base64编码的JSON内容"
                  :status="base64InputStatus"
                  :tips="base64InputTips"
                  :autosize="{ minRows: 3, maxRows: 6 }"
                />
                <div class="base64-actions">
                  <t-button theme="primary" @click="handleBase64Import" :loading="isBase64Importing">
                    解析
                  </t-button>
                </div>
              </div>
            </t-tab-panel>
            <t-tab-panel value="url" label="从URL导入">
              <div class="url-input-area">
                <t-input
                  v-model="importUrl"
                  placeholder="请输入JSON文件的URL地址"
                  :status="urlInputStatus"
                  :tips="urlInputTips"
                >
                  <template #suffix>
                    <t-button theme="primary" size="small" @click="handleUrlImport" :loading="isUrlImporting">
                      解析
                    </t-button>
                  </template>
                </t-input>
              </div>
            </t-tab-panel>
            <t-tab-panel value="file" label="从文件导入">
              <div class="upload-area" @click="triggerFileInput" @drop.prevent="handleFileDrop" @dragover.prevent>
                <input
                  ref="fileInput"
                  type="file"
                  accept=".json,.yaml,.yml"
                  class="file-input"
                  @change="handleFileChange"
                />
                <div class="upload-placeholder">
                  <t-icon name="upload" size="48" />
                  <p>点击或拖拽文件到此处</p>
                  <p class="upload-tip">支持 .json、.yaml、.yml 格式</p>
                </div>
              </div>
            </t-tab-panel>
          </t-tabs>
        </div>

        <!-- 文件预览 -->
        <div v-if="previewContent" class="preview-section">
          <h3 class="preview-title">文件预览</h3>
          <div class="preview-content">
            <div ref="editorContainer" class="json-editor"></div>
          </div>
          <div class="preview-actions">
            <t-button theme="default" @click="clearPreview">取消</t-button>
            <t-button theme="primary" :loading="isImporting" @click="handleImport">确认导入</t-button>
          </div>
        </div>
      </div>
    </t-dialog>

 
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { MessagePlugin } from 'tdesign-vue-next'
import { getAppList } from '@/api/appStoreApi'
import type { AppStoreApp } from '@/api/model/appStoreModel'
import { importTemplate, deleteTemplate } from '@/api/websocket/container'
import * as monaco from 'monaco-editor'
import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'
import jsonWorker from 'monaco-editor/esm/vs/language/json/json.worker?worker'

// 配置 Monaco Editor workers
self.MonacoEnvironment = {
  getWorker(_, label) {
    if (label === 'json') {
      return new jsonWorker()
    }
    return new editorWorker()
  }
}

const router = useRouter()

// 分页
const current = ref(1)
const pageSize = ref(12)
const total = ref(0)
const loading = ref(false)

// 应用列表数据
const apps = ref<AppStoreApp[]>([])

// 导入相关状态
const showImportDialog = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)
const previewContent = ref<string>('')
const isImporting = ref(false)
const currentFile = ref<File | null>(null)
const importTab = ref('base64')
const importUrl = ref('')
const urlInputStatus = ref<'default' | 'success' | 'warning' | 'error'>('default')
const urlInputTips = ref('')
const isUrlImporting = ref(false)
const base64Content = ref('')
const base64InputStatus = ref<'default' | 'success' | 'warning' | 'error'>('default')
const base64InputTips = ref('')
const isBase64Importing = ref(false)

const editorContainer = ref<HTMLElement | null>(null)
let editor: monaco.editor.IStandaloneCodeEditor | null = null

// 初始化编辑器
const initEditor = () => {
  if (!editorContainer.value) return

  editor = monaco.editor.create(editorContainer.value, {
    value: previewContent.value,
    language: 'json',
    theme: 'vs-dark',
    automaticLayout: true,
    minimap: {
      enabled: false
    },
    scrollBeyondLastLine: false,
    formatOnPaste: true,
    formatOnType: true,
    tabSize: 2,
    wordWrap: 'on'
  })

  // 添加格式化快捷键
  editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS, () => {
    editor?.getAction('editor.action.formatDocument')?.run()
  })
}

// 更新编辑器内容
const updateEditorContent = () => {
  if (editor) {
    editor.setValue(previewContent.value)
  }
}

// 获取编辑器内容
const getEditorContent = () => {
  if (editor) {
    return editor.getValue()
  }
  return previewContent.value
}

// 处理删除按钮点击
const handleDelete = async (app: AppStoreApp) => {
  try {
    const result = await deleteTemplate(app.id)
    if (result.success) {
      MessagePlugin.success('删除成功')
      fetchAppList() // 刷新列表
    } else {
      MessagePlugin.error(result.message || '删除失败')
    }
  } catch (error) {
    MessagePlugin.error('删除失败')
  }
}

// 获取应用列表
const fetchAppList = async () => {
  try {
    loading.value = true
    const res = await getAppList({
      page: current.value,
      size: pageSize.value
    })
    

    if (res.code === 0) {
      apps.value = res.data.records
      total.value = res.data.total
    } else {
      console.error('接口返回错误:', res.message)
      MessagePlugin.error(res.message || '获取应用列表失败')
    }
  } catch (error) {
    console.error('请求异常:', error)
    MessagePlugin.error('获取应用列表失败')
  } finally {
    loading.value = false
  }
}

// 事件处理
const handlePageChange = (pageInfo: { current: number }) => {
  current.value = pageInfo.current
  fetchAppList()
}

const handleCardClick = (app: AppStoreApp) => {
  router.push(`/store/install/${app.id}`);
}

// 获取分类名称
const getCategoryName = (category: string) => {
  const categoryMap: Record<string, string> = {
    media: '媒体服务',
    download: '下载工具',
    dev: '开发工具',
    database: '数据库',
  }
  return categoryMap[category] || category
}

// 安装应用
const handleInstall = (app: AppStoreApp) => {
  router.push(`/store/install/${app.id}`);
}

// 处理导入模板按钮点击
const handleImportTemplate = () => {
  showImportDialog.value = true;
};

// 处理文件选择
const handleFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement;
  const file = target.files?.[0];
  if (!file) return;

  // 检查文件大小（限制为1MB）
  if (file.size > 1024 * 1024) {
    MessagePlugin.error('文件大小不能超过1MB');
    return;
  }

  const reader = new FileReader();
  reader.onload = (event) => {
    try {
      const content = event.target?.result;
      previewContent.value = content as string;
      currentFile.value = file;
    } catch (error) {
      MessagePlugin.error('文件读取失败：' + (error as Error).message);
    }
  };
  reader.onerror = () => {
    MessagePlugin.error('文件读取失败');
  };
  reader.readAsText(file);
};

// 处理文件拖放
const handleFileDrop = (e: DragEvent) => {
  e.preventDefault();
  const file = e.dataTransfer?.files[0];
  if (file) {
    handleFile(file);
  }
};

// 处理文件
const handleFile = async (file: File) => {
  // 检查文件大小（限制为1MB）
  if (file.size > 1024 * 1024) {
    MessagePlugin.error('文件大小不能超过1MB');
    return;
  }

  try {
    const content = await file.text();
    previewContent.value = content;
    currentFile.value = file;
  } catch (error) {
    console.error('读取文件失败:', error);
    MessagePlugin.error('读取文件失败');
  }
};

// 清除预览
const clearPreview = () => {
  previewContent.value = ''
  currentFile.value = null
  base64Content.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  if (editor) {
    editor.dispose()
    editor = null
  }
}

// 处理导入
const handleImport = async () => {
  if (!previewContent.value) return

  isImporting.value = true
  
  try {
    // 获取编辑器中的内容
    const content = getEditorContent()
    
    // 验证JSON格式
    try {
      JSON.parse(content)
    } catch (e) {
      MessagePlugin.error('JSON格式错误，请检查并修正后再导入')
      isImporting.value = false
      return
    }
    
    // 根据不同的导入方式设置文件名
    let fileName = 'template.json'
    if (currentFile.value) {
      fileName = currentFile.value.name
    } else if (importUrl.value) {
      fileName = importUrl.value.split('/').pop() || 'template.json'
    } else if (base64Content.value) {
      fileName = 'base64_template.json'
    }

    const result = await importTemplate(content, fileName)
    if (result.success) {
      MessagePlugin.success('模板导入成功')
      showImportDialog.value = false
      clearPreview()
      fetchAppList()
    } else {
      MessagePlugin.error(result.message || '模板导入失败')
    }
  } catch (error) {
    MessagePlugin.error('导入失败')
  } finally {
    isImporting.value = false
  }
}

// 触发文件选择
const triggerFileInput = () => {
  fileInput.value?.click();
};

// 生成任务ID
const generateTaskId = () => {
  return Math.random().toString(36).substring(2, 15);
};

// 处理URL导入
const handleUrlImport = async () => {
  if (!importUrl.value) {
    urlInputStatus.value = 'error'
    urlInputTips.value = '请输入URL地址'
    return
  }

  try {
    isUrlImporting.value = true
    urlInputStatus.value = 'default'
    urlInputTips.value = '正在获取文件...'

    const response = await fetch(importUrl.value)
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const content = await response.text()
    try {
      // 验证JSON格式
      JSON.parse(content)
      previewContent.value = content
      urlInputStatus.value = 'success'
      urlInputTips.value = '文件获取成功'
    } catch (e) {
      urlInputStatus.value = 'error'
      urlInputTips.value = '无效的JSON格式'
      throw e
    }
  } catch (error) {
    urlInputStatus.value = 'error'
    urlInputTips.value = error instanceof Error ? error.message : '获取文件失败'
  } finally {
    isUrlImporting.value = false
  }
}

// 添加base64导入处理函数
const handleBase64Import = async () => {
  if (!base64Content.value) {
    base64InputStatus.value = 'error'
    base64InputTips.value = '请输入Base64内容'
    return
  }

  try {
    isBase64Importing.value = true
    base64InputStatus.value = 'default'
    base64InputTips.value = '正在解析...'

    // 尝试解码base64，处理中文编码
    const decodedContent = decodeURIComponent(escape(atob(base64Content.value)))
    try {
      // 验证JSON格式
      JSON.parse(decodedContent)
      previewContent.value = decodedContent
      base64InputStatus.value = 'success'
      base64InputTips.value = '解析成功'
    } catch (e) {
      base64InputStatus.value = 'error'
      base64InputTips.value = '无效的JSON格式'
      throw e
    }
  } catch (error) {
    base64InputStatus.value = 'error'
    base64InputTips.value = error instanceof Error ? error.message : '解析失败'
  } finally {
    isBase64Importing.value = false
  }
}

// 监听 previewContent 变化
watch(previewContent, (newValue) => {
  if (newValue && !editor) {
    nextTick(() => {
      initEditor()
    })
  } else if (newValue && editor) {
    updateEditorContent()
  }
})

// 组件卸载时清理编辑器
onBeforeUnmount(() => {
  if (editor) {
    editor.dispose()
    editor = null
  }
})

// 初始化
onMounted(() => {
  console.log('组件挂载，开始获取数据')
  fetchAppList()
})
</script>

<style scoped>
.store-container {
  padding: 24px;
  height: 100%;
  background-color: var(--td-bg-color-page);
}

.store-wrapper {
  height: 100%;
  background-color: var(--td-bg-color-container);
  border-radius: 12px;
  box-shadow: var(--td-shadow-1);
  padding: 24px;
  display: flex;
  flex-direction: column;
}

.store-title {
  font-size: 20px;
  font-weight: 600;
  color: var(--td-text-color-primary);
  margin: 0 0 24px;
}

.app-list {
  flex: 1;
  margin-bottom: 24px;
  min-height: 0;
  overflow-y: auto;
  padding: 4px;
}

.app-card {
  cursor: pointer;
  transition: all 0.3s ease;
  border-radius: 8px;
  overflow: hidden;
  background: var(--td-bg-color-container);
  border: 1px solid var(--td-component-stroke);
  display: flex;
  flex-direction: row;
  position: relative;
  z-index: 1;
}

.app-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--td-shadow-3);
  border-color: var(--td-brand-color);
}

.app-icon-container {
  position: relative;
  width: 100px;
  height: 100px;
  flex-shrink: 0;
  overflow: hidden;
}

.app-icon {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.app-card:hover .app-icon {
  transform: scale(1.05);
}

.app-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 8px;
  min-width: 0;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.app-title {
  font-size: 14px;
  font-weight: 600;
  color: var(--td-text-color-primary);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.app-category {
  font-size: 11px;
  color: var(--td-text-color-secondary);
  background: var(--td-bg-color-secondarycontainer);
  padding: 1px 4px;
  border-radius: 3px;
  flex-shrink: 0;
  margin-left: 8px;
}

.app-description {
  font-size: 12px;
  color: var(--td-text-color-secondary);
  margin: 4px 0 8px;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 34px;
}

.app-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: auto;
}

.app-footer :deep(.t-button) {
  width: 60px;
  height: 24px;
  font-size: 12px;
}

.pagination-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 24px;
  border-top: 1px solid var(--td-component-stroke);
  margin-top: auto;
  flex-shrink: 0;
}

.pagination-container .t-button {
  display: flex;
  align-items: center;
  gap: 4px;
}

.pagination-container .t-icon {
  font-size: 16px;
}

/* 响应式调整 */
@media screen and (max-width: 768px) {
  .store-container {
    padding: 16px;
  }

  .store-wrapper {
    padding: 16px;
  }

  .pagination-container {
    flex-direction: column;
    gap: 16px;
  }

  .app-icon-container {
    width: 80px;
    height: 80px;
  }

  .app-content {
    padding: 6px;
  }

  .app-title {
    font-size: 13px;
  }

  .app-description {
    font-size: 11px;
    margin: 3px 0 6px;
  }

  .app-footer :deep(.t-button) {
    width: 50px;
    height: 22px;
    font-size: 11px;
  }
}

.import-dialog :deep(.t-dialog__body) {
  padding: 0;
}

.import-content {
  padding: 24px;
}

.import-tabs {
  margin-bottom: 16px;
}

.url-input-area {
  padding: 16px;
}

.upload-area {
  border: 2px dashed var(--td-component-stroke);
  border-radius: 8px;
  padding: 32px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.upload-area:hover {
  border-color: var(--td-brand-color);
}

.upload-placeholder {
  color: var(--td-text-color-secondary);
}

.upload-tip {
  font-size: 12px;
  margin-top: 8px;
  color: var(--td-text-color-placeholder);
}

.file-input {
  display: none;
}

.preview-section {
  margin-top: 24px;
}

.preview-title {
  font-size: 16px;
  font-weight: 500;
  margin: 0 0 16px;
}

.preview-content {
  background-color: var(--td-bg-color-secondarycontainer);
  border-radius: 6px;
  padding: 16px;
  max-height: 500px;
  overflow: hidden;
}

.preview-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 16px;
}

/* 响应式调整 */
@media screen and (max-width: 768px) {
  .import-content {
    padding: 16px;
  }

  .upload-area {
    padding: 24px;
  }

  .preview-content {
    max-height: 200px;
  }
}

.base64-input-area {
  padding: 16px;
}

.base64-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.json-editor {
  width: 100%;
  height: 400px;
  border-radius: 6px;
  overflow: hidden;
}
</style> 