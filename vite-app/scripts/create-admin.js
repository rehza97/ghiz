#!/usr/bin/env node

/**
 * Script to create an admin user in Firebase
 * Uses Firebase Admin SDK to create user and set custom claims
 * 
 * Usage: node scripts/create-admin.js <email> <password> [role] [displayName]
 * 
 * Example:
 *   node scripts/create-admin.js admin@library.dz Admin123! super_admin "Super Admin"
 */

import admin from 'firebase-admin'
import { readFileSync } from 'fs'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Parse command line arguments
const [email, password, role = 'admin', displayName = 'Admin User'] = process.argv.slice(2)

if (!email || !password) {
  console.error('❌ Usage: node create-admin.js <email> <password> [role] [displayName]')
  console.error('   Roles: super_admin, admin, librarian')
  process.exit(1)
}

// Validate role
const validRoles = ['super_admin', 'admin', 'librarian']
if (!validRoles.includes(role)) {
  console.error(`❌ Invalid role. Must be one of: ${validRoles.join(', ')}`)
  process.exit(1)
}

// Initialize Firebase Admin SDK
try {
  // Try to load service account key
  let serviceAccount
  try {
    serviceAccount = JSON.parse(
      readFileSync(join(__dirname, '../firebase-service-account.json'), 'utf8')
    )
  } catch (err) {
    console.error('❌ Firebase service account key not found!')
    console.error('   Please download your service account key from Firebase Console:')
    console.error('   1. Go to Project Settings > Service Accounts')
    console.error('   2. Click "Generate new private key"')
    console.error('   3. Save as firebase-service-account.json in the vite-app directory')
    process.exit(1)
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  })

  console.log('✅ Firebase Admin initialized\n')
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message)
  process.exit(1)
}

const auth = admin.auth()
const firestore = admin.firestore()

async function createAdminUser() {
  try {
    console.log('Creating admin user...')
    console.log('Email:', email)
    console.log('Role:', role)
    console.log('Display Name:', displayName)
    console.log('')

    // Create the user
    let userRecord
    try {
      userRecord = await auth.createUser({
        email,
        password,
        displayName,
        emailVerified: true, // Auto-verify email for admin users
      })
      console.log('✅ Firebase Auth user created:', userRecord.uid)
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log('⚠️  User already exists, fetching existing user...')
        userRecord = await auth.getUserByEmail(email)
        console.log('✅ Found existing user:', userRecord.uid)
        
        // Update password if user exists
        await auth.updateUser(userRecord.uid, { password })
        console.log('✅ Password updated')
      } else {
        throw error
      }
    }

    // Set custom claims for role-based access
    await auth.setCustomUserClaims(userRecord.uid, {
      role,
      isAdmin: true,
    })
    console.log('✅ Custom claims set')

    // Create admin user document in Firestore
    const adminUserData = {
      uid: userRecord.uid,
      email,
      displayName,
      role,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }

    await firestore.collection('admin_users').doc(userRecord.uid).set(adminUserData, { merge: true })
    console.log('✅ Admin user document created in Firestore')

    console.log('\n✅ Admin user created successfully!')
    console.log('\n📝 Login Credentials:')
    console.log('   Email:', email)
    console.log('   Password:', password)
    console.log('   Role:', role)
    console.log('\n🔗 You can now login at: http://localhost:5173/login')

    process.exit(0)
  } catch (error) {
    console.error('\n❌ Error creating admin user:', error.message)
    if (error.code) {
      console.error('   Error code:', error.code)
    }
    process.exit(1)
  }
}

// Run the script
createAdminUser()

