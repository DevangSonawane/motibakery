import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { deleteOrderInSupabase, listOrdersFromSupabase } from '@/lib/supabaseOrders';

export const useOrders = (filters = {}) =>
  useQuery({
    queryKey: ['orders', filters],
    queryFn: () => listOrdersFromSupabase(),
  });

export const useOrder = (id) =>
  useQuery({
    queryKey: ['orders', id],
    queryFn: async () => {
      const rows = await listOrdersFromSupabase();
      return rows.find((row) => String(row.id) === String(id)) || null;
    },
    enabled: Boolean(id),
  });

export const useDeleteOrder = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, orderId }) => deleteOrderInSupabase({ id, orderId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      toast.success('Order deleted');
    },
  });
};
