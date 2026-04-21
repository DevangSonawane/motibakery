import { useMemo, useRef, useState } from 'react';
import * as XLSX from 'xlsx';
import { toast } from 'sonner';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { StatusBadge } from '@/components/shared/StatusBadge';
import { useBulkUpdateCakes, useCakes, useCreateCake, useDeleteCake, useImportCakes, useUpdateCake } from '@/hooks/useCakes';
import { BulkEditModal } from './BulkEditModal';

const EMPTY_FORM = {
  handle: '',
  title: '',
  name: '',
  category: '',
  rate: '',
  weight: '',
  minWeight: '',
  maxWeight: '',
  flavours: '1',
  flavourItems: [{ name: '', price: '', customName: '' }],
  option1Name: 'Title',
  option1Value: 'Default Title',
  option2Name: '',
  option2Value: '',
  option3Name: '',
  option3Value: '',
  coo: '',
  location: 'Moti bakery',
  binName: '',
  incoming: '0',
  unavailable: '0',
  committed: '0',
  available: '0',
  onHandCurrent: '0',
  onHandNew: '',
  imageUrl: '',
};

const FLAVOUR_OPTIONS = ['Chocolate', 'Vanilla', 'Pineapple', 'Butterscotch', 'Strawberry'];

const normalizeText = (value) => String(value || '').trim();
const slugify = (value) =>
  normalizeText(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const formatDisplayIndex = (index) => `#C${String(index).padStart(3, '0')}`;

const normalizeFlavourItems = (items) => {
  if (!Array.isArray(items)) return [];
  return items.map((item) => {
    const selected = normalizeText(item?.name);
    const customName = normalizeText(item?.customName);
    return {
      name: selected === '__custom__' ? customName : selected,
      price: normalizeText(item?.price),
      customName,
    };
  });
};

const parseFlavourItems = (product) => {
  const parsedItems = normalizeFlavourItems(product?.option2Value).filter((item) => item.name || item.price || item.customName);
  if (parsedItems.length) return parsedItems;

  const fallbackCount = Math.max(1, Number(product?.flavours || 1) || 1);
  return Array.from({ length: fallbackCount }, () => ({ name: '', price: '', customName: '' }));
};

function buildColumnsWithActions(onEdit, onDelete, onToggleSelect, onToggleSelectAll, isSelected, isAllVisibleSelected) {
  return [
    {
      key: 'select',
      label: (
        <input
          type="checkbox"
          checked={isAllVisibleSelected}
          onChange={onToggleSelectAll}
          className="h-4 w-4 rounded border-gray-300"
          aria-label="Select all visible products"
        />
      ),
      render: (row) => (
        <input
          type="checkbox"
          checked={isSelected(row.id)}
          onChange={() => onToggleSelect(row.id)}
          className="h-4 w-4 rounded border-gray-300"
          aria-label={`Select ${row.name}`}
        />
      ),
    },
    { key: 'displayId', label: 'ID' },
    {
      key: 'image',
      label: 'Image',
      render: (row) =>
        row.image ? (
          <img src={row.image} alt={row.name} className="h-12 w-12 rounded-md border border-gray-200 object-cover" />
        ) : (
          <span className="text-xs text-gray-400">No image</span>
        ),
    },
    { key: 'name', label: 'Name' },
    { key: 'rate', label: 'Rate' },
    {
      key: 'minWeight',
      label: 'Min Weight',
      render: (row) => (row.minWeight == null ? '-' : row.minWeight),
    },
    {
      key: 'maxWeight',
      label: 'Max Weight',
      render: (row) => (row.maxWeight == null ? '-' : row.maxWeight),
    },
    { key: 'flavours', label: 'Flavours' },
    { key: 'status', label: 'Status', render: (row) => <StatusBadge status={row.status} /> },
    {
      key: 'actions',
      label: 'Actions',
      render: (row) => (
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => onEdit(row)}
            className="rounded-md border border-gray-300 px-3 py-1 text-xs font-medium text-gray-700 hover:bg-gray-50"
          >
            Edit
          </button>
          <button
            type="button"
            onClick={() => onDelete(row)}
            className="rounded-md border border-red-200 px-3 py-1 text-xs font-medium text-red-700 hover:bg-red-50"
          >
            Delete
          </button>
        </div>
      ),
    },
  ];
}

function AddProductModal({ form, onChange, onClose, onSubmit, onImageSelect, isSaving, mode = 'create' }) {
  const isEditMode = mode === 'edit';
  const flavourItems = Array.isArray(form.flavourItems) ? form.flavourItems : [{ name: '', price: '', customName: '' }];

  const addFlavourRow = () => {
    onChange('flavourItems', [...flavourItems, { name: '', price: '', customName: '' }]);
  };

  const updateFlavourRow = (index, key, value) => {
    onChange(
      'flavourItems',
      flavourItems.map((item, itemIndex) => {
        if (itemIndex !== index) return item;
        if (key === 'name' && value !== '__custom__') {
          return { ...item, name: value, customName: '' };
        }
        return { ...item, [key]: value };
      })
    );
  };

  const removeFlavourRow = (index) => {
    const next = flavourItems.filter((_, itemIndex) => itemIndex !== index);
    onChange('flavourItems', next.length ? next : [{ name: '', price: '', customName: '' }]);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/30 p-3 sm:p-4">
      <div className="mx-auto my-3 w-full max-w-2xl rounded-xl bg-white p-4 shadow-modal sm:my-6 sm:p-6">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900">{mode === 'edit' ? 'Edit Product' : 'Add Product'}</h3>
          <button type="button" className="rounded-md px-3 py-2 text-sm text-gray-500 hover:bg-gray-100" onClick={onClose}>
            Close
          </button>
        </div>
        <form className="grid max-h-[70vh] gap-4 overflow-y-auto pr-1 md:grid-cols-2" onSubmit={onSubmit}>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Handle</span>
            <input
              value={form.handle}
              onChange={(event) => onChange('handle', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="auto if blank"
            />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Title</span>
            <input
              value={form.title}
              onChange={(event) => onChange('title', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="Display title"
            />
          </label>
          {isEditMode ? null : (
            <label className="space-y-1 text-sm text-gray-700">
              <span>Name</span>
              <input
                required
                value={form.name}
                onChange={(event) => onChange('name', event.target.value)}
                className="h-10 w-full rounded-md border border-gray-300 px-3"
                placeholder="Product name"
              />
            </label>
          )}
          <div className="space-y-2 text-sm text-gray-700 md:col-span-2">
            <span>Weight Range (kg)</span>
            <div className="grid grid-cols-2 gap-2">
              <input
                type="number"
                value={form.minWeight}
                onChange={(event) => onChange('minWeight', event.target.value)}
                className="h-10 w-full rounded-md border border-gray-300 px-3"
                placeholder="Min weight"
                min="0"
                step="0.1"
              />
              <input
                type="number"
                value={form.maxWeight}
                onChange={(event) => onChange('maxWeight', event.target.value)}
                className="h-10 w-full rounded-md border border-gray-300 px-3"
                placeholder="Max weight"
                min="0"
                step="0.1"
              />
            </div>
          </div>
          <div className="space-y-2 text-sm text-gray-700 md:col-span-2">
            <div className="flex items-center justify-between">
              <span>Flavours</span>
              <button
                type="button"
                onClick={addFlavourRow}
                className="inline-flex h-9 items-center justify-center rounded-md border border-gray-300 px-3 text-xs font-medium text-gray-700 hover:bg-gray-50"
                aria-label="Add flavour"
              >
                +
              </button>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {flavourItems.map((item, index) => (
                <div key={`flavour-${index}`} className="flex flex-wrap items-center gap-2 rounded-md border border-gray-300 bg-white p-2">
                  <select
                    value={item.name}
                    onChange={(event) => updateFlavourRow(index, 'name', event.target.value)}
                    className="h-9 w-44 rounded-md border border-gray-200 px-2 text-sm"
                  >
                    <option value="">Select flavour</option>
                    {FLAVOUR_OPTIONS.map((flavour) => (
                      <option key={`flavour-${flavour}`} value={flavour}>
                        {flavour}
                      </option>
                    ))}
                    <option value="__custom__">Custom</option>
                  </select>
                  {item.name === '__custom__' ? (
                    <input
                      value={item.customName || ''}
                      onChange={(event) => updateFlavourRow(index, 'customName', event.target.value)}
                      className="h-9 w-44 rounded-md border border-gray-200 px-2 text-sm"
                      placeholder="Custom flavour"
                    />
                  ) : null}
                  <input
                    type="number"
                    value={item.price}
                    onChange={(event) => updateFlavourRow(index, 'price', event.target.value)}
                    className="h-9 w-28 rounded-md border border-gray-200 px-2 text-sm"
                    placeholder="Rate"
                  />
                  <button
                    type="button"
                    onClick={() => removeFlavourRow(index)}
                    className="inline-flex h-9 w-9 items-center justify-center rounded-md border border-gray-200 text-xs font-semibold text-gray-600 hover:bg-gray-50"
                    aria-label="Remove flavour"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          </div>
          <div className="space-y-2 md:col-span-2">
            <span className="text-sm text-gray-700">Image Upload</span>
            <label className="flex cursor-pointer items-center gap-3 rounded-md border border-dashed border-gray-300 px-4 py-3 text-sm text-gray-600 hover:bg-gray-50">
              <input type="file" accept="image/*" className="hidden" onChange={onImageSelect} />
              <span>Choose image from device</span>
            </label>
            {form.imageUrl ? (
              <img src={form.imageUrl} alt="Preview" className="h-24 w-24 rounded-md border border-gray-200 object-cover" />
            ) : (
              <p className="text-xs text-gray-400">No image selected</p>
            )}
          </div>
          <div className="flex justify-end gap-2 md:col-span-2">
            <button type="button" onClick={onClose} className="rounded-md border border-gray-300 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50">
              Cancel
            </button>
            <button disabled={isSaving} type="submit" className="rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark disabled:opacity-60">
              {isSaving ? 'Saving...' : mode === 'edit' ? 'Update product' : 'Add product'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function toFormState(product) {
  const rawFlavourItems = parseFlavourItems(product);
  const mappedFlavourItems = rawFlavourItems.map((item) => {
    const name = normalizeText(item.name);
    if (!name) return { ...item, name: '', customName: item.customName || '' };
    if (FLAVOUR_OPTIONS.includes(name)) {
      return { ...item, name, customName: '' };
    }
    return { ...item, name: '__custom__', customName: name };
  });
  return {
    handle: product.handle || '',
    title: product.title || product.name || '',
    name: product.name || '',
    category: product.category || '',
    rate: product.rate == null ? '' : String(product.rate),
    weight: product.weight == null ? '' : String(product.weight),
    minWeight: product.minWeight == null ? '' : String(product.minWeight),
    maxWeight: product.maxWeight == null ? '' : String(product.maxWeight),
    flavours: String(product.flavours || 1),
    flavourItems: mappedFlavourItems,
    option1Name: product.option1Name || 'Title',
    option1Value: product.option1Value || 'Default Title',
    option2Name: product.option2Name || '',
    option2Value: product.option2Value ?? null,
    option3Name: product.option3Name || '',
    option3Value: product.option3Value || '',
    coo: product.coo || '',
    location: product.location || 'Moti bakery',
    binName: product.binName || '',
    incoming: String(product.incoming ?? 0),
    unavailable: String(product.unavailable ?? 0),
    committed: String(product.committed ?? 0),
    available: String(product.available ?? 0),
    onHandCurrent: String(product.onHandCurrent ?? 0),
    onHandNew: product.onHandNew == null ? '' : String(product.onHandNew),
    imageUrl: product.image || '',
  };
}

export function ProductsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedIds, setSelectedIds] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isBulkEditOpen, setIsBulkEditOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingProduct, setEditingProduct] = useState(null);
  const csvInputRef = useRef(null);

  const { data: products = [], isLoading, isError, error } = useCakes();
  const createCake = useCreateCake();
  const updateCake = useUpdateCake();
  const deleteCake = useDeleteCake();
  const importCakes = useImportCakes();
  const bulkUpdateCakes = useBulkUpdateCakes();

  const amountOptions = useMemo(() => {
    const amounts = [];

    products.forEach((product) => {
      const baseRate = Number.parseFloat(String(product?.rate ?? '').trim());
      if (Number.isFinite(baseRate)) amounts.push(baseRate);

      const items = normalizeFlavourItems(product?.option2Value);
      items.forEach((item) => {
        const price = Number.parseFloat(String(item?.price ?? '').trim());
        if (!Number.isFinite(price)) return;
        amounts.push(price);
      });
    });

    return Array.from(new Set(amounts)).sort((a, b) => a - b);
  }, [products]);

  const amountCounts = useMemo(() => {
    const counts = new Map();

    products.forEach((product) => {
      const pricesInProduct = new Set();

      const baseRate = Number.parseFloat(String(product?.rate ?? '').trim());
      if (Number.isFinite(baseRate)) pricesInProduct.add(baseRate);

      const items = normalizeFlavourItems(product?.option2Value);
      items.forEach((item) => {
        const price = Number.parseFloat(String(item?.price ?? '').trim());
        if (!Number.isFinite(price)) return;
        pricesInProduct.add(price);
      });

      pricesInProduct.forEach((price) => {
        counts.set(price, (counts.get(price) || 0) + 1);
      });
    });

    return Object.fromEntries(Array.from(counts.entries()).map(([amount, count]) => [String(amount), count]));
  }, [products]);

  const rows = useMemo(() => {
    const filtered = products.filter((product) => {
      const query = search.trim().toLowerCase();
      const matchesSearch = !query || product.name.toLowerCase().includes(query) || product.handle.toLowerCase().includes(query);
      const matchesStatus = statusFilter === 'all' || product.status === statusFilter;
      return matchesSearch && matchesStatus;
    });

    return filtered.map((product, index) => ({
      ...product,
      displayId: formatDisplayIndex(index + 1),
    }));
  }, [products, search, statusFilter]);

  const selectedVisibleCount = useMemo(() => rows.filter((row) => selectedIds.includes(row.id)).length, [rows, selectedIds]);
  const isAllVisibleSelected = rows.length > 0 && selectedVisibleCount === rows.length;

  const columns = useMemo(
    () =>
      buildColumnsWithActions(
        (row) => {
          setEditingProduct(row);
          setForm(toFormState(row));
          setIsModalOpen(true);
        },
        async (row) => {
          const ok = window.confirm(`Delete product "${row.name}"?`);
          if (!ok) return;
          try {
            await deleteCake.mutateAsync(row.id);
            setSelectedIds((previous) => previous.filter((id) => id !== row.id));
          } catch (requestError) {
            toast.error(requestError?.message || 'Failed to delete product');
          }
        },
        (id) => {
          setSelectedIds((previous) => (previous.includes(id) ? previous.filter((item) => item !== id) : [...previous, id]));
        },
        () => {
          setSelectedIds((previous) => {
            if (isAllVisibleSelected) {
              return previous.filter((id) => !rows.some((row) => row.id === id));
            }
            const merged = new Set([...previous, ...rows.map((row) => row.id)]);
            return Array.from(merged);
          });
        },
        (id) => selectedIds.includes(id),
        isAllVisibleSelected
      ),
    [deleteCake, isAllVisibleSelected, rows, selectedIds]
  );

  const updateForm = (key, value) => {
    setForm((previous) => ({ ...previous, [key]: value }));
  };

  const resetForm = () => {
    setForm(EMPTY_FORM);
  };

  const handleImageSelect = (event) => {
    const [file] = event.target.files || [];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      updateForm('imageUrl', String(reader.result || ''));
    };
    reader.readAsDataURL(file);
  };

  const onSaveProduct = async (event) => {
    event.preventDefault();
    if (!normalizeText(form.name)) {
      toast.error('Product name is required');
      return;
    }

    const flavourItemsToPersist = normalizeFlavourItems(form.flavourItems).filter((item) => item.name || item.price || item.customName);
    const flavoursCount = Math.max(1, flavourItemsToPersist.length || Number(form.flavours) || 1);
    const weightValue = normalizeText(form.weight);
    const minWeightValue = normalizeText(form.minWeight);
    const maxWeightValue = normalizeText(form.maxWeight);
    const minWeightNumber = minWeightValue === '' ? null : Number(minWeightValue);
    const maxWeightNumber = maxWeightValue === '' ? null : Number(maxWeightValue);
    const minWeight = Number.isFinite(minWeightNumber) ? minWeightNumber : null;
    const maxWeight = Number.isFinite(maxWeightNumber) ? maxWeightNumber : null;

    const payload = {
      handle: normalizeText(form.handle) || slugify(form.name || form.title),
      title: normalizeText(form.title) || normalizeText(form.name),
      name: normalizeText(form.name),
      category: normalizeText(form.category) || 'General',
      rate: normalizeText(form.rate) || '-',
      weight: weightValue || '-',
      minWeight,
      maxWeight,
      flavours: flavoursCount,
      status: editingProduct?.status || 'active',
      image: normalizeText(form.imageUrl),
      option1Name: normalizeText(form.option1Name) || 'Weight',
      option1Value: weightValue || normalizeText(form.option1Value) || 'Default Title',
      option2Name: flavourItemsToPersist.length ? 'flavours' : normalizeText(form.option2Name),
      option2Value: flavourItemsToPersist.length ? flavourItemsToPersist : Array.isArray(form.option2Value) ? form.option2Value : null,
      option3Name: normalizeText(form.option3Name),
      option3Value: normalizeText(form.option3Value),
      coo: normalizeText(form.coo),
      location: normalizeText(form.location) || 'Moti bakery',
      binName: normalizeText(form.binName),
      incoming: Number(form.incoming || 0),
      unavailable: Number(form.unavailable || 0),
      committed: Number(form.committed || 0),
      available: Number(form.available || 0),
      onHandCurrent: Number(form.onHandCurrent || 0),
      onHandNew: normalizeText(form.onHandNew) === '' ? null : Number(form.onHandNew),
    };

    try {
      if (editingProduct?.id) {
        await updateCake.mutateAsync({ id: editingProduct.id, payload });
      } else {
        await createCake.mutateAsync(payload);
      }
      resetForm();
      setEditingProduct(null);
      setIsModalOpen(false);
    } catch (requestError) {
      toast.error(requestError?.message || 'Failed to save product');
    }
  };

  const parseImportRows = (jsonRows) => {
    const grouped = new Map();
    jsonRows.forEach((row) => {
      const handle = normalizeText(row.Handle);
      const title = normalizeText(row.Title);
      if (!title) return;
      const key = handle || slugify(title);
      if (!grouped.has(key)) {
        grouped.set(key, {
          handle: key,
          title,
          name: title,
          category: 'Imported',
          rate: '-',
          weightOptions: new Set(),
          flavours: 1,
          status: 'inactive',
          image: '',
          stock: 0,
          option1Name: normalizeText(row['Option1 Name']) || 'Title',
          option2Name: normalizeText(row['Option2 Name']),
          option3Name: normalizeText(row['Option3 Name']),
          coo: normalizeText(row.COO),
          location: normalizeText(row.Location) || 'Moti bakery',
          binName: normalizeText(row['Bin name']),
          incoming: Number(row['Incoming (not editable)'] || 0),
          unavailable: Number(row['Unavailable (not editable)'] || 0),
          committed: Number(row['Committed (not editable)'] || 0),
          available: Number(row['Available (not editable)'] || 0),
          onHandCurrent: Number(row['On hand (current)'] || 0),
          onHandNew: normalizeText(row['On hand (new)']) === '' ? null : Number(row['On hand (new)']),
        });
      }
      const item = grouped.get(key);
      const optionValue = normalizeText(row['Option1 Value']);
      if (optionValue && optionValue.toLowerCase() !== 'default title') item.weightOptions.add(optionValue);
      const available = Number(row['Available (not editable)'] || 0);
      item.stock += Number.isFinite(available) ? available : 0;
      item.flavours = Math.max(item.flavours, item.weightOptions.size || 1);
      item.status = item.stock > 0 ? 'active' : 'inactive';
      if (!item.option2Name) item.option2Name = normalizeText(row['Option2 Name']);
      if (!item.option3Name) item.option3Name = normalizeText(row['Option3 Name']);
      if (!item.coo) item.coo = normalizeText(row.COO);
      if (!item.binName) item.binName = normalizeText(row['Bin name']);
    });

    return Array.from(grouped.values()).map((item) => ({
      handle: item.handle,
      title: item.title || item.name,
      name: item.name,
      category: item.category,
      rate: '-',
      weight: item.weightOptions.size > 0 ? Array.from(item.weightOptions).join(', ') : '-',
      flavours: item.flavours,
      status: item.status,
      image: '',
      option1Name: item.option1Name || 'Title',
      option1Value: item.weightOptions.size > 0 ? Array.from(item.weightOptions).join(', ') : 'Default Title',
      option2Name: item.option2Name || '',
      option2Value: '',
      option3Name: item.option3Name || '',
      option3Value: '',
      coo: item.coo || '',
      location: item.location || 'Moti bakery',
      binName: item.binName || '',
      incoming: Number.isFinite(item.incoming) ? item.incoming : 0,
      unavailable: Number.isFinite(item.unavailable) ? item.unavailable : 0,
      committed: Number.isFinite(item.committed) ? item.committed : 0,
      available: Number.isFinite(item.available) ? item.available : 0,
      onHandCurrent: Number.isFinite(item.onHandCurrent) ? item.onHandCurrent : 0,
      onHandNew: item.onHandNew == null || Number.isNaN(item.onHandNew) ? null : item.onHandNew,
    }));
  };

  const handleImportClick = () => {
    csvInputRef.current?.click();
  };

  const handleCsvImport = async (event) => {
    const [file] = event.target.files || [];
    event.target.value = '';
    if (!file) return;

    try {
      const buffer = await file.arrayBuffer();
      const workbook = XLSX.read(buffer, { type: 'array' });
      const firstSheetName = workbook.SheetNames[0];
      const firstSheet = workbook.Sheets[firstSheetName];
      const jsonRows = XLSX.utils.sheet_to_json(firstSheet, { defval: '' });
      const mappedRows = parseImportRows(jsonRows);

      if (!mappedRows.length) {
        toast.error('No valid products found in CSV');
        return;
      }

      const result = await importCakes.mutateAsync(mappedRows);
      if (result) {
        toast.success(`Import complete: ${result.inserted || 0} added, ${result.updated || 0} updated`);
      }
    } catch (requestError) {
      toast.error(requestError?.message || 'CSV import failed');
    }
  };

  const handleBulkDelete = async () => {
    if (!selectedIds.length) {
      toast.error('Select at least one product');
      return;
    }

    const confirmed = window.confirm(`Delete ${selectedIds.length} selected products?`);
    if (!confirmed) return;

    try {
      await Promise.all(selectedIds.map((id) => deleteCake.mutateAsync(id)));
      toast.success(`${selectedIds.length} products deleted`);
      setSelectedIds([]);
    } catch (requestError) {
      toast.error(requestError?.message || 'Failed to delete selected products');
    }
  };

  return (
    <div>
      <PageHeader
        title="Products"
        subtitle="Cake Catalogue"
        action={{
          label: '+ Add Product',
          onClick: () => {
            setEditingProduct(null);
            resetForm();
            setIsModalOpen(true);
          },
        }}
        secondaryActions={[
          { key: 'bulk-edit', label: 'Bulk Edit', onClick: () => setIsBulkEditOpen(true) },
          { key: 'import-csv', label: importCakes.isPending ? 'Importing...' : 'Import CSV', onClick: handleImportClick },
        ]}
      />

      <input ref={csvInputRef} type="file" accept=".csv,.xlsx,.xls" className="hidden" onChange={handleCsvImport} />

      {isBulkEditOpen ? (
        <BulkEditModal
          flavourOptions={FLAVOUR_OPTIONS}
          amountOptions={amountOptions}
          amountCounts={amountCounts}
          onApply={(spec) => bulkUpdateCakes.mutateAsync(spec)}
          onClose={() => setIsBulkEditOpen(false)}
        />
      ) : null}

      {isError ? <div className="mb-4 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{String(error?.message || 'Failed to load products')}</div> : null}

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="h-10 min-w-[220px] rounded-md border border-gray-300 px-3 text-sm"
          placeholder="Search products..."
        />
        <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)} className="h-10 rounded-md border border-gray-300 px-3 text-sm">
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      <div className="mb-4 flex items-center gap-3">
        <button
          type="button"
          onClick={handleBulkDelete}
          disabled={!selectedIds.length || deleteCake.isPending}
          className="rounded-md border border-red-200 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-50 disabled:opacity-60"
        >
          {deleteCake.isPending ? 'Deleting...' : `Delete Selected (${selectedIds.length})`}
        </button>
        {selectedVisibleCount ? <span className="text-xs text-gray-500">{selectedVisibleCount} selected in current view</span> : null}
      </div>

      <DataTable columns={columns} rows={rows} emptyText={isLoading ? 'Loading products...' : 'No products found'} />

      {isModalOpen ? (
        <AddProductModal
          form={form}
          onChange={updateForm}
          onClose={() => {
            resetForm();
            setEditingProduct(null);
            setIsModalOpen(false);
          }}
          onSubmit={onSaveProduct}
          onImageSelect={handleImageSelect}
          isSaving={createCake.isPending || updateCake.isPending}
          mode={editingProduct ? 'edit' : 'create'}
        />
      ) : null}
    </div>
  );
}
