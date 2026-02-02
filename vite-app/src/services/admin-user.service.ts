/**
 * Admin user creation via Cloud Function (no CLI required)
 */

import { getFunctions, httpsCallable } from 'firebase/functions'
import { app } from '@/lib/firebase'

export interface CreateAdminUserInput {
  email: string
  password: string
  role: 'super_admin' | 'admin' | 'librarian'
  displayName?: string
  assignedLibraries?: string[]
}

export async function createAdminUserViaFunction(
  data: CreateAdminUserInput
): Promise<{ uid: string; email: string; role: string; message: string }> {
  const functions = getFunctions(app, 'europe-west1')
  const createAdminUser = httpsCallable<
    CreateAdminUserInput,
    { uid: string; email: string; role: string; message: string }
  >(functions, 'createAdminUser')

  const result = await createAdminUser({
    email: data.email.trim(),
    password: data.password,
    role: data.role,
    displayName: data.displayName?.trim() || '',
    assignedLibraries: data.assignedLibraries?.filter(Boolean) || [],
  })

  return result.data
}
