import { authStore } from './auth.svelte';

class ApiClient {
  private baseUrl = import.meta.env.VITE_API_BASE || '';

  private async fetch<T>(path: string, options?: RequestInit): Promise<T> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options?.headers as Record<string, string>)
    };

    if (authStore.token) {
      headers['Authorization'] = `Bearer ${authStore.token}`;
    }

    const res = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers
    });

    if (res.status === 401) {
      authStore.logout();
      throw new Error('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    if (!res.ok) {
      const error = await res.json().catch(() => ({ error: res.statusText }));
      throw new Error(error.error || res.statusText);
    }

    return res.json();
  }

  // Health
  health = () => this.fetch<{ status: string; service: string }>('/health');

  // Tenants
  createTenant = (data: { name: string; contact_email: string; timezone?: string }) =>
    this.fetch('/tenants', { method: 'POST', body: JSON.stringify(data) });

  getTenant = (id: string) => this.fetch(`/tenants/${id}`);

  // Treatments
  createTreatment = (data: {
    tenant_id: string;
    name: string;
    duration_minutes: number;
    buffer_minutes?: number;
    price?: number;
  }) => this.fetch('/treatments', { method: 'POST', body: JSON.stringify(data) });

  listTreatments = (tenantId: string) =>
    this.fetch<{ treatments: any[]; count: number }>(`/treatments?tenant_id=${tenantId}`);

  // Bookings
  createBooking = (data: {
    tenant_id: string;
    site_id: string;
    professional_id: string;
    treatment_id: string;
    start_time: string;
    patient_name: string;
    patient_email: string;
  }) => this.fetch('/bookings', { method: 'POST', body: JSON.stringify(data) });

  listBookings = (tenantId: string) =>
    this.fetch<{ bookings: any[]; count: number }>(`/bookings?tenant_id=${tenantId}`);

  cancelBooking = (bookingId: string) =>
    this.fetch(`/bookings/${bookingId}`, { method: 'DELETE' });

  rescheduleBooking = (bookingId: string, newStartTime: string) =>
    this.fetch(`/bookings/${bookingId}`, {
      method: 'PUT',
      body: JSON.stringify({ start_time: newStartTime })
    });

  // Availability
  getAvailability = (data: { site_id: string; professional_id?: string; date?: string }) =>
    this.fetch('/booking/availability', { method: 'POST', body: JSON.stringify(data) });

  // Generic methods
  get = <T = any>(path: string) => this.fetch<T>(path);
  post = <T = any>(path: string, data?: any) =>
    this.fetch<T>(path, { method: 'POST', body: data ? JSON.stringify(data) : undefined });
  put = <T = any>(path: string, data?: any) =>
    this.fetch<T>(path, { method: 'PUT', body: data ? JSON.stringify(data) : undefined });
  delete = <T = any>(path: string) =>
    this.fetch<T>(path, { method: 'DELETE' });
}

export const api = new ApiClient();
export const apiClient = api;

