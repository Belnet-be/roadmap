import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "errorMessage", "stage", "reasonError", "stageError"]

  confirm(event) {
    event.preventDefault()
    event.stopImmediatePropagation()
    
    this.inputTarget.classList.remove('is-invalid')
    this.stageTarget.classList.remove('is-invalid')
    this.inputTarget.value = ""
    
    this.errorMessageTarget.classList.add('d-none')
    this.reasonErrorTarget.classList.add('d-none')
    this.stageErrorTarget.classList.add('d-none')

    $(this.modalTarget).modal('show')
  }

  close(event) {
    if (event) event.preventDefault()
    $(this.modalTarget).modal('hide')

  }

  submitWithReason(event) {
    if (event){
      event.preventDefault()

    } 

    const input = this.inputTarget
    const stageElement = this.stageTarget
    const reason = input.value.trim()
    const stage = stageElement.value

    let hasErrors = false

    if (!input.checkValidity()) {
      input.classList.add('is-invalid')
      this.reasonErrorTarget.classList.remove('d-none')
      hasErrors = true
    } else {
      input.classList.remove('is-invalid')
      this.reasonErrorTarget.classList.add('d-none')
    }

    if (!stageElement.checkValidity()) {
      stageElement.classList.add('is-invalid')
      this.stageErrorTarget.classList.remove('d-none')
      hasErrors = true
    } else {
      stageElement.classList.remove('is-invalid')
      
      this.stageErrorTarget.classList.add('d-none')
    }

    if (hasErrors) {
      this.errorMessageTarget.classList.remove('d-none')
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
    hiddenStageInput.value = stage
    form.appendChild(hiddenStageInput)
    
    $(this.modalTarget).modal('hide')
    form.submit()
  }
}