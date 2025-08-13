class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum user_type: { corp: 'corp', individual: 'individual', corp_inventor: 'corp_inventor' }

  # Associations
  has_many :user_patents, dependent: :destroy
  has_many :patents, through: :user_patents
  has_many :notifications, dependent: :destroy
  has_many :sync_jobs, foreign_key: :target_user_id, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :user_type, presence: true
  validates :customer_number, uniqueness: true, allow_blank: true, length: { maximum: 20 }
  validates :email, presence: true, uniqueness: true
  validates :terms_agreed, acceptance: true
  validates :privacy_agreed, acceptance: true

  # Scopes
  scope :with_customer_number, -> { where.not(customer_number: nil) }
  scope :agreed_to_email, -> { where(email_agreed: true) }

  # Methods
  def full_name
    [name, manager].compact.join(' - ')
  end

  def patent_summary
    {
      total: patents.count,
      filed: patents.where(current_status: ['filed', 'published']).count,
      granted: patents.where(current_status: 'granted').count,
      rejected: patents.where(current_status: 'rejected').count
    }
  end

  def overdue_fees
    AnnualFee.joins(patent: :user_patents)
             .where(user_patents: { user_id: id })
             .where(status: 'overdue')
  end

  def due_soon_fees(days = 30)
    AnnualFee.joins(patent: :user_patents)
             .where(user_patents: { user_id: id })
             .where(status: 'due')
             .where('due_date <= ?', days.days.from_now)
  end
end