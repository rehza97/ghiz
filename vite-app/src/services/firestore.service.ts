/**
 * Firestore Service
 * Provides CRUD operations for all Firestore collections
 * Matches the Flutter FirebaseService implementation
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  Query,
  DocumentData,
  serverTimestamp,
  Timestamp,
  addDoc,
  CollectionReference,
  DocumentReference,
} from 'firebase/firestore'
import { firestore } from '@/lib/firebase'
import type {
  Library,
  Floor,
  Shelf,
  Book,
  BookLocation,
  Scan,
  Correction,
  AdminUser,
  User,
  Analytics,
  SystemConfig,
  CreateLibraryInput,
  CreateFloorInput,
  CreateShelfInput,
  CreateBookInput,
  UpdateLibraryInput,
  UpdateFloorInput,
  UpdateShelfInput,
  UpdateBookInput,
  ShelfBook,
} from '@/types'

// ==================== Helper Functions ====================

function getTimestamp(): Timestamp {
  return Timestamp.now()
}

// ==================== Libraries ====================

export class LibraryService {
  private static collectionPath = 'libraries'

  /**
   * Get all active libraries, optionally filtered by wilaya
   */
  static async getLibraries(wilaya?: string): Promise<Library[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      let q: Query<DocumentData> = collection(firestore, this.collectionPath)

      // Filter by active libraries
      q = query(q, where('isActive', '==', true))

      // Filter by wilaya if provided
      if (wilaya && wilaya !== 'All' && wilaya !== 'Tous') {
        q = query(q, where('wilaya', '==', wilaya))
      }

      // Order by city
      q = query(q, orderBy('city'))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Library))
    } catch (error) {
      console.error('Error fetching libraries:', error)
      throw new Error(`Failed to fetch libraries: ${error}`)
    }
  }

  /**
   * Get library by ID
   */
  static async getLibraryById(libraryId: string): Promise<Library | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, libraryId)
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return { id: docSnap.id, ...docSnap.data() } as Library
    } catch (error) {
      console.error('Error fetching library:', error)
      throw new Error(`Failed to fetch library: ${error}`)
    }
  }

  /**
   * Create or update a library
   */
  static async saveLibrary(libraryId: string, data: CreateLibraryInput): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, libraryId)
      const timestamp = getTimestamp()

      const libraryData: Partial<Library> = {
        ...data,
        id: libraryId,
        wilaya: data.city, // Use city as wilaya for now
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      }

      await setDoc(docRef, libraryData, { merge: true })
    } catch (error) {
      console.error('Error saving library:', error)
      throw new Error(`Failed to save library: ${error}`)
    }
  }

  /**
   * Update library
   */
  static async updateLibrary(
    libraryId: string,
    data: UpdateLibraryInput
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, libraryId)

      await updateDoc(docRef, {
        ...data,
        updatedAt: getTimestamp(),
      })
    } catch (error) {
      console.error('Error updating library:', error)
      throw new Error(`Failed to update library: ${error}`)
    }
  }

  /**
   * Delete library (soft delete by setting isActive to false)
   */
  static async deleteLibrary(libraryId: string): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      await this.updateLibrary(libraryId, { isActive: false })
    } catch (error) {
      console.error('Error deleting library:', error)
      throw new Error(`Failed to delete library: ${error}`)
    }
  }
}

// ==================== Floors ====================

export class FloorService {
  /**
   * Get all floors for a library
   */
  static async getFloorsByLibrary(libraryId: string): Promise<Floor[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const floorsRef = collection(firestore, `libraries/${libraryId}/floors`)
      const q = query(floorsRef, orderBy('floorNumber'))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Floor))
    } catch (error) {
      console.error('Error fetching floors:', error)
      throw new Error(`Failed to fetch floors: ${error}`)
    }
  }

  /**
   * Get floor by ID
   */
  static async getFloorById(libraryId: string, floorId: string): Promise<Floor | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, `libraries/${libraryId}/floors`, floorId)
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return { id: docSnap.id, ...docSnap.data() } as Floor
    } catch (error) {
      console.error('Error fetching floor:', error)
      throw new Error(`Failed to fetch floor: ${error}`)
    }
  }

  /**
   * Save floor
   */
  static async saveFloor(
    libraryId: string,
    floorId: string,
    data: CreateFloorInput
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, `libraries/${libraryId}/floors`, floorId)
      const timestamp = getTimestamp()

      const floorData: Partial<Floor> = {
        ...data,
        id: floorId,
        libraryId,
        mapUrl: data.mapAssetPath, // Copy mapAssetPath to mapUrl
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      }

      await setDoc(docRef, floorData, { merge: true })
    } catch (error) {
      console.error('Error saving floor:', error)
      throw new Error(`Failed to save floor: ${error}`)
    }
  }

  /**
   * Update floor
   */
  static async updateFloor(
    libraryId: string,
    floorId: string,
    data: UpdateFloorInput
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, `libraries/${libraryId}/floors`, floorId)

      await updateDoc(docRef, {
        ...data,
        updatedAt: getTimestamp(),
      })
    } catch (error) {
      console.error('Error updating floor:', error)
      throw new Error(`Failed to update floor: ${error}`)
    }
  }
}

// ==================== Shelves ====================

export class ShelfService {
  /**
   * Get all shelves for a floor
   */
  static async getShelvesByFloor(libraryId: string, floorId: string): Promise<Shelf[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const shelvesRef = collection(
        firestore,
        `libraries/${libraryId}/floors/${floorId}/shelves`
      )
      const q = query(shelvesRef, where('isActive', '==', true))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Shelf))
    } catch (error) {
      console.error('Error fetching shelves:', error)
      throw new Error(`Failed to fetch shelves: ${error}`)
    }
  }

  /**
   * Get shelf by ID
   */
  static async getShelfById(
    libraryId: string,
    floorId: string,
    shelfId: string
  ): Promise<Shelf | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(
        firestore,
        `libraries/${libraryId}/floors/${floorId}/shelves`,
        shelfId
      )
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return { id: docSnap.id, ...docSnap.data() } as Shelf
    } catch (error) {
      console.error('Error fetching shelf:', error)
      throw new Error(`Failed to fetch shelf: ${error}`)
    }
  }

  /**
   * Save shelf
   */
  static async saveShelf(
    libraryId: string,
    floorId: string,
    shelfId: string,
    data: CreateShelfInput
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(
        firestore,
        `libraries/${libraryId}/floors/${floorId}/shelves`,
        shelfId
      )
      const timestamp = getTimestamp()

      // Calculate accuracy
      const accuracy = data.capacity > 0 
        ? Math.min(100, Math.max(0, (data.currentCount / data.capacity) * 100))
        : 0

      const shelfData: Partial<Shelf> = {
        ...data,
        id: shelfId,
        libraryId,
        floorId,
        accuracy,
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      }

      await setDoc(docRef, shelfData, { merge: true })
    } catch (error) {
      console.error('Error saving shelf:', error)
      throw new Error(`Failed to save shelf: ${error}`)
    }
  }

  /**
   * Update shelf
   */
  static async updateShelf(
    libraryId: string,
    floorId: string,
    shelfId: string,
    data: UpdateShelfInput
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(
        firestore,
        `libraries/${libraryId}/floors/${floorId}/shelves`,
        shelfId
      )

      await updateDoc(docRef, {
        ...data,
        updatedAt: getTimestamp(),
      })
    } catch (error) {
      console.error('Error updating shelf:', error)
      throw new Error(`Failed to update shelf: ${error}`)
    }
  }

  /**
   * Get books on a shelf (from subcollection)
   */
  static async getShelfBooks(
    libraryId: string,
    floorId: string,
    shelfId: string
  ): Promise<ShelfBook[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const booksRef = collection(
        firestore,
        `libraries/${libraryId}/floors/${floorId}/shelves/${shelfId}/books`
      )
      const q = query(booksRef, orderBy('position'))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ bookIsbn: doc.id, ...doc.data() } as ShelfBook))
    } catch (error) {
      console.error('Error fetching shelf books:', error)
      throw new Error(`Failed to fetch shelf books: ${error}`)
    }
  }
}

// ==================== Books ====================

export class BookService {
  private static collectionPath = 'books'

  /**
   * Get all books
   */
  static async getBooks(categoryFilter?: string): Promise<Book[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      let q: Query<DocumentData> = collection(firestore, this.collectionPath)

      q = query(q, where('isActive', '==', true))

      if (categoryFilter) {
        q = query(q, where('category', '==', categoryFilter))
      }

      q = query(q, orderBy('title'))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ isbn: doc.id, ...doc.data() } as Book))
    } catch (error) {
      console.error('Error fetching books:', error)
      throw new Error(`Failed to fetch books: ${error}`)
    }
  }

  /**
   * Get book by ISBN
   */
  static async getBookByIsbn(isbn: string): Promise<Book | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, isbn)
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return { isbn: docSnap.id, ...docSnap.data() } as Book
    } catch (error) {
      console.error('Error fetching book:', error)
      throw new Error(`Failed to fetch book: ${error}`)
    }
  }

  /**
   * Search books by title, author, or ISBN
   */
  static async searchBooks(searchQuery: string): Promise<Book[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      // Note: This is a simple implementation. For production, use Algolia or similar
      const q = query(
        collection(firestore, this.collectionPath),
        where('isActive', '==', true),
        limit(50)
      )

      const snapshot = await getDocs(q)
      const books = snapshot.docs.map((doc) => ({ isbn: doc.id, ...doc.data() } as Book))

      // Client-side filtering (not ideal for production)
      const lowerQuery = searchQuery.toLowerCase()
      return books.filter(
        (book) =>
          book.title.toLowerCase().includes(lowerQuery) ||
          book.author.toLowerCase().includes(lowerQuery) ||
          book.isbn.includes(searchQuery)
      )
    } catch (error) {
      console.error('Error searching books:', error)
      throw new Error(`Failed to search books: ${error}`)
    }
  }

  /**
   * Save book
   */
  static async saveBook(isbn: string, data: CreateBookInput): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, isbn)
      const timestamp = getTimestamp()

      const bookData: Partial<Book> = {
        ...data,
        isbn,
        language: data.language || 'fr', // Default language
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      }

      await setDoc(docRef, bookData, { merge: true })
    } catch (error) {
      console.error('Error saving book:', error)
      throw new Error(`Failed to save book: ${error}`)
    }
  }

  /**
   * Update book
   */
  static async updateBook(isbn: string, data: UpdateBookInput): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, isbn)

      await updateDoc(docRef, {
        ...data,
        updatedAt: getTimestamp(),
      })
    } catch (error) {
      console.error('Error updating book:', error)
      throw new Error(`Failed to update book: ${error}`)
    }
  }

  /**
   * Delete book (soft delete)
   */
  static async deleteBook(isbn: string): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      await this.updateBook(isbn, { isActive: false })
    } catch (error) {
      console.error('Error deleting book:', error)
      throw new Error(`Failed to delete book: ${error}`)
    }
  }
}

// ==================== Book Locations ====================

export class BookLocationService {
  private static collectionPath = 'bookLocations'

  /**
   * Get book locations by library
   */
  static async getLocationsByLibrary(libraryId: string): Promise<BookLocation[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const q = query(
        collection(firestore, this.collectionPath),
        where('libraryId', '==', libraryId)
      )

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as BookLocation))
    } catch (error) {
      console.error('Error fetching book locations:', error)
      throw new Error(`Failed to fetch book locations: ${error}`)
    }
  }

  /**
   * Get misplaced books in a library
   */
  static async getMisplacedBooks(libraryId: string): Promise<BookLocation[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const q = query(
        collection(firestore, this.collectionPath),
        where('libraryId', '==', libraryId),
        where('isCorrectOrder', '==', false)
      )

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as BookLocation))
    } catch (error) {
      console.error('Error fetching misplaced books:', error)
      throw new Error(`Failed to fetch misplaced books: ${error}`)
    }
  }

  /**
   * Update book position
   */
  static async updateBookPosition(
    bookIsbn: string,
    libraryId: string,
    shelfId: string,
    data: Partial<BookLocation>
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      // Find existing location document
      const q = query(
        collection(firestore, this.collectionPath),
        where('bookIsbn', '==', bookIsbn),
        where('libraryId', '==', libraryId),
        where('shelfId', '==', shelfId),
        limit(1)
      )

      const snapshot = await getDocs(q)

      if (!snapshot.empty) {
        // Update existing document
        const docRef = snapshot.docs[0].ref
        await updateDoc(docRef, {
          ...data,
          updatedAt: getTimestamp(),
        })
      } else {
        // Create new document
        await addDoc(collection(firestore, this.collectionPath), {
          bookIsbn,
          libraryId,
          shelfId,
          ...data,
          createdAt: getTimestamp(),
          updatedAt: getTimestamp(),
        })
      }
    } catch (error) {
      console.error('Error updating book position:', error)
      throw new Error(`Failed to update book position: ${error}`)
    }
  }
}

// ==================== Scans ====================

export class ScanService {
  private static collectionPath = 'scans'

  /**
   * Get recent scans for a library
   */
  static async getRecentScans(libraryId: string, limitCount = 50): Promise<Scan[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const q = query(
        collection(firestore, this.collectionPath),
        where('libraryId', '==', libraryId),
        orderBy('createdAt', 'desc'),
        limit(limitCount)
      )

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Scan))
    } catch (error) {
      console.error('Error fetching scans:', error)
      throw new Error(`Failed to fetch scans: ${error}`)
    }
  }

  /**
   * Save scan
   */
  static async saveScan(scanData: Omit<Scan, 'id'>): Promise<string> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = await addDoc(collection(firestore, this.collectionPath), {
        ...scanData,
        createdAt: getTimestamp(),
      })

      return docRef.id
    } catch (error) {
      console.error('Error saving scan:', error)
      throw new Error(`Failed to save scan: ${error}`)
    }
  }
}

// ==================== Corrections ====================

export class CorrectionService {
  private static collectionPath = 'corrections'

  /**
   * Get recent corrections for a library
   */
  static async getRecentCorrections(
    libraryId: string,
    limitCount = 50
  ): Promise<Correction[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const q = query(
        collection(firestore, this.collectionPath),
        where('libraryId', '==', libraryId),
        orderBy('createdAt', 'desc'),
        limit(limitCount)
      )

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Correction))
    } catch (error) {
      console.error('Error fetching corrections:', error)
      throw new Error(`Failed to fetch corrections: ${error}`)
    }
  }

  /**
   * Save correction
   */
  static async saveCorrection(correctionData: Omit<Correction, 'id'>): Promise<string> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = await addDoc(collection(firestore, this.collectionPath), {
        ...correctionData,
        createdAt: getTimestamp(),
      })

      return docRef.id
    } catch (error) {
      console.error('Error saving correction:', error)
      throw new Error(`Failed to save correction: ${error}`)
    }
  }

  /**
   * Update correction
   */
  static async updateCorrection(
    correctionId: string,
    updates: Partial<Correction>
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, correctionId)

      await updateDoc(docRef, {
        ...updates,
        updatedAt: getTimestamp(),
      })
    } catch (error) {
      console.error('Error updating correction:', error)
      throw new Error(`Failed to update correction: ${error}`)
    }
  }
}

// ==================== Analytics ====================

export class AnalyticsService {
  private static collectionPath = 'analytics'

  /**
   * Get analytics for a date range
   */
  static async getAnalytics(
    startDate: string,
    endDate: string,
    libraryId?: string
  ): Promise<Analytics[]> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      let q: Query<DocumentData> = collection(firestore, this.collectionPath)

      if (libraryId) {
        q = query(q, where('libraryId', '==', libraryId))
      }

      // Note: Need composite index for this query
      q = query(q, where('date', '>=', startDate), where('date', '<=', endDate))

      const snapshot = await getDocs(q)
      return snapshot.docs.map((doc) => ({ date: doc.id, ...doc.data() } as Analytics))
    } catch (error) {
      console.error('Error fetching analytics:', error)
      throw new Error(`Failed to fetch analytics: ${error}`)
    }
  }

  /**
   * Get analytics for a specific date
   */
  static async getAnalyticsForDate(date: string): Promise<Analytics | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, date)
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return { date: docSnap.id, ...docSnap.data() } as Analytics
    } catch (error) {
      console.error('Error fetching analytics for date:', error)
      throw new Error(`Failed to fetch analytics: ${error}`)
    }
  }
}

// ==================== System Configuration ====================

export class SystemService {
  private static collectionPath = 'system'

  /**
   * Get system configuration
   */
  static async getSystemConfig(): Promise<SystemConfig | null> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, 'config')
      const docSnap = await getDoc(docRef)

      if (!docSnap.exists()) return null

      return docSnap.data() as SystemConfig
    } catch (error) {
      console.error('Error fetching system config:', error)
      throw new Error(`Failed to fetch system config: ${error}`)
    }
  }

  /**
   * Update system configuration
   */
  static async updateSystemConfig(
    updates: Partial<SystemConfig>,
    adminId: string
  ): Promise<void> {
    if (!firestore) throw new Error('Firestore not initialized')

    try {
      const docRef = doc(firestore, this.collectionPath, 'config')

      await updateDoc(docRef, {
        ...updates,
        updatedAt: getTimestamp(),
        updatedBy: adminId,
      })
    } catch (error) {
      console.error('Error updating system config:', error)
      throw new Error(`Failed to update system config: ${error}`)
    }
  }
}

// Export all services
export const FirestoreService = {
  Library: LibraryService,
  Floor: FloorService,
  Shelf: ShelfService,
  Book: BookService,
  BookLocation: BookLocationService,
  Scan: ScanService,
  Correction: CorrectionService,
  Analytics: AnalyticsService,
  System: SystemService,
}

