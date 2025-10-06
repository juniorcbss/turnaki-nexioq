<script>
  import { onMount } from 'svelte';
  import { authStore } from '$lib/auth.svelte';
  
  let apiBase = $state(import.meta.env.VITE_API_BASE || '');
  let healthStatus = $state(null);
  let loading = $state(false);
  let error = $state(null);
  
  async function checkHealth() {
    loading = true;
    error = null;
    
    try {
      const res = await fetch(`${apiBase}/health`);
      if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`);
      healthStatus = await res.json();
    } catch (err) {
      error = err.message;
      healthStatus = null;
    } finally {
      loading = false;
    }
  }
  
  onMount(() => {
    if (apiBase) checkHealth();
  });
</script>

<svelte:head>
  <title>Turnaki - Reservas Odontológicas</title>
</svelte:head>

<main class="container">
  <header class="header">
    <div>
      <h1>Turnaki</h1>
      <p class="subtitle">Plataforma SaaS de Reservas Odontológicas</p>
    </div>
    
    <div class="auth-section">
      {#if authStore.isAuthenticated}
        <div class="user-info">
          <span>👤 {authStore.currentUser?.email}</span>
          {#if authStore.currentUser?.groups && authStore.currentUser.groups.length > 0}
            <span class="badge">{authStore.currentUser.groups[0]}</span>
          {/if}
          <button onclick={() => authStore.logout()} class="btn-secondary">Cerrar sesión</button>
        </div>
      {:else}
        <button onclick={() => authStore.login()} class="btn-primary">Iniciar sesión</button>
      {/if}
    </div>
  </header>

  <nav class="nav">
    {#if authStore.isAuthenticated}
      <a href="/booking" class="nav-link">📅 Reservar Cita</a>
      <a href="/my-appointments" class="nav-link">📋 Mis Citas</a>
      {#if authStore.currentUser?.groups?.includes('Admin') || authStore.currentUser?.groups?.includes('Owner') || authStore.currentUser?.groups?.includes('Odontólogo') || authStore.currentUser?.groups?.includes('Recepción')}
        <a href="/calendar" class="nav-link">🗓️ Calendario</a>
        <a href="/admin" class="nav-link">⚙️ Administración</a>
      {/if}
    {/if}
  </nav>
  
  <div class="api-status">
    <h2>Estado de la API</h2>
    <p>Endpoint: <code>{apiBase || 'No configurado'}</code></p>
    
    <button onclick={checkHealth} disabled={loading} class="btn-primary">
      {loading ? '⏳ Verificando...' : '🔄 Verificar API'}
    </button>
    
    {#if error}
      <div class="alert alert-error">
        ❌ Error: {error}
      </div>
    {/if}
    
    {#if healthStatus}
      <div class="alert alert-success">
        ✅ API operativa
        <pre>{JSON.stringify(healthStatus, null, 2)}</pre>
      </div>
    {/if}
  </div>

  {#if authStore.isAuthenticated}
    <div class="welcome">
      <h3>Bienvenido, {authStore.currentUser?.name || authStore.currentUser?.email}! 🎉</h3>
      <p>Estás autenticado correctamente. Ahora puedes:</p>
      <ul>
        <li>Reservar citas odontológicas</li>
        <li>Ver y gestionar tus reservas</li>
        {#if authStore.currentUser?.groups?.includes('Admin') || authStore.currentUser?.groups?.includes('Owner')}
          <li>Administrar catálogo de servicios</li>
          <li>Gestionar agenda y profesionales</li>
        {/if}
      </ul>
    </div>
  {/if}
</main>

<style>
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
    font-family: system-ui, -apple-system, sans-serif;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 3rem;
    padding-bottom: 2rem;
    border-bottom: 2px solid #e2e8f0;
  }
  
  h1 {
    font-size: 2.5rem;
    font-weight: 700;
    margin: 0;
    color: #1e293b;
  }
  
  .subtitle {
    color: #64748b;
    margin: 0.5rem 0 0 0;
  }

  .auth-section {
    display: flex;
    gap: 1rem;
    align-items: center;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 1rem;
    font-size: 0.875rem;
  }

  .badge {
    background: #0ea5e9;
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 600;
  }

  .nav {
    display: flex;
    gap: 1rem;
    margin-bottom: 2rem;
    flex-wrap: wrap;
  }

  .nav-link {
    padding: 0.75rem 1.5rem;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    text-decoration: none;
    color: #334155;
    font-weight: 500;
    transition: all 0.2s;
  }

  .nav-link:hover {
    background: #e2e8f0;
    border-color: #cbd5e1;
  }
  
  .api-status {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;
  }
  
  h2 {
    font-size: 1.25rem;
    margin: 0 0 1rem 0;
  }

  h3 {
    color: #0ea5e9;
    margin-bottom: 1rem;
  }

  .welcome {
    background: linear-gradient(135deg, #ecfdf5 0%, #f0f9ff 100%);
    border: 1px solid #10b981;
    padding: 2rem;
    border-radius: 8px;
  }

  .welcome ul {
    list-style: none;
    padding: 0;
  }

  .welcome li {
    padding: 0.5rem 0;
    padding-left: 1.5rem;
  }

  .welcome li::before {
    content: '✓ ';
    color: #10b981;
    font-weight: bold;
    margin-right: 0.5rem;
  }
  
  code {
    background: #fff;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-family: 'Monaco', 'Courier New', monospace;
    font-size: 0.875rem;
  }
  
  .btn-primary {
    background: #0ea5e9;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s;
  }
  
  .btn-primary:hover:not(:disabled) {
    background: #0284c7;
  }
  
  .btn-primary:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .btn-secondary {
    background: #64748b;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-weight: 500;
    cursor: pointer;
    font-size: 0.875rem;
  }

  .btn-secondary:hover {
    background: #475569;
  }
  
  .alert {
    margin-top: 1rem;
    padding: 1rem;
    border-radius: 6px;
  }
  
  .alert-success {
    background: #ecfdf5;
    border: 1px solid #10b981;
    color: #065f46;
  }
  
  .alert-error {
    background: #fef2f2;
    border: 1px solid #ef4444;
    color: #991b1b;
  }
  
  pre {
    background: #1e293b;
    color: #f1f5f9;
    padding: 1rem;
    border-radius: 4px;
    overflow-x: auto;
    font-size: 0.875rem;
    margin-top: 0.5rem;
  }
</style>