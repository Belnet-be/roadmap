import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "errorMessage", "stage"]

  confirm(event) {
    event.preventDefault()
    event.stopImmediatePropagation()
    
    // Reset state
    this.errorMessageTarget.classList.add('d-none')
    this.inputTarget.classList.remove('is-invalid')
    this.inputTarget.value = ""

    $(this.modalTarget).modal('show')
  }

  close(event) {
    event.preventDefault()
    $(this.modalTarget).modal('hide')
  }

  submitWithReason(event) {
    const input = this.inputTarget
    const reason = input.value.trim()

    if (!input.checkValidity() || reason === "") {
      this.errorMessageTarget.classList.remove('d-none')
      
      this.inputTarget.classList.add('is-invalid')
      this.inputTarget.focus()
      return
    }

    const form = this.element.querySelector("form")
    
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = "belnet_reason"
    hiddenInput.value = reason
    form.appendChild(hiddenInput)

    const hiddenStageInput = document.createElement("input")
    hiddenStageInput.type = "hidden"
    hiddenStageInput.name = "belnet_stage"
    hiddenStageInput.value = this.stageTarget.value
    form.appendChild(hiddenStageInput)
    
    $(this.modalTarget).modal('hide')
    form.submit()
  }
}