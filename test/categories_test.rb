require File.dirname(__FILE__) + '/test_helper.rb'

class CategoriesTest < Test::Unit::TestCase
  include Shoehorn

  context "initialization" do
    setup do
      @connection = Shoehorn::Connection.new
      @categories = @connection.categories
    end

    should "have a pointer back to the connection" do
      assert_equal @connection, @categories.connection
    end
  end

end