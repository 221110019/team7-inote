<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;
use App\Models\User;

class ApiRoutesTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_api_flow()
    {
        // Register
        $username = 'user_' . Str::random(8);
        $email = $username . '@test.com';
        $password = 'TestPass123!';

        $register = $this->postJson('/api/user/register', [
            'name' => $username,
            'email' => $email,
            'password' => $password,
            'password_confirmation' => $password,
        ]);
        $register->assertCreated();
        $token = $register->json('token');
        $userId = $register->json('user.id');

        // Login
        $login = $this->postJson('/api/user/login', [
            'name' => $username,
            'password' => $password,
        ]);
        $login->assertCreated();
        $token = $login->json('token');

        // Auth headers
        $headers = ['Authorization' => 'Bearer ' . $token];

        // Create Group
        $groupName = 'group_' . Str::random(8);
        $entryCode = Str::random(6);

        $createGroup = $this->actingAs(User::find($userId))
            ->postJson('/api/groups', [
                'name' => $groupName,
                'entry_code' => $entryCode,
            ]);
        $createGroup->assertStatus(200)->assertJsonStructure(['group']);

        // List My Groups
        $myGroups = $this->withHeaders($headers)->get('/api/my-groups');
        $myGroups->assertOk()->assertJsonStructure(['groups']);

        // Create Note
        $noteTitle = 'Test Note ' . Str::random(5);
        $note = $this->withHeaders($headers)->postJson('/api/notes', [
            'title' => $noteTitle,
            'content' => 'This is a test note.',
            'category' => $groupName,
        ]);
        $note->assertStatus(200);

        // Create Task
        $taskTitle = 'Test Task ' . Str::random(5);
        $task = $this->withHeaders($headers)->postJson('/api/tasks', [
            'by' => $username,
            'title' => $taskTitle,
            'category' => $groupName,
            'task_items' => [['item' => 'Do something']],
        ]);
        $task->assertStatus(201);

        // List Notes
        $notes = $this->withHeaders($headers)->get('/api/notes');
        $notes->assertOk();

        // List Tasks
        $tasks = $this->withHeaders($headers)->get('/api/tasks');
        $tasks->assertOk();

        // Logout
        $logout = $this->withHeaders($headers)->post('/api/user/logout');
        $logout->assertOk();
    }
}
