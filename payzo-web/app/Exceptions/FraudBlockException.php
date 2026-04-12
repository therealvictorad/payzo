<?php

namespace App\Exceptions;

use Illuminate\Validation\ValidationException;

class FraudBlockException extends ValidationException
{
    public static function make(): static
    {
        return static::withMessages([
            'transaction' => 'This transaction has been blocked due to suspicious activity. Contact support.',
        ]);
    }
}
