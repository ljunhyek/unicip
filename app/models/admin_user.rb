class AdminUser < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :rememberable, :validatable

  # Associations
  has_many :sync_jobs, foreign_key: :requester_id, dependent: :nullify

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[admin operator auditor] }

  # Scopes
  scope :admins, -> { where(role: 'admin') }
  scope :operators, -> { where(role: 'operator') }
  scope :auditors, -> { where(role: 'auditor') }

  # Methods
  def admin?
    role == 'admin'
  end

  def operator?
    role == 'operator'
  end

  def auditor?
    role == 'auditor'
  end

  def can_manage_users?
    admin?
  end

  def can_sync_data?
    admin? || operator?
  end

  def can_view_logs?
    admin? || auditor?
  end

  def display_name
    email.split('@').first.humanize
  end
end