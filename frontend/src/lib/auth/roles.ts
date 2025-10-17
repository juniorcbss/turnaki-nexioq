export type AppRole = 'Admin' | 'Owner' | 'Recepción' | 'Odontólogo' | 'Paciente';

export interface AppUser {
  email: string;
  name?: string;
  groups?: string[];
  tenant_id?: string;
}

export function hasRole(user: AppUser | null | undefined, required: AppRole | AppRole[]): boolean {
  if (!user || !user.groups) return false;
  const requiredRoles = Array.isArray(required) ? required : [required];
  return requiredRoles.some(r => user.groups?.includes(r));
}

export function requireRole(user: AppUser | null | undefined, required: AppRole | AppRole[]): { allowed: boolean; reason?: string } {
  const allowed = hasRole(user, required);
  return allowed ? { allowed } : { allowed: false, reason: 'not_authorized' };
}
