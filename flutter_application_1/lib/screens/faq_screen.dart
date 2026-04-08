import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: const Color(0xFF38ada9),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FaqItem(
            q: 'كيف يعمل التطبيق؟',
            a: 'التطبيق يعتمد على قاعدة بيانات محلية. تضيف الطوابق والرفوف ثم تضيف الكتب وتربطها بمواقعها. بعد ذلك تستخدم البحث والماسح AR لمراجعة الترتيب.',
          ),
          _FaqItem(
            q: 'كيف أضيف كتاب بسرعة؟',
            a: 'من تبويب "إضافة" اختر "إضافة كتاب"، فعّل ISBN التلقائي، اختر الرف السريع ثم اضغط "إضافة سريع".',
          ),
          _FaqItem(
            q: 'كيف أضيف رف أو طابق؟',
            a: 'من تبويب "إضافة" اختر "إضافة رف". يمكن أيضاً الضغط على "إضافة طابق" أولاً ثم إنشاء الرف تحته.',
          ),
          _FaqItem(
            q: 'كيف أستخدم التصحيح بالواقع المعزز؟',
            a: 'من الصفحة الرئيسية اختر "تصحيح الواقع المعزز" ثم اختر الرف. امسح الكتب وشاهد الحالة لمعرفة الكتب التي تحتاج إعادة ترتيب.',
          ),
          _FaqItem(
            q: 'أين أجد صفحة FAQ لاحقاً؟',
            a: 'من الصفحة الرئيسية، في أعلى اليمين، اضغط أيقونة علامة الاستفهام (؟).',
          ),
          _FaqItem(
            q: 'كيف أعبّئ قاعدة البيانات بسرعة للاختبار؟',
            a: 'اذهب إلى صفحة "معلومات" ثم اضغط أيقونة البيانات في أعلى اليمين (Quick Test Data). سيتم إدخال بيانات اختبار كاملة تلقائياً لتجربة التطبيق بسرعة.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.q, required this.a});

  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(q, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              a,
              style: const TextStyle(height: 1.45, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
