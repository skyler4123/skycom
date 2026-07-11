class Companies::ShiftTemplatesController < Companies::ApplicationController
  feature_key :hrm_attendance

  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        scope = current_company.shift_templates
        @pagy, @results = pagy(:offset, scope, jsonapi: true)
        render json: { shift_templates: @results.map { |st| format_shift_template(st) }, pagination: @pagy.data_hash }
      end
    end
  end

  def show
    @shift_template = current_company.shift_templates.find(params[:id])
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json { render json: { shift_template: format_shift_template(@shift_template) } }
    end
  end

  def new
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def edit
    @shift_template = current_company.shift_templates.find(params[:id])
    respond_to { |f| f.html { render html: "", layout: true } }
  end

  def create
    st = current_company.shift_templates.new(shift_template_params)
    if st.save
      redirect_to company_shift_template_path(current_company, st), notice: "Shift template created"
    else
      redirect_to new_company_shift_template_path(current_company), alert: st.errors.full_messages.to_sentence
    end
  end

  def update
    st = current_company.shift_templates.find(params[:id])
    if st.update(shift_template_params)
      redirect_to company_shift_template_path(current_company, st), notice: "Updated"
    else
      redirect_to edit_company_shift_template_path(current_company, st), alert: st.errors.full_messages.to_sentence
    end
  end

  private

  def shift_template_params
    params.require(:shift_template).permit(:name, :start_time, :end_time, :grace_period_minutes, :unpaid_break_minutes, :description, :branch_id)
  end

  def format_shift_template(st)
    st.as_json(only: %i[id name start_time end_time grace_period_minutes unpaid_break_minutes description created_at])
  end
end
