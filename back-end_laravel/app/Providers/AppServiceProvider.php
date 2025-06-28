<?php

namespace App\Providers;

use Illuminate\Support\Facades\App;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{

    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        if (App::environment('production')) {
            config([
                'logging.channels.stack' => [
                    'driver' => 'single',
                    'path' => '/tmp/laravel.log',
                    'level' => 'debug',
                ],
                'view.compiled' => '/tmp',
                'cache.stores.file.path' => '/tmp',
            ]);
        }
    }
}
