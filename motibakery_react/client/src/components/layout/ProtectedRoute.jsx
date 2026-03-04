import { Navigate } from 'react-router-dom';
import { getValidStoredSupabaseToken } from '@/lib/authToken';

export function ProtectedRoute({ children }) {
  const token = getValidStoredSupabaseToken();

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  return children;
}
