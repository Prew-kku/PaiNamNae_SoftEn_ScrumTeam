export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig()
  
  // 1. ดึง Reference ของ Cookie มา (ยังไม่เอา .value)
  const token = useCookie('token')

  const api = $fetch.create({
    baseURL: config.public.apiBase,
    credentials: 'include',

    async onRequest({ options }) {
      // 2. เช็คค่า .value ในจังหวะที่จะยิง Request จริงๆ
      if (token.value) {
        options.headers = {
          ...options.headers,
          Authorization: `Bearer ${token.value}`,
        }
      }
    },

    onResponse({ response }) {
      // Logic เดิมของคุณ: แกะ data ออกมา
      if (response._data && response._data.data) {
         response._data = response._data.data
      }
    },

    onResponseError({ response }) {
      // ... Logic error handling เดิมของคุณ ...
      let body = response?._data
      if (typeof body === 'string') {
        try { body = JSON.parse(body) } catch { }
      }

      const msg =
        body?.message ||
        body?.error?.message ||
        body?.error ||
        response?.statusText ||
        'Request failed'

      // เพิ่ม: ถ้า Token หมดอายุ (401) ให้ล้าง Cookie แล้วดีดไปหน้า Login
      if (response.status === 401) {
          token.value = null;
          if (process.client) {
             // window.location.href = '/login'; // เปิดบรรทัดนี้ถ้าต้องการให้เด้งออก
          }
      }

      throw createError({
        statusCode: response?.status || 500,
        statusMessage: msg,
        data: body,
      })
    },
  })

  return { provide: { api } }
}) 