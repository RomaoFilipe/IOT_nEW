import consumer from "./consumer";

export const subscribeToIrrigationChannel = (sensorId, onUpdate) => {
  return consumer.subscriptions.create(
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

        if (!data || !data.remaining_time || !data.total_time) return;

        let remainingTime = data.remaining_time;
        const totalTime = data.total_time;

        const progressBar = document.querySelector(".irrigation-progress-bar");
        const progressText = document.querySelector(".irrigation-progress-text");

        if (!progressBar || !progressText) return;

        function formatTime(seconds) {
          const m = Math.floor(seconds / 60);
          const h = Math.floor(m / 60);
          const min = m % 60;
          const s = seconds % 60;
          return `${h}h ${min}m ${s}s`;
        }

        function updateUI() {
          const percent = (remainingTime / totalTime) * 100;
          progressBar.style.width = `${percent}%`;
          progressText.textContent = `Faltam: ${formatTime(remainingTime)}`;
        }

        updateUI();

        const interval = setInterval(() => {
          remainingTime--;
          updateUI();
          if (remainingTime <= 0) {
            clearInterval(interval);
            progressText.textContent = "Irrigação concluída";
            progressBar.style.width = "0%";
          }
        }, 1000);

        // Chama função externa se necessário
        if (onUpdate) onUpdate(data);
      }
    }
  );
};
