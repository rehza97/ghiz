import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { Button } from '@/components/ui/button'
import { FillTestDataButton } from '@/components/fill-test-data-button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Library, Shield, Lock, Mail, ArrowRight, AlertCircle } from 'lucide-react'
import { useAuth } from '@/contexts/auth-context'

const loginSchema = z.object({
  email: z.string().email({
    message: 'يرجى إدخال بريد إلكتروني صحيح',
  }),
  password: z.string().min(6, {
    message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
  }),
})

type LoginFormValues = z.infer<typeof loginSchema>

export function LoginPage() {
  const navigate = useNavigate()
  const { signIn } = useAuth()
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: 'admin@library.dz',
      password: 'Password123!',
    },
  })

  const onSubmit = async (data: LoginFormValues) => {
    setIsLoading(true)
    setError(null)

    try {
      await signIn(data.email, data.password)
      // Navigate to admin dashboard
      navigate('/admin')
    } catch (err: any) {
      setError(err.message || 'فشل تسجيل الدخول. يرجى التحقق من بياناتك والمحاولة مرة أخرى.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div dir="rtl" className="min-h-screen bg-[#38ada9]/5 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo and Title */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center h-16 w-16 rounded-2xl bg-[#38ada9] mb-4 shadow-lg">
            <Library className="h-8 w-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            نظام إدارة المكتبات
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            تسجيل الدخول إلى لوحة التحكم
          </p>
        </div>

        {/* Login Card */}
        <Card className="border-2 shadow-xl">
          <CardHeader className="space-y-1 pb-4">
            <div className="flex items-center gap-2">
              <Shield className="h-5 w-5 text-[#38ada9]" />
              <CardTitle className="text-2xl">تسجيل الدخول</CardTitle>
            </div>
            <CardDescription>
              أدخل بياناتك للوصول إلى لوحة التحكم. البيانات الافتراضية: admin@library.dz / Password123!
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {/* Error Message */}
              {error && (
                <div className="flex items-center gap-2 p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-700 dark:text-red-400">
                  <AlertCircle className="h-4 w-4" />
                  <span className="text-sm">{error}</span>
                </div>
              )}

              {/* Email Field */}
              <div className="space-y-2">
                <Label htmlFor="email" className="flex items-center gap-2">
                  <Mail className="h-4 w-4" />
                  البريد الإلكتروني
                </Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@library.dz"
                  {...register('email')}
                  className="h-11"
                />
                {errors.email && (
                  <p className="text-sm text-red-600 dark:text-red-400">
                    {errors.email.message}
                  </p>
                )}
              </div>

              {/* Fill test data - for easy testing */}
              <FillTestDataButton
                formKey="login"
                onFill={(data) => reset(data as LoginFormValues)}
                className="mb-2"
              />

              {/* Password Field */}
              <div className="space-y-2">
                <Label htmlFor="password" className="flex items-center gap-2">
                  <Lock className="h-4 w-4" />
                  كلمة المرور
                </Label>
                <Input
                  id="password"
                  type="password"
                  placeholder="Password123!"
                  autoComplete="current-password"
                  {...register('password')}
                  className="h-11"
                />
                {errors.password && (
                  <p className="text-sm text-red-600 dark:text-red-400">
                    {errors.password.message}
                  </p>
                )}
              </div>

              {/* Remember Me & Forgot Password */}
              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" className="rounded" />
                  <span className="text-gray-600 dark:text-gray-400">تذكرني</span>
                </label>
                <button
                  type="button"
                  className="text-[#38ada9] hover:text-[#2d8a86] font-medium"
                >
                  نسيت كلمة المرور؟
                </button>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                className="w-full h-11 bg-[#38ada9] hover:bg-[#2d8a86] text-white"
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <div className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                    جاري تسجيل الدخول...
                  </>
                ) : (
                  <>
                    تسجيل الدخول
                    <ArrowRight className="mr-2 h-4 w-4" />
                  </>
                )}
              </Button>
            </form>
          </CardContent>
        </Card>

        {/* Back to Landing */}
        <div className="text-center mt-6">
          <button
            onClick={() => navigate('/')}
            className="text-sm text-gray-600 dark:text-gray-400 hover:text-[#38ada9] transition-colors"
          >
            ← العودة إلى الصفحة الرئيسية
          </button>
        </div>
      </div>
    </div>
  )
}


