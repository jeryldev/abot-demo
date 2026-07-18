defmodule AbotDemoWeb.AbotLiveTest do
  use AbotDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "walks a student from ranked move to a request letter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "h1", "Start with your real situation.")
    assert has_element?(view, "#profile-intake")
    assert has_element?(view, "input[name='student[name]']")

    view
    |> form("#profile-intake",
      student: %{
        name: "Mika Santos",
        location: "Marikina City",
        course: "BS Computer Science",
        grade: "96"
      }
    )
    |> render_change()

    view
    |> element("button[phx-value-screen='plan']")
    |> render_click()

    assert render(view) =~ "Mika Santos, here are your 3 next moves"
    assert render(view) =~ "official-source tracker"
    assert render(view) =~ "2027 announced / verify RO"

    view
    |> element("button[phx-value-id='ched']")
    |> render_click()

    assert render(view) =~ "CHED Merit Scholarship Program (CMSP)"
    assert render(view) =~ "Filipino first-year applicants"

    view
    |> element("button.primary-button[phx-value-screen='checklist']")
    |> render_click()

    assert has_element?(view, ".requirements-list", "CHED CMSP application form")
    assert has_element?(view, ".readiness-meter span", "You're 0 of 1 ready.")

    view
    |> element("button[phx-value-id='requirement-1'][phx-value-status='have']")
    |> render_click()

    assert has_element?(view, ".readiness-meter span", "You're 1 of 1 ready.")

    view
    |> form(".letter-request-form", %{document: "PSA Birth Certificate"})
    |> render_submit()

    assert has_element?(view, ".letter-empty", "PSA Birth Certificate")

    send(view.pid, {:letter_drafted, {:ok, "A live letter for Ana."}})

    assert has_element?(view, "#request-letter-text", "A live letter for Ana.")
    assert has_element?(view, "#copy-request-letter[data-copy-target='request-letter-text']")
    assert render(view) =~ "Live OpenAI draft"
    assert has_element?(view, ".letter-panel h2", "PSA Birth Certificate")
  end

  test "changes readiness items when the selected tracker record changes", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("button[phx-value-screen='plan']")
    |> render_click()

    view
    |> element("button[phx-value-id='dost']")
    |> render_click()

    view
    |> element("button.primary-button[phx-value-screen='checklist']")
    |> render_click()

    assert has_element?(view, ".requirements-list", "E-application")
    assert has_element?(view, ".requirements-list", "school/grades documents")
    assert has_element?(view, ".readiness-meter span", "You're 0 of 3 ready.")
  end

  test "does not claim a correction reaches an external queue", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("button[phx-value-screen='detail']")
    |> render_click()

    view
    |> element("button[phx-click='report']")
    |> render_click()

    assert render(view) =~ "Correction marked for review in this demo."
  end

  test "labels the offline letter fallback honestly", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("button[phx-value-screen='checklist']")
    |> render_click()

    send(view.pid, {:letter_drafted, {:error, :missing_api_key}})

    assert has_element?(view, "#request-letter-text")
    assert render(view) =~ "Offline fallback draft."
  end
end
