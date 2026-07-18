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
    |> render_submit()

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

    assert has_element?(view, ".readiness-meter span", "You're 2 of 4 ready.")

    view
    |> element("button[phx-value-id='income'][phx-value-status='have']")
    |> render_click()

    assert has_element?(view, ".readiness-meter span", "You're 3 of 4 ready.")

    view
    |> element("button[phx-click='draft_letter']")
    |> render_click()

    assert render(view) =~ "Drafting a live letter"

    send(view.pid, {:letter_drafted, {:ok, "A live letter for Ana."}})

    assert has_element?(view, "#request-letter-text", "A live letter for Ana.")
    assert has_element?(view, "#copy-request-letter[data-copy-target='request-letter-text']")
    assert render(view) =~ "Live OpenAI draft"
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
