require 'helper'

class SinatraFakeWebServiceTest < Test::Unit::TestCase
  context "creating a sinatra web instance" do
    should "not blowup when passed a string port" do
      port = 9001
      sinatra_fws = SinatraFakeWebService.new :port => port.to_s
      assert_equal port, sinatra_fws.port
    end
  end

  context "a sinatra web service instance" do
    setup do
      @sinatra_app = SinatraFakeWebService.new
      @sinatra_app.run!
      @test_client = SinatraFakeWebService::TestClient.new( @sinatra_app )
    end

    should "be independent of other instances" do
      action = "/test"

      @other_instance = SinatraFakeWebService.new
      @other_instance.run!
      @other_instance.get( action ) { "new hotness" }

      @sinatra_app.get( action ) { "old and busted" }

      assert_equal "old and busted", @test_client.get( action ).body

      @other_client = SinatraFakeWebService::TestClient.new( @other_instance )
      assert_equal "new hotness", @other_client.get( action ).body
    end

    should "not be ready until it can serve connections" do
      assert @sinatra_app.alive?
    end

    # XXX: this test depends on the fact that it comes first alphabetically
    should "aaa have default host and port" do
      assert_equal 4567, @sinatra_app.port
      assert_equal 'localhost', @sinatra_app.host
    end

    context "with a registered GET service" do
      setup do
        @sinatra_app.get '/payme' do
          "OMG I GOT PAID"
        end
      end

      should "respond to GET '/payme' with 'OMG I GOT PAID" do
        res = @test_client.get('/payme')
        assert_equal "OMG I GOT PAID",res.body
      end
    end

    context "with a registered POST service" do
      setup do
        @sinatra_app.post '/returnme' do
          "#{params[:return_value]}"
        end
      end

      should "respond to POST '/returnme' with param :return_value with param value" do
        res = @test_client.post('/returnme',"return_value=2")
        assert_equal "2", res.body
      end
    end

    context "with a registered DELETE service" do
      setup do
        @sinatra_app.delete '/killme' do
          "argh! i is dead."
        end
      end

      should "respond to DELETE '/killme'" do
        res = @test_client.delete('/killme')
        assert_equal "argh! i is dead.", res.body
      end
    end

    context "with a registered PUT service" do
      setup do
        @sinatra_app.put '/gimmieitnow' do
          "yay, i haz it."
        end
      end

      should "respond to put '/gimmieitnow'" do
        res = @test_client.put('/gimmieitnow')
        assert_equal "yay, i haz it.", res.body
      end
    end
  end
end

