class AnnualFee < ApplicationRecord
  # Enums
  enum status: { 
    scheduled: 'scheduled', 
    due: 'due', 
    overdue: 'overdue', 
    paid: 'paid', 
    waived: 'waived', 
    exempt: 'exempt' 
  }

  # Associations
  belongs_to :patent
  has_many :fee_payments, dependent: :destroy
  has_many :notifications, foreign_key: :related_fee, dependent: :nullify

  # Validations
  validates :year_no, presence: true, uniqueness: { scope: :patent_id }
  validates :amount_krw, presence: true, numericality: { greater_than: 0 }
  validates :due_date, presence: true
  validates :status, presence: true

  # Scopes
  scope :overdue, -> { where(status: 'overdue') }
  scope :due_soon, ->(days = 30) { where(status: 'due').where('due_date <= ?', days.days.from_now) }
  scope :unpaid, -> { where(status: ['scheduled', 'due', 'overdue']) }
  scope :paid, -> { where(status: 'paid') }
  scope :by_year, ->(year) { where(year_no: year) }
  scope :due_before, ->(date) { where('due_date <= ?', date) }

  # Callbacks
  before_save :calculate_surcharge, if: :overdue?
  after_update :update_patent_notifications, if: :saved_change_to_status?

  # Class methods
  def self.update_statuses!
    # Update status to 'due' for fees due within 30 days
    scheduled.where('due_date <= ?', 30.days.from_now).update_all(status: 'due')
    
    # Update status to 'overdue' for fees past due date
    where(status: ['scheduled', 'due']).where('due_date < ?', Date.current).each do |fee|
      fee.update!(status: 'overdue')
    end
  end

  # Instance methods
  def days_until_due
    return nil unless due_date
    (due_date - Date.current).to_i
  end

  def days_overdue
    return 0 unless overdue? && due_date
    [0, (Date.current - due_date).to_i].max
  end

  def total_amount
    amount_krw + surcharge_krw
  end

  def total_paid
    fee_payments.sum(:pay_amount)
  end

  def remaining_amount
    total_amount - total_paid
  end

  def fully_paid?
    total_paid >= total_amount
  end

  def partially_paid?
    total_paid > 0 && total_paid < total_amount
  end

  def grace_period_expired?
    grace_end_date && Date.current > grace_end_date
  end

  def mark_as_paid!(payment_date = Date.current)
    update!(
      status: 'paid',
      paid_date: payment_date
    )
  end

  private

  def calculate_surcharge
    return unless overdue? && due_date
    
    overdue_days = days_overdue
    return if overdue_days <= 0
    
    # Simple surcharge calculation: 10% of base amount plus 1% per month overdue
    base_surcharge = amount_krw * 0.1
    monthly_surcharge = amount_krw * 0.01 * (overdue_days / 30.0).ceil
    
    self.surcharge_krw = base_surcharge + monthly_surcharge
  end

  def update_patent_notifications
    return unless saved_change_to_status?
    
    if overdue?
      NotificationService.schedule_overdue_notification(self)
    elsif due?
      NotificationService.schedule_due_notification(self)
    end
  end
end