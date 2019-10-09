# JWKStore

Some JWT issuer(e.g. [google](https://developers.google.com/identity/protocols/OpenIDConnect)) refreshes JWK periodically.
To make you just use JWK without worrying about refreshing, this library handles refreshing JWK automatically.

Note: **Current status is experimental**.

## Usage

```elixir
uri = URI.parse("https://www.googleapis.com/oauth2/v3/certs")
{:ok, supervisor} = JWKStore.start_link(uri)
JWKStore.lookup("__input_kid_here__")
# %{
#   "alg" => "RS256",
#   "e" => "AQAB",
#   "kid" => "8c58e138614bd58742172bd5080d197d2b2dd2f3",
#   "kty" => "RSA",
#   "n" => "yf3ymX8X1Q-vGALjH5eW56DQY2eJMoVzIn35IsxqSRpDEdoC-mp7EmC63feBp_1uRR9ITCwliuNYAV1yOmpSOstGDRknhp5mzmc_EovqDH4jwI_TWmsDMDZ7rHTKq5DFKzAVJlkk85OLbbt1PU1ZCF2eYtCzb57STrhvhmuAPgmoqROmNUKF5BcBQw7pvKqV2CjJRdKUmxs_zW9qNUYyDZaPYMfiloGjytsFsPp-lyQyxbXJoUbUD7jA6cUb3mOtzpROAgkYZyS740g-GZcVLapqAwC6UZxlCN-lXbGab7c-QrCMvDwfu2U3AQSvI38u95MabrjHZWsWRCbqJVfHIw",
#   "use" => "sig"
# }
```

## Installation

```elixir
def deps do
  [
    {:jwk_store, github: "niku/jwk_store"}
  ]
end
```
