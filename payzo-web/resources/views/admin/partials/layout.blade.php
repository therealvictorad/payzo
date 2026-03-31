<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payzo Admin — @yield('title', 'Dashboard')</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root {
            --sidebar-width: 240px;
            --brand-color: #4f46e5;
            --brand-dark:  #3730a3;
        }

        body { background: #f1f5f9; font-family: 'Segoe UI', sans-serif; }

        /* ── Sidebar ── */
        #sidebar {
            width: var(--sidebar-width);
            min-height: 100vh;
            background: #1e1b4b;
            position: fixed;
            top: 0; left: 0;
            display: flex;
            flex-direction: column;
            z-index: 100;
        }

        #sidebar .brand {
            padding: 1.5rem 1.25rem 1rem;
            border-bottom: 1px solid rgba(255,255,255,.08);
        }

        #sidebar .brand span {
            font-size: 1.4rem;
            font-weight: 700;
            color: #fff;
            letter-spacing: .5px;
        }

        #sidebar .brand small {
            display: block;
            color: #a5b4fc;
            font-size: .7rem;
            margin-top: 2px;
        }

        #sidebar .nav-link {
            color: #c7d2fe;
            padding: .65rem 1.25rem;
            border-radius: 8px;
            margin: 2px .75rem;
            font-size: .875rem;
            display: flex;
            align-items: center;
            gap: .6rem;
            transition: background .15s, color .15s;
        }

        #sidebar .nav-link:hover,
        #sidebar .nav-link.active {
            background: rgba(255,255,255,.1);
            color: #fff;
        }

        #sidebar .nav-link i { font-size: 1rem; width: 18px; }

        #sidebar .nav-section {
            color: #6366f1;
            font-size: .65rem;
            font-weight: 700;
            letter-spacing: 1px;
            text-transform: uppercase;
            padding: 1rem 1.25rem .35rem;
        }

        #sidebar .logout-area {
            margin-top: auto;
            padding: 1rem .75rem;
            border-top: 1px solid rgba(255,255,255,.08);
        }

        /* ── Main content ── */
        #main {
            margin-left: var(--sidebar-width);
            min-height: 100vh;
        }

        #topbar {
            background: #fff;
            border-bottom: 1px solid #e2e8f0;
            padding: .85rem 1.75rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 50;
        }

        #topbar .page-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: #1e293b;
            margin: 0;
        }

        #topbar .admin-badge {
            background: #ede9fe;
            color: var(--brand-color);
            font-size: .75rem;
            font-weight: 600;
            padding: .3rem .75rem;
            border-radius: 20px;
        }

        .content-area { padding: 1.75rem; }

        /* ── Cards ── */
        .stat-card {
            background: #fff;
            border-radius: 12px;
            padding: 1.5rem;
            border: 1px solid #e2e8f0;
            transition: box-shadow .2s;
        }

        .stat-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.07); }

        .stat-card .icon-wrap {
            width: 48px; height: 48px;
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 1.3rem;
            margin-bottom: 1rem;
        }

        .stat-card .stat-value {
            font-size: 1.9rem;
            font-weight: 700;
            color: #1e293b;
            line-height: 1;
        }

        .stat-card .stat-label {
            font-size: .8rem;
            color: #64748b;
            margin-top: .35rem;
        }

        /* ── Tables ── */
        .table-card {
            background: #fff;
            border-radius: 12px;
            border: 1px solid #e2e8f0;
            overflow: hidden;
        }

        .table-card .table-header {
            padding: 1.1rem 1.5rem;
            border-bottom: 1px solid #f1f5f9;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .table-card .table-header h6 {
            font-weight: 600;
            color: #1e293b;
            margin: 0;
        }

        .table thead th {
            background: #f8fafc;
            color: #64748b;
            font-size: .75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: .5px;
            border-bottom: 1px solid #e2e8f0;
            padding: .75rem 1rem;
        }

        .table tbody td {
            padding: .85rem 1rem;
            vertical-align: middle;
            font-size: .875rem;
            color: #334155;
            border-bottom: 1px solid #f1f5f9;
        }

        .table tbody tr:last-child td { border-bottom: none; }
        .table tbody tr:hover td { background: #fafbff; }

        /* ── Badges ── */
        .badge-success { background: #dcfce7; color: #16a34a; }
        .badge-failed  { background: #fee2e2; color: #dc2626; }
        .badge-high    { background: #fee2e2; color: #dc2626; }
        .badge-medium  { background: #fef9c3; color: #ca8a04; }
        .badge-low     { background: #dbeafe; color: #2563eb; }
        .badge-admin   { background: #ede9fe; color: #7c3aed; }
        .badge-agent   { background: #fce7f3; color: #be185d; }
        .badge-user    { background: #f0fdf4; color: #15803d; }

        .risk-high td { background: #fff5f5 !important; }

        /* ── Filter bar ── */
        .filter-bar {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            padding: .85rem 1.5rem;
            display: flex;
            gap: .75rem;
            flex-wrap: wrap;
            align-items: center;
        }

        .filter-bar .form-control,
        .filter-bar .form-select {
            font-size: .8rem;
            padding: .4rem .75rem;
            border-color: #e2e8f0;
            border-radius: 8px;
            max-width: 180px;
        }

        .filter-bar .btn { font-size: .8rem; padding: .4rem .9rem; border-radius: 8px; }

        /* ── Login page ── */
        .login-wrapper {
            min-height: 100vh;
            background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4f46e5 100%);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-card {
            background: #fff;
            border-radius: 16px;
            padding: 2.5rem;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 25px 50px rgba(0,0,0,.25);
        }
    </style>
</head>
<body>

{{-- Sidebar --}}
<div id="sidebar">
    <div class="brand">
        <span>💳 Payzo</span>
        <small>Admin Dashboard</small>
    </div>

    <nav class="mt-2">
        <div class="nav-section">Main</div>
        <a href="{{ route('admin.dashboard') }}"
           class="nav-link {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
            <i class="bi bi-grid-1x2"></i> Dashboard
        </a>

        <div class="nav-section">Management</div>
        <a href="{{ route('admin.users') }}"
           class="nav-link {{ request()->routeIs('admin.users') ? 'active' : '' }}">
            <i class="bi bi-people"></i> Users
        </a>
        <a href="{{ route('admin.transactions') }}"
           class="nav-link {{ request()->routeIs('admin.transactions') ? 'active' : '' }}">
            <i class="bi bi-arrow-left-right"></i> Transactions
        </a>
        <a href="{{ route('admin.fraud-logs') }}"
           class="nav-link {{ request()->routeIs('admin.fraud-logs') ? 'active' : '' }}">
            <i class="bi bi-shield-exclamation"></i> Fraud Logs
        </a>

        <div class="nav-section">Services</div>
        <a href="{{ route('admin.topups') }}"
           class="nav-link {{ request()->routeIs('admin.topups') ? 'active' : '' }}">
            <i class="bi bi-phone"></i> Top-ups
        </a>
        <a href="{{ route('admin.bills') }}"
           class="nav-link {{ request()->routeIs('admin.bills') ? 'active' : '' }}">
            <i class="bi bi-receipt"></i> Bills
        </a>
        <a href="{{ route('admin.payment-links') }}"
           class="nav-link {{ request()->routeIs('admin.payment-links') ? 'active' : '' }}">
            <i class="bi bi-link-45deg"></i> Payment Links
        </a>
        <a href="{{ route('admin.cards') }}"
           class="nav-link {{ request()->routeIs('admin.cards') ? 'active' : '' }}">
            <i class="bi bi-credit-card"></i> Virtual Cards
        </a>
    </nav>

    <div class="logout-area">
        <form method="POST" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit" class="nav-link border-0 bg-transparent w-100 text-start">
                <i class="bi bi-box-arrow-left"></i> Logout
            </button>
        </form>
    </div>
</div>

{{-- Main --}}
<div id="main">
    <div id="topbar">
        <h1 class="page-title">@yield('title', 'Dashboard')</h1>
        <span class="admin-badge">
            <i class="bi bi-person-fill me-1"></i>
            {{ session('admin_name', 'Admin') }}
        </span>
    </div>

    <div class="content-area">
        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                {{ session('error') }}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        @endif

        @yield('content')
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
@yield('scripts')
</body>
</html>
