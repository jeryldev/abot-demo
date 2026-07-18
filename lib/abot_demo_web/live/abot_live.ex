defmodule AbotDemoWeb.AbotLive do
  use AbotDemoWeb, :live_view

  @student %{
    name: "Ana Reyes",
    level: "Grade 12, graduating SY 2025-26",
    intake: "Incoming college AY 2026-27",
    location: "Quezon City",
    course: "BS Information Technology",
    grade: "94",
    income: "220000",
    school: "Public senior high school",
    situation: "At risk of not enrolling without financial support"
  }

  @opportunities [
    %{
      id: "ched",
      rank: "1",
      program: "CHED Merit Scholarship",
      full_name: "CHED Merit Scholarship Program (CMSP)",
      kind: "Scholarship",
      provider: "Commission on Higher Education (CHED)",
      chip: "Due soon · 31 Jul",
      chip_style: "chip chip-amber",
      status: "Open - apply by 31 Jul 2026",
      verification: "official source",
      checked: "18 Jul 2026",
      source: "ched.gov.ph / regional CHED offices",
      fit:
        "94% average clears the 93% GWA minimum, IT is a priority course, income within the need band.",
      blocker: "Needs >=93% GWA (you're at 94%) and priority-course enrolment.",
      detail_blockers: [
        "needs >=93% GWA (you're at 94%)",
        "CHED priority-course enrolment",
        "can't hold another government scholarship"
      ],
      note:
        "Open in multiple regional CHED offices; central/legacy pages may lag - we show the discrepancy, not a guess.",
      action: "Prepare this application"
    },
    %{
      id: "dost",
      rank: "2",
      program: "DOST-SEI Undergraduate (S&T)",
      full_name: "DOST-SEI Undergraduate Scholarship (S&T)",
      kind: "Scholarship",
      provider: "DOST - Science Education Institute",
      chip: "Opens next cycle",
      chip_style: "chip chip-blue",
      status: "Closed now - next cycle ~Oct 2026",
      verification: "official source",
      checked: "18 Jul 2026",
      source: "science-scholarships.ph",
      fit: "Full S&T scholarship, IT qualifies, your income fits the RA 7687 track.",
      blocker: "You'll need to pass the DOST exam (~Feb). Start prepping now.",
      detail_blockers: ["must sit and pass the DOST-SEI exam", "next cycle opens ~Oct 2026"],
      note: "The 2026 cycle is over; this is a prepare-now path for the next application window.",
      action: "Add to my next-cycle plan"
    },
    %{
      id: "bagong",
      rank: "3",
      program: "\"Bagong Pilipinas Merit Scholarship\"",
      full_name: "\"Bagong Pilipinas Merit Scholarship\"",
      kind: "Claimed scholarship",
      provider: "Claimed government-linked",
      chip: "Flagged",
      chip_style: "chip chip-flagged",
      status: "We couldn't verify this.",
      verification: "sources conflict",
      checked: "18 Jul 2026",
      source: "Aggregator sites only",
      fit: "Unknown - cannot assess until confirmed.",
      blocker: "Existence and terms are unconfirmed.",
      detail_blockers: ["existence unconfirmed", "terms unconfirmed", "deadline unknown"],
      note:
        "It appears on scholarship websites, but we could not confirm it on an official source. We won't recommend action until we can.",
      action: "Why is this flagged?"
    }
  ]

  @requirements [
    %{id: "cards", label: "Grade 11 & Grade 12 (1st sem) report cards"},
    %{
      id: "income",
      label: "Proof of income (ITR, Barangay Certificate of Indigency, or tax exemption)"
    },
    %{id: "form", label: "Application form"},
    %{id: "enrolment", label: "Proof of enrolment / acceptance"}
  ]

  @initial_readiness %{
    "cards" => "have",
    "income" => "request",
    "form" => "have",
    "enrolment" => "not_sure"
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Abot",
       screen: :intake,
       student: @student,
       opportunities: @opportunities,
       selected_id: "ched",
       requirements: @requirements,
       readiness: @initial_readiness,
       toast: nil,
       copied: false,
       letter_open: false,
       letter: fallback_letter(@student),
       letter_status: :idle
     )}
  end

  @impl true
  def handle_event("go", %{"screen" => screen} = params, socket) do
    socket = update_student(socket, Map.get(params, "student", %{}))
    {:noreply, assign(socket, screen: String.to_existing_atom(screen), toast: nil)}
  end

  def handle_event("update_profile", %{"student" => student}, socket) do
    {:noreply, update_student(socket, student)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_id: id, screen: :detail, toast: nil)}
  end

  def handle_event("report", _params, socket) do
    toast =
      "Correction marked for review in this demo. A production release would send this listing and its source to a verifier."

    {:noreply, assign(socket, toast: toast)}
  end

  def handle_event("set_req", %{"id" => id, "status" => status}, socket) do
    {:noreply, assign(socket, readiness: Map.put(socket.assigns.readiness, id, status))}
  end

  def handle_event("copy", _params, socket) do
    {:noreply,
     assign(socket,
       copied: true,
       toast: "Letter copied for #{socket.assigns.student.name}'s application packet."
     )}
  end

  def handle_event("copy_failed", _params, socket) do
    {:noreply,
     assign(socket,
       copied: false,
       toast: "Your browser blocked clipboard access. Select the letter and copy it manually."
     )}
  end

  def handle_event("draft_letter", _params, socket) do
    caller = self()

    Task.start(fn ->
      result =
        AbotDemo.OpenAI.draft_request_letter(%{
          student: socket.assigns.student,
          scholarship: "CHED Merit Scholarship",
          document: "Barangay Certificate of Indigency",
          deadline: "31 July 2026"
        })

      send(caller, {:letter_drafted, result})
    end)

    {:noreply,
     assign(socket, letter_open: false, letter_status: :drafting, copied: false, toast: nil)}
  end

  @impl true
  def handle_info({:letter_drafted, {:ok, letter}}, socket) do
    {:noreply,
     assign(socket,
       letter: letter,
       letter_open: true,
       letter_status: :generated,
       toast: "Live OpenAI draft ready for #{socket.assigns.student.name} to review."
     )}
  end

  def handle_info({:letter_drafted, {:error, _reason}}, socket) do
    {:noreply,
     assign(socket,
       letter: fallback_letter(socket.assigns.student),
       letter_open: true,
       letter_status: :fallback,
       toast: "Live drafting is unavailable, so Abot prepared its offline fallback."
     )}
  end

  defp selected(assigns) do
    Enum.find(assigns.opportunities, &(&1.id == assigns.selected_id))
  end

  defp update_student(socket, updates) do
    permitted_updates =
      updates
      |> Map.take(Enum.map(Map.keys(@student), &Atom.to_string/1))
      |> Map.new(fn {key, value} -> {String.to_existing_atom(key), value} end)

    assign(socket, :student, Map.merge(socket.assigns.student, permitted_updates))
  end

  defp ready_count(readiness) do
    readiness
    |> Map.values()
    |> Enum.count(&(&1 == "have"))
  end

  defp step_class(current, step) do
    if current == step, do: "nav-step active", else: "nav-step"
  end

  defp status_label("have"), do: "I have this"
  defp status_label("request"), do: "I need to request this"
  defp status_label("not_sure"), do: "Not sure"

  defp option_class(current, value) do
    if current == value, do: "toggle-option selected", else: "toggle-option"
  end

  defp fallback_letter(student) do
    """
    To the Office of the Barangay Captain,

    I am #{student.name}, a #{student.level} student and resident of #{student.location}, applying for the CHED Merit Scholarship. I respectfully request a Barangay Certificate of Indigency to complete my application, which is due 31 July 2026.

    Thank you for your kind assistance.

    Respectfully,
    #{student.name}
    """
  end

  defp format_income(income) do
    income
    |> String.replace(~r/\D/, "")
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map_join(",", &Enum.join/1)
    |> String.reverse()
  end

  defp blockers_for(%{id: "ched"}, student) do
    [
      "minimum: >=93% GWA (you entered #{student.grade}%)",
      "CHED priority-course enrolment",
      "can't hold another government scholarship"
    ]
  end

  defp blockers_for(selected, _student), do: selected.detail_blockers

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :selected, selected(assigns))
    assigns = assign(assigns, :ready_count, ready_count(assigns.readiness))

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="editorial-page">
        <header class="editorial-topbar">
          <div class="editorial-brand">
            <p class="brand-name">Abot.</p>
            <div>
              <p class="product-line">
                Know what to trust, what you qualify for, and what to do before the deadline.
              </p>
            </div>
          </div>
          <nav class="editorial-nav" aria-label="Demo steps">
            <button
              class={step_class(@screen, :intake)}
              phx-click="go"
              phx-value-screen="intake"
              aria-label="Profile"
              title="Profile"
            >
              <span class="nav-index">01</span><span class="nav-label">Profile</span>
              <.icon name="hero-user-mini" class="nav-icon size-4" />
            </button>
            <button
              class={step_class(@screen, :plan)}
              phx-click="go"
              phx-value-screen="plan"
              aria-label="Next moves"
              title="Next moves"
            >
              <span class="nav-index">02</span><span class="nav-label">Next moves</span>
              <.icon name="hero-arrow-trending-up-mini" class="nav-icon size-4" />
            </button>
            <button
              class={step_class(@screen, :detail)}
              phx-click="go"
              phx-value-screen="detail"
              aria-label="Trust details"
              title="Trust details"
            >
              <span class="nav-index">03</span><span class="nav-label">Trust</span>
              <.icon name="hero-shield-check-mini" class="nav-icon size-4" />
            </button>
            <button
              class={step_class(@screen, :checklist)}
              phx-click="go"
              phx-value-screen="checklist"
              aria-label="Checklist"
              title="Checklist"
            >
              <span class="nav-index">04</span><span class="nav-label">Checklist</span>
              <.icon name="hero-clipboard-document-check-mini" class="nav-icon size-4" />
            </button>
          </nav>
        </header>

        <main class="editorial-workspace">
          <section id="screen-stage" phx-hook="ScreenTransition" data-screen={@screen}>
            <%= if @toast do %>
              <div class="toast-line" role="status">
                <.icon name="hero-check-circle-mini" class="size-5" />
                <span>{@toast}</span>
              </div>
            <% end %>

            <%= case @screen do %>
              <% :intake -> %>
                <.intake student={@student} />
              <% :plan -> %>
                <.plan opportunities={@opportunities} student={@student} />
              <% :detail -> %>
                <.detail selected={@selected} student={@student} />
              <% :checklist -> %>
                <.checklist
                  requirements={@requirements}
                  readiness={@readiness}
                  ready_count={@ready_count}
                  letter={@letter}
                  letter_open={@letter_open}
                  copied={@copied}
                  letter_status={@letter_status}
                  student={@student}
                />
            <% end %>
          </section>
        </main>
      </div>
    </Layouts.app>
    """
  end

  attr :student, :map, required: true

  def intake(assigns) do
    ~H"""
    <div class="screen-grid intake-screen">
      <section class="hero-panel">
        <div class="hero-copy">
          <p class="small-label">Profile intake</p>
          <h1>Start with your real situation.</h1>
          <p>
            Tell Abot what you have, where you are, and what could get in the way. We'll show what fits, what is open, and what to prepare - without pretending to know what we cannot verify.
          </p>
        </div>

        <form id="profile-intake" class="profile-form" phx-change="update_profile" phx-submit="go">
          <input type="hidden" name="screen" value="plan" />
          <div class="profile-form-heading">
            <p class="small-label">Your details</p>
            <span>Step 1 of 4</span>
          </div>

          <div class="profile-fields">
            <label class="profile-field full">
              <span>Name</span>
              <input name="student[name]" type="text" value={@student.name} required />
            </label>
            <label class="profile-field">
              <span>Level</span>
              <select name="student[level]">
                <option selected={@student.level == "Grade 12, graduating SY 2025-26"}>
                  Grade 12, graduating SY 2025-26
                </option>
                <option selected={@student.level == "Grade 11"}>Grade 11</option>
                <option selected={@student.level == "College applicant"}>College applicant</option>
              </select>
            </label>
            <label class="profile-field">
              <span>Location</span>
              <input name="student[location]" type="text" value={@student.location} required />
            </label>
            <label class="profile-field full">
              <span>Intended course</span>
              <input name="student[course]" type="text" value={@student.course} required />
            </label>
            <label class="profile-field">
              <span>General average</span>
              <div class="input-affix">
                <input
                  name="student[grade]"
                  type="number"
                  min="0"
                  max="100"
                  step="0.1"
                  value={@student.grade}
                  required
                />
                <span>%</span>
              </div>
            </label>
            <label class="profile-field">
              <span>Household income</span>
              <div class="input-affix">
                <span>PHP</span>
                <input
                  name="student[income]"
                  type="number"
                  min="0"
                  step="1000"
                  value={@student.income}
                  required
                />
              </div>
            </label>
            <label class="profile-field">
              <span>School type</span>
              <select name="student[school]">
                <option selected={@student.school == "Public senior high school"}>
                  Public senior high school
                </option>
                <option selected={@student.school == "Private senior high school"}>
                  Private senior high school
                </option>
                <option selected={@student.school == "Alternative learning system"}>
                  Alternative learning system
                </option>
              </select>
            </label>
            <label class="profile-field">
              <span>Situation</span>
              <select name="student[situation]">
                <option selected={
                  @student.situation == "At risk of not enrolling without financial support"
                }>
                  At risk of not enrolling without financial support
                </option>
                <option selected={@student.situation == "Needs financial support to stay enrolled"}>
                  Needs financial support to stay enrolled
                </option>
                <option selected={@student.situation == "Looking for additional financial support"}>
                  Looking for additional financial support
                </option>
              </select>
            </label>
          </div>

          <button class="primary-button profile-submit" type="submit">
            Show my moves <.icon name="hero-arrow-right-mini" class="size-5" />
          </button>
        </form>
      </section>
    </div>
    """
  end

  attr :opportunities, :list, required: true
  attr :student, :map, required: true

  def plan(assigns) do
    ~H"""
    <div class="plan-layout editorial-plan">
      <section class="plan-intro">
        <p class="small-label">02 / Ranked action plan</p>
        <h1>{@student.name}, here are your 3 next moves</h1>
        <p>Ranked by what to do first.</p>
        <div class="trust-strip">
          Abot refuses to pretend — 1 open, 1 for next cycle, 1 we couldn't verify.
        </div>
      </section>

      <section class="ranked-rows" aria-label="Ranked scholarship actions">
        <%= for item <- @opportunities do %>
          <article class={"ranked-row #{if item.id == "bagong", do: "flagged", else: ""}"}>
            <div class="rank">{item.rank}</div>
            <div class="row-main">
              <div class="row-heading">
                <div>
                  <h2>{item.program}</h2>
                  <p>{item.kind}</p>
                </div>
                <span class={item.chip_style}>{item.chip}</span>
              </div>

              <%= if item.id == "ched" do %>
                <p class="row-line">
                  Profile basis: {@student.grade}% average · {@student.course} · PHP {format_income(
                    @student.income
                  )} household income
                </p>
                <p class="source-line">official source · checked 18 Jul 2026</p>
              <% end %>

              <%= if item.id == "dost" do %>
                <p class="row-line">Closed now, opens ~Oct 2026 · prep for the Feb exam</p>
                <p class="source-line">official source · checked 18 Jul 2026</p>
              <% end %>

              <%= if item.id == "bagong" do %>
                <p class="row-line">
                  Shows up on scholarship sites, but we couldn't confirm it on an official source. We won't tell you to act on it yet.
                </p>
                <p class="source-line">sources conflict · checked 18 Jul 2026</p>
              <% end %>
            </div>

            <div class="row-action">
              <%= cond do %>
                <% item.id == "ched" -> %>
                  <button class="primary-button" phx-click="select" phx-value-id={item.id}>
                    Prepare application
                  </button>
                <% item.id == "dost" -> %>
                  <button class="secondary-button" phx-click="select" phx-value-id={item.id}>
                    Add to plan
                  </button>
                <% true -> %>
                  <button class="quiet-link" phx-click="select" phx-value-id={item.id}>
                    Why is this flagged?
                  </button>
              <% end %>
            </div>
          </article>
        <% end %>
      </section>

      <aside class="detail-column">
        <.trust_panel selected={List.first(@opportunities)} />
      </aside>
    </div>
    """
  end

  attr :selected, :map, required: true
  attr :student, :map, required: true

  def detail(assigns) do
    ~H"""
    <div class="detail-layout">
      <section class="application-panel">
        <p class="small-label">Match detail</p>
        <h1>{@selected.full_name}</h1>
        <p class="muted">{@selected.provider}</p>

        <div class="reason-grid">
          <div>
            <h2>Profile facts considered</h2>
            <ul class="check-list">
              <li><.icon name="hero-check-mini" class="size-5" /> {@student.level}</li>
              <li>
                <.icon name="hero-check-mini" class="size-5" /> {@student.course} intended course
              </li>
              <li>
                <.icon name="hero-check-mini" class="size-5" /> {@student.grade}% general average provided
              </li>
            </ul>
          </div>
          <div>
            <h2>What could block you</h2>
            <ul class="plain-list">
              <%= for blocker <- blockers_for(@selected, @student) do %>
                <li>{blocker}</li>
              <% end %>
            </ul>
          </div>
        </div>

        <div class="button-row">
          <button class="primary-button" phx-click="go" phx-value-screen="checklist">
            Build my checklist <.icon name="hero-arrow-right-mini" class="size-5" />
          </button>
          <button class="ghost-button" phx-click="report">
            Confirm listing / Report correction
          </button>
        </div>
      </section>

      <.trust_panel selected={@selected} />
    </div>
    """
  end

  attr :selected, :map, required: true

  def trust_panel(assigns) do
    ~H"""
    <section class="trust-panel">
      <div class="panel-title">
        <.icon name="hero-shield-check-mini" class="size-5" />
        <h2>Trust details</h2>
      </div>
      <dl>
        <div>
          <dt>Status</dt><dd><span class="chip chip-green">{@selected.status}</span></dd>
        </div>
        <div>
          <dt>Verification</dt><dd>{@selected.verification}</dd>
        </div>
        <div>
          <dt>Checked</dt><dd>{@selected.checked}</dd>
        </div>
        <div>
          <dt>Source</dt><dd>{@selected.source}</dd>
        </div>
        <div>
          <dt>Note</dt><dd>{@selected.note}</dd>
        </div>
      </dl>
      <p class="guide-note">Abot is a guide; the official provider makes the final decision.</p>
    </section>
    """
  end

  attr :requirements, :list, required: true
  attr :readiness, :map, required: true
  attr :ready_count, :integer, required: true
  attr :letter, :string, required: true
  attr :letter_open, :boolean, required: true
  attr :copied, :boolean, required: true
  attr :letter_status, :atom, required: true
  attr :student, :map, required: true

  def checklist(assigns) do
    ~H"""
    <div class="checklist-layout">
      <section class="application-panel">
        <div class="screen-heading compact">
          <p class="small-label">04 / Readiness checklist</p>
          <h1>What you'll need for CHED Merit</h1>
          <p>Use simple readiness toggles. No uploads needed.</p>
        </div>

        <div class="readiness-meter">
          <span>You're {@ready_count} of 4 ready.</span>
          <div><i style={"width: #{@ready_count * 25}%"}></i></div>
        </div>

        <div class="requirements-list">
          <%= for req <- @requirements do %>
            <% current = Map.fetch!(@readiness, req.id) %>
            <article class="requirement-row">
              <div>
                <strong>{req.label}</strong>
                <small>{status_label(current)}</small>
              </div>
              <div class="toggle-group">
                <button
                  class={option_class(current, "have")}
                  phx-click="set_req"
                  phx-value-id={req.id}
                  phx-value-status="have"
                >I have this</button>
                <button
                  class={option_class(current, "request")}
                  phx-click="set_req"
                  phx-value-id={req.id}
                  phx-value-status="request"
                >I need to request this</button>
                <button
                  class={option_class(current, "not_sure")}
                  phx-click="set_req"
                  phx-value-id={req.id}
                  phx-value-status="not_sure"
                >Not sure</button>
              </div>
            </article>
          <% end %>
        </div>

        <div class="callout">
          <.icon name="hero-document-text-mini" class="size-5" />
          <span>Need a request letter? Abot can make a live draft from {@student.name}'s profile, or use its offline fallback when the connection is unavailable.</span>
        </div>

        <button class="primary-button" phx-click="draft_letter" disabled={@letter_status == :drafting}>
          {if @letter_status == :drafting, do: "Drafting letter...", else: "Draft my request letter"}
        </button>
      </section>

      <section class="letter-panel">
        <p class="small-label">Request letter</p>
        <h2>Barangay Certificate of Indigency</h2>
        <%= if @letter_status == :drafting do %>
          <p class="letter-empty">
            Drafting a live letter from {@student.name}'s profile and the missing document...
          </p>
        <% end %>
        <%= if @letter_open do %>
          <textarea id="request-letter-text" class="letter-box"><%= @letter %></textarea>
          <p class="letter-origin">
            {if @letter_status == :generated,
              do: "Live OpenAI draft. Review and edit it before sending.",
              else: "Offline fallback draft. Add an API key to generate a live version."}
          </p>
          <div class="button-row">
            <button
              id="copy-request-letter"
              class="primary-button"
              type="button"
              phx-hook="CopyLetter"
              data-copy-target="request-letter-text"
            >
              Copy
            </button>
            <button class="secondary-button" phx-click="go" phx-value-screen="plan">Back to plan</button>
          </div>
          <%= if @copied do %>
            <p class="copy-note">Copied into {@student.name}'s application packet for this demo.</p>
          <% end %>
        <% else %>
          <p class="letter-empty">
            A request letter appears here after you choose to draft it.
          </p>
        <% end %>
      </section>
    </div>
    """
  end

  attr :letter, :string, required: true
  attr :copied, :boolean, required: true

  def letter(assigns) do
    ~H"""
    <div class="letter-layout">
      <section class="application-panel">
        <p class="small-label">Generated request letter</p>
        <h1>Ready to send - a request for your Barangay Certificate of Indigency</h1>
        <textarea id="generated-letter-text" class="letter-box"><%= @letter %></textarea>
        <div class="button-row">
          <button
            id="copy-generated-letter"
            class="primary-button"
            type="button"
            phx-hook="CopyLetter"
            data-copy-target="generated-letter-text"
          >
            <.icon name="hero-clipboard-document-mini" class="size-5" /> Copy
          </button>
          <button class="secondary-button">Edit</button>
          <button class="ghost-button" phx-click="go" phx-value-screen="plan">Back to my plan</button>
        </div>
        <%= if @copied do %>
          <p class="copy-note">Copied into Ana's application packet for this demo.</p>
        <% end %>
      </section>
      <section class="mini-panel close-panel">
        <h2>That's the loop.</h2>
        <p>Find what fits -> see what's open -> prepare what's missing -> act before the deadline.</p>
      </section>
    </div>
    """
  end
end
