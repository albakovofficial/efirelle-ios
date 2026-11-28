#!/usr/bin/env ruby
# frozen_string_literal: true

# Печатает следующий номер сборки: последний номер, загруженный в App Store Connect, плюс один.
# Первая сборка — 1, дальше 2, 3, 4… Неудачные запуски номер не тратят.
#
# Нужны переменные окружения: KEY_ID, ISSUER_ID, KEY_PATH (файл .p8), BUNDLE_ID.

require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

def base64url(data) = Base64.urlsafe_encode64(data, padding: false)

# Токен App Store Connect API (ES256, живёт 10 минут).
def token
  header = { alg: "ES256", kid: ENV.fetch("KEY_ID"), typ: "JWT" }
  now = Time.now.to_i
  payload = { iss: ENV.fetch("ISSUER_ID"), iat: now, exp: now + 600, aud: "appstoreconnect-v1" }
  signing_input = "#{base64url(header.to_json)}.#{base64url(payload.to_json)}"
  key = OpenSSL::PKey::EC.new(File.read(ENV.fetch("KEY_PATH")))
  der = key.sign(OpenSSL::Digest.new("SHA256"), signing_input)
  # JWT хранит подпись как r||s по 32 байта, а OpenSSL отдаёт её в DER.
  r, s = OpenSSL::ASN1.decode(der).value.map { |part| part.value.to_s(2).rjust(32, "\x00".b) }
  "#{signing_input}.#{base64url(r + s)}"
end

def get(path, params, auth)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  uri.query = URI.encode_www_form(params)
  request = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{auth}")
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
  abort "App Store Connect API: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

auth = token
bundle_id = ENV.fetch("BUNDLE_ID")
app = get("/v1/apps", { "filter[bundleId]" => bundle_id, "limit" => 1 }, auth)["data"].first
abort "Приложение #{bundle_id} не найдено в App Store Connect — создайте его в разделе «Приложения»." unless app

builds = get("/v1/builds", { "filter[app]" => app["id"], "fields[builds]" => "version", "limit" => 200 }, auth)["data"]
latest = builds.map { |build| build.dig("attributes", "version").to_i }.max || 0
puts latest + 1
