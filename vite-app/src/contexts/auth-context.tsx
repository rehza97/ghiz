/**
 * Authentication Context Provider
 * Manages authentication state and provides auth methods
 */

import { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User as FirebaseUser,
} from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, firestore } from '@/lib/firebase'

interface AdminUser {
  uid: string
  email: string
  displayName?: string
  role: 'admin' | 'super_admin' | 'librarian'
  libraryId?: string
  isActive: boolean
  createdAt: string
}

interface AuthContextType {
  currentUser: FirebaseUser | null
  adminUser: AdminUser | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  isAdmin: boolean
  isSuperAdmin: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null)
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null)
  const [loading, setLoading] = useState(true)

  // Fetch admin user data from Firestore
  const fetchAdminUser = async (uid: string) => {
    if (!firestore) return null

    try {
      const adminDoc = await getDoc(doc(firestore, 'admin_users', uid))
      if (adminDoc.exists()) {
        return adminDoc.data() as AdminUser
      }
    } catch (error) {
      console.error('Error fetching admin user:', error)
    }
    return null
  }

  useEffect(() => {
    if (!auth) {
      setLoading(false)
      return
    }

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user)

      if (user) {
        // Fetch admin user data
        const admin = await fetchAdminUser(user.uid)
        setAdminUser(admin)
      } else {
        setAdminUser(null)
      }

      setLoading(false)
    })

    return unsubscribe
  }, [])

  const signIn = async (email: string, password: string) => {
    if (!auth) throw new Error('Firebase Auth not initialized')

    try {
      const result = await signInWithEmailAndPassword(auth, email, password)
      
      // Check if user is an admin
      const admin = await fetchAdminUser(result.user.uid)
      if (!admin) {
        // Not an admin user, sign out
        await firebaseSignOut(auth)
        throw new Error('ليس لديك صلاحيات الوصول إلى لوحة التحكم')
      }

      if (!admin.isActive) {
        await firebaseSignOut(auth)
        throw new Error('حسابك غير نشط. يرجى الاتصال بالمسؤول')
      }
    } catch (error: any) {
      if (error.code === 'auth/invalid-credential' || error.code === 'auth/user-not-found') {
        throw new Error('البريد الإلكتروني أو كلمة المرور غير صحيحة')
      }
      throw error
    }
  }

  const signOut = async () => {
    if (!auth) throw new Error('Firebase Auth not initialized')
    await firebaseSignOut(auth)
  }

  const value: AuthContextType = {
    currentUser,
    adminUser,
    loading,
    signIn,
    signOut,
    isAdmin: adminUser?.role === 'admin' || adminUser?.role === 'super_admin',
    isSuperAdmin: adminUser?.role === 'super_admin',
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

