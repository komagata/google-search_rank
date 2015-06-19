require "google/search_rank/version"
require "google/api_client"

module Google
  class SearchRank
    TOKEN_CREDENTIAL_URI = "https://accounts.google.com/o/oauth2/token"
    AUDIENCE = "https://accounts.google.com/o/oauth2/token"
    SCOPE = "https://www.googleapis.com/auth/cse"

    def initialize(application_name: "google-search_rank",
                   application_version: "1.0",
                   api_key:,
                   cse_id:)
      @application_name = application_name
      @application_version = application_version
      @api_key = api_key
      @cse_id = cse_id
    end

    def client
      Google::APIClient.new(
        application_name: @application_name,
        application_version: @application_version,
        authorization: nil
      )
    end

    def service
      client.discovered_api('customsearch')
    end

    def find(query, link, page = 1)
      start = (page - 1) * 10 + 1
      result = client.execute(
        service.cse.list,
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
