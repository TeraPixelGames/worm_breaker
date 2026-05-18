(function () {
  if (window.WormBreakerWebAudio) {
    return;
  }

  const PULSE_THRESHOLD = 0.003;
  const ONSET_THRESHOLD = 0.002;
  const LEVEL_GAIN = 14.0;
  const LEVEL_MAX = 0.18;
  const ONSET_GAIN = 32.0;
  const ATTACK = 32.0;
  const DECAY = 6.8;

  let audioContext = null;
  let analyser = null;
  let source = null;
  let stream = null;
  let data = null;
  let frequencyData = null;
  let animationId = 0;
  let energy = 0.0;
  let pulse = 0.0;
  let bass = 0.0;
  let mid = 0.0;
  let treble = 0.0;
  let energyFloor = 0.0;
  let previousEnergy = 0.0;
  let previousTime = 0.0;
  let status = "idle";
  let errorMessage = "";

  function supported() {
    return !!(
      navigator.mediaDevices &&
      navigator.mediaDevices.getDisplayMedia &&
      (window.AudioContext || window.webkitAudioContext)
    );
  }

  function smoothPulse(currentPulse, targetPulse, delta) {
    const rate = targetPulse > currentPulse ? ATTACK : DECAY;
    const weight = 1.0 - Math.exp(-rate * Math.max(delta, 0.0));
    const target = Math.max(0.0, Math.min(1.0, targetPulse));
    return Math.max(0.0, Math.min(1.0, currentPulse + (target - currentPulse) * Math.max(0.0, Math.min(1.0, weight))));
  }

  function smoothEnergyFloor(currentFloor, latestEnergy) {
    const clampedEnergy = Math.max(0.0, latestEnergy);
    const rate = clampedEnergy > currentFloor ? 0.04 : 0.35;
    return Math.max(0.0, Math.min(1.0, currentFloor + (clampedEnergy - currentFloor) * rate));
  }

  function pulseTarget(currentEnergy, lastEnergy, floor) {
    const levelReference = Math.max(PULSE_THRESHOLD, floor + PULSE_THRESHOLD);
    const levelPulse = Math.min(Math.max(currentEnergy - levelReference, 0.0) * LEVEL_GAIN, LEVEL_MAX);
    const onsetPulse = Math.max((currentEnergy - lastEnergy) - ONSET_THRESHOLD, 0.0) * ONSET_GAIN;
    return Math.max(0.0, Math.min(1.0, Math.max(levelPulse, onsetPulse)));
  }

  function resetLevels() {
    energy = 0.0;
    pulse = 0.0;
    bass = 0.0;
    mid = 0.0;
    treble = 0.0;
    energyFloor = 0.0;
    previousEnergy = 0.0;
    previousTime = 0.0;
  }

  function cleanup(nextStatus) {
    if (animationId) {
      cancelAnimationFrame(animationId);
      animationId = 0;
    }
    if (source) {
      source.disconnect();
      source = null;
    }
    if (stream) {
      for (const track of stream.getTracks()) {
        track.onended = null;
        track.stop();
      }
      stream = null;
    }
    if (audioContext) {
      audioContext.close();
      audioContext = null;
    }
    analyser = null;
    data = null;
    frequencyData = null;
    resetLevels();
    status = nextStatus || "idle";
  }

  function update(now) {
    if (!analyser || !data || !frequencyData) {
      return;
    }
    analyser.getByteTimeDomainData(data);
    analyser.getByteFrequencyData(frequencyData);
    let sum = 0.0;
    for (let i = 0; i < data.length; i += 1) {
      const sample = Math.max(-1.0, Math.min(1.0, (data[i] - 128.0) / 128.0));
      sum += sample * sample;
    }
    const latestEnergy = Math.sqrt(sum / data.length);
    const delta = previousTime > 0.0 ? Math.max(0.0, (now - previousTime) / 1000.0) : 1.0 / 60.0;
    previousTime = now;
    energyFloor = smoothEnergyFloor(energyFloor, latestEnergy);
    pulse = smoothPulse(pulse, pulseTarget(latestEnergy, previousEnergy, energyFloor), delta);
    bass = frequencyBandLevel(0, 6, 2.8);
    mid = frequencyBandLevel(7, 34, 2.1);
    treble = frequencyBandLevel(35, 160, 2.4);
    previousEnergy = latestEnergy;
    energy = latestEnergy;
    status = "capturing";
    animationId = requestAnimationFrame(update);
  }

  function frequencyBandLevel(startBin, endBin, gain) {
    if (!frequencyData || frequencyData.length === 0) {
      return 0.0;
    }
    const start = Math.max(0, Math.min(frequencyData.length - 1, startBin));
    const end = Math.max(start, Math.min(frequencyData.length - 1, endBin));
    let sum = 0.0;
    let peak = 0.0;
    let count = 0;
    for (let i = start; i <= end; i += 1) {
      const value = frequencyData[i] / 255.0;
      sum += value * value;
      peak = Math.max(peak, value);
      count += 1;
    }
    const rms = Math.sqrt(sum / Math.max(1, count));
    return Math.max(0.0, Math.min(1.0, Math.max(rms * gain, peak * gain * 0.45)));
  }

  async function start() {
    if (status === "capturing" || status === "starting") {
      return true;
    }
    if (!supported()) {
      status = "unsupported";
      errorMessage = "getDisplayMedia or Web Audio is unavailable";
      return false;
    }
    status = "starting";
    errorMessage = "";
    cleanup("starting");
    try {
      stream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: {
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
          suppressLocalAudioPlayback: false
        },
        systemAudio: "include",
        windowAudio: "system",
        surfaceSwitching: "include",
        monitorTypeSurfaces: "include"
      });
      if (!stream.getAudioTracks || stream.getAudioTracks().length === 0) {
        cleanup("no-audio");
        errorMessage = "Selected share source did not include audio";
        return false;
      }
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      audioContext = new AudioContextClass();
      if (audioContext.state === "suspended") {
        await audioContext.resume();
      }
      analyser = audioContext.createAnalyser();
      analyser.fftSize = 1024;
      analyser.smoothingTimeConstant = 0.18;
      source = audioContext.createMediaStreamSource(stream);
      source.connect(analyser);
      data = new Uint8Array(analyser.fftSize);
      frequencyData = new Uint8Array(analyser.frequencyBinCount);
      for (const track of stream.getTracks()) {
        track.onended = function () {
          cleanup("ended");
        };
      }
      resetLevels();
      status = "capturing";
      animationId = requestAnimationFrame(update);
      return true;
    } catch (err) {
      cleanup("error");
      errorMessage = err && err.message ? err.message : String(err);
      return false;
    }
  }

  window.WormBreakerWebAudio = {
    start: start,
    stop: function () {
      cleanup("stopped");
      return true;
    },
    isSupported: supported,
    isAvailable: function () {
      return status === "capturing";
    },
    getEnergy: function () {
      return energy;
    },
    getPulse: function () {
      return pulse;
    },
    getBass: function () {
      return bass;
    },
    getMid: function () {
      return mid;
    },
    getTreble: function () {
      return treble;
    },
    getStatus: function () {
      return status;
    },
    getError: function () {
      return errorMessage;
    }
  };
})();
