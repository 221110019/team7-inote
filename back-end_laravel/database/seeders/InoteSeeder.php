<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use App\Models\User;
use App\Models\Groups;
use App\Models\Notes;
use App\Models\Tasks;

class InoteSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::create([
            'name' => 'dummy' . Str::random(8),
            'email' => 'dummy' . Str::random(8) . '@test.com',
            'password' => bcrypt('passdummy'),
        ]);

        $group = Groups::create([
            'name' => 'group_' . Str::random(2),
            'entry_code' => Str::random(6),
            'leader' => $user->id,
        ]);

        if (method_exists($group, 'members')) {
            $group->members()->attach($user->id);
        }

        Notes::create([
            'title' => 'Test Note ' . Str::random(5),
            'note' => 'This is a test note.',
            'category' => $group->name,
            'by' => $user->id,
        ]);

        Tasks::create([
            'by' => $user->name,
            'title' => 'Test ' . Str::random(5),
            'category' => $group->name,
            'task_items' => json_encode([['item' => 'Do something']]),
        ]);
    }
}
