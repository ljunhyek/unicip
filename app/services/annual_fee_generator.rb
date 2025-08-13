class AnnualFeeGenerator
  def initialize(patent)
    @patent = patent
  end

  def generate
    return unless @patent.is_granted? && @patent.grant_date

    # Generate annual fees for the next 20 years (typical patent life)
    (1..20).each do |year_no|
      next if @patent.annual_fees.exists?(year_no: year_no)

      due_date = calculate_due_date(year_no)
      amount = calculate_fee_amount(year_no)

      @patent.annual_fees.create!(
        year_no: year_no,
        amount_krw: amount,
        due_date: due_date,
        status: 'scheduled'
      )
    end
  end

  private

  def calculate_due_date(year_no)
    base_date = @patent.grant_date || @patent.filing_date
    base_date + year_no.years
  end

  def calculate_fee_amount(year_no)
    # Korean patent annual fee structure (simplified)
    case year_no
    when 1..3
      55000  # Years 1-3: 55,000 KRW
    when 4..6
      130000 # Years 4-6: 130,000 KRW
    when 7..9
      390000 # Years 7-9: 390,000 KRW
    when 10..12
      520000 # Years 10-12: 520,000 KRW
    when 13..15
      650000 # Years 13-15: 650,000 KRW
    when 16..20
      780000 # Years 16-20: 780,000 KRW
    else
      780000
    end
  end
end