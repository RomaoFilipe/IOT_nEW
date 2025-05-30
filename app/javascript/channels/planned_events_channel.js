import consumer from "./consumer"

consumer.subscriptions.create("PlannedEventsChannel", {
  connected() {
    console.log("Subscreveu PlannedEventsChannel")
  },

  disconnected() {
    console.log("Desligou PlannedEventsChannel")
  },

  received(data) {
    console.log("Recebeu dado:", data)

    if (data.action === 'destroy') {
      // Tarefa
      const el = document.querySelector(`#planned-task-${data.task_id}`)
      if (el) {
        el.classList.add('line-through', 'opacity-50')
        setTimeout(() => el.remove(), 5000)
      }
    }

    if (data.action === 'destroy_irrigation') {
      // Irrigação
      const el = document.querySelector(`#irrigation-schedule-${data.irrigation_id}`)
      if (el) {
        el.classList.add('line-through', 'opacity-50')
        setTimeout(() => el.remove(), 5000)
      }
    }
  }
})
