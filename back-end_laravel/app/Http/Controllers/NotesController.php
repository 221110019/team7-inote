<?php

namespace App\Http\Controllers;

use App\Classes\ApiResponseClass;
use App\Http\Requests\StoreNotesRequest;
use App\Http\Requests\UpdateNotesRequest;
use App\Http\Resources\NotesResource;
use App\Interfaces\NotesRepositoryInterface;
use Illuminate\Support\Facades\DB;

class NotesController extends Controller
{
    private NotesRepositoryInterface $notesRepositoryInterface;
    public function __construct(NotesRepositoryInterface $notesRepositoryInterface)
    {
        $this->notesRepositoryInterface = $notesRepositoryInterface;
    }
    public function index()
    {
        $data = $this->notesRepositoryInterface->index();
        return ApiResponseClass::sendResponse(NotesResource::collection($data), '', 200);
    }

    public function store(StoreNotesRequest $request)
    {
        $data = [
            'by' => $request->user()->name,
            'title' => $request->title,
            'note' => $request->note,
            'category' => $request->category
        ];
        DB::beginTransaction();
        try {
            $notes = $this->notesRepositoryInterface->store($data);
            DB::commit();
            return ApiResponseClass::sendResponse(new NotesResource($notes), 'Note created ...', 201);
        } catch (\Exception $ex) {
            return ApiResponseClass::rollback($ex);
        }
    }

    public function show($id)
    {
        $notes = $this->notesRepositoryInterface->getById($id);

        return ApiResponseClass::sendResponse(new NotesResource($notes), '', 200);
    }

    public function update(UpdateNotesRequest $request, $id)
    {
        $updateDetails = [
            'by' => $request->user()->name,
            'title' => $request->title,
            'note' => $request->note,
            'category' => $request->category,

        ];
        DB::beginTransaction();
        try {
            $this->notesRepositoryInterface->update($updateDetails, $id);
            DB::commit();
            return ApiResponseClass::sendResponse('Note updated ...', '', 201);
        } catch (\Exception $ex) {
            return ApiResponseClass::rollback($ex);
        }
    }

    public function destroy($id)
    {
        $this->notesRepositoryInterface->delete($id);
        return ApiResponseClass::sendResponse('Note deleted ...', '', 202);
    }
}
