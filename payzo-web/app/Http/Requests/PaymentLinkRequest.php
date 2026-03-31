<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PaymentLinkRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'amount'      => ['required', 'numeric', 'min:1'],
            'description' => ['nullable', 'string', 'max:255'],
        ];
    }
}
