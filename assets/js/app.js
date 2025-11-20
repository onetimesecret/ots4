// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

// Copy to clipboard hook
Hooks.Copy = {
  mounted() {
    this.el.addEventListener("click", e => {
      e.preventDefault()
      const text = this.el.dataset.text || this.el.value
      navigator.clipboard.writeText(text).then(() => {
        const originalText = this.el.textContent
        this.el.textContent = "Copied!"
        setTimeout(() => {
          this.el.textContent = originalText
        }, 2000)
      })
    })
  }
}

// Convert UTC times to local timezone
Hooks.LocalTime = {
  mounted() {
    this.updateTime()
  },
  updated() {
    this.updateTime()
  },
  updateTime() {
    const datetime = this.el.getAttribute("datetime")
    const format = this.el.dataset.format || "long"

    if (datetime) {
      const date = new Date(datetime)
      let formatted

      switch(format) {
        case "short":
          formatted = date.toLocaleString(undefined, {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
          })
          break
        case "relative":
          formatted = this.relativeTime(date)
          break
        default:
          formatted = date.toLocaleString(undefined, {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            timeZoneName: 'short'
          })
      }

      this.el.textContent = formatted
    }
  },
  relativeTime(date) {
    const now = new Date()
    const diff = Math.floor((date - now) / 1000)

    if (diff < 60) return `in ${diff} seconds`
    if (diff < 3600) return `in ${Math.floor(diff / 60)} minutes`
    if (diff < 86400) return `in ${Math.floor(diff / 3600)} hours`
    if (diff < 604800) return `in ${Math.floor(diff / 86400)} days`

    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
