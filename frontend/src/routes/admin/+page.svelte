<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/auth.svelte';
  import { api } from '$lib/api.svelte';

  let activeTab = $state('treatments');
  let treatments = $state([]);
  let loading = $state(false);
  let error = $state(null);
  let success = $state(null);

  // Form para nuevo tratamiento
  let newTreatment = $state({
    name: '',
    duration_minutes: 30,
    buffer_minutes: 10,
    price: 0
  });

  const MOCK_TENANT_ID = 'demo-tenant-123';

  onMount(() => {
    const groups = authStore.currentUser?.groups || [];
    if (!groups.includes('Admin') && !groups.includes('Owner')) {
      goto('/');
      return;
    }

    loadTreatments();
  });

  async function loadTreatments() {
    loading = true;
    try {
      const result = await api.listTreatments(MOCK_TENANT_ID);
      treatments = result.treatments || [];
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }

  async function createTreatment() {
    if (!newTreatment.name) {
      error = 'El nombre es requerido';
      return;
    }

    loading = true;
    error = null;
    success = null;

    try {
      await api.createTreatment({
        tenant_id: MOCK_TENANT_ID,
        ...newTreatment
      });

      success = 'Tratamiento creado exitosamente';
      newTreatment = { name: '', duration_minutes: 30, buffer_minutes: 10, price: 0 };
      await loadTreatments();
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Administración - Turnaki</title>
</svelte:head>

<main class="container">
  <h1>Panel de Administración</h1>

  <div class="tabs">
    <button class="tab {activeTab === 'treatments' ? 'active' : ''}" onclick={() => activeTab = 'treatments'}>
      Tratamientos
    </button>
    <button class="tab {activeTab === 'professionals' ? 'active' : ''}" onclick={() => activeTab = 'professionals'}>
      Profesionales
    </button>
    <button class="tab {activeTab === 'settings' ? 'active' : ''}" onclick={() => activeTab = 'settings'}>
      Configuración
    </button>
  </div>

  {#if error}
    <div class="alert alert-error">❌ {error}</div>
  {/if}

  {#if success}
    <div class="alert alert-success">✅ {success}</div>
  {/if}

  {#if activeTab === 'treatments'}
    <div class="tab-content">
      <div class="section">
        <h2>Crear Tratamiento</h2>
        
        <div class="form">
          <div class="field">
            <label for="name">Nombre del tratamiento</label>
            <input id="name" type="text" bind:value={newTreatment.name} placeholder="Ej: Limpieza Dental" />
          </div>

          <div class="field-row">
            <div class="field">
              <label for="duration">Duración (min)</label>
              <input id="duration" type="number" bind:value={newTreatment.duration_minutes} min="5" max="480" />
            </div>

            <div class="field">
              <label for="buffer">Buffer (min)</label>
              <input id="buffer" type="number" bind:value={newTreatment.buffer_minutes} min="0" max="60" />
            </div>

            <div class="field">
              <label for="price">Precio ($)</label>
              <input id="price" type="number" bind:value={newTreatment.price} min="0" step="1000" />
            </div>
          </div>

          <button class="btn-primary" onclick={createTreatment} disabled={loading}>
            {loading ? 'Creando...' : 'Crear Tratamiento'}
          </button>
        </div>
      </div>

      <div class="section">
        <h2>Tratamientos Existentes</h2>
        
        {#if loading}
          <p>Cargando...</p>
        {:else if treatments.length === 0}
          <p class="empty">No hay tratamientos creados aún</p>
        {:else}
          <div class="table">
            <table>
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Duración</th>
                  <th>Buffer</th>
                  <th>Precio</th>
                  <th>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {#each treatments as treatment}
                  <tr>
                    <td>{treatment.name}</td>
                    <td>{treatment.duration_minutes} min</td>
                    <td>{treatment.buffer_minutes} min</td>
                    <td>${treatment.price?.toLocaleString() || 0}</td>
                    <td>
                      <button class="btn-link">Editar</button>
                      <button class="btn-link danger">Eliminar</button>
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        {/if}
      </div>
    </div>
  {/if}

  {#if activeTab === 'professionals'}
    <div class="tab-content">
      <p class="placeholder">Gestión de profesionales (próximamente)</p>
    </div>
  {/if}

  {#if activeTab === 'settings'}
    <div class="tab-content">
      <p class="placeholder">Configuración de clínica (próximamente)</p>
    </div>
  {/if}
</main>

<style>
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }

  h1 {
    margin-bottom: 2rem;
    color: #1e293b;
  }

  .tabs {
    display: flex;
    gap: 0.5rem;
    border-bottom: 2px solid #e2e8f0;
    margin-bottom: 2rem;
  }

  .tab {
    background: none;
    border: none;
    padding: 1rem 2rem;
    font-weight: 600;
    color: #64748b;
    cursor: pointer;
    border-bottom: 3px solid transparent;
    transition: all 0.2s;
  }

  .tab.active {
    color: #0ea5e9;
    border-bottom-color: #0ea5e9;
  }

  .section {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 2rem;
    margin-bottom: 2rem;
  }

  h2 {
    margin: 0 0 1.5rem 0;
    font-size: 1.25rem;
    color: #334155;
  }

  .form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .field-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }

  label {
    font-weight: 600;
    color: #334155;
    font-size: 0.875rem;
  }

  input {
    padding: 0.75rem;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    font-size: 1rem;
  }

  .btn-primary {
    background: #0ea5e9;
    color: white;
    border: none;
    padding: 0.75rem 2rem;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
    align-self: flex-start;
  }

  .btn-primary:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .table {
    overflow-x: auto;
  }

  table {
    width: 100%;
    border-collapse: collapse;
  }

  th {
    text-align: left;
    padding: 0.75rem;
    background: #f8fafc;
    border-bottom: 2px solid #e2e8f0;
    font-weight: 600;
    color: #334155;
  }

  td {
    padding: 1rem 0.75rem;
    border-bottom: 1px solid #e2e8f0;
  }

  .btn-link {
    background: none;
    border: none;
    color: #0ea5e9;
    cursor: pointer;
    font-weight: 500;
    text-decoration: underline;
    padding: 0;
    margin-right: 1rem;
  }

  .btn-link.danger {
    color: #ef4444;
  }

  .alert {
    margin-bottom: 1rem;
    padding: 1rem;
    border-radius: 6px;
  }

  .alert-error {
    background: #fef2f2;
    border: 1px solid #ef4444;
    color: #991b1b;
  }

  .alert-success {
    background: #ecfdf5;
    border: 1px solid #10b981;
    color: #065f46;
  }

  .placeholder {
    text-align: center;
    padding: 4rem 2rem;
    color: #94a3b8;
    font-style: italic;
  }

  .empty {
    background: #f8fafc;
    border: 1px dashed #cbd5e1;
    border-radius: 8px;
    padding: 3rem 2rem;
  }
</style>

