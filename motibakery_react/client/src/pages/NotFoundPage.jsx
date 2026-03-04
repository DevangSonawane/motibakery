import { Link } from 'react-router-dom';

export function NotFoundPage() {
  return (
    <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 text-center">
      <h1 className="text-4xl font-bold text-gray-900">404</h1>
      <p className="text-gray-500">This page does not exist.</p>
      <Link to="/dashboard" className="text-sm font-semibold text-brand hover:underline">
        Back to Dashboard
      </Link>
    </div>
  );
}
