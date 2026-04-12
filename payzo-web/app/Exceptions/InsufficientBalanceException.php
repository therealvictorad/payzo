<?php

namespace App\Exceptions;

use Illuminate\Validation\ValidationException;

class InsufficientBalanceException extends ValidationException
{
    public static function make(): static
    {
        return static::withMessages(['amount' => 'Insufficient wallet balance.']);
    }
}
