<?php

namespace App\Repositories;

use App\Interfaces\NotesRepositoryInterface;
use App\Models\Notes;

class NotesRepository implements NotesRepositoryInterface
{
    public function index()
    {
        return Notes::all();
    }

    public function getById($id)
    {
        return Notes::findOrFail($id);
    }

    public function store(array $data)
    {
        return Notes::create($data);
    }

    public function update(array $data, $id)
    {
        return Notes::whereId($id)->update($data);
    }

    public function delete($id)
    {
        Notes::destroy($id);
    }
}
