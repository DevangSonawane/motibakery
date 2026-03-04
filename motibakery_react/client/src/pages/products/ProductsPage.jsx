import { useMemo, useRef, useState } from 'react';
import * as XLSX from 'xlsx';
import { toast } from 'sonner';
import { PageHeader } from '@/components/shared/PageHeader';
import { DataTable } from '@/components/shared/DataTable';
import { StatusBadge } from '@/components/shared/StatusBadge';
import { useCakes, useCreateCake, useDeleteCake, useImportCakes, useUpdateCake } from '@/hooks/useCakes';

const EMPTY_FORM = {
  handle: '',
  title: '',
  name: '',
  category: '',
  rate: '',
  weight: '',
  flavours: '1',
  option1Name: 'Title',
  option1Value: 'Default Title',
  option2Name: '',
  option2Value: '',
  option3Name: '',
  option3Value: '',
  sku: '',
  hsCode: '',
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

const normalizeText = (value) => String(value || '').trim();
const slugify = (value) =>
  normalizeText(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const formatDisplayIndex = (index) => `#C${String(index).padStart(3, '0')}`;

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
    { key: 'category', label: 'Category' },
    { key: 'rate', label: 'Rate' },
    { key: 'weight', label: 'Weight' },
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
          <label className="space-y-1 text-sm text-gray-700">
            <span>Category</span>
            <input
              value={form.category}
              onChange={(event) => onChange('category', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="Cake, cookies, snacks..."
            />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Rate</span>
            <input
              value={form.rate}
              onChange={(event) => onChange('rate', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="₹350/kg"
            />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Weight</span>
            <input
              value={form.weight}
              onChange={(event) => onChange('weight', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="500g, 1kg"
            />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Flavours</span>
            <input
              type="number"
              min="1"
              value={form.flavours}
              onChange={(event) => onChange('flavours', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
            />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option1 Name</span>
            <input value={form.option1Name} onChange={(event) => onChange('option1Name', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option1 Value</span>
            <input value={form.option1Value} onChange={(event) => onChange('option1Value', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option2 Name</span>
            <input value={form.option2Name} onChange={(event) => onChange('option2Name', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option2 Value</span>
            <input value={form.option2Value} onChange={(event) => onChange('option2Value', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option3 Name</span>
            <input value={form.option3Name} onChange={(event) => onChange('option3Name', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Option3 Value</span>
            <input value={form.option3Value} onChange={(event) => onChange('option3Value', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>SKU</span>
            <input value={form.sku} onChange={(event) => onChange('sku', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>HS Code</span>
            <input value={form.hsCode} onChange={(event) => onChange('hsCode', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>COO</span>
            <input value={form.coo} onChange={(event) => onChange('coo', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" placeholder="Country of origin" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Location</span>
            <input value={form.location} onChange={(event) => onChange('location', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Bin Name</span>
            <input value={form.binName} onChange={(event) => onChange('binName', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <div />
          <label className="space-y-1 text-sm text-gray-700">
            <span>Incoming</span>
            <input type="number" value={form.incoming} onChange={(event) => onChange('incoming', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Unavailable</span>
            <input type="number" value={form.unavailable} onChange={(event) => onChange('unavailable', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Committed</span>
            <input type="number" value={form.committed} onChange={(event) => onChange('committed', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>Available</span>
            <input type="number" value={form.available} onChange={(event) => onChange('available', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>On Hand (Current)</span>
            <input type="number" value={form.onHandCurrent} onChange={(event) => onChange('onHandCurrent', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700">
            <span>On Hand (New)</span>
            <input type="number" value={form.onHandNew} onChange={(event) => onChange('onHandNew', event.target.value)} className="h-10 w-full rounded-md border border-gray-300 px-3" />
          </label>
          <label className="space-y-1 text-sm text-gray-700 md:col-span-2">
            <span>Image URL (optional)</span>
            <input
              value={form.imageUrl}
              onChange={(event) => onChange('imageUrl', event.target.value)}
              className="h-10 w-full rounded-md border border-gray-300 px-3"
              placeholder="https://example.com/product.jpg"
            />
          </label>
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
  return {
    handle: product.handle || '',
    title: product.title || product.name || '',
    name: product.name || '',
    category: product.category || '',
    rate: product.rate || '',
    weight: product.weight || '',
    flavours: String(product.flavours || 1),
    option1Name: product.option1Name || 'Title',
    option1Value: product.option1Value || 'Default Title',
    option2Name: product.option2Name || '',
    option2Value: product.option2Value || '',
    option3Name: product.option3Name || '',
    option3Value: product.option3Value || '',
    sku: product.sku || '',
    hsCode: product.hsCode || '',
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
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedIds, setSelectedIds] = useState([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingProduct, setEditingProduct] = useState(null);
  const csvInputRef = useRef(null);

  const { data: products = [], isLoading, isError, error } = useCakes();
  const createCake = useCreateCake();
  const updateCake = useUpdateCake();
  const deleteCake = useDeleteCake();
  const importCakes = useImportCakes();

  const categories = useMemo(() => {
    const values = Array.from(new Set(products.map((product) => product.category).filter(Boolean)));
    return values.sort((a, b) => a.localeCompare(b));
  }, [products]);

  const rows = useMemo(() => {
    const filtered = products.filter((product) => {
      const query = search.trim().toLowerCase();
      const matchesSearch = !query || product.name.toLowerCase().includes(query) || product.handle.toLowerCase().includes(query);
      const matchesCategory = categoryFilter === 'all' || product.category === categoryFilter;
      const matchesStatus = statusFilter === 'all' || product.status === statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    });

    return filtered.map((product, index) => ({
      ...product,
      displayId: formatDisplayIndex(index + 1),
    }));
  }, [products, search, categoryFilter, statusFilter]);

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

    const payload = {
      handle: normalizeText(form.handle) || slugify(form.name || form.title),
      title: normalizeText(form.title) || normalizeText(form.name),
      name: normalizeText(form.name),
      category: normalizeText(form.category) || 'General',
      rate: normalizeText(form.rate) || '-',
      weight: normalizeText(form.weight) || '-',
      flavours: Number(form.flavours) || 1,
      status: editingProduct?.status || 'active',
      image: normalizeText(form.imageUrl),
      option1Name: normalizeText(form.option1Name),
      option1Value: normalizeText(form.option1Value),
      option2Name: normalizeText(form.option2Name),
      option2Value: normalizeText(form.option2Value),
      option3Name: normalizeText(form.option3Name),
      option3Value: normalizeText(form.option3Value),
      sku: normalizeText(form.sku),
      hsCode: normalizeText(form.hsCode),
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
          sku: normalizeText(row.SKU),
          hsCode: normalizeText(row['HS Code']),
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
      if (!item.sku) item.sku = normalizeText(row.SKU);
      if (!item.hsCode) item.hsCode = normalizeText(row['HS Code']);
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
      sku: item.sku || '',
      hsCode: item.hsCode || '',
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
        secondaryAction={{ label: importCakes.isPending ? 'Importing...' : 'Import CSV', onClick: handleImportClick }}
      />

      <input ref={csvInputRef} type="file" accept=".csv,.xlsx,.xls" className="hidden" onChange={handleCsvImport} />

      {isError ? <div className="mb-4 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{String(error?.message || 'Failed to load products')}</div> : null}

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="h-10 min-w-[220px] rounded-md border border-gray-300 px-3 text-sm"
          placeholder="Search products..."
        />
        <select value={categoryFilter} onChange={(event) => setCategoryFilter(event.target.value)} className="h-10 rounded-md border border-gray-300 px-3 text-sm">
          <option value="all">All Categories</option>
          {categories.map((category) => (
            <option key={category} value={category}>
              {category}
            </option>
          ))}
        </select>
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
