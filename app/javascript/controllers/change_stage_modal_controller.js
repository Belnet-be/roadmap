import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "stageSelect", "lastUpdatedBy", "versionNumber", "lastUpdatedAt"]

  open(event) {
    event.preventDefault()
    event.stopImmediatePropagation()
    
    let planId = event.currentTarget.dataset.planId
    let planPath = event.currentTarget.dataset.planPath
    let stage = event.currentTarget.dataset.stageModalStageParam

    this.formTarget.action = planPath

    if (stage) {
      this.stageSelectTarget.value = stage
    } else {
      this.stageSelectTarget.value = ""
    }

    this.lastUpdatedByTarget.textContent = "Last updated by " + event.currentTarget.dataset.stageModalLastUpdatedByParam + " " + event.currentTarget.dataset.stageModalLastUpdatedAtParam + " ago"
    this.versionNumberTarget.textContent = "Version " + event.currentTarget.dataset.stageModalVersionParam
    $(this.modalTarget).modal('show')
  }

  close(event) {
    event.preventDefault()
    console.log(event.currentTarget)
    $(this.modalTarget).modal('hide')
  }
}