<?php

namespace App\Providers;

use App\Interfaces\Interface\TasksRepositoryInterface;
use App\Interfaces\NotesRepositoryInterface;
use App\Repositories\NotesRepository;
use App\Repositories\TasksRepository;
use Illuminate\Support\ServiceProvider;

class RepositoryServiceProvider extends ServiceProvider
{

    public function register(): void
    {
        $this->app->bind(NotesRepositoryInterface::class, NotesRepository::class);
        $this->app->bind(TasksRepositoryInterface::class, TasksRepository::class);
    }

    public function boot(): void {}
}
