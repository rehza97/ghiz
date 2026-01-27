# 📱 Testing Guide - AR Book Scanner App

## 🚀 Quick Start

### 1. Run the App

```bash
flutter run
```

Or run on a specific device:

```bash
flutter run -d 2312BPC51X  # Android device
```

---

## 📋 Step-by-Step Testing Guide

### **Test 1: Library Selection**

1. **Launch the app** - You'll see the Library Selection screen
2. **Test wilaya filter:**

   - Scroll horizontally through wilaya badges
   - Tap "Alger" - Should show only Bibliothèque Nationale d'Algérie
   - Tap "Oran" - Should show only Bibliothèque Municipale d'Oran
   - Tap "Constantine" - Should show only Bibliothèque Universitaire de Constantine
   - Tap "Tous" - Should show all 3 libraries

3. **Select a library:**
   - Tap on "Bibliothèque Nationale d'Algérie"
   - You'll see a confirmation dialog
   - Tap "Continuer"
   - You'll be taken to the Dashboard

---

### **Test 2: Dashboard Navigation**

1. **Check all tabs:**

   - **Accueil (Home):** Shows welcome message, quick actions, stats
   - **Rechercher (Search):** Book search screen
   - **Scannés (Scanned):** History of scanned books
   - **Infos (Info):** Library information

2. **Test Quick Actions:**
   - Tap "Rechercher un livre" → Should switch to Search tab
   - Tap "Scanner des livres" → Should open AR scanning screen
   - Tap "Mes scans" → Should switch to Scanned tab

---

### **Test 3: Book Search**

1. **Navigate to Search tab** (from bottom navigation)
2. **Test search:**

   - Type "Tolkien" → Should show books by J.R.R. Tolkien
   - Type "1984" → Should show "1984" by George Orwell
   - Type "978-2070364008" → Should show "Le Seigneur des Anneaux"

3. **Test category filter:**

   - Scroll through category chips
   - Tap "Fantasy" → Should show only fantasy books
   - Tap "Science-Fiction" → Should show only SF books
   - Tap "Tous" → Should show all books

4. **Test book details:**
   - Tap any book card
   - Should show modal with:
     - Book title, author, category
     - ISBN
     - Floor, shelf, position
     - Status (En place / À ranger)
   - Tap "Localiser" → Shows snackbar
   - Tap "Fermer" → Closes modal

---

### **Test 4: AR Book Scanning** ⭐ **MAIN FEATURE**

#### **Option A: Test with Real Barcodes (Recommended)**

**You need barcode images/QR codes with these ISBNs:**

1. **Valid ISBNs to test (from shelf_004):**

   - `978-2070364008` - Le Seigneur des Anneaux (Correct position)
   - `978-2070113018` - 1984 (Misplaced - needs correction)
   - `978-2080701473` - Le Seigneur de Brume (Misplaced)
   - `978-2070113575` - Fondation (Correct position)

2. **How to get barcodes:**

   - **Online barcode generators:**

     - Visit: https://barcode.tec-it.com/en/EAN13
     - Enter ISBN: `9782070364008` (without dashes)
     - Generate and save image
     - Print or display on another device

   - **QR Code generators:**
     - Visit: https://www.qr-code-generator.com/
     - Enter ISBN as text
     - Generate QR code
     - Display on screen

3. **Testing steps:**
   - From Dashboard → Tap "Scanner des livres"
   - Camera opens
   - Point camera at barcode/QR code
   - **Expected:**
     - Green message: "Book Title détecté ✓"
     - Book appears in bottom panel
     - Status updates: "X books detected"
4. **Test validation:**
   - Scan `978-2070364008` → ✅ Should work (book on shelf_004)
   - Scan `978-2253089698` → ❌ Should show "Ce livre n'est pas sur ce rayon" (book on different shelf)
   - Scan invalid barcode → ❌ Should show "Code-barres non reconnu"
   - Scan same book twice → ⚠️ Should show "Livre déjà scanné"

#### **Option B: Test with Manual Input (For Development)**

If you want to test without physical barcodes, you can temporarily add a manual input button:

**Add this to `ar_book_detection_screen.dart`:**

```dart
// In AppBar actions, add:
IconButton(
  icon: const Icon(Icons.keyboard),
  onPressed: () {
    _showManualInputDialog();
  },
  tooltip: 'Entrer ISBN manuellement',
),

// Add this method:
void _showManualInputDialog() {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Entrer ISBN'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '978-2070364008',
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              _addDetectedBook(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Scanner'),
        ),
      ],
    ),
  );
}
```

---

### **Test 5: AR Correction Flow**

1. **Scan multiple books:**

   - Scan at least 2-3 books from the list above
   - Some should be misplaced (to trigger corrections)

2. **Check bottom panel:**

   - Should show detected books in horizontal list
   - Each book shows: Title, Position, Status badge

3. **Check correction guide:**

   - If books are misplaced, you'll see:
     - Orange box: "X erreur(s) trouvée(s)"
     - "Corriger" button appears

4. **Start correction:**

   - Tap "Corriger" button
   - Opens Book Correction Screen

5. **Test correction screen:**

   - **Progress bar:** Shows completion percentage
   - **Shelf info:** Shows accuracy status
   - **Movement list:**
     - "Mouvements à effectuer" section
     - Each movement card shows:
       - Priority badge (color-coded)
       - Book title
       - Instruction: "Move 'Book' to the right (X positions)"
       - Position chips: "Position 3 → Position 8"
       - "Mark as completed" button

6. **Test completing movements:**

   - Tap "Mark as completed" on a movement
   - **Expected:**
     - Green snackbar: "Mouvement effectué ✓"
     - Card moves to "Mouvements effectués" section
     - Progress bar updates
     - Correct books count increases

7. **Test undo:**

   - Tap "Annuler" button
   - **Expected:**
     - Last completed movement moves back to "remaining"
     - Progress decreases

8. **Test completion:**
   - Complete all movements
   - **Expected:**
     - Progress: 100%
     - Dialog: "Correction Complète! 🎉"
     - Shows total movements made

---

## 📊 Test Data Reference

### **Books on shelf_004 (for testing):**

| ISBN           | Title                   | Current Pos | Expected Pos | Status                     |
| -------------- | ----------------------- | ----------- | ------------ | -------------------------- |
| 978-2070364008 | Le Seigneur des Anneaux | 5           | 5            | ✅ Correct                 |
| 978-2070113018 | 1984                    | 3           | 8            | ❌ Misplaced (5 positions) |
| 978-2080701473 | Le Seigneur de Brume    | 8           | 12           | ❌ Misplaced (4 positions) |
| 978-2070113575 | Fondation               | 2           | 2            | ✅ Correct                 |

### **Books NOT on shelf_004 (for error testing):**

| ISBN           | Title               | Location  |
| -------------- | ------------------- | --------- |
| 978-2253089698 | Orgueil et Préjugés | shelf_005 |
| 978-2259201414 | Les Misérables      | shelf_006 |

---

## 🐛 Common Issues & Solutions

### **Issue: Camera not opening**

- **Solution:** Check camera permissions in device settings
- For Android: `android/app/src/main/AndroidManifest.xml` should have:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```

### **Issue: Barcode not detected**

- **Solution:**
  - Ensure good lighting
  - Hold camera steady
  - Try different angles
  - Use online barcode generator for clear images

### **Issue: "Code-barres non reconnu"**

- **Solution:** Make sure you're using one of the ISBNs from the test data above

### **Issue: "Ce livre n'est pas sur ce rayon"**

- **Solution:** This is expected! The app validates that books belong to the current shelf. Use books from shelf_004.

---

## ✅ Testing Checklist

- [ ] Library selection with wilaya filter works
- [ ] Dashboard navigation between tabs works
- [ ] Book search finds books correctly
- [ ] Category filter works
- [ ] Book details modal shows correct information
- [ ] AR scanning opens camera
- [ ] Barcode detection works (with real/online barcodes)
- [ ] Book validation works (correct/incorrect shelf)
- [ ] Duplicate scan prevention works
- [ ] AR overlay shows detected books
- [ ] Correction guide calculates correctly
- [ ] Correction screen shows movements
- [ ] Marking movements as completed works
- [ ] Progress tracking updates correctly
- [ ] Undo functionality works
- [ ] Completion dialog appears when done

---

## 🎯 Quick Test Scenarios

### **Scenario 1: Perfect Shelf**

1. Scan only books in correct positions
2. Expected: "Tous les livres sont en bon ordre ✓"
3. No correction needed

### **Scenario 2: Misplaced Books**

1. Scan books with errors (1984, Le Seigneur de Brume)
2. Expected: Shows errors, correction guide appears
3. Complete corrections
4. Expected: All books now correct

### **Scenario 3: Mixed Shelf**

1. Scan mix of correct and misplaced books
2. Expected: Shows partial accuracy
3. Correct only misplaced ones
4. Expected: Progress updates incrementally

---

## 📱 Testing on Different Devices

### **Android:**

- Camera permissions should be granted automatically
- Test on physical device (2312BPC51X)

### **iOS:**

- May need to grant camera permissions manually
- Test on physical device (Fetho)

### **Emulator:**

- Camera may not work on emulator
- Use manual input method for testing

---

## 🔧 Debug Mode

To see what's happening:

1. Check console logs when scanning
2. Look for messages like:
   - "Book detected ✓"
   - "Code-barres non reconnu"
   - "Ce livre n'est pas sur ce rayon"

---

## 📝 Notes

- The app uses `shelf_004` by default when opening AR scanning
- All test books should be from `shelf_004` to work properly
- Barcode format: Use ISBN-13 format (13 digits, usually starts with 978)
- For testing, you can use online barcode generators to create scannable images

---

**Happy Testing! 🎉**
