import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { createUserInSupabase, listUsersFromSupabase } from '@/lib/supabaseUsers';

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
