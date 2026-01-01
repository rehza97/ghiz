/**
 * User Management Component
 * Manage admin users and their permissions
 */

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Users, Plus, Edit, Shield, Loader2, Mail, User } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { useAuth } from '@/contexts/auth-context'

interface AdminUser {
  uid: string
  email: string
  displayName?: string
  role: 'admin' | 'super_admin' | 'librarian'
  libraryId?: string
  isActive: boolean
  createdAt: string
}

export function UserManagement() {
  const { isSuperAdmin } = useAuth()
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingUser, setEditingUser] = useState<AdminUser | null>(null)
  const [users, setUsers] = useState<AdminUser[]>([])
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<{
    email: string
    displayName: string
    role: string
    libraryId?: string
    password?: string
  }>()

  const selectedRole = watch('role')

  const onSubmit = async (data: any) => {
    try {
      setIsLoading(true)
      
      // In a real implementation, this would call Firebase Admin API
      // to create/update the user
      console.log('Creating/updating user:', data)
      
      // For demo purposes, just show a message
      alert(
        'لإنشاء مستخدم جديد، يرجى استخدام سكريبت Firebase Admin:\n\n' +
        `npm run create-admin ${data.email} ${data.password || 'password'} ${data.role} "${data.displayName}"`
      )
      
      setIsDialogOpen(false)
      setEditingUser(null)
      reset()
    } catch (error) {
      console.error('Error saving user:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleEdit = (user: AdminUser) => {
    setEditingUser(user)
    reset({
      email: user.email,
      displayName: user.displayName || '',
      role: user.role,
      libraryId: user.libraryId,
    })
    setIsDialogOpen(true)
  }

  const handleAdd = () => {
    setEditingUser(null)
    reset({
      email: '',
      displayName: '',
      role: 'librarian',
      libraryId: '',
      password: '',
    })
    setIsDialogOpen(true)
  }

  const getRoleBadge = (role: string) => {
    switch (role) {
      case 'super_admin':
        return (
          <Badge className="bg-purple-100 text-purple-800">
            <Shield className="h-3 w-3 ml-1" />
            مدير عام
          </Badge>
        )
      case 'admin':
        return (
          <Badge className="bg-blue-100 text-blue-800">
            <Shield className="h-3 w-3 ml-1" />
            مدير
          </Badge>
        )
      case 'librarian':
        return (
          <Badge className="bg-green-100 text-green-800">
            <User className="h-3 w-3 ml-1" />
            أمين مكتبة
          </Badge>
        )
      default:
        return <Badge>{role}</Badge>
    }
  }

  if (!isSuperAdmin) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="text-center text-red-600">
            ليس لديك صلاحيات الوصول إلى إدارة المستخدمين
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
                <Users className="h-5 w-5 text-[#38ada9]" />
                إدارة المستخدمين
              </CardTitle>
              <CardDescription>
                {users.length} مستخدم
              </CardDescription>
            </div>
            <Button
              onClick={handleAdd}
              className="bg-[#38ada9] hover:bg-[#2d8a86]"
            >
              <Plus className="ml-2 h-4 w-4" />
              إضافة مستخدم
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {users.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Users className="h-12 w-12 mx-auto mb-3 text-gray-300" />
              <p>لا يوجد مستخدمون</p>
              <p className="text-sm mt-2">
                استخدم سكريبت Firebase Admin لإنشاء مستخدمين جدد:
              </p>
              <code className="block mt-2 p-2 bg-gray-100 rounded text-xs">
                npm run create-admin email@example.com password role "Display Name"
              </code>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="text-right">البريد الإلكتروني</TableHead>
                  <TableHead className="text-right">الاسم</TableHead>
                  <TableHead className="text-right">الدور</TableHead>
                  <TableHead className="text-right">المكتبة</TableHead>
                  <TableHead className="text-right">الحالة</TableHead>
                  <TableHead className="text-right">الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.uid}>
                    <TableCell className="font-medium">
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-gray-400" />
                        {user.email}
                      </div>
                    </TableCell>
                    <TableCell>{user.displayName || '-'}</TableCell>
                    <TableCell>{getRoleBadge(user.role)}</TableCell>
                    <TableCell>{user.libraryId || '-'}</TableCell>
                    <TableCell>
                      <Badge
                        variant={user.isActive ? 'default' : 'secondary'}
                        className={
                          user.isActive
                            ? 'bg-green-100 text-green-800'
                            : 'bg-gray-100 text-gray-800'
                        }
                      >
                        {user.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEdit(user)}
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
              {editingUser ? 'تعديل المستخدم' : 'إضافة مستخدم جديد'}
            </DialogTitle>
            <DialogDescription>
              {editingUser
                ? 'قم بتعديل معلومات المستخدم'
                : 'أدخل معلومات المستخدم الجديد'}
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmit(onSubmit)}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="email">البريد الإلكتروني *</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@example.com"
                  {...register('email', { required: 'البريد الإلكتروني مطلوب' })}
                  disabled={!!editingUser}
                />
                {errors.email && (
                  <span className="text-sm text-red-600">
                    {errors.email.message}
                  </span>
                )}
              </div>

              {!editingUser && (
                <div className="grid gap-2">
                  <Label htmlFor="password">كلمة المرور *</Label>
                  <Input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    {...register('password', {
                      required: !editingUser ? 'كلمة المرور مطلوبة' : false,
                      minLength: {
                        value: 6,
                        message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                      },
                    })}
                  />
                  {errors.password && (
                    <span className="text-sm text-red-600">
                      {errors.password.message}
                    </span>
                  )}
                </div>
              )}

              <div className="grid gap-2">
                <Label htmlFor="displayName">الاسم الكامل</Label>
                <Input
                  id="displayName"
                  placeholder="محمد أحمد"
                  {...register('displayName')}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="role">الدور *</Label>
                <Select
                  value={selectedRole}
                  onValueChange={(value) => setValue('role', value)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="اختر الدور" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="super_admin">مدير عام</SelectItem>
                    <SelectItem value="admin">مدير</SelectItem>
                    <SelectItem value="librarian">أمين مكتبة</SelectItem>
                  </SelectContent>
                </Select>
                {errors.role && (
                  <span className="text-sm text-red-600">
                    {errors.role.message}
                  </span>
                )}
              </div>

              {selectedRole === 'librarian' && (
                <div className="grid gap-2">
                  <Label htmlFor="libraryId">معرف المكتبة</Label>
                  <Input
                    id="libraryId"
                    placeholder="lib_001"
                    {...register('libraryId')}
                  />
                  <p className="text-xs text-gray-500">
                    معرف المكتبة التي سيديرها هذا المستخدم
                  </p>
                </div>
              )}

              <div className="bg-blue-50 p-3 rounded-lg">
                <p className="text-sm text-blue-800">
                  💡 ملاحظة: لإنشاء مستخدم جديد، استخدم سكريبت Firebase Admin:
                </p>
                <code className="block mt-2 p-2 bg-white rounded text-xs">
                  npm run create-admin {watch('email') || 'email@example.com'}{' '}
                  {watch('password') || 'password'} {watch('role') || 'role'} "
                  {watch('displayName') || 'Display Name'}"
                </code>
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
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <Loader2 className="ml-2 h-4 w-4 animate-spin" />
                    جاري الحفظ...
                  </>
                ) : editingUser ? (
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

