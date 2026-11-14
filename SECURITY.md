# Basha Bodol – security notes

## What was wrong (original code)
| # | Issue | Severity |
|---|-------|----------|
| 1 | No authentication on any API route – anyone could call `/api/admin/*`, read all users (including **bcrypt password hashes**) and delete users/houses | Critical |
| 2 | `/api/admin/delete` interpolated `req.body.table` into SQL → SQL injection | Critical |
| 3 | Identity trusted from the client (`user_id`, `owner_id` in the body/URL, `localStorage`) → anyone could act as, or read data of, any user (IDOR) | Critical |
| 4 | `user_type` accepted from the client → self-register as `admin` | Critical |
| 5 | Stored XSS: titles, comments, names rendered with `innerHTML` | High |
| 6 | Any logged-in (or anonymous) user could accept/reject any visit or booking | High |
| 7 | CSP disabled, CORS `*`, DB errors (`err.message`) returned to the browser | Medium |
| 8 | No password rules, no login brute-force protection, user enumeration ("User not found") | Medium |
| 9 | `.env` (DB credentials) shipped inside the zip; DB user is `root` | High |

## What changed
* **Auth**: HMAC-signed session in an `HttpOnly`, `SameSite=Strict`, (`Secure`/`__Host-` in production) cookie. User/role is re-read from the DB on every request, so deleting a user or changing role takes effect immediately.
* **RBAC + ownership**: every route declares its role; owners/providers can only touch their own rows (enforced inside the SQL `WHERE`). Identity always comes from the session.
* **Admin**: whitelisted tables, no password hashes returned, cannot delete yourself or other admins.
* **Validation** on every input (types, lengths, ranges, dates, BD phone, email, password policy); status values are enum-checked; booking status moves one legal step at a time.
* **Login**: bcrypt cost 12, constant-time dummy compare, identical error for unknown user / bad password, 8-failure limiter per IP+email, register limiter, global API limiter.
* **CSRF**: SameSite=Strict + required `X-Requested-With` header + Origin check.
* **Headers**: strict CSP (`script-src 'self'`, no inline script/style), HSTS in production, nosniff, frame-ancestors none, Permissions-Policy, `no-store` on API.
* **Errors**: generic messages for 5xx, details only in server logs.
* **Frontend**: all dynamic text escaped, no inline handlers, no `localStorage` identity, `alert/prompt` replaced by accessible dialogs.
* 12 automated tests: `npm test` (use an in-memory fake DB – no MySQL needed).

## You must do (cannot be done in code)
1. **Rotate the DB password** – your `.env` was in the zip you shared. Never commit/share it (`.gitignore` added).
2. Create a non-root DB user (see `security_migration.sql`), then run that file once.
3. Set `NODE_ENV=production`, a real `SESSION_SECRET` (`.env.example`), serve over HTTPS, and `TRUST_PROXY=1` behind a proxy.
4. Create your admin with `npm run create-admin -- "Name" you@mail.com 01XXXXXXXXX 'StrongPass1'`.
5. Run `npm audit` periodically.

## Behaviour changes to know about
* Visit requests: **tenant** accounts only; listings: **owner** only; provider profile: **provider** only.
* New endpoints: `GET /api/visits/incoming|mine`, `GET /api/houses/mine`, `DELETE /api/houses/:id`, `GET /api/services/my-bookings`, `GET /api/auth/me`, `POST /api/auth/logout`.
* New page: `my_requests.html` (tenant). Passwords now need 8+ chars with a letter and a number (existing users are unaffected).
