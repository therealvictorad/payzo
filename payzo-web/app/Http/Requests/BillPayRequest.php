<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BillPayRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'provider'    => ['required', 'in:DSTV,GOtv,Startimes,IKEDC,EKEDC,AEDC,IBEDC'],
            'customer_id' => ['required', 'string', 'max:30'],
            'amount'      => ['required', 'numeric', 'min:100', 'max:500000'],
        ];
    }
}
