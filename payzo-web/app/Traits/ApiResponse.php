<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function success(string $message, mixed $data = null, int $status = 200): JsonResponse
    {
        $payload = ['status' => 'success', 'message' => $message];

        if (!is_null($data)) {
            $payload['data'] = $data;
        }

        return response()->json($payload, $status);
    }

    protected function error(string $message, int $status = 400): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], $status);
    }
}
