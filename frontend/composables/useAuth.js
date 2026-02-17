import { useCookie, useNuxtApp } from '#app' // Import ให้ครบ
import { useRouter } from 'vue-router'

export function useAuth() {
  const { $api } = useNuxtApp()

  const cookieOpts = {
    maxAge: 60 * 60 * 24 * 7, // 7 วัน
    path: '/',
    sameSite: 'lax',
    secure: false // ปิด secure เพื่อให้รองรับ HTTP ของมหาลัย
  }

  const token = useCookie('token', cookieOpts)
  const user = useCookie('user', cookieOpts)
  const router = useRouter()

  const login = async (identifier, password) => {
    const payload = { password }
    if (identifier.includes('@')) {
      payload.email = identifier
    } else {
      payload.username = identifier
    }

    try {
      const res = await $api('/auth/login', {
        method: 'POST',
        body: payload
      })

      console.log("🔥 DEBUG LOGIN RESPONSE:", res) // ดูค่าจริงใน Console

      //  เช็คทั้งแบบมี .data และไม่มี .data 
      // สาเหตุ: บางที $api ของ Nuxt มันแกะ .data ออกให้เราเองอัตโนมัติ
      const accessToken = res.token || res.data?.token
      const userData = res.user || res.data?.user

      if (accessToken) {
        // 1. บันทึกลง State/Cookie
        token.value = accessToken
        user.value = userData
        
        // 2. บันทึกลง LocalStorage (กันเหนียว)
        if (process.client) {
            localStorage.setItem('token', accessToken)
            if (userData) {
                localStorage.setItem('user', JSON.stringify(userData))
            }
        }
      } else {
        console.error("❌ หา Token ไม่เจอใน Response:", res)
        throw new Error("Login failed: No token received")
      }
      
      return res
    } catch (error) {
      console.error("Login Error:", error)
      throw error
    }
  }

  const register = async (formData) => {
    const res = await $api('/users', {
      method: 'POST',
      body: formData 
    })
    return res
  }

  const logout = () => {
    token.value = null
    user.value = null
    if (process.client) {
        localStorage.removeItem('token')
        localStorage.removeItem('user')
    }
    return router.push('/login')
  }

  return { token, user, login, logout, register }
}