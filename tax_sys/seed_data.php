<?php
require 'db.php';

echo "<h1>جاري توليد البيانات...</h1>";

// أسماء وهمية لتركيبها عشوائياً
$first_names = ['محمد', 'أحمد', 'محمود', 'علي', 'عمر', 'يوسف', 'إبراهيم', 'خالد', 'سعيد', 'حسن'];
$last_names = ['السيد', 'علي', 'عبدالله', 'حسن', 'حسين', 'إسماعيل', 'نصر', 'عثمان', 'كامل', 'سالم'];

try {
    $pdo->beginTransaction(); // بدء معاملة لضمان السرعة والأمان

    for ($i = 1; $i <= 100; $i++) {
        // 1. توليد اسم عشوائي
        $name = $first_names[array_rand($first_names)] . ' ' . $last_names[array_rand($last_names)];
        $email = "user" . rand(1000, 9999) . $i . "@example.com";

        // 2. إدخال المواطن
        $stmt = $pdo->prepare("INSERT INTO citizens (full_name, email) VALUES (?, ?)");
        $stmt->execute([$name, $email]);
        $citizen_id = $pdo->lastInsertId();

        // 3. توليد بيانات مالية عشوائية
        $income = rand(30000, 500000); // دخل بين 30 ألف و نصف مليون
        $tax = $income * 0.10; // الضريبة 10%
        $year = rand(2020, 2025);
        $status_options = ['Paid', 'Pending', 'Overdue'];
        $status = $status_options[array_rand($status_options)];

        // 4. إدخال الإقرار الضريبي
        $stmtTax = $pdo->prepare("INSERT INTO tax_returns (citizen_id, tax_year, declared_income, tax_amount, status) VALUES (?, ?, ?, ?, ?)");
        $stmtTax->execute([$citizen_id, $year, $income, $tax, $status]);
    }

    $pdo->commit(); // حفظ التغييرات دفعة واحدة
    echo "<h2 style='color:green'>✅ تم إضافة 100 مواطن وسجلاتهم الضريبية بنجاح!</h2>";
    echo "<a href='index.php'>العودة للوحة التحكم</a>";

} catch (Exception $e) {
    $pdo->rollBack(); // التراجع في حالة الخطأ
    echo "<h2 style='color:red'>حدث خطأ: " . $e->getMessage() . "</h2>";
}
?>
