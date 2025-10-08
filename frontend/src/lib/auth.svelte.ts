interface User {
  email: string;
  name?: string;
  groups?: string[];
  tenant_id?: string;
}

import { COGNITO } from '../config.js';

class AuthStore {
  user = $state<User | null>(null);
  token = $state<string | null>(null);

  constructor() {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('tk_nq_token');
      if (token) {
        this.token = token;
        this.loadUser(token);
      }
    }
  }

  async loadUser(token: string) {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      this.user = {
        email: payload.email,
        name: payload.name,
        groups: payload['cognito:groups'] || [],
        tenant_id: payload.tenant_id || payload['custom:tenant_id']
      };
    } catch (e) {
      this.logout();
    }
  }

  login() {
    const url = `${COGNITO.domain}/oauth2/authorize?client_id=${COGNITO.clientId}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(COGNITO.redirectUri)}`;
    window.location.assign(url);
  }

  logout() {
    this.user = null;
    this.token = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('tk_nq_token');
    }
  }

  setToken(token: string) {
    this.token = token;
    if (typeof window !== 'undefined') {
      localStorage.setItem('tk_nq_token', token);
    }
    this.loadUser(token);
  }

  get isAuthenticated() {
    return this.user !== null && this.token !== null;
  }
}

export const authStore = new AuthStore();
