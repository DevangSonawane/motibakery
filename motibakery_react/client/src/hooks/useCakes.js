import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import {
  bulkUpdateProductsInSupabase,
  createProductInSupabase,
  deleteProductInSupabase,
  listProductsFromSupabase,
  updateProductInSupabase,
  upsertImportedProductsInSupabase,
} from '@/lib/supabaseProducts';

export const useCakes = (filters = {}) =>
  useQuery({
    queryKey: ['cakes', filters],
    queryFn: () => listProductsFromSupabase(),
  });

export const useCreateCake = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => createProductInSupabase(payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['cakes'] });
      await queryClient.refetchQueries({ queryKey: ['cakes'] });
      toast.success('Cake added successfully');
    },
  });
};

export const useImportCakes = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => upsertImportedProductsInSupabase(payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['cakes'] });
      await queryClient.refetchQueries({ queryKey: ['cakes'] });
      toast.success('Products imported successfully');
    },
  });
};

export const useUpdateCake = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }) => updateProductInSupabase(id, payload),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['cakes'] });
      await queryClient.refetchQueries({ queryKey: ['cakes'] });
      toast.success('Product updated successfully');
    },
  });
};

export const useDeleteCake = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id) => deleteProductInSupabase(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['cakes'] });
      await queryClient.refetchQueries({ queryKey: ['cakes'] });
      toast.success('Product deleted');
    },
  });
};

export const useBulkUpdateCakes = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (bulkSpec) => bulkUpdateProductsInSupabase(bulkSpec),
    onSuccess: async (result) => {
      await queryClient.invalidateQueries({ queryKey: ['cakes'] });
      await queryClient.refetchQueries({ queryKey: ['cakes'] });
      toast.success(`Bulk update applied: ${result?.updated ?? 0} products updated`);
    },
    onError: (error) => {
      toast.error(error?.message || 'Bulk update failed');
    },
  });
};
