<template>
  <div class="min-h-[80vh] flex items-center justify-center p-4">
    <main class="bg-white rounded-lg shadow-lg max-w-md w-full p-8 border border-gray-300">
      <h1 class="text-2xl font-bold text-gray-900 mb-3 text-center">บัญชีอยู่ระหว่างรอลบ</h1>
      <p class="text-sm text-gray-600 text-center mb-6">
        บัญชีของคุณถูกปิดใช้งานชั่วคราว หากต้องการใช้งานต่อสามารถยกเลิกคำขอลบบัญชีได้ที่หน้านี้
      </p>

      <button
        :disabled="isLoading"
        @click="cancelDeletion"
        class="w-full py-3 bg-blue-600 text-white rounded-md font-medium hover:bg-blue-700 disabled:bg-gray-400"
      >
        {{ isLoading ? 'กำลังยกเลิกคำขอ...' : 'ยกเลิกการลบบัญชี' }}
      </button>

      <button
        :disabled="isLoading"
        @click="logout"
        class="w-full mt-3 py-3 bg-gray-200 text-gray-800 rounded-md font-medium hover:bg-gray-300 disabled:opacity-60"
      >
        ออกจากระบบ
      </button>

      <p v-if="errorMessage" class="text-red-600 text-sm mt-4 text-center">{{ errorMessage }}</p>
    </main>
  </div>
</template>

<script setup>
definePageMeta({
  middleware: 'auth'
})

const { $api } = useNuxtApp()
const { logout } = useAuth()
const router = useRouter()
const user = useCookie('user')

const isLoading = ref(false)
const errorMessage = ref('')

onMounted(() => {
  if (!user.value?.deletionPending) {
    router.replace('/')
  }
})

const cancelDeletion = async () => {
  errorMessage.value = ''
  isLoading.value = true

  try {
    await $api('/deletion/cancel', { method: 'POST' })

    if (user.value) {
      user.value = {
        ...user.value,
        deletionPending: false,
        isActive: true
      }
    }

    router.push('/')
  } catch (e) {
    errorMessage.value = e?.data?.message || 'ไม่สามารถยกเลิกคำขอลบได้'
  } finally {
    isLoading.value = false
  }
}
</script>
