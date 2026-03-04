import { useQuery } from '@tanstack/react-query';
import api from '@/lib/axios';

export const useOrders = (filters = {}) =>
  useQuery({
    queryKey: ['orders', filters],
    queryFn: () => api.get('/orders', { params: filters }).then((response) => response.data),
  });

export const useOrder = (id) =>
  useQuery({
    queryKey: ['orders', id],
    queryFn: () => api.get(`/orders/${id}`).then((response) => response.data),
    enabled: Boolean(id),
  });
