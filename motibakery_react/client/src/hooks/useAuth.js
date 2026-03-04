import { useAuthStore } from '@/stores/authStore';

export const useAuth = () => {
  const token = useAuthStore((state) => state.token);
  const user = useAuthStore((state) => state.user);
  const setAuth = useAuthStore((state) => state.setAuth);
  const clearAuth = useAuthStore((state) => state.clearAuth);

  return {
    isAuthenticated: Boolean(token),
    token,
    user,
    setAuth,
    clearAuth,
  };
};
