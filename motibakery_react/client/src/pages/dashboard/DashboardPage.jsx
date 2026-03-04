import { useMemo } from 'react';
import { PageHeader } from '@/components/shared/PageHeader';
import { StatusBadge } from '@/components/shared/StatusBadge';
import { useCakes } from '@/hooks/useCakes';
import { useUsers } from '@/hooks/useUsers';
import { useOrders } from '@/hooks/useOrders';

const safeArray = (value, key) => {
  if (Array.isArray(value)) return value;
  if (key && Array.isArray(value?.[key])) return value[key];
  return [];
};

const toOrderStatus = (order) => {
  const raw = String(order?.status || '').toLowerCase();
  if (raw.includes('progress')) return 'in_progress';
  if (raw.includes('prepare')) return 'prepared';
  if (raw.includes('active')) return 'in_progress';
  if (raw.includes('new') || raw.includes('pending')) return 'new';
  return 'new';
};

const formatDateValue = (value) => {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

export function DashboardPage() {
  const cakesQuery = useCakes();
  const usersQuery = useUsers();
  const ordersQuery = useOrders();

  const products = useMemo(() => safeArray(cakesQuery.data), [cakesQuery.data]);
  const users = useMemo(() => safeArray(usersQuery.data, 'users'), [usersQuery.data]);
  const orders = useMemo(() => safeArray(ordersQuery.data, 'orders'), [ordersQuery.data]);

  const activeProductsCount = useMemo(
    () => products.filter((product) => String(product.status || '').toLowerCase() === 'active').length,
    [products]
  );

  const pendingOrdersCount = useMemo(
    () =>
      orders.filter((order) =>
        ['new', 'pending', 'in_progress'].includes(String(order.status || '').toLowerCase())
      ).length,
    [orders]
  );

  const stats = [
    { label: 'Total Products', value: cakesQuery.isSuccess ? String(products.length) : '-' },
    { label: 'Active Products', value: cakesQuery.isSuccess ? String(activeProductsCount) : '-' },
    { label: 'Users', value: usersQuery.isSuccess ? String(users.length) : '-' },
    { label: 'Pending Orders', value: ordersQuery.isSuccess ? String(pendingOrdersCount) : '-' },
  ];

  const recentOrders = useMemo(() => {
    return [...orders]
      .sort((a, b) => {
        const aTime = new Date(a?.createdAt || a?.created_at || a?.created || 0).getTime();
        const bTime = new Date(b?.createdAt || b?.created_at || b?.created || 0).getTime();
        return bTime - aTime;
      })
      .slice(0, 5)
      .map((order, index) => ({
        id: order.id || order.orderId || `order_${index}`,
        orderId: order.orderId || order.order_id || `#ORD-${String(index + 1).padStart(4, '0')}`,
        itemName: order.cake || order.productName || order.product || order.title || 'Product',
        source: order.source || order.counter || order.createdBy || '-',
        slot: formatDateValue(order.delivery || order.deliveryAt || order.createdAt || order.created_at),
        status: toOrderStatus(order),
      }));
  }, [orders]);

  return (
    <div>
      <PageHeader title="Dashboard" subtitle="Live operational data" />

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <div key={stat.label} className="rounded-xl border border-gray-200 bg-white p-5 shadow-card">
            <p className="text-sm text-gray-500">{stat.label}</p>
            <p className="mt-2 text-3xl font-bold text-gray-900">{stat.value}</p>
          </div>
        ))}
      </section>

      {cakesQuery.isError || usersQuery.isError || ordersQuery.isError ? (
        <div className="mt-4 rounded-md border border-orange-200 bg-orange-50 px-4 py-3 text-sm text-orange-700">
          Some widgets could not load. Check Supabase/API connectivity.
        </div>
      ) : null}

      <section className="mt-8 rounded-xl border border-gray-200 bg-white p-6 shadow-card">
        <h3 className="text-lg font-semibold">Recent Orders</h3>
        <div className="mt-4 space-y-3">
          {ordersQuery.isLoading ? (
            <p className="text-sm text-gray-500">Loading recent orders...</p>
          ) : recentOrders.length > 0 ? (
            recentOrders.map((order) => (
              <div key={order.id} className="flex flex-wrap items-center gap-3 rounded-md border border-gray-100 p-3">
                <p className="font-mono text-sm text-gray-700">{order.orderId}</p>
                <p className="text-sm font-medium text-gray-900">{order.itemName}</p>
                <p className="text-sm text-gray-500">{order.source}</p>
                <p className="text-sm text-gray-500">{order.slot}</p>
                <div className="ml-auto">
                  <StatusBadge status={order.status} />
                </div>
              </div>
            ))
          ) : (
            <p className="text-sm text-gray-500">No order records available.</p>
          )}
        </div>
      </section>
    </div>
  );
}
