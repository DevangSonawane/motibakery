import { useQuery } from '@tanstack/react-query';
import { listOrdersFromSupabase } from '@/lib/supabaseOrders';

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
