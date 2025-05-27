import consumer from "./consumer"



export const subscribeToIrrigation = (sensorId, updateUI) => {
  return consumer.subscriptions.create(
    { channel: "IrrigationStatusChannel", sensor_id: sensorId },
    {
      received(data) {
        updateUI(data)
      }
    }
  )
}
