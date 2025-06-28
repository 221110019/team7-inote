<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Notes;
use App\Models\Tasks;
use App\Models\Groups;

class Controller
{
    public function getAllTables()
    {
        return [
            'users' => User::all(),
            'notes' => Notes::all(),
            'tasks' => Tasks::all(),
            'groups' => Groups::all(),
        ];
    }
}
