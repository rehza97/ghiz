/**
 * Shelf Management Component
 * Manage shelves within a floor
 */

import { useState } from 'react'
import { useShelves, useSaveShelf, useUpdateShelf, useShelfBooks, useBook, useAddBookToShelf, useRemoveBookFromShelf, useBooks } from '@/hooks/useFirestore'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { FillTestDataButton } from '@/components/fill-test-data-button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { BookOpen, Plus, Edit, Loader2, Box, BookPlus, Trash2 } from 'lucide-react'
import { useForm } from 'react-hook-form'
import type { Shelf, CreateShelfInput, ShelfBook } from '@/types'

// Component to display a shelf book with book details
function ShelfBookItem({
  shelfBook,
  onRemove,
}: {
  shelfBook: ShelfBook
  onRemove?: (bookIsbn: string) => void
}) {
  const { data: book, isLoading } = useBook(shelfBook.bookIsbn)

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <Loader2 className="h-5 w-5 animate-spin text-[#38ada9]" />
            <span className="text-sm text-gray-600">جاري التحميل...</span>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <BookOpen className="h-5 w-5 text-[#38ada9]" />
            <div>
              <p className="font-medium">{book?.title || 'غير معروف'}</p>
              <p className="text-sm text-gray-600">
                ISBN: {shelfBook.bookIsbn}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge>الموقع: {shelfBook.position}</Badge>
            {onRemove && (
              <Button
                variant="ghost"
                size="sm"
                className="text-red-600 hover:text-red-700"
                onClick={() => onRemove(shelfBook.bookIsbn)}
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

interface ShelfManagementProps {
  libraryId: string
  floorId: string
  floorName: string
}

export function ShelfManagement({ libraryId, floorId, floorName }: ShelfManagementProps) {
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isAddBookDialogOpen, setIsAddBookDialogOpen] = useState(false)
  const [editingShelf, setEditingShelf] = useState<Shelf | null>(null)
  const [selectedShelfId, setSelectedShelfId] = useState<string | null>(null)
  const [addBookIsbn, setAddBookIsbn] = useState('')
  const [addBookPosition, setAddBookPosition] = useState(1)

  const { data: shelves, isLoading, error } = useShelves(libraryId, floorId)
  const { data: shelfBooks } = useShelfBooks(
    libraryId,
    floorId,
    selectedShelfId || ''
  )
  const { data: books } = useBooks()
  const saveShelf = useSaveShelf()
  const updateShelf = useUpdateShelf()
  const addBookToShelf = useAddBookToShelf()
  const removeBookFromShelf = useRemoveBookFromShelf()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CreateShelfInput>()

  const onSubmit = async (data: CreateShelfInput) => {
    try {
      const shelfId = editingShelf?.id || `shelf_${Date.now()}`

      if (editingShelf) {
        await updateShelf.mutateAsync({
          libraryId,
          floorId,
          shelfId,
          data,
        })
      } else {
        await saveShelf.mutateAsync({
          libraryId,
          floorId,
          shelfId,
          data: {
            ...data,
            libraryId,
            floorId,
            currentCount: 0,
            isActive: true,
          },
        })
      }

      setIsDialogOpen(false)
      setEditingShelf(null)
      reset()
    } catch (error) {
      console.error('Error saving shelf:', error)
    }
  }

  const handleEdit = (shelf: Shelf) => {
    setEditingShelf(shelf)
    reset(shelf)
    setIsDialogOpen(true)
  }

  const handleAdd = () => {
    setEditingShelf(null)
    reset({
      name: '',
      x: 0,
      y: 0,
      z: 0,
      width: 100,
      height: 200,
      depth: 30,
      capacity: 50,
    })
    setIsDialogOpen(true)
  }

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
            <span className="mr-3 text-gray-600">جاري تحميل الرفوف...</span>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="text-center text-red-600">
            حدث خطأ أثناء تحميل الرفوف
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div dir="rtl" className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Box className="h-5 w-5 text-[#38ada9]" />
                إدارة الرفوف - {floorName}
              </CardTitle>
              <CardDescription>
                {shelves?.length || 0} رف
              </CardDescription>
            </div>
            <Button
              onClick={handleAdd}
              className="bg-[#38ada9] hover:bg-[#2d8a86]"
            >
              <Plus className="ml-2 h-4 w-4" />
              إضافة رف
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {!shelves || shelves.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Box className="h-12 w-12 mx-auto mb-3 text-gray-300" />
              <p>لا توجد رفوف</p>
              <Button
                variant="outline"
                onClick={handleAdd}
                className="mt-4"
              >
                إضافة الرف الأول
              </Button>
            </div>
          ) : (
            <Tabs defaultValue="list" dir="rtl">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="list">قائمة الرفوف</TabsTrigger>
                <TabsTrigger value="details">التفاصيل</TabsTrigger>
              </TabsList>
              <TabsContent value="list">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-right">الاسم</TableHead>
                      <TableHead className="text-right">الموقع (X, Y, Z)</TableHead>
                      <TableHead className="text-right">الأبعاد</TableHead>
                      <TableHead className="text-right">السعة</TableHead>
                      <TableHead className="text-right">الدقة</TableHead>
                      <TableHead className="text-right">الحالة</TableHead>
                      <TableHead className="text-right">الإجراءات</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {shelves.map((shelf) => (
                      <TableRow
                        key={shelf.id}
                        className="cursor-pointer hover:bg-gray-50"
                        onClick={() => setSelectedShelfId(shelf.id)}
                      >
                        <TableCell className="font-medium">
                          {shelf.name}
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          ({shelf.x}, {shelf.y}, {shelf.z})
                        </TableCell>
                        <TableCell className="text-sm text-gray-600">
                          {shelf.width}×{shelf.height}×{shelf.depth}
                        </TableCell>
                        <TableCell>
                          {shelf.currentCount} / {shelf.capacity}
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={shelf.accuracy >= 90 ? 'default' : 'secondary'}
                            className={
                              shelf.accuracy >= 90
                                ? 'bg-green-100 text-green-800'
                                : 'bg-yellow-100 text-yellow-800'
                            }
                          >
                            {shelf.accuracy}%
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={shelf.isActive ? 'default' : 'secondary'}
                            className={
                              shelf.isActive
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-800'
                            }
                          >
                            {shelf.isActive ? 'نشط' : 'غير نشط'}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={(e) => {
                              e.stopPropagation()
                              handleEdit(shelf)
                            }}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TabsContent>
              <TabsContent value="details">
                {selectedShelfId && shelfBooks ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-semibold">
                        الكتب على الرف ({shelfBooks.length})
                      </h3>
                      <Button
                        size="sm"
                        onClick={() => {
                          setAddBookPosition((shelfBooks?.length ?? 0) + 1)
                          setAddBookIsbn('')
                          setIsAddBookDialogOpen(true)
                        }}
                        className="bg-[#38ada9] hover:bg-[#2d8a86]"
                      >
                        <BookPlus className="h-4 w-4 ml-2" />
                        إضافة كتاب للرف
                      </Button>
                    </div>
                    {shelfBooks.length === 0 ? (
                      <p className="text-gray-500 text-center py-8">
                        لا توجد كتب على هذا الرف. انقر "إضافة كتاب للرف" لإضافة كتب من الفهرس.
                      </p>
                    ) : (
                      <div className="grid gap-2">
                        {shelfBooks.map((shelfBook) => (
                          <ShelfBookItem
                            key={shelfBook.bookIsbn}
                            shelfBook={shelfBook}
                            onRemove={async (bookIsbn) => {
                              if (confirm('إزالة هذا الكتاب من الرف؟')) {
                                try {
                                  await removeBookFromShelf.mutateAsync({
                                    libraryId,
                                    floorId,
                                    shelfId: selectedShelfId,
                                    bookIsbn,
                                  })
                                } catch (e) {
                                  console.error(e)
                                  alert('فشل في إزالة الكتاب')
                                }
                              }
                            }}
                          />
                        ))}
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-gray-500 text-center py-8">
                    اختر رفًا لعرض تفاصيله وإضافة الكتب
                  </p>
                )}
              </TabsContent>
            </Tabs>
          )}
        </CardContent>
      </Card>

      {/* Add/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-[600px]" dir="rtl">
          <DialogHeader>
            <div className="flex items-center justify-between">
              <DialogTitle>
                {editingShelf ? 'تعديل الرف' : 'إضافة رف جديد'}
              </DialogTitle>
              <FillTestDataButton
                formKey="shelf"
                onFill={(data) => {
                  reset({
                    name: String(data.name ?? ''),
                    x: Number(data.x ?? 0),
                    y: Number(data.y ?? 0),
                    z: Number(data.z ?? 0),
                    width: Number(data.width ?? 100),
                    height: Number(data.height ?? 200),
                    depth: Number(data.depth ?? 30),
                    capacity: Number(data.capacity ?? 50),
                    category: String(data.category ?? ''),
                    description: String(data.description ?? ''),
                  })
                }}
              />
            </div>
            <DialogDescription>
              {editingShelf
                ? 'قم بتعديل معلومات الرف'
                : 'أدخل معلومات الرف الجديد'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="name">اسم الرف *</Label>
                <Input
                  id="name"
                  placeholder="مثال: رف أ-1"
                  {...register('name', { required: 'الاسم مطلوب' })}
                />
                {errors.name && (
                  <span className="text-sm text-red-600">
                    {errors.name.message}
                  </span>
                )}
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="x">الموقع X *</Label>
                  <Input
                    id="x"
                    type="number"
                    {...register('x', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="y">الموقع Y *</Label>
                  <Input
                    id="y"
                    type="number"
                    {...register('y', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="z">الموقع Z *</Label>
                  <Input
                    id="z"
                    type="number"
                    {...register('z', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="width">العرض *</Label>
                  <Input
                    id="width"
                    type="number"
                    {...register('width', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="height">الارتفاع *</Label>
                  <Input
                    id="height"
                    type="number"
                    {...register('height', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="depth">العمق *</Label>
                  <Input
                    id="depth"
                    type="number"
                    {...register('depth', {
                      required: 'مطلوب',
                      valueAsNumber: true,
                    })}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="capacity">السعة *</Label>
                  <Input
                    id="capacity"
                    type="number"
                    placeholder="50"
                    {...register('capacity', {
                      required: 'السعة مطلوبة',
                      valueAsNumber: true,
                    })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="category">التصنيف</Label>
                  <Input
                    id="category"
                    placeholder="مثال: علوم"
                    {...register('category')}
                  />
                </div>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="description">الوصف</Label>
                <Textarea
                  id="description"
                  placeholder="وصف الرف..."
                  {...register('description')}
                />
              </div>
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setIsDialogOpen(false)}
              >
                إلغاء
              </Button>
              <Button
                type="submit"
                className="bg-[#38ada9] hover:bg-[#2d8a86]"
                disabled={saveShelf.isPending || updateShelf.isPending}
              >
                {saveShelf.isPending || updateShelf.isPending ? (
                  <>
                    <Loader2 className="ml-2 h-4 w-4 animate-spin" />
                    جاري الحفظ...
                  </>
                ) : editingShelf ? (
                  'تحديث'
                ) : (
                  'إضافة'
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Add Book to Shelf Dialog */}
      <Dialog open={isAddBookDialogOpen} onOpenChange={setIsAddBookDialogOpen}>
        <DialogContent className="sm:max-w-[450px]" dir="rtl">
          <DialogHeader>
            <DialogTitle>إضافة كتاب للرف</DialogTitle>
            <DialogDescription>
              اختر كتاباً من الفهرس وأدخل موقعه على الرف. يجب أن يكون الكتاب مضافاً مسبقاً في قسم الكتب.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="grid gap-2">
              <Label htmlFor="addBookIsbn">اختر الكتاب من الفهرس</Label>
              <select
                id="addBookIsbn"
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                value={addBookIsbn}
                onChange={(e) => setAddBookIsbn(e.target.value)}
              >
                <option value="">-- اختر كتابًا --</option>
                {books?.map((b) => (
                  <option key={b.isbn} value={b.isbn}>
                    {b.title} ({b.isbn})
                  </option>
                ))}
              </select>
              {(!books || books.length === 0) && (
                <p className="text-xs text-amber-600">
                  لا توجد كتب في الفهرس. أضف كتباً من قسم الكتب أولاً.
                </p>
              )}
              <Label className="mt-2">أو أدخل ISBN يدوياً</Label>
              <Input
                placeholder="978-2-07-036002-4"
                value={addBookIsbn}
                onChange={(e) => setAddBookIsbn(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="addBookPosition">الموقع على الرف</Label>
              <Input
                id="addBookPosition"
                type="number"
                min={1}
                value={addBookPosition}
                onChange={(e) => setAddBookPosition(parseInt(e.target.value, 10) || 1)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setIsAddBookDialogOpen(false)}
            >
              إلغاء
            </Button>
            <Button
              className="bg-[#38ada9] hover:bg-[#2d8a86]"
              disabled={!addBookIsbn.trim() || addBookToShelf.isPending}
              onClick={async () => {
                const isbn = addBookIsbn.trim()
                const exists = books?.some((b) => b.isbn === isbn)
                if (!exists) {
                  alert('الكتاب غير موجود في الفهرس. أضف الكتاب أولاً من قسم الكتب.')
                  return
                }
                const alreadyOnShelf = shelfBooks?.some((b) => b.bookIsbn === isbn)
                if (alreadyOnShelf) {
                  alert('الكتاب موجود مسبقاً على هذا الرف.')
                  return
                }
                try {
                  await addBookToShelf.mutateAsync({
                    libraryId,
                    floorId,
                    shelfId: selectedShelfId!,
                    bookIsbn: isbn,
                    position: addBookPosition,
                  })
                  setIsAddBookDialogOpen(false)
                  setAddBookIsbn('')
                  setAddBookPosition((shelfBooks?.length ?? 0) + 2)
                } catch (e) {
                  console.error(e)
                  alert('فشل في إضافة الكتاب للرف')
                }
              }}
            >
              {addBookToShelf.isPending ? (
                <>
                  <Loader2 className="ml-2 h-4 w-4 animate-spin" />
                  جاري الإضافة...
                </>
              ) : (
                'إضافة'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

