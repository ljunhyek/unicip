class SyncLog < ApplicationRecord
  # Associations
  belongs_to :sync_job, foreign_key: :job_id

  # Validations
  validates :level, presence: true, inclusion: { in: %w[info warn error] }
  validates :message, presence: true

  # Scopes
  scope :errors, -> { where(level: 'error') }
  scope :warnings, -> { where(level: 'warn') }
  scope :info, -> { where(level: 'info') }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_patent, ->(app_no) { where(patent_app_no: app_no) }

  # Methods
  def error?
    level == 'error'
  end

  def warning?
    level == 'warn'
  end

  def info?
    level == 'info'
  end

  def level_icon
    case level
    when 'error'
      'fa-exclamation-circle text-danger'
    when 'warn'
      'fa-exclamation-triangle text-warning'
    when 'info'
      'fa-info-circle text-info'
    end
  end

  def formatted_time
    created_at.strftime('%H:%M:%S')
  end

  def short_message(limit = 100)
    return message if message.length <= limit
    "#{message[0..limit-3]}..."
  end
end