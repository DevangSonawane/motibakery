import { Link, useParams } from 'react-router-dom';

export function OrderDetailPage() {
  const { id } = useParams();

  return (
    <div>
      <Link to="/orders" className="text-sm font-medium text-brand hover:underline">
        ← Back to Orders
      </Link>

      <h1 className="mt-3 text-2xl font-semibold">Order #{id}</h1>
      <p className="mt-1 text-sm text-gray-500">Read-only view. Status updates happen in the Flutter Cake Room app.</p>

      <div className="mt-6 grid gap-5 lg:grid-cols-2">
        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-card">
          <h2 className="text-lg font-semibold">Order Information</h2>
          <dl className="mt-4 space-y-3 text-sm">
            <div className="flex justify-between border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Cake</dt>
              <dd className="font-medium">Black Forest</dd>
            </div>
            <div className="flex justify-between border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Flavour</dt>
              <dd className="font-medium">Chocolate</dd>
            </div>
            <div className="flex justify-between border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Weight</dt>
              <dd className="font-medium">1.5 kg</dd>
            </div>
            <div className="flex justify-between border-b border-gray-100 pb-2">
              <dt className="text-gray-500">Total</dt>
              <dd className="font-medium">₹855</dd>
            </div>
          </dl>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-card">
          <h2 className="text-lg font-semibold">Status Timeline</h2>
          <ul className="mt-4 space-y-4 text-sm">
            <li className="rounded-md bg-gray-50 p-3">New - 9:12 AM</li>
            <li className="rounded-md bg-blue-50 p-3 text-blue-700">In Progress - 10:05 AM</li>
            <li className="rounded-md bg-green-50 p-3 text-green-700">Prepared - 11:20 AM</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
