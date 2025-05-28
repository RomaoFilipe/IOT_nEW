// app/javascript/channels/irrigation_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("IrrigationChannel", {
  connected() {
    console.log("Conectado ao IrrigationChannel");
  },
  disconnected() {
    console.log("Desconectado do IrrigationChannel");
  },
  received(data) {
    console.log("Recebido via WebSocket:", data);
    // Atualiza a UI com data recebido
  }
});
