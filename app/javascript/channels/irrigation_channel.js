import consumer from "./consumer";

document.addEventListener("DOMContentLoaded", () => {
  const sensorId = document.querySelector("meta[name='sensor-id']")?.content;
  if (!sensorId) return;

  consumer.subscriptions.create(
    { channel: "IrrigationChannel", sensor_id: sensorId },
    {
      connected() {
        console.log(`🟢 Conectado ao IrrigationChannel para sensor ${sensorId}`);
      },
      disconnected() {
        console.log("🔴 Desconectado");
      },
      received(data) {
        console.log("📡 WebSocket recebido:", data);

        let remainingTime = data.remaining_time;
        const totalTime = data.total_time;

        const progressBar = document.querySelector(".irrigation-progress-bar");
        const progressText = document.querySelector(".irrigation-progress-text");

        function formatTime(seconds) {
          const m = Math.floor(seconds / 60);
          const h = Math.floor(m / 60);
          const min = m % 60;
          const s = seconds % 60;
          return `${h}h ${min}m ${s}s`;
        }

        function updateUI() {
          if (!progressBar || !progressText) return;
          const percent = (remainingTime / totalTime) * 100;
          progressBar.style.width = `${percent}%`;
          progressText.textContent = `Faltam: ${formatTime(remainingTime)}`;
        }

        updateUI();

        const interval = setInterval(() => {
          if (remainingTime <= 0) {
            clearInterval(interval);
            return;
          }
          remainingTime--;
          updateUI();
        }, 1000);
      }
    }
  );
});
