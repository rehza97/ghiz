/**
 * Firebase Storage Service
 * Handles file uploads and downloads
 */

import { getStorage, ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage'
import { app } from '@/lib/firebase'

const storage = getStorage(app)

export class StorageService {
  /**
   * Upload a file to Firebase Storage
   * @param file - The file to upload
   * @param path - The storage path (e.g., 'libraries/logos/lib_001.png')
   * @returns The download URL of the uploaded file
   */
  static async uploadFile(file: File, path: string): Promise<string> {
    try {
      const storageRef = ref(storage, path)
      const snapshot = await uploadBytes(storageRef, file)
      const downloadURL = await getDownloadURL(snapshot.ref)
      return downloadURL
    } catch (error) {
      console.error('Error uploading file:', error)
      throw new Error('فشل رفع الملف')
    }
  }

  /**
   * Upload an image with automatic compression and optimization
   * @param file - The image file to upload
   * @param path - The storage path
   * @param maxWidth - Maximum width for the image (default: 1920)
   * @param maxHeight - Maximum height for the image (default: 1080)
   * @param quality - Image quality (0-1, default: 0.8)
   * @returns The download URL of the uploaded image
   */
  static async uploadImage(
    file: File,
    path: string,
    maxWidth = 1920,
    maxHeight = 1080,
    quality = 0.8
  ): Promise<string> {
    try {
      // Compress and resize image
      const compressedFile = await this.compressImage(file, maxWidth, maxHeight, quality)
      return await this.uploadFile(compressedFile, path)
    } catch (error) {
      console.error('Error uploading image:', error)
      throw new Error('فشل رفع الصورة')
    }
  }

  /**
   * Compress and resize an image
   * @param file - The image file to compress
   * @param maxWidth - Maximum width
   * @param maxHeight - Maximum height
   * @param quality - Image quality (0-1)
   * @returns Compressed image file
   */
  private static compressImage(
    file: File,
    maxWidth: number,
    maxHeight: number,
    quality: number
  ): Promise<File> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.readAsDataURL(file)
      reader.onload = (event) => {
        const img = new Image()
        img.src = event.target?.result as string
        img.onload = () => {
          const canvas = document.createElement('canvas')
          let width = img.width
          let height = img.height

          // Calculate new dimensions
          if (width > height) {
            if (width > maxWidth) {
              height = (height * maxWidth) / width
              width = maxWidth
            }
          } else {
            if (height > maxHeight) {
              width = (width * maxHeight) / height
              height = maxHeight
            }
          }

          canvas.width = width
          canvas.height = height

          const ctx = canvas.getContext('2d')
          if (!ctx) {
            reject(new Error('Failed to get canvas context'))
            return
          }

          ctx.drawImage(img, 0, 0, width, height)

          canvas.toBlob(
            (blob) => {
              if (!blob) {
                reject(new Error('Failed to compress image'))
                return
              }
              const compressedFile = new File([blob], file.name, {
                type: 'image/jpeg',
                lastModified: Date.now(),
              })
              resolve(compressedFile)
            },
            'image/jpeg',
            quality
          )
        }
        img.onerror = () => reject(new Error('Failed to load image'))
      }
      reader.onerror = () => reject(new Error('Failed to read file'))
    })
  }

  /**
   * Delete a file from Firebase Storage
   * @param path - The storage path of the file to delete
   */
  static async deleteFile(path: string): Promise<void> {
    try {
      const storageRef = ref(storage, path)
      await deleteObject(storageRef)
    } catch (error) {
      console.error('Error deleting file:', error)
      throw new Error('فشل حذف الملف')
    }
  }

  /**
   * Get the download URL for a file
   * @param path - The storage path
   * @returns The download URL
   */
  static async getDownloadURL(path: string): Promise<string> {
    try {
      const storageRef = ref(storage, path)
      return await getDownloadURL(storageRef)
    } catch (error) {
      console.error('Error getting download URL:', error)
      throw new Error('فشل الحصول على رابط التحميل')
    }
  }

  /**
   * Upload library logo
   * @param file - The logo image file
   * @param libraryId - The library ID
   * @returns The download URL
   */
  static async uploadLibraryLogo(file: File, libraryId: string): Promise<string> {
    const path = `libraries/logos/${libraryId}_${Date.now()}.jpg`
    return await this.uploadImage(file, path, 512, 512, 0.9)
  }

  /**
   * Upload floor map
   * @param file - The map image file
   * @param libraryId - The library ID
   * @param floorId - The floor ID
   * @returns The download URL
   */
  static async uploadFloorMap(
    file: File,
    libraryId: string,
    floorId: string
  ): Promise<string> {
    const path = `libraries/${libraryId}/floors/${floorId}_${Date.now()}.jpg`
    return await this.uploadImage(file, path, 2048, 2048, 0.85)
  }

  /**
   * Upload book cover
   * @param file - The cover image file
   * @param isbn - The book ISBN
   * @returns The download URL
   */
  static async uploadBookCover(file: File, isbn: string): Promise<string> {
    const path = `books/covers/${isbn}_${Date.now()}.jpg`
    return await this.uploadImage(file, path, 800, 1200, 0.9)
  }
}

