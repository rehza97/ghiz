/**
 * Real-time Firestore hooks
 * Uses Firestore onSnapshot for real-time updates
 */

import { useEffect, useState } from 'react'
import {
  collection,
  doc,
  onSnapshot,
  query,
  where,
  orderBy,
  limit,
  QueryConstraint,
} from 'firebase/firestore'
import { firestore } from '@/lib/firebase'
import type { Library, Floor, Shelf, Book, BookLocation, Scan, Correction } from '@/types'

interface RealtimeState<T> {
  data: T | null
  loading: boolean
  error: Error | null
}

interface RealtimeListState<T> {
  data: T[]
  loading: boolean
  error: Error | null
}

// ==================== Libraries ====================

export function useRealtimeLibraries(wilaya?: string): RealtimeListState<Library> {
  const [state, setState] = useState<RealtimeListState<Library>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore) {
      setState({ data: [], loading: false, error: new Error('Firestore not initialized') })
      return
    }

    const constraints: QueryConstraint[] = []
    if (wilaya) {
      constraints.push(where('wilaya', '==', wilaya))
    }
    constraints.push(orderBy('name', 'asc'))

    const q = query(collection(firestore, 'libraries'), ...constraints)

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const libraries = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Library[]
        setState({ data: libraries, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [wilaya])

  return state
}

export function useRealtimeLibrary(libraryId: string): RealtimeState<Library> {
  const [state, setState] = useState<RealtimeState<Library>>({
    data: null,
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId) {
      setState({ data: null, loading: false, error: null })
      return
    }

    const unsubscribe = onSnapshot(
      doc(firestore, 'libraries', libraryId),
      (snapshot) => {
        if (snapshot.exists()) {
          setState({
            data: { id: snapshot.id, ...snapshot.data() } as Library,
            loading: false,
            error: null,
          })
        } else {
          setState({ data: null, loading: false, error: new Error('Library not found') })
        }
      },
      (error) => {
        setState({ data: null, loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId])

  return state
}

// ==================== Floors ====================

export function useRealtimeFloors(libraryId: string): RealtimeListState<Floor> {
  const [state, setState] = useState<RealtimeListState<Floor>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId) {
      setState({ data: [], loading: false, error: null })
      return
    }

    const q = query(
      collection(firestore, `libraries/${libraryId}/floors`),
      orderBy('floorNumber', 'asc')
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const floors = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Floor[]
        setState({ data: floors, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId])

  return state
}

// ==================== Shelves ====================

export function useRealtimeShelves(
  libraryId: string,
  floorId: string
): RealtimeListState<Shelf> {
  const [state, setState] = useState<RealtimeListState<Shelf>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId || !floorId) {
      setState({ data: [], loading: false, error: null })
      return
    }

    const q = query(
      collection(firestore, `libraries/${libraryId}/floors/${floorId}/shelves`),
      orderBy('name', 'asc')
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const shelves = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Shelf[]
        setState({ data: shelves, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId, floorId])

  return state
}

// ==================== Books ====================

export function useRealtimeBooks(categoryFilter?: string): RealtimeListState<Book> {
  const [state, setState] = useState<RealtimeListState<Book>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore) {
      setState({ data: [], loading: false, error: new Error('Firestore not initialized') })
      return
    }

    const constraints: QueryConstraint[] = []
    if (categoryFilter) {
      constraints.push(where('category', '==', categoryFilter))
    }
    constraints.push(orderBy('title', 'asc'))

    const q = query(collection(firestore, 'books'), ...constraints)

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const books = snapshot.docs.map((doc) => ({
          isbn: doc.id,
          ...doc.data(),
        })) as Book[]
        setState({ data: books, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [categoryFilter])

  return state
}

// ==================== Book Locations ====================

export function useRealtimeMisplacedBooks(libraryId: string): RealtimeListState<BookLocation> {
  const [state, setState] = useState<RealtimeListState<BookLocation>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId) {
      setState({ data: [], loading: false, error: null })
      return
    }

    const q = query(
      collection(firestore, 'book_locations'),
      where('libraryId', '==', libraryId),
      where('isCorrectOrder', '==', false),
      orderBy('misplacementCount', 'desc')
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const locations = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as BookLocation[]
        setState({ data: locations, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId])

  return state
}

// ==================== Recent Scans ====================

export function useRealtimeRecentScans(
  libraryId: string,
  limitCount = 10
): RealtimeListState<Scan> {
  const [state, setState] = useState<RealtimeListState<Scan>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId) {
      setState({ data: [], loading: false, error: null })
      return
    }

    const q = query(
      collection(firestore, 'scans'),
      where('libraryId', '==', libraryId),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const scans = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Scan[]
        setState({ data: scans, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId, limitCount])

  return state
}

// ==================== Recent Corrections ====================

export function useRealtimeRecentCorrections(
  libraryId: string,
  limitCount = 10
): RealtimeListState<Correction> {
  const [state, setState] = useState<RealtimeListState<Correction>>({
    data: [],
    loading: true,
    error: null,
  })

  useEffect(() => {
    if (!firestore || !libraryId) {
      setState({ data: [], loading: false, error: null })
      return
    }

    const q = query(
      collection(firestore, 'corrections'),
      where('libraryId', '==', libraryId),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const corrections = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Correction[]
        setState({ data: corrections, loading: false, error: null })
      },
      (error) => {
        setState({ data: [], loading: false, error })
      }
    )

    return () => unsubscribe()
  }, [libraryId, limitCount])

  return state
}

