require 'test/payback_test_data'
require 'lib/payback_client'

describe PaybackClient do
  
  before :each do
    @payback_card = PAYBACK_TEST_CARDS[0]
    @payback_client = PaybackClient.new(PAYBACK_PARTNER_ID, PAYBACK_BRANCH_ID)
  end
  
  it "check the current balance" do
    points_on_card = @payback_client.check_card_for_redemption(@payback_card[:card_number])
    points_on_card.should be_a(Hash)
    points_on_card.length.should == 3
    points_on_card.should have_key(:acctbalance)
    points_on_card.should have_key(:available)
    points_on_card.should have_key(:available_for_next_redemption)
    points_on_card[:acctbalance].should be_a(Number)
    points_on_card[:acctbalance].should == 12345
  end
  
end