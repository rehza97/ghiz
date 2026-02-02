import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Library,
  Search,
  Shield,
  ArrowRight,
  Camera,
  ScanLine,
  MapPin,
  CheckCircle2,
  Globe,
  BarChart3,
  Menu,
  X,
  Download,
  Smartphone,
  Building2,
  Users,
  TrendingUp,
  LogOut,
  User,
} from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/auth-context";

export function LandingPage() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { currentUser, adminUser, signOut, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const handleLogout = async () => {
    try {
      await signOut();
      navigate("/");
    } catch (error) {
      console.error("Logout error:", error);
    }
  };

  const displayName =
    adminUser?.displayName ||
    currentUser?.displayName ||
    currentUser?.email ||
    "المستخدم";

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "start" });
      setMobileMenuOpen(false);
    }
  };

  const androidDownloadUrl =
    "https://play.google.com/store/apps/details?id=com.ghiz.bookscanner";
  const androidApkDirectUrl =
    "https://github.com/rehza97/ghiz/raw/main/flutter_application_1/build/app/outputs/flutter-apk/app-release.apk";
  const iosDownloadUrl = "https://apps.apple.com/app/id123456789";
  const qrCodeValue = androidApkDirectUrl;

  return (
    <div dir="rtl" className="min-h-screen bg-white dark:bg-gray-900">
      {/* Professional Header */}
      <header
        className={`border-b sticky top-0 z-50 transition-all duration-300 ${
          isScrolled
            ? "bg-white dark:bg-gray-900 shadow-md"
            : "bg-white dark:bg-gray-900"
        }`}
      >
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-[#38ada9] flex items-center justify-center">
                <Library className="h-6 w-6 text-white" />
              </div>
              <div>
                <span className="text-lg font-bold text-gray-900 dark:text-white">
                  DocShelf Eye
                </span>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  تطبيق ذكي لإدارة الأرصدة الوثائقية
                </p>
              </div>
            </div>

            {/* Desktop Navigation */}
            <nav className="hidden md:flex items-center gap-8">
              <button
                onClick={() => scrollToSection("features")}
                className="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-[#38ada9] transition-colors"
              >
                المميزات
              </button>
              <button
                onClick={() => scrollToSection("solutions")}
                className="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-[#38ada9] transition-colors"
              >
                الحلول
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-[#38ada9] transition-colors"
              >
                التطبيق
              </button>
              {!loading && (
                <>
                  {currentUser ? (
                    <>
                      <div className="flex items-center gap-3 px-3 py-1.5 rounded-lg bg-gray-100 dark:bg-gray-800">
                        <User className="h-4 w-4 text-[#38ada9]" />
                        <div className="text-right">
                          <p className="text-xs font-medium text-gray-900 dark:text-white">
                            {displayName}
                          </p>
                          {adminUser?.role && (
                            <p className="text-xs text-gray-600 dark:text-gray-400">
                              {adminUser.role === "super_admin"
                                ? "مدير عام"
                                : adminUser.role === "admin"
                                ? "مدير"
                                : "أمين مكتبة"}
                            </p>
                          )}
                        </div>
                      </div>
                      <Link to="/admin">
                        <Button className="bg-[#38ada9] hover:bg-[#2d8a86] text-white">
                          لوحة التحكم
                        </Button>
                      </Link>
                      <Button
                        variant="outline"
                        onClick={handleLogout}
                        className="border-red-200 text-red-600 hover:bg-red-50 dark:border-red-800 dark:text-red-400"
                      >
                        <LogOut className="h-4 w-4 ml-2" />
                        تسجيل الخروج
                      </Button>
                    </>
                  ) : (
                    <>
                      <Link to="/login">
                        <Button
                          variant="outline"
                          className="border-[#38ada9] text-[#38ada9] hover:bg-[#38ada9] hover:text-white"
                        >
                          تسجيل الدخول
                        </Button>
                      </Link>
                      <Link to="/login">
                        <Button className="bg-[#38ada9] hover:bg-[#2d8a86] text-white">
                          لوحة التحكم
                        </Button>
                      </Link>
                    </>
                  )}
                </>
              )}
            </nav>

            {/* Mobile Menu */}
            <button
              className="md:hidden p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? (
                <X className="h-6 w-6 text-gray-900 dark:text-white" />
              ) : (
                <Menu className="h-6 w-6 text-gray-900 dark:text-white" />
              )}
            </button>
          </div>

          {mobileMenuOpen && (
            <nav className="md:hidden mt-4 pb-4 space-y-2 border-t pt-4">
              <button
                onClick={() => scrollToSection("features")}
                className="block w-full text-right px-4 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 font-medium"
              >
                المميزات
              </button>
              <button
                onClick={() => scrollToSection("solutions")}
                className="block w-full text-right px-4 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 font-medium"
              >
                الحلول
              </button>
              <button
                onClick={() => scrollToSection("download")}
                className="block w-full text-right px-4 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 font-medium"
              >
                التطبيق
              </button>
              {!loading && (
                <>
                  {currentUser ? (
                    <>
                      <div className="px-4 py-3 rounded-lg bg-gray-100 dark:bg-gray-800">
                        <div className="flex items-center gap-2 text-right">
                          <User className="h-4 w-4 text-[#38ada9]" />
                          <div>
                            <p className="text-sm font-medium text-gray-900 dark:text-white">
                              {displayName}
                            </p>
                            {adminUser?.role && (
                              <p className="text-xs text-gray-600 dark:text-gray-400">
                                {adminUser.role === "super_admin"
                                  ? "مدير عام"
                                  : adminUser.role === "admin"
                                  ? "مدير"
                                  : "أمين مكتبة"}
                              </p>
                            )}
                          </div>
                        </div>
                      </div>
                      <Link to="/admin" className="block">
                        <Button className="w-full mt-2 bg-[#38ada9] hover:bg-[#2d8a86] text-white">
                          لوحة التحكم
                        </Button>
                      </Link>
                      <Button
                        variant="outline"
                        onClick={handleLogout}
                        className="w-full mt-2 border-red-200 text-red-600 hover:bg-red-50"
                      >
                        <LogOut className="h-4 w-4 ml-2" />
                        تسجيل الخروج
                      </Button>
                    </>
                  ) : (
                    <Link to="/login" className="block">
                      <Button className="w-full mt-2" variant="outline">
                        تسجيل الدخول
                      </Button>
                    </Link>
                  )}
                </>
              )}
            </nav>
          )}
        </div>
      </header>

      <div className="container mx-auto px-4">
        {/* Hero Section - Business Professional */}
        <section className="py-20 md:py-32">
          <div className="max-w-5xl mx-auto text-center space-y-8">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#38ada9]/10 text-[#38ada9] text-sm font-medium border border-[#38ada9]/20">
              <Building2 className="h-4 w-4" />
              حلول احترافية للمكتبات
            </div>
            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold text-gray-900 dark:text-white leading-tight">
              نظام إدارة مكتبات
              <span className="block mt-2 text-[#38ada9]">متكامل وذكي</span>
            </h1>
            <p className="text-xl md:text-2xl text-gray-600 dark:text-gray-400 max-w-3xl mx-auto leading-relaxed">
              حل شامل لإدارة المكتبات باستخدام أحدث تقنيات الواقع المعزز والذكاء
              الاصطناعي. زد من كفاءة عملياتك وحسّن تجربة المستخدمين.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-6">
              {currentUser ? (
                <Link to="/admin">
                  <Button
                    size="lg"
                    className="text-lg px-8 h-12 bg-[#38ada9] hover:bg-[#2d8a86] text-white"
                  >
                    انتقل إلى لوحة التحكم
                    <ArrowRight className="mr-2 h-5 w-5" />
                  </Button>
                </Link>
              ) : (
                <Link to="/login">
                  <Button
                    size="lg"
                    className="text-lg px-8 h-12 bg-[#38ada9] hover:bg-[#2d8a86] text-white"
                  >
                    ابدأ الآن
                    <ArrowRight className="mr-2 h-5 w-5" />
                  </Button>
                </Link>
              )}
              <Button
                size="lg"
                variant="outline"
                className="text-lg px-8 h-12 border-2 border-gray-300 dark:border-gray-700"
              >
                طلب عرض توضيحي
              </Button>
            </div>
          </div>
        </section>

        {/* Stats Section */}
        <section className="py-16 border-y bg-gray-50 dark:bg-gray-800/50">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-6xl mx-auto">
            <div className="text-center">
              <div className="text-4xl font-bold text-[#38ada9] mb-2">500+</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                مكتبة نشطة
              </div>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-[#38ada9] mb-2">50K+</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                كتاب مُدار
              </div>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-[#38ada9] mb-2">10K+</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                مستخدم نشط
              </div>
            </div>
            <div className="text-center">
              <div className="text-4xl font-bold text-[#38ada9] mb-2">99%</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                معدل الرضا
              </div>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <section id="features" className="py-20 scroll-mt-20">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-4">
                مميزات النظام
              </h2>
              <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
                أدوات قوية مصممة لتحسين إدارة المكتبات
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#38ada9] flex items-center justify-center mb-4">
                    <Camera className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">
                    اكتشاف بالواقع المعزز
                  </CardTitle>
                  <CardDescription>
                    تصور ترتيب الكتب واكتشاف الأخطاء في الوقت الفعلي
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#3c6382] flex items-center justify-center mb-4">
                    <ScanLine className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">مسح ذكي</CardTitle>
                  <CardDescription>
                    مسح سريع ودقيق للرموز الشريطية باستخدام الذكاء الاصطناعي
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#38ada9] flex items-center justify-center mb-4">
                    <Search className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">بحث متقدم</CardTitle>
                  <CardDescription>
                    نظام بحث ذكي يدعم الفلترة المتعددة والبحث السريع
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#3c6382] flex items-center justify-center mb-4">
                    <MapPin className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">تتبع دقيق</CardTitle>
                  <CardDescription>
                    تتبع موقع كل كتاب بدقة عالية - طابق، رف، وموضع
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#38ada9] flex items-center justify-center mb-4">
                    <CheckCircle2 className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">تصحيح تلقائي</CardTitle>
                  <CardDescription>
                    نظام تصحيح ذكي يرشدك لإصلاح الأخطاء خطوة بخطوة
                  </CardDescription>
                </CardHeader>
              </Card>

              <Card className="border hover:border-[#38ada9] transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="h-12 w-12 rounded-lg bg-[#3c6382] flex items-center justify-center mb-4">
                    <Globe className="h-6 w-6 text-white" />
                  </div>
                  <CardTitle className="text-xl">إدارة متعددة</CardTitle>
                  <CardDescription>
                    إدارة عدة مكتبات من منصة واحدة مع فصل البيانات
                  </CardDescription>
                </CardHeader>
              </Card>
            </div>
          </div>
        </section>

        {/* Solutions Section */}
        <section
          id="solutions"
          className="py-20 bg-gray-50 dark:bg-gray-800/50 scroll-mt-20"
        >
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-4">
                حلول مصممة لاحتياجاتك
              </h2>
              <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
                نظام شامل يلبي احتياجات جميع أنواع المكتبات
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <Card className="border-2 p-8">
                <CardHeader className="p-0 mb-6">
                  <div className="h-16 w-16 rounded-xl bg-[#38ada9] flex items-center justify-center mb-4">
                    <Building2 className="h-8 w-8 text-white" />
                  </div>
                  <CardTitle className="text-2xl">للمكتبات الكبيرة</CardTitle>
                  <CardDescription className="text-base">
                    حل متكامل للمكتبات الجامعية والوطنية
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-0 space-y-3">
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      إدارة آلاف الكتب بكفاءة
                    </span>
                  </div>
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      تقارير وتحليلات متقدمة
                    </span>
                  </div>
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      دعم متعدد المستخدمين
                    </span>
                  </div>
                </CardContent>
              </Card>

              <Card className="border-2 p-8">
                <CardHeader className="p-0 mb-6">
                  <div className="h-16 w-16 rounded-xl bg-[#3c6382] flex items-center justify-center mb-4">
                    <Users className="h-8 w-8 text-white" />
                  </div>
                  <CardTitle className="text-2xl">للمكتبات الصغيرة</CardTitle>
                  <CardDescription className="text-base">
                    حل بسيط وفعال للمكتبات المدرسية والخاصة
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-0 space-y-3">
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      سهولة الاستخدام والتركيب
                    </span>
                  </div>
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      تكلفة منخفضة
                    </span>
                  </div>
                  <div className="flex items-start gap-3">
                    <CheckCircle2 className="h-5 w-5 text-[#38ada9] mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700 dark:text-gray-300">
                      دعم فني مخصص
                    </span>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </section>

        {/* Download Section */}
        <section id="download" className="py-20 scroll-mt-20">
          <div className="max-w-4xl mx-auto">
            <Card className="border-2 shadow-xl">
              <CardHeader className="text-center space-y-4 pb-8">
                <div className="flex justify-center">
                  <div className="h-20 w-20 rounded-2xl bg-[#38ada9] flex items-center justify-center shadow-lg">
                    <Download className="h-10 w-10 text-white" />
                  </div>
                </div>
                <CardTitle className="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white">
                  حمّل التطبيق الآن
                </CardTitle>
                <CardDescription className="text-lg text-gray-600 dark:text-gray-400">
                  متوفر على جميع المنصات
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
                  <div className="flex flex-col items-center space-y-4">
                    <div className="bg-white p-4 rounded-xl shadow-lg">
                      <img
                        src={`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(
                          qrCodeValue
                        )}`}
                        alt="QR Code"
                        className="w-44 h-44"
                      />
                    </div>
                    <p className="text-sm text-gray-600 dark:text-gray-400 font-medium">
                      امسح الرمز للتحميل
                    </p>
                  </div>

                  <div className="space-y-4">
                    <a
                      href={androidDownloadUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-4 p-5 bg-[#38ada9] hover:bg-[#2d8a86] text-white rounded-xl shadow-lg transition-all"
                    >
                      <Smartphone className="h-8 w-8" />
                      <div className="text-right flex-1">
                        <div className="text-sm opacity-90">احصل عليه على</div>
                        <div className="text-lg font-bold">Google Play</div>
                      </div>
                      <ArrowRight className="h-5 w-5" />
                    </a>

                    <a
                      href={iosDownloadUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-4 p-5 bg-[#3c6382] hover:bg-[#2f4d66] text-white rounded-xl shadow-lg transition-all"
                    >
                      <Smartphone className="h-8 w-8" />
                      <div className="text-right flex-1">
                        <div className="text-sm opacity-90">احصل عليه على</div>
                        <div className="text-lg font-bold">App Store</div>
                      </div>
                      <ArrowRight className="h-5 w-5" />
                    </a>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </section>

        {/* Business Benefits */}
        <section className="py-20 bg-gray-50 dark:bg-gray-800/50">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-4">
                فوائد تجارية حقيقية
              </h2>
              <p className="text-xl text-gray-600 dark:text-gray-400">
                استثمر في نظام يزيد من إنتاجيتك
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div className="text-center p-6">
                <div className="h-16 w-16 rounded-full bg-[#38ada9] flex items-center justify-center mx-auto mb-4">
                  <TrendingUp className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
                  زيادة الكفاءة
                </h3>
                <p className="text-gray-600 dark:text-gray-400">
                  قلل الوقت المستغرق في البحث عن الكتب بنسبة 80%
                </p>
              </div>

              <div className="text-center p-6">
                <div className="h-16 w-16 rounded-full bg-[#3c6382] flex items-center justify-center mx-auto mb-4">
                  <Shield className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
                  أمان عالي
                </h3>
                <p className="text-gray-600 dark:text-gray-400">
                  حماية بياناتك مع تشفير متقدم ونسخ احتياطي تلقائي
                </p>
              </div>

              <div className="text-center p-6">
                <div className="h-16 w-16 rounded-full bg-[#38ada9] flex items-center justify-center mx-auto mb-4">
                  <BarChart3 className="h-8 w-8 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
                  تحليلات ذكية
                </h3>
                <p className="text-gray-600 dark:text-gray-400">
                  تقارير مفصلة تساعدك على اتخاذ قرارات مدروسة
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-20">
          <div className="max-w-4xl mx-auto text-center space-y-8 bg-[#38ada9] rounded-2xl p-12 text-white">
            <h2 className="text-3xl md:text-4xl font-bold">جاهز للبدء؟</h2>
            <p className="text-xl text-white/90 max-w-2xl mx-auto">
              انضم إلى مئات المكتبات التي تستخدم نظامنا لإدارة مجموعاتها
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              {currentUser ? (
                <Link to="/admin">
                  <Button
                    size="lg"
                    className="text-lg px-8 h-12 bg-white text-[#38ada9] hover:bg-white/90"
                  >
                    انتقل إلى لوحة التحكم
                    <ArrowRight className="mr-2 h-5 w-5" />
                  </Button>
                </Link>
              ) : (
                <Link to="/login">
                  <Button
                    size="lg"
                    className="text-lg px-8 h-12 bg-white text-[#38ada9] hover:bg-white/90"
                  >
                    تسجيل الدخول
                    <ArrowRight className="mr-2 h-5 w-5" />
                  </Button>
                </Link>
              )}
              <Button
                size="lg"
                variant="outline"
                className="text-lg px-8 h-12 border-2 border-white text-white hover:bg-white/10"
              >
                طلب عرض توضيحي
              </Button>
            </div>
          </div>
        </section>
      </div>

      {/* Professional Footer */}
      <footer className="border-t bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4 py-12">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <Library className="h-6 w-6 text-[#38ada9]" />
                <span className="text-lg font-bold text-gray-900 dark:text-white">
                  DocShelf Eye
                </span>
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                حل شامل لإدارة المكتبات باستخدام أحدث التقنيات
              </p>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-gray-900 dark:text-white">
                المنتج
              </h4>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>المميزات</li>
                <li>التسعير</li>
                <li>التوثيق</li>
                <li>API</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-gray-900 dark:text-white">
                الدعم
              </h4>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>مركز المساعدة</li>
                <li>التواصل معنا</li>
                <li>الدعم الفني</li>
                <li>الأسئلة الشائعة</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4 text-gray-900 dark:text-white">
                الشركة
              </h4>
              <ul className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                <li>من نحن</li>
                <li>المدونة</li>
                <li>الوظائف</li>
                <li>الخصوصية</li>
              </ul>
            </div>
          </div>

          <div className="border-t mt-12 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              © 2026 DocShelf Eye. جميع الحقوق محفوظة.
            </p>
            <div className="flex gap-6 text-sm text-gray-600 dark:text-gray-400">
              <button>الشروط</button>
              <button>الخصوصية</button>
              <button>ملفات تعريف الارتباط</button>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
