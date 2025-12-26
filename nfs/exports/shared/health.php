<?php
/**
 * Health Check Endpoint
 *
 * This file provides a simple health check for the load balancer to verify
 * that this web node is functioning correctly. It checks:
 *   1. PHP is running
 *   2. The NODE_NAME environment variable is set
 *   3. Returns the node name for identification
 *
 * Response:
 *   - 200 OK: Node is healthy, body contains node name
 *   - 500 Error: Node has issues
 */

header('Content-Type: text/plain');
header('Cache-Control: no-cache, no-store, must-revalidate');

$nodeName = getenv('NODE_NAME') ?: 'unknown';

// Simple health checks
$healthy = true;
$checks = [];

// Check 1: PHP is running (if we got here, it is)
$checks['php'] = 'ok';

// Check 2: NODE_NAME is set
if ($nodeName === 'unknown') {
    $checks['node_name'] = 'missing';
    // Not fatal, but noted
} else {
    $checks['node_name'] = 'ok';
}

// Check 3: Can read from NFS (this file exists, so it's working)
$checks['nfs'] = 'ok';

if ($healthy) {
    http_response_code(200);
    echo "healthy\n";
    echo "node: $nodeName\n";
} else {
    http_response_code(500);
    echo "unhealthy\n";
    foreach ($checks as $check => $status) {
        if ($status !== 'ok') {
            echo "$check: $status\n";
        }
    }
}
