export function PageHeader({ title, subtitle, action, secondaryAction }) {
  return (
    <div className="mb-6 border-b border-gray-200 pb-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-2xl font-semibold text-gray-900">{title}</h2>
          {subtitle ? <p className="mt-1 text-sm text-gray-500">{subtitle}</p> : null}
        </div>

        <div className="flex items-center gap-3">
          {secondaryAction ? (
            <button
              type="button"
              onClick={secondaryAction.onClick}
              className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              {secondaryAction.label}
            </button>
          ) : null}
          {action ? (
            <button
              type="button"
              onClick={action.onClick}
              className="rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white shadow-brand hover:bg-brand-dark"
            >
              {action.label}
            </button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
