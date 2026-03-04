import { QueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      gcTime: 1000 * 60 * 10,
      retry: 2,
      refetchOnWindowFocus: false,
    },
    mutations: {
      onError: (error) => {
        toast.error(error?.response?.data?.message || 'Something went wrong');
      },
    },
  },
});
