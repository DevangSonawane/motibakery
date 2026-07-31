import { useMemo, useState } from 'react';
import { Pencil, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { UserForm } from '@/components/forms/UserForm';
import { useCreateUser, useDeleteUser, useUpdateUser, useUsers } from '@/hooks/useUsers';

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

const EMPTY_USER_FORM = {
  name: '',
  email: '',
  role: 'counter',
  password: '',
};

function buildColumns(onEdit, onDelete) {
  return [
    { key: 'name', label: 'Name' },
    { key: 'email', label: 'Gmail' },
    { key: 'role', label: 'Role', render: (row) => formatRole(row.role) },
    {
      key: 'actions',
      label: 'Actions',
      render: (row) => (
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onEdit(row)}
            className="inline-flex items-center gap-1 rounded-md border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50"
          >
            <Pencil size={14} />
            Edit
          </button>
          <button
            type="button"
            onClick={() => onDelete(row)}
            className="inline-flex items-center gap-1 rounded-md border border-red-200 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-50"
          >
            <Trash2 size={14} />
            Delete
          </button>
        </div>
      ),
    },
  ];
}

function UserModal({ open, title, description, onClose, onSubmit, loading, mode = 'create', defaultValues = EMPTY_USER_FORM }) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-modal">
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        <p className="mt-1 text-sm text-gray-500">{description}</p>
        <div className="mt-5">
          <UserForm
            key={`${mode}-${defaultValues.id || defaultValues.email || 'user'}`}
            mode={mode}
            defaultValues={defaultValues}
            onSubmit={onSubmit}
            onCancel={onClose}
            loading={loading}
            submitLabel={mode === 'edit' ? 'Save Changes' : 'Create User'}
          />
        </div>
      </div>
    </div>
  );
}

export function UsersPage() {
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [deletingUser, setDeletingUser] = useState(null);

  const usersQuery = useUsers();
  const createUser = useCreateUser();
  const updateUser = useUpdateUser();
  const deleteUser = useDeleteUser();

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

  const columns = useMemo(
    () =>
      buildColumns(
        (row) => {
          setEditingUser({
            id: row.id,
            name: row.name === '-' ? '' : row.name,
            email: row.email === '-' ? '' : row.email,
            role: row.role || 'counter',
            password: '',
          });
          setShowAddModal(false);
        },
        (row) => setDeletingUser(row)
      ),
    []
  );

  const handleCreateUser = async (values) => {
    const payload = {
      name: values.name.trim(),
      email: values.email.trim(),
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

  const handleUpdateUser = async (values) => {
    if (!editingUser?.id) {
      toast.error('No user selected for editing.');
      return;
    }

    const payload = {
      uid: editingUser.id,
      name: values.name.trim(),
      email: values.email.trim(),
      role: values.role,
    };

    if (values.password) {
      payload.password = values.password;
    }

    try {
      await updateUser.mutateAsync(payload);
      setEditingUser(null);
    } catch (error) {
      toast.error(error?.message || 'Failed to update user in Supabase.');
    }
  };

  const confirmDeleteUser = async () => {
    if (!deletingUser?.id) {
      toast.error('No user selected for deletion.');
      return;
    }

    try {
      await deleteUser.mutateAsync(deletingUser.id);
      setDeletingUser(null);
    } catch (error) {
      toast.error(error?.message || 'Failed to delete user from Supabase.');
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

      <UserModal
        open={showAddModal}
        title="Add User"
        description="Create Counter, Cake, or Admin access account."
        onClose={() => setShowAddModal(false)}
        onSubmit={handleCreateUser}
        loading={createUser.isPending}
        mode="create"
        defaultValues={EMPTY_USER_FORM}
      />

      <UserModal
        open={Boolean(editingUser)}
        title="Edit User"
        description="Update the user's profile, Gmail, role, or password."
        onClose={() => setEditingUser(null)}
        onSubmit={handleUpdateUser}
        loading={updateUser.isPending}
        mode="edit"
        defaultValues={editingUser || EMPTY_USER_FORM}
      />

      <ConfirmDialog
        open={Boolean(deletingUser)}
        title="Delete User"
        description={
          deletingUser
            ? `Delete ${deletingUser.name} (${deletingUser.email})? This removes the auth account and user record permanently.`
            : 'Delete this user?'
        }
        confirmLabel="Delete User"
        onConfirm={confirmDeleteUser}
        onCancel={() => setDeletingUser(null)}
        loading={deleteUser.isPending}
      />
    </div>
  );
}
