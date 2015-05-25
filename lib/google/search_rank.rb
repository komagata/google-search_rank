require "google/search_rank/version"
require "google/api_client"

module Google
  class SearchRank
    TOKEN_CREDENTIAL_URI = "https://accounts.google.com/o/oauth2/token"
    AUDIENCE = "https://accounts.google.com/o/oauth2/token"
    SCOPE = "https://www.googleapis.com/auth/cse"

    def initialize(app_name, key_path, key_pass,
                   client_id, client_secret,
                   api_key, cse_id)
      @app_name = app_name
      @key_path = key_path
      @key_pass = key_pass
      @client_id = client_id
      @client_secret = client_secret
      @api_key = api_key
      @cse_id = cse_id
    end

    def authorize!
      @client = Google::APIClient.new(
        application_name: @app_name
      )
      key = Google::APIClient::KeyUtils.load_from_pkcs12(
        @key_path, @key_pass
      )
      @client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => TOKEN_CREDENTIAL_URI,
        :audience => AUDIENCE,
        :scope => SCOPE,
        :issuer => @client_secret,
        :signing_key => key,
      )
      @client.authorization.fetch_access_token!
      @search = @client.discovered_api('customsearch')
    end

    def find(query, link, page = 1)
      authorize! if @search.nil?

      start = (page - 1) * 10 + 1
      result = @client.execute(
        @search.cse.list,
        'key' => @api_key,
        'cx' => @cse_id,
        'q' => query,
        'start' => start,
      )
      queries = result.data.queries
      has_next_page = !queries.nil? && queries['nextPage'].count > 0
      has_result = result.data.items.count > 0

      return 0 unless has_result

      result.data.items.each_with_index do |item, i|
        puts "start: #{start}, i: #{i} rank: #{start + i}, query: #{query}, link: #{item.link}"
        if item.link =~ link
          return start + i
        elsif item.link == link
          return start + i
        end
      end

      if has_next_page
        find(query, link, page + 1)
      else
        nil
      end
    end
  end
end
