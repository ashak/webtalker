import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="terminal"
export default class extends Controller {
  static targets = [ "input", "output" ]

  connect() {
    this.observer = new MutationObserver(this.handleMutations.bind(this))

    this.observer.observe(this.outputTarget, {
      childList: true,
      subtree: false
    })

    this.shouldStickToBottom = true;
    this.outputTarget.scrollTop = this.outputTarget.scrollHeight;
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleMutations(mutations) {
    for (const mutation of mutations) {
      if (this.shouldStickToBottom && mutation.type === "childList") {
        this.outputTarget.scrollTop = this.outputTarget.scrollHeight;
      }
    }
  }

  // Detect whether user is near the bottom of the scrolling window
  isNearBottom() {
    const threshold = this.outputTarget.clientHeight / 2;
    return (
      this.outputTarget.scrollHeight - this.outputTarget.scrollTop - this.outputTarget.clientHeight < threshold
    )
  }

  update_scroll_status() {
    console.log = "updating scroll status " + this.isNearBottom();
    this.shouldStickToBottom = this.isNearBottom();
  }

  reset_input() {
    this.inputTarget.value = '';
  }
}