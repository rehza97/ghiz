/**
 * Floor Management Component
 * Manage floors within a library
 */

import { useState } from 'react'
import { useFloors, useSaveFloor, useUpdateFloor } from '@/hooks/useFirestore'
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
import { Building2, Plus, Edit, Layers, Loader2, MapPin } from 'lucide-react'
import { useForm } from 'react-hook-form'
import type { Floor, CreateFloorInput } from '@/types'

interface FloorManagementProps {
  libraryId: string
  libraryName: string
}

export function FloorManagement({ libraryId, libraryName }: FloorManagementProps) {
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingFloor, setEditingFloor] = useState<Floor | null>(null)

  const { data: floors, isLoading, error } = useFloors(libraryId)
  const saveFloor = useSaveFloor()
  const updateFloor = useUpdateFloor()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CreateFloorInput>()

  const onSubmit = async (data: CreateFloorInput) => {
    try {
      const floorId = editingFloor?.id || `floor_${Date.now()}`

      if (editingFloor) {
        await updateFloor.mutateAsync({
          libraryId,
          floorId,
          data,
        })
      } else {
        await saveFloor.mutateAsync({
          libraryId,
          floorId,
          data: {
            ...data,
            libraryId,
            shelfCount: 0,
            isActive: true,
          },
        })
      }

      setIsDialogOpen(false)
      setEditingFloor(null)
      reset()
    } catch (error) {
      console.error('Error saving floor:', error)
    }
  }

  const handleEdit = (floor: Floor) => {
    setEditingFloor(floor)
    reset(floor)
    setIsDialogOpen(true)
  }

  const handleAdd = () => {
    setEditingFloor(null)
    reset({
      name: '',
      floorNumber: (floors?.length || 0) + 1,
      description: '',
      mapWidth: 1000,
      mapHeight: 1000,
    })
    setIsDialogOpen(true)
  }

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
            <span className="mr-3 text-gray-600">جاري تحميل الطوابق...</span>
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
            حدث خطأ أثناء تحميل الطوابق
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
                <Building2 className="h-5 w-5 text-[#38ada9]" />
                إدارة الطوابق - {libraryName}
              </CardTitle>
              <CardDescription>
                {floors?.length || 0} طابق
              </CardDescription>
            </div>
            <Button
              onClick={handleAdd}
              className="bg-[#38ada9] hover:bg-[#2d8a86]"
            >
              <Plus className="ml-2 h-4 w-4" />
              إضافة طابق
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {!floors || floors.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Layers className="h-12 w-12 mx-auto mb-3 text-gray-300" />
              <p>لا توجد طوابق</p>
              <Button
                variant="outline"
                onClick={handleAdd}
                className="mt-4"
              >
                إضافة الطابق الأول
              </Button>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="text-right">رقم الطابق</TableHead>
                  <TableHead className="text-right">الاسم</TableHead>
                  <TableHead className="text-right">عدد الرفوف</TableHead>
                  <TableHead className="text-right">الأبعاد</TableHead>
                  <TableHead className="text-right">الحالة</TableHead>
                  <TableHead className="text-right">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {floors.map((floor) => (
                  <TableRow key={floor.id}>
                    <TableCell className="font-medium">
                      {floor.floorNumber}
                    </TableCell>
                    <TableCell>{floor.name}</TableCell>
                    <TableCell>{floor.shelfCount}</TableCell>
                    <TableCell>
                      {floor.mapWidth && floor.mapHeight ? (
                        <span className="text-sm text-gray-600">
                          {floor.mapWidth} × {floor.mapHeight}
                        </span>
                      ) : (
                        <span className="text-sm text-gray-400">غير محدد</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={floor.isActive ? 'default' : 'secondary'}
                        className={
                          floor.isActive
                            ? 'bg-green-100 text-green-800'
                            : 'bg-gray-100 text-gray-800'
                        }
                      >
                        {floor.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEdit(floor)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Add/Edit Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-[500px]" dir="rtl">
          <DialogHeader>
            <DialogTitle>
              {editingFloor ? 'تعديل الطابق' : 'إضافة طابق جديد'}
            </DialogTitle>
            <DialogDescription>
              {editingFloor
                ? 'قم بتعديل معلومات الطابق'
                : 'أدخل معلومات الطابق الجديد'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="name">اسم الطابق *</Label>
                <Input
                  id="name"
                  placeholder="مثال: الطابق الأول"
                  {...register('name', { required: 'الاسم مطلوب' })}
                />
                {errors.name && (
                  <span className="text-sm text-red-600">
                    {errors.name.message}
                  </span>
                )}
              </div>

              <div className="grid gap-2">
                <Label htmlFor="floorNumber">رقم الطابق *</Label>
                <Input
                  id="floorNumber"
                  type="number"
                  {...register('floorNumber', {
                    required: 'رقم الطابق مطلوب',
                    valueAsNumber: true,
                  })}
                />
                {errors.floorNumber && (
                  <span className="text-sm text-red-600">
                    {errors.floorNumber.message}
                  </span>
                )}
              </div>

              <div className="grid gap-2">
                <Label htmlFor="description">الوصف</Label>
                <Textarea
                  id="description"
                  placeholder="وصف الطابق..."
                  {...register('description')}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="mapWidth">عرض الخريطة</Label>
                  <Input
                    id="mapWidth"
                    type="number"
                    placeholder="1000"
                    {...register('mapWidth', { valueAsNumber: true })}
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="mapHeight">ارتفاع الخريطة</Label>
                  <Input
                    id="mapHeight"
                    type="number"
                    placeholder="1000"
                    {...register('mapHeight', { valueAsNumber: true })}
                  />
                </div>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="mapUrl">رابط الخريطة</Label>
                <Input
                  id="mapUrl"
                  type="url"
                  placeholder="https://..."
                  {...register('mapUrl')}
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
                disabled={saveFloor.isPending || updateFloor.isPending}
              >
                {saveFloor.isPending || updateFloor.isPending ? (
                  <>
                    <Loader2 className="ml-2 h-4 w-4 animate-spin" />
                    جاري الحفظ...
                  </>
                ) : editingFloor ? (
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

