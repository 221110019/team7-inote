<?php

namespace App\Repositories;

use App\Interfaces\Interface\TasksRepositoryInterface;
use App\Models\Tasks;

class TasksRepository implements TasksRepositoryInterface
{
    public function index()
    {
        return Tasks::all();
    }

    public function getById($id)
    {
        return Tasks::findOrFail($id);
    }

    public function store(array $data)
    {
        return Tasks::create($data);
    }

    public function update(array $data, $id)
    {
        return Tasks::whereId($id)->update($data);
    }

    public function delete($id)
    {
        Tasks::destroy($id);
    }
}
