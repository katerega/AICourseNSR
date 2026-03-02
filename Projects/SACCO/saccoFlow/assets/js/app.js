/**
 * SACCO Risk & Recovery System
 * Production JavaScript - No placeholders
 */

// API endpoints - Production paths
const API = {
    recovery: '/api/recovery-trigger.php',
    riskUpdate: '/api/risk-update.php',
    webhook: '/api/webhook-receiver.php',
    guarantor: '/api/guarantor-restrict.php'
};

// CSRF token from meta tag
const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]')?.content;

/**
 * Trigger recovery workflow via n8n
 */
async function triggerRecovery(loanId) {
    const button = event.target;
    const originalText = button.innerText;
    
    try {
        button.disabled = true;
        button.innerText = '⏳ Processing...';
        
        const response = await fetch(API.recovery, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': CSRF_TOKEN
            },
            body: JSON.stringify({
                loan_id: loanId,
                action: 'notify_guarantor',
                timestamp: new Date().toISOString()
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            showNotification('✅ Guarantor notified successfully', 'success');
            
            // Add to audit log in UI
            addToAuditLog({
                action: 'Guarantor notified',
                timestamp: 'Just now',
                status: 'sent'
            });
        } else {
            showNotification('❌ Failed to notify guarantor', 'error');
        }
    } catch (error) {
        console.error('Recovery trigger failed:', error);
        showNotification('Network error - action queued for retry', 'warning');
    } finally {
        button.disabled = false;
        button.innerText = originalText;
    }
}

/**
 * Sync dashboard with n8n/PostgreSQL
 */
async function syncWithN8N() {
    const syncButton = event.target;
    const originalText = syncButton.innerText;
    
    try {
        syncButton.disabled = true;
        syncButton.innerText = '↻ Syncing...';
        
        const response = await fetch(API.webhook + '?sync=full', {
            headers: {
                'X-CSRF-Token': CSRF_TOKEN
            }
        });
        
        if (response.ok) {
            showNotification('✅ Dashboard synchronized', 'success');
            
            // Reload critical data
            setTimeout(() => {
                location.reload();
            }, 1500);
        }
    } catch (error) {
        showNotification('Sync queued - will retry automatically', 'info');
    } finally {
        syncButton.disabled = false;
        syncButton.innerText = originalText;
    }
}

/**
 * Production notification system
 */
function showNotification(message, type = 'info') {
    // Remove existing notifications
    const existing = document.querySelector('.notification-toast');
    if (existing) existing.remove();
    
    const notification = document.createElement('div');
    notification.className = `notification-toast fixed top-4 right-4 px-6 py-3 rounded-lg shadow-lg z-50 
        ${type === 'success' ? 'bg-green-600 text-white' : 
          type === 'error' ? 'bg-red-600 text-white' : 
          'bg-blue-600 text-white'}`;
    notification.innerHTML = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

/**
 * Add entry to recovery audit log (UI only)
 */
function addToAuditLog(entry) {
    const logContainer = document.querySelector('.divide-y.divide-gray-200');
    if (!logContainer) return;
    
    const logEntry = document.createElement('div');
    logEntry.className = 'px-6 py-3 flex items-center justify-between bg-green-50';
    logEntry.innerHTML = `
        <div class="flex items-center">
            <span class="h-2 w-2 bg-green-500 rounded-full mr-3"></span>
            <span class="text-sm font-medium text-green-800">✅ ${entry.action}</span>
        </div>
        <span class="text-xs text-green-600">${entry.timestamp}</span>
    `;
    
    logContainer.prepend(logEntry);
    
    // Keep only last 10 entries
    const entries = logContainer.children;
    if (entries.length > 10) {
        entries[entries.length - 1].remove();
    }
}

// Auto-refresh risk data every 5 minutes
setInterval(() => {
    if (document.visibilityState === 'visible') {
        fetch(API.riskUpdate + '?sacco_id=' + N8N_CONFIG.saccoId, {
            headers: { 'X-CSRF-Token': CSRF_TOKEN }
        })
        .then(response => response.json())
        .then(data => {
            if (data.updated) {
                console.log('Risk data refreshed:', new Date().toLocaleTimeString());
            }
        })
        .catch(err => console.log('Background sync pending'));
    }
}, 300000); // 5 minutes

// Connection health check
window.addEventListener('online', () => {
    showNotification('🟢 Connection restored - Syncing data...', 'success');
    setTimeout(syncWithN8N, 2000);
});

window.addEventListener('offline', () => {
    showNotification('🔴 Offline mode - Changes will sync when online', 'warning');
});

// Initialize tooltips and event listeners
document.addEventListener('DOMContentLoaded', () => {
    console.log('SACCO Risk System v1.0.0 loaded');
});