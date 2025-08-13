class UserPatent < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :patent

  # Validations
  validates :user_id, uniqueness: { scope: :patent_id }
  validates :role, inclusion: { in: %w[owner viewer agent manager] }

  # Scopes
  scope :owners, -> { where(role: 'owner') }
  scope :viewers, -> { where(role: 'viewer') }
  scope :agents, -> { where(role: 'agent') }

  # Methods
  def owner?
    role == 'owner'
  end

  def can_manage?
    %w[owner manager].include?(role)
  end

  def can_view?
    %w[owner manager viewer agent].include?(role)
  end
end