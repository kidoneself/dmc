<template>
  <t-form
    ref="form"
    :class="['item-container', `login-${type}`]"
    :data="formData"
    :rules="FORM_RULES"
    label-width="0"
    @submit="onSubmit"
  >
    <template v-if="type == 'password'">
      <t-form-item name="username">
        <t-input v-model="formData.username" size="large" placeholder="请输入账号：admin">
          <template #prefix-icon>
            <t-icon name="user" />
          </template>
        </t-input>
      </t-form-item>

      <t-form-item name="password">
        <t-input
          v-model="formData.password"
          size="large"
          :type="showPsw ? 'text' : 'password'"
          clearable
          placeholder="请输入密码：123456"
        >
          <template #prefix-icon>
            <t-icon name="lock-on" />
          </template>
          <template #suffix-icon>
            <t-icon :name="showPsw ? 'browse' : 'browse-off'" @click="showPsw = !showPsw" />
          </template>
        </t-input>
      </t-form-item>

      <!-- <div class="check-container remember-pwd">
        <t-checkbox>记住密码</t-checkbox>
      </div> -->
    </template>

    <!-- 扫码登录 -->
    <!-- <template v-else-if="type == 'qrcode'">
      <div class="tip-container">
        <span class="tip">微信扫码登录</span>
        <span class="refresh">刷新 <t-icon name="refresh" /> </span>
      </div>
      <qrcode-vue value="" :size="160" level="H" />
    </template> -->

    <!-- 手机号登录 -->
    <!-- <template v-else>
      <t-form-item name="phone">
        <t-input v-model="formData.phone" size="large" placeholder="请输入手机号">
          <template #prefix-icon>
            <t-icon name="mobile" />
          </template>
        </t-input>
      </t-form-item>

      <t-form-item class="verification-code" name="verifyCode">
        <t-input v-model="formData.verifyCode" size="large" placeholder="请输入验证码" />
        <t-button size="large" variant="outline" :disabled="countDown > 0" @click="sendCode">
          {{ countDown == 0 ? '发送验证码' : `${countDown}秒后可重发` }}
        </t-button>
      </t-form-item>
    </template> -->

    <t-form-item v-if="type !== 'qrcode'" class="btn-container">
      <t-button block size="large" type="submit">登录</t-button>
    </t-form-item>

    <div class="switch-container">
      <span v-if="type !== 'password'" class="tip" @click="switchType('password')">账号密码登录</span>
      <!-- <span v-if="type !== 'qrcode'" class="tip" @click="switchType('qrcode')">微信扫码登录</span> -->
      <!-- <span v-if="type !== 'phone'" class="tip" @click="switchType('phone')">手机号登录</span> -->
    </div>
  </t-form>
</template>

<script setup lang="ts">
import QrcodeVue from 'qrcode.vue';
import type { FormInstanceFunctions, FormRule, SubmitContext } from 'tdesign-vue-next';
import { MessagePlugin } from 'tdesign-vue-next';
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

import { useCounter } from '@/hooks';
import { useUserStore } from '@/store';

const userStore = useUserStore();

const INITIAL_DATA = {
  username: 'admin',
  password: '123456',
};

const FORM_RULES: Record<string, FormRule[]> = {
  username: [{ required: true, message: '请输入用户名', type: 'error' }],
  password: [{ required: true, message: '请输入密码', type: 'error' }],
};

const type = ref('password');

const form = ref<FormInstanceFunctions>();
const formData = ref({ ...INITIAL_DATA });
const showPsw = ref(false);

const [countDown, handleCounter] = useCounter();

const router = useRouter();
const route = useRoute();

const switchType = (val: string) => {
  type.value = val;
};

// /**
//  * 发送验证码
//  */
// const sendCode = () => {
//   form.value.validate({ fields: ['phone'] }).then((e) => {
//     if (e === true) {
//       handleCounter();
//     }
//   });
// };

const onSubmit = async (ctx: SubmitContext) => {
  if (ctx.validateResult === true) {
    try {
      await userStore.login({
        username: formData.value.username,
        password: formData.value.password,
      });
      
      // 登录成功后获取用户信息
      await userStore.getUserInfo();

      MessagePlugin.success('登录成功');
      const redirect = route.query.redirect as string;
      const redirectUrl = redirect ? decodeURIComponent(redirect) : '/';
      router.push(redirectUrl);
    } catch (e) {
      MessagePlugin.error(e.message || '登录失败');
    }
  }
};
</script>

<style lang="less" scoped>
@import '../index.less';
</style>
