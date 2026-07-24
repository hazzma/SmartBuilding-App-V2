# SmartBuild V2 App Implementation Status

## Done

- Simplified 3-tab app shell: Home, Devices, Settings.
- Home combines room selector, sensor summary, sensor graph, and allowed controls.
- Devices contains MQTT master discovery, show-in-home toggle, display/room naming, sensor/control visibility config, master detail advanced, and debug advanced.
- Settings contains global MQTT broker/topic configuration and connection actions.
- MQTT config input for host, port, username, password, state topic, command topic template, and publish interval.
- MQTT config persistence with local preferences.
- Per-master Home display config persistence with local preferences.
- MQTT adapter for connect, wildcard subscribe, disconnect, and JSON publish.
- Master registry from incoming state payload.
- Active master selection.
- Stale/offline detection from publish interval.
- Payload parsing for network, slaves, sensor data, AC, projector, and light channels.
- Sensor invalid value handling for `null` and `-100`.
- Command builders with unique `command_id` and explicit final states.
- Main controls locked when MQTT is offline or selected master is stale.
- Debug information is nested under Devices advanced instead of main navigation.
- Sample state injection for UI testing without broker.
- Android internet permission for MQTT.
- Unit/widget tests for shell, parser, and command JSON.

## Needs Real Device/Broker Validation

- Confirm exact master JSON payload keys against firmware output.
- Confirm command JSON shape expected by firmware.
- Confirm MQTT broker authentication and topic naming convention.
- Confirm publish interval from firmware so stale threshold is accurate.
- Confirm Android device can reach broker IP/host on the same network.

## Useful Next Work

- Add real connection error UI toast/snackbar.
- Add command pending state until the next state publish confirms it.
- Add import/export config JSON for debug.
- Add richer slave detail/debug register view after register map is finalized.
- Add integration test with a local MQTT broker when broker details are available.
