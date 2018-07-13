#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'http-cookie'

# Performs a login to Optus.com.au
# I'm hoping to eventually extend this to fetching user data.
#
# Current problems: Needs to get the UXF session token (a JWT)
# from somewhere.

username = ENV["OPTUS_USER"]
userpass = ENV["OPTUS_PASS"]

$jar = HTTP::CookieJar.new

def login(username, userpass)
  login_url = 'https://www.optus.com.au/id/forms/login.sm'
  uri = URI(login_url)

  res = Net::HTTP::post_form(
    uri,
    {
      "user" => username,
      "password" => userpass,
      "target" => '-SM-HTTP://www.optus.com.au/secure/sm/login.process?target=https-:-/-/www.optus.com.au-/my--account',
      ":cq_csrf_token" => nil,
    }
  )

  puts res.code + " " + res.message
  puts res.body
  res.get_fields('Set-Cookie').each do |c|
    $jar.parse(c, uri)
  end
  # puts "Using these cookies:"
  # $jar.cookies.each { |c| puts(c) }

  # Redirect goes to http://www.optus.com.au/secure/sm/login.process?target=https://www.optus.com.au/my-account
  # then there is SAML2SSO
  # then shibboleth
end

def my_account()
  url = "https://www.optus.com.au/my-account"
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  cookies = HTTP::Cookie.cookie_value($jar.cookies)
  request["Cookie"] = cookies
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|
    response = http.request(request)
    puts response.code + " " + response.message
    puts response.body
  }
end

# Doesn't appear to work any more, returns anonymousUser=true
def user_info()
  url = "https://api.www.optus.com.au/mcssapi/rp-webapp-9-common/user/information"
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  cookies = HTTP::Cookie.cookie_value($jar.cookies)
  request["Cookie"] = cookies
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|
    response = http.request(request)
    puts response.code + " " + response.message
    puts response.body
  }
end

# Needs the UXF authorization token
def usage()
  # Required:
  cust_num = ENV["OPTUS_CUSTNUM"] # customer number
  account_num = ENV["OPTUS_CUSTNUM"] # account number
  sub_id = ENV["OPTUS_SUBID"] #subscription id

  url = "https://api.www.optus.com.au/mcssapi/rp-webapp-9-common/ebill/customer/#{cust_num}/shared-unbilled-usage-accumulators?account=#{account_num}&subscription=#{sub_id}"
  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  cookies = HTTP::Cookie.cookie_value($jar.cookies)
  # puts "Using following cookies for next request:"
  # puts cookies
  request["Cookie"] = cookies
  request["Accept"] = 'application/json, text/javascript, */*; q=0.01'
  request["Authorization"] = "UXF_SessionToken:where does this come from?"
  request["Authority"] = "www.optus.com.au"
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http|
    response = http.request(request)
    puts response.code + " " + response.message
    puts response.body
  }
end

login(username, userpass)
#my_account
#user_info
usage

