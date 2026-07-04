// src/stores/auth.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user    = ref(null)
  const profile = ref(null)
  const loading = ref(false)

  const isAdmin    = computed(() => profile.value?.role === 'admin')
  const isLoggedIn = computed(() => !!user.value)

  async function fetchProfile(userId) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()
      if (!error && data) {
        profile.value = data
        localStorage.setItem('salon_user', JSON.stringify({ id: data.id, role: data.role }))
        if (data.role === 'admin') {
          localStorage.setItem('salon_admin', 'true')
        } else {
          localStorage.removeItem('salon_admin')
        }
      }
    } catch (e) {
      console.error('fetchProfile error:', e)
    }
  }

  async function ensureProfile(authUser) {
    try {
      const { data: existing } = await supabase
        .from('profiles')
        .select('id')
        .eq('id', authUser.id)
        .single()

      if (!existing) {
        const meta = authUser.user_metadata || {}
        await supabase.from('profiles').insert({
          id:         authUser.id,
          full_name:  meta.full_name || meta.name || authUser.email?.split('@')[0] || 'Pengguna',
          email:      authUser.email,
          phone:      meta.phone || '',
          avatar_url: meta.avatar_url || meta.picture || null,
          role:       'customer'
        })
      }
    } catch (e) {
      console.error('ensureProfile error:', e)
    }
  }

  async function init() {
    loading.value = true
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user) {
        user.value = session.user
        await ensureProfile(session.user)
        await fetchProfile(session.user.id)
      }
    } catch (e) {
      console.error('Auth init error:', e)
    } finally {
      loading.value = false
    }

    // ← Hanya SATU onAuthStateChange
    supabase.auth.onAuthStateChange(async (event, session) => {
      user.value = session?.user ?? null
      if (session?.user) {
        if (event === 'SIGNED_IN') {
          await ensureProfile(session.user)
        }
        await fetchProfile(session.user.id)
      } else {
        profile.value = null
        localStorage.removeItem('salon_user')
        localStorage.removeItem('salon_admin')
      }
    })
  }

  async function login(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    if (data.user) {
      user.value = data.user
      await fetchProfile(data.user.id)
    }
    return data
  }

  async function loginWithGoogle(redirectTo = window.location.origin + '/') {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo }
    })
    if (error) throw error
  }

  async function register(email, password, fullName, phone) {
    const { data, error } = await supabase.auth.signUp({
      email, password,
      options: {
        data: { full_name: fullName, phone },
        emailRedirectTo: `${window.location.origin}`
      }
    })
    if (error) throw error
    return data
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value    = null
    profile.value = null
    localStorage.removeItem('salon_user')
    localStorage.removeItem('salon_admin')
  }

  async function updateProfile(updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', user.value.id)
      .select()
      .single()
    if (error) throw error
    profile.value = data
    return data
  }

  return {
    user, profile, loading,
    isAdmin, isLoggedIn,
    init, login, loginWithGoogle, register, logout, updateProfile
  }
})