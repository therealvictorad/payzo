<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class TopupRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'phone_number' => ['required', 'string', 'regex:/^[0-9]{10,15}$/'],
            'network'      => ['required', 'in:MTN,Airtel,Glo,9mobile'],
            'type'         => ['required', 'in:airtime,data'],
            'amount'       => ['required', 'numeric', 'min:50', 'max:50000'],
        ];
    }
}
