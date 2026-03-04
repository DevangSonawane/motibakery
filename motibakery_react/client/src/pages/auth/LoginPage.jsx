import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Navigate, useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { loginWithSupabaseEmailPassword } from '@/lib/supabaseAuth';
import { useAuthStore } from '@/stores/authStore';

const loginSchema = z.object({
  email: z.string().email('Enter a valid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

export function LoginPage() {
  const defaultLoginEmail = import.meta.env.VITE_ADMIN_EMAIL || 'admin@gmail.com';
  const navigate = useNavigate();
  const token = useAuthStore((state) => state.token);
  const setAuth = useAuthStore((state) => state.setAuth);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: defaultLoginEmail, password: '' },
  });

  if (token) {
    return <Navigate to="/dashboard" replace />;
  }

  const onSubmit = async (values) => {
    try {
      const session = await loginWithSupabaseEmailPassword(values.email, values.password);
      setAuth(session.token, session.user);
      navigate('/dashboard', { replace: true });
    } catch (error) {
      toast.error(error?.message || 'Unable to sign in');
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 p-4">
      <div className="w-full max-w-[420px] rounded-2xl bg-white p-8 shadow-[0_4px_24px_rgba(0,0,0,0.08)]">
        <div className="mx-auto mb-5 flex h-20 w-20 items-center justify-center rounded-full bg-brand-pale text-2xl font-bold text-brand">
          MB
        </div>
        <h1 className="text-center text-2xl font-bold">Welcome back</h1>
        <p className="mt-2 text-center text-sm text-gray-400">Sign in to your admin account</p>

        <form className="mt-6 space-y-4" onSubmit={handleSubmit(onSubmit)}>
          <div>
            <label className="mb-1 block text-sm font-medium">Email Address</label>
            <input
              type="email"
              autoComplete="email"
              {...register('email')}
              className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
            />
            {errors.email ? <p className="mt-1 text-xs text-red-600">{errors.email.message}</p> : null}
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium">Password</label>
            <input
              type="password"
              autoComplete="current-password"
              {...register('password')}
              className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
            />
            {errors.password ? <p className="mt-1 text-xs text-red-600">{errors.password.message}</p> : null}
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="h-10 w-full rounded-md bg-brand text-sm font-semibold text-white hover:bg-brand-dark disabled:opacity-60"
          >
            {isSubmitting ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <p className="mt-4 text-center text-xs text-gray-400">Authorized staff access only</p>
      </div>
    </div>
  );
}
