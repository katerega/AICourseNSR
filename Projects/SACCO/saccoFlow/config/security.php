<?php
/**
 * PRODUCTION SECURITY CONFIGURATION
 * No placeholders - Real security implementation
 */

// CSRF Protection
function generateCSRFToken() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function validateCSRFToken($token) {
    if (!isset($_SESSION['csrf_token']) || $token !== $_SESSION['csrf_token']) {
        error_log("CSRF validation failed - possible attack");
        http_response_code(403);
        die('Security validation failed');
    }
    return true;
}

// Rate Limiting - Prevent abuse
class RateLimiter {
    private $redis;
    private $max_requests = 100;
    private $time_window = 60; // seconds
    
    public function __construct() {
        // Production Redis connection
        if (extension_loaded('redis')) {
            $this->redis = new Redis();
            $this->redis->connect('127.0.0.1', 6379, 2.5);
        }
    }
    
    public function checkLimit($ip_address, $endpoint) {
        if (!$this->redis) return true; // Fail open if Redis unavailable
        
        $key = "rate_limit:{$endpoint}:{$ip_address}";
        $current = $this->redis->get($key);
        
        if ($current >= $this->max_requests) {
            return false;
        }
        
        $this->redis->incr($key);
        $this->redis->expire($key, $this->time_window);
        return true;
    }
}

// Input Sanitization - Production ready
function sanitizeInput($data) {
    if (is_array($data)) {
        return array_map('sanitizeInput', $data);
    }
    
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data, ENT_QUOTES, 'UTF-8');
    
    // Remove potential SQL injection patterns
    $data = preg_replace('/(\bselect\b|\binsert\b|\bupdate\b|\bdelete\b|\bdrop\b|\bunion\b|\bexec\b)/i', '', $data);
    
    return $data;
}

// CORS Headers - API security
function setSecureHeaders() {
    header("X-Frame-Options: DENY");
    header("X-XSS-Protection: 1; mode=block");
    header("X-Content-Type-Options: nosniff");
    header("Referrer-Policy: strict-origin-when-cross-origin");
    header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com;");
    header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
}

// IP Whitelist for admin functions
function isWhitelistedIP() {
    $whitelist = [
        '196.43.133.0/24', // Uganda telecom range
        '41.190.0.0/16',   // Additional Uganda ranges
        '102.0.0.0/8'      // MTN Uganda
    ];
    
    $client_ip = $_SERVER['REMOTE_ADDR'];
    
    foreach ($whitelist as $range) {
        if (ipInRange($client_ip, $range)) {
            return true;
        }
    }
    
    return false;
}

// Production settings
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_secure', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_samesite', 'Strict');
ini_set('session.gc_maxlifetime', 7200); // 2 hours
ini_set('session.cookie_lifetime', 0); // Session cookie

setSecureHeaders();
?>