class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @patents_summary = current_user.patent_summary
    @recent_patents = current_user.patents.includes(:annual_fees, :patent_documents)
                                          .order(updated_at: :desc)
                                          .limit(10)
    
    @overdue_fees = current_user.overdue_fees.includes(:patent).order(:due_date)
    @due_soon_fees = current_user.due_soon_fees(30).includes(:patent).order(:due_date)
    
    @recent_notifications = current_user.notifications
                                        .includes(:related_patent, :related_fee)
                                        .order(created_at: :desc)
                                        .limit(5)

    # Statistics for charts
    @patent_status_stats = current_user.patents.group(:current_status).count
    @monthly_fee_stats = monthly_fee_statistics
    @annual_fee_summary = annual_fee_summary
  end

  private

  def monthly_fee_statistics
    current_user.patents
                .joins(:annual_fees)
                .where(annual_fees: { due_date: 12.months.ago..12.months.from_now })
                .group('EXTRACT(MONTH FROM annual_fees.due_date)')
                .group('annual_fees.status')
                .sum('annual_fees.amount_krw')
  end

  def annual_fee_summary
    fees = AnnualFee.joins(patent: :user_patents)
                    .where(user_patents: { user_id: current_user.id })
    
    {
      total_scheduled: fees.scheduled.sum(:amount_krw),
      total_due: fees.due.sum(:amount_krw),
      total_overdue: fees.overdue.sum(:amount_krw) + fees.overdue.sum(:surcharge_krw),
      total_paid: fees.paid.sum(:amount_krw),
      count_overdue: fees.overdue.count,
      count_due_soon: fees.due.where('due_date <= ?', 30.days.from_now).count
    }
  end
end