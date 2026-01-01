/**
 * TypeScript Types matching Flutter AR Book Scanner Schema
 * Based on FIREBASE_SCHEMA.md and SCHEMA_DATA_STRUCTURE_ANALYSIS.md
 */

import { Timestamp } from 'firebase/firestore'

// ==================== Core Library Types ====================

export interface Library {
  id: string
  name: string
  address: string
  postalCode: string
  city: string
  wilaya: string // For filtering (usually same as city)
  phone?: string
  email?: string
  floorCount: number
  latitude: number
  longitude: number
  logoUrl?: string
  hours?: string
  description?: string
  isActive: boolean
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
  createdBy?: string // Admin user ID
  stats?: LibraryStats
}

export interface LibraryStats {
  totalBooks: number
  totalShelves: number
  totalFloors: number
  lastScanDate?: Timestamp | string
}

// ==================== Floor Types ====================

export interface Floor {
  id: string
  name: string
  floorNumber: number // 0 = ground floor, 1 = first floor, etc.
  libraryId: string
  mapAssetPath?: string
  mapUrl?: string // Firebase Storage URL
  description?: string
  shelfCount: number
  mapWidth?: number
  mapHeight?: number
  isActive: boolean
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
}

// ==================== Shelf Types ====================

export interface Shelf {
  id: string
  name: string // "A-1-1" or "B-2-1"
  floorId: string
  libraryId: string
  x: number // Position X (meters)
  y: number // Position Y (meters)
  z: number // Position Z (height)
  width: number // Width (meters)
  height: number // Height (meters)
  depth: number // Depth (meters)
  category?: string // "Fiction", "Science", etc.
  capacity: number // Max books capacity
  currentCount: number // Current number of books
  description?: string
  isActive: boolean
  lastCorrectionDate?: Timestamp | string
  accuracy: number // Percentage (0-100)
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
}

// ==================== Book Types ====================

export interface Book {
  isbn: string // Document ID
  title: string
  author: string
  category: string
  coverUrl?: string
  description?: string
  publisher?: string
  publishDate?: string
  language: string // "fr", "ar", "en"
  pageCount?: number
  isActive: boolean
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
  addedBy?: string // Admin user ID
  stats?: BookStats
}

export interface BookStats {
  totalCopies: number // Total copies across all libraries
  totalLocations: number // Number of shelf locations
  scanCount: number // Total scans
  lastScanDate?: Timestamp | string
}

// ==================== Book Location Types ====================

export interface BookLocation {
  id: string // Auto-generated
  bookIsbn: string
  libraryId: string
  floorId: string
  shelfId: string
  position: number // Current position (1-indexed)
  expectedPosition: number // Expected position
  isCorrectOrder: boolean
  isFlagged: boolean
  reason?: string
  lastCheckedAt?: Timestamp | string
  misplacementCount: number
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
}

// ==================== Shelf Books Subcollection ====================

export interface ShelfBook {
  bookIsbn: string // Document ID (ISBN)
  position: number // Current position (1-indexed)
  expectedPosition: number // Expected position
  isCorrectOrder: boolean
  isFlagged: boolean
  reason?: string
  lastCheckedAt?: Timestamp | string
  misplacementCount: number
  addedAt: Timestamp | string
  updatedAt: Timestamp | string
}

// ==================== Scan Types ====================

export interface Scan {
  id: string // Auto-generated
  userId?: string // User who scanned (if authenticated)
  libraryId: string
  shelfId: string
  floorId: string
  scannedBooks: ScannedBookItem[]
  totalScanned: number
  correctCount: number
  errorCount: number
  accuracy: number // Percentage
  scanDuration?: number // Duration in seconds
  createdAt: Timestamp | string
  deviceInfo?: DeviceInfo
}

export interface ScannedBookItem {
  isbn: string
  title: string
  detectedPosition: number // Physical position from scan
  expectedPosition: number
  isCorrect: boolean
}

export interface DeviceInfo {
  platform: string // "android", "ios", "web"
  model?: string
  osVersion?: string
}

// ==================== Correction Types ====================

export interface Correction {
  id: string // Auto-generated
  libraryId: string
  shelfId: string
  userId?: string // User who performed correction
  status: 'in_progress' | 'completed' | 'cancelled'
  totalMoves: number
  completedMoves: number
  progressPercentage: number // 0-100
  movements: BookMovement[]
  startedAt: Timestamp | string
  completedAt?: Timestamp | string
  duration?: number // Duration in seconds
  createdAt: Timestamp | string
}

export interface BookMovement {
  bookIsbn: string
  bookTitle: string
  fromPosition: number
  toPosition: number
  direction: 'left' | 'right' // Movement direction
  priority: number // 0-5 (0 = most urgent)
  isCompleted: boolean
  completedAt?: Timestamp | string
}

// ==================== User Types ====================

export interface User {
  id: string // Firebase Auth UID
  email: string
  displayName?: string
  photoUrl?: string
  role: 'user' | 'librarian' | 'admin'
  libraryId?: string // Associated library (for librarians)
  isActive: boolean
  lastLoginAt?: Timestamp | string
  createdAt: Timestamp | string
  updatedAt: Timestamp | string
  preferences: UserPreferences
  stats?: UserStats
}

export interface UserPreferences {
  language: 'fr' | 'ar' | 'en'
  theme?: 'light' | 'dark'
}

export interface UserStats {
  totalScans: number
  totalCorrections: number
  lastScanDate?: Timestamp | string
}

// ==================== Admin Types ====================

export interface AdminUser {
  id: string // Firebase Auth UID
  email: string
  displayName: string
  role: 'super_admin' | 'admin' | 'librarian'
  permissions: AdminPermissions
  assignedLibraries: string[] // Array of library IDs
  isActive: boolean
  lastLoginAt?: Timestamp | string
  createdAt: Timestamp | string
  createdBy?: string // Admin who created this account
  updatedAt: Timestamp | string
}

export interface AdminPermissions {
  canManageLibraries: boolean
  canManageBooks: boolean
  canManageUsers: boolean
  canViewAnalytics: boolean
  canManageSystem: boolean
}

// ==================== Analytics Types ====================

export interface Analytics {
  date: string // "YYYY-MM-DD" format (document ID)
  libraryId?: string // Optional: library-specific analytics
  metrics: AnalyticsMetrics
  topMisplacedShelves: TopShelfItem[]
  topScannedBooks: TopBookItem[]
  createdAt: Timestamp | string
}

export interface AnalyticsMetrics {
  totalScans: number
  totalCorrections: number
  totalBooksScanned: number
  averageAccuracy: number // Average shelf accuracy
  totalMisplacedBooks: number
  correctionsCompleted: number
  activeUsers: number
}

export interface TopShelfItem {
  shelfId: string
  shelfName: string
  errorCount: number
}

export interface TopBookItem {
  isbn: string
  title: string
  scanCount: number
}

// ==================== System Configuration ====================

export interface SystemConfig {
  appVersion: string
  minAppVersion: string
  maintenanceMode: boolean
  maintenanceMessage?: string
  features: SystemFeatures
  settings: SystemSettings
  updatedAt: Timestamp | string
  updatedBy: string // Admin user ID
}

export interface SystemFeatures {
  arScanning: boolean
  bookSearch: boolean
  corrections: boolean
  analytics: boolean
}

export interface SystemSettings {
  maxBooksPerScan: number
  scanTimeout: number // Scan timeout in seconds
  correctionTimeout: number // Correction timeout in seconds
}

// ==================== IPS Beacon Types (for future implementation) ====================

export interface IPSBeacon {
  id: string
  uuid: string // BLE UUID
  txPower: number // RSSI at 1 meter
  x: number // Position X (meters)
  y: number // Position Y (meters)
  z: number // Position Z (height)
  floorId: string
  libraryId: string
  coverageRadius: number // Coverage radius (meters)
  location?: string // Location description
}

// ==================== Helper Types ====================

export type FirestoreTimestamp = Timestamp | string | Date

// For forms and creating new documents (without auto-generated fields)
export type CreateLibraryInput = Omit<Library, 'id' | 'createdAt' | 'updatedAt' | 'stats'>
export type CreateFloorInput = Omit<Floor, 'id' | 'createdAt' | 'updatedAt'>
export type CreateShelfInput = Omit<Shelf, 'id' | 'createdAt' | 'updatedAt' | 'accuracy'>
export type CreateBookInput = Omit<Book, 'isbn' | 'createdAt' | 'updatedAt' | 'stats'>
export type CreateBookLocationInput = Omit<BookLocation, 'id' | 'createdAt' | 'updatedAt'>

// For updates (all fields optional except id)
export type UpdateLibraryInput = Partial<Omit<Library, 'id' | 'createdAt'>>
export type UpdateFloorInput = Partial<Omit<Floor, 'id' | 'createdAt'>>
export type UpdateShelfInput = Partial<Omit<Shelf, 'id' | 'createdAt'>>
export type UpdateBookInput = Partial<Omit<Book, 'isbn' | 'createdAt'>>

