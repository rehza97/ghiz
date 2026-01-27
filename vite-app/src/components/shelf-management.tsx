/**
 * Shelf Management Component
 * Manage shelves within a floor
 */

import { useState } from 'react'
import { useShelves, useSaveShelf, useUpdateShelf, useShelfBooks, useBook } from '@/hooks/useFirestore'
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { BookOpen, Plus, Edit, Loader2, Box } from 'lucide-react'
import { useForm } from 'react-hook-form'
import type { Shelf, CreateShelfInput, ShelfBook } from '@/types'

// Component to display a shelf book with book details
function ShelfBookItem({ shelfBook }: { shelfBook: ShelfBook }) {
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
          <Badge>الموقع: {shelfBook.position}</Badge>
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
  const [editingShelf, setEditingShelf] = useState<Shelf | null>(null)
  const [selectedShelfId, setSelectedShelfId] = useState<string | null>(null)

  const { data: shelves, isLoading, error } = useShelves(libraryId, floorId)
  const { data: shelfBooks } = useShelfBooks(
    libraryId,
    floorId,
    selectedShelfId || ''
  )
  const saveShelf = useSaveShelf()
  const updateShelf = useUpdateShelf()

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
                    <h3 className="text-lg font-semibold">
                      الكتب على الرف ({shelfBooks.length})
                    </h3>
                    {shelfBooks.length === 0 ? (
                      <p className="text-gray-500 text-center py-8">
                        لا توجد كتب على هذا الرف
                      </p>
                    ) : (
                      <div className="grid gap-2">
                        {shelfBooks.map((shelfBook) => (
                          <ShelfBookItem key={shelfBook.bookIsbn} shelfBook={shelfBook} />
                        ))}
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-gray-500 text-center py-8">
                    اختر رفًا لعرض تفاصيله
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
            <DialogTitle>
              {editingShelf ? 'تعديل الرف' : 'إضافة رف جديد'}
            </DialogTitle>
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
    </div>
  )
}

