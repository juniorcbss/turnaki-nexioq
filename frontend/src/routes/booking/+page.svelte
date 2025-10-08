<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/auth.svelte';
  import { api } from '$lib/api.svelte';

  let step = $state(1);
  let loading = $state(false);
  let error = $state(null);
  
  // Step 1: Selección de servicio
  let treatments = $state([]);
  let selectedTreatment = $state(null);
  
  // Step 2: Fecha y hora
  let selectedDate = $state('');
  let selectedTime = $state('');
  let availableSlots = $state([]);
  
  // Step 3: Datos del paciente
  let patientName = $state('');
  let patientEmail = $state('');
  
  // Booking result
  let bookingConfirmed = $state(null);
  
  const TENANT_ID = authStore.user?.tenant_id || 'tenant-demo-001';
  const SITE_ID = 'site-001';
  const PROFESSIONAL_ID = 'prof-001';

  onMount(async () => {
    if (!authStore.isAuthenticated) {
      goto('/');
      return;
    }
    
    // Load treatments
    loadTreatments();
  });

  async function loadTreatments() {
    loading = true;
    try {
      const result = await api.listTreatments(TENANT_ID);
      treatments = result.treatments || [];
      
      // Mock treatments si la tabla está vacía
      if (treatments.length === 0) {
        treatments = [
          { id: 't1', name: 'Limpieza Dental', duration_minutes: 30, price: 50000 },
          { id: 't2', name: 'Extracción Simple', duration_minutes: 45, price: 80000 },
          { id: 't3', name: 'Ortodoncia - Consulta', duration_minutes: 60, price: 120000 }
        ];
      }
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }

  async function selectTreatment(treatment) {
    selectedTreatment = treatment;
    step = 2;
    
    // Auto-cargar slots para mañana
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    selectedDate = tomorrow.toISOString().split('T')[0];
    await loadAvailability();
  }

  async function loadAvailability() {
    if (!selectedDate) return;
    
    loading = true;
    try {
      const result = await api.getAvailability({
        site_id: SITE_ID,
        professional_id: PROFESSIONAL_ID,
        date: selectedDate
      });
      
      availableSlots = result.slots || [];
    } catch (err) {
      error = err.message;
      // Mock slots si falla
      availableSlots = [
        { start: '09:00', end: '09:45', available: true },
        { start: '10:00', end: '10:45', available: true },
        { start: '11:00', end: '11:45', available: true },
        { start: '14:00', end: '14:45', available: true },
        { start: '15:00', end: '15:45', available: true }
      ];
    } finally {
      loading = false;
    }
  }

  function selectTimeSlot(slot) {
    selectedTime = slot.start;
    patientName = authStore.user?.name || '';
    patientEmail = authStore.user?.email || '';
    step = 3;
  }

  async function confirmBooking() {
    if (!patientName || !patientEmail) {
      error = 'Completa todos los campos';
      return;
    }

    loading = true;
    error = null;

    try {
      const startDateTime = `${selectedDate}T${selectedTime}:00Z`;
      
      const result = await api.createBooking({
        tenant_id: TENANT_ID,
        site_id: SITE_ID,
        professional_id: PROFESSIONAL_ID,
        treatment_id: selectedTreatment.id,
        start_time: startDateTime,
        patient_name: patientName,
        patient_email: patientEmail
      });
      
      bookingConfirmed = result;
      step = 4;
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }

  function restart() {
    step = 1;
    selectedTreatment = null;
    selectedDate = '';
    selectedTime = '';
    bookingConfirmed = null;
    error = null;
  }
</script>

<svelte:head>
  <title>Reservar Cita - Turnaki</title>
</svelte:head>

<main class="container">
  <div class="wizard">
    <div class="steps-indicator">
      <div class="step {step >= 1 ? 'active' : ''}">1. Servicio</div>
      <div class="step {step >= 2 ? 'active' : ''}">2. Fecha/Hora</div>
      <div class="step {step >= 3 ? 'active' : ''}">3. Confirmar</div>
    </div>

    {#if error}
      <div class="alert alert-error">❌ {error}</div>
    {/if}

    {#if step === 1}
      <div class="step-content">
        <h2>Selecciona un servicio</h2>
        
        {#if loading}
          <p>Cargando servicios...</p>
        {:else}
          <div class="treatments-grid">
            {#each treatments as treatment}
              <button class="treatment-card" onclick={() => selectTreatment(treatment)}>
                <h3>{treatment.name}</h3>
                <div class="duration">{treatment.duration_minutes} minutos</div>
                {#if treatment.price}
                  <div class="price">${treatment.price.toLocaleString()}</div>
                {/if}
              </button>
            {/each}
          </div>
        {/if}
      </div>
    {/if}

    {#if step === 2}
      <div class="step-content">
        <h2>{selectedTreatment?.name}</h2>
        <p>Selecciona fecha y hora</p>
        
        <input type="date" bind:value={selectedDate} onchange={loadAvailability} min={new Date().toISOString().split('T')[0]} />
        
        {#if loading}
          <p>Cargando disponibilidad...</p>
        {:else if availableSlots.length > 0}
          <div class="slots-grid">
            {#each availableSlots as slot}
              {#if slot.available}
                <button class="slot-btn" onclick={() => selectTimeSlot(slot)}>
                  {slot.start}
                </button>
              {/if}
            {/each}
          </div>
        {:else}
          <p>No hay horarios disponibles para esta fecha</p>
        {/if}
        
        <button class="btn-secondary" onclick={() => step = 1}>← Volver</button>
      </div>
    {/if}

    {#if step === 3}
      <div class="step-content">
        <h2>Confirmar reserva</h2>
        
        <div class="summary">
          <div class="summary-item">
            <strong>Servicio:</strong> {selectedTreatment?.name}
          </div>
          <div class="summary-item">
            <strong>Fecha:</strong> {selectedDate}
          </div>
          <div class="summary-item">
            <strong>Hora:</strong> {selectedTime}
          </div>
          <div class="summary-item">
            <strong>Duración:</strong> {selectedTreatment?.duration_minutes} minutos
          </div>
        </div>
        
        <div class="form">
          <div class="field">
            <label for="name">Nombre completo</label>
            <input id="name" type="text" bind:value={patientName} required />
          </div>
          
          <div class="field">
            <label for="email">Email</label>
            <input id="email" type="email" bind:value={patientEmail} required />
          </div>
        </div>
        
        <div class="actions">
          <button class="btn-secondary" onclick={() => step = 2}>← Volver</button>
          <button class="btn-primary" onclick={confirmBooking} disabled={loading || !patientName || !patientEmail}>
            {loading ? 'Confirmando...' : 'Confirmar Reserva'}
          </button>
        </div>
      </div>
    {/if}

    {#if step === 4 && bookingConfirmed}
      <div class="step-content success">
        <div class="success-icon">✅</div>
        <h2>¡Reserva confirmada!</h2>
        
        <div class="confirmation">
          <p><strong>Código de reserva:</strong> {bookingConfirmed.id}</p>
          <p><strong>Servicio:</strong> {selectedTreatment?.name}</p>
          <p><strong>Fecha:</strong> {selectedDate} a las {selectedTime}</p>
          <p>Hemos enviado un email de confirmación a {patientEmail}</p>
        </div>
        
        <div class="actions">
          <button class="btn-primary" onclick={restart}>Nueva Reserva</button>
          <button class="btn-secondary" onclick={() => goto('/my-appointments')}>Ver Mis Citas</button>
        </div>
      </div>
    {/if}
  </div>
</main>

<style>
  .container {
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem;
  }

  .wizard {
    background: white;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    padding: 2rem;
  }

  .steps-indicator {
    display: flex;
    justify-content: space-between;
    margin-bottom: 3rem;
    position: relative;
  }

  .steps-indicator::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    height: 2px;
    background: #e2e8f0;
    z-index: 0;
  }

  .step {
    background: white;
    border: 2px solid #e2e8f0;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    font-weight: 600;
    color: #94a3b8;
    position: relative;
    z-index: 1;
  }

  .step.active {
    border-color: #0ea5e9;
    color: #0ea5e9;
    background: #f0f9ff;
  }

  .step-content {
    min-height: 400px;
  }

  h2 {
    margin-bottom: 1.5rem;
    color: #1e293b;
  }

  .treatments-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 1rem;
  }

  .treatment-card {
    background: #f8fafc;
    border: 2px solid #e2e8f0;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
  }

  .treatment-card:hover {
    border-color: #0ea5e9;
    background: #f0f9ff;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(14, 165, 233, 0.2);
  }

  .treatment-card h3 {
    margin: 0 0 0.5rem 0;
    color: #1e293b;
  }

  .duration {
    color: #64748b;
    font-size: 0.875rem;
    margin-bottom: 0.5rem;
  }

  .price {
    font-size: 1.25rem;
    font-weight: 700;
    color: #0ea5e9;
  }

  input[type="date"] {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    font-size: 1rem;
    margin-bottom: 1.5rem;
  }

  .slots-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
    gap: 0.75rem;
    margin-top: 1rem;
  }

  .slot-btn {
    padding: 1rem;
    background: #f8fafc;
    border: 2px solid #e2e8f0;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
    transition: all 0.2s;
  }

  .slot-btn:hover {
    background: #0ea5e9;
    color: white;
    border-color: #0ea5e9;
  }

  .summary {
    background: #f8fafc;
    padding: 1.5rem;
    border-radius: 8px;
    margin-bottom: 2rem;
  }

  .summary-item {
    padding: 0.5rem 0;
    border-bottom: 1px solid #e2e8f0;
  }

  .summary-item:last-child {
    border-bottom: none;
  }

  .form {
    margin-bottom: 2rem;
  }

  .field {
    margin-bottom: 1rem;
  }

  .field label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #334155;
  }

  .field input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    font-size: 1rem;
  }

  .actions {
    display: flex;
    gap: 1rem;
    justify-content: flex-end;
  }

  .btn-primary {
    background: #0ea5e9;
    color: white;
    border: none;
    padding: 0.75rem 2rem;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
  }

  .btn-primary:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .btn-secondary {
    background: #64748b;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
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

  .success {
    text-align: center;
  }

  .success-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .confirmation {
    background: #ecfdf5;
    border: 1px solid #10b981;
    padding: 2rem;
    border-radius: 8px;
    margin: 2rem 0;
    text-align: left;
  }

  .confirmation p {
    margin: 0.75rem 0;
  }
</style>

