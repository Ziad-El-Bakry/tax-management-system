<?php
session_start();
require 'db.php'; // استدعاء ملف الاتصال

// لو هو أصلاً مسجل دخول، نوجهه حسب رتبته
if (isset($_SESSION['user_id'])) {
    if ($_SESSION['role'] == 'admin') {
        header("Location: index.php");
    } else {
        header("Location: dashboard.php");
    }
    exit();
}

// معالجة الضغط على زر الدخول
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_input = $_POST['username'];
    $pass_input = $_POST['password'];

    // البحث عن المستخدم في الداتا بيز
    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = :user");
    $stmt->execute(['user' => $user_input]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // التحقق من الباسورد (مقارنة مباشرة عشان إنت مدخل الداتا يدوي)
    // ملحوظة: في المشاريع الحقيقية بنستخدم password_verify
    if ($user && $user['password'] == $pass_input) {
        
        // 1. حفظ البيانات في السيشن
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['role']    = $user['role'];
        $_SESSION['name']    = $user['username'];

        // 2. التوجيه حسب الرتبة
        if ($user['role'] == 'admin') {
            header("Location: index.php");
        } else {
            header("Location: dashboard.php");
        }
        exit();

    } else {
        $error = "اسم المستخدم أو كلمة المرور غير صحيحة!";
    }
}
?>

<!DOCTYPE html>
<html dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>تسجيل الدخول</title>
    <style>
        body { font-family: Tahoma; background-color: #f4f4f9; text-align: center; padding-top: 50px; }
        .login-box { background: white; width: 300px; margin: auto; padding: 20px; border: 1px solid #ccc; border-radius: 10px; }
        input { width: 90%; margin-bottom: 10px; padding: 10px; }
        button { background: #2c3e50; color: white; padding: 10px; width: 100%; border: none; cursor: pointer; }
        .error { color: red; background: #ffdada; padding: 5px; border-radius: 5px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>نظام الضرائب - تسجيل الدخول</h2>
        
        <?php if(isset($error)) echo "<p class='error'>$error</p>"; ?>
        
        <form method="POST">
            <input type="text" name="username" placeholder="اسم المستخدم" required>
            <input type="password" name="password" placeholder="كلمة المرور" required>
            <button type="submit">دخول</button>
        </form>
    </div>
</body>
</html>