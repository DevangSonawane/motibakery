import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { createUserInSupabase, deleteUserFromSupabase, listUsersFromSupabase, updateUserInSupabase } from '@/lib/supabaseUsers';

export const useUsers = (filters = {}) =>
  useQuery({
    queryKey: ['users', filters],
    queryFn: () => listUsersFromSupabase(),
  });

export const useCreateUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => createUserInSupabase(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast.success('User created');
    },
  });
};

export const useUpdateUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => updateUserInSupabase(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast.success('User updated');
    },
  });
};

export const useDeleteUser = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (uid) => deleteUserFromSupabase(uid),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      toast.success('User deleted');
    },
  });
};
