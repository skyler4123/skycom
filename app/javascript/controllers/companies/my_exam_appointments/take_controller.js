import { Controller } from "@hotwired/stimulus"

export default class Companies_MyExamAppointments_TakeController extends Controller {
  // Full-screen timed attempt page.
  // Depends on BE: Companies::MyExamAppointmentsController#take/#answer/#submit
  // Endpoints: GET .../take.json, PATCH .../answer, POST .../submit
  // Docs: docs/EXAMS.md

  appointment = null
  exam = null
  questions = []
  currentIndex = 0
  answers = {}
  remainingSeconds = null
  timer = null
  saveTimers = {}
  submitted = false

  async connect() {
    try {
      const response = await fetchJson()

      if (response.redirect_url) {
        window.location.href = response.redirect_url
        return
      }

      this.appointment = response.appointment
      this.exam = response.exam
      this.questions = response.questions || []
      this.remainingSeconds = response.remaining_seconds
      this.questions.forEach(question => {
        this.answers[question.id] = {
          selected_option_ids: [ ...(question.selected_option_ids || []) ],
          text_answer: question.text_answer || ""
        }
      })

      this.render()
      this.startTimer()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load exam attempt")}${detail ? ": " + detail : ""}` })
    }
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
    Object.values(this.saveTimers).forEach(timer => clearTimeout(timer))
  }

  companyId() {
    return currentCompany()?.id
  }

  currentQuestion() {
    return this.questions[this.currentIndex]
  }

  answerFor(question) {
    return this.answers[question.id] || { selected_option_ids: [], text_answer: "" }
  }

  optionMap(question) {
    return (question.options || []).reduce((result, option) => {
      result[option.id] = option
      return result
    }, {})
  }

  displayOptions(question) {
    const map = this.optionMap(question)
    return (question.option_order || []).map(id => map[id]).filter(Boolean)
  }

  answeredCount() {
    return this.questions.filter(question => {
      const answer = this.answerFor(question)
      return (answer.selected_option_ids || []).length > 0 || Boolean(answer.text_answer?.trim())
    }).length
  }

  startTimer() {
    if (this.remainingSeconds === null || this.remainingSeconds === undefined) return

    this.timer = setInterval(() => {
      this.remainingSeconds = Math.max(0, this.remainingSeconds - 1)
      this.updateTimer()
      if (this.remainingSeconds === 0) {
        clearInterval(this.timer)
        this.autoSubmit()
      }
    }, 1000)
  }

  formatTime(seconds) {
    if (seconds === null || seconds === undefined) return translate("No time limit")
    const minutes = Math.floor(seconds / 60)
    const remainder = seconds % 60
    return `${String(minutes).padStart(2, "0")}:${String(remainder).padStart(2, "0")}`
  }

  updateTimer() {
    const element = this.element.querySelector("[data-take-timer]")
    if (element) element.textContent = this.formatTime(this.remainingSeconds)
  }

  updateProgress() {
    const answered = this.element.querySelector("[data-take-answered]")
    if (answered) answered.textContent = this.answeredCount()

    this.renderNavigator()
  }

  render() {
    this.element.innerHTML = this.contentHTML()
  }

  renderNavigator() {
    const navigator = this.element.querySelector("[data-take-navigator]")
    if (navigator) navigator.innerHTML = this.navigatorHTML()
  }

  navigatorHTML() {
    return this.questions.map((question, index) => {
      const answered = this.answeredCountFor(question)
      const current = index === this.currentIndex
      const classes = current
        ? "bg-primary text-primary-foreground border-primary"
        : answered
          ? "bg-success/10 text-success border-success/40"
          : "bg-card text-foreground border-line hover:bg-muted"

      return `
        <button type="button" data-action="click->${this.identifier}#goToQuestion" data-index="${index}"
          class="flex h-9 w-9 items-center justify-center rounded-lg border text-sm font-bold ${classes}">
          ${index + 1}
        </button>
      `
    }).join("")
  }

  answeredCountFor(question) {
    const answer = this.answerFor(question)
    return (answer.selected_option_ids || []).length > 0 || Boolean(answer.text_answer?.trim())
  }

  optionInputHTML(question, option, index) {
    const answer = this.answerFor(question)
    const selected = (answer.selected_option_ids || []).map(String).includes(String(option.id))
    const label = String.fromCharCode(65 + index)

    return `
      <label class="flex cursor-pointer items-start gap-3 rounded-lg border ${selected ? "border-primary bg-primary/10" : "border-line bg-card"} p-3 hover:bg-muted/50">
        <input type="radio" name="question-${question.id}" value="${option.id}" ${selected ? "checked" : ""}
          data-action="change->${this.identifier}#selectOption"
          data-answer-id="${question.id}" data-option-id="${option.id}"
          class="mt-1 h-4 w-4 cursor-pointer">
        <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-bold text-foreground">${label}</span>
        <span class="min-w-0 flex-1 text-sm text-foreground">${escapeHtml(option.content)}</span>
      </label>
    `
  }

  questionCardHTML() {
    const question = this.currentQuestion()
    if (!question) return `<p class="p-6 text-sm text-muted-foreground">${translate("This exam has no questions.")}</p>`

    const answer = this.answerFor(question)
    const isText = question.question_type === "text"

    return `
      <div class="rounded-xl border border-line bg-card p-5">
        <div class="mb-4 flex items-center justify-between gap-3">
          <span class="text-xs font-bold uppercase tracking-wider text-muted-foreground">
            ${translate("Question")} ${this.currentIndex + 1} / ${this.questions.length}
          </span>
          <span class="text-xs text-muted-foreground">${question.question_type === "true_false" ? translate("True / False") : isText ? translate("Text answer") : translate("Single choice")}</span>
        </div>

        <h3 class="text-base font-bold text-foreground">${escapeHtml(question.name)}</h3>
        ${question.description ? `<p class="mt-2 text-sm text-muted-foreground">${escapeHtml(question.description)}</p>` : ""}

        <div class="mt-5 space-y-2">
          ${isText
            ? `<textarea rows="6" data-action="input->${this.identifier}#onTextInput" data-answer-id="${question.id}"
                 class="w-full rounded-lg border border-line bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                 placeholder="${translate("Write your answer...")}">${escapeHtml(answer.text_answer || "")}</textarea>`
            : this.displayOptions(question).map((option, index) => this.optionInputHTML(question, option, index)).join("")
          }
        </div>
      </div>
    `
  }

  contentHTML() {
    const unanswered = this.questions.length - this.answeredCount()

    return `
      <div class="min-h-screen bg-background text-foreground">
        <header class="sticky top-0 z-10 border-b border-line bg-card">
          <div class="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3">
            <div class="min-w-0">
              <h1 class="truncate text-base font-bold text-foreground">${escapeHtml(this.exam?.name || translate("Exam"))}</h1>
              <p class="text-xs text-muted-foreground">${translate("Attempt")} #${this.appointment?.attempt_number || 1}</p>
            </div>
            <div class="flex flex-wrap items-center gap-3">
              <div class="rounded-lg border border-line bg-background px-3 py-1.5 text-center">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Time Remaining")}</p>
                <p class="text-sm font-bold text-foreground" data-take-timer>${this.formatTime(this.remainingSeconds)}</p>
              </div>
              <div class="rounded-lg border border-line bg-background px-3 py-1.5 text-center">
                <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Answered")}</p>
                <p class="text-sm font-bold text-foreground"><span data-take-answered>${this.answeredCount()}</span> / ${this.questions.length}</p>
              </div>
              <button type="button" data-action="click->${this.identifier}#submitExam"
                class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
                <span class="material-symbols-outlined text-[18px]!">send</span>${translate("Submit Exam")}
              </button>
            </div>
          </div>
        </header>

        <main class="mx-auto grid max-w-6xl grid-cols-1 gap-4 px-4 py-4 lg:grid-cols-[1fr_240px]">
          <div class="space-y-4">
            ${this.questionCardHTML()}

            <div class="flex items-center justify-between gap-3">
              <button type="button" data-action="click->${this.identifier}#previousQuestion" ${this.currentIndex === 0 ? "disabled" : ""}
                class="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-40">
                <span class="material-symbols-outlined text-[18px]!">chevron_left</span>${translate("Previous")}
              </button>
              <span class="text-xs text-muted-foreground" data-take-save-status></span>
              <button type="button" data-action="click->${this.identifier}#nextQuestion" ${this.currentIndex === this.questions.length - 1 ? "disabled" : ""}
                class="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-40">
                ${translate("Next")}<span class="material-symbols-outlined text-[18px]!">chevron_right</span>
              </button>
            </div>
          </div>

          <aside class="space-y-3">
            <div class="rounded-xl border border-line bg-card p-3">
              <p class="mb-2 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Questions")}</p>
              <div class="flex flex-wrap gap-2" data-take-navigator>${this.navigatorHTML()}</div>
            </div>
            <div class="rounded-xl border border-line bg-card p-3 text-xs text-muted-foreground">
              <p>${translate("Answered questions are green. You can move between questions freely.")}</p>
              ${unanswered > 0 ? `<p class="mt-2 font-medium text-warning">${unanswered} ${translate("unanswered")}</p>` : ""}
            </div>
          </aside>
        </main>
      </div>
    `
  }

  selectOption(event) {
    const answerId = event.currentTarget.dataset.answerId
    const optionId = event.currentTarget.dataset.optionId
    this.answers[answerId] = { ...(this.answers[answerId] || {}), selected_option_ids: [ optionId ] }
    this.render()
    this.scheduleSave(answerId)
  }

  onTextInput(event) {
    const answerId = event.currentTarget.dataset.answerId
    this.answers[answerId] = { ...(this.answers[answerId] || {}), text_answer: event.currentTarget.value }
    this.updateProgress()
    this.scheduleSave(answerId)
  }

  scheduleSave(answerId) {
    clearTimeout(this.saveTimers[answerId])
    this.saveTimers[answerId] = setTimeout(() => this.saveAnswer(answerId), 600)
  }

  async saveAnswer(answerId) {
    const answer = this.answers[answerId] || { selected_option_ids: [], text_answer: "" }
    const status = this.element.querySelector("[data-take-save-status]")
    if (status) status.textContent = translate("Saving...")

    try {
      await fetchJson(Helpers.answer_company_my_exam_appointment_path(this.companyId(), this.appointment.id), {
        method: "PATCH",
        body: {
          answer_id: answerId,
          selected_option_ids: answer.selected_option_ids || [],
          text_answer: answer.text_answer || ""
        }
      })
      if (status) status.textContent = translate("Saved")
      this.updateProgress()
    } catch (error) {
      if (error.errors?.includes("Time is up.")) {
        window.location.href = Helpers.company_my_exam_appointment_path(this.companyId(), this.appointment.id)
        return
      }
      if (status) status.textContent = ""
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  goToQuestion(event) {
    this.currentIndex = Number(event.currentTarget.dataset.index)
    this.render()
  }

  previousQuestion() {
    if (this.currentIndex <= 0) return
    this.currentIndex -= 1
    this.render()
  }

  nextQuestion() {
    if (this.currentIndex >= this.questions.length - 1) return
    this.currentIndex += 1
    this.render()
  }

  answersPayload() {
    return this.questions.map(question => {
      const answer = this.answerFor(question)
      return {
        id: question.id,
        selected_option_ids: answer.selected_option_ids || [],
        text_answer: answer.text_answer || ""
      }
    })
  }

  async submitExam() {
    if (this.submitted) return

    const unanswered = this.questions.length - this.answeredCount()
    const result = await Helpers.confirmAction({
      title: translate("Submit exam?"),
      text: unanswered > 0
        ? `${unanswered} ${translate("questions are unanswered. You can still submit.")}`
        : translate("You cannot change your answers after submitting."),
      confirmButtonText: translate("Submit"),
      cancelButtonText: translate("Cancel")
    })
    if (!result.isConfirmed) return

    await this.performSubmit()
  }

  async autoSubmit() {
    if (this.submitted) return
    toast({ type: "warning", message: translate("Time is up. Submitting your exam...") })
    await this.performSubmit()
  }

  async performSubmit() {
    this.submitted = true
    if (this.timer) clearInterval(this.timer)

    try {
      const response = await fetchJson(Helpers.submit_company_my_exam_appointment_path(this.companyId(), this.appointment.id), {
        method: "POST",
        body: { answers: this.answersPayload() }
      })
      navigateThenToast(response.redirect_url, { type: "success", message: response.message })
    } catch (error) {
      if (error.redirect_url) {
        navigateThenToast(error.redirect_url, { type: "error", message: error.errors?.join(", ") || error.message })
      } else {
        this.submitted = false
        toast({ type: "error", message: error.errors?.join(", ") || error.message })
      }
    }
  }
}
