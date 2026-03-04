import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import api from '@/lib/axios';

export const usePricingRules = () =>
  useQuery({
    queryKey: ['pricing-rules'],
    queryFn: () => api.get('/pricing-rules').then((response) => response.data),
  });

export const useCreatePricingRule = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.post('/pricing-rules', payload).then((response) => response.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pricing-rules'] });
      toast.success('Pricing rule created');
    },
  });
};
