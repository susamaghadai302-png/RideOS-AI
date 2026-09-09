-- ============================================================================
-- RIDEOS-AI PHASE 16: UNIVERSAL VEHICLE DATABASE SCHEMA
-- PostgreSQL Multi-Domain Relational Schema for Automotive & Powersports
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(64) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    description TEXT NOT NULL
);

INSERT INTO schema_migrations (version, description)
VALUES ('20260831_v16_universal_vehicle_registry', 'Phase 16 Universal Vehicle Identification & Database Schema')
ON CONFLICT (version) DO NOTHING;

-- 1. Manufacturers / OEMs
CREATE TABLE IF NOT EXISTS manufacturers (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    country VARCHAR(64) NOT NULL,
    wmi_prefixes TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_manufacturers_wmi ON manufacturers USING GIN (wmi_prefixes);

-- 2. Fuel Types
CREATE TABLE IF NOT EXISTS fuel_types (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    is_electric BOOLEAN DEFAULT FALSE
);

-- 3. Transmissions
CREATE TABLE IF NOT EXISTS transmissions (
    id VARCHAR(64) PRIMARY KEY,
    transmission_type VARCHAR(64) NOT NULL, -- Manual, Automatic, DualClutch, CVT, DirectDriveEV, Quickshifter
    gears_count INT DEFAULT 6
);

-- 4. Engines & Electric Motors
CREATE TABLE IF NOT EXISTS engines (
    id VARCHAR(64) PRIMARY KEY,
    manufacturer_id VARCHAR(64) REFERENCES manufacturers(id) ON DELETE CASCADE,
    code VARCHAR(64) NOT NULL,
    configuration VARCHAR(64) NOT NULL, -- Inline-4, V4, Crossplane-4, Boxer, Electric Dual-Motor
    displacement_cc INT DEFAULT 0,
    max_power_hp NUMERIC(6,2) NOT NULL,
    max_torque_nm NUMERIC(6,2) NOT NULL,
    redline_rpm NUMERIC(6,1) DEFAULT 12000.0,
    fuel_type_id VARCHAR(32) REFERENCES fuel_types(id)
);

CREATE TABLE IF NOT EXISTS electric_motors (
    id VARCHAR(64) PRIMARY KEY,
    manufacturer_id VARCHAR(64) REFERENCES manufacturers(id) ON DELETE CASCADE,
    motor_architecture VARCHAR(64) NOT NULL, -- Permanent Magnet Synchronous, AC Induction
    max_power_kw NUMERIC(6,2) NOT NULL,
    max_torque_nm NUMERIC(6,2) NOT NULL,
    battery_capacity_kwh NUMERIC(6,2) NOT NULL
);

-- 5. Diagnostic Profiles & ECU Profiles
CREATE TABLE IF NOT EXISTS diagnostic_profiles (
    id VARCHAR(64) PRIMARY KEY,
    protocol_type VARCHAR(64) NOT NULL, -- ISO15765_4_CAN, ISO14229_1_UDS, ISO14230_4_KWP2000, SAE_J1939
    standard_baud_rate INT DEFAULT 500000,
    can_id_mode VARCHAR(32) DEFAULT '11_BIT',
    default_tx_header VARCHAR(16) DEFAULT '0x7E0',
    default_rx_header VARCHAR(16) DEFAULT '0x7E8'
);

CREATE TABLE IF NOT EXISTS ecu_profiles (
    id VARCHAR(64) PRIMARY KEY,
    ecu_vendor VARCHAR(64) NOT NULL, -- Denso, Bosch, Marelli, Continental, Siemens
    calibration_id_pattern VARCHAR(128),
    diagnostic_profile_id VARCHAR(64) REFERENCES diagnostic_profiles(id),
    firmware_read_supported BOOLEAN DEFAULT FALSE,
    dtc_clear_supported BOOLEAN DEFAULT TRUE
);

-- 6. Vehicle Screen & Head-Unit Profiles
CREATE TABLE IF NOT EXISTS vehicle_screen_profiles (
    id VARCHAR(64) PRIMARY KEY,
    display_type VARCHAR(64) NOT NULL, -- TFT_COLOR, LCD_SEGMENTED, TOUCHSCREEN_ANDROID_AUTO, DUAL_CLUSTER
    resolution_width INT DEFAULT 800,
    resolution_height INT DEFAULT 480,
    supports_turn_by_turn BOOLEAN DEFAULT TRUE,
    supports_caller_id BOOLEAN DEFAULT TRUE,
    supports_media_info BOOLEAN DEFAULT TRUE
);

-- 7. Maintenance Profiles
CREATE TABLE IF NOT EXISTS maintenance_profiles (
    id VARCHAR(64) PRIMARY KEY,
    oil_change_interval_km INT DEFAULT 6000,
    valve_clearance_interval_km INT DEFAULT 24000,
    brake_fluid_months INT DEFAULT 24,
    spark_plug_interval_km INT DEFAULT 12000,
    custom_intervals_json JSONB DEFAULT '{}'::jsonb
);

-- 8. Vehicle Models & Generations
CREATE TABLE IF NOT EXISTS vehicle_models (
    id VARCHAR(64) PRIMARY KEY,
    manufacturer_id VARCHAR(64) REFERENCES manufacturers(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    domain_type VARCHAR(32) NOT NULL, -- MOTORCYCLE, CAR, SCOOTER, EV, FLEET, ATV
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_generations (
    id VARCHAR(64) PRIMARY KEY,
    model_id VARCHAR(64) REFERENCES vehicle_models(id) ON DELETE CASCADE,
    generation_name VARCHAR(128) NOT NULL, -- Gen 5 (2020-2024), 992.1 (2019-2024)
    start_year INT NOT NULL,
    end_year INT
);

CREATE TABLE IF NOT EXISTS vehicle_variants (
    id VARCHAR(64) PRIMARY KEY,
    generation_id VARCHAR(64) REFERENCES vehicle_generations(id) ON DELETE CASCADE,
    variant_name VARCHAR(128) NOT NULL, -- Carbon Performance, S, Track Edition
    year INT NOT NULL,
    engine_id VARCHAR(64) REFERENCES engines(id),
    motor_id VARCHAR(64) REFERENCES electric_motors(id),
    transmission_id VARCHAR(64) REFERENCES transmissions(id),
    ecu_profile_id VARCHAR(64) REFERENCES ecu_profiles(id),
    screen_profile_id VARCHAR(64) REFERENCES vehicle_screen_profiles(id),
    maintenance_profile_id VARCHAR(64) REFERENCES maintenance_profiles(id),
    model_3d_asset_path VARCHAR(256),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_vehicle_variants_year ON vehicle_variants(year);
CREATE INDEX IF NOT EXISTS idx_vehicle_variants_generation ON vehicle_variants(generation_id);

-- 9. Authoritative VIN Registry Catalog
CREATE TABLE IF NOT EXISTS authoritative_vin_records (
    vin VARCHAR(17) PRIMARY KEY,
    variant_id VARCHAR(64) REFERENCES vehicle_variants(id),
    assembly_plant VARCHAR(64),
    serial_number INT,
    manufacture_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_authoritative_vin_prefix ON authoritative_vin_records(SUBSTRING(vin FROM 1 FOR 8));
