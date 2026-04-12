<?php

namespace App\Exceptions;

use Illuminate\Validation\ValidationException;

class DuplicateTransactionException extends ValidationException
{
    public static function make(): static
    {
        return static::withMessages([
            'idempotency_key' => 'A transaction with this idempotency key already exists.',
        ]);
    }
}
