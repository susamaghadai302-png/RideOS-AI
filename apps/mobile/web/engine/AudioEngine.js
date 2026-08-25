export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.compressor = null;
    this.oscPrimary = null;
    this.oscSub = null;
    this.oscHarmonic = null;
    this.oscIntake = null;
    this.filter = null;
    this.isPlaying = false;
    this.isMuted = false;
    this.currentVehicleId = 'yamaha_r1m_2024';
    this.currentRpm = 0;
  }

  _ensureContext() {
    if (!this.ctx) {
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (AudioContextClass) {
        this.ctx = new AudioContextClass();
        this.compressor = this.ctx.createDynamicsCompressor();
        this.compressor.threshold.setValueAtTime(-18, this.ctx.currentTime);
        this.compressor.knee.setValueAtTime(12, this.ctx.currentTime);
        this.compressor.ratio.setValueAtTime(6, this.ctx.currentTime);
        this.compressor.attack.setValueAtTime(0.003, this.ctx.currentTime);
        this.compressor.release.setValueAtTime(0.25, this.ctx.currentTime);

        this.masterGain = this.ctx.createGain();
        this.masterGain.gain.setValueAtTime(0.20, this.ctx.currentTime);

        this.compressor.connect(this.masterGain);
        this.masterGain.connect(this.ctx.destination);
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  startEngine(vehicleId, initialRpm = 1250) {
    if (this.isMuted) return;
    this._ensureContext();
    if (!this.ctx) return;
    if (this.isPlaying) this.stopEngine();

    this.currentVehicleId = vehicleId || 'yamaha_r1m_2024';
    this.currentRpm = initialRpm;
    this.lastRpm = initialRpm;
    this.exhaustType = this.exhaustType || 0;
    const now = this.ctx.currentTime;

    // Filter for induction & exhaust acoustics
    this.filter = this.ctx.createBiquadFilter();
    this.filter.type = 'lowpass';
    this.filter.frequency.setValueAtTime(450, now);
    this.filter.Q.setValueAtTime(3.5, now);
    this.filter.connect(this.compressor);

    // Starter crank click/crackle
    this._playStarterBurst();

    // Multi-oscillator setup based on bike engine architecture
    const isDucati = this.currentVehicleId.includes('ducati');
    const isBmw = this.currentVehicleId.includes('bmw');

    // Primary cylinder combustion pulses
    this.oscPrimary = this.ctx.createOscillator();
    this.oscPrimary.type = isDucati ? 'sawtooth' : 'triangle';

    // Sub-harmonic crank thud
    this.oscSub = this.ctx.createOscillator();
    this.oscSub.type = 'sawtooth';

    // High-frequency mechanical valve whine
    this.oscHarmonic = this.ctx.createOscillator();
    this.oscHarmonic.type = isBmw ? 'sawtooth' : 'sine';

    // Connect to filter
    this.oscPrimary.connect(this.filter);
    this.oscSub.connect(this.filter);
    this.oscHarmonic.connect(this.filter);

    this.updateRpm(initialRpm);

    this.oscPrimary.start(now + 0.15);
    this.oscSub.start(now + 0.15);
    this.oscHarmonic.start(now + 0.15);

    this.isPlaying = true;
  }

  _playStarterBurst() {
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(65, now);
    osc.frequency.exponentialRampToValueAtTime(140, now + 0.25);
    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.25);
    osc.connect(gain);
    gain.connect(this.compressor);
    osc.start(now);
    osc.stop(now + 0.25);
  }

  setExhaustProfile(exhaustIndex) {
    this.exhaustType = exhaustIndex;
    if (this.isPlaying && this.currentRpm > 0) {
      this.updateRpm(this.currentRpm);
    }
  }

  _triggerBackfire() {
    if (!this.ctx || this.isMuted) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(120 + Math.random() * 80, now);
    osc.frequency.exponentialRampToValueAtTime(25, now + 0.09);
    gain.gain.setValueAtTime(0.32, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);
    osc.connect(gain);
    gain.connect(this.compressor);
    osc.start(now);
    osc.stop(now + 0.09);
  }

  updateRpm(rpm) {
    if (!this.isPlaying || !this.ctx) return;
    const now = this.ctx.currentTime;

    // Detect rapid deceleration to trigger backfire pops
    if (this.lastRpm && (this.lastRpm - rpm > 600) && (this.exhaustType === 2 || this.exhaustType === 3)) {
      if (Math.random() < 0.65) {
        this._triggerBackfire();
      }
    }
    this.lastRpm = rpm;
    this.currentRpm = rpm;

    // Base engine frequency (RPM -> Hz: 4-stroke 4-cylinder fires twice per revolution)
    const isDucati = this.currentVehicleId.includes('ducati');
    const isBmw = this.currentVehicleId.includes('bmw');

    const freqMultiplier = isDucati ? 1.85 : isBmw ? 2.15 : 2.0;
    const baseFreq = Math.max(25, (rpm / 60.0) * freqMultiplier);

    // Acoustic multipliers based on aftermarket exhaust system
    let exhaustGainMultiplier = 1.0;
    let exhaustFilterBoost = 1.0;
    let exhaustQ = 3.5;

    switch (this.exhaustType) {
      case 1: // Akrapovič Full Titanium
        exhaustGainMultiplier = 1.15;
        exhaustFilterBoost = 1.25;
        exhaustQ = 4.2;
        break;
      case 2: // SC-Project SC1-R
        exhaustGainMultiplier = 1.35;
        exhaustFilterBoost = 1.45;
        exhaustQ = 5.0;
        break;
      case 3: // Austin Racing GP-1
        exhaustGainMultiplier = 1.25;
        exhaustFilterBoost = 1.65;
        exhaustQ = 5.8;
        break;
      default: // OEM
        exhaustGainMultiplier = 1.0;
        exhaustFilterBoost = 1.0;
        exhaustQ = 3.5;
        break;
    }

    if (this.oscPrimary) {
      this.oscPrimary.frequency.setTargetAtTime(baseFreq, now, 0.04);
    }
    if (this.oscSub) {
      this.oscSub.frequency.setTargetAtTime(baseFreq * 0.5, now, 0.04);
    }
    if (this.oscHarmonic) {
      const harmMult = isBmw ? 4.0 : 3.0;
      this.oscHarmonic.frequency.setTargetAtTime(baseFreq * harmMult, now, 0.04);
    }
    if (this.filter) {
      const filterCutoff = Math.min(7500, (350 + (rpm / 15000.0) * 4200) * exhaustFilterBoost);
      this.filter.frequency.setTargetAtTime(filterCutoff, now, 0.05);
      this.filter.Q.setTargetAtTime(exhaustQ, now, 0.05);
    }
    if (this.masterGain && !this.isMuted) {
      const gainVal = Math.min(0.40, (0.16 + (rpm / 16000.0) * 0.18) * exhaustGainMultiplier);
      this.masterGain.gain.setTargetAtTime(gainVal, now, 0.04);
    }
  }

  stopEngine() {
    if (!this.isPlaying || !this.ctx) return;
    const now = this.ctx.currentTime;

    if (this.masterGain) {
      this.masterGain.gain.setTargetAtTime(0.001, now, 0.15);
    }

    setTimeout(() => {
      try {
        if (this.oscPrimary) { this.oscPrimary.stop(); this.oscPrimary.disconnect(); this.oscPrimary = null; }
        if (this.oscSub) { this.oscSub.stop(); this.oscSub.disconnect(); this.oscSub = null; }
        if (this.oscHarmonic) { this.oscHarmonic.stop(); this.oscHarmonic.disconnect(); this.oscHarmonic = null; }
        if (this.filter) { this.filter.disconnect(); this.filter = null; }
      } catch (_) {}
      this.isPlaying = false;
    }, 200);
  }

  setMuted(muted) {
    this.isMuted = muted;
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setValueAtTime(muted ? 0 : 0.20, this.ctx.currentTime);
    }
    if (!muted && this.currentRpm > 0 && !this.isPlaying) {
      this.startEngine(this.currentVehicleId, this.currentRpm);
    }
  }
}
