import { useState } from 'react'
import { useLibraries, useSaveLibrary, useDeleteLibrary } from '@/hooks/useFirestore'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  Library,
  Building2,
  MapPin,
  Phone,
  Mail,
  Plus,
  Edit,
  Trash2,
  Search,
  Loader2,
} from 'lucide-react'
import type { CreateLibraryInput } from '@/types'

export function LibraryManagement() {
  const [searchQuery, setSearchQuery] = useState('')
  const [showAddForm, setShowAddForm] = useState(false)
  const [editingLibrary, setEditingLibrary] = useState<string | null>(null)

  const { data: libraries, isLoading, error } = useLibraries()
  const saveLibrary = useSaveLibrary()
  const deleteLibrary = useDeleteLibrary()

  const [formData, setFormData] = useState<CreateLibraryInput>({
    name: '',
    address: '',
    postalCode: '',
    city: '',
    floorCount: 1,
    latitude: 0,
    longitude: 0,
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const libraryId = editingLibrary || `lib_${Date.now()}`

    try {
      await saveLibrary.mutateAsync({ libraryId, data: formData })
      setShowAddForm(false)
      setEditingLibrary(null)
      setFormData({
        name: '',
        address: '',
        postalCode: '',
        city: '',
        floorCount: 1,
        latitude: 0,
        longitude: 0,
      })
    } catch (error) {
      console.error('Error saving library:', error)
      alert('فشل في حفظ المكتبة')
    }
  }

  const handleDelete = async (libraryId: string) => {
    if (!confirm('هل أنت متأكد من حذف هذه المكتبة؟')) return

    try {
      await deleteLibrary.mutateAsync(libraryId)
    } catch (error) {
      console.error('Error deleting library:', error)
      alert('فشل في حذف المكتبة')
    }
  }

  const filteredLibraries = libraries?.filter(
    (lib) =>
      lib.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lib.city.toLowerCase().includes(searchQuery.toLowerCase())
  )

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <p className="text-red-600">خطأ في تحميل المكتبات: {String(error)}</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white">إدارة المكتبات</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            إدارة المكتبات والمعلومات الخاصة بها
          </p>
        </div>
        <Button onClick={() => setShowAddForm(!showAddForm)}>
          <Plus className="h-4 w-4 ml-2" />
          إضافة مكتبة جديدة
        </Button>
      </div>

      {/* Add/Edit Form */}
      {showAddForm && (
        <Card>
          <CardHeader>
            <CardTitle>{editingLibrary ? 'تعديل المكتبة' : 'إضافة مكتبة جديدة'}</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">اسم المكتبة *</Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="city">المدينة *</Label>
                  <Input
                    id="city"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="address">العنوان *</Label>
                  <Input
                    id="address"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="postalCode">الرمز البريدي *</Label>
                  <Input
                    id="postalCode"
                    value={formData.postalCode}
                    onChange={(e) => setFormData({ ...formData, postalCode: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="phone">الهاتف</Label>
                  <Input
                    id="phone"
                    type="tel"
                    value={formData.phone || ''}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="email">البريد الإلكتروني</Label>
                  <Input
                    id="email"
                    type="email"
                    value={formData.email || ''}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="floorCount">عدد الطوابق *</Label>
                  <Input
                    id="floorCount"
                    type="number"
                    min="1"
                    value={formData.floorCount}
                    onChange={(e) =>
                      setFormData({ ...formData, floorCount: parseInt(e.target.value) })
                    }
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="hours">ساعات العمل</Label>
                  <Input
                    id="hours"
                    value={formData.hours || ''}
                    onChange={(e) => setFormData({ ...formData, hours: e.target.value })}
                    placeholder="الأحد-الخميس: 8ص-5م"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="latitude">خط العرض *</Label>
                  <Input
                    id="latitude"
                    type="number"
                    step="0.000001"
                    value={formData.latitude}
                    onChange={(e) =>
                      setFormData({ ...formData, latitude: parseFloat(e.target.value) })
                    }
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="longitude">خط الطول *</Label>
                  <Input
                    id="longitude"
                    type="number"
                    step="0.000001"
                    value={formData.longitude}
                    onChange={(e) =>
                      setFormData({ ...formData, longitude: parseFloat(e.target.value) })
                    }
                    required
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
                <Button type="submit" disabled={saveLibrary.isPending}>
                  {saveLibrary.isPending ? (
                    <>
                      <Loader2 className="h-4 w-4 ml-2 animate-spin" />
                      جاري الحفظ...
                    </>
                  ) : (
                    'حفظ'
                  )}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setShowAddForm(false)
                    setEditingLibrary(null)
                  }}
                >
                  إلغاء
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Search */}
      <div className="relative">
        <Search className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
        <Input
          placeholder="البحث عن مكتبة..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="pr-10"
        />
      </div>

      {/* Libraries List */}
      {isLoading ? (
        <Card>
          <CardContent className="p-6 flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredLibraries?.map((library) => (
            <Card key={library.id} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-2">
                    <div className="h-10 w-10 rounded-lg bg-[#38ada9] flex items-center justify-center">
                      <Library className="h-5 w-5 text-white" />
                    </div>
                    <div>
                      <CardTitle className="text-lg">{library.name}</CardTitle>
                      <CardDescription className="text-xs">{library.city}</CardDescription>
                    </div>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                    <MapPin className="h-4 w-4" />
                    <span>{library.address}</span>
                  </div>
                  {library.phone && (
                    <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                      <Phone className="h-4 w-4" />
                      <span>{library.phone}</span>
                    </div>
                  )}
                  {library.email && (
                    <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                      <Mail className="h-4 w-4" />
                      <span>{library.email}</span>
                    </div>
                  )}
                  <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                    <Building2 className="h-4 w-4" />
                    <span>{library.floorCount} طوابق</span>
                  </div>
                </div>

                {library.stats && (
                  <div className="grid grid-cols-3 gap-2 pt-3 border-t">
                    <div className="text-center">
                      <p className="text-xs text-gray-600 dark:text-gray-400">الكتب</p>
                      <p className="text-lg font-bold text-[#38ada9]">
                        {library.stats.totalBooks}
                      </p>
                    </div>
                    <div className="text-center">
                      <p className="text-xs text-gray-600 dark:text-gray-400">الرفوف</p>
                      <p className="text-lg font-bold text-[#38ada9]">
                        {library.stats.totalShelves}
                      </p>
                    </div>
                    <div className="text-center">
                      <p className="text-xs text-gray-600 dark:text-gray-400">الطوابق</p>
                      <p className="text-lg font-bold text-[#38ada9]">
                        {library.stats.totalFloors}
                      </p>
                    </div>
                  </div>
                )}

                <div className="flex gap-2 pt-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="flex-1"
                    onClick={() => {
                      setEditingLibrary(library.id)
                      setFormData({
                        name: library.name,
                        address: library.address,
                        postalCode: library.postalCode,
                        city: library.city,
                        phone: library.phone,
                        email: library.email,
                        floorCount: library.floorCount,
                        latitude: library.latitude,
                        longitude: library.longitude,
                        hours: library.hours,
                        description: library.description,
                        logoUrl: library.logoUrl,
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
                    onClick={() => handleDelete(library.id)}
                    disabled={deleteLibrary.isPending}
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

      {!isLoading && filteredLibraries?.length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <Library className="h-12 w-12 mx-auto text-gray-400 mb-4" />
            <p className="text-gray-600 dark:text-gray-400">
              {searchQuery ? 'لم يتم العثور على مكتبات' : 'لا توجد مكتبات بعد'}
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

