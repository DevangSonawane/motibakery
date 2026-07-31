import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Eye, EyeOff } from 'lucide-react';

const baseUserSchema = z.object({
  name: z.string().min(2, 'Full name must be at least 2 characters').max(60, 'Full name must be at most 60 characters'),
  email: z.string().email('Enter a valid Gmail address').refine((value) => value.endsWith('@gmail.com'), {
    message: 'Only @gmail.com addresses are allowed',
  }),
  role: z.enum(['counter', 'cake_room', 'admin'], {
    errorMap: () => ({ message: 'Select a valid role' }),
  }),
});

const createUserSchema = baseUserSchema.extend({
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

const editUserSchema = baseUserSchema.extend({
  password: z.string().refine((value) => value === '' || value.length >= 8, {
    message: 'Password must be at least 8 characters',
  }),
});

const EMPTY_FORM_VALUES = {
  name: '',
  email: '',
  role: 'counter',
  password: '',
};

export function UserForm({
  onSubmit,
  onCancel,
  loading = false,
  defaultValues = EMPTY_FORM_VALUES,
  mode = 'create',
  submitLabel,
}) {
  const [showPassword, setShowPassword] = useState(false);
  const schema = mode === 'edit' ? editUserSchema : createUserSchema;
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
    defaultValues: {
      ...EMPTY_FORM_VALUES,
      ...defaultValues,
    },
  });

  useEffect(() => {
    reset({
      ...EMPTY_FORM_VALUES,
      ...defaultValues,
    });
    setShowPassword(false);
  }, [defaultValues, reset]);

  const resolvedSubmitLabel = submitLabel || (mode === 'edit' ? 'Save Changes' : 'Create User');
  const resolvedLoadingLabel = loading ? (mode === 'edit' ? 'Saving...' : 'Creating...') : resolvedSubmitLabel;

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
          <option value="cake_room">Cake</option>
          <option value="admin">Admin</option>
        </select>
        {errors.role ? <p className="mt-1 text-xs text-red-600">{errors.role.message}</p> : null}
      </div>

      <div>
        <label className="mb-1 block text-sm font-medium text-gray-700">
          Password {mode === 'edit' ? <span className="text-gray-400">(optional)</span> : null}
        </label>
        <div className="relative">
          <input
            type={showPassword ? 'text' : 'password'}
            autoComplete="new-password"
            {...register('password')}
            className="h-10 w-full rounded-md border border-gray-300 px-3 pr-10 text-sm outline-none ring-brand/20 focus:ring-2"
            placeholder={mode === 'edit' ? 'Leave blank to keep current password' : 'At least 8 characters'}
          />
          <button
            type="button"
            onClick={() => setShowPassword((current) => !current)}
            className="absolute inset-y-0 right-0 flex items-center px-3 text-gray-500 hover:text-gray-700"
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            aria-pressed={showPassword}
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
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
          {resolvedLoadingLabel}
        </button>
      </div>
    </form>
  );
}
