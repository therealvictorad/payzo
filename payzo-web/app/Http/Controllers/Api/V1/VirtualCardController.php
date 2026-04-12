<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\VirtualCardService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VirtualCardController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly VirtualCardService $virtualCardService) {}

    public function create(Request $request): JsonResponse
    {
        $card = $this->virtualCardService->create($request->user());

        return $this->success('Virtual card created successfully', $card, 201);
    }

    public function index(Request $request): JsonResponse
    {
        $cards = $this->virtualCardService->getUserCards($request->user());

        return $this->success('Cards retrieved', $cards);
    }
}
