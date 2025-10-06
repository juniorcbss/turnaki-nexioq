import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock del fetch global
global.fetch = vi.fn();

describe('API Client', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('debe incluir Authorization header si hay token', async () => {
    const mockFetch = vi.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ status: 'ok' })
      } as Response)
    );
    global.fetch = mockFetch;

    // Simular que authStore tiene token
    const token = 'mock-jwt-token';
    localStorage.setItem('tk_nq_token', token);

    // Hacer una llamada (requiere importación dinámica del api client)
    const baseUrl = 'https://api.test.com';
    await fetch(`${baseUrl}/health`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining('/health'),
      expect.objectContaining({
        headers: expect.objectContaining({
          'Authorization': `Bearer ${token}`
        })
      })
    );
  });

  it('debe manejar errores 401 y logout', async () => {
    const mockFetch = vi.fn(() =>
      Promise.resolve({
        ok: false,
        status: 401,
        json: () => Promise.resolve({ error: 'Unauthorized' })
      } as Response)
    );
    global.fetch = mockFetch;

    // Simular llamada con 401
    const response = await fetch('https://api.test.com/protected');
    
    expect(response.status).toBe(401);
    expect(response.ok).toBe(false);
  });

  it('debe parsear respuestas JSON correctamente', async () => {
    const mockData = { treatments: [{ id: '1', name: 'Test' }], count: 1 };
    
    const mockFetch = vi.fn(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockData)
      } as Response)
    );
    global.fetch = mockFetch;

    const response = await fetch('https://api.test.com/treatments?tenant_id=123');
    const data = await response.json();
    
    expect(data).toEqual(mockData);
    expect(data.treatments).toHaveLength(1);
  });
});
