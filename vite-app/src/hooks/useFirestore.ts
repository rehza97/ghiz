/**
 * React hooks for Firestore data fetching
 * Uses React Query for caching and state management
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { FirestoreService } from '@/services/firestore.service'
import type {
  BookLocation,
  Scan,
  Correction,
  SystemConfig,
  CreateLibraryInput,
  CreateFloorInput,
  CreateShelfInput,
  CreateBookInput,
  UpdateLibraryInput,
  UpdateFloorInput,
  UpdateShelfInput,
  UpdateBookInput,
} from '@/types'

// ==================== Libraries ====================

export function useLibraries(wilaya?: string) {
  return useQuery({
    queryKey: ['libraries', wilaya],
    queryFn: () => FirestoreService.Library.getLibraries(wilaya),
  })
}

export function useLibrary(libraryId: string) {
  return useQuery({
    queryKey: ['library', libraryId],
    queryFn: () => FirestoreService.Library.getLibraryById(libraryId),
    enabled: !!libraryId,
  })
}

export function useSaveLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ libraryId, data }: { libraryId: string; data: CreateLibraryInput }) =>
      FirestoreService.Library.saveLibrary(libraryId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

export function useUpdateLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ libraryId, data }: { libraryId: string; data: UpdateLibraryInput }) =>
      FirestoreService.Library.updateLibrary(libraryId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
      queryClient.invalidateQueries({ queryKey: ['library', variables.libraryId] })
    },
  })
}

export function useDeleteLibrary() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (libraryId: string) => FirestoreService.Library.deleteLibrary(libraryId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['libraries'] })
    },
  })
}

// ==================== Floors ====================

export function useFloors(libraryId: string) {
  return useQuery({
    queryKey: ['floors', libraryId],
    queryFn: () => FirestoreService.Floor.getFloorsByLibrary(libraryId),
    enabled: !!libraryId,
  })
}

export function useFloor(libraryId: string, floorId: string) {
  return useQuery({
    queryKey: ['floor', libraryId, floorId],
    queryFn: () => FirestoreService.Floor.getFloorById(libraryId, floorId),
    enabled: !!libraryId && !!floorId,
  })
}

export function useSaveFloor() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      data,
    }: {
      libraryId: string
      floorId: string
      data: CreateFloorInput
    }) => FirestoreService.Floor.saveFloor(libraryId, floorId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['floors', variables.libraryId] })
    },
  })
}

export function useUpdateFloor() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      data,
    }: {
      libraryId: string
      floorId: string
      data: UpdateFloorInput
    }) => FirestoreService.Floor.updateFloor(libraryId, floorId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['floors', variables.libraryId] })
      queryClient.invalidateQueries({
        queryKey: ['floor', variables.libraryId, variables.floorId],
      })
    },
  })
}

// ==================== Shelves ====================

export function useShelves(libraryId: string, floorId: string) {
  return useQuery({
    queryKey: ['shelves', libraryId, floorId],
    queryFn: () => FirestoreService.Shelf.getShelvesByFloor(libraryId, floorId),
    enabled: !!libraryId && !!floorId,
  })
}

export function useShelf(libraryId: string, floorId: string, shelfId: string) {
  return useQuery({
    queryKey: ['shelf', libraryId, floorId, shelfId],
    queryFn: () => FirestoreService.Shelf.getShelfById(libraryId, floorId, shelfId),
    enabled: !!libraryId && !!floorId && !!shelfId,
  })
}

export function useSaveShelf() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      shelfId,
      data,
    }: {
      libraryId: string
      floorId: string
      shelfId: string
      data: CreateShelfInput
    }) => FirestoreService.Shelf.saveShelf(libraryId, floorId, shelfId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['shelves', variables.libraryId, variables.floorId],
      })
    },
  })
}

export function useUpdateShelf() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      shelfId,
      data,
    }: {
      libraryId: string
      floorId: string
      shelfId: string
      data: UpdateShelfInput
    }) => FirestoreService.Shelf.updateShelf(libraryId, floorId, shelfId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['shelves', variables.libraryId, variables.floorId],
      })
      queryClient.invalidateQueries({
        queryKey: ['shelf', variables.libraryId, variables.floorId, variables.shelfId],
      })
    },
  })
}

export function useShelfBooks(libraryId: string, floorId: string, shelfId: string) {
  return useQuery({
    queryKey: ['shelfBooks', libraryId, floorId, shelfId],
    queryFn: () => FirestoreService.Shelf.getShelfBooks(libraryId, floorId, shelfId),
    enabled: !!libraryId && !!floorId && !!shelfId,
  })
}

export function useAddBookToShelf() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      shelfId,
      bookIsbn,
      position,
    }: {
      libraryId: string
      floorId: string
      shelfId: string
      bookIsbn: string
      position: number
    }) =>
      FirestoreService.Shelf.addBookToShelf(
        libraryId,
        floorId,
        shelfId,
        bookIsbn,
        position
      ),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['shelfBooks', variables.libraryId, variables.floorId, variables.shelfId],
      })
      queryClient.invalidateQueries({
        queryKey: ['shelves', variables.libraryId, variables.floorId],
      })
      queryClient.invalidateQueries({
        queryKey: ['shelf', variables.libraryId, variables.floorId, variables.shelfId],
      })
    },
  })
}

export function useRemoveBookFromShelf() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      libraryId,
      floorId,
      shelfId,
      bookIsbn,
    }: {
      libraryId: string
      floorId: string
      shelfId: string
      bookIsbn: string
    }) =>
      FirestoreService.Shelf.removeBookFromShelf(
        libraryId,
        floorId,
        shelfId,
        bookIsbn
      ),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ['shelfBooks', variables.libraryId, variables.floorId, variables.shelfId],
      })
      queryClient.invalidateQueries({
        queryKey: ['shelves', variables.libraryId, variables.floorId],
      })
      queryClient.invalidateQueries({
        queryKey: ['shelf', variables.libraryId, variables.floorId, variables.shelfId],
      })
    },
  })
}

// ==================== Books ====================

export function useBooks(categoryFilter?: string) {
  return useQuery({
    queryKey: ['books', categoryFilter],
    queryFn: () => FirestoreService.Book.getBooks(categoryFilter),
  })
}

export function useBook(isbn: string) {
  return useQuery({
    queryKey: ['book', isbn],
    queryFn: () => FirestoreService.Book.getBookByIsbn(isbn),
    enabled: !!isbn,
  })
}

export function useSearchBooks(searchQuery: string) {
  return useQuery({
    queryKey: ['searchBooks', searchQuery],
    queryFn: () => FirestoreService.Book.searchBooks(searchQuery),
    enabled: searchQuery.length >= 2, // Only search if query is at least 2 characters
  })
}

export function useSaveBook() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ isbn, data }: { isbn: string; data: CreateBookInput }) =>
      FirestoreService.Book.saveBook(isbn, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] })
    },
  })
}

export function useUpdateBook() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ isbn, data }: { isbn: string; data: UpdateBookInput }) =>
      FirestoreService.Book.updateBook(isbn, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['books'] })
      queryClient.invalidateQueries({ queryKey: ['book', variables.isbn] })
    },
  })
}

export function useDeleteBook() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (isbn: string) => FirestoreService.Book.deleteBook(isbn),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] })
    },
  })
}

// ==================== Book Locations ====================

export function useBookLocations(libraryId: string) {
  return useQuery({
    queryKey: ['bookLocations', libraryId],
    queryFn: () => FirestoreService.BookLocation.getLocationsByLibrary(libraryId),
    enabled: !!libraryId,
  })
}

export function useMisplacedBooks(libraryId: string) {
  return useQuery({
    queryKey: ['misplacedBooks', libraryId],
    queryFn: () => FirestoreService.BookLocation.getMisplacedBooks(libraryId),
    enabled: !!libraryId,
  })
}

export function useUpdateBookPosition() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      bookIsbn,
      libraryId,
      shelfId,
      data,
    }: {
      bookIsbn: string
      libraryId: string
      shelfId: string
      data: Partial<BookLocation>
    }) => FirestoreService.BookLocation.updateBookPosition(bookIsbn, libraryId, shelfId, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['bookLocations', variables.libraryId] })
      queryClient.invalidateQueries({ queryKey: ['misplacedBooks', variables.libraryId] })
    },
  })
}

// ==================== Scans ====================

export function useRecentScans(libraryId: string, limitCount = 50) {
  return useQuery({
    queryKey: ['scans', libraryId, limitCount],
    queryFn: () => FirestoreService.Scan.getRecentScans(libraryId, limitCount),
    enabled: !!libraryId,
  })
}

export function useSaveScan() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (scanData: Omit<Scan, 'id'>) => FirestoreService.Scan.saveScan(scanData),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['scans', variables.libraryId] })
    },
  })
}

// ==================== Corrections ====================

export function useRecentCorrections(libraryId: string, limitCount = 50) {
  return useQuery({
    queryKey: ['corrections', libraryId, limitCount],
    queryFn: () => FirestoreService.Correction.getRecentCorrections(libraryId, limitCount),
    enabled: !!libraryId,
  })
}

export function useSaveCorrection() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (correctionData: Omit<Correction, 'id'>) =>
      FirestoreService.Correction.saveCorrection(correctionData),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['corrections', variables.libraryId] })
    },
  })
}

export function useUpdateCorrection() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      correctionId,
      updates,
    }: {
      correctionId: string
      updates: Partial<Correction>
    }) => FirestoreService.Correction.updateCorrection(correctionId, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['corrections'] })
    },
  })
}

// ==================== Analytics ====================

export function useAnalytics(startDate: string, endDate: string, libraryId?: string) {
  return useQuery({
    queryKey: ['analytics', startDate, endDate, libraryId],
    queryFn: () => FirestoreService.Analytics.getAnalytics(startDate, endDate, libraryId),
    enabled: !!startDate && !!endDate,
  })
}

export function useAnalyticsForDate(date: string) {
  return useQuery({
    queryKey: ['analytics', date],
    queryFn: () => FirestoreService.Analytics.getAnalyticsForDate(date),
    enabled: !!date,
  })
}

// ==================== Admin Users ====================

export function useAdminUsers() {
  return useQuery({
    queryKey: ['adminUsers'],
    queryFn: () => FirestoreService.AdminUser.getAdminUsers(),
  })
}

export function useAdminUser(uid: string) {
  return useQuery({
    queryKey: ['adminUser', uid],
    queryFn: () => FirestoreService.AdminUser.getAdminUserById(uid),
    enabled: !!uid,
  })
}

// ==================== System Configuration ====================

export function useSystemConfig() {
  return useQuery({
    queryKey: ['systemConfig'],
    queryFn: () => FirestoreService.System.getSystemConfig(),
  })
}

export function useUpdateSystemConfig() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      updates,
      adminId,
    }: {
      updates: Partial<SystemConfig>
      adminId: string
    }) => FirestoreService.System.updateSystemConfig(updates, adminId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['systemConfig'] })
    },
  })
}

