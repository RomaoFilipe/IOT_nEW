import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]
  static contentTargets = ["yield", "resources", "soil", "profit"]

  connect() {
    this.switch({ currentTarget: this.element.querySelector("[data-tabs-target='yield']") }) // Tab inicial
  }

  switch(event) {
    const target = event.currentTarget.dataset.tabsTarget

    this.contentTargets.forEach((el) => el.classList.add("hidden"))
    this.tabTargets.forEach((btn) => {
      btn.classList.remove("bg-green-600", "text-white", "shadow")
      btn.classList.add("bg-white", "text-gray-700")
    })

    const selected = this.contentTargets.find(el => el.dataset.tabsContent === target)
    if (selected) selected.classList.remove("hidden")

    event.currentTarget.classList.remove("bg-white", "text-gray-700")
    event.currentTarget.classList.add("bg-green-600", "text-white", "shadow")
  }
}
