interface User {
  email: string;
  name?: string;
  groups?: string[];
}

const COGNITO_DOMAIN = import.meta.env.VITE_COGNITO_DOMAIN;
const CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID;
const REDIRECT_URI = import.meta.env.VITE_REDIRECT_URI || 'http://localhost:5173/auth/callback';

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
        groups: payload['cognito:groups'] || []
      };
    } catch (e) {
      this.logout();
    }
  }

  login() {
    const url = `${COGNITO_DOMAIN}/oauth2/authorize?client_id=${CLIENT_ID}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;
    window.location.href = url;
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
