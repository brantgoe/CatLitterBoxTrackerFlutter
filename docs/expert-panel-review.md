# Expert panel review

A structured architectural critique of the Cat Litter Box Tracker project (tablet
app + companion app + sync protocol) as of the troubleshooting-docs commit on
the companion repo. The "experts" below are focused critical lenses — not real
people — used to surface issues that any single viewpoint tends to miss.

## The lenses

- **Distributed Systems** — sync protocol, conflict resolution, consistency guarantees
- **Mobile / Flutter architecture** — code structure, state management, package boundaries
- **Android Platform** — battery, background execution, permissions, real-device behavior
- **Security & Privacy** — threat model, auth, transport, data exposure
- **Product / UX** — onboarding, error states, multi-device flows

---

## Opening statements

### Distributed Systems

> The protocol works on paper for the happy path but assumes too much about the
> network and too little about the clocks. Three serious concerns:
>
> 1. **Integer auto-increment IDs are shared across devices.** Master assigns
>    them, clients receive them via snapshot, but the moment a client creates
>    a new entity locally before the next broadcast lands, two clients can pick
>    the same `id`. LWW won't save you — the second insert is rejected because
>    `existing.updatedAt >= remote.updatedAt` is true, and the user's tap
>    silently vanishes. The fix is a UUID `syncId` column as the cross-device
>    identifier, with the integer `id` kept as a local foreign-key target.
> 2. **Deletes have no tombstones.** A client that's offline during a delete
>    will never see it — the next snapshot replaces local state, so the delete
>    eventually propagates, but only after a full reconnect. A delete that
>    arrives concurrent with an update has undefined precedence. For a
>    litter-box app this is fine 99% of the time; you should know it isn't
>    actually correct.
> 3. **LWW uses each device's wall clock.** The protocol's `welcome.serverTime`
>    field exists but is never used. Two clocks 30 seconds apart will cause
>    spurious "newer wins" decisions. Use a single Lamport-style counter
>    maintained by the master, or at minimum capture clock skew on each connect
>    and offset client timestamps before sending.

### Mobile / Flutter architecture

> The biggest issue is **the tablet and companion repos share a wire protocol
> by copy-paste**. The moment you bump `protocolVersion` you have to edit two
> places, build two APKs, and pray no one runs a stale companion. Extract a
> shared `cat_litter_protocol` Dart package, depended on by both. Either
> path-based (works for local dev) or published to a private pub server.
>
> Other things:
> - The `Repository` does the outbox emission *after* the DB write but in the
>   same async function. If the process dies between, you've lost the sync
>   event. You want a transactional outbox: write the change and an outbox row
>   in the same drift transaction; a background task drains the outbox to the
>   network. That gives you crash safety and lets you handle the "device was
>   killed while a message was in flight" case.
> - **Wire format and ORM are the same type.**
>   `EntityCodec.roomToJson(BoxRoom)` serializes drift's data class directly.
>   Add a new column to the DB and your wire format changes without you
>   thinking about it. The right thing is a DTO layer between drift and JSON,
>   even though it's a few more files.
> - **Zero tests on the sync applier.** The piece of code most likely to
>   silently corrupt state has no coverage at all.

### Android Platform

> On Android I see two real failure modes that will bite users:
>
> 1. **WorkManager's minimum periodic interval is 15 minutes**, and Android
>    frequently extends that under Doze and App Standby Buckets. Your
>    "cleaning is due" notification could be delayed an hour or more in
>    practice. For the use case ("the litter box is overflowing") that's fine;
>    for anything more time-sensitive you need a real foreground service. The
>    current docs in the companion suggest near-real-time, which they aren't.
> 2. **`usesCleartextTraffic=true` and no network security config.** It works
>    today but Android keeps tightening this — Play Store warnings are likely
>    in the next year or two even for local IPs. Add a `network_security_config.xml`
>    that whitelists `192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`, and
>    `*.local` instead of the global cleartext allow.
>
> Also: the master starts on `InternetAddress.anyIPv4` but the app has no
> foreground service. When the user backgrounds the tablet, Android will
> eventually kill the master process and clients silently lose sync. Master
> mode needs a foreground service to keep the server alive.

### Security & Privacy

> Let's name the threat model: anyone on your home Wi-Fi can connect to the
> master and:
>
> - Receive a full snapshot of who's home, when they cleaned what, room layouts.
> - Send fabricated cleaning events, fabricate maintenance state, delete entities.
>
> For most homes this is fine. For shared Wi-Fi (apartments, dorms, guest
> networks), it isn't. At minimum, **a shared secret token in `hello`**, set
> during master setup, displayed once on the master screen, entered or
> QR-scanned on the client. The master refuses connections without the matching
> token. This is ten lines on each side and you sleep better.
>
> Cleartext is also a real concern. Anyone with packet capture (a roommate, a
> malicious smart-bulb on your VLAN) can read everything. WSS with a self-signed
> cert plus cert-pinning the master's certificate at first pair gives you real
> transport security with no PKI.

### Product / UX

> Two things that will frustrate real users:
>
> 1. **Switching to client mode wipes local data with one confirmation dialog
>    and no preview.** If someone accidentally taps client without configuring
>    the host, or enters the wrong IP, their data is gone. The wipe should
>    happen on the first successful snapshot, not on the role switch. If the
>    connection fails, no data is destroyed. And the dialog should say
>    something specific like "you currently have 2 rooms and 4 boxes that will
>    be replaced."
> 2. **The tablet's master/client/standalone toggle is a global mode** but the
>    actual user mental model is per-room. People naturally think "this tablet
>    is for the upstairs bathroom" — they don't think "this tablet is a client
>    that owns the Upstairs room." The setting needs to walk them through
>    pairing a room, not picking a role.
>
> The companion has the opposite problem: it's read-only for now, but most
> users will eventually expect to log a cleaning from their phone. The
> protocol already supports it (mutations flow client → master). The companion
> just doesn't surface a "Log cleaning" button. Plan for that or explicitly
> decide against it.

---

## Where they push back on each other

### Mobile vs Distributed Systems on the UUID question

> **Mobile**: "Adding `syncId` is a schema migration that breaks compatibility.
> We have two installed apps and we just shipped v1. We'd need a versioned
> migration on both sides."
>
> **Distributed Systems**: "Yes, and it's still the right fix. The longer you
> defer it, the worse the migration gets, and you'll hit real ID collisions
> the first time you have two phones logging cleanings on the same shared box.
> The pain is unavoidable; the question is whether you take it at 2 users or
> 200."
>
> **Consensus**: Do it now. Add `syncId TEXT` to all four tables. Server
> resolves entity identity by `syncId`; integer `id` is local-only. Migration
> generates UUIDs for existing rows.

### Android vs Security on transport

> **Android**: "WSS with self-signed certs is a maintenance burden. Users will
> hit cert expiry and won't know how to fix it."
>
> **Security**: "Then issue a 100-year cert at pairing time. The cert is
> generated by the master, pinned by the client at first sight, and lives in
> the device's keystore. Users don't see it ever."
>
> **Consensus**: Plain cleartext is fine for v1 in an isolated home network;
> add WSS+pinning when you ship the shared-secret token in the same release.

### UX vs Product on the master/client mode

> **UX**: "The role toggle is the simplest possible model. Three buttons. Users
> understand it."
>
> **Product**: "They understand the *buttons*. They don't understand the
> consequences. They tap client to try it out, lose their data, and uninstall."
>
> **Consensus**: Keep the three-mode toggle internally; rebrand the
> user-facing flow as "this tablet is..." → "...alone" / "...sharing with
> other tablets" / "...joining a shared setup." Don't destroy data on role
> change; defer destruction to first successful snapshot.

---

## Prioritized fix list

| Priority | Fix | Cost | Why now |
|---|---|---|---|
| **P0** | Add `syncId` UUID column to all entities; sync messages reference syncId; integer IDs become local-only | ~3h | Future-proofs the data model; harder the longer you wait. Required before adding any new client. |
| **P0** | Defer client-mode data wipe until *after* the snapshot arrives | ~30m | Prevents silent data loss from misconfiguration. |
| **P0** | Move the protocol files into a shared `cat_litter_protocol` Dart package | ~1h | Stops the two repos from drifting. |
| **P1** | Shared-secret token in `hello`, set on master, entered/QR-scanned on client | ~2h | Cheap auth; removes the "anyone on Wi-Fi can write" hole. |
| **P1** | Foreground service for master mode; persistent notification | ~2h | Otherwise master silently dies when the tablet is backgrounded. |
| **P1** | Persist the companion's `_lastState` so notifications don't re-fire on relaunch | ~30m | Direct user pain. |
| **P1** | Transactional outbox table in tablet repo; sync engine drains it instead of subscribing to in-memory stream | ~3h | Survives process kill; the only way the sync protocol is actually reliable. |
| **P2** | `network_security_config.xml` whitelisting local CIDRs instead of global `usesCleartextTraffic` | ~30m | Defensive; future-proofs against Android tightening. |
| **P2** | DTO layer between drift entities and JSON wire format | ~2h | Prevents DB schema changes silently breaking the wire protocol. |
| **P2** | Adopt server-time-based clock for LWW using the existing `welcome.serverTime` field | ~1h | Removes clock-skew correctness bugs. |
| **P2** | Tests for `SyncApplier` covering upsert LWW, delete, and snapshot replace edge cases | ~2h | The riskiest code with zero coverage. |
| **P3** | mDNS discovery (both sides) — the auto-pair we already documented | ~3h | UX win; user no longer types IPs. |
| **P3** | WSS + cert pinning generated at pairing | ~3h | Real transport security. Pair with P1 shared-secret. |
| **P3** | "Sharing with other tablets" wording in the role picker; deferred-destruction wipe | ~1h | Aligns UI with the mental model the actual users have. |
| **P3** | Companion can log a cleaning back to the master | ~2h | Closes the obvious phone use case. |

---

## Strong recommendation

The next three commits, before any new features:

1. `syncId`
2. transactional outbox
3. master foreground service

Those are the three places where the current code is structurally wrong rather
than just incomplete. Everything else is additive and can ship later without
rework.
