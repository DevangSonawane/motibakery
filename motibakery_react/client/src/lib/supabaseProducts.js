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

function normalizeProductRow(row) {
  return {
    id: row.id,
    handle: row.handle,
    title: row.title || row.name || '',
    name: row.name,
    category: row.category || 'General',
    rate: row.rate || '-',
    weight: row.weight || '-',
    flavours: String(row.flavours || 1),
    status: row.status || 'inactive',
    image: row.image || row.image_url || '',
    option1Name: row.option1_name || '',
    option1Value: row.option1_value || '',
    option2Name: row.option2_name || '',
    option2Value: row.option2_value || '',
    option3Name: row.option3_name || '',
    option3Value: row.option3_value || '',
    sku: row.sku || '',
    hsCode: row.hs_code || '',
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
      'id,handle,title,name,category,rate,weight,flavours,status,image,option1_name,option1_value,option2_name,option2_value,option3_name,option3_value,sku,hs_code,coo,location,bin_name,incoming,unavailable,committed,available,on_hand_current,on_hand_new,created_at,updated_at',
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
    flavours: payload.flavours,
    status: payload.status,
    image: payload.image,
    option1_name: payload.option1Name || null,
    option1_value: payload.option1Value || null,
    option2_name: payload.option2Name || null,
    option2_value: payload.option2Value || null,
    option3_name: payload.option3Name || null,
    option3_value: payload.option3Value || null,
    sku: payload.sku || null,
    hs_code: payload.hsCode || null,
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
    return null;
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
    flavours: payload.flavours,
    status: payload.status,
    image: payload.image,
    option1_name: payload.option1Name || null,
    option1_value: payload.option1Value || null,
    option2_name: payload.option2Name || null,
    option2_value: payload.option2Value || null,
    option3_name: payload.option3Name || null,
    option3_value: payload.option3Value || null,
    sku: payload.sku || null,
    hs_code: payload.hsCode || null,
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
    return null;
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
        flavours: product.flavours,
        status: product.status,
        image: product.image,
        option1_name: product.option1Name || null,
        option1_value: product.option1Value || null,
        option2_name: product.option2Name || null,
        option2_value: product.option2Value || null,
        option3_name: product.option3Name || null,
        option3_value: product.option3Value || null,
        sku: product.sku || null,
        hs_code: product.hsCode || null,
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
