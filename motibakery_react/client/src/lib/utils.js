export const formatPrice = (value) => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(Number(value || 0));
};

export const formatDate = (input) => {
  if (!input) return '-';
  const value = new Date(input);
  if (Number.isNaN(value.getTime())) return '-';
  return value.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

export const cn = (...classes) => classes.filter(Boolean).join(' ');
