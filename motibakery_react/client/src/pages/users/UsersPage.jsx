import { useMemo, useState } from 'react';
import { toast } from 'sonner';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { UserForm } from '@/components/forms/UserForm';
import { useCreateUser, useUsers } from '@/hooks/useUsers';

const formatRole = (role) => {
  if (role === 'cake_room') return 'Cake';
  if (role === 'counter') return 'Counter';
  if (role === 'admin') return 'Admin';
  return role || '-';
};

const mapUserRow = (user, fallbackIndex = 0) => ({
  id: user.uid || user.id || user._id || `user_${fallbackIndex}`,
  name: user.full_name || user.name || user.fullName || '-',
  email: user.gmail || user.email || '-',
  role: user.role || 'counter',
});

const columns = [
  { key: 'name', label: 'Name' },
  { key: 'email', label: 'Gmail' },
  { key: 'role', label: 'Role', render: (row) => formatRole(row.role) },
];

function AddUserModal({ open, onClose, onSubmit, loading }) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-modal">
        <h3 className="text-lg font-semibold text-gray-900">Add User</h3>
        <p className="mt-1 text-sm text-gray-500">Create Counter, Cake, or Admin access account.</p>
        <div className="mt-5">
          <UserForm onSubmit={onSubmit} onCancel={onClose} loading={loading} />
        </div>
      </div>
    </div>
  );
}

export function UsersPage() {
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);

  const usersQuery = useUsers();
  const createUser = useCreateUser();

  const sourceUsers = useMemo(() => {
    if (!usersQuery.isSuccess) return [];

    const payload = usersQuery.data;
    const list = Array.isArray(payload) ? payload : payload?.users;

    if (!Array.isArray(list)) {
      return [];
    }

    return list.map((user, index) => mapUserRow(user, index));
  }, [usersQuery.data, usersQuery.isSuccess]);

  const filteredUsers = useMemo(() => {
    const term = search.trim().toLowerCase();

    return sourceUsers.filter((user) => {
      const matchesSearch =
        !term || user.name.toLowerCase().includes(term) || user.email.toLowerCase().includes(term);
      const matchesRole = roleFilter === 'all' || user.role === roleFilter;
      return matchesSearch && matchesRole;
    });
  }, [roleFilter, search, sourceUsers]);

  const handleCreateUser = async (values) => {
    const payload = {
      name: values.name,
      email: values.email,
      role: values.role,
      password: values.password,
    };

    try {
      await createUser.mutateAsync(payload);
      setShowAddModal(false);
    } catch (error) {
      toast.error(error?.message || 'Failed to create user in Supabase.');
    }
  };

  return (
    <div>
      <PageHeader title="Users" subtitle="Manage access" action={{ label: '+ Add User', onClick: () => setShowAddModal(true) }} />

      {usersQuery.isError ? (
        <div className="mb-4 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {usersQuery.error?.message || 'Failed to fetch users from Supabase.'}
        </div>
      ) : null}

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="h-10 min-w-[220px] rounded-md border border-gray-300 px-3 text-sm"
          placeholder="Search users..."
        />
        <select
          value={roleFilter}
          onChange={(event) => setRoleFilter(event.target.value)}
          className="h-10 rounded-md border border-gray-300 px-3 text-sm"
        >
          <option value="all">All Roles</option>
          <option value="counter">Counter</option>
          <option value="cake_room">Cake</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      {usersQuery.isLoading ? (
        <div className="rounded-xl border border-gray-200 bg-white p-6 text-sm text-gray-500 shadow-card">Loading users...</div>
      ) : (
        <DataTable columns={columns} rows={filteredUsers} emptyText="No users found" />
      )}

      <AddUserModal
        open={showAddModal}
        onClose={() => setShowAddModal(false)}
        onSubmit={handleCreateUser}
        loading={createUser.isPending}
      />
    </div>
  );
}
