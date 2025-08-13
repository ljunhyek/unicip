class PatentStatusEvent < ApplicationRecord
  # Enums
  enum status: { 
    filed: 'filed', 
    published: 'published', 
    granted: 'granted', 
    rejected: 'rejected', 
    withdrawn: 'withdrawn', 
    expired: 'expired' 
  }

  # Associations
  belongs_to :patent

  # Validations
  validates :status, presence: true
  validates :event_date, presence: true

  # Scopes
  scope :recent, -> { order(event_date: :desc, created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :between_dates, ->(start_date, end_date) { where(event_date: start_date..end_date) }

  # Methods
  def status_display
    status.humanize
  end

  def formatted_event_date
    event_date&.strftime('%Y-%m-%d')
  end
end