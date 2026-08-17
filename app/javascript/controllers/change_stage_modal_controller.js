import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "stageSelect", "versionNumber", "historyList", "historyEmpty"]

  open(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    const planPath = event.currentTarget.dataset.planPath
    const stageId = event.currentTarget.dataset.stageModalStageParam
    const history = JSON.parse(event.currentTarget.dataset.stageModalHistoryParam || "[]")

    this.formTarget.action = planPath
    this.stageSelectTarget.value = stageId || ""
    const versionParam = event.currentTarget.dataset.stageModalVersionParam
    // Hardcoded validation because models validations are not available here
    this.versionNumberTarget.textContent =
      versionParam === "0" ? "LIVE version" : "Version " + versionParam
    this.renderHistory(history)
    $(this.modalTarget).modal("show")
  }

  close(event) {
    event.preventDefault()
    $(this.modalTarget).modal("hide")
  }

  renderHistory(entries) {
    this.historyListTarget.replaceChildren()

    if (!entries.length) {
      this.historyEmptyTarget.classList.remove("d-none")
      return
    }

    this.historyEmptyTarget.classList.add("d-none")

    entries.forEach((entry) => {
      const item = document.createElement("li")
      item.className = "list-group-item"

      const stage = document.createElement("div")
      stage.className = "fw-bold"
      stage.textContent = entry.stage || ""

      const meta = document.createElement("div")
      meta.className = "small text-muted"
      meta.textContent = [entry.user, entry.date].filter(Boolean).join(" · ")

      item.appendChild(stage)
      item.appendChild(meta)

      if (entry.motivation) {
        const motivation = document.createElement("div")
        motivation.className = "small mt-1"
        motivation.textContent = entry.motivation
        item.appendChild(motivation)
      }

      this.historyListTarget.appendChild(item)
    })
  }
}
