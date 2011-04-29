module PaybackClientExceptions
  class InvalidCardException < StandardError; end
  class InternalErrorException < StandardError; end
  class GenericException < StandardError; end
  class AuthenticationFailedException < StandardError; end
  class NotEnoughPointsException < StandardError; end
  class InvalidXMLException < StandardError; end
  class CardIsNotRegisteredException < StandardError; end
  class HTTPException < StandardError; end
end

