import { Link } from 'react-router-dom';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { StatusBadge } from '@/components/shared/StatusBadge';

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
  { key: 'cake', label: 'Cake' },
  { key: 'weight', label: 'Weight' },
  { key: 'delivery', label: 'Delivery' },
  { key: 'total', label: 'Total' },
  { key: 'status', label: 'Status', render: (row) => <StatusBadge status={row.status} /> },
  { key: 'created', label: 'Created' },
];

const rows = [
  {
    id: '42',
    orderId: '#ORD-0042',
    cake: 'Black Forest',
    weight: '1.5 kg',
    delivery: '12 Mar, 3:00PM',
    total: '₹855',
    status: 'prepared',
    created: 'Today 9:12AM',
  },
  {
    id: '41',
    orderId: '#ORD-0041',
    cake: 'Truffle Royale',
    weight: '3 kg',
    delivery: '12 Mar, 5:00PM',
    total: '₹1560',
    status: 'in_progress',
    created: 'Today 8:50AM',
  },
  {
    id: '40',
    orderId: '#ORD-0040',
    cake: 'Mango Delight',
    weight: '1 kg',
    delivery: '14 Mar, 6:00PM',
    total: '₹290',
    status: 'new',
    created: 'Yesterday 4PM',
  },
];

export function OrdersPage() {
  return (
    <div>
      <PageHeader title="Orders" subtitle="All orders" action={{ label: 'Export Excel', onClick: () => {} }} />

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          className="h-10 min-w-[220px] rounded-md border border-gray-300 px-3 text-sm"
          placeholder="Search by ID / name"
        />
        <select className="h-10 rounded-md border border-gray-300 px-3 text-sm">
          <option>All Status</option>
        </select>
      </div>

      <DataTable columns={columns} rows={rows} emptyText="No orders found" />
    </div>
  );
}
