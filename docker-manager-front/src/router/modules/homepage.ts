import { DashboardIcon } from 'tdesign-icons-vue-next';
import { shallowRef } from 'vue';
import Layout from '@/layouts/index.vue';
import IFrame from '@/layouts/frame/index.vue';

export default [

  {
    path: '/dashboard',
    component: Layout,
    redirect: '/dashboard/base',
    name: 'dashboard',
    meta: {
      title: '仪表盘',
      icon: shallowRef(DashboardIcon),
      orderNo: 0,
      hidden: true,
    },
    children: [
      {
        path: 'base',
        name: 'DashboardBase',
        component: () => import('@/pages/dashboard/base/index.vue'),
        meta: {
          title: '概览仪表盘',
        },
      },
    ],
  },
  {
    path: '/docker',
    name: 'docker',
    component: Layout,
    redirect: '/docker/containers',
    meta: {
      title: '容器管理',
      icon: 'server',
      requiresAuth: true,
    },
    children: [
      {
        path: 'containers',
        name: 'DockerContainers',
        component: () => import('@/pages/docker/containers/index.vue'),
        meta: {
          title: '容器列表',
          requiresAuth: true,
        },
      },
      {
        path: 'create',
        name: 'ContainerCreate',
        component: () => import('@/pages/docker/containers/container-create/index.vue'),
        meta: {
          title: '创建容器',
          requiresAuth: true,
        },
      },
      {
        path: 'containers/edit',
        name: 'ContainerEdit',
        component: () => import('@/pages/docker/containers/container-edit/index.vue'),
        meta: {
          title: '编辑容器',
          hidden: true,
          requiresAuth: true,
        },
      },
      {
        path: 'containers/detail',
        name: 'ContainerDetail',
        component: () => import('@/pages/docker/containers/container-detail/index.vue'),
        meta: {
          title: '容器详情',
          hidden: true,
          requiresAuth: true,
        },
      },
      {
        path: 'images',
        name: 'DockerImages',
        component: () => import('@/pages/docker/images/index.vue'),
        meta: {
          title: '镜像列表',
          requiresAuth: true,
        },
      },
    ],
  },
  {
    path: '/system',
    name: 'System',
    component: () => import('@/layouts/index.vue'),
    redirect: '/system/proxy',
    meta: {
      title: '系统设置',
      icon: 'system-setting',
      requiresAuth: true,
      // requiresPro: true,
    },
    children: [
      {
        path: 'proxy',
        name: 'ProxySetting',
        component: () => import('@/pages/system/proxy.vue'),
        meta: {
          title: '加速设置',
          requiresAuth: true,
          // requiresPro: true,
        },
      },
    ],
  },
  {
    path: '/frame',
    name: 'Frame',
    component: Layout,
    redirect: '/frame/doc',
    meta: {
      icon: 'internet',
      title: '外部页面',
      orderNo: 10,
      hidden: true,
    },
    children: [
      {
        path: 'doc',
        name: 'Doc',
        component: IFrame,
        meta: {
          frameSrc: 'https://naspt.vip',
          title: '使用文档（内嵌）',
        },
      },
      {
        path: 'TDesign',
        name: 'TDesign',
        component: IFrame,
        meta: {
          frameSrc: 'https://pan.naspt.vip',
          title: '资源下载网盘（内嵌）',
        },
      },
      {
        path: 'TDesign2',
        name: 'TDesign2',
        component: IFrame,
        meta: {
          frameSrc: 'https://pan.naspt.vip',
          frameBlank: true,
          title: '资源下载网盘（外链）',
        },
      },
    ],
  },
  {
    path: '/store',
    name: 'Store',
    component: Layout,
    redirect: '/store/index',
    meta: {
      title: '应用商店',
      icon: 'app',
    },
    children: [
      {
        path: 'index',
        name: 'StoreIndex',
        component: () => import('@/pages/store/index.vue'),
        meta: {
          title: '应用商店',
        },
      },
      {
        path: 'install/:id',
        name: 'StoreInstall',
        component: () => import('@/pages/store/install.vue'),
        meta: {
          title: '安装应用',
          hidden: true,
        },
      },
    ],
  },
  {
    path: '/',
    name: 'home',
    component: () => import('@/pages/home/index.vue'),
    meta: {
      requiresAuth: false,
      hidden: true,
    },
  },
];
