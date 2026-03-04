export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = 'Confirm',
  onConfirm,
  onCancel,
  loading = false,
}) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-modal">
        <h3 className="text-lg font-bold text-gray-900">{title}</h3>
        <p className="mt-2 text-sm text-gray-600">{description}</p>
        <div className="mt-6 flex justify-end gap-3">
          <button type="button" onClick={onCancel} className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium">
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={loading}
            className="rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {loading ? 'Please wait...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
