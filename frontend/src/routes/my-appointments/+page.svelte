<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/auth.svelte';
  import { apiClient } from '$lib/api.svelte';

  const TENANT_ID = authStore.user?.tenant_id || 'tenant-demo-001';

  let appointments = $state([]);
  let loading = $state(true);
  let error = $state('');

  function toLocal(dateIso) {
    try {
      return new Date(dateIso).toLocaleString('es-EC', {
        dateStyle: 'medium',
        timeStyle: 'short'
      });
    } catch (_) {
      return dateIso;
    }
  }

  function statusLabel(s) {
    if (s === 'confirmed') return 'Confirmada';
    if (s === 'cancelled') return 'Cancelada';
    return s;
  }

  async function loadAppointments() {
    try {
      loading = true;
      error = '';
      let res;
      try {
        res = await apiClient.get(`/bookings?tenant_id=${TENANT_ID}`);
      } catch (e) {
        if ((e.message || '').toLowerCase().includes('método no soportado')) {
          res = await apiClient.get(`/bookings/?tenant_id=${TENANT_ID}`);
        } else {
          throw e;
        }
      }
      appointments = res.bookings.map((b) => ({
        id: b.id,
        treatment: b.treatment_id || 'Tratamiento',
        dateTime: b.start_time,
        professional: b.professional_id,
        status: b.status
      }));
    } catch (e) {
      error = e.message || 'Error cargando citas';
    } finally {
      loading = false;
    }
  }

  async function cancelAppointment(id) {
    if (!confirm('¿Cancelar esta cita?')) return;
    try {
      await apiClient.delete(`/bookings/${id}`);
      await loadAppointments();
    } catch (e) {
      alert(e.message || 'No se pudo cancelar');
    }
  }

  async function rescheduleAppointment(id) {
    const input = prompt('Nueva fecha/hora (ISO 8601, ej: 2025-10-10T10:30:00Z)');
    if (!input) return;
    try {
      await apiClient.put(`/bookings/${id}`, { start_time: input });
      await loadAppointments();
    } catch (e) {
      alert(e.message || 'No se pudo reprogramar');
    }
  }

  onMount(async () => {
    if (!authStore.isAuthenticated) {
      goto('/');
      return;
    }
    await loadAppointments();
  });
</script>

<svelte:head>
  <title>Mis Citas - Turnaki</title>
</svelte:head>

<main class="container">
  <h1>Mis Citas</h1>

  {#if loading}
    <div class="loading">Cargando citas...</div>
  {:else if error}
    <div class="empty">
      <p>{error}</p>
      <button class="btn-primary" onclick={loadAppointments}>Reintentar</button>
    </div>
  {:else if appointments.length === 0}
    <div class="empty">
      <p>No tienes citas programadas</p>
      <button class="btn-primary" onclick={() => goto('/booking')}>
        Reservar Cita
      </button>
    </div>
  {:else}
    <div class="appointments-list">
      {#each appointments as a}
        <div class="appointment-card">
          <div class="appointment-header">
            <h3>{a.treatment}</h3>
            <span class={`status status-${a.status}`}>{statusLabel(a.status)}</span>
          </div>
          <div class="appointment-details">
            <div class="detail">
              <span class="icon">📅</span>
              {toLocal(a.dateTime)}
            </div>
            <div class="detail">
              <span class="icon">👨‍⚕️</span>
              {a.professional}
            </div>
          </div>
          <div class="appointment-actions">
            <button class="btn-link" onclick={() => rescheduleAppointment(a.id)}>Reprogramar</button>
            <button class="btn-link danger" onclick={() => cancelAppointment(a.id)}>Cancelar</button>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</main>

<style>
  .container { max-width: 900px; margin: 0 auto; padding: 2rem; }
  h1 { margin-bottom: 2rem; color: #1e293b; }
  .loading, .empty { text-align: center; padding: 4rem 2rem; color: #64748b; }
  .btn-primary { background: #0ea5e9; color: white; border: none; padding: 0.75rem 2rem; border-radius: 6px; font-weight: 600; cursor: pointer; margin-top: 1rem; }
  .appointments-list { display: flex; flex-direction: column; gap: 1rem; }
  .appointment-card { background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1.5rem; transition: box-shadow 0.2s; }
  .appointment-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
  .appointment-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; }
  .appointment-header h3 { margin: 0; color: #1e293b; }
  .status { padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; }
  .status-confirmed { background: #ecfdf5; color: #0f766e; }
  .status-cancelled { background: #fee2e2; color: #b91c1c; }
  .appointment-details { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 1rem; }
  .detail { display: flex; align-items: center; gap: 0.5rem; color: #475569; }
  .icon { font-size: 1.25rem; }
  .appointment-actions { display: flex; gap: 1rem; padding-top: 1rem; border-top: 1px solid #e2e8f0; }
  .btn-link { background: none; border: none; color: #0ea5e9; cursor: pointer; font-weight: 500; text-decoration: underline; padding: 0; }
  .btn-link.danger { color: #ef4444; }
</style>

