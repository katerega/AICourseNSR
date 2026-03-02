<?php
/**
 * PRODUCTION DATABASE CONFIGURATION
 * DO NOT commit to public repositories
 * Store credentials outside webroot in production
 */

// Load from environment variables or secure config file
// DO NOT hardcode in version control
$config_file = '/var/www/secure/db_config.php';
if (file_exists($config_file)) {
    require_once $config_file;
} else {
    // Production credentials - SET THESE ON YOUR SERVER
    define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
    define('DB_PORT', getenv('DB_PORT') ?: '5432');
    define('DB_NAME', getenv('DB_NAME') ?: 'sacco_production');
    define('DB_USER', getenv('DB_USER') ?: 'sacco_admin');
    define('DB_PASS', getenv('DB_PASS') ?: ''); // Must be set in environment
}

// SSL Configuration for production
define('DB_SSL_MODE', getenv('DB_SSL_MODE') ?: 'require');

class Database {
    private static $instance = null;
    private $connection;
    
    private function __construct() {
        try {
            $dsn = sprintf(
                "pgsql:host=%s;port=%s;dbname=%s;sslmode=%s",
                DB_HOST,
                DB_PORT,
                DB_NAME,
                DB_SSL_MODE
            );
            
            $this->connection = new PDO(
                $dsn,
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                    PDO::ATTR_PERSISTENT => true, // Connection pooling
                    PDO::ATTR_TIMEOUT => 5
                ]
            );
        } catch (PDOException $e) {
            // Log error without exposing details
            error_log("Database connection failed: " . $e->getMessage());
            die("System temporarily unavailable. Please try again later.");
        }
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function getConnection() {
        return $this->connection;
    }
}

// Helper function for queries
function db_query($sql, $params = []) {
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    return $stmt;
}

// Connection status for UI
define('DB_CONNECTION_STATUS', Database::getInstance()->getConnection() ? 'Connected' : 'Disconnected');
?>