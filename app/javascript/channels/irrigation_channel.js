import consumer from "./consumer";

document.addEventListener("DOMContentLoaded", () => {
  // Obter sensor_id do meta tag no HTML
  const sensorId = document.querySelector("meta[name='sensor-id']")?.content;
  if (!sensorId) return;

  // Criar subscrição no canal ActionCable para este sensor
  consumer.subscriptions.create(
    { channel: "IrrigationChannel", sensor_id: sensorId },
    {
      connected() {
        console.log(`🟢 Conectado ao IrrigationChannel para sensor ${sensorId}`);
      },
      disconnected() {
        console.log("🔴 Desconectado do IrrigationChannel");
      },
      received(data) {
        console.log("📡 Dados recebidos do WebSocket:", data);

        // Dados esperados: remaining_time e total_time
        if (!data.remaining_time || !data.total_time) return;

        let remainingTime = data.remaining_time;
        const totalTime = data.total_time;

        // Selecionar elementos da UI
        const progressBar = document.querySelector(".irrigation-progress-bar");
        const progressText = document.querySelector(".irrigation-progress-text");

        if (!progressBar || !progressText) return;

        // Formatar tempo (segundos) para h m s
        function formatTime(seconds) {
          const m = Math.floor(seconds / 60);
          const h = Math.floor(m / 60);
          const min = m % 60;
          const s = seconds % 60;
          return `${h}h ${min}m ${s}s`;
        }

        // Função para atualizar a barra e texto na UI
        function updateUI() {
          const percent = (remainingTime / totalTime) * 100;
          progressBar.style.width = `${percent}%`;
          progressText.textContent = `Faltam: ${formatTime(remainingTime)}`;
        }

        updateUI();

        // Atualizar a UI a cada segundo até acabar o tempo
        const interval = setInterval(() => {
          remainingTime--;
          updateUI();

          if (remainingTime <= 0) {
            clearInterval(interval);
            progressText.textContent = "Irrigação concluída";
            progressBar.style.width = "0%";
          }
        }, 1000);
      }
    }
  );
});
