class PatentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_patent, only: [:show, :sync]

  def index
    @patents = current_user.patents.includes(:annual_fees, :patent_documents, :patent_status_events)
    
    # Filtering
    @patents = @patents.by_status(params[:status]) if params[:status].present?
    @patents = @patents.where('title_ko ILIKE ? OR title_en ILIKE ? OR application_number ILIKE ?', 
                             "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    # Sorting
    case params[:sort]
    when 'filing_date'
      @patents = @patents.order(filing_date: :desc)
    when 'grant_date'
      @patents = @patents.order(grant_date: :desc)
    when 'status'
      @patents = @patents.order(:current_status)
    else
      @patents = @patents.order(updated_at: :desc)
    end

    @patents = @patents.page(params[:page]).per(20)

    # Export functionality
    respond_to do |format|
      format.html
      format.xlsx do
        response.headers['Content-Disposition'] = 'attachment; filename="patents_export.xlsx"'
      end
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="patents_export.csv"'
      end
    end
  end

  def show
    @annual_fees = @patent.annual_fees.order(:year_no)
    @status_events = @patent.patent_status_events.recent.limit(10)
    @documents = @patent.patent_documents.order(:doc_type)
    @recent_payments = FeePayment.joins(:annual_fee)
                                 .where(annual_fees: { patent_id: @patent.id })
                                 .recent
                                 .limit(5)
  end

  def sync
    if current_user.customer_number.present?
      sync_job = SyncJob.create_user_sync(current_user, 'delta_user')
      KiprisSyncJob.perform_later(sync_job.id)
      
      redirect_to @patent, notice: '특허 정보 동기화가 시작되었습니다.'
    else
      redirect_to @patent, alert: '고객번호가 설정되지 않아 동기화할 수 없습니다.'
    end
  end

  private

  def set_patent
    @patent = current_user.patents.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to patents_path, alert: '접근 권한이 없습니다.'
  end

  def patent_params
    params.require(:patent).permit(:title_ko, :title_en, :current_status)
  end
end