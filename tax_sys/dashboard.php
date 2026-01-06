<?php
session_start();
require 'db.php'; // استخدام require بدل include للأمان

// لو مفيش حد عامل دخول، رجعه لصفحة الدخول
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}

$user_id = $_SESSION['user_id'];
$user_name = $_SESSION['name'];

// هات بيانات الضرائب للشخص ده بس
// ملحوظة: بنفترض هنا إن citizen_id في جدول الضرائب هو هو user_id
$stmt = $pdo->prepare("SELECT * FROM tax_returns WHERE citizen_id = :uid");
$stmt->execute(['uid' => $user_id]);
$result = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<!DOCTYPE html>
<html dir="rtl">
<head>
    <title>بياناتي الضريبية</title>
    <style>
        body { font-family: Tahoma; background-color: #f9f9f9; }
        table { width: 80%; margin: 20px auto; border-collapse: collapse; background: white; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: center; }
        th { background-color: #2c3e50; color: white; }
        .welcome { text-align: center; margin-top: 20px; color: #333; }
        .logout { display: inline-block; margin-top: 20px; text-decoration: none; color: white; background: red; padding: 10px 20px; border-radius: 5px;}
    </style>
</head>
<body>
    <div class="welcome">
        <h1>أهلاً بك يا، <?php echo htmlspecialchars($user_name); ?></h1>
        <h3>إقراراتك الضريبية المسجلة:</h3>
    </div>
    
    <table>
        <tr>
            <th>السنة المالية</th>
            <th>الدخل المصرح به</th>
            <th>الضريبة المستحقة</th>
            <th>الحالة</th>
        </tr>
        <?php
        if (count($result) > 0) {
            foreach($result as $row) {
                echo "<tr>";
                // تأكدنا هنا إن الأسماء مطابقة لجدول tax_returns
                echo "<td>" . $row['tax_year'] . "</td>"; 
                echo "<td>" . number_format($row['declared_income']) . " جنية</td>";
                echo "<td>" . number_format($row['tax_amount']) . " جنية</td>";
                echo "<td>" . $row['status'] . "</td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='4'>لا توجد إقرارات مسجلة لهذا الحساب (ID: $user_id)</td></tr>";
        }
        ?>
    </table>
    
    <center>
        <a href="logout.php" class="logout">تسجيل خروج</a>
    </center>
</body>
</html>