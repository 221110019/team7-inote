<!DOCTYPE html>
<html>

<head>
    <title>All Tables</title>
    <style>
        body {
            background: hsl(231, 76%, 70%);
            font-size: 12px;
        }

        table {
            border-collapse: collapse;
            margin-bottom: 30px;
        }

        th,
        td {
            border: 1px solid #ffffff;
            padding: 8px;
        }

        th {
            background: #6d98fb;
        }
    </style>
</head>

<body>
    @foreach ($tables as $tableName => $rows)
    <h2>{{ ucfirst($tableName) }}</h2>
    @if (count($rows))
    <table>
        <thead>
            <tr>
                @foreach (array_keys($rows[0]->getAttributes()) as $col)
                <th>{{ $col }}</th>
                @endforeach
            </tr>
        </thead>
        <tbody>
            @foreach ($rows as $row)
            <tr>
                @foreach ($row->getAttributes() as $cell)
                <td>{{ $cell }}</td>
                @endforeach
            </tr>
            @endforeach
        </tbody>
    </table>
    @else
    <p>No data found.</p>
    @endif
    @endforeach