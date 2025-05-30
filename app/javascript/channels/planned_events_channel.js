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

    const list = document.getElementById("planned-events-list")
    if (!list) return

    if (data.action === 'create') {
      // Adiciona novo evento ao topo da lista
      const tempDiv = document.createElement("template")
      tempDiv.innerHTML = data.task
      const newItem = tempDiv.content.firstElementChild
      list.querySelector("ul")?.prepend(newItem)
    }

    if (data.action === 'destroy') {
      // Risca e remove item da lista
      const el = document.getElementById(`planned_task_${data.id}`)
      if (el) {
        el.classList.add('line-through', 'opacity-50')
        setTimeout(() => el.remove(), 5000)
      }
    }

    if (data.action === 'destroy_irrigation') {
      const el = document.getElementById(`irrigation_schedule_${data.id}`)
      if (el) {
        el.classList.add('line-through', 'opacity-50')
        setTimeout(() => el.remove(), 5000)
      }
    }
  }
})
