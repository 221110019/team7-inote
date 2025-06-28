<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'email' => 'required|string|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password'])
        ]);
        $token = $user->createToken('inote-token')->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response()->json($response, 201);
    }
    public function login(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'password' => 'required|min:8'
        ]);

        $user = User::where('name', $request->name)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response([
                'message' => ['These credentials do not match our records.']
            ], 404);
        }

        $token = $user->createToken('inote-token')->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response()->json($response, 201);
    }
    public function logout(Request $request)
    {
        $user = $request->user();
        $user->tokens()->delete();

        $response = [
            'message' => 'logged out',
        ];
        return response($response);
    }
    public function myGroups(Request $request)
    {
        $user = $request->user();
        $groups = $user->groups()->get();

        return response()->json([
            'groups' => $groups
        ]);
    }
    public function edit(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name' => 'sometimes|string|unique:users,name,' . $user->id,
            'password' => 'sometimes|string|min:8|confirmed',
        ]);

        if ($request->filled('name')) {
            $user->name = $request->name;
        }
        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }
        $user->save();

        return response()->json([
            'message' => 'User updated successfully.',
            'user' => $user
        ]);
    }

    public function delete(Request $request)
    {
        $user = $request->user();
        if (method_exists($user, 'notes')) {
            $user->notes()->delete();
        } else {
            \App\Models\Notes::where('by', $user->name)->delete();
        }
        if (method_exists($user, 'tasks')) {
            $user->tasks()->delete();
        } else {
            \App\Models\Tasks::where('by', $user->name)->delete();
        }
        if (method_exists($user, 'groups')) {
            $user->groups()->detach();
        }
        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'message' => 'User account and related data deleted successfully.'
        ]);
    }
}
