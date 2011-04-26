require "rubygems"
require 'nokogiri'
require 'net/http'

class PaybackClient
  
  PAYBACK_PRODUCTION_URL = "https://partner.payback.de:443/" #192.6.93.115
  PAYBACK_SANDBOX_URL = "http://pbltapp1.pbtst.lprz.com:6111/" #192.56.25.167
  
  def initialize(partner_id, branch_id)
    @partner_id = partner_id
    @branch_id = branch_id
    @terminal_id = 12435
  end
  
  def check_card_for_redemption(card_number)    
    xml_request = build_xml_request_for_command(1, :CheckCardForRedemption, :cardnumber => card_number)
    puts xml_request
    
    return {
      :balance => 12345,
      :available => 12345,
      :available_for_next_redemption => 12345
    }
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

  def send_xml_request_to_payback
    
  end

  def build_xml_request(request_id)
    builder = Nokogiri::XML::Builder.new(:encoding => "ISO-8859-1") do |xml|
      xml.send(:"LMS-Service", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:noNamespaceSchemaLocation" => "F:/R09006POS_Terminals/3-Design/LM-Service.xsd") do
        xml.PartnerID(:value => @partner_id)
        xml.TerminalID(:value => @terminal_id)        
        xml.Request do
          xml.RequestID(:value => request_id)
          yield(xml) if block_given?
        end
      end
    end
    return builder.to_xml
  end
  
  def build_xml_request_for_command(request_id, command, data={})
    build_xml_request(request_id) do |xml|
      xml.Command{ xml.Name(:value => command) }
      xml.DataRecord do
        data.each do |key, value|
          xml.Entry do
            xml.Key(:value => key)
            xml.Value(:value => value)
          end
        end
      end
    end
  end
  
end