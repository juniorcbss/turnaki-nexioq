<script lang="ts">
  import { onMount } from 'svelte';
  import { Calendar } from '@fullcalendar/core';
  import dayGridPlugin from '@fullcalendar/daygrid';
  import timeGridPlugin from '@fullcalendar/timegrid';
  import interactionPlugin from '@fullcalendar/interaction';
  import listPlugin from '@fullcalendar/list';
  import { apiClient } from '$lib/api.svelte';
  import type { BookingDto } from '$lib/api.svelte';
  import { authStore } from '$lib/auth.svelte';
  import { hasRole } from '$lib/auth/roles';
  
  let calendarEl = $state<HTMLElement>();
  let calendar: Calendar;
  let bookings = $state<any[]>([]);
  let loading = $state(true);
  let error = $state('');
  let selectedBooking = $state<any>(null);
  let showModal = $state(false);
  let showRescheduleModal = $state(false);
  let newStartTime = $state('');
  
  const TENANT_ID = authStore.user?.tenant_id || 'tenant-demo-001';
  let notAuthorized = $state(false);
  
  onMount(async () => {
    if (!authStore.isAuthenticated) {
      notAuthorized = true;
      return;
    }
    const user = authStore.user;
    if (!hasRole(user, ['Admin', 'Owner', 'Recepción', 'Odontólogo'])) {
      notAuthorized = true;
      return;
    }
    await loadBookings();
    
    if (!calendarEl) return;
    
    calendar = new Calendar(calendarEl, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin],
      initialView: 'timeGridWeek',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek'
      },
      locale: 'es',
      slotMinTime: '08:00:00',
      slotMaxTime: '20:00:00',
      allDaySlot: false,
      height: 'auto',
      events: bookings.map(b => ({
        id: b.id,
        title: `${b.patient_name} - ${b.status}`,
        start: b.start_time,
        end: b.end_time,
        backgroundColor: b.status === 'confirmed' ? '#10b981' : 
                        b.status === 'cancelled' ? '#ef4444' : '#6b7280',
        borderColor: b.status === 'confirmed' ? '#059669' : 
                     b.status === 'cancelled' ? '#dc2626' : '#4b5563',
        extendedProps: {
          patientEmail: b.patient_email,
          treatmentId: b.treatment_id,
          professionalId: b.professional_id,
          status: b.status
        }
      })),
      eventClick: (info) => {
        const booking = bookings.find(b => b.id === info.event.id);
        if (booking) {
          selectedBooking = booking;
          showModal = true;
        }
      },
      dateClick: (info) => {
        console.log('Date clicked:', info.dateStr);
      },
      editable: true,
      eventDrop: async (info) => {
        // Drag & drop para reprogramar
        await rescheduleBooking(info.event.id, info.event.start?.toISOString() || '');
      }
    });
    
    calendar.render();
  });
  
  async function loadBookings() {
    try {
      loading = true;
      error = '';
      const response = await apiClient.get<{ bookings: BookingDto[] }>(`/bookings?tenant_id=${TENANT_ID}`);
      bookings = response.bookings || [];
      
      // Actualizar eventos del calendario si ya está renderizado
      if (calendar) {
        calendar.removeAllEvents();
        calendar.addEventSource(bookings.map(b => ({
          id: b.id,
          title: `${b.patient_name} - ${b.status}`,
          start: b.start_time,
          end: b.end_time,
          backgroundColor: b.status === 'confirmed' ? '#10b981' : 
                          b.status === 'cancelled' ? '#ef4444' : '#6b7280',
          borderColor: b.status === 'confirmed' ? '#059669' : 
                       b.status === 'cancelled' ? '#dc2626' : '#4b5563',
          extendedProps: {
            patientEmail: b.patient_email,
            treatmentId: b.treatment_id,
            professionalId: b.professional_id,
            status: b.status
          }
        })));
      }
    } catch (err: any) {
      error = err.message || 'Error al cargar citas';
      console.error('Error loading bookings:', err);
    } finally {
      loading = false;
    }
  }
  
  async function cancelBooking(bookingId: string) {
    if (!confirm('¿Estás seguro de cancelar esta cita?')) return;
    
    try {
      await apiClient.delete(`/bookings/${bookingId}`);
      showModal = false;
      await loadBookings();
    } catch (err: any) {
      alert('Error al cancelar: ' + (err.message || 'Error desconocido'));
    }
  }
  
  async function rescheduleBooking(bookingId: string, newTime: string) {
    try {
      await apiClient.put(`/bookings/${bookingId}`, {
        start_time: newTime
      });
      showRescheduleModal = false;
      showModal = false;
      await loadBookings();
    } catch (err: any) {
      alert('Error al reprogramar: ' + (err.message || 'Error desconocido'));
      await loadBookings(); // Recargar para revertir cambios visuales
    }
  }
  
  function openRescheduleModal() {
    if (selectedBooking) {
      const start = new Date(selectedBooking.start_time);
      newStartTime = start.toISOString().slice(0, 16);
      showRescheduleModal = true;
    }
  }
</script>

<svelte:head>
  <title>Calendario - Turnaki NexioQ</title>
</svelte:head>

<div class="max-w-7xl mx-auto px-4 py-8">
  <div class="mb-6 flex justify-between items-center">
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Calendario de Citas</h1>
      <p class="text-gray-600 mt-2">Gestiona todas las citas programadas</p>
    </div>
    <button 
      onclick={() => loadBookings()}
      class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
    >
      🔄 Actualizar
    </button>
  </div>
  
  {#if loading}
    <div class="text-center py-12" role="status" aria-live="polite" data-testid="loading-calendar">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      <p class="mt-4 text-gray-600">Cargando citas...</p>
    </div>
  {:else if error}
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded" role="alert" aria-live="assertive" data-testid="alert-error">
      <p><strong>Error:</strong> {error}</p>
    </div>
  {:else}
    <div class="bg-white rounded-lg shadow p-4">
      <div bind:this={calendarEl}></div>
    </div>
    
    <div class="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-green-50 border border-green-200 rounded-lg p-4">
        <h3 class="font-semibold text-green-800">Confirmadas</h3>
        <p class="text-3xl font-bold text-green-600">
          {bookings.filter(b => b.status === 'confirmed').length}
        </p>
      </div>
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <h3 class="font-semibold text-red-800">Canceladas</h3>
        <p class="text-3xl font-bold text-red-600">
          {bookings.filter(b => b.status === 'cancelled').length}
        </p>
      </div>
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 class="font-semibold text-blue-800">Total</h3>
        <p class="text-3xl font-bold text-blue-600">
          {bookings.length}
        </p>
      </div>
    </div>
  {/if}
</div>

<!-- Modal de detalles -->
{#if showModal && selectedBooking}
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
      <h2 class="text-2xl font-bold mb-4">Detalles de la Cita</h2>
      
      <div class="space-y-3">
        <div>
          <div class="block text-sm font-medium text-gray-700">Paciente</div>
          <p class="text-gray-900">{selectedBooking.patient_name}</p>
        </div>
        
        <div>
          <div class="block text-sm font-medium text-gray-700">Email</div>
          <p class="text-gray-900">{selectedBooking.patient_email}</p>
        </div>
        
        <div>
          <div class="block text-sm font-medium text-gray-700">Fecha/Hora</div>
          <p class="text-gray-900">
            {new Date(selectedBooking.start_time).toLocaleString('es-EC', {
              dateStyle: 'full',
              timeStyle: 'short'
            })}
          </p>
        </div>
        
        <div>
          <div class="block text-sm font-medium text-gray-700">Estado</div>
          <span class={`inline-block px-3 py-1 rounded-full text-sm font-medium ${
            selectedBooking.status === 'confirmed' 
              ? 'bg-green-100 text-green-800' 
              : 'bg-red-100 text-red-800'
          }`}>
            {selectedBooking.status === 'confirmed' ? 'Confirmada' : 'Cancelada'}
          </span>
        </div>
      </div>
      
      <div class="mt-6 flex gap-3">
        {#if selectedBooking.status === 'confirmed'}
          <button
            onclick={() => openRescheduleModal()}
            class="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Reprogramar
          </button>
          <button
            onclick={() => cancelBooking(selectedBooking.id)}
            class="flex-1 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Cancelar Cita
          </button>
        {/if}
        <button
          onclick={() => showModal = false}
          class="flex-1 px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
        >
          Cerrar
        </button>
      </div>
    </div>
  </div>
{/if}

<!-- Modal de reprogramación -->
{#if showRescheduleModal && selectedBooking}
  <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
    <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
      <h2 class="text-2xl font-bold mb-4">Reprogramar Cita</h2>
      
      <div class="mb-4">
        <label for="reschedule-datetime" class="block text-sm font-medium text-gray-700 mb-2">Nueva Fecha/Hora</label>
        <input
          id="reschedule-datetime"
          type="datetime-local"
          bind:value={newStartTime}
          class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div class="flex gap-3">
        <button
          onclick={() => rescheduleBooking(selectedBooking.id, new Date(newStartTime).toISOString())}
          class="flex-1 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Confirmar
        </button>
        <button
          onclick={() => showRescheduleModal = false}
          class="flex-1 px-4 py-2 bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
        >
          Cancelar
        </button>
      </div>
    </div>
  </div>
{/if}

  <style>
    /* FullCalendar CSS imports removed temporarily to fix build issues */
    .fc {
      font-family: system-ui, sans-serif;
    }
</style>
