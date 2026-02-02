import { useState } from 'react'
import { useBooks, useSaveBook, useUpdateBook, useDeleteBook, useSearchBooks } from '@/hooks/useFirestore'
import { StorageService } from '@/services/storage.service'
import { FileUpload } from '@/components/file-upload'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { FillTestDataButton } from '@/components/fill-test-data-button'
import { BookOpen, Plus, Edit, Trash2, Search, Loader2, Filter } from 'lucide-react'
import type { CreateBookInput } from '@/types'

export function BooksManagement() {
  const [searchQuery, setSearchQuery] = useState('')
  const [categoryFilter, setCategoryFilter] = useState<string | undefined>()
  const [showAddForm, setShowAddForm] = useState(false)
  const [editingBook, setEditingBook] = useState<string | null>(null)

  const { data: books, isLoading, error } = useBooks(categoryFilter)
  const { data: searchResults } = useSearchBooks(searchQuery)
  const saveBook = useSaveBook()
  const updateBook = useUpdateBook()
  const deleteBook = useDeleteBook()

  const [formData, setFormData] = useState<CreateBookInput & { isbn: string }>({
    isbn: '',
    title: '',
    author: '',
    category: '',
    language: 'fr',
    isActive: true,
  })

  const displayBooks = searchQuery.length >= 2 ? searchResults : books

  const categories = Array.from(new Set(books?.map((b) => b.category) || []))

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const { isbn, ...bookData } = formData

    try {
      if (editingBook) {
        // Update existing book
        await updateBook.mutateAsync({ isbn, data: bookData })
      } else {
        // Create new book
        await saveBook.mutateAsync({ isbn, data: bookData })
      }
      setShowAddForm(false)
      setEditingBook(null)
      setFormData({
        isbn: '',
        title: '',
        author: '',
        category: '',
        language: 'fr',
        isActive: true,
      })
    } catch (error) {
      console.error('Error saving book:', error)
      alert('فشل في حفظ الكتاب')
    }
  }

  const handleDelete = async (isbn: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا الكتاب؟')) return

    try {
      await deleteBook.mutateAsync(isbn)
    } catch (error) {
      console.error('Error deleting book:', error)
      alert('فشل في حذف الكتاب')
    }
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <p className="text-red-600">خطأ في تحميل الكتب: {String(error)}</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white">إدارة الكتب</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            إدارة الكتب والمعلومات الخاصة بها
          </p>
        </div>
        <Button onClick={() => setShowAddForm(!showAddForm)}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة كتاب جديد
        </Button>
      </div>

      {/* Add/Edit Form */}
      {showAddForm && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>{editingBook ? 'تعديل الكتاب' : 'إضافة كتاب جديد'}</CardTitle>
              <FillTestDataButton
                formKey="book"
                onFill={(data) =>
                  setFormData((prev) => ({
                    ...prev,
                    ...data,
                    pageCount: data.pageCount ? Number(data.pageCount) : undefined,
                    language: (data.language as string) || 'fr',
                  }))
                }
              />
            </div>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="isbn">ISBN *</Label>
                  <Input
                    id="isbn"
                    value={formData.isbn}
                    onChange={(e) => setFormData({ ...formData, isbn: e.target.value })}
                    required
                    disabled={!!editingBook}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="title">العنوان *</Label>
                  <Input
                    id="title"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="author">المؤلف *</Label>
                  <Input
                    id="author"
                    value={formData.author}
                    onChange={(e) => setFormData({ ...formData, author: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="category">التصنيف *</Label>
                  <Input
                    id="category"
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="language">اللغة *</Label>
                  <select
                    id="language"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md"
                    value={formData.language}
                    onChange={(e) => setFormData({ ...formData, language: e.target.value })}
                    required
                  >
                    <option value="fr">Français</option>
                    <option value="ar">العربية</option>
                    <option value="en">English</option>
                  </select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="publisher">الناشر</Label>
                  <Input
                    id="publisher"
                    value={formData.publisher || ''}
                    onChange={(e) => setFormData({ ...formData, publisher: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="publishDate">تاريخ النشر</Label>
                  <Input
                    id="publishDate"
                    value={formData.publishDate || ''}
                    onChange={(e) => setFormData({ ...formData, publishDate: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="pageCount">عدد الصفحات</Label>
                  <Input
                    id="pageCount"
                    type="number"
                    value={formData.pageCount || ''}
                    onChange={(e) =>
                      setFormData({ ...formData, pageCount: parseInt(e.target.value) })
                    }
                  />
                </div>

                <div className="space-y-2 md:col-span-2">
                  <Label>غلاف الكتاب</Label>
                  <FileUpload
                    accept="image/*"
                    maxSize={2}
                    currentUrl={formData.coverUrl}
                    onUpload={async (file) => {
                      const isbn = formData.isbn || 'temp'
                      const url = await StorageService.uploadBookCover(file, isbn)
                      setFormData({ ...formData, coverUrl: url })
                      return url
                    }}
                    onUrlChange={(url) => setFormData({ ...formData, coverUrl: url || undefined })}
                  />
                  <p className="text-xs text-gray-500">أو أدخل رابط الصورة يدوياً</p>
                  <Input
                    id="coverUrl"
                    type="url"
                    placeholder="https://..."
                    value={formData.coverUrl || ''}
                    onChange={(e) => setFormData({ ...formData, coverUrl: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">الوصف</Label>
                <textarea
                  id="description"
                  className="w-full min-h-[100px] px-3 py-2 border border-gray-300 rounded-md"
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>

              <div className="flex gap-2">
                <Button type="submit" disabled={saveBook.isPending || updateBook.isPending}>
                  {(saveBook.isPending || updateBook.isPending) ? (
                    <>
                      <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                      جاري الحفظ...
                    </>
                  ) : editingBook ? (
                    'تحديث'
                  ) : (
                    'حفظ'
                  )}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setShowAddForm(false)
                    setEditingBook(null)
                  }}
                >
                  إلغاء
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Search and Filter */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="relative">
          <Search className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder="البحث عن كتاب (العنوان، المؤلف، ISBN)..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pr-10"
          />
        </div>

        <div className="relative">
          <Filter className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <select
            className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md"
            value={categoryFilter || ''}
            onChange={(e) => setCategoryFilter(e.target.value || undefined)}
          >
            <option value="">جميع التصنيفات</option>
            {categories.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Books List */}
      {isLoading ? (
        <Card>
          <CardContent className="p-6 flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {displayBooks?.map((book) => (
            <Card key={book.isbn} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex items-start gap-3">
                  {book.coverUrl ? (
                    <img
                      src={book.coverUrl}
                      alt={book.title}
                      className="w-16 h-20 object-cover rounded"
                    />
                  ) : (
                    <div className="w-16 h-20 rounded bg-[#38ada9] flex items-center justify-center">
                      <BookOpen className="h-8 w-8 text-white" />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <CardTitle className="text-base line-clamp-2">{book.title}</CardTitle>
                    <CardDescription className="text-xs">{book.author}</CardDescription>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">التصنيف:</span>
                    <span className="font-medium">{book.category}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">ISBN:</span>
                    <span className="font-mono text-xs">{book.isbn}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">اللغة:</span>
                    <span className="font-medium">{book.language.toUpperCase()}</span>
                  </div>
                </div>

                {book.stats && (
                  <div className="grid grid-cols-2 gap-2 pt-3 border-t">
                    <div className="text-center">
                      <p className="text-xs text-gray-600 dark:text-gray-400">النسخ</p>
                      <p className="text-lg font-bold text-[#38ada9]">{book.stats.totalCopies}</p>
                    </div>
                    <div className="text-center">
                      <p className="text-xs text-gray-600 dark:text-gray-400">المسح</p>
                      <p className="text-lg font-bold text-[#38ada9]">{book.stats.scanCount}</p>
                    </div>
                  </div>
                )}

                <div className="flex gap-2 pt-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="flex-1"
                    onClick={() => {
                      setEditingBook(book.isbn)
                      setFormData({
                        isbn: book.isbn,
                        title: book.title,
                        author: book.author,
                        category: book.category,
                        language: book.language,
                        coverUrl: book.coverUrl,
                        description: book.description,
                        publisher: book.publisher,
                        publishDate: book.publishDate,
                        pageCount: book.pageCount,
                        isActive: book.isActive,
                      })
                      setShowAddForm(true)
                    }}
                  >
                    <Edit className="h-4 w-4 ml-1" />
                    تعديل
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="border-red-200 text-red-600 hover:bg-red-50"
                    onClick={() => handleDelete(book.isbn)}
                    disabled={deleteBook.isPending}
                  >
                    <Trash2 className="h-4 w-4 ml-1" />
                    حذف
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {!isLoading && displayBooks?.length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <BookOpen className="h-12 w-12 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery || categoryFilter ? 'لم يتم العثور على كتب' : 'لا توجد كتب بعد'}
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

