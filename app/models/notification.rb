class Notification < ApplicationRecord
  # Enums
  enum channel: { email: 'email', sms: 'sms', webpush: 'webpush' }
  enum status: { queued: 'queued', sent: 'sent', failed: 'failed', cancelled: 'cancelled' }

  # Associations
  belongs_to :user
  belongs_to :related_fee, class_name: 'AnnualFee', optional: true
  belongs_to :related_patent, class_name: 'Patent', optional: true

  # Validations
  validates :channel, presence: true
  validates :status, presence: true
  validates :subject, presence: true, if: :email?

  # Scopes
  scope :pending, -> { where(status: ['queued']) }
  scope :sent_successfully, -> { where(status: 'sent') }
  scope :failed_delivery, -> { where(status: 'failed') }
  scope :scheduled_for, ->(date) { where('scheduled_at <= ?', date) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.process_pending!
    pending.scheduled_for(Time.current).find_each do |notification|
      NotificationDeliveryJob.perform_later(notification.id)
    end
  end

  # Instance methods
  def deliver!
    case channel
    when 'email'
      deliver_email
    when 'sms'
      deliver_sms
    when 'webpush'
      deliver_webpush
    end
  end

  def mark_as_sent!
    update!(
      status: 'sent',
      sent_at: Time.current
    )
  end

  def mark_as_failed!(error_message)
    update!(
      status: 'failed',
      error_msg: error_message
    )
  end

  def can_retry?
    failed? && created_at > 24.hours.ago
  end

  def retry!
    return unless can_retry?
    
    update!(
      status: 'queued',
      error_msg: nil,
      scheduled_at: Time.current
    )
  end

  private

  def deliver_email
    UserMailer.notification_email(self).deliver_now
  rescue StandardError => e
    mark_as_failed!(e.message)
    raise
  end

  def deliver_sms
    # SMS delivery implementation
    # SmsService.send_message(user.contact, body)
    mark_as_sent!
  rescue StandardError => e
    mark_as_failed!(e.message)
    raise
  end

  def deliver_webpush
    # Web push notification implementation
    # WebPushService.send_notification(user, subject, body)
    mark_as_sent!
  rescue StandardError => e
    mark_as_failed!(e.message)
    raise
  end
end