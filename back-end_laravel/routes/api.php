<?php

use App\Http\Controllers\NotesController;
use App\Http\Controllers\TasksController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\GroupsController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// header('Access-Control-Allow-Methods: GET, POST, PATCH, PUT, DELETE, OPTIONS');
// header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization, Accept,charset,boundary,Content-Length');
// header('Access-Control-Allow-Origin: *');

Route::post('user/register', [UserController::class, 'register'])->name('user.register');
Route::post('user/login', [UserController::class, 'login'])->name('user.login');

Route::get('/notes', [NotesController::class, 'index'])->name('notes.index');
Route::get('/tasks', [TasksController::class, 'index'])->name('tasks.index');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::put('/user/edit', [UserController::class, 'edit']);
    Route::delete('/user/delete', [UserController::class, 'delete']);
    Route::post('user/logout', [UserController::class, 'logout'])->name('user.logout');

    Route::post('/notes', [NotesController::class, 'store'])->name('notes.store');
    Route::put('/notes/{note}', [NotesController::class, 'update'])->name('notes.update');
    Route::delete('/notes/{note}', [NotesController::class, 'destroy'])->name('notes.destroy');

    Route::post('/tasks', [TasksController::class, 'store'])->name('tasks.store');
    Route::put('/tasks/{task}', [TasksController::class, 'update'])->name('tasks.update');
    Route::delete('/tasks/{task}', [TasksController::class, 'destroy'])->name('tasks.destroy');

    Route::post('/groups', [GroupsController::class, 'createGroup'])->name('groups.create');
    Route::post('/groups/join', [GroupsController::class, 'joinGroup'])->name('groups.join');
    Route::put('/groups/{id}', [GroupsController::class, 'editGroup'])->name('groups.edit');
    Route::delete('/groups/{id}', [GroupsController::class, 'deleteGroup'])->name('groups.delete');
    Route::post('/groups/{id}/leave', [GroupsController::class, 'leaveGroup'])->name('groups.leave');
    Route::get('/groups', [GroupsController::class, 'index'])->name('groups.index');
    Route::get('/groups/{id}', [GroupsController::class, 'show'])->name('groups.show');
});
