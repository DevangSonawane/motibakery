import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';

const userSchema = z.object({
  name: z.string().min(2, 'Full name must be at least 2 characters').max(60, 'Full name must be at most 60 characters'),
  email: z.string().email('Enter a valid Gmail address').refine((value) => value.endsWith('@gmail.com'), {
    message: 'Only @gmail.com addresses are allowed',
  }),
  role: z.enum(['counter', 'cake_room'], {
    errorMap: () => ({ message: 'Select a valid role' }),
  }),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

export function UserForm({ onSubmit, onCancel, loading = false }) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(userSchema),
    defaultValues: {
      name: '',
      email: '',
      role: 'counter',
      password: '',
    },
  });

  return (
    <form className="space-y-4" onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Full Name</label>
        <input
          type="text"
          {...register('name')}
          className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
          placeholder="Priya Shah"
        />
        {errors.name ? <p className="mt-1 text-xs text-red-600">{errors.name.message}</p> : null}
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Gmail</label>
        <input
          type="email"
          autoComplete="email"
          {...register('email')}
          className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
          placeholder="counter1@gmail.com"
        />
        {errors.email ? <p className="mt-1 text-xs text-red-600">{errors.email.message}</p> : null}
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Role</label>
        <select
          {...register('role')}
          className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
        >
          <option value="counter">Counter</option>
          <option value="cake_room">Cake Room</option>
        </select>
        {errors.role ? <p className="mt-1 text-xs text-red-600">{errors.role.message}</p> : null}
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">Password</label>
        <input
          type="password"
          autoComplete="new-password"
          {...register('password')}
          className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm outline-none ring-brand/20 focus:ring-2"
          placeholder="At least 8 characters"
        />
        {errors.password ? <p className="mt-1 text-xs text-red-600">{errors.password.message}</p> : null}
      </div>

      <div className="flex items-center justify-end gap-3 pt-2">
        <button
          type="button"
          onClick={onCancel}
          className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark disabled:opacity-60"
        >
          {loading ? 'Creating...' : 'Create User'}
        </button>
      </div>
    </form>
  );
}
