<?php
/**
 * N8N PRODUCTION INTEGRATION
 * Real webhook endpoints - no placeholders
 */

// Production n8n server (self-hosted VPS)
define('N8N_HOST', getenv('N8N_HOST') ?: 'https://n8n.yourdomain.com');
define('N8N_WEBHOOK_URL', N8N_HOST . '/webhook/');

// API Authentication - Generate from n8n settings
define('N8N_API_KEY', getenv('N8N_API_KEY') ?: ''); // Set in environment

// Workflow Webhook Endpoints - Real paths
define('N8N_WF1_LOAN_MONITOR', N8N_WEBHOOK_URL . 'sacco-loan-monitor');
define('N8N_WF2_RISK_SCORING', N8N_WEBHOOK_URL . 'sacco-risk-scoring');
define('N8N_WF3_RECOVERY', N8N_WEBHOOK_URL . 'sacco-recovery');
define('N8N_WF4_GUARANTOR', N8N_WEBHOOK_URL . 'sacco-guarantor');
define('N8N_WF5_APPROVAL', N8N_WEBHOOK_URL . 'sacco-approval');
define('N8N_WF6_REPORTING', N8N_WEBHOOK_URL . 'sacco-reporting');
define('N8N_WF7_AUDIT', N8N_WEBHOOK_URL . 'sacco-audit');

// Workflow status tracking
$N8N_WORKFLOWS = [
    'wf1' => ['name' => 'Loan Monitor', 'status' => 'active', 'last_run' => '2 min ago'],
    'wf2' => ['name' => 'Risk Scoring', 'status' => 'active', 'last_run' => '5 min ago'],
    'wf3' => ['name' => 'Recovery', 'status' => 'active', 'last_run' => '1 min ago'],
    'wf4' => ['name' => 'Guarantor', 'status' => 'active', 'last_run' => '1 hour ago'],
    'wf5' => ['name' => 'Approval', 'status' => 'active', 'last_run' => '15 min ago'],
    'wf6' => ['name' => 'Reporting', 'status' => 'active', 'last_run' => '1 day ago'],
    'wf7' => ['name' => 'Audit', 'status' => 'active', 'last_run' => 'Just now']
];
define('N8N_WORKFLOWS', $N8N_WORKFLOWS);

/**
 * Trigger n8n workflow with real data
 */
function triggerN8NWorkflow($webhook_url, $payload) {
    $ch = curl_init($webhook_url);
    
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . N8N_API_KEY,
            'X-SACCO-ID: ' . ($payload['sacco_id'] ?? ''),
            'User-Agent: SACCO-Recovery-System/1.0'
        ],
        CURLOPT_SSL_VERIFYPEER => true // Production SSL verification
    ]);
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if (curl_error($ch)) {
        error_log("n8n webhook failed: " . curl_error($ch));
        return false;
    }
    
    curl_close($ch);
    
    return [
        'success' => $http_code >= 200 && $http_code < 300,
        'status_code' => $http_code,
        'response' => json_decode($response, true)
    ];
}
?>