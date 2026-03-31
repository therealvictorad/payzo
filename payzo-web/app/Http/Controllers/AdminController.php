<?php

namespace App\Http\Controllers;

use App\Services\AdminService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class AdminController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly AdminService $adminService) {}

    public function users(): JsonResponse
    {
        return $this->success('Users retrieved', $this->adminService->getAllUsers());
    }

    public function transactions(): JsonResponse
    {
        return $this->success('Transactions retrieved', $this->adminService->getAllTransactions());
    }

    public function fraudLogs(): JsonResponse
    {
        return $this->success('Fraud logs retrieved', $this->adminService->getAllFraudLogs());
    }

    public function topups(): JsonResponse
    {
        return $this->success('Top-ups retrieved', $this->adminService->getAllTopups());
    }

    public function bills(): JsonResponse
    {
        return $this->success('Bills retrieved', $this->adminService->getAllBills());
    }

    public function paymentLinks(): JsonResponse
    {
        return $this->success('Payment links retrieved', $this->adminService->getAllPaymentLinks());
    }

    public function cards(): JsonResponse
    {
        return $this->success('Virtual cards retrieved', $this->adminService->getAllCards());
    }
}
