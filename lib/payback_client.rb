require "rubygems"
require 'nokogiri'
require 'net/http'
require 'net/https'
require 'uri'

require 'pp' # FIXME remove me

class PaybackClient
  
  PAYBACK_PRODUCTION_URL = "https://partner.payback.de:443/" #192.6.93.115
  PAYBACK_SANDBOX_URL = "http://pbltapp1.pbtst.lprz.com:80/" #192.56.25.167
  
  def initialize(partner_id, branch_id)
    @partner_id = partner_id
    @branch_id = branch_id
    @terminal_id = @branch_id # FIXME where is the documentation for this?
  end
  
  def check_card_for_redemption(card_number)    
    api_response = build_and_submit_request_with_command(1, :CheckCardForRedemption, :cardnumber => card_number) # FIXME request-id is always one
    return {
      :balance => api_response['acctbalance'].to_i,
      :available => api_response['available'].to_i,
      :available_for_next_redemption => api_response['availableForNextRedemption'].to_i
    }
  end
  
  def authenticate_alternate_and_redeem(card_number, points_to_redeem, transaction_id, zip, dob)
    # FIXME request-id is always one
    api_response = build_and_submit_request_with_command(1, :AuthenticateAlternateAndRedeem, 
      :cardnumber => card_number,
      :points => points_to_redeem,
      :terminalTransactionID => transaction_id,
      :zip => zip,
      :dob => dob
    ) 
    pp api_response
  end
    
  def authenticate_and_redeem(card_number, points_to_redeem, pin)
    raise "not implemented"
  end
  
  def auto_refund_points
    raise "not implemented"
  end
  
private

  def build_and_submit_request_with_command(request_id, command, data={})
    xml_request = build_xml_request_with_command(request_id, command, data)    
    xml_response = submit_xml_request(xml_request)
    parse_xml_response(xml_response)
  end

  def submit_xml_request(xml)
    uri = URI::parse(PAYBACK_SANDBOX_URL) # FIXME
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    resp, data = http.post('/pos/callCMD', xml, nil)
    # FIXME error handling
    return data
  end
  
  def parse_xml_response(xml)
    doc = Nokogiri::XML(xml)
    check_error_code(doc)
    entries_as_hash = Hash.new
    doc.xpath('//Response//DataRecord//Entry').each do |entry|
      key = entry.xpath('Key').attribute('value').to_s
      value = entry.xpath('Value').attribute('value').to_s
      entries_as_hash[key] = value
    end
    return entries_as_hash
  end
  
  def check_error_code(parsed_xml)
    error_code = -1
    error_code = parsed_xml.xpath('//Response/ErrorCode').attribute('value').to_s.to_i
    if error_code == -202
      raise PaybackClient::InternalErrorException
    elsif error_code == -203
      raise PaybackClient::InvalidException
    elsif error_code == -204
      raise PaybackClient::AuthenticationFailedException
    elsif error_code == -216
      raise PaybackClient::NotEnoughPointsException
    elsif error_code < 0
      raise PaybackClient::GenericException
    end
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
  
  def build_xml_request_with_command(request_id, command, data={})
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