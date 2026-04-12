<?php

namespace App\Http\Middleware;

use App\Traits\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountNotFrozen
{
    use ApiResponse;

    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()?->isFrozen()) {
            return $this->error(
                'Your account has been frozen. Please contact support.',
                403
            );
        }

        return $next($request);
    }
}
