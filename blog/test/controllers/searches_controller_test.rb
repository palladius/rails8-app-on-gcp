require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  test "search page renders the search bar without a query" do
    get search_url

    assert_response :success
    assert_select "form.semantic-search input[name=q]"
    assert_select "#search-results", count: 0
  end

  test "search lists matching posts (keyword fallback on SQLite)" do
    get search_url(q: "second")

    assert_response :success
    assert_select "#search-results li", count: 1
    assert_select "#search-results a", text: "My Second Test Post"
    assert_select "#search-mode-notice"
  end

  test "search with no match says so" do
    get search_url(q: "zebra unicorn spaceship")

    assert_response :success
    assert_select "#search-results-empty"
  end

  test "posts index shows the search bar" do
    get posts_url

    assert_response :success
    assert_select "form.semantic-search[action=?]", search_path
  end
end
