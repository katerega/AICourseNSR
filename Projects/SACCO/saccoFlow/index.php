<?php
/**
 * SACCO RISK & RECOVERY SYSTEM
 * Production Version 1.0.0
 * Uganda Market Deployment
 * 
 * NO DEMO DATA - Real SACCO infrastructure
 */

session_start();
require_once 'config/security.php';
require_once 'config/database.php';
require_once 'includes/auth.php';
require_once 'includes/functions.php';

// Authenticate SACCO user
$sacco_id = authenticateRequest();
$sacco_data = getSaccoDetails($sacco_id);

// Get real-time portfolio data from PostgreSQL
$portfolio_stats = getPortfolioStats($sacco_id);
$high_risk_borrowers = getHighRiskBorrowers($sacco_id);
$guarantor_alerts = getGuarantorExposureAlerts($sacco_id);
$recovery_actions = getTodayRecoveryActions($sacco_id);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($sacco_data['name']); ?> - Risk & Recovery System</title>
    <meta name="description" content="SACCO Loan Recovery & Risk Management System - Real-time default prevention">
    <meta name="author" content="SACCO Risk Engine">
    
    <!-- Production CSS (Minified) -->
    <link href="/assets/css/app.css?v=<?php echo filemtime('assets/css/app.css'); ?>" rel="stylesheet">
    
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/assets/images/favicon.png">
    
    <!-- CSRF Protection -->
    <meta name="csrf-token" content="<?php echo generateCSRFToken(); ?>">
</head>
<body class="bg-gray-100 font-sans antialiased">
    <!-- Top Navigation - SACCO Branded -->
    <nav class="bg-sacco-primary text-white shadow-lg">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex items-center">
                    <span class="text-2xl font-bold">
                        <?php echo htmlspecialchars($sacco_data['name']); ?> 
                        <span class="text-sm font-normal bg-white bg-opacity-20 px-3 py-1 rounded-full ml-3">
                            Risk Management
                        </span>
                    </span>
                </div>
                <div class="flex items-center space-x-6">
                    <span class="text-sm">
                        <?php echo htmlspecialchars($_SESSION['user_name']); ?> - 
                        <?php echo htmlspecialchars($sacco_data['role']); ?>
                    </span>
                    <a href="/logout.php" class="text-white hover:text-gray-200 text-sm">
                        Sign Out
                    </a>
                </div>
            </div>
        </div>
    </nav>

    <!-- Main Dashboard - Production Data -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        <!-- Quick Stats - Real PostgreSQL Data -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div class="stat-card border-l-4 border-green-600">
                <p class="stat-label">Total Loan Book</p>
                <p class="stat-value">UGX <?php echo number_format($portfolio_stats['total_loan_book']); ?></p>
                <p class="stat-change positive"><?php echo $portfolio_stats['loan_growth']; ?>% from last month</p>
            </div>
            <div class="stat-card border-l-4 border-yellow-500">
                <p class="stat-label">At Risk Portfolio</p>
                <p class="stat-value text-yellow-600">UGX <?php echo number_format($portfolio_stats['at_risk']); ?></p>
                <p class="stat-percentage"><?php echo $portfolio_stats['risk_percentage']; ?>% of total book</p>
            </div>
            <div class="stat-card border-l-4 border-red-600">
                <p class="stat-label">30+ Days Overdue</p>
                <p class="stat-value text-red-600">UGX <?php echo number_format($portfolio_stats['overdue_30_plus']); ?></p>
                <p class="stat-alert">Immediate action required</p>
            </div>
            <div class="stat-card border-l-4 border-blue-600">
                <p class="stat-label">Recoverable Loans</p>
                <p class="stat-value text-blue-600">UGX <?php echo number_format($portfolio_stats['recoverable']); ?></p>
                <p class="stat-target">30-day recovery target</p>
            </div>
        </div>

        <!-- Two-Column Layout -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            
            <!-- LEFT: Recovery Setup - Production Price Card -->
            <div class="lg:col-span-1">
                <div class="recovery-setup-card">
                    <div class="card-header bg-sacco-primary">
                        <h2 class="text-xl font-bold text-white flex items-center">
                            <span class="mr-2">⚡</span> Emergency Recovery Setup
                        </h2>
                        <p class="text-blue-100 text-sm mt-1">Same-day diagnostic + recovery priority</p>
                    </div>
                    
                    <div class="p-6">
                        <div class="text-center mb-6 pb-6 border-b border-gray-200">
                            <span class="text-3xl font-bold text-gray-900">UGX <?php echo number_format(RECOVERY_SETUP_PRICE); ?></span>
                            <span class="text-gray-600 ml-2">one-time</span>
                            <p class="text-sm text-gray-500 mt-1">Payment today • Delivery starts immediately</p>
                        </div>

                        <div class="service-includes mb-6">
                            <?php foreach (RECOVERY_SERVICES as $service): ?>
                            <div class="flex items-start mb-3">
                                <div class="flex-shrink-0 h-6 w-6 text-green-600">✓</div>
                                <div class="ml-3">
                                    <p class="text-sm font-medium text-gray-900"><?php echo $service['title']; ?></p>
                                    <p class="text-xs text-gray-500"><?php echo $service['description']; ?></p>
                                </div>
                            </div>
                            <?php endforeach; ?>
                        </div>

                        <div class="bg-blue-50 p-4 rounded-lg mb-6">
                            <p class="text-sm font-medium text-blue-800">
                                💰 "If we improve recovery by 5%, this setup pays for itself immediately."
                            </p>
                        </div>

                        <form id="recoverySetupForm" action="/api/recovery-trigger.php" method="POST">
                            <input type="hidden" name="csrf_token" value="<?php echo $_SESSION['csrf_token']; ?>">
                            <input type="hidden" name="sacco_id" value="<?php echo $sacco_id; ?>">
                            <input type="hidden" name="price" value="<?php echo RECOVERY_SETUP_PRICE; ?>">
                            
                            <button type="submit" 
                                    class="w-full bg-sacco-primary text-white font-bold py-3 px-4 rounded-lg hover:bg-sacco-dark transition duration-200 text-lg shadow-md"
                                    onclick="this.form.submit(); this.disabled=true; this.innerHTML='⏳ Processing...';">
                                🚀 Start Recovery Setup — UGX <?php echo number_format(RECOVERY_SETUP_PRICE); ?>
                            </button>
                        </form>

                        <div class="mt-4 pt-4 border-t border-gray-200 text-center">
                            <p class="text-sm text-gray-600">
                                <span class="font-semibold">Payment plan available:</span> 
                                Pay 50% now, 50% after first recovery
                            </p>
                            <p class="text-xs text-gray-500 mt-2">
                                Accepted: Mobile Money • Bank Transfer • Cash
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- RIGHT: Live Risk Dashboard - PostgreSQL Data -->
            <div class="lg:col-span-2 space-y-6">
                
                <!-- High Risk Borrowers - Real SACCO Data -->
                <div class="bg-white rounded-xl shadow-sm overflow-hidden">
                    <div class="px-6 py-4 bg-gray-50 border-b border-gray-200 flex justify-between items-center">
                        <div>
                            <h3 class="text-lg font-semibold text-gray-900">📋 High-Risk Borrowers</h3>
                            <p class="text-xs text-gray-500">
                                Risk scores calculated by n8n WF2 • Updated <?php echo timeAgo($portfolio_stats['last_risk_update']); ?>
                            </p>
                        </div>
                        <span class="px-3 py-1 bg-red-100 text-red-800 rounded-full text-xs font-semibold">
                            <?php echo count($high_risk_borrowers); ?> require action
                        </span>
                    </div>
                    
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Borrower</th>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Loan Amount</th>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Days Overdue</th>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Risk Score</th>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Level</th>
                                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Action</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <?php foreach ($high_risk_borrowers as $borrower): ?>
                                <tr class="hover:bg-gray-50">
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="text-sm font-medium text-gray-900">
                                            <?php echo htmlspecialchars($borrower['full_name']); ?>
                                        </div>
                                        <div class="text-xs text-gray-500">
                                            #<?php echo htmlspecialchars($borrower['member_number']); ?>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                        UGX <?php echo number_format($borrower['loan_amount']); ?>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="text-sm font-semibold <?php echo $borrower['days_overdue'] > 30 ? 'text-red-600' : 'text-orange-600'; ?>">
                                            <?php echo $borrower['days_overdue']; ?> days
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="risk-score-badge risk-<?php echo strtolower($borrower['risk_level']); ?>">
                                            <?php echo $borrower['risk_score']; ?>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span class="risk-level-badge level-<?php echo strtolower($borrower['risk_level']); ?>">
                                            <?php echo $borrower['risk_level']; ?>
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm">
                                        <button onclick="triggerRecovery('<?php echo $borrower['loan_id']; ?>')" 
                                                class="text-blue-600 hover:text-blue-900 font-medium">
                                            📞 Notify Guarantor
                                        </button>
                                    </td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Guarantor Exposure - Production Alerts -->
                <div class="bg-white rounded-xl shadow-sm overflow-hidden">
                    <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
                        <h3 class="text-lg font-semibold text-gray-900">🛡️ Guarantor Exposure Monitoring</h3>
                        <p class="text-xs text-gray-500">Automated by n8n WF4 • Weekly exposure check</p>
                    </div>
                    <div class="divide-y divide-gray-200">
                        <?php foreach ($guarantor_alerts as $alert): ?>
                        <div class="p-6 <?php echo $alert['exposure_percentage'] > 70 ? 'bg-red-50' : ''; ?>">
                            <div class="flex items-center justify-between mb-3">
                                <div class="flex items-center">
                                    <div class="h-10 w-10 rounded-full bg-red-100 flex items-center justify-center text-red-600 font-bold text-lg">
                                        !
                                    </div>
                                    <div class="ml-3">
                                        <p class="text-sm font-medium text-gray-900">
                                            <?php echo htmlspecialchars($alert['guarantor_name']); ?>
                                        </p>
                                        <p class="text-xs text-gray-500">
                                            Member #<?php echo htmlspecialchars($alert['member_number']); ?>
                                        </p>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <p class="text-sm font-semibold text-gray-900">
                                        UGX <?php echo number_format($alert['total_guaranteed']); ?> guaranteed
                                    </p>
                                    <p class="text-xs <?php echo $alert['exposure_percentage'] > 70 ? 'text-red-600 font-bold' : 'text-orange-600'; ?>">
                                        Exposure: <?php echo $alert['exposure_percentage']; ?>% of savings
                                    </p>
                                </div>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="exposure-bar h-2 rounded-full" 
                                     style="width: <?php echo min($alert['exposure_percentage'], 100); ?>%; 
                                            background-color: <?php echo $alert['exposure_percentage'] > 70 ? '#dc2626' : '#f59e0b'; ?>">
                                </div>
                            </div>
                            <?php if ($alert['exposure_percentage'] > 70): ?>
                            <div class="mt-4 flex justify-end">
                                <button onclick="restrictGuarantor('<?php echo $alert['guarantor_member_id']; ?>')" 
                                        class="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700">
                                    ⚠️ Restrict New Guarantees
                                </button>
                            </div>
                            <?php endif; ?>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>

                <!-- Recovery Actions Log - Audit Trail -->
                <div class="bg-white rounded-xl shadow-sm overflow-hidden">
                    <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
                        <h3 class="text-lg font-semibold text-gray-900">📝 Recovery Audit Trail</h3>
                        <p class="text-xs text-gray-500">All actions logged to PostgreSQL • n8n WF7</p>
                    </div>
                    <div class="divide-y divide-gray-200">
                        <?php foreach ($recovery_actions as $action): ?>
                        <div class="px-6 py-3 flex items-center justify-between">
                            <div class="flex items-center">
                                <span class="h-2 w-2 <?php echo $action['status'] === 'sent' ? 'bg-green-500' : 'bg-yellow-500'; ?> rounded-full mr-3"></span>
                                <span class="text-sm text-gray-600">
                                    <?php echo htmlspecialchars($action['description']); ?>
                                </span>
                            </div>
                            <span class="text-xs text-gray-500">
                                <?php echo date('h:i A', strtotime($action['created_at'])); ?>
                            </span>
                        </div>
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
        </div>

        <!-- n8n Status - Production Integration -->
        <div class="mt-8 bg-white rounded-lg shadow-sm p-4 border border-gray-200">
            <div class="flex items-center justify-between flex-wrap">
                <div class="flex items-center space-x-6">
                    <?php foreach (N8N_WORKFLOWS as $wf): ?>
                    <div class="flex items-center">
                        <span class="h-3 w-3 <?php echo $wf['status'] === 'active' ? 'bg-green-500' : 'bg-red-500'; ?> rounded-full mr-2"></span>
                        <span class="text-sm text-gray-700"><?php echo $wf['name']; ?></span>
                        <span class="ml-2 text-xs bg-gray-100 text-gray-800 px-2 py-0.5 rounded">
                            <?php echo $wf['last_run']; ?>
                        </span>
                    </div>
                    <?php endforeach; ?>
                </div>
                <div class="flex items-center space-x-3">
                    <span class="text-xs text-gray-500">
                        PostgreSQL: <?php echo DB_CONNECTION_STATUS; ?>
                    </span>
                    <button onclick="syncWithN8N()" 
                            class="text-sm text-blue-600 hover:text-blue-800 font-medium">
                        ↻ Force Sync
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script src="/assets/js/app.js?v=<?php echo filemtime('assets/js/app.js'); ?>"></script>
    <script>
        // Production configuration
        const N8N_CONFIG = {
            webhookBase: '<?php echo N8N_WEBHOOK_URL; ?>',
            apiKey: '<?php echo N8N_API_KEY; ?>',
            saccoId: '<?php echo $sacco_id; ?>'
        };
    </script>
</body>
</html>
<?php
// Log page access
logAuditTrail($sacco_id, 'dashboard_view', $_SERVER['REQUEST_URI']);
?>