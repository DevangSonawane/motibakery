export function DataTable({ columns = [], rows = [], emptyText = 'No data available' }) {
  return (
    <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-card">
      <table className="w-full text-left">
        <thead className="bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
          <tr>
            {columns.map((column) => (
              <th key={column.key} className="px-4 py-3 font-medium">
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {rows.length > 0 ? (
            rows.map((row, idx) => (
              <tr key={row.id || idx} className="hover:bg-brand-pale/50">
                {columns.map((column) => (
                  <td key={column.key} className="px-4 py-3 text-sm text-gray-700">
                    {column.render ? column.render(row) : row[column.key]}
                  </td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td className="px-4 py-8 text-center text-sm text-gray-500" colSpan={columns.length || 1}>
                {emptyText}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
