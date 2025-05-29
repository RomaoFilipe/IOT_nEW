import { subscribeToIrrigationChannel } from "../channels/irrigation_channel";

document.addEventListener("DOMContentLoaded", () => {
  const sensorId = document.querySelector("meta[name='sensor-id']")?.content;
  if (!sensorId) return;

  subscribeToIrrigationChannel(sensorId);
});
