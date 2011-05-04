require "rubygems"
require 'nokogiri'
require 'net/http'
require 'net/https'
require 'uri'

$: << File.dirname(__FILE__)
require 'payback_client_exceptions'

class PaybackClient 
  include PaybackClientExceptions
  
  def initialize(api_url, partner_id, branch_id)
    @api_url = api_url
    @partner_id = partner_id
    @branch_id = branch_id
    @terminal_id = @branch_id # the documentation for this is nowhere to be found, but it works...
  end
  
  def check_card_for_redemption(card_number)    
    verify_card_number!(card_number)
    api_response = build_and_submit_request_with_command(:CheckCardForRedemption, :cardnumber => card_number) 
    return {
      :balance => api_response['acctbalance'].to_i,
      :available => api_response['available'].to_i,
      :available_for_next_redemption => api_response['availableForNextRedemption'].to_i
    }
  end
  
  def authenticate_alternate_and_redeem(card_number, points_to_redeem, transaction_id, zip, dob)
    verify_card_number!(card_number)
    api_response = build_and_submit_request_with_command(:AuthenticateAlternateAndRedeemPoints, 
      :cardnumber => card_number,
      :points => points_to_redeem,
      :terminalTransactionID => transaction_id,
      :zip => zip,
      :dob => dob
    ) 
  end
    
  def authenticate_and_redeem(card_number, points_to_redeem, pin)
    raise "not implemented"
  end
  
  def auto_refund_points
    raise "not implemented"
  end
  
  def card_number_valid?(card_number) #calculate the luhn checksum
    odd = true
    card_number.to_s.gsub(/\D/,'').reverse.split('').map(&:to_i).collect { |d|
      d *= 2 if odd = !odd
      d > 9 ? d - 9 : d
    }.reduce(0){ |sum,n| sum += n } % 10 == 0
  end
  
private

  def build_and_submit_request_with_command(command, data={})
    request_id = 1 #request_id is always one
    xml_request = build_xml_request_with_command(request_id, command, data)    
    xml_response = submit_xml_request(xml_request)
    return parse_xml_response(xml_response)
  end

  def submit_xml_request(xml)
    uri = URI::parse(@api_url) 
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    resp, data = http.post(uri.path, xml, nil)
    return data
  rescue
    raise PaybackClient::HTTPException
  end
  
  def parse_xml_response(xml)
    begin
      doc = Nokogiri::XML(xml)
      error_code = doc.xpath('//Response/ErrorCode').attribute('value').to_s.to_i
      entries_as_hash = Hash.new
      doc.xpath('//Response//DataRecord//Entry').each do |entry|
        key = entry.xpath('Key').attribute('value').to_s
        value = entry.xpath('Value').attribute('value').to_s
        entries_as_hash[key] = value
      end
    rescue
      raise PaybackClient::InvalidXMLException, xml
    else
      check_error_code!(error_code)
      return entries_as_hash
    end
  end
  
  def check_error_code!(error_code)
    if error_code == -202
      raise PaybackClient::InternalErrorException
    elsif error_code == -203
      raise PaybackClient::InvalidException
    elsif error_code == -204
      raise PaybackClient::AuthenticationFailedException
    elsif error_code == -216
      raise PaybackClient::NotEnoughPointsException
    elsif error_code == -224
      raise PaybackClient::InvalidXMLException
    elsif error_code == -287
      raise PaybackClient::CardIsNotRegisteredException
    elsif error_code < 0
      raise PaybackClient::GenericException
    end
  end

  def verify_card_number!(card_number)
    raise PaybackClient::InvalidCardException unless card_number_valid?(card_number)
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
