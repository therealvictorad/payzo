<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class KycSubmitRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'document_type'   => ['required', 'in:nin,bvn,passport,drivers_license'],
            'document_number' => ['required', 'string', 'min:6', 'max:20'],
            'full_name'       => ['required', 'string', 'max:255'],
            'date_of_birth'   => ['required', 'date', 'before:-18 years'], // must be 18+
            'address'         => ['nullable', 'string', 'max:500'],
            'document'        => [
                'required',
                'file',
                'mimes:jpg,jpeg,png,pdf',
                'max:2048', // 2MB max
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'date_of_birth.before' => 'You must be at least 18 years old.',
            'document.mimes'       => 'Document must be a JPG, PNG, or PDF file.',
            'document.max'         => 'Document must not exceed 2MB.',
        ];
    }
}
