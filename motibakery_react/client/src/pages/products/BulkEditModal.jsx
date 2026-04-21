import { useMemo, useState } from 'react';
import { toast } from 'sonner';

const toNumber = (value) => {
  const parsed = Number.parseFloat(String(value ?? '').trim());
  return Number.isFinite(parsed) ? parsed : null;
};

const buildInitialFlavourRows = (flavourOptions) =>
  (Array.isArray(flavourOptions) ? flavourOptions : []).map((name) => ({
    name,
    increaseBy: '',
    decreaseBy: '',
  }));

export function BulkEditModal({ onClose, onApply, flavourOptions, amountOptions, amountCounts }) {
  const [activeTab, setActiveTab] = useState('flavour');
  const [flavourRows, setFlavourRows] = useState(() => buildInitialFlavourRows(flavourOptions));
  const [priceUpdate, setPriceUpdate] = useState({ amount: '', increaseBy: '', decreaseBy: '' });
  const [isApplying, setIsApplying] = useState(false);

  const selectedAmountCount = useMemo(() => {
    const key = String(toNumber(priceUpdate.amount));
    if (!key || key === 'null' || key === 'NaN') return 0;
    return Number(amountCounts?.[key] || 0);
  }, [amountCounts, priceUpdate.amount]);

  const resolvedFlavourRows = useMemo(() => {
    if (flavourRows.length) return flavourRows;
    return buildInitialFlavourRows(flavourOptions);
  }, [flavourOptions, flavourRows]);

  const bulkSpec = useMemo(() => {
    const flavourUpdates = resolvedFlavourRows
      .filter((row) => row.increaseBy || row.decreaseBy)
      .map((row) => ({
        flavour: row.name,
        increaseBy: toNumber(row.increaseBy) ?? 0,
        decreaseBy: toNumber(row.decreaseBy) ?? 0,
      }));

    const parsedPriceUpdate = {
      amount: toNumber(priceUpdate.amount),
      increaseBy: toNumber(priceUpdate.increaseBy) ?? 0,
      decreaseBy: toNumber(priceUpdate.decreaseBy) ?? 0,
    };

    return { type: activeTab, flavourUpdates, priceUpdate: parsedPriceUpdate };
  }, [activeTab, priceUpdate, resolvedFlavourRows]);

  const pricePreview = useMemo(() => {
    const amount = bulkSpec.priceUpdate.amount;
    const delta = (bulkSpec.priceUpdate.increaseBy || 0) - (bulkSpec.priceUpdate.decreaseBy || 0);
    if (amount == null) return { amount: null, delta, nextAmount: null };
    return { amount, delta, nextAmount: Math.max(0, amount + delta) };
  }, [bulkSpec.priceUpdate.amount, bulkSpec.priceUpdate.decreaseBy, bulkSpec.priceUpdate.increaseBy]);

  const updateFlavourRow = (index, key, value) => {
    setFlavourRows((prev) =>
      prev.map((item, itemIndex) => {
        if (itemIndex !== index) return item;
        return { ...item, [key]: value };
      })
    );
  };

  const handleApply = async () => {
    if (activeTab === 'flavour' && bulkSpec.flavourUpdates.length === 0) {
      toast.error('Enter at least one increase or decrease value');
      return;
    }
    if (activeTab === 'price' && bulkSpec.priceUpdate.amount == null) {
      toast.error('Select an amount to update');
      return;
    }
    if (activeTab === 'price' && bulkSpec.priceUpdate.increaseBy === 0 && bulkSpec.priceUpdate.decreaseBy === 0) {
      toast.error('Enter an increase or decrease amount');
      return;
    }

    setIsApplying(true);
    try {
      await onApply?.(bulkSpec);
      onClose?.();
    } catch {
      // error toast handled in hook
    } finally {
      setIsApplying(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/30 p-3 sm:p-4">
      <div className="mx-auto my-3 w-full max-w-4xl rounded-xl bg-white p-4 shadow-modal sm:my-6 sm:p-6">
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Bulk Edit</h3>
            <p className="mt-1 text-sm text-gray-500">Prepare updates by flavour or by price. Saving will be wired to SQL later.</p>
          </div>
          <button type="button" className="rounded-md px-3 py-2 text-sm text-gray-500 hover:bg-gray-100" onClick={onClose}>
            Close
          </button>
        </div>

        <div className="mb-4 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => setActiveTab('flavour')}
            className={`rounded-md border px-3 py-2 text-sm font-medium ${
              activeTab === 'flavour' ? 'border-brand bg-brand/5 text-brand' : 'border-gray-200 text-gray-700 hover:bg-gray-50'
            }`}
          >
            Update by Flavour
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('price')}
            className={`rounded-md border px-3 py-2 text-sm font-medium ${
              activeTab === 'price' ? 'border-brand bg-brand/5 text-brand' : 'border-gray-200 text-gray-700 hover:bg-gray-50'
            }`}
          >
            Update by Price
          </button>
        </div>

        {activeTab === 'flavour' ? (
          <div className="space-y-3">
            <div className="grid grid-cols-1 gap-2 rounded-lg border border-gray-200 bg-gray-50 p-3 text-sm text-gray-700 md:grid-cols-3">
              <div className="font-semibold text-gray-600">Flavour</div>
              <div className="font-semibold text-gray-600">Increase By</div>
              <div className="font-semibold text-gray-600">Decrease By</div>
            </div>

            <div className="max-h-[52vh] space-y-2 overflow-y-auto pr-1">
              {resolvedFlavourRows.map((row, index) => (
                <div key={row.name} className="grid grid-cols-1 gap-2 rounded-lg border border-gray-200 p-3 md:grid-cols-3 md:items-center">
                  <div className="text-sm font-medium text-gray-900">{row.name}</div>

                  <input
                    inputMode="decimal"
                    type="number"
                    step="0.01"
                    value={row.increaseBy}
                    onChange={(event) => updateFlavourRow(index, 'increaseBy', event.target.value)}
                    className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm"
                    placeholder="₹"
                  />

                  <input
                    inputMode="decimal"
                    type="number"
                    step="0.01"
                    value={row.decreaseBy}
                    onChange={(event) => updateFlavourRow(index, 'decreaseBy', event.target.value)}
                    className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm"
                    placeholder="₹"
                  />
                </div>
              ))}
            </div>
          </div>
        ) : null}

        {activeTab === 'price' ? (
          <div className="space-y-4">
            <div className="grid gap-3 rounded-lg border border-gray-200 bg-gray-50 p-4 md:grid-cols-3">
              <label className="space-y-1 text-sm text-gray-700">
                <span>Amount</span>
	                <select
	                  value={priceUpdate.amount}
	                  onChange={(event) => setPriceUpdate((prev) => ({ ...prev, amount: event.target.value }))}
	                  className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm"
	                >
                  <option value="">Select amount</option>
                  {(Array.isArray(amountOptions) ? amountOptions : []).map((amount) => (
                    <option key={String(amount)} value={String(amount)}>
                      {String(amount)}
	                    </option>
	                  ))}
	                </select>
	                {priceUpdate.amount ? (
	                  <div className="text-xs text-gray-500">
	                    {selectedAmountCount} products match this amount
	                    {pricePreview.nextAmount != null ? ` · New amount: ${pricePreview.nextAmount.toFixed(2)}` : ''}
	                  </div>
	                ) : null}
	              </label>
              <label className="space-y-1 text-sm text-gray-700">
                <span>Increase By</span>
                <input
                  inputMode="decimal"
                  type="number"
                  step="0.01"
                  value={priceUpdate.increaseBy}
                  onChange={(event) => setPriceUpdate((prev) => ({ ...prev, increaseBy: event.target.value }))}
                  className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm"
                  placeholder="₹"
                />
              </label>
              <label className="space-y-1 text-sm text-gray-700">
                <span>Decrease By</span>
                <input
                  inputMode="decimal"
                  type="number"
                  step="0.01"
                  value={priceUpdate.decreaseBy}
                  onChange={(event) => setPriceUpdate((prev) => ({ ...prev, decreaseBy: event.target.value }))}
                  className="h-10 w-full rounded-md border border-gray-300 px-3 text-sm"
                  placeholder="₹"
                />
              </label>
            </div>
          </div>
        ) : null}

        <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t border-gray-200 pt-4">
          <div className="text-xs text-gray-500">
            {activeTab === 'flavour' ? `${bulkSpec.flavourUpdates.length} flavour updates staged` : 'Price update staged'}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleApply}
              disabled={isApplying}
              className="rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white shadow-brand hover:bg-brand-dark disabled:opacity-60"
            >
              {isApplying ? 'Applying...' : 'Apply'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
