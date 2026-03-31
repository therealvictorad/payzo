<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payzo — Admin Login</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body {
            min-height: 100vh;
            background: linear-gradient(135deg, #1e1b4b 0%, #312e81 50%, #4f46e5 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Segoe UI', sans-serif;
        }

        .login-card {
            background: #fff;
            border-radius: 16px;
            padding: 2.5rem;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 25px 50px rgba(0,0,0,.25);
        }

        .login-card .brand {
            text-align: center;
            margin-bottom: 2rem;
        }

        .login-card .brand .logo {
            font-size: 2.5rem;
            display: block;
            margin-bottom: .5rem;
        }

        .login-card .brand h4 {
            font-weight: 700;
            color: #1e293b;
            margin: 0;
        }

        .login-card .brand p {
            color: #64748b;
            font-size: .85rem;
            margin: .25rem 0 0;
        }

        .form-label { font-size: .85rem; font-weight: 600; color: #374151; }

        .form-control {
            border-color: #e2e8f0;
            border-radius: 8px;
            padding: .65rem .9rem;
            font-size: .9rem;
        }

        .form-control:focus {
            border-color: #4f46e5;
            box-shadow: 0 0 0 3px rgba(79,70,229,.15);
        }

        .btn-login {
            background: #4f46e5;
            border: none;
            border-radius: 8px;
            padding: .75rem;
            font-weight: 600;
            font-size: .95rem;
            transition: background .2s;
        }

        .btn-login:hover { background: #3730a3; }

        .alert { border-radius: 8px; font-size: .875rem; }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="brand">
            <span class="logo">💳</span>
            <h4>Payzo Admin</h4>
            <p>Sign in to access the dashboard</p>
        </div>

        @if(session('error'))
            <div class="alert alert-danger">
                <i class="bi bi-exclamation-circle me-2"></i>{{ session('error') }}
            </div>
        @endif

        <form method="POST" action="{{ route('admin.login.post') }}">
            @csrf
            <div class="mb-3">
                <label class="form-label">Email Address</label>
                <input
                    type="email"
                    name="email"
                    class="form-control @error('email') is-invalid @enderror"
                    value="{{ old('email', 'admin@payzo.com') }}"
                    required
                    autofocus
                >
                @error('email')
                    <div class="invalid-feedback">{{ $message }}</div>
                @enderror
            </div>

            <div class="mb-4">
                <label class="form-label">Password</label>
                <input
                    type="password"
                    name="password"
                    class="form-control @error('password') is-invalid @enderror"
                    required
                >
                @error('password')
                    <div class="invalid-feedback">{{ $message }}</div>
                @enderror
            </div>

            <button type="submit" class="btn btn-login btn-primary w-100 text-white">
                <i class="bi bi-box-arrow-in-right me-2"></i>Sign In
            </button>
        </form>

        <p class="text-center text-muted mt-3 mb-0" style="font-size:.75rem;">
            Admin access only &nbsp;·&nbsp; Payzo Fintech
        </p>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
