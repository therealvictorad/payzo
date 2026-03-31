<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    public function test_api_status_endpoint_returns_ok(): void
    {
        $this->getJson('/api/status')
             ->assertStatus(200)
             ->assertJson(['status' => 'ok']);
    }
}
