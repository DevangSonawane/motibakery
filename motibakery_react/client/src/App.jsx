import { Navigate, Route, Routes } from 'react-router-dom';
import { ProtectedRoute } from '@/components/layout/ProtectedRoute';
import { AdminLayout } from '@/components/layout/AdminLayout';
import { LoginPage } from '@/pages/auth/LoginPage';
import { DashboardPage } from '@/pages/dashboard/DashboardPage';
import { ProductsPage } from '@/pages/products/ProductsPage';
import { ProductDetailPage } from '@/pages/products/ProductDetailPage';
import { PricingPage } from '@/pages/pricing/PricingPage';
import { UsersPage } from '@/pages/users/UsersPage';
import { OrdersPage } from '@/pages/orders/OrdersPage';
import { OrderDetailPage } from '@/pages/orders/OrderDetailPage';
import { NotFoundPage } from '@/pages/NotFoundPage';

function ProtectedApp({ children }) {
  return (
    <ProtectedRoute>
      <AdminLayout>{children}</AdminLayout>
    </ProtectedRoute>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={<Navigate to="/dashboard" replace />} />

      <Route
        path="/dashboard"
        element={
          <ProtectedApp>
            <DashboardPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/products"
        element={
          <ProtectedApp>
            <ProductsPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/products/new"
        element={
          <ProtectedApp>
            <ProductDetailPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/products/:id/edit"
        element={
          <ProtectedApp>
            <ProductDetailPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/pricing"
        element={
          <ProtectedApp>
            <PricingPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/users"
        element={
          <ProtectedApp>
            <UsersPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/orders"
        element={
          <ProtectedApp>
            <OrdersPage />
          </ProtectedApp>
        }
      />
      <Route
        path="/orders/:id"
        element={
          <ProtectedApp>
            <OrderDetailPage />
          </ProtectedApp>
        }
      />

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
