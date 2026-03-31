<?php

namespace Database\Seeders;

use App\Models\FraudLog;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Admin ──────────────────────────────────────────────────────────
        $admin = User::factory()->admin()->create([
            'name'     => 'Super Admin',
            'email'    => 'admin@payzo.com',
            'password' => Hash::make('password'),
        ]);
        $admin->wallet()->create(['balance' => 0.00]);

        // ── 2. Agents (each gets a referral code) ─────────────────────────────
        $agents = User::factory()->agent()->count(2)->create();
        $agents->each(fn ($agent) => $agent->wallet()->create(['balance' => 5000.00]));

        // ── 3. Regular users — some referred by agents ────────────────────────
        $users = collect();

        // 5 users referred by agent 1
        User::factory()->count(5)->create(['referred_by' => $agents[0]->id])
            ->each(function ($user) use ($users) {
                $user->wallet()->create(['balance' => fake()->randomFloat(2, 100, 3000)]);
                $users->push($user);
            });

        // 5 users referred by agent 2
        User::factory()->count(5)->create(['referred_by' => $agents[1]->id])
            ->each(function ($user) use ($users) {
                $user->wallet()->create(['balance' => fake()->randomFloat(2, 100, 3000)]);
                $users->push($user);
            });

        // 5 organic users (no referral)
        User::factory()->count(5)->create()
            ->each(function ($user) use ($users) {
                $user->wallet()->create(['balance' => fake()->randomFloat(2, 100, 3000)]);
                $users->push($user);
            });

        // ── 4. Transactions between users ─────────────────────────────────────
        $allUsers = $users->shuffle();

        for ($i = 0; $i < 30; $i++) {
            $sender   = $allUsers->random();
            $receiver = $allUsers->where('id', '!=', $sender->id)->random();
            $amount   = fake()->randomFloat(2, 10, 1500);

            // Only create transaction if sender has enough balance
            if ($sender->wallet->balance >= $amount) {
                $sender->wallet()->decrement('balance', $amount);
                $receiver->wallet()->increment('balance', $amount);

                $transaction = Transaction::create([
                    'sender_id'   => $sender->id,
                    'receiver_id' => $receiver->id,
                    'amount'      => $amount,
                    'status'      => 'success',
                    'created_at'  => fake()->dateTimeBetween('-30 days', 'now'),
                    'updated_at'  => now(),
                ]);

                // ── 5. Seed some fraud logs ────────────────────────────────────
                if ($amount > 1000) {
                    FraudLog::create([
                        'user_id'        => $sender->id,
                        'transaction_id' => $transaction->id,
                        'rule_triggered' => 'LARGE_TRANSACTION',
                        'risk_level'     => 'HIGH',
                    ]);
                }

                // Randomly flag some as unusual time
                if (fake()->boolean(20)) {
                    FraudLog::create([
                        'user_id'        => $sender->id,
                        'transaction_id' => $transaction->id,
                        'rule_triggered' => 'UNUSUAL_TIME',
                        'risk_level'     => 'LOW',
                    ]);
                }
            }
        }

        $this->command->info('✅ Seeded: 1 admin, 2 agents, 15 users, transactions & fraud logs.');
        $this->command->info('   Admin login → admin@payzo.com / password');
        $this->command->info('   Agent referral codes: ' . $agents->pluck('referral_code')->join(', '));
    }
}
