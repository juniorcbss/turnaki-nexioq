# Plan de Historias de Usuario y Backlog por Sprints
**Plataforma SaaS de Reserva de Citas Odontológicas — De la especificación a la ejecución**

---

## 1) Alcance y convenciones
**Base:** documento “Plataforma SaaS de Reserva de Citas Odontológicas — Especificación funcional y técnica (2025)”.  
**Objetivo:** transformar la especificación en **historias de usuario** accionables y un **backlog operativo por sprints** (MVP → MMP).  
**Convenciones:**
- **Prioridad:** P0 (crítico), P1 (alto), P2 (medio), P3 (bajo).  
- **Estimación:** *Story Points* (Fibonacci: 1,2,3,5,8,13).  
- **Definición de Hecho (DoD):** tests (unit+contract+e2e) en verde, logs/metricas/X-Ray, seguridad (scopes/ABAC), docs actualizadas, *feature flag* definido si aplica.  
- **Criterios:** estilo **Gherkin** (Dado/Cuando/Entonces).  
- **Dependencias:** `→` indica requisito previo.

---

## 2) Mapa de producto → Épicas
- **E1. Infra & Pipeline** (CDK, entornos, CI/CD).  
- **E2. Identidad** (Cognito: registro, login, MFA).  
- **E3. Tenancy** (alta de tenant, branding, sedes, TZ).  
- **E4. Catálogo & Recursos** (servicios, profesionales, recursos).  
- **E5. Motor de Reservas** (disponibilidad, reserva atómica, reprogramación/cancelación).  
- **E6. Portal Paciente (PWA)** (flujo 3 pasos + gestión de citas).  
- **E7. Back‑office Agenda** (vista recepcion, bloqueos, drag&drop).  
- **E8. Comunicaciones** (recordatorios email; luego SMS/WhatsApp).  
- **E9. Centro de Configuración (UI 100% configurable)** (versionado, borrador/publicación, simulador).  
- **E10. IAM en UI** (usuarios/roles/políticas, RBAC+ABAC, simulador).  
- **E11. Observabilidad & Seguridad** (WAF, CORS, métricas/alertas).  
- **E12. Pagos** (opcional).  
- **E13. Analítica & Reportes**.

---

## 3) Historias de usuario (detalle)

### E1. Infra & Pipeline
**US‑001 (P0, 8 SP)** — Como *devops* quiero **infra base con CDK** para desplegar Auth, API, Data, Frontend y Observability en *dev* para iterar rápido.  
**Criterios**  
Dado el *repo*, Cuando ejecuto `cdk deploy` en *dev* Entonces se crean recursos mínimos y *outputs* quedan documentados.  
**Deps:** —

**US‑002 (P0, 8 SP)** — Como *equipo* quiero **CI/CD** (GitHub Actions → CDK Pipelines) para *dev→stage→prod* con aprobaciones.  
**Criterios**  
Dado un *push* a `main`, Cuando corre el pipeline Entonces se ejecuta build/test/synth y despliega a dev; stage/prod requieren aprobación.  
**Deps:** US‑001

**US‑003 (P0, 5 SP)** — Como *equipo* quiero **observabilidad base** (logs estructurados, X‑Ray/ADOT, EMF, alarmas mínimas).  
**Criterios**  
Dado un fallo >1% 5min en un endpoint crítico, Cuando ocurre Entonces se dispara una alarma.

---

### E2. Identidad (Cognito)
**US‑010 (P0, 5 SP)** — Como *paciente* quiero **registro/login** (Hosted UI) para gestionar mis citas.  
**Criterios**  
Dado que no tengo cuenta, Cuando me registro Entonces recibo verificación email y puedo iniciar sesión.

**US‑011 (P0, 5 SP)** — Como *admin* quiero **roles básicos** (admin, odontólogo, recepción, paciente) para limitar acceso.  
**Criterios**  
Dado JWT con rol, Cuando accedo a recurso no permitido Entonces recibo 403.

---

### E3. Tenancy
**US‑020 (P0, 8 SP)** — Como *operador* quiero **crear tenant** con branding y políticas base.  
**Criterios**  
Dado payload válido, Cuando creo tenant Entonces persiste configuración inicial y queda accesible vía `GET /config/:tenantId` (ETag).

**US‑021 (P1, 5 SP)** — Como *admin* quiero **gestionar sedes y TZ** para operar por ubicación.  
**Criterios**  
Dado una sede con zona horaria, Cuando consulto disponibilidad Entonces los horarios se muestran en su TZ.

---

### E4. Catálogo & Recursos
**US‑030 (P0, 3 SP)** — Como *admin* quiero **crear tratamientos** con duración y buffers.  
**Criterios**  
Dado servicio 45m y buffer 10m, Cuando reservo Entonces el slot ocupa 55m totales.

**US‑031 (P0, 5 SP)** — Como *admin* quiero **registrar profesionales y recursos** (sillón, RX).  
**Criterios**  
Dado recurso no disponible, Cuando busco agenda Entonces no aparecen *slots*.

---

### E5. Motor de Reservas
**US‑040 (P0, 8 SP)** — Como *paciente* quiero **ver disponibilidad** por sede/profesional/recurso.  
**Criterios**  
Dado filtros válidos, Cuando llamo `/booking/availability` Entonces recibo *slots* ordenados y paginados (p95 < 300ms en dev).

**US‑041 (P0, 8 SP)** — Como *paciente* quiero **reservar de forma atómica** para evitar doble reserva.  
**Criterios**  
Dado slot libre, Cuando creo `/booking/reservations` Entonces la transacción usa `attribute_not_exists` y si hay doble clic responde 409 con alternativas.

**US‑042 (P0, 5 SP)** — Como *paciente* quiero **reprogramar/cancelar** según política del tenant.  
**Criterios**  
Dado ventana de cancelación 12h, Cuando cancelo a 2h Entonces recibo 422 con motivo.

---

### E6. Portal del Paciente (PWA)
**US‑050 (P0, 8 SP)** — Como *paciente* quiero **flujo 3 pasos** (servicio → fecha/hora → confirmación).  
**Criterios**  
Dado que elijo servicio, Cuando paso al calendario Entonces veo *slots* compatibles; al confirmar, recibo pantalla de éxito y email.

**US‑051 (P1, 5 SP)** — Como *paciente* quiero **gestionar mis citas** (ver/reprogramar/cancelar).  
**Criterios**  
Dado que tengo citas, Cuando abro “Mis citas” Entonces veo estados y acciones.

---

### E7. Back‑office Agenda
**US‑060 (P1, 8 SP)** — Como *recepción* quiero **agenda operativa** (día/semana, filtros, drag&drop con validación).  
**Criterios**  
Dado un movimiento, Cuando suelto la cita Entonces el backend valida conflictos (200/409).

**US‑061 (P1, 3 SP)** — Como *recepción* quiero **bloqueos** por mantenimiento/capacitación.  
**Criterios**  
Dado bloqueo, Cuando consulto disponibilidad Entonces esos *slots* no aparecen.

---

### E8. Comunicaciones
**US‑070 (P1, 5 SP)** — Como *paciente* quiero **recordatorios por email** T‑24h y T‑2h.  
**Criterios**  
Dado cita confirmada, Cuando llega T‑24h Entonces EventBridge Scheduler dispara Lambda → SES envía correo templado.

**US‑071 (P2, 5 SP)** — Como *tenant* quiero **SMS/WhatsApp** con opt‑in.  
**Criterios**  
Dado opt‑in válido, Cuando llega T‑2h Entonces envío por Pinpoint o *fallback* a email.

---

### E9. Centro de Configuración (UI 100% configurable)
**US‑080 (P0, 8 SP)** — Como *admin* quiero **editar configuración en borrador** por categorías, con validación.  
**Criterios**  
Dado cambios en “Políticas de reserva”, Cuando guardo borrador Entonces el sistema valida JSON Schema y reglas cruzadas.

**US‑081 (P1, 5 SP)** — Como *admin* quiero **publicar y versionar** con *rollback* y programación temporal.  
**Criterios**  
Dado versión v5, Cuando publico con `scheduleAt` Entonces entra en vigor a la hora fijada; puedo volver a v4 con un clic.

**US‑082 (P1, 5 SP)** — Como *admin* quiero **simular impacto en agenda** antes de publicar.  
**Criterios**  
Dado un borrador, Cuando simulo Entonces veo *diff* de slots por día.

---

### E10. IAM en UI (RBAC + ABAC)
**US‑090 (P0, 5 SP)** — Como *admin* quiero **invitar usuarios** y asignar roles/sedes.  
**Criterios**  
Dado email válido, Cuando invito Entonces el usuario recibe enlace y al aceptar queda con rol/sede asignados.

**US‑091 (P1, 8 SP)** — Como *admin* quiero **políticas y matriz de permisos** (editor visual y Cedar).  
**Criterios**  
Dado política Cedar, Cuando valido Entonces obtengo *lint* y tests; publicar crea versión trazable.

**US‑092 (P1, 5 SP)** — Como *auditor* quiero **simular decisión de acceso** (ALLOW/DENY) con explicación.  
**Criterios**  
Dado actor/acción/recurso, Cuando simulo Entonces obtengo resultado y *decisionId*.

---

### E11. Observabilidad & Seguridad
**US‑100 (P0, 3 SP)** — Como *plataforma* quiero **WAF + CORS** para proteger la API.  
**Criterios**  
Dado origen no permitido, Cuando llama Entonces responde 403.

**US‑101 (P0, 3 SP)** — Como *equipo* quiero **métricas y alertas** por endpoint/tenant.  
**Criterios**  
Dado p95 > umbral, Cuando persiste 5min Entonces alarma al canal de on‑call.

---

### E12. Pagos (opcional)
**US‑110 (P1, 8 SP)** — Como *tenant* quiero **adelantos con pasarela** (Stripe) antes de confirmar.  
**Criterios**  
Dado *payment intent* fallido, Cuando confirmo cita Entonces se cancela la reserva.

---

### E13. Analítica & Reportes
**US‑120 (P1, 5 SP)** — Como *manager* quiero **dashboard operacional** (ocupación, no‑show, lead time).  
**Criterios**  
Dado filtros por sede/profesional, Cuando consulto Entonces veo KPIs y export CSV.

---

## 4) Backlog operativo por sprints (MVP → MMP)
**Ritmo:** sprints de 2 semanas. Capacidad de referencia: 30–34 SP/sprint (equipo 4–5 devs).  
**Entornos:** *dev* (siempre verde), *stage* (UAT), *prod* (cadencia al cierre de MVP y luego bisemanal).

### Sprint 0 — Fundaciones (28–32 SP)
- US‑001 (8) Infra base CDK  
- US‑003 (5) Observabilidad base  
- US‑100 (3) WAF + CORS  
- US‑101 (3) Métricas/alertas  
- US‑002 (8) CI/CD (pipeline)  
**Objetivo:** repos, despliegue *dev*, seguridad mínima y visibilidad.  
**Entregables:** *repo* monorepo, `README`, *pipelines* operativos, alarmas básicas.

### Sprint 1 — Identidad, Tenancy y Catálogo (31–33 SP)
- US‑010 (5) Registro/Login  
- US‑011 (5) Roles básicos  
- US‑020 (8) Alta tenant  
- US‑021 (5) Sedes/TZ  
- US‑030 (3) Servicios (tratamientos)  
- US‑031 (5) Profesionales/recursos  
**Objetivo:** entrar al sistema, crear tenant/sedes, definir servicios y recursos.  
**Entregables:** demo con tenant funcional y datos base.

### Sprint 2 — Motor de Reservas y PWA (30–34 SP)
- US‑040 (8) Disponibilidad  
- US‑041 (8) Reserva atómica  
- US‑042 (5) Reprogramar/Cancelar  
- US‑050 (8) Flujo PWA 3 pasos  
**Objetivo:** reservas end‑to‑end desde el portal paciente.  
**Entregables:** e2e Playwright “buscar→reservar→confirmar→cancelar”.

### Sprint 3 — Back‑office, Comunicaciones y Config (31–34 SP)
- US‑060 (8) Agenda operativa  
- US‑061 (3) Bloqueos  
- US‑070 (5) Recordatorios email  
- US‑080 (8) Configuración en borrador  
- US‑082 (5) Simulador de agenda  
**Objetivo:** operación diaria en recepción y comunicaciones mínimas.  
**Entregables:** vista agenda día/semana, emails T‑24/T‑2, centro de configuración (borrador + simulación).

### Sprint 4 — Publicación de Config y Hardening IAM (30–33 SP) ★ **Cierre MVP**
- US‑081 (5) Publicación/versionado/rollback  
- US‑090 (5) Invitaciones y asignaciones  
- US‑091 (8) Matriz/Políticas (editor + Cedar)  
- US‑092 (5) Simulador de acceso  
- Endurecimiento de *scopes* JWT en endpoints (tarea técnica, 5)  
**Objetivo:** control total desde UI (config + IAM) y seguridad madura.  
**Entregables:** *release* MVP en *prod*, *runbook*, checklist de *go‑live*.

### Sprint 5 — MMP Early (30–34 SP)
- US‑071 (5) SMS/WhatsApp (opt‑in, quiet hours)  
- US‑110 (8) Pagos/adelantos (Stripe)  
- US‑120 (5) Dashboard operacional  
- Endpoints de export CSV (tarea técnica, 3)  
- Mejoras UX PWA (accesibilidad, 5)  
- Optimización disponibilidad (caché selectiva, 5)  
**Objetivo:** valor incremental (mensajería multicanal, cobros, KPIs).  
**Entregables:** tablero básico y flujos de cobro controlados por *feature flag*.

### Sprint 6 — MMP Plus (30–32 SP)
- Dominio por tenant y SSL (tarea técnica, 5)  
- iCal suscripción (historia nueva, 5)  
- Formularios/consentimientos (historia nueva, 8)  
- SLOs y auto‑remediación (historia nueva, 8)  
- *Hardening* costos (alertas de gasto, 3)  
**Objetivo:** experiencia pulida y operativa avanzada.  
**Entregables:** dominios dedicados, iCal, SLOs iniciales.

---

## 5) Matriz de trazabilidad (módulo ↔ historias)
| Módulo | Historias |
|---|---|
| Infra & Pipeline | US‑001, US‑002, US‑003 |
| Identidad | US‑010, US‑011 |
| Tenancy | US‑020, US‑021 |
| Catálogo & Recursos | US‑030, US‑031 |
| Motor de Reservas | US‑040, US‑041, US‑042 |
| Portal Paciente | US‑050, US‑051 |
| Back‑office | US‑060, US‑061 |
| Comunicaciones | US‑070, US‑071 |
| Configuración | US‑080, US‑081, US‑082 |
| IAM UI | US‑090, US‑091, US‑092 |
| Seguridad/Obs | US‑100, US‑101 |
| Pagos | US‑110 |
| Analítica | US‑120 |

---

## 6) Criterios de aceptación extendidos (muestras)
**US‑041 Reserva atómica**  
- Dado que dos clientes intentan reservar el mismo slot, Cuando el segundo confirma Entonces recibe 409 y sugerencias ±30min.  
- Dado que falla la transacción, Cuando se reintenta con *idempotency key* Entonces el resultado es consistente.  

**US‑081 Publicación/rollback**  
- Dado una versión programada, Cuando llega `scheduleAt` Entonces el *event* `ConfigChanged` se emite y se invalidan cachés.  
- Dado un problema post‑publicación, Cuando hago *rollback* Entonces reaparece la versión previa en ≤1 min.

**US‑091 Políticas Cedar**  
- Dado una política con error, Cuando valido Entonces obtengo explicación de la regla fallida y línea.  
- Dado una política publicada, Cuando audito Entonces puedo ver *decision logs* filtrando por actor/acción.

---

## 7) Riesgos y mitigaciones (top‑5)
1. **Cold‑starts** en horas pico → *provisioned concurrency* selectiva y binarios optimizados.  
2. **Conflictos de agenda** por reglas complejas → simulador y *feature flags* para rollout gradual.  
3. **Entrega de comunicaciones** (spam) → DKIM/DMARC, *fallback* y *suppression list* gestionada.  
4. **Curva de aprendizaje IAM** → editor visual, plantillas de roles y simulador guiado.  
5. **Costos inesperados** → alarmas de gasto, límites de *throughput* y *budget alerts*.

---

## 8) Plan de pruebas
- **Unitarias (Rust/Svelte):** cobertura mínima 70% en módulos críticos.  
- **Contract (Pact):** endpoints `/booking/*`, `/config/*`, `/iam/*`.  
- **e2e (Playwright):** flujos paciente (buscar→reservar→recordatorio→cancelar) y back‑office (mover cita, bloqueo).  
- **Carga (k6):** 200 RPS en disponibilidad, 20 RPS en confirmación con p95 < 400ms en *stage*.  
- **Seguridad:** pruebas de *scopes* JWT y ABAC (Cedar) en rutas sensibles.

---

## 9) Cierres y entregables por fase
- **MVP:** sprints 0–4, *runbook*, checklist *go‑live*, monitoreo 24/7 básico.  
- **MMP Early:** sprint 5, multicanal + pagos + KPIs.  
- **MMP Plus:** sprint 6, dominios por tenant, iCal, SLOs, consentimientos.

---

## 10) Anexos rápidos
- **Glosario:** slot, buffer, no‑show, *quiet hours*, ABAC, Cedar, OAC.  
- **Formato de historia:** *Como [rol] quiero [capacidad] para [beneficio]* + Gherkin + SP + Deps + DoD.  
- **Política de *feature flags*:** *release* oscuro → beta limitada → GA por tenant/sede/rol.

