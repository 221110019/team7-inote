<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Groups extends Model
{
    use HasFactory;
    protected $fillable = ['leader', 'name', 'entry_code'];
    protected $casts = [
        'members' => 'array',
    ];
    public function members()
    {
        return $this->belongsToMany(User::class, 'group_user', 'group_id', 'user_id');
    }
    public function leaderUser()
    {
        return $this->belongsTo(User::class, 'leader');
    }
}
