<?php
// ---- Load DB config from environment ----
$host = getenv('DB_HOST');
$db   = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');

echo "<pre>";

try {
    // ---- Connect ----
    $pdo = new PDO(
        "mysql:host=$host;dbname=$db;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "Connected to database\n";

    // ---- CREATE TABLE ----
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS crud_test (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL
        )
    ");
    echo "Table created (or already exists)\n";

    // ---- CREATE  ----
    $stmt = $pdo->prepare("INSERT INTO crud_test (name) VALUES (:name)");
    $stmt->execute(['name' => 'Test Record']);
    $id = $pdo->lastInsertId();
    echo "Inserted record with ID: $id\n";

    // ---- READ ----
    $stmt = $pdo->prepare("SELECT * FROM crud_test WHERE id = :id");
    $stmt->execute(['id' => $id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Read record: " . json_encode($row) . "\n";

    // ---- UPDATE ----
    $stmt = $pdo->prepare("UPDATE crud_test SET name = :name WHERE id = :id");
    $stmt->execute([
        'name' => 'Updated Record',
        'id'   => $id
    ]);
    echo "Updated record\n";

    // ---- DELETE ----
    $stmt = $pdo->prepare("DELETE FROM crud_test WHERE id = :id");
    $stmt->execute(['id' => $id]);
    echo "Deleted record\n";

    // ---- CLEANUP ----
    $pdo->exec("DROP TABLE crud_test");
    echo "Dropped test table\n";

    echo "CRUD test PASSED\n";

} catch (PDOException $e) {
    echo "CRUD test FAILED\n";
    echo $e->getMessage();
}

echo "</pre>";
