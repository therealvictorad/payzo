<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Fraud Detection Thresholds
    |--------------------------------------------------------------------------
    | All values are overridable via .env so you can tune them per environment
    | without a code deploy.
    */

    // Amount (in Naira) above which a transaction is flagged HIGH risk
    'large_transaction_threshold' => env('FRAUD_LARGE_TX_THRESHOLD', 50000),

    // Max number of transactions allowed within the window before MEDIUM flag
    'rapid_transaction_limit' => env('FRAUD_RAPID_TX_LIMIT', 5),

    // Window in seconds for rapid transaction check
    'rapid_transaction_window_seconds' => env('FRAUD_RAPID_TX_WINDOW', 60),
];
