/**
 * Authentication Context Provider
 * Manages authentication state and provides auth methods
 */

import { createContext, useContext, useState, useEffect, type ReactNode } from 'react'
import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  getIdTokenResult,
  type User as FirebaseUser,
} from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, firestore } from '@/lib/firebase'

interface AdminUser {
  uid?: string
  id?: string
  email: string
  displayName?: string
  role: 'admin' | 'super_admin' | 'librarian'
  libraryId?: string
  isActive: boolean
  createdAt?: string
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
    if (!firestore) {
      console.log('[Auth] fetchAdminUser: Firestore not initialized')
      return null
    }

    try {
      const adminRef = doc(firestore, 'admin_users', uid)
      console.log('[Auth] fetchAdminUser: Querying admin_users/', uid, '(app uses "book" Firestore DB per VITE_FIRESTORE_DATABASE)')
      const adminDoc = await getDoc(adminRef)
      console.log('[Auth] fetchAdminUser: Document exists?', adminDoc.exists(), '| Path:', adminDoc.ref.path)
      if (adminDoc.exists()) {
        const data = adminDoc.data() as AdminUser
        console.log('[Auth] fetchAdminUser: Admin data:', { email: data?.email, role: data?.role, isActive: data?.isActive })
        return { ...data, uid: adminDoc.id } as AdminUser
      }
      console.log('[Auth] fetchAdminUser: No admin document found for uid:', uid)
    } catch (error) {
      console.error('[Auth] fetchAdminUser: Error fetching admin user:', error)
    }
    return null
  }

  // Build admin from custom claims when Firestore doc doesn't exist
  const buildAdminFromClaims = async (user: FirebaseUser): Promise<AdminUser | null> => {
    const tokenResult = await getIdTokenResult(user)
    const role = tokenResult.claims.role as string | undefined
    const isAdminClaim = tokenResult.claims.isAdmin as boolean | undefined
    if (role && (role === 'super_admin' || role === 'admin' || role === 'librarian' || isAdminClaim)) {
      return {
        uid: user.uid,
        email: user.email || '',
        displayName: user.displayName || undefined,
        role: role as AdminUser['role'],
        isActive: true,
      }
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
        const admin = await fetchAdminUser(user.uid)
        if (!admin) {
          const fallback = await buildAdminFromClaims(user)
          setAdminUser(fallback)
        } else {
          setAdminUser(admin)
        }
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
      console.log('[Auth] signIn: Attempting login for', email)
      const result = await signInWithEmailAndPassword(auth, email, password)
      console.log('[Auth] signIn: Firebase Auth success, uid:', result.user.uid, '| email:', result.user.email)
      
      // Check if user is an admin (document in admin_users collection)
      const admin = await fetchAdminUser(result.user.uid)
      console.log('[Auth] signIn: fetchAdminUser result:', admin ? { email: admin.email, role: admin.role } : 'null')
      
      if (!admin) {
        // Fallback: check custom claims (role, isAdmin) - admin_users doc may be in different DB
        const tokenResult = await getIdTokenResult(result.user)
        const role = tokenResult.claims.role as string | undefined
        const isAdminClaim = tokenResult.claims.isAdmin as boolean | undefined
        console.log('[Auth] signIn: Fallback - checking custom claims:', { role, isAdmin: isAdminClaim })
        if (role && (role === 'super_admin' || role === 'admin' || role === 'librarian' || isAdminClaim)) {
          const fallbackAdmin: AdminUser = {
            uid: result.user.uid,
            email: result.user.email || email,
            displayName: result.user.displayName || undefined,
            role: role as AdminUser['role'],
            isActive: true,
          }
          console.log('[Auth] signIn: Using admin from custom claims:', fallbackAdmin.role)
          setAdminUser(fallbackAdmin)
          return
        }
        console.warn('[Auth] signIn: No admin_users document and no valid custom claims - signing out')
        await firebaseSignOut(auth)
        throw new Error('ليس لديك صلاحيات الوصول إلى لوحة التحكم')
      }

      if (!admin.isActive) {
        console.warn('[Auth] signIn: Admin user is inactive')
        await firebaseSignOut(auth)
        throw new Error('حسابك غير نشط. يرجى الاتصال بالمسؤول')
      }
      console.log('[Auth] signIn: Login successful for', admin.email)
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

