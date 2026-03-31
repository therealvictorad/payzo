<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'receiver_email' => ['required', 'email', 'exists:users,email'],
            'amount'         => ['required', 'numeric', 'min:0.01'],
        ];
    }
}
