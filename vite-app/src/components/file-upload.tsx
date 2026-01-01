/**
 * File Upload Component
 * Reusable component for uploading files to Firebase Storage
 */

import { useState, useRef } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Upload, X, Loader2, Image as ImageIcon, File } from 'lucide-react'
import { cn } from '@/lib/utils'

interface FileUploadProps {
  onUpload: (file: File) => Promise<string>
  accept?: string
  maxSize?: number // in MB
  preview?: boolean
  currentUrl?: string
  onUrlChange?: (url: string) => void
  className?: string
}

export function FileUpload({
  onUpload,
  accept = 'image/*',
  maxSize = 5,
  preview = true,
  currentUrl,
  onUrlChange,
  className,
}: FileUploadProps) {
  const [uploading, setUploading] = useState(false)
  const [previewUrl, setPreviewUrl] = useState<string | null>(currentUrl || null)
  const [error, setError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file size
    if (file.size > maxSize * 1024 * 1024) {
      setError(`حجم الملف يجب أن يكون أقل من ${maxSize} ميجابايت`)
      return
    }

    // Validate file type
    if (accept && !file.type.match(accept.replace('*', '.*'))) {
      setError('نوع الملف غير مدعوم')
      return
    }

    setError(null)
    setUploading(true)

    try {
      // Show preview
      if (preview && file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onload = (e) => {
          setPreviewUrl(e.target?.result as string)
        }
        reader.readAsDataURL(file)
      }

      // Upload file
      const url = await onUpload(file)
      setPreviewUrl(url)
      onUrlChange?.(url)
    } catch (err: any) {
      setError(err.message || 'فشل رفع الملف')
      setPreviewUrl(null)
    } finally {
      setUploading(false)
    }
  }

  const handleRemove = () => {
    setPreviewUrl(null)
    setError(null)
    onUrlChange?.('')
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const handleClick = () => {
    fileInputRef.current?.click()
  }

  return (
    <div className={cn('space-y-2', className)} dir="rtl">
      <input
        ref={fileInputRef}
        type="file"
        accept={accept}
        onChange={handleFileSelect}
        className="hidden"
      />

      {!previewUrl ? (
        <Card
          className="border-2 border-dashed cursor-pointer hover:border-[#38ada9] transition-colors"
          onClick={handleClick}
        >
          <CardContent className="flex flex-col items-center justify-center p-6">
            {uploading ? (
              <>
                <Loader2 className="h-12 w-12 text-[#38ada9] animate-spin mb-3" />
                <p className="text-sm text-gray-600">جاري الرفع...</p>
              </>
            ) : (
              <>
                {accept.includes('image') ? (
                  <ImageIcon className="h-12 w-12 text-gray-400 mb-3" />
                ) : (
                  <File className="h-12 w-12 text-gray-400 mb-3" />
                )}
                <p className="text-sm text-gray-600 mb-1">
                  انقر لاختيار ملف أو اسحبه هنا
                </p>
                <p className="text-xs text-gray-400">
                  الحد الأقصى للحجم: {maxSize} ميجابايت
                </p>
              </>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-4">
            <div className="relative">
              {preview && previewUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                <img
                  src={previewUrl}
                  alt="Preview"
                  className="w-full h-48 object-cover rounded-lg"
                />
              ) : (
                <div className="flex items-center gap-3 p-4 bg-gray-50 rounded-lg">
                  <File className="h-8 w-8 text-[#38ada9]" />
                  <div className="flex-1">
                    <p className="text-sm font-medium">تم رفع الملف بنجاح</p>
                    <p className="text-xs text-gray-500 truncate">{previewUrl}</p>
                  </div>
                </div>
              )}
              <Button
                variant="destructive"
                size="icon"
                className="absolute top-2 left-2"
                onClick={handleRemove}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
            <Button
              variant="outline"
              className="w-full mt-3"
              onClick={handleClick}
              disabled={uploading}
            >
              <Upload className="ml-2 h-4 w-4" />
              تغيير الملف
            </Button>
          </CardContent>
        </Card>
      )}

      {error && (
        <p className="text-sm text-red-600 text-center">{error}</p>
      )}
    </div>
  )
}

