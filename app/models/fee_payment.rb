class FeePayment < ApplicationRecord
  # Associations
  belongs_to :annual_fee

  # Validations
  validates :pay_amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :paid_at, presence: true

  # Scopes
  scope :by_currency, ->(currency) { where(currency: currency) }
  scope :paid_between, ->(start_date, end_date) { where(paid_at: start_date..end_date) }
  scope :recent, -> { order(paid_at: :desc) }

  # Callbacks
  after_create :update_annual_fee_status

  # Methods
  def payment_reference
    "PAY-#{id.to_s.rjust(8, '0')}"
  end

  def krw_amount
    return pay_amount if currency == 'KRW'
    
    # Convert to KRW if needed (would need exchange rate service)
    pay_amount * exchange_rate_to_krw
  end

  private

  def update_annual_fee_status
    annual_fee.reload
    
    if annual_fee.fully_paid?
      annual_fee.mark_as_paid!(paid_at.to_date)
    end
  end

  def exchange_rate_to_krw
    # Simplified - in real implementation, use exchange rate service
    case currency
    when 'USD'
      1300.0
    when 'EUR'
      1400.0
    when 'JPY'
      10.0
    else
      1.0
    end
  end
end