class PaybackClient
  
  PAYBACK_PRODUCTION_URL = "https://partner.payback.de:443/" #192.6.93.115
  PAYBACK_SANDBOX_URL = "http://pbltapp1.pbtst.lprz.com:6111/" #192.56.25.167
  
  def initialize(partner_id, branch_id)
    @partner_id = partner_id
    @branch_id = branch_id
  end
  
  def check_card_for_redemption(card_number)
    return 123
  end
  
  def authenticate_alternate_and_redeem(card_number, points_to_redeem, zip, dob)
    raise "not implemented"
  end
    
  def authenticate_and_redeem(card_number, points_to_redeem, pin)
    raise "not implemented"
  end
  
  def auto_refund_points
    raise "not implemented"
  end
  
private

  def xml_request
  end
  
end