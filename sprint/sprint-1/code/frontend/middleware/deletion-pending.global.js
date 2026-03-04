export default defineNuxtRouteMiddleware((to) => {
  if (process.server) return

  const token = useCookie('token').value
  const user = useCookie('user').value

  if (!token || !user?.deletionPending) return

  if (to.path !== '/deletion/cancel') {
    return navigateTo('/deletion/cancel')
  }
})