class SyncJob < ApplicationRecord
  # Enums
  enum status: { 
    queued: 'queued', 
    running: 'running', 
    success: 'success', 
    warning: 'warning', 
    failed: 'failed' 
  }

  # Associations
  belongs_to :requester, class_name: 'AdminUser', optional: true
  belongs_to :target_user, class_name: 'User', optional: true
  has_many :sync_logs, foreign_key: :job_id, dependent: :destroy

  # Validations
  validates :job_type, presence: true, inclusion: { 
    in: %w[full_user delta_user full_all delta_all] 
  }
  validates :status, presence: true

  # Scopes
  scope :pending, -> { where(status: 'queued') }
  scope :in_progress, -> { where(status: 'running') }
  scope :completed, -> { where(status: ['success', 'warning']) }
  scope :failed_jobs, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(target_user: user) }

  # Class methods
  def self.process_pending!
    pending.find_each do |job|
      KiprisSyncJob.perform_later(job.id)
    end
  end

  def self.create_user_sync(user, job_type = 'delta_user', requester = nil)
    create!(
      job_type: job_type,
      target_user: user,
      requester: requester,
      status: 'queued'
    )
  end

  def self.create_full_sync(requester)
    create!(
      job_type: 'full_all',
      requester: requester,
      status: 'queued'
    )
  end

  # Instance methods
  def start!
    update!(
      status: 'running',
      started_at: Time.current
    )
  end

  def complete!(final_status = 'success', message = nil)
    update!(
      status: final_status,
      finished_at: Time.current,
      message: message
    )
  end

  def duration
    return nil unless started_at
    
    end_time = finished_at || Time.current
    end_time - started_at
  end

  def formatted_duration
    return 'Not started' unless started_at
    
    seconds = duration.to_i
    return "#{seconds}s" if seconds < 60
    
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    "#{minutes}m #{remaining_seconds}s"
  end

  def log_info(message, patent_app_no = nil)
    sync_logs.create!(
      level: 'info',
      message: message,
      patent_app_no: patent_app_no
    )
  end

  def log_warning(message, patent_app_no = nil)
    sync_logs.create!(
      level: 'warn',
      message: message,
      patent_app_no: patent_app_no
    )
  end

  def log_error(message, patent_app_no = nil)
    sync_logs.create!(
      level: 'error',
      message: message,
      patent_app_no: patent_app_no
    )
  end

  def error_count
    sync_logs.where(level: 'error').count
  end

  def warning_count
    sync_logs.where(level: 'warn').count
  end

  def success_count
    sync_logs.where(level: 'info').count
  end

  def can_retry?
    failed? && created_at > 24.hours.ago
  end

  def retry!
    return unless can_retry?
    
    update!(
      status: 'queued',
      started_at: nil,
      finished_at: nil,
      message: nil
    )
    sync_logs.destroy_all
  end
end