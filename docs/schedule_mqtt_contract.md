# MQTT Schedule Communication Contract (Server ↔ Phone ↔ Master)

This document defines the interface contract for managing and synchronizing weekly repeating schedules between the **Flutter Mobile App**, the **Backend Server**, and the **Master Devices** (Classrooms).

---

## 1. Topic Hierarchy & Payload Schemas

### 1.1 Weekly Schedule Configuration (Sync & State)
This topic acts as the shared weekly schedule database between the Phone App and the Backend Server.

* **Topic:** `binus/ayam/<classroom_name>/data/schedule` (e.g., `binus/ayam/HD01/data/schedule`)
* **QoS:** 1 (At least once)
* **Retain:** `true` (Enabled)
* **Publisher:** Phone App (upon user configuration changes) or Server (upon database updates)
* **Subscriber:** Phone App, Backend Server
* **Payload Format:** Plain text string consisting of 7 semicolon-separated daily bitmasks representing Monday to Sunday.
  - **Syntax:** `"<Mon>;<Tue>;<Wed>;<Thu>;<Fri>;<Sat>;<Sun>"`
  - **Daily Bitmask:** A string of up to 6 binary digits (`'1'` = active session, `'0'` = inactive session). Single days with no classes can be written as `"0"`.
  - **Example Payload:** `"100110;111000;0;0;0;0;0"`
    * **Monday:** `100110` (Sessions 1 and 4 are ON; Sessions 2, 3, 5, 6 are OFF)
    * **Tuesday:** `111000` (Sessions 1, 2, and 3 are ON; Sessions 4, 5, 6 are OFF)
    * **Wednesday - Sunday:** `0` (No sessions scheduled)

---

### 1.2 Daily Schedule Command (Master Control)
This topic is used by the Server to push today's running schedule or specific trigger commands directly to the Master Device.

* **Topic:** `binus/ayam/<classroom_name>/control/schedule` (e.g., `binus/ayam/HD01/control/schedule`)
* **QoS:** 1 (At least once)
* **Retain:** `false` (Disabled)
* **Publisher:** Backend Server
* **Subscriber:** Master Device
* **Payload Format:** Plain text string.
  - **Daily Bitmask:** Right-aligned representation of today's schedule sessions.
    * `"100000"` (Session 1 is active today)
    * `"10"` (Session 5 is active today)
    * `"1"` (Session 6 is active today)
    * `"0"` (No sessions active today)
  - **Event Commands:**
    * `PRE_CLASS_ON`: Trigger class warm-up manually
    * `CLASS_ENDED`: Explicitly end class sessions for the day

---

## 2. Synchronization & Workflow Rules

### 2.1 Synchronization Flow (Phone ↔ Server)
```txt
   Flutter App (Phone)                                 Backend Server
         │                                                   │
         │ (1) Publish new weekly schedule                   │
         ├──────────────────────────────────────────────────>│ (2) Receives retained message
         │     Topic: binus/ayam/HD01/data/schedule          │     and updates internal DB.
         │     Payload: "100110;111000;0;0;0;0;0"            │
         │                                                   │
         │ (4) Receives updated schedule config              │ (3) Server updates database
         │<──────────────────────────────────────────────────┤     directly and publishes
         │     Topic: binus/ayam/HD01/data/schedule          │     retained state confirmation.
```

1. **Broker-As-Database:** The MQTT broker stores the latest configuration for each room as a **Retained Message** on the `data/schedule` topic.
2. **On Startup:** 
   - The Flutter App subscribes to `binus/ayam/+/data/schedule` to load the current schedule layout of all classrooms instantly.
   - The Server subscribes to the same wildcard topic to keep its in-memory schedules populated.
3. **On Modification:**
   - Any modifications made on the phone are published with the `retain` flag set to `true`.
   - The Server receives the message, writes it to its database, and updates its scheduling timers.

---

## 3. Daily Execution Cron (Server ↔ Master)

Because the Master Device does not track date parameters, the **Backend Server** acts as the clock provider.

```txt
  At 12:00 AM (Midnight)
  ┌─────────────────────────────────────────────────────────────┐
  │ 1. Server gets current day of the week (e.g., "Tuesday").    │
  │ 2. Server extracts Tuesday's bitmask from stored schedule.  │
  │ 3. Server publishes bitmask to control topic:               │
  │    binus/ayam/HD01/control/schedule -> "111000" (retain=off)│
  └─────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌──────────────────────────┐
                    │ Master Device (HD01)     │
                    │ Clears volatile memory & │
                    │ runs Tuesday's schedule  │
                    └──────────────────────────┘
```

1. Every day at **12:00 AM (midnight)**, the Server triggers a cron job.
2. The Server extracts the daily segment matching the current day of the week from the weekly schedule.
3. The Server publishes the extracted daily bitmask to `binus/ayam/<room>/control/schedule`.
4. The Master Device receives the daily bitmask and updates its daily operations checklist.
