import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { FirebaseStatus } from '@/components/firebase-status'
import { LibraryManagement } from '@/components/library-management'
import { BooksManagement } from '@/components/books-management'
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
  Loader2,
} from 'lucide-react'
import { useLibraries, useBooks, useRecentScans } from '@/hooks/useFirestore'

type TabType = 'overview' | 'libraries' | 'books' | 'users' | 'analytics' | 'settings'

export function AdminDashboard() {
  const navigate = useNavigate()
  const [activeTab, setActiveTab] = useState<TabType>('overview')

  // Fetch data for overview
  const { data: libraries, isLoading: librariesLoading } = useLibraries()
  const { data: books, isLoading: booksLoading } = useBooks()
  const { data: recentScans, isLoading: scansLoading } = useRecentScans(
    libraries?.[0]?.id || '',
    10
  )

  const handleLogout = () => {
    // Add logout logic here
    navigate('/login')
  }

  // Calculate statistics
  const totalLibraries = libraries?.length || 0
  const totalBooks = books?.length || 0
  const totalScans = recentScans?.length || 0
  const averageAccuracy =
    recentScans && recentScans.length > 0
      ? recentScans.reduce((sum, scan) => sum + scan.accuracy, 0) / recentScans.length
      : 0

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
                  نظام إدارة المكتبات بتقنية AR
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
                  variant={activeTab === 'analytics' ? 'default' : 'ghost'}
                  className="w-full justify-start h-10"
                  onClick={() => setActiveTab('analytics')}
                >
                  <BarChart3 className="h-4 w-4 ml-2" />
                  التحليلات
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
          </aside>

          {/* Main Content */}
          <main className="lg:col-span-4 space-y-6">
            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Statistics Cards */}
                  <Card>
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">المكتبات</p>
                          {librariesLoading ? (
                            <Loader2 className="h-6 w-6 animate-spin text-[#38ada9] mt-2" />
                          ) : (
                            <p className="text-3xl font-bold text-[#38ada9] mt-1">
                              {totalLibraries}
                            </p>
                          )}
                        </div>
                        <div className="h-12 w-12 rounded-lg bg-[#38ada9]/10 flex items-center justify-center">
                          <Library className="h-6 w-6 text-[#38ada9]" />
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">الكتب</p>
                          {booksLoading ? (
                            <Loader2 className="h-6 w-6 animate-spin text-[#3c6382] mt-2" />
                          ) : (
                            <p className="text-3xl font-bold text-[#3c6382] mt-1">{totalBooks}</p>
                          )}
                        </div>
                        <div className="h-12 w-12 rounded-lg bg-[#3c6382]/10 flex items-center justify-center">
                          <BookOpen className="h-6 w-6 text-[#3c6382]" />
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">عمليات المسح</p>
                          {scansLoading ? (
                            <Loader2 className="h-6 w-6 animate-spin text-blue-600 mt-2" />
                          ) : (
                            <p className="text-3xl font-bold text-blue-600 mt-1">{totalScans}</p>
                          )}
                        </div>
                        <div className="h-12 w-12 rounded-lg bg-blue-600/10 flex items-center justify-center">
                          <Activity className="h-6 w-6 text-blue-600" />
                        </div>
                      </div>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm text-gray-600 dark:text-gray-400">الدقة</p>
                          {scansLoading ? (
                            <Loader2 className="h-6 w-6 animate-spin text-green-600 mt-2" />
                          ) : (
                            <p className="text-3xl font-bold text-green-600 mt-1">
                              {averageAccuracy.toFixed(0)}%
                            </p>
                          )}
                        </div>
                        <div className="h-12 w-12 rounded-lg bg-green-600/10 flex items-center justify-center">
                          <TrendingUp className="h-6 w-6 text-green-600" />
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </div>

                {/* Firebase Status */}
                <Card>
                  <CardHeader>
                    <div className="flex items-center gap-2">
                      <Database className="h-5 w-5 text-[#38ada9]" />
                      <CardTitle>حالة الاتصال بـ Firebase</CardTitle>
                    </div>
                    <CardDescription>
                      مراقبة حالة اتصال خدمات Firebase
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <FirebaseStatus />
                  </CardContent>
                </Card>

                {/* Recent Activity */}
                <Card>
                  <CardHeader>
                    <CardTitle>النشاط الأخير</CardTitle>
                    <CardDescription>آخر عمليات المسح في النظام</CardDescription>
                  </CardHeader>
                  <CardContent>
                    {scansLoading ? (
                      <div className="flex items-center justify-center p-8">
                        <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
                      </div>
                    ) : recentScans && recentScans.length > 0 ? (
                      <div className="space-y-3">
                        {recentScans.slice(0, 5).map((scan) => (
                          <div
                            key={scan.id}
                            className="flex items-center justify-between p-3 rounded-lg border"
                          >
                            <div className="flex items-center gap-3">
                              {scan.accuracy >= 90 ? (
                                <CheckCircle2 className="h-5 w-5 text-green-600" />
                              ) : scan.accuracy >= 70 ? (
                                <Clock className="h-5 w-5 text-yellow-600" />
                              ) : (
                                <AlertCircle className="h-5 w-5 text-red-600" />
                              )}
                              <div>
                                <p className="font-medium text-sm">
                                  مسح {scan.totalScanned} كتاب
                                </p>
                                <p className="text-xs text-gray-600 dark:text-gray-400">
                                  الدقة: {scan.accuracy.toFixed(0)}%
                                </p>
                              </div>
                            </div>
                            <div className="text-xs text-gray-600 dark:text-gray-400">
                              {typeof scan.createdAt === 'string'
                                ? new Date(scan.createdAt).toLocaleDateString('ar-DZ')
                                : 'الآن'}
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-center text-gray-600 dark:text-gray-400 py-8">
                        لا توجد عمليات مسح بعد
                      </p>
                    )}
                  </CardContent>
                </Card>
              </>
            )}

            {/* Libraries Tab */}
            {activeTab === 'libraries' && <LibraryManagement />}

            {/* Books Tab */}
            {activeTab === 'books' && <BooksManagement />}

            {/* Users Tab */}
            {activeTab === 'users' && (
              <Card>
                <CardHeader>
                  <CardTitle>إدارة المستخدمين</CardTitle>
                  <CardDescription>قريباً...</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-600 dark:text-gray-400">
                    ستتوفر ميزة إدارة المستخدمين قريباً
                  </p>
                </CardContent>
              </Card>
            )}

            {/* Analytics Tab */}
            {activeTab === 'analytics' && (
              <Card>
                <CardHeader>
                  <CardTitle>التحليلات والإحصائيات</CardTitle>
                  <CardDescription>قريباً...</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-600 dark:text-gray-400">
                    ستتوفر ميزة التحليلات قريباً
                  </p>
                </CardContent>
              </Card>
            )}

            {/* Settings Tab */}
            {activeTab === 'settings' && (
              <Card>
                <CardHeader>
                  <CardTitle>إعدادات النظام</CardTitle>
                  <CardDescription>قريباً...</CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-gray-600 dark:text-gray-400">ستتوفر ميزة الإعدادات قريباً</p>
                </CardContent>
              </Card>
            )}
          </main>
        </div>
      </div>
    </div>
  )
}

