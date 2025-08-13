class Patent < ApplicationRecord
  # Enums
  enum current_status: { 
    filed: 'filed', 
    published: 'published', 
    granted: 'granted', 
    rejected: 'rejected', 
    withdrawn: 'withdrawn', 
    expired: 'expired' 
  }

  # Associations
  has_many :user_patents, dependent: :destroy
  has_many :users, through: :user_patents
  has_many :patent_status_events, dependent: :destroy
  has_many :patent_documents, dependent: :destroy
  has_many :annual_fees, dependent: :destroy
  has_many :notifications, foreign_key: :related_patent, dependent: :nullify

  # Validations
  validates :application_number, presence: true, uniqueness: true
  validates :current_status, presence: true

  # Scopes
  scope :active, -> { where(current_status: ['filed', 'published', 'granted']) }
  scope :granted, -> { where(current_status: 'granted') }
  scope :by_status, ->(status) { where(current_status: status) }
  scope :filed_after, ->(date) { where('filing_date >= ?', date) }
  scope :granted_after, ->(date) { where('grant_date >= ?', date) }

  # Callbacks
  after_update :create_status_event, if: :saved_change_to_current_status?
  after_update :generate_annual_fees, if: :saved_change_to_grant_date?

  # Methods
  def display_title
    title_ko.presence || title_en.presence || "Patent #{application_number}"
  end

  def primary_applicant
    return applicant_name if applicant_name.present?
    
    if applicants_json.is_a?(Array) && applicants_json.any?
      applicants_json.first['name'] || applicants_json.first.to_s
    end
  end

  def inventors_list
    return [] unless inventors_json.is_a?(Array)
    inventors_json.map { |inv| inv.is_a?(Hash) ? inv['name'] : inv.to_s }.compact
  end

  def is_granted?
    current_status == 'granted'
  end

  def is_active?
    ['filed', 'published', 'granted'].include?(current_status)
  end

  def days_since_filing
    return nil unless filing_date
    (Date.current - filing_date).to_i
  end

  def overdue_fees
    annual_fees.where(status: 'overdue')
  end

  def upcoming_fees(days = 30)
    annual_fees.where(status: 'due')
               .where('due_date <= ?', days.days.from_now)
  end

  def total_paid_fees
    FeePayment.joins(:annual_fee)
              .where(annual_fees: { patent_id: id })
              .sum(:pay_amount)
  end

  private

  def create_status_event
    patent_status_events.create!(
      status: current_status,
      event_date: Date.current,
      message: "Status changed to #{current_status}"
    )
  end

  def generate_annual_fees
    return unless grant_date && is_granted?
    
    AnnualFeeGenerator.new(self).generate
  end
end