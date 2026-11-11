class Mobile::BaseController < ApplicationController
  skip_before_action :sync_client_cache_version
  skip_before_action :set_paper_trail_whodunnit
  layout "mobile"

  private

  # Renders the Shell-First mount point for a mobile page. The response carries
  # no content: the page Stimulus controller names itself in data-controller and
  # hydrates from data-json-url. `action:` lets a failed create re-render the
  # new/show page shell instead of naming the create action.
  #
  # Docs: docs/MOBILE.md §2
  def render_mobile_shell(json_url:, data: {}, status: :ok, action: action_name)
    shell = helpers.tag.div(
      "",
      class: "min-h-dvh bg-background",
      data: { controller: mobile_stimulus_controller(action), json_url: json_url }.merge(data)
    )

    render html: shell, layout: true, status: status
  end

  # Same derivation as ApplicationHelper#stimulus_controller, so the mobile
  # shell can never drift from the JS file path.
  def mobile_stimulus_controller(action)
    [ controller_path.gsub("/", "--"), action.to_s ].join("--").dasherize
  end

  # Mobile pages are also served inside the Hotwire Native app, so signed-out
  # visitors must land on the mobile sign-in page instead of the marketing root.
  def authenticate
    redirect_to mobile_sign_in_path unless is_signed_in?
  end
end
