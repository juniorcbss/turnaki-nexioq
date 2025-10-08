<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/auth.svelte';

  let error = $state(null);
  let processing = $state(true);

  import { COGNITO } from '$lib/../config.js';

  onMount(async () => {
    const params = new URLSearchParams(window.location.search);
    const code = params.get('code');

    if (!code) {
      error = 'No se recibió código de autorización';
      processing = false;
      return;
    }

    try {
      const tokenUrl = `${COGNITO.domain}/oauth2/token`;
      const response = await fetch(tokenUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'authorization_code',
          client_id: COGNITO.clientId,
          code,
          redirect_uri: COGNITO.redirectUri
        })
      });

      if (!response.ok) {
        throw new Error(`Token exchange failed: ${response.statusText}`);
      }

      const tokens = await response.json();
      authStore.setToken(tokens.id_token);

      goto('/');
    } catch (err) {
      error = err.message;
      processing = false;
    }
  });
</script>

<svelte:head>
  <title>Autenticando...</title>
</svelte:head>

<main class="container">
  {#if processing}
    <div class="loading">
      <div class="spinner"></div>
      <p>Autenticando...</p>
    </div>
  {:else if error}
    <div class="error">
      <h2>Error de autenticación</h2>
      <p>{error}</p>
      <button onclick={() => goto('/')}>Volver al inicio</button>
    </div>
  {/if}
</main>

<style>
  .container {
    max-width: 600px;
    margin: 4rem auto;
    padding: 2rem;
    text-align: center;
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }

  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #e2e8f0;
    border-top-color: #0ea5e9;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .error {
    background: #fef2f2;
    border: 1px solid #ef4444;
    padding: 2rem;
    border-radius: 8px;
  }

  button {
    margin-top: 1rem;
    padding: 0.75rem 1.5rem;
    background: #0ea5e9;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
  }
</style>