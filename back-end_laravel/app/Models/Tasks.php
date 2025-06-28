<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tasks extends Model
{
    /** @use HasFactory<\Database\Factories\TasksFactory> */
    use HasFactory;
    protected $fillable = ['by', 'title', 'category', 'task_items'];
    protected $casts = [
        'task_items' => 'array',
    ];
}
