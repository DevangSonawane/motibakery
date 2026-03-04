import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import {
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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cakes'] });
      toast.success('Cake added successfully');
    },
  });
};

export const useImportCakes = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => upsertImportedProductsInSupabase(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cakes'] });
      toast.success('Products imported successfully');
    },
  });
};

export const useUpdateCake = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }) => updateProductInSupabase(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cakes'] });
      toast.success('Product updated successfully');
    },
  });
};

export const useDeleteCake = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id) => deleteProductInSupabase(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cakes'] });
      toast.success('Product deleted');
    },
  });
};
