// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'

// ── PUBLIC / USER VIEWS ────────────────────────────────────────
import PublicLayout       from '../views/public/PublicLayout.vue'
import HomeView           from '../views/public/HomeView.vue'
import ServicesView       from '../views/public/ServicesView.vue'
import BookingView        from '../views/public/BookingView.vue'
import BookingSuccessView from '../views/public/BookingSuccessView.vue'
import BookingHistoryView from '../views/public/BookingHistoryView.vue'
import ReviewView         from '../views/public/ReviewView.vue'
import ProfileView        from '../views/public/ProfileView.vue'
import NotificationsView  from '../views/public/NotificationsView.vue'
import LoginView          from '../views/public/LoginView.vue'
import RegisterView       from '../views/public/RegisterView.vue'

// ── ADMIN VIEWS ────────────────────────────────────────────────
import AdminLayout        from '../views/admin/AdminLayout.vue'
import AdminDashboard     from '../views/admin/AdminDashboard.vue'
import AdminBookings      from '../views/admin/AdminBookings.vue'
import AdminBookingDetail from '../views/admin/AdminBookingDetail.vue'
import AdminServices      from '../views/admin/AdminServices.vue'
import AdminStaff         from '../views/admin/AdminStaff.vue'
import AdminReviews       from '../views/admin/AdminReviews.vue'
import AdminCustomers     from '../views/admin/AdminCustomers.vue'
import AdminSchedule      from '../views/admin/AdminSchedule.vue'

const routes = [
  // ── PUBLIC ──────────────────────────────────────────────────
  {
    path: '/',
    component: PublicLayout,
    children: [
      { path: '',                name: 'home',           component: HomeView },
      { path: 'services',        name: 'services',        component: ServicesView },
      { path: 'booking',         name: 'booking',         component: BookingView },
      { path: 'booking/success', name: 'booking-success', component: BookingSuccessView },
      { path: 'history',         name: 'booking-history', component: BookingHistoryView },
      { path: 'review/:bookingId', name: 'review',        component: ReviewView },
      { path: 'profile',         name: 'profile',         component: ProfileView },
      { path: 'notifications',   name: 'notifications',   component: NotificationsView },
    ]
  },

  // ── AUTH ─────────────────────────────────────────────────────
  { path: '/login',    name: 'login',    component: LoginView },
  { path: '/register', name: 'register', component: RegisterView },

  // ── ADMIN ────────────────────────────────────────────────────
  {
    path: '/admin',
    component: AdminLayout,
    meta: { requiresAdmin: true },
    children: [
      { path: '',          redirect: '/admin/dashboard' },
      { path: 'dashboard', name: 'admin-dashboard',       component: AdminDashboard },
      { path: 'bookings',  name: 'admin-bookings',         component: AdminBookings },
      { path: 'bookings/:id', name: 'admin-booking-detail', component: AdminBookingDetail },
      { path: 'services',  name: 'admin-services',         component: AdminServices },
      { path: 'staff',     name: 'admin-staff',            component: AdminStaff },
      { path: 'reviews',   name: 'admin-reviews',          component: AdminReviews },
      { path: 'customers', name: 'admin-customers',        component: AdminCustomers },
      { path: 'schedule',  name: 'admin-schedule',         component: AdminSchedule },
    ]
  },

  // ── CATCH-ALL ────────────────────────────────────────────────
  { path: '/:pathMatch(.*)*', redirect: '/' }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  // Scroll ke atas setiap pindah halaman
  scrollBehavior() {
    return { top: 0 }
  }
})

// ── NAVIGATION GUARD ─────────────────────────────────────────
// Hanya proteksi route /admin, semua public route bebas diakses
router.beforeEach((to, from, next) => {
  if (to.matched.some(r => r.meta.requiresAdmin)) {
    const isAdmin = localStorage.getItem('salon_admin') === 'true'
    if (!isAdmin) {
      return next({ name: 'login', query: { redirect: to.fullPath } })
    }
  }
  next()
})

export default router