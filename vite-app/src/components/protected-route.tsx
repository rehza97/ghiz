/**
 * Protected Route Component
 * Redirects to login if user is not authenticated
 */

import { Navigate } from 'react-router-dom'
import { useAuth } from '@/contexts/auth-context'
import { Loader2 } from 'lucide-react'

interface ProtectedRouteProps {
  children: React.ReactNode
  requireSuperAdmin?: boolean
}

export function ProtectedRoute({ children, requireSuperAdmin = false }: ProtectedRouteProps) {
  const { currentUser, adminUser: _adminUser, loading, isSuperAdmin } = useAuth()
  void _adminUser // kept for future use (e.g. role display or admin doc checks)

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-[#38ada9] mx-auto mb-4" />
          <p className="text-gray-600">جاري التحميل...</p>
        </div>
      </div>
    )
  }

  if (!currentUser) {
    return <Navigate to="/login" replace />
  }

  // Note: We allow access if user is authenticated, even if adminUser document
  // doesn't exist yet. The adminUser document is created via Firebase Admin script
  // but custom claims (role, isAdmin) are set during user creation and work immediately.

  if (requireSuperAdmin && !isSuperAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-red-600 mb-2">غير مصرح</h1>
          <p className="text-gray-600">ليس لديك صلاحيات الوصول إلى هذه الصفحة</p>
        </div>
      </div>
    )
  }

  return <>{children}</>
}

