import { supabaseRestRequest } from '@/lib/supabase';
import { getValidStoredSupabaseToken } from '@/lib/authToken';
import { useAuthStore } from '@/stores/authStore';

function requireToken() {
  const token = getValidStoredSupabaseToken();
  if (!token) {
    throw new Error('Session expired. Please sign in again.');
  }
  return token;
}

function handleSupabaseAuthError(error) {
  const message = String(error?.message || '').toLowerCase();
  if (message.includes('invalid jwt') || message.includes('jwt')) {
    useAuthStore.getState().clearAuth();
    throw new Error('Session expired or invalid. Please sign in again.');
  }
  throw error;
}

const toTrimmedStringOrDash = (value) => {
  if (value == null) return '-';
  const text = String(value).trim();
  return text.length ? text : '-';
};

const safeParseJsonArray = (value) => {
  if (Array.isArray(value)) return value;
  if (typeof value !== 'string') return null;
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
};

function normalizeProductRow(row) {
  return {
    id: row.id,
    handle: row.handle,
    title: row.title || row.name || '',
    name: row.name,
    category: row.category || 'General',
    rate: toTrimmedStringOrDash(row.rate),
    weight: toTrimmedStringOrDash(row.weight),
    minWeight: row.min_weight == null ? null : Number(row.min_weight),
    maxWeight: row.max_weight == null ? null : Number(row.max_weight),
    flavours: String(row.flavours || 1),
    status: row.status || 'inactive',
    image: row.image || row.image_url || '',
    option1Name: row.option1_name || '',
    option1Value: row.option1_value || '',
    option2Name: row.option2_name || '',
    option2Value: safeParseJsonArray(row.option2_value),
    option3Name: row.option3_name || '',
    option3Value: row.option3_value || '',
    coo: row.coo || '',
    location: row.location || '',
    binName: row.bin_name || '',
    incoming: Number(row.incoming || 0),
    unavailable: Number(row.unavailable || 0),
    committed: Number(row.committed || 0),
    available: Number(row.available || 0),
    onHandCurrent: Number(row.on_hand_current || 0),
    onHandNew: row.on_hand_new == null ? null : Number(row.on_hand_new),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function listProductsFromSupabase() {
  const token = requireToken();
  const params = new URLSearchParams({
    select:
      'id,handle,title,name,category,rate,weight,min_weight,max_weight,flavours,status,image,option1_name,option1_value,option2_name,option2_value,option3_name,option3_value,coo,location,bin_name,incoming,unavailable,committed,available,on_hand_current,on_hand_new,created_at,updated_at',
    order: 'created_at.desc',
  });

  try {
    const rows = await supabaseRestRequest(`/products?${params.toString()}`, { accessToken: token });
    return Array.isArray(rows) ? rows.map(normalizeProductRow) : [];
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}

export async function createProductInSupabase(payload) {
  const token = requireToken();
  const body = {
    handle: payload.handle,
    title: payload.title || payload.name,
    name: payload.name,
    category: payload.category,
    rate: payload.rate,
    weight: payload.weight,
    min_weight: payload.minWeight == null ? null : Number(payload.minWeight),
    max_weight: payload.maxWeight == null ? null : Number(payload.maxWeight),
    flavours: payload.flavours,
    status: payload.status,
    image: payload.image,
    option1_name: payload.option1Name || null,
    option1_value: payload.option1Value || null,
    option2_name: payload.option2Name || null,
    option2_value: payload.option2Value || null,
    option3_name: payload.option3Name || null,
    option3_value: payload.option3Value || null,
    coo: payload.coo || null,
    location: payload.location || null,
    bin_name: payload.binName || null,
    incoming: Number(payload.incoming || 0),
    unavailable: Number(payload.unavailable || 0),
    committed: Number(payload.committed || 0),
    available: Number(payload.available || 0),
    on_hand_current: Number(payload.onHandCurrent || 0),
    on_hand_new: payload.onHandNew == null || payload.onHandNew === '' ? null : Number(payload.onHandNew),
  };

  try {
    const rows = await supabaseRestRequest('/products', {
      method: 'POST',
      body,
      accessToken: token,
      preferReturnRepresentation: true,
    });
    if (Array.isArray(rows) && rows[0]) return normalizeProductRow(rows[0]);
    throw new Error('No product was created. Check Supabase RLS policy/permissions.');
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}

export async function updateProductInSupabase(id, payload) {
  const token = requireToken();
  if (!id) {
    throw new Error('Product id is required for update.');
  }

  const body = {
    handle: payload.handle,
    title: payload.title || payload.name,
    name: payload.name,
    category: payload.category,
    rate: payload.rate,
    weight: payload.weight,
    min_weight: payload.minWeight == null ? null : Number(payload.minWeight),
    max_weight: payload.maxWeight == null ? null : Number(payload.maxWeight),
    flavours: payload.flavours,
    status: payload.status,
    image: payload.image,
    option1_name: payload.option1Name || null,
    option1_value: payload.option1Value || null,
    option2_name: payload.option2Name || null,
    option2_value: payload.option2Value || null,
    option3_name: payload.option3Name || null,
    option3_value: payload.option3Value || null,
    coo: payload.coo || null,
    location: payload.location || null,
    bin_name: payload.binName || null,
    incoming: Number(payload.incoming || 0),
    unavailable: Number(payload.unavailable || 0),
    committed: Number(payload.committed || 0),
    available: Number(payload.available || 0),
    on_hand_current: Number(payload.onHandCurrent || 0),
    on_hand_new: payload.onHandNew == null || payload.onHandNew === '' ? null : Number(payload.onHandNew),
  };

  try {
    const rows = await supabaseRestRequest(`/products?id=eq.${id}`, {
      method: 'PATCH',
      body,
      accessToken: token,
      preferReturnRepresentation: true,
    });
    if (Array.isArray(rows) && rows[0]) return normalizeProductRow(rows[0]);
    throw new Error('No product was updated. Check Supabase RLS policy/permissions (admin) and that the product id exists.');
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}

export async function deleteProductInSupabase(id) {
  const token = requireToken();
  if (!id) {
    throw new Error('Product id is required for delete.');
  }

  try {
    await supabaseRestRequest(`/products?id=eq.${id}`, {
      method: 'DELETE',
      accessToken: token,
    });
    return { success: true };
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}

export async function upsertImportedProductsInSupabase(products = []) {
  if (!products.length) return [];
  const token = requireToken();

  const incomingByHandle = new Map(products.map((product) => [product.handle, product]));
  const handles = products.map((product) => product.handle).filter(Boolean);
  if (!handles.length) return [];

  const quotedHandles = handles.map((handle) => `"${String(handle).replaceAll('"', '\\"')}"`).join(',');
  const existingParams = new URLSearchParams({
    select: 'id,handle',
  });
  existingParams.set('handle', `in.(${quotedHandles})`);

  try {
    const existingRows = await supabaseRestRequest(`/products?${existingParams.toString()}`, { accessToken: token });
    const existingByHandle = new Map((Array.isArray(existingRows) ? existingRows : []).map((row) => [row.handle, row.id]));

    const inserts = [];
    const updates = [];
    incomingByHandle.forEach((product, handle) => {
      const rowBody = {
        handle: product.handle,
        title: product.title || product.name,
        name: product.name,
        category: product.category,
        rate: product.rate,
        weight: product.weight,
        min_weight: product.minWeight == null ? null : Number(product.minWeight),
        max_weight: product.maxWeight == null ? null : Number(product.maxWeight),
        flavours: product.flavours,
        status: product.status,
        image: product.image,
        option1_name: product.option1Name || null,
        option1_value: product.option1Value || null,
        option2_name: product.option2Name || null,
        option2_value: product.option2Value || null,
        option3_name: product.option3Name || null,
        option3_value: product.option3Value || null,
        coo: product.coo || null,
        location: product.location || null,
        bin_name: product.binName || null,
        incoming: Number(product.incoming || 0),
        unavailable: Number(product.unavailable || 0),
        committed: Number(product.committed || 0),
        available: Number(product.available || 0),
        on_hand_current: Number(product.onHandCurrent || 0),
        on_hand_new: product.onHandNew == null || product.onHandNew === '' ? null : Number(product.onHandNew),
      };

      if (existingByHandle.has(handle)) {
        updates.push({ id: existingByHandle.get(handle), body: rowBody });
      } else {
        inserts.push(rowBody);
      }
    });

    if (inserts.length) {
      await supabaseRestRequest('/products', {
        method: 'POST',
        body: inserts,
        accessToken: token,
      });
    }

    if (updates.length) {
      await Promise.all(
        updates.map((update) =>
          supabaseRestRequest(`/products?id=eq.${update.id}`, {
            method: 'PATCH',
            body: update.body,
            accessToken: token,
          })
        )
      );
    }

    return { inserted: inserts.length, updated: updates.length };
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}

const roundTo2dpString = (value) => Number(value).toFixed(2);

export async function bulkUpdateProductsInSupabase(bulkSpec) {
  const token = requireToken();
  const params = new URLSearchParams({ select: 'id,rate,option2_value' });

  const type = bulkSpec?.type;
  const flavourUpdates = Array.isArray(bulkSpec?.flavourUpdates) ? bulkSpec.flavourUpdates : [];
  const priceUpdate = bulkSpec?.priceUpdate || {};

  try {
    const rows = await supabaseRestRequest(`/products?${params.toString()}`, { accessToken: token });
    const products = Array.isArray(rows) ? rows : [];

    const patches = [];
    const getOption2Array = (raw) => safeParseJsonArray(raw);
    const buildOption2PatchValue = (raw, nextItems) => (Array.isArray(raw) ? nextItems : JSON.stringify(nextItems));

    if (type === 'flavour') {
      products.forEach((product) => {
        const rawOption2 = product?.option2_value;
        const parsed = getOption2Array(rawOption2);
        if (!parsed?.length) return;

        let changed = false;
        const nextItems = parsed.map((item) => ({ ...item }));

        flavourUpdates.forEach((update) => {
          const targetFlavour = String(update?.flavour || '');
          if (!targetFlavour) return;

          const increaseBy = Number(update?.increaseBy || 0);
          const decreaseBy = Number(update?.decreaseBy || 0);
          const delta = (Number.isFinite(increaseBy) ? increaseBy : 0) - (Number.isFinite(decreaseBy) ? decreaseBy : 0);
          if (delta === 0) return;

          nextItems.forEach((item) => {
            if (item?.name !== targetFlavour) return;
            const currentPrice = Number.parseFloat(String(item?.price ?? '').trim());
            if (!Number.isFinite(currentPrice)) return;

            const updatedPrice = Math.max(0, currentPrice + delta);
            item.price = roundTo2dpString(updatedPrice);
            changed = true;
          });
        });

        if (!changed) return;

        patches.push(
          supabaseRestRequest(`/products?id=eq.${product.id}`, {
            method: 'PATCH',
            body: { option2_value: buildOption2PatchValue(rawOption2, nextItems) },
            accessToken: token,
          })
        );
      });
    }

    if (type === 'price') {
      const amount = typeof priceUpdate?.amount === 'number' && Number.isFinite(priceUpdate.amount) ? priceUpdate.amount : null;
      const increaseBy = Number(priceUpdate?.increaseBy || 0);
      const decreaseBy = Number(priceUpdate?.decreaseBy || 0);
      const delta = (Number.isFinite(increaseBy) ? increaseBy : 0) - (Number.isFinite(decreaseBy) ? decreaseBy : 0);

      if (amount != null && delta !== 0) {
        products.forEach((product) => {
          const patchBody = {};

          const currentRate = Number.parseFloat(String(product?.rate ?? '').trim());
          if (Number.isFinite(currentRate) && currentRate === amount) {
            patchBody.rate = roundTo2dpString(Math.max(0, currentRate + delta));
          }

          const rawOption2 = product?.option2_value;
          const parsed = getOption2Array(rawOption2);
          if (parsed && parsed.length) {
            let option2Changed = false;
            const nextItems = parsed.map((item) => ({ ...item }));

            nextItems.forEach((item) => {
              const currentPrice = Number.parseFloat(String(item?.price ?? '').trim());
              if (!Number.isFinite(currentPrice)) return;
              if (currentPrice !== amount) return;
              item.price = roundTo2dpString(Math.max(0, currentPrice + delta));
              option2Changed = true;
            });

            if (option2Changed) {
              patchBody.option2_value = buildOption2PatchValue(rawOption2, nextItems);
            }
          }

          if (!Object.keys(patchBody).length) return;
          patches.push(
            supabaseRestRequest(`/products?id=eq.${product.id}`, {
              method: 'PATCH',
              body: patchBody,
              accessToken: token,
            })
          );
        });
      }
    }

    if (!patches.length) {
      return { updated: 0 };
    }

    await Promise.all(patches);
    return { updated: patches.length };
  } catch (error) {
    handleSupabaseAuthError(error);
  }
}
