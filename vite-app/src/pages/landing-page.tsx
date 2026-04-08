import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  ArrowRight,
  Barcode,
  BookOpen,
  CircleHelp,
  Database,
  Download,
  LayoutGrid,
  Library,
  LogOut,
  Menu,
  ScanLine,
  Smartphone,
  Sparkles,
  User,
  X,
} from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/auth-context";

const APP_DOWNLOAD_ANDROID =
  "https://play.google.com/store/apps/details?id=com.ghiz.bookscanner";
const APP_DOWNLOAD_APK =
  "https://github.com/rehza97/ghiz/raw/main/flutter_application_1/build/app/outputs/flutter-apk/app-release.apk";
const APP_DOWNLOAD_IOS = "https://apps.apple.com/app/id123456789";

const features = [
  {
    icon: Database,
    title: "قاعدة بيانات محلية حقيقية (SQLite)",
    description:
      "كل البيانات محفوظة محلياً: المكتبات، الطوابق، الرفوف، الكتب، المواقع، السجل، والإعدادات.",
  },
  {
    icon: User,
    title: "تهيئة أول تشغيل لأمين المكتبة",
    description:
      "أول تشغيل يبدأ بنموذج التهيئة ثم ينقلك مباشرة إلى لوحة التشغيل بنفس بياناتك.",
  },
  {
    icon: ScanLine,
    title: "مسح باركود + وضع AR عملي",
    description:
      "فحص ISBN وباركود الرفوف، التحقق من المكان الصحيح، وإظهار الأخطاء مباشرة.",
  },
  {
    icon: Barcode,
    title: "طباعة وحفظ ملصقات الباركود",
    description:
      "ملصقات ISBN والرفوف قابلة للطباعة أو الحفظ كصورة داخل المعرض.",
  },
  {
    icon: LayoutGrid,
    title: "بحث قوي مع فلاتر مركبة",
    description:
      "فلترة بالتصنيف والطابق والرف والحالة مع تحميل تدريجي لتحسين الأداء.",
  },
  {
    icon: BookOpen,
    title: "إدخال سريع للكتب/الرفوف/الطوابق",
    description:
      "ISBN تلقائي، قوالب جاهزة، واختصارات إدخال سريعة مع Auto Fill للتجارب.",
  },
];

const modules = [
  {
    title: "الرئيسية",
    summary:
      "لوحة تحكم فورية مع إحصائيات الترتيب، عدد الكتب، وعدد الرفوف والتنبيهات.",
  },
  {
    title: "بحث",
    summary:
      "بحث بالعنوان/المؤلف/ISBN مع تفاصيل الكتاب والملصق والموقع الدقيق.",
  },
  {
    title: "الممسوحة",
    summary: "سجل الكتب التي تم مسحها مع إعادة المسح وتنظيف السجل عند الحاجة.",
  },
  {
    title: "إضافة",
    summary: "إضافة كتاب/رف/طابق بسرعة مع توليد باركود الرف وحفظه كصورة.",
  },
  {
    title: "معلومات",
    summary:
      "تحرير كامل لبيانات المكتبة والطوابق والرفوف + زر تعبئة قاعدة البيانات.",
  },
];

const workflow = [
  "Splash Screen وهوية التطبيق.",
  "تهيئة أول مرة (بيانات أمين المكتبة).",
  "دخول لوحة التشغيل المحلية.",
  "إضافة طوابق ورفوف ثم الكتب وربط المواقع.",
  "تشغيل البحث + فحص AR لمراجعة الترتيب.",
  "FAQ مدمج مع تلميح تلقائي لأول دخول.",
];

export function LandingPage() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { currentUser, adminUser, signOut, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    const onScroll = () => setIsScrolled(window.scrollY > 16);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
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

  const scrollTo = (id: string) => {
    const element = document.getElementById(id);
    if (!element) return;
    element.scrollIntoView({ behavior: "smooth", block: "start" });
    setMobileMenuOpen(false);
  };

  const authAction = currentUser ? (
    <Link to="/admin/overview">
      <Button className="bg-[#1f8f8a] hover:bg-[#167b76] text-white">لوحة التحكم</Button>
    </Link>
  ) : (
    <Link to="/login">
      <Button className="bg-[#1f8f8a] hover:bg-[#167b76] text-white">تسجيل الدخول</Button>
    </Link>
  );

  return (
    <div dir="rtl" className="relative min-h-screen overflow-x-hidden bg-[#f4f8f9] text-slate-900 [font-family:'IBM_Plex_Sans_Arabic','Noto_Sans_Arabic',sans-serif]">
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -top-24 right-[-10%] h-80 w-80 rounded-full bg-[#38ada9]/25 blur-3xl" />
        <div className="absolute top-72 left-[-8%] h-72 w-72 rounded-full bg-[#3c6382]/20 blur-3xl" />
        <div className="absolute bottom-0 right-1/4 h-72 w-72 rounded-full bg-[#88c9c6]/25 blur-3xl" />
      </div>

      <header className={`sticky top-0 z-50 border-b border-white/30 transition-all ${isScrolled ? "bg-white/80 backdrop-blur-xl shadow-sm" : "bg-transparent"}`}>
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div className="h-11 w-11 rounded-xl bg-gradient-to-br from-[#2f9d98] to-[#3c6382] flex items-center justify-center shadow-lg shadow-cyan-900/20">
                <Library className="h-6 w-6 text-white" />
              </div>
              <div>
                <p className="text-lg font-bold leading-tight tracking-tight">DocShelf Eye</p>
                <p className="text-xs text-slate-600">Local-First Library Operations</p>
              </div>
            </div>

            <nav className="hidden md:flex items-center gap-6">
              <button onClick={() => scrollTo("features")} className="text-sm font-medium hover:text-[#1f8f8a]">المميزات</button>
              <button onClick={() => scrollTo("modules")} className="text-sm font-medium hover:text-[#1f8f8a]">الوحدات</button>
              <button onClick={() => scrollTo("download")} className="text-sm font-medium hover:text-[#1f8f8a]">التحميل</button>
              <button onClick={() => scrollTo("faq")} className="text-sm font-medium hover:text-[#1f8f8a]">FAQ</button>

              {!loading && currentUser && (
                <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-white/90 px-3 py-1.5">
                  <User className="h-4 w-4 text-[#1f8f8a]" />
                  <span className="text-xs font-medium">{displayName}</span>
                </div>
              )}

              {!loading && authAction}

              {!loading && currentUser && (
                <Button variant="outline" onClick={handleLogout} className="text-red-600 border-red-200 bg-white/80">
                  <LogOut className="h-4 w-4 ml-2" />
                  خروج
                </Button>
              )}
            </nav>

            <button className="md:hidden p-2" onClick={() => setMobileMenuOpen((v) => !v)}>
              {mobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>

          {mobileMenuOpen && (
            <div className="md:hidden mt-4 rounded-xl border border-slate-200 bg-white/95 p-2 shadow-lg backdrop-blur">
              <button onClick={() => scrollTo("features")} className="block w-full text-right px-3 py-2 rounded-lg hover:bg-slate-100">المميزات</button>
              <button onClick={() => scrollTo("modules")} className="block w-full text-right px-3 py-2 rounded-lg hover:bg-slate-100">الوحدات</button>
              <button onClick={() => scrollTo("download")} className="block w-full text-right px-3 py-2 rounded-lg hover:bg-slate-100">التحميل</button>
              <button onClick={() => scrollTo("faq")} className="block w-full text-right px-3 py-2 rounded-lg hover:bg-slate-100">FAQ</button>
              <div className="mt-2 px-1">{!loading && authAction}</div>
            </div>
          )}
        </div>
      </header>

      <main className="container mx-auto px-4">
        <section className="py-14 md:py-24">
          <div className="grid items-center gap-10 lg:grid-cols-2">
            <div className="space-y-6 reveal-right">
              <div className="inline-flex items-center gap-2 rounded-full border border-[#38ada9]/30 bg-white/70 px-4 py-2 text-sm font-medium text-[#1f8f8a] backdrop-blur reveal-up">
                <Sparkles className="h-4 w-4" />
                نسخة Flutter الفعلية — عرض Landing عالي الجودة
              </div>

              <h1 className="text-4xl font-extrabold leading-tight md:text-6xl reveal-up [animation-delay:120ms]">
                منصة تشغيل مكتبات
                <span className="mt-2 block bg-gradient-to-l from-[#2f9d98] to-[#3c6382] bg-clip-text text-transparent">
                  سريعة، بصرية، ومحلية بالكامل
                </span>
              </h1>

              <p className="max-w-xl text-lg leading-8 text-slate-600 reveal-up [animation-delay:200ms]">
                نسخة Flutter الفعلية بتجربة عرض احترافية، مع هوية بصرية محسّنة
                وتدفّق استخدام أوضح للمكتبات.
              </p>

              <div className="flex flex-wrap items-center gap-3 reveal-up [animation-delay:280ms]">
                {authAction}
                <Button variant="outline" className="bg-white/80" onClick={() => scrollTo("download")}>
                  تنزيل التطبيق
                  <ArrowRight className="mr-2 h-4 w-4" />
                </Button>
              </div>
            </div>

            <div className="relative reveal-left [animation-delay:120ms]">
              <div className="rounded-3xl border border-white/60 bg-white/70 p-5 shadow-2xl shadow-slate-900/10 backdrop-blur-xl">
                <div className="rounded-2xl bg-gradient-to-br from-[#2f9d98] via-[#38ada9] to-[#3c6382] p-5 text-white float-soft">
                  <p className="text-sm text-white/80">نظرة تشغيلية سريعة</p>
                  <h3 className="mt-1 text-2xl font-bold">DocShelf Eye Workflow</h3>
                  <div className="mt-4 grid grid-cols-2 gap-3 text-sm">
                    <div className="rounded-xl bg-white/15 p-3 backdrop-blur">SQLite Local DB</div>
                    <div className="rounded-xl bg-white/15 p-3 backdrop-blur">AR + Barcode</div>
                    <div className="rounded-xl bg-white/15 p-3 backdrop-blur">Advanced Search</div>
                    <div className="rounded-xl bg-white/15 p-3 backdrop-blur">Fast Add Flow</div>
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-3 gap-3">
                  <div className="rounded-xl border border-slate-200 bg-white p-3 text-center">
                    <p className="text-xs text-slate-500">تبويبات</p>
                    <p className="text-xl font-bold text-[#1f8f8a]">5</p>
                  </div>
                  <div className="rounded-xl border border-slate-200 bg-white p-3 text-center">
                    <p className="text-xs text-slate-500">وضع المسح</p>
                    <p className="text-xl font-bold text-[#1f8f8a]">AR</p>
                  </div>
                  <div className="rounded-xl border border-slate-200 bg-white p-3 text-center">
                    <p className="text-xs text-slate-500">البيانات</p>
                    <p className="text-xl font-bold text-[#1f8f8a]">Local</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="scroll-mt-24 py-12 md:py-16">
          <div className="mb-8 text-center reveal-up">
            <h2 className="text-3xl font-extrabold md:text-4xl">مميزات حقيقية من التطبيق</h2>
            <p className="mt-2 text-slate-600">واجهة تسويقية مطابقة للوظائف المنفذة فعلياً.</p>
          </div>

          <div className="grid grid-cols-1 gap-5 md:grid-cols-2 lg:grid-cols-3">
            {features.map((feature, index) => (
              <Card
                key={feature.title}
                style={{ animationDelay: `${100 + index * 90}ms` }}
                className="group reveal-up border-white/70 bg-white/75 shadow-md shadow-slate-900/5 backdrop-blur transition duration-300 hover:-translate-y-1 hover:shadow-xl"
              >
                <CardHeader>
                  <div className="mb-3 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-[#2f9d98] to-[#3c6382] text-white shadow">
                    <feature.icon className="h-5 w-5" />
                  </div>
                  <CardTitle className="text-lg leading-7">{feature.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm leading-7 text-slate-600">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section id="modules" className="scroll-mt-24 py-12 md:py-16">
          <div className="grid gap-6 lg:grid-cols-2">
            <Card className="reveal-right border-0 bg-gradient-to-br from-[#1f8f8a] to-[#3c6382] text-white shadow-xl">
              <CardHeader>
                <CardTitle className="text-2xl">تدفق الاستخدام</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {workflow.map((step, index) => (
                  <div
                    key={step}
                    style={{ animationDelay: `${120 + index * 80}ms` }}
                    className="reveal-up flex items-start gap-3 rounded-xl bg-white/12 p-3 backdrop-blur"
                  >
                    <div className="mt-0.5 inline-flex h-6 w-6 flex-none items-center justify-center rounded-full bg-white/25 text-xs font-bold">
                      {index + 1}
                    </div>
                    <p className="text-sm leading-6 text-white/95">{step}</p>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="reveal-left border-white/70 bg-white/80 shadow-lg backdrop-blur">
              <CardHeader>
                <CardTitle className="text-2xl">الوحدات الرئيسية</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {modules.map((module, index) => (
                  <div
                    key={module.title}
                    style={{ animationDelay: `${140 + index * 85}ms` }}
                    className="reveal-up rounded-xl border border-slate-200 bg-white p-4"
                  >
                    <p className="text-base font-bold text-[#1f6f6b]">{module.title}</p>
                    <p className="mt-1 text-sm leading-6 text-slate-600">{module.summary}</p>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </section>

        <section id="download" className="scroll-mt-24 py-12 md:py-16">
          <Card className="reveal-up overflow-hidden border-0 bg-slate-900 text-white shadow-2xl">
            <CardContent className="p-7 md:p-10">
              <div className="grid items-center gap-8 md:grid-cols-2">
                <div>
                  <p className="text-sm text-cyan-200">جاهز للاستخدام الميداني</p>
                  <h3 className="mt-2 text-3xl font-extrabold">تحميل التطبيق</h3>
                  <p className="mt-3 leading-7 text-slate-300">
                    نفس منطق قاعدة البيانات المحلية وتجربة التشغيل اليومية على Android و iOS.
                  </p>
                  <div className="mt-6 space-y-3">
                    <a
                      href={APP_DOWNLOAD_ANDROID}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-between rounded-xl bg-[#1f8f8a] px-4 py-3 transition hover:bg-[#167b76]"
                    >
                      <span className="inline-flex items-center gap-2 font-medium">
                        <Smartphone className="h-5 w-5" /> Google Play
                      </span>
                      <ArrowRight className="h-4 w-4" />
                    </a>
                    <a
                      href={APP_DOWNLOAD_IOS}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-between rounded-xl bg-[#3c6382] px-4 py-3 transition hover:bg-[#304f66]"
                    >
                      <span className="inline-flex items-center gap-2 font-medium">
                        <Smartphone className="h-5 w-5" /> App Store
                      </span>
                      <ArrowRight className="h-4 w-4" />
                    </a>
                  </div>
                </div>

                <div className="rounded-2xl border border-white/15 bg-white/5 p-5">
                  <div className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-xs text-slate-200">
                    <Download className="h-3.5 w-3.5" /> APK Direct
                  </div>
                  <p className="mt-4 text-sm leading-7 text-slate-300">
                    للتجارب السريعة يمكنك تنزيل APK المباشر. كما يتوفر زر تعبئة قاعدة البيانات داخل التطبيق لتجهيز بيئة اختبار كاملة فوراً.
                  </p>
                  <a
                    href={APP_DOWNLOAD_APK}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-4 inline-flex items-center gap-2 rounded-lg bg-white px-4 py-2 text-sm font-semibold text-slate-900"
                  >
                    تنزيل APK
                    <ArrowRight className="h-4 w-4" />
                  </a>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>

        <section id="faq" className="pb-16 pt-12">
          <Card className="reveal-up border border-white/70 bg-white/85 shadow-lg backdrop-blur">
            <CardContent className="p-7 md:p-9">
              <div className="flex items-center gap-2 text-[#1f8f8a]">
                <CircleHelp className="h-5 w-5" />
                <p className="font-bold">FAQ + Tutorial داخل التطبيق</p>
              </div>
              <p className="mt-3 max-w-3xl leading-7 text-slate-600">
                التطبيق يتضمن FAQ داخلي يشرح التشغيل خطوة بخطوة، مع تلميح تلقائي لأول تشغيل يوجه المستخدم لمكان FAQ. كما يتضمن Splash Screen وهوية المطور داخل التطبيق.
              </p>
              <p className="mt-4 text-sm text-slate-500">
                Developer: <a className="font-semibold text-[#1f8f8a] underline" href="http://dataforgestack.com/" target="_blank" rel="noopener noreferrer">dataforgestack.com</a>
              </p>
            </CardContent>
          </Card>
        </section>
      </main>

      <footer className="border-t border-white/60 bg-white/80 backdrop-blur">
        <div className="container mx-auto flex flex-col items-center justify-between gap-2 px-4 py-6 text-sm text-slate-600 md:flex-row">
          <p>© 2026 DocShelf Eye</p>
          <p>High-end landing synced with real Flutter implementation</p>
        </div>
      </footer>
    </div>
  );
}
