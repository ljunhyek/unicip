class PatentDocument < ApplicationRecord
  # Enums
  enum doc_type: { 
    opinion: 'opinion',
    publication_pdf: 'publication_pdf',
    announcement_pdf: 'announcement_pdf',
    spec: 'spec',
    claims: 'claims',
    drawing: 'drawing',
    others: 'others'
  }

  # Associations
  belongs_to :patent

  # Validations
  validates :doc_type, presence: true
  validates :title, presence: true

  # Scopes
  scope :downloaded, -> { where(downloaded: true) }
  scope :not_downloaded, -> { where(downloaded: false) }
  scope :by_type, ->(type) { where(doc_type: type) }

  # Methods
  def display_title
    title.presence || "#{doc_type.humanize} Document"
  end

  def file_available?
    url.present? || file_key.present?
  end

  def download_url
    return url if url.present?
    return file_storage_url if file_key.present?
    nil
  end

  def mark_as_downloaded!(key = nil)
    update!(
      downloaded: true,
      file_key: key || file_key
    )
  end

  def icon_class
    case doc_type
    when 'opinion'
      'fa-file-text'
    when 'publication_pdf', 'announcement_pdf'
      'fa-file-pdf'
    when 'spec', 'claims'
      'fa-file-code'
    when 'drawing'
      'fa-file-image'
    else
      'fa-file'
    end
  end

  private

  def file_storage_url
    # Implementation would depend on your file storage service
    # e.g., AWS S3, Google Cloud Storage, etc.
    return nil unless file_key
    
    "#{ENV['FILE_STORAGE_BASE_URL']}/#{file_key}"
  end
end