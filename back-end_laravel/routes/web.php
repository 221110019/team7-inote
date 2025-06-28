<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Controller;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dev221110019', function () {
    $controller = new Controller();
    $tables = $controller->getAllTables();
    return view('dev221110019', ['tables' => $tables]);
});
