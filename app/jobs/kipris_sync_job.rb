class KiprisSyncJob < ApplicationJob
  queue_as :default

  def perform(sync_job_id)
    sync_job = SyncJob.find(sync_job_id)
    sync_job.start!

    begin
      case sync_job.job_type
      when 'delta_user', 'full_user'
        sync_user_patents(sync_job)
      when 'full_all', 'delta_all'
        sync_all_users(sync_job)
      end

      sync_job.complete!('success', 'Synchronization completed successfully')
    rescue StandardError => e
      Rails.logger.error "KIPRIS Sync Job Error: #{e.message}"
      sync_job.log_error("Sync job failed: #{e.message}")
      sync_job.complete!('failed', e.message)
    end
  end

  private

  def sync_user_patents(sync_job)
    user = sync_job.target_user
    return unless user&.customer_number

    sync_job.log_info("Starting sync for user: #{user.email}")
    
    api_service = KiprisApiService.new
    patents_data = api_service.fetch_user_patents(user.customer_number)
    
    sync_job.log_info("Found #{patents_data.count} patents from API")

    patents_data.each do |patent_data|
      begin
        sync_patent(patent_data, user, sync_job)
      rescue StandardError => e
        sync_job.log_error("Failed to sync patent #{patent_data[:application_number]}: #{e.message}")
      end
    end

    sync_job.log_info("Sync completed for user: #{user.email}")
  end

  def sync_all_users(sync_job)
    users_with_customer_number = User.with_customer_number
    sync_job.log_info("Starting sync for #{users_with_customer_number.count} users")

    users_with_customer_number.find_each do |user|
      begin
        # Create individual sync job for each user
        user_sync_job = SyncJob.create_user_sync(user, 'delta_user', sync_job.requester)
        KiprisSyncJob.perform_later(user_sync_job.id)
        
        sync_job.log_info("Queued sync for user: #{user.email}")
      rescue StandardError => e
        sync_job.log_error("Failed to queue sync for user #{user.email}: #{e.message}")
      end
    end
  end

  def sync_patent(patent_data, user, sync_job)
    application_number = patent_data[:application_number]
    
    # Find or create patent
    patent = Patent.find_or_initialize_by(application_number: application_number)
    
    if patent.new_record?
      sync_job.log_info("Creating new patent: #{application_number}")
    else
      sync_job.log_info("Updating existing patent: #{application_number}")
    end

    # Update patent attributes
    patent.assign_attributes(patent_data)
    
    if patent.save
      # Link patent to user if not already linked
      unless patent.users.include?(user)
        UserPatent.create!(user: user, patent: patent, role: 'owner')
        sync_job.log_info("Linked patent #{application_number} to user #{user.email}")
      end

      # Generate annual fees if patent is granted
      if patent.is_granted? && patent.grant_date
        AnnualFeeGenerator.new(patent).generate
        sync_job.log_info("Generated annual fees for patent #{application_number}")
      end

      # Fetch detailed information
      fetch_patent_details(patent, sync_job)
      
    else
      sync_job.log_error("Failed to save patent #{application_number}: #{patent.errors.full_messages.join(', ')}")
    end
  end

  def fetch_patent_details(patent, sync_job)
    api_service = KiprisApiService.new
    detailed_data = api_service.fetch_patent_details(patent.application_number)
    
    if detailed_data
      patent.update(detailed_data)
      sync_job.log_info("Updated detailed info for patent #{patent.application_number}")
    else
      sync_job.log_warning("Could not fetch detailed info for patent #{patent.application_number}")
    end
  end
end