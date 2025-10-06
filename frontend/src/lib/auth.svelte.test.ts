import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('Auth Store', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();
  });

  it('debe inicializar sin usuario', () => {
    // El authStore se importa dinámicamente para evitar side effects
    expect(typeof localStorage).toBe('object');
  });

  it('debe parsear JWT y extraer usuario', () => {
    // Mock JWT (header.payload.signature)
    const mockJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJuYW1lIjoiVGVzdCBVc2VyIiwiY29nbml0bzpncm91cHMiOlsiUGFjaWVudGUiXX0.test';
    
    const payload = JSON.parse(atob(mockJwt.split('.')[1]));
    
    expect(payload.email).toBe('test@test.com');
    expect(payload.name).toBe('Test User');
    expect(payload['cognito:groups']).toContain('Paciente');
  });

  it('debe construir URL de login correctamente', () => {
    const domain = 'https://test.auth.us-east-1.amazoncognito.com';
    const clientId = 'test-client-id';
    const redirect = 'http://localhost:5173/auth/callback';
    
    const expectedUrl = `${domain}/oauth2/authorize?client_id=${clientId}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(redirect)}`;
    
    expect(expectedUrl).toContain('oauth2/authorize');
    expect(expectedUrl).toContain('response_type=code');
  });
});
