import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { FirebaseStatus } from '@/components/firebase-status'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { 
  LayoutDashboard, 
  BookOpen, 
  Users, 
  Settings, 
  BarChart3, 
  LogOut,
  Database,
  Shield,
  Library,
  TrendingUp,
  Activity,
  AlertCircle,
  CheckCircle2,
  Clock,
  Search,
  Plus,
  Filter,
  Download,
  Eye
} from 'lucide-react'

export function AdminPage() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<'overview' | 'books' | 'users' | 'settings' | 'libraries'>('overview')

  const handleLogout = () => {
    // Add logout logic here
    navigate('/login')
  }

  return (
    <div dir="rtl" className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Professional Header */}
      <header className="border-b bg-white dark:bg-gray-900 shadow-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="h-10 w-10 rounded-lg bg-[#38ada9] flex items-center justify-center">
                <Shield className="h-6 w-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                  لوحة التحكم الإدارية
                </h1>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  نظام إدارة المكتبات
                </p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-right hidden md:block">
                <p className="text-sm font-medium text-gray-900 dark:text-white">مدير النظام</p>
                <p className="text-xs text-gray-600 dark:text-gray-400">admin@example.com</p>
              </div>
              <Button 
                variant="outline" 
                size="sm"
                onClick={handleLogout}
                className="border-red-200 text-red-600 hover:bg-red-50 dark:border-red-800 dark:text-red-400"
              >
                <LogOut className="h-4 w-4 ml-2" />
                تسجيل الخروج
              </Button>
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          {/* Sidebar Navigation */}
          <aside className="lg:col-span-1 space-y-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">القائمة</CardTitle>
              </CardHeader>
              <CardContent className="space-y-1 p-0">
                <Button
                  variant={activeTab === 'overview' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('overview')}
                >
                  <LayoutDashboard className="h-4 w-4 ml-2" />
                  نظرة عامة
                </Button>
                <Button
                  variant={activeTab === 'libraries' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('libraries')}
                >
                  <Library className="h-4 w-4 ml-2" />
                  المكتبات
                </Button>
                <Button
                  variant={activeTab === 'books' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('books')}
                >
                  <BookOpen className="h-4 w-4 ml-2" />
                  الكتب
                </Button>
                <Button
                  variant={activeTab === 'users' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('users')}
                >
                  <Users className="h-4 w-4 ml-2" />
                  المستخدمون
                </Button>
                <Button
                  variant={activeTab === 'settings' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('settings')}
                >
                  <Settings className="h-4 w-4 ml-2" />
                  الإعدادات
                </Button>
              </CardContent>
            </Card>

            {/* Quick Stats */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-base">إحصائيات سريعة</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="p-3 rounded-lg bg-[#38ada9]/10 border border-[#38ada9]/20">
                  <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">إجمالي الكتب</p>
                  <p className="text-2xl font-bold text-[#38ada9]">1,234</p>
                </div>
                <div className="p-3 rounded-lg bg-[#3c6382]/10 border border-[#3c6382]/20">
                  <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">المستخدمون النشطون</p>
                  <p className="text-2xl font-bold text-[#3c6382]">456</p>
                </div>
                <div className="p-3 rounded-lg bg-[#38ada9]/10 border border-[#38ada9]/20">
                  <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">المكتبات</p>
                  <p className="text-2xl font-bold text-[#38ada9]">12</p>
                </div>
              </CardContent>
            </Card>
          </aside>

          {/* Main Content */}
          <main className="lg:col-span-4 space-y-6">
            {activeTab === 'overview' && (
              <>
                <div>
                  <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                    نظرة عامة
                  </h2>
                  <p className="text-gray-600 dark:text-gray-400">
                    مراقبة نظام المكتبة وإدارة العمليات
                  </p>
                </div>

                {/* Stats Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Card className="border hover:shadow-lg transition-shadow">
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium text-gray-600 dark:text-gray-400">
                        إجمالي الكتب
                      </CardTitle>
                      <div className="h-10 w-10 rounded-lg bg-[#38ada9]/10 flex items-center justify-center">
                        <BookOpen className="h-5 w-5 text-[#38ada9]" />
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="text-3xl font-bold text-gray-900 dark:text-white">1,234</div>
                      <div className="flex items-center gap-1 mt-2">
                        <TrendingUp className="h-4 w-4 text-green-600" />
                        <p className="text-xs text-green-600">+12% من الشهر الماضي</p>
                      </div>
                    </CardContent>
                  </Card>

                  <Card className="border hover:shadow-lg transition-shadow">
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium text-gray-600 dark:text-gray-400">
                        المستخدمون النشطون
                      </CardTitle>
                      <div className="h-10 w-10 rounded-lg bg-[#3c6382]/10 flex items-center justify-center">
                        <Users className="h-5 w-5 text-[#3c6382]" />
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="text-3xl font-bold text-gray-900 dark:text-white">456</div>
                      <div className="flex items-center gap-1 mt-2">
                        <TrendingUp className="h-4 w-4 text-green-600" />
                        <p className="text-xs text-green-600">+8% من الشهر الماضي</p>
                      </div>
                    </CardContent>
                  </Card>

                  <Card className="border hover:shadow-lg transition-shadow">
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium text-gray-600 dark:text-gray-400">
                        الإعارات اليوم
                      </CardTitle>
                      <div className="h-10 w-10 rounded-lg bg-[#38ada9]/10 flex items-center justify-center">
                        <BarChart3 className="h-5 w-5 text-[#38ada9]" />
                      </div>
                    </CardHeader>
                    <CardContent>
                      <div className="text-3xl font-bold text-gray-900 dark:text-white">89</div>
                      <div className="flex items-center gap-1 mt-2">
                        <TrendingUp className="h-4 w-4 text-green-600" />
                        <p className="text-xs text-green-600">+23% من أمس</p>
                      </div>
                    </CardContent>
                  </Card>
                </div>

                {/* System Status */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <Card className="border">
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2 text-lg">
                        <Activity className="h-5 w-5 text-[#38ada9]" />
                        حالة النظام
                      </CardTitle>
                      <CardDescription>
                        مراقبة حالة اتصال خدمات Firebase
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <FirebaseStatus />
                    </CardContent>
                  </Card>

                  <Card className="border">
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2 text-lg">
                        <AlertCircle className="h-5 w-5 text-orange-500" />
                        التنبيهات الأخيرة
                      </CardTitle>
                      <CardDescription>
                        أحدث التنبيهات والأنشطة
                      </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="flex items-start gap-3 p-3 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
                        <CheckCircle2 className="h-5 w-5 text-green-600 dark:text-green-400 mt-0.5" />
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-900 dark:text-white">
                            تم إضافة 5 كتب جديدة
                          </p>
                          <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                            منذ ساعتين
                          </p>
                        </div>
                      </div>
                      <div className="flex items-start gap-3 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
                        <Clock className="h-5 w-5 text-blue-600 dark:text-blue-400 mt-0.5" />
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-900 dark:text-white">
                            نسخة احتياطية مجدولة
                          </p>
                          <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                            غداً الساعة 2:00 صباحاً
                          </p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </>
            )}

            {activeTab === 'libraries' && (
              <Card className="border">
                <CardHeader className="flex flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-2xl">إدارة المكتبات</CardTitle>
                    <CardDescription>إدارة المكتبات والمواقع</CardDescription>
                  </div>
                  <Button className="bg-[#38ada9] hover:bg-[#2d8a86]">
                    <Plus className="h-4 w-4 ml-2" />
                    إضافة مكتبة
                  </Button>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center gap-4 p-4 border rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                      <div className="h-12 w-12 rounded-lg bg-[#38ada9] flex items-center justify-center">
                        <Library className="h-6 w-6 text-white" />
                      </div>
                      <div className="flex-1">
                        <h3 className="font-semibold text-gray-900 dark:text-white">المكتبة المركزية</h3>
                        <p className="text-sm text-gray-600 dark:text-gray-400">الطابق الأول - 5 أرفف</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm">
                          <Eye className="h-4 w-4 ml-2" />
                          عرض
                        </Button>
                        <Button variant="outline" size="sm">
                          <Settings className="h-4 w-4 ml-2" />
                          إعدادات
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {activeTab === 'books' && (
              <Card className="border">
                <CardHeader className="flex flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-2xl">إدارة الكتب</CardTitle>
                    <CardDescription>إدارة مجموعة مكتبتك</CardDescription>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button variant="outline" size="sm">
                      <Filter className="h-4 w-4 ml-2" />
                      فلترة
                    </Button>
                    <Button variant="outline" size="sm">
                      <Download className="h-4 w-4 ml-2" />
                      تصدير
                    </Button>
                    <Button className="bg-[#38ada9] hover:bg-[#2d8a86]">
                      <Plus className="h-4 w-4 ml-2" />
                      إضافة كتاب
                    </Button>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center gap-4 p-4 border rounded-lg">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <Search className="h-4 w-4 text-gray-400" />
                          <input
                            type="text"
                            placeholder="ابحث عن كتاب..."
                            className="flex-1 border-0 outline-none bg-transparent text-gray-900 dark:text-white"
                          />
                        </div>
                      </div>
                    </div>
                    <div className="text-center py-12 text-gray-500 dark:text-gray-400">
                      <BookOpen className="h-12 w-12 mx-auto mb-4 opacity-50" />
                      <p>لا توجد كتب لعرضها</p>
                      <p className="text-sm mt-2">ابدأ بإضافة كتاب جديد</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {activeTab === 'users' && (
              <Card className="border">
                <CardHeader className="flex flex-row items-center justify-between">
                  <div>
                    <CardTitle className="text-2xl">إدارة المستخدمين</CardTitle>
                    <CardDescription>إدارة حسابات المستخدمين والصلاحيات</CardDescription>
                  </div>
                  <Button className="bg-[#38ada9] hover:bg-[#2d8a86]">
                    <Plus className="h-4 w-4 ml-2" />
                    إضافة مستخدم
                  </Button>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="text-center py-12 text-gray-500 dark:text-gray-400">
                      <Users className="h-12 w-12 mx-auto mb-4 opacity-50" />
                      <p>لا يوجد مستخدمون لعرضهم</p>
                      <p className="text-sm mt-2">ابدأ بإضافة مستخدم جديد</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {activeTab === 'settings' && (
              <Card className="border">
                <CardHeader>
                  <CardTitle className="text-2xl">إعدادات النظام</CardTitle>
                  <CardDescription>تكوين الإعدادات على مستوى النظام</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="space-y-4">
                    <div>
                      <h3 className="font-semibold text-gray-900 dark:text-white mb-2">إعدادات Firebase</h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        إدارة اتصال قاعدة البيانات والمصادقة
                      </p>
                      <Button variant="outline">
                        <Database className="h-4 w-4 ml-2" />
                        تكوين Firebase
                      </Button>
                    </div>
                    <div className="border-t pt-4">
                      <h3 className="font-semibold text-gray-900 dark:text-white mb-2">إعدادات المكتبة</h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        إدارة مواقع المكتبات والطوابق
                      </p>
                      <Button variant="outline">
                        <Library className="h-4 w-4 ml-2" />
                        إدارة المواقع
                      </Button>
                    </div>
                    <div className="border-t pt-4">
                      <h3 className="font-semibold text-gray-900 dark:text-white mb-2">النسخ الاحتياطي</h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        إعداد النسخ الاحتياطي والمزامنة
                      </p>
                      <Button variant="outline">
                        <Download className="h-4 w-4 ml-2" />
                        إعداد النسخ الاحتياطي
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}
          </main>
        </div>
      </div>
    </div>
  )
}
