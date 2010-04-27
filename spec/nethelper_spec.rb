require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "NetHelper" do
  before(:each) do
    @mock_response = mock("response")
    @mock_response.stub!(:body).and_return("body")
  end

  describe "do_get" do
    it "should get the HTTP response" do
      NetHelper.stub!(:handle_response).and_return("")
      Net::HTTP.should_receive( :get_response ).with( URI.parse("http://some.com") ).and_return(@mock_response)
      NetHelper.do_get( "http://some.com" )
    end
    
    it "should call handle_response with the response" do
      Net::HTTP.stub!( :get_response ).with( URI.parse("http://some.com") ).and_return(@mock_response)
      NetHelper.should_receive(:handle_response).and_return("")
      NetHelper.do_get( "http://some.com" )
    end
  
    
    describe "when the GET takes longer than time_out seconds" do
      before(:each) do
        NetHelper.stub!(:get_with_timeout).and_raise( TimeoutError.new("expected timeout") ) 
      end
      
      describe "when it has retried < retries_on_timeout times" do
        it "should retry" do
          NetHelper.should_receive(:get_with_timeout).twice
          # NOTE: the important expectation is the above one!
          lambda {
            NetHelper.do_get( "http://some.com", 1, 2 )
          }.should raise_error( IOError )
        end
      end
      
      describe "when it has retried retries_on_timeout times" do
        it "should raise an IOError" do
          lambda {
            NetHelper.do_get( "http://some.com", 0, 2 )
          }.should raise_error( IOError )
        end
      end
      
    end
  end
  
  describe "handle_response" do
    
    describe "when the response is OK" do
      before(:each) do
        @mock_response.stub!(:is_a?).with(Net::HTTPSuccess).and_return true
      end
      
      it "should return the response body" do
        NetHelper.handle_response("http://some.com", @mock_response).should == "body"
      end
    end
    
    describe "when the response is a redirect" do
      before(:each) do
        @mock_response.stub!(:is_a?).with(Net::HTTPSuccess).and_return false
        @mock_response.stub!(:is_a?).with(Net::HTTPRedirection).and_return true
      end
      
      describe "when redirects > 0" do
        it "should recurse" do
          NetHelper.should_receive(:do_get)
          NetHelper.handle_response("http://some.com", @mock_response)          
        end
        
        it "should pass the same url and timeout" do
          NetHelper.should_receive(:do_get).with( "http://some.com", 23, anything )
          NetHelper.handle_response( "http://some.com", @mock_response, 23)     
        end
        
        it "should pass redirects - 1 as the redirects param" do
          NetHelper.should_receive(:do_get).with( anything, anything, 15 )
          NetHelper.handle_response( "http://some.com", @mock_response, 23, 16)     
        end
      end
      
      describe "when redirects = 0" do
        it "should raise an IOError" do
          lambda {
            NetHelper.handle_response( "http://some.com", @mock_response, 23, 0)     
          }.should raise_error( IOError )
        end
      end
    end
    
    
    
  end
  
end
