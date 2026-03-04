import { cn } from '@/lib/utils';

const styles = {
  new: 'bg-gray-100 text-gray-600',
  in_progress: 'bg-blue-50 text-blue-700',
  prepared: 'bg-green-50 text-green-700',
  active: 'bg-orange-50 text-orange-600',
  inactive: 'bg-gray-100 text-gray-400',
};

const labels = {
  new: 'New',
  in_progress: 'In Progress',
  prepared: 'Prepared',
  active: 'Active',
  inactive: 'Inactive',
};

export function StatusBadge({ status = 'inactive' }) {
  return (
    <span className={cn('inline-flex rounded-full px-2.5 py-1 text-xs font-semibold', styles[status] || styles.inactive)}>
      {labels[status] || 'Unknown'}
    </span>
  );
}
