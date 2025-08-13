class KiprisApiService
  include HTTParty
  
  base_uri ENV['KIPRIS_API_URL'] || 'http://plus.kipris.or.kr/openapi/rest'
  
  def initialize
    @api_key = ENV['KIPRIS_API_KEY']
    raise 'KIPRIS API Key is required' unless @api_key
  end

  def fetch_user_patents(customer_number)
    return [] unless customer_number.present?

    response = self.class.get('/PatentService/getPatentListByApplicant', {
      query: {
        ServiceKey: @api_key,
        applicant: customer_number,
        numOfRows: 100,
        pageNo: 1
      },
      timeout: 30
    })

    if response.success?
      parse_patent_response(response.body)
    else
      Rails.logger.error "KIPRIS API Error: #{response.code} - #{response.message}"
      []
    end
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error "KIPRIS API Service Error: #{e.message}"
    []
  end

  def fetch_patent_details(application_number)
    return nil unless application_number.present?

    response = self.class.get('/PatentService/getPatentDetailByApplNum', {
      query: {
        ServiceKey: @api_key,
        applicationNumber: application_number
      },
      timeout: 30
    })

    if response.success?
      parse_patent_detail_response(response.body)
    else
      Rails.logger.error "KIPRIS API Error for #{application_number}: #{response.code}"
      nil
    end
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error "KIPRIS API Detail Error: #{e.message}"
    nil
  end

  private

  def parse_patent_response(xml_body)
    doc = Nokogiri::XML(xml_body)
    patents = []

    doc.xpath('//item').each do |item|
      patent_data = {
        application_number: extract_text(item, 'applicationNumber'),
        registration_number: extract_text(item, 'registrationNumber'),
        title_ko: extract_text(item, 'inventionTitle'),
        applicant_name: extract_text(item, 'applicantName'),
        filing_date: parse_date(extract_text(item, 'applicationDate')),
        publication_date: parse_date(extract_text(item, 'publicationDate')),
        grant_date: parse_date(extract_text(item, 'registrationDate')),
        current_status: map_status(extract_text(item, 'applicationStatus')),
        raw_payload_xml: item.to_xml,
        updated_from_api_at: Time.current
      }
      
      patents << patent_data if patent_data[:application_number].present?
    end

    patents
  end

  def parse_patent_detail_response(xml_body)
    doc = Nokogiri::XML(xml_body)
    item = doc.at_xpath('//item')
    return nil unless item

    {
      application_number: extract_text(item, 'applicationNumber'),
      registration_number: extract_text(item, 'registrationNumber'),
      title_ko: extract_text(item, 'inventionTitle'),
      title_en: extract_text(item, 'inventionTitleEng'),
      applicant_name: extract_text(item, 'applicantName'),
      applicants_json: parse_applicants(item),
      inventors_json: parse_inventors(item),
      filing_date: parse_date(extract_text(item, 'applicationDate')),
      priority_number: extract_text(item, 'priorityNumber'),
      priority_claim: extract_text(item, 'priorityClaim') == 'Y',
      publication_date: parse_date(extract_text(item, 'publicationDate')),
      grant_date: parse_date(extract_text(item, 'registrationDate')),
      current_status: map_status(extract_text(item, 'applicationStatus')),
      raw_payload_xml: item.to_xml,
      updated_from_api_at: Time.current
    }
  end

  def extract_text(node, xpath)
    node.at_xpath(xpath)&.text&.strip
  end

  def parse_date(date_string)
    return nil unless date_string.present?
    
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end

  def parse_applicants(item)
    applicants = []
    item.xpath('.//applicant').each do |applicant|
      applicants << {
        name: extract_text(applicant, 'applicantName'),
        address: extract_text(applicant, 'address'),
        nationality: extract_text(applicant, 'nationality')
      }
    end
    applicants
  end

  def parse_inventors(item)
    inventors = []
    item.xpath('.//inventor').each do |inventor|
      inventors << {
        name: extract_text(inventor, 'inventorName'),
        address: extract_text(inventor, 'address'),
        nationality: extract_text(inventor, 'nationality')
      }
    end
    inventors
  end

  def map_status(api_status)
    case api_status&.downcase
    when 'application', 'pending'
      'filed'
    when 'publication'
      'published'
    when 'registration', 'granted'
      'granted'
    when 'rejection', 'rejected'
      'rejected'
    when 'withdrawal', 'withdrawn'
      'withdrawn'
    when 'expiration', 'expired'
      'expired'
    else
      'filed'
    end
  end
end