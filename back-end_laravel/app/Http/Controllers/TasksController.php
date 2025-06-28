<?php

namespace App\Http\Controllers;

use App\Classes\ApiResponseClass;
use App\Http\Requests\StoreTasksRequest;
use App\Http\Requests\UpdateTasksRequest;
use App\Http\Resources\TasksResource;
use App\Interfaces\Interface\TasksRepositoryInterface;
use Illuminate\Support\Facades\DB;

class TasksController extends Controller
{
    private TasksRepositoryInterface $tasksRepositoryInterface;


    public function __construct(TasksRepositoryInterface $tasksRepositoryInterface)
    {
        $this->tasksRepositoryInterface = $tasksRepositoryInterface;
    }
    public function index()
    {
        $data = $this->tasksRepositoryInterface->index();
        return ApiResponseClass::sendResponse(TasksResource::collection($data), '', 200);
    }


    public function store(StoreTasksRequest $request)
    {
        $details = [
            'by' => $request->user()->name,
            'title' => $request->title,
            'category' => $request->category,
            'task_items' => $request->task_items,

        ];
        DB::beginTransaction();
        try {
            $tasks = $this->tasksRepositoryInterface->store($details);

            DB::commit();
            return ApiResponseClass::sendResponse(new TasksResource($tasks), 'Task created ...', 201);
        } catch (\Exception $ex) {
            return ApiResponseClass::rollback($ex);
        }
    }

    public function show($id)
    {
        $tasks = $this->tasksRepositoryInterface->getById($id);

        return ApiResponseClass::sendResponse(new TasksResource($tasks), '', 200);
    }

    public function update(UpdateTasksRequest $request, $id)
    {
        $updateDetails = [
            'by' => $request->user()->name,
            'title' => $request->title,
            'category' => $request->category,
            'task_items' => $request->task_items,
        ];
        DB::beginTransaction();
        try {
            $this->tasksRepositoryInterface->update($updateDetails, $id);

            DB::commit();
            return ApiResponseClass::sendResponse('tasks Update Successful', '', 201);
        } catch (\Exception $ex) {
            return ApiResponseClass::rollback($ex);
        }
    }

    public function destroy($id)
    {
        $this->tasksRepositoryInterface->delete($id);

        return ApiResponseClass::sendResponse('tasks Delete Successful', '', 202);
    }
}
