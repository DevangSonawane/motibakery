import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { StatusBadge } from '@/components/shared/StatusBadge';

const columns = [
  { key: 'name', label: 'Rule Name' },
  { key: 'type', label: 'Type' },
  { key: 'appliesTo', label: 'Applies To' },
  { key: 'increment', label: 'Increment' },
  { key: 'status', label: 'Status', render: (row) => <StatusBadge status={row.status} /> },
];

const rows = [
  { name: 'Chocolate Premium', type: 'Flavour', appliesTo: 'Chocolate', increment: '+₹50/kg', status: 'active' },
  { name: 'Truffle Luxury', type: 'Flavour', appliesTo: 'Truffle', increment: '+12%', status: 'active' },
  { name: 'Weekend Surcharge', type: 'Global', appliesTo: 'All cakes', increment: '+5%', status: 'inactive' },
];

export function PricingPage() {
  return (
    <div>
      <PageHeader
        title="Pricing Rules"
        subtitle="Configure price adjustments"
        action={{ label: '+ Add Rule', onClick: () => {} }}
        secondaryAction={{ label: 'Import Excel', onClick: () => {} }}
      />
      <DataTable columns={columns} rows={rows} emptyText="No pricing rules found" />
    </div>
  );
}
