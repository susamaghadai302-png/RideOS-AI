/**
 * RideOS-AI Web Bluetooth Bridge
 * Implements real Bluetooth Low Energy (BLE) scanning, GATT connection,
 * and service/characteristic exploration via navigator.bluetooth on Chrome/Edge (macOS, Windows, Android).
 */

(function() {
  const activeDevices = new Map(); // deviceId -> BluetoothDevice
  const gattServers = new Map(); // deviceId -> BluetoothRemoteGATTServer
  let disconnectListeners = [];

  // Known standard GATT services for pretty printing
  const KNOWN_SERVICES = {
    '00001800-0000-1000-8000-00805f9b34fb': 'Generic Access',
    '00001801-0000-1000-8000-00805f9b34fb': 'Generic Attribute',
    '0000180a-0000-1000-8000-00805f9b34fb': 'Device Information',
    '0000180f-0000-1000-8000-00805f9b34fb': 'Battery Service',
    '0000180d-0000-1000-8000-00805f9b34fb': 'Heart Rate',
    '00001816-0000-1000-8000-00805f9b34fb': 'Cycling Speed & Cadence',
    '00001814-0000-1000-8000-00805f9b34fb': 'Running Speed & Cadence',
    '0000181a-0000-1000-8000-00805f9b34fb': 'Environmental Sensing',
    '000018f0-0000-1000-8000-00805f9b34fb': 'TVS SmartXonnect Telematics',
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e': 'Nordic UART Service (NUS)',
    '0000fe59-0000-1000-8000-00805f9b34fb': 'Royal Enfield Tripper Nav',
    '0000fff0-0000-1000-8000-00805f9b34fb': 'OBD-II / Motorcycle CCU',
    '0000ffe0-0000-1000-8000-00805f9b34fb': 'Standard BLE Pass-Through',
    'e7810a71-73ae-499d-8c15-faa9aef0c3f2': 'OBDLink MX+ Custom',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455': 'Microchip IS187x BLE',
  };

  // Standard Motorcycle CCU and OBD optional services list
  const STANDARD_OPTIONAL_SERVICES = [
    'battery_service',
    'device_information',
    'generic_access',
    'generic_attribute',
    'cycling_speed_and_cadence',
    'environmental_sensing',
    '00001800-0000-1000-8000-00805f9b34fb',
    '00001801-0000-1000-8000-00805f9b34fb',
    '0000180a-0000-1000-8000-00805f9b34fb',
    '0000180f-0000-1000-8000-00805f9b34fb',
    '00001816-0000-1000-8000-00805f9b34fb',
    '0000181a-0000-1000-8000-00805f9b34fb',
    '000018f0-0000-1000-8000-00805f9b34fb',
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
    '0000fe59-0000-1000-8000-00805f9b34fb',
    '0000fff0-0000-1000-8000-00805f9b34fb',
    '0000ffe0-0000-1000-8000-00805f9b34fb',
    '0000fee0-0000-1000-8000-00805f9b34fb',
    'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455',
  ];

  window.RideOSWebBluetooth = {
    /**
     * Check if Web Bluetooth API is supported in the current browser environment.
     */
    checkSupport: function() {
      const isLocalhost = Boolean(
        window.location.hostname === 'localhost' ||
        window.location.hostname === '[::1]' ||
        window.location.hostname.match(/^127(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$/)
      );

      const isSecure = window.isSecureContext || isLocalhost;
      const hasApi = Boolean(navigator.bluetooth && typeof navigator.bluetooth.requestDevice === 'function');

      let reason = 'Web Bluetooth is fully operational on macOS Chrome/Edge.';
      if (!hasApi) {
        if (!isSecure) {
          reason = 'Web Bluetooth requires a Secure Context (HTTPS or localhost).';
        } else {
          reason = 'Web Bluetooth API is not supported in this browser. Please use Google Chrome, Microsoft Edge, or a Chromium-based browser on macOS.';
        }
      }

      return JSON.stringify({
        supported: hasApi,
        isSecureContext: isSecure,
        isLocalhost: isLocalhost,
        userAgent: navigator.userAgent,
        reason: reason,
      });
    },

    /**
     * Check if Bluetooth radio is currently available and turned on.
     */
    getAvailability: async function() {
      try {
        if (!navigator.bluetooth || !navigator.bluetooth.getAvailability) {
          return JSON.stringify({ available: false, error: 'getAvailability not supported' });
        }
        const available = await navigator.bluetooth.getAvailability();
        return JSON.stringify({ available: available, error: null });
      } catch (e) {
        return JSON.stringify({ available: false, error: e.toString() });
      }
    },

    /**
     * Trigger native browser Bluetooth device picker using navigator.bluetooth.requestDevice().
     */
    requestDevice: async function(optionsJson) {
      try {
        if (!navigator.bluetooth) {
          return JSON.stringify({
            success: false,
            cancelled: false,
            error: 'Web Bluetooth API not available in this browser. Use Google Chrome on macOS.'
          });
        }

        let options = {
          acceptAllDevices: true,
          optionalServices: STANDARD_OPTIONAL_SERVICES
        };

        if (optionsJson && typeof optionsJson === 'string') {
          try {
            const parsed = JSON.parse(optionsJson);
            if (parsed.filters && Array.isArray(parsed.filters) && parsed.filters.length > 0) {
              options = {
                filters: parsed.filters,
                optionalServices: parsed.optionalServices || STANDARD_OPTIONAL_SERVICES
              };
            } else if (parsed.optionalServices) {
              options.optionalServices = parsed.optionalServices;
            }
          } catch (_) {}
        }

        console.log('[RideOS Web BLE] Requesting real Bluetooth device with options:', options);
        const device = await navigator.bluetooth.requestDevice(options);

        if (!device) {
          return JSON.stringify({
            success: false,
            cancelled: true,
            error: 'No device selected'
          });
        }

        activeDevices.set(device.id, device);

        // Setup disconnect listener
        device.addEventListener('gattserverdisconnected', (event) => {
          console.log('[RideOS Web BLE] Device disconnected:', device.id, device.name);
          gattServers.delete(device.id);
          window.dispatchEvent(new CustomEvent('rideos_ble_disconnected', {
            detail: { deviceId: device.id, deviceName: device.name || 'Unknown BLE Device' }
          }));
        });

        return JSON.stringify({
          success: true,
          cancelled: false,
          deviceId: device.id,
          deviceName: device.name || 'Unknown BLE Vehicle',
          isConnected: device.gatt ? device.gatt.connected : false
        });
      } catch (err) {
        console.warn('[RideOS Web BLE] requestDevice exception:', err);
        const errStr = err ? err.toString() : '';
        const isCancelled = err.name === 'NotFoundError' || errStr.includes('cancelled') || errStr.includes('User cancelled');

        return JSON.stringify({
          success: false,
          cancelled: isCancelled,
          error: isCancelled ? 'User cancelled Bluetooth device selection.' : errStr
        });
      }
    },

    /**
     * Connect to the selected device via GATT and discover services & characteristics.
     */
    connectGatt: async function(deviceId) {
      try {
        const device = activeDevices.get(deviceId);
        if (!device) {
          return JSON.stringify({
            success: false,
            error: 'Device not found in active cache. Please scan again.'
          });
        }

        console.log('[RideOS Web BLE] Connecting to GATT server for device:', device.id, device.name);
        const server = await device.gatt.connect();
        gattServers.set(deviceId, server);

        console.log('[RideOS Web BLE] Connected! Discovering primary services...');
        let services = [];
        try {
          const primaryServices = await server.getPrimaryServices();
          for (const service of primaryServices) {
            const serviceUuid = service.uuid.toLowerCase();
            const serviceName = KNOWN_SERVICES[serviceUuid] || 'Custom Vehicle Service';

            let characteristics = [];
            try {
              const chars = await service.getCharacteristics();
              for (const ch of chars) {
                const props = [];
                if (ch.properties.read) props.push('READ');
                if (ch.properties.write) props.push('WRITE');
                if (ch.properties.writeWithoutResponse) props.push('WRITE_NO_RESP');
                if (ch.properties.notify) props.push('NOTIFY');
                if (ch.properties.indicate) props.push('INDICATE');

                characteristics.push({
                  uuid: ch.uuid,
                  properties: props
                });
              }
            } catch (charErr) {
              console.warn('[RideOS Web BLE] Error getting characteristics for service:', serviceUuid, charErr);
            }

            services.push({
              uuid: service.uuid,
              name: serviceName,
              isPrimary: service.isPrimary,
              characteristicsCount: characteristics.length,
              characteristics: characteristics
            });
          }
        } catch (servErr) {
          console.warn('[RideOS Web BLE] Error discovering services:', servErr);
        }

        return JSON.stringify({
          success: true,
          deviceId: device.id,
          deviceName: device.name || 'Unknown BLE Vehicle',
          isConnected: server.connected,
          servicesCount: services.length,
          services: services
        });
      } catch (err) {
        console.error('[RideOS Web BLE] connectGatt error:', err);
        return JSON.stringify({
          success: false,
          error: err.toString()
        });
      }
    },

    /**
     * Disconnect GATT server.
     */
    disconnect: async function(deviceId) {
      try {
        const device = activeDevices.get(deviceId);
        if (device && device.gatt && device.gatt.connected) {
          device.gatt.disconnect();
        }
        gattServers.delete(deviceId);
        return JSON.stringify({ success: true });
      } catch (e) {
        return JSON.stringify({ success: false, error: e.toString() });
      }
    }
  };

  console.log('[RideOS Web BLE Bridge] Initialized. navigator.bluetooth available:', Boolean(navigator.bluetooth));
})();
