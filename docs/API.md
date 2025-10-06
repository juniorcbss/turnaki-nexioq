# 📡 Especificación de API

**Base URL**: `https://x292iexx8a.execute-api.us-east-1.amazonaws.com`

---

## Autenticación

Todos los endpoints (excepto `/health`) requieren un JWT token de Cognito.

```http
Authorization: Bearer <jwt_token>
```

---

## Endpoints

### Health

#### GET /health

Health check público.

**Request**:
```bash
curl https://api.turnaki.com/health
```

**Response** `200 OK`:
```json
{
  "service": "health",
  "status": "ok",
  "timestamp": "2025-10-06T12:00:00Z"
}
```

---

### Availability

#### POST /booking/availability

Consultar disponibilidad de slots.

**Request**:
```json
{
  "site_id": "site-1",
  "professional_id": "prof-1",
  "treatment_id": "treat-1",
  "start_date": "2025-10-10",
  "end_date": "2025-10-17"
}
```

**Response** `200 OK`:
```json
{
  "slots": [
    {
      "slot_id": "slot-20251010-0900",
      "date": "2025-10-10",
      "start_time": "09:00",
      "end_time": "09:30",
      "professional_id": "prof-1",
      "available": true
    }
  ],
  "total": 42
}
```

---

### Bookings

#### POST /bookings

Crear una reserva.

**Request**:
```json
{
  "tenant_id": "site-1",
  "patient_id": "patient-123",
  "professional_id": "prof-1",
  "treatment_id": "treat-1",
  "slot_id": "slot-20251010-0900",
  "date_time": "2025-10-10T09:00:00Z",
  "patient_name": "Juan Pérez",
  "patient_email": "juan@example.com"
}
```

**Response** `201 Created`:
```json
{
  "booking_id": "booking-abc123",
  "status": "confirmed",
  "confirmation_code": "ABC123"
}
```

**Errores**:
- `400 Bad Request`: Datos inválidos
- `409 Conflict`: Slot ya reservado
- `422 Unprocessable Entity`: Horario no disponible

#### GET /bookings

Listar reservas.

**Query Params**:
- `tenant_id` (required)
- `patient_id` (optional)
- `status` (optional): confirmed, cancelled
- `from_date` (optional)
- `to_date` (optional)

**Response** `200 OK`:
```json
{
  "bookings": [
    {
      "booking_id": "booking-abc123",
      "patient_name": "Juan Pérez",
      "treatment_name": "Limpieza Dental",
      "professional_name": "Dr. Smith",
      "date_time": "2025-10-10T09:00:00Z",
      "status": "confirmed"
    }
  ],
  "count": 1
}
```

#### DELETE /bookings/{id}

Cancelar una reserva.

**Response** `200 OK`:
```json
{
  "message": "Booking cancelled successfully",
  "booking_id": "booking-abc123"
}
```

---

### Tenants

#### GET /tenants

Listar clínicas/tenants.

**Response** `200 OK`:
```json
{
  "tenants": [
    {
      "tenant_id": "site-1",
      "name": "Clínica Dental ABC",
      "email": "info@abc.com",
      "phone": "+593 99 123 4567"
    }
  ]
}
```

#### POST /tenants

Crear tenant (requiere rol Owner).

**Request**:
```json
{
  "name": "Clínica Dental ABC",
  "email": "info@abc.com",
  "phone": "+593 99 123 4567",
  "address": "Av. Principal 123"
}
```

---

### Treatments

#### GET /treatments

Listar tratamientos.

**Query Params**:
- `tenant_id` (required)

**Response** `200 OK`:
```json
{
  "treatments": [
    {
      "treatment_id": "treat-1",
      "name": "Limpieza Dental",
      "duration_minutes": 30,
      "price": 50.00,
      "currency": "USD"
    }
  ]
}
```

---

### Professionals

#### GET /professionals

Listar profesionales.

**Query Params**:
- `tenant_id` (required)
- `specialty` (optional)

**Response** `200 OK`:
```json
{
  "professionals": [
    {
      "professional_id": "prof-1",
      "name": "Dr. John Smith",
      "specialty": "Odontología General",
      "email": "jsmith@example.com"
    }
  ]
}
```

---

## Códigos de Error

| Código | Descripción |
|--------|-------------|
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Token inválido o expirado |
| 403 | Forbidden - Sin permisos |
| 404 | Not Found - Recurso no encontrado |
| 409 | Conflict - Conflicto (ej: slot ya reservado) |
| 422 | Unprocessable Entity - Validación fallida |
| 500 | Internal Server Error - Error del servidor |

---

**Última actualización**: Octubre 2025
