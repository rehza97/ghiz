/**
 * Analytics Dashboard Component
 * Display analytics data with charts and metrics
 */

import { useState } from "react";
import { useAnalytics } from "@/hooks/useFirestore";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {
  TrendingUp,
  TrendingDown,
  Activity,
  AlertTriangle,
  CheckCircle,
  Loader2,
  Calendar,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface AnalyticsDashboardProps {
  libraryId?: string;
}

export function AnalyticsDashboard({ libraryId }: AnalyticsDashboardProps) {
  // Default to last 7 days
  const today = new Date();
  const lastWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

  const [startDate, setStartDate] = useState(
    lastWeek.toISOString().split("T")[0]
  );
  const [endDate, setEndDate] = useState(today.toISOString().split("T")[0]);

  const {
    data: analytics,
    isLoading,
    error,
  } = useAnalytics(startDate, endDate, libraryId);

  if (isLoading) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="flex items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-[#38ada9]" />
            <span className="mr-3 text-gray-600">جاري تحميل التحليلات...</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="text-center text-red-600">
            حدث خطأ أثناء تحميل التحليلات
          </div>
        </CardContent>
      </Card>
    );
  }

  // Aggregate metrics from all analytics data
  const aggregatedMetrics = analytics?.reduce(
    (acc, item) => ({
      totalScans: acc.totalScans + (item.metrics?.totalScans || 0),
      totalCorrections:
        acc.totalCorrections + (item.metrics?.totalCorrections || 0),
      totalMisplacedBooks:
        acc.totalMisplacedBooks + (item.metrics?.totalMisplacedBooks || 0),
      totalBooksScanned:
        acc.totalBooksScanned + (item.metrics?.totalBooksScanned || 0),
      averageAccuracy:
        (acc.averageAccuracy + (item.metrics?.averageAccuracy || 0)) / 2,
    }),
    {
      totalScans: 0,
      totalCorrections: 0,
      totalMisplacedBooks: 0,
      totalBooksScanned: 0,
      averageAccuracy: 0,
    }
  ) || {
    totalScans: 0,
    totalCorrections: 0,
    totalMisplacedBooks: 0,
    totalBooksScanned: 0,
    averageAccuracy: 0,
  };

  // Prepare data for charts
  const scanTrendData =
    analytics?.map((item) => ({
      date: new Date(item.date).toLocaleDateString("ar-DZ", {
        month: "short",
        day: "numeric",
      }),
      scans: item.metrics?.totalScans || 0,
      corrections: item.metrics?.totalCorrections || 0,
    })) || [];

  const accuracyData =
    analytics?.map((item) => ({
      date: new Date(item.date).toLocaleDateString("ar-DZ", {
        month: "short",
        day: "numeric",
      }),
      accuracy: item.metrics?.averageAccuracy || 0,
    })) || [];

  // Get top misplaced shelves from latest analytics
  const topMisplacedShelves =
    analytics?.[analytics.length - 1]?.topMisplacedShelves || [];

  // Get top scanned books from latest analytics
  const topScannedBooks =
    analytics?.[analytics.length - 1]?.topScannedBooks || [];

  return (
    <div dir="rtl" className="space-y-6">
      {/* Date Range Filter */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5 text-[#38ada9]" />
            فترة التحليل
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="startDate">من تاريخ</Label>
              <Input
                id="startDate"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="endDate">إلى تاريخ</Label>
              <Input
                id="endDate"
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>
            <div className="flex items-end">
              <Button className="bg-[#38ada9] hover:bg-[#2d8a86] w-full">
                تطبيق
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">إجمالي المسح</CardTitle>
            <Activity className="h-4 w-4 text-[#38ada9]" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {aggregatedMetrics.totalScans}
            </div>
            <p className="text-xs text-muted-foreground">
              عملية مسح في الفترة المحددة
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">التصحيحات</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {aggregatedMetrics.totalCorrections}
            </div>
            <p className="text-xs text-muted-foreground">عملية تصحيح مكتملة</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              الكتب في غير مكانها
            </CardTitle>
            <AlertTriangle className="h-4 w-4 text-yellow-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {aggregatedMetrics.totalMisplacedBooks}
            </div>
            <p className="text-xs text-muted-foreground">
              كتاب يحتاج إلى إعادة ترتيب
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">متوسط الدقة</CardTitle>
            {aggregatedMetrics.averageAccuracy >= 90 ? (
              <TrendingUp className="h-4 w-4 text-green-600" />
            ) : (
              <TrendingDown className="h-4 w-4 text-red-600" />
            )}
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {aggregatedMetrics.averageAccuracy.toFixed(1)}%
            </div>
            <p className="text-xs text-muted-foreground">دقة الترتيب</p>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Scan Trend Chart */}
        <Card>
          <CardHeader>
            <CardTitle>اتجاه المسح والتصحيح</CardTitle>
            <CardDescription>
              عدد عمليات المسح والتصحيح خلال الفترة
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={scanTrendData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="scans"
                  stroke="#38ada9"
                  name="المسح"
                  strokeWidth={2}
                />
                <Line
                  type="monotone"
                  dataKey="corrections"
                  stroke="#3c6382"
                  name="التصحيح"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Accuracy Trend Chart */}
        <Card>
          <CardHeader>
            <CardTitle>اتجاه الدقة</CardTitle>
            <CardDescription>متوسط دقة الترتيب خلال الفترة</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={accuracyData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis domain={[0, 100]} />
                <Tooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="accuracy"
                  stroke="#38ada9"
                  name="الدقة %"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Top Misplaced Shelves */}
        <Card>
          <CardHeader>
            <CardTitle>الرفوف الأكثر احتياجًا للتصحيح</CardTitle>
            <CardDescription>أعلى 5 رفوف بها كتب في غير مكانها</CardDescription>
          </CardHeader>
          <CardContent>
            {topMisplacedShelves.length === 0 ? (
              <p className="text-center text-gray-500 py-8">لا توجد بيانات</p>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={topMisplacedShelves}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="shelfName" />
                  <YAxis />
                  <Tooltip />
                  <Bar dataKey="count" fill="#38ada9" name="العدد" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Top Scanned Books */}
        <Card>
          <CardHeader>
            <CardTitle>الكتب الأكثر مسحًا</CardTitle>
            <CardDescription>أعلى 5 كتب تم مسحها</CardDescription>
          </CardHeader>
          <CardContent>
            {topScannedBooks.length === 0 ? (
              <p className="text-center text-gray-500 py-8">لا توجد بيانات</p>
            ) : (
              <div className="space-y-4">
                {topScannedBooks.map((book, index) => (
                  <div
                    key={book.isbn}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex items-center justify-center h-8 w-8 rounded-full bg-[#38ada9] text-white font-bold">
                        {index + 1}
                      </div>
                      <div>
                        <p className="font-medium">{book.title}</p>
                        <p className="text-sm text-gray-600">
                          ISBN: {book.isbn}
                        </p>
                      </div>
                    </div>
                    <Badge className="bg-[#38ada9]">{book.scanCount} مسح</Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
