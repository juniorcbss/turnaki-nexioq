<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/auth.svelte';

  let appointments = $state([]);
  let loading = $state(true);

  onMount(() => {
    if (!authStore.isAuthenticated) {
      goto('/');
      return;
    }

    // Mock appointments (TODO: fetch from API)
    setTimeout(() => {
      appointments = [
        {
          id: '1',
          treatment: 'Limpieza Dental',
          date: '2025-10-05',
          time: '10:00',
          professional: 'Dra. María González',
          status: 'confirmed'
        },
        {
          id: '2',
          treatment: 'Ortodoncia - Consulta',
          date: '2025-10-12',
          time: '14:00',
          professional: 'Dr. Carlos Ruiz',
          status: 'confirmed'
        }
      ];
      loading = false;
    }, 500);
  });
</script>

<svelte:head>
  <title>Mis Citas - Turnaki</title>
</svelte:head>

<main class="container">
  <h1>Mis Citas</h1>

  {#if loading}
    <div class="loading">Cargando citas...</div>
  {:else if appointments.length === 0}
    <div class="empty">
      <p>No tienes citas programadas</p>
      <button class="btn-primary" onclick={() => goto('/booking')}>
        Reservar Cita
      </button>
    </div>
  {:else}
    <div class="appointments-list">
      {#each appointments as appointment}
        <div class="appointment-card">
          <div class="appointment-header">
            <h3>{appointment.treatment}</h3>
            <span class="status status-{appointment.status}">
              {appointment.status === 'confirmed' ? 'Confirmada' : appointment.status}
            </span>
          </div>
          
          <div class="appointment-details">
            <div class="detail">
              <span class="icon">📅</span>
              {appointment.date} a las {appointment.time}
            </div>
            <div class="detail">
              <span class="icon">👨‍⚕️</span>
              {appointment.professional}
            </div>
          </div>

          <div class="appointment-actions">
            <button class="btn-link">Reprogramar</button>
            <button class="btn-link danger">Cancelar</button>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</main>

<style>
  .container {
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem;
  }

  h1 {
    margin-bottom: 2rem;
    color: #1e293b;
  }

  .loading, .empty {
    text-align: center;
    padding: 4rem 2rem;
    color: #64748b;
  }

  .btn-primary {
    background: #0ea5e9;
    color: white;
    border: none;
    padding: 0.75rem 2rem;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 1rem;
  }

  .appointments-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .appointment-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 1.5rem;
    transition: box-shadow 0.2s;
  }

  .appointment-card:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }

  .appointment-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1rem;
  }

  .appointment-header h3 {
    margin: 0;
    color: #1e293b;
  }

  .status {
    padding: 0.25rem 0.75rem;
    border-radius: 12px;
    font-size: 0.875rem;
    font-weight: 600;
  }

  .status-confirmed {
    background: #ecfdf5;
    color: #10b981;
  }

  .appointment-details {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }

  .detail {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #475569;
  }

  .icon {
    font-size: 1.25rem;
  }

  .appointment-actions {
    display: flex;
    gap: 1rem;
    padding-top: 1rem;
    border-top: 1px solid #e2e8f0;
  }

  .btn-link {
    background: none;
    border: none;
    color: #0ea5e9;
    cursor: pointer;
    font-weight: 500;
    text-decoration: underline;
    padding: 0;
  }

  .btn-link.danger {
    color: #ef4444;
  }
</style>

