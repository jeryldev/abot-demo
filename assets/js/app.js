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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/abot_demo"
import topbar from "../vendor/topbar"
import {gsap} from "gsap"

async function copyToClipboard(text) {
  if (!text?.trim()) return false

  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      return true
    }
  } catch (_error) {
    // Fall through to the browser-compatible copy path.
  }

  const buffer = document.createElement("textarea")
  buffer.value = text
  buffer.setAttribute("readonly", "")
  buffer.style.position = "fixed"
  buffer.style.opacity = "0"
  document.body.append(buffer)
  buffer.select()

  const copied = document.execCommand("copy")
  buffer.remove()
  return copied
}

const copyLetterHook = {
  mounted() {
    this.copyLetter = async () => {
      const source = document.getElementById(this.el.dataset.copyTarget)
      const copied = await copyToClipboard(source?.value || "")
      this.pushEvent(copied ? "copy" : "copy_failed")
    }

    this.el.addEventListener("click", this.copyLetter)
  },
  destroyed() {
    this.el.removeEventListener("click", this.copyLetter)
  },
}

const screenTransitionHook = {
  mounted() {
    this.currentScreen = this.el.dataset.screen
    this.transitionDirection = 1
    this.animateScreen()
  },
  updated() {
    const nextScreen = this.el.dataset.screen

    if (nextScreen !== this.currentScreen) {
      const screens = ["intake", "plan", "detail", "checklist"]
      this.transitionDirection = Math.sign(screens.indexOf(nextScreen) - screens.indexOf(this.currentScreen)) || 1
      this.currentScreen = nextScreen
      window.scrollTo({top: 0, behavior: "smooth"})
      this.animateScreen()
    }
  },
  destroyed() {
    this.timeline?.kill()
  },
  animateScreen() {
    const layers = this.el.querySelectorAll(
      ".hero-copy, .profile-form, .plan-intro, .ranked-row, .detail-column, .application-panel, .detail-layout > .trust-panel, .checklist-layout > .letter-panel",
    )

    this.timeline?.kill()
    gsap.killTweensOf(layers)

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      gsap.set(layers, {clearProps: "transform,opacity,visibility,willChange"})
      return
    }

    this.timeline = gsap
      .timeline()
      .set(layers, {willChange: "transform,opacity"})
      .fromTo(
        layers,
        {autoAlpha: 0, x: 28 * this.transitionDirection, y: 10},
        {
          autoAlpha: 1,
          x: 0,
          y: 0,
          duration: 0.5,
          ease: "power3.out",
          stagger: 0.06,
          clearProps: "transform,opacity,visibility,willChange",
        },
      )
  },
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, CopyLetter: copyLetterHook, ScreenTransition: screenTransitionHook},
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

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
