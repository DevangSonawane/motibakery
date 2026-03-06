import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { toast } from 'sonner';
import { ConfirmDialog } from '@/components/shared/ConfirmDialog';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { StatusBadge } from '@/components/shared/StatusBadge';
import { useDeleteOrder, useOrders } from '@/hooks/useOrders';

const columns = [
  {
    key: 'orderId',
    label: 'Order ID',
    render: (row) => (
      <Link to={`/orders/${row.id}`} className="font-mono text-brand hover:underline">
        {row.orderId}
      </Link>
    ),
  },
  { key: 'product', label: 'Product' },
  { key: 'variant', label: 'Variant' },
  { key: 'date', label: 'Date' },
  { key: 'price', label: 'Price' },
  { key: 'status', label: 'Status', render: (row) => <StatusBadge status={row.status} /> },
  {
    key: 'actions',
    label: 'Actions',
    render: (row) => (
      <button
        type="button"
        onClick={() => row.onDelete?.(row)}
        disabled={!row.canDelete}
        className="rounded-md border border-red-200 px-3 py-1 text-xs font-semibold text-red-700 hover:bg-red-50 disabled:opacity-50"
      >
        Delete
      </button>
    ),
  },
];

const safeArray = (value, key) => {
  if (Array.isArray(value)) return value;
  if (key && Array.isArray(value?.[key])) return value[key];
  return [];
};

const APP_TIMEZONE = 'Asia/Kolkata';

const toOrderStatus = (order) => {
  const raw = String(order?.status || '').toLowerCase();
  if (raw.includes('deliver')) return 'delivered';
  if (raw.includes('progress')) return 'in_progress';
  if (raw.includes('prepare')) return 'prepared';
  if (raw.includes('active')) return 'in_progress';
  if (raw.includes('new') || raw.includes('pending')) return 'new';
  return raw || 'new';
};

const formatDateValue = (value) => {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: APP_TIMEZONE,
  });
};

const getOrderDateValue = (order) => {
  const deliveryTime = order.deliveryTime || order.delivery_time;
  if (deliveryTime) return formatDateValue(deliveryTime);

  const direct = order.deliveryAt || order.delivery_at || order.delivery || order.slot || order.timeSlot;

  if (direct) return formatDateValue(direct);

  const datePart = order.deliveryDate || order.delivery_date || order.orderDate || order.order_date;
  const timePart = order.time || order.orderTime || order.order_time;

  if (datePart && timePart) {
    return formatDateValue(`${datePart} ${timePart}`);
  }

  return '-';
};

const formatPriceValue = (value) => {
  if (value == null || value === '') return '-';
  if (typeof value === 'number') {
    return `₹${Number.isInteger(value) ? value : value.toFixed(2)}`;
  }
  const raw = String(value).trim();
  if (!raw) return '-';
  if (/[₹$€£]/.test(raw)) return raw;
  const numeric = Number(raw.replace(/,/g, ''));
  if (!Number.isNaN(numeric)) {
    return `₹${Number.isInteger(numeric) ? numeric : numeric.toFixed(2)}`;
  }
  return raw;
};

const getProductName = (order) => {
  if (order?.product && typeof order.product === 'object') {
    const nestedName = order.product.name || order.product.title;
    if (nestedName) return nestedName;
  }
  return (
    order.productName ||
    order.product_name ||
    order.itemName ||
    order.item_name ||
    order.cake ||
    order.cake_name ||
    order.title ||
    order.name ||
    'Product'
  );
};

const normalizeVariantValue = (value) => {
  if (value == null) return '';
  if (Array.isArray(value)) {
    return value
      .map((item) => normalizeVariantValue(item))
      .filter(Boolean)
      .join(' / ');
  }
  if (typeof value === 'object') {
    return (
      value.value ||
      value.name ||
      value.label ||
      value.title ||
      value.option ||
      value.optionValue ||
      value.option_value ||
      ''
    );
  }
  if (typeof value === 'number') {
    return `${value} kg`;
  }
  return String(value);
};

const getVariantValue = (order) => {
  const candidates = [
    order.variant,
    order.variantName,
    order.variant_value,
    order.variantValue,
    order.size,
    order.weight,
    order.weightKg,
    order.weight_kg,
    order.option,
    order.optionValue,
    order.option_value,
    order.option1Value,
    order.option1_value,
    order.option2Value,
    order.option2_value,
    order.option3Value,
    order.option3_value,
    order.variant1,
    order.variant2,
    order.variant3,
    order.sku,
    order.variants,
    order.options,
    order.product?.option1_value,
    order.product?.option2_value,
    order.product?.option3_value,
  ];

  for (const candidate of candidates) {
    const normalized = normalizeVariantValue(candidate);
    if (normalized) return normalized;
  }

  return '-';
};

export function OrdersPage() {
  const ordersQuery = useOrders();
  const deleteOrder = useDeleteOrder();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [deleteTarget, setDeleteTarget] = useState(null);

  const orders = useMemo(() => safeArray(ordersQuery.data, 'orders'), [ordersQuery.data]);

  const rows = useMemo(() => {
    return orders.map((order, index) => {
      const price = order.price || order.total || order.amount || order.totalAmount || order.total_price || order.totalPrice;
      const variant = getVariantValue(order);
      const id = order.id ?? null;
      const orderIdRaw = order.order_id ?? order.orderId ?? null;
      return {
        id: order.id || order.orderId || `order_${index}`,
        orderId: order.orderId || order.order_id || order.id || `#ORD-${String(index + 1).padStart(4, '0')}`,
        product: getProductName(order),
        variant,
        date: getOrderDateValue(order),
        price: formatPriceValue(price),
        status: toOrderStatus(order),
        deleteId: id,
        deleteOrderId: orderIdRaw,
        canDelete: Boolean(id || orderIdRaw),
      };
    });
  }, [orders]);

  const filteredRows = useMemo(() => {
    const trimmed = search.trim().toLowerCase();
    return rows.filter((row) => {
      const matchesSearch = !trimmed
        ? true
        : [row.orderId, row.product].some((value) => String(value || '').toLowerCase().includes(trimmed));
      const matchesStatus = statusFilter === 'all' ? true : String(row.status || '') === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [rows, search, statusFilter]);

  const statusOptions = useMemo(() => {
    const unique = new Set(rows.map((row) => row.status).filter(Boolean));
    return ['all', ...Array.from(unique)];
  }, [rows]);

  const handleDeleteRequest = (row) => {
    setDeleteTarget(row);
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await deleteOrder.mutateAsync({ id: deleteTarget.deleteId, orderId: deleteTarget.deleteOrderId });
      setDeleteTarget(null);
    } catch (requestError) {
      toast.error(requestError?.message || 'Failed to delete order');
    }
  };

  return (
    <div>
      <PageHeader title="Orders" subtitle="All orders" action={{ label: 'Export Excel', onClick: () => {} }} />

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          className="h-10 min-w-[220px] rounded-md border border-gray-300 px-3 text-sm"
          placeholder="Search by ID / name"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <select
          className="h-10 rounded-md border border-gray-300 px-3 text-sm"
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value)}
        >
          {statusOptions.map((status) => (
            <option key={status} value={status}>
              {status === 'all' ? 'All Status' : status.replaceAll('_', ' ')}
            </option>
          ))}
        </select>
      </div>

      {ordersQuery.isError ? (
        <div className="mb-4 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {String(ordersQuery.error?.message || 'Failed to load orders')}
        </div>
      ) : null}

      {ordersQuery.isLoading ? (
        <div className="rounded-xl border border-gray-200 bg-white p-6 text-sm text-gray-500 shadow-card">
          Loading orders...
        </div>
      ) : (
        <DataTable
          columns={columns}
          rows={filteredRows.map((row) => ({ ...row, onDelete: handleDeleteRequest }))}
          emptyText="No orders found"
        />
      )}

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Delete order"
        description={`Are you sure you want to delete ${deleteTarget?.orderId || 'this order'}? This cannot be undone.`}
        confirmLabel="Delete"
        loading={deleteOrder.isPending}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
      />
    </div>
  );
}
