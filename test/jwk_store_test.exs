defmodule JWKStoreTest do
  use ExUnit.Case, async: true
  doctest JWKStore

  @tag capture_log: true

  setup do
    {:ok, %{bypass: Bypass.open()}}
  end

  test "it works", %{bypass: bypass} do
    #
    # Setup testing environment
    #
    Bypass.stub(bypass, "GET", "/", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.put_resp_header("cache-control", "public, max-age=#{max_age()}, must-revalidate, no-transform")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(jwks())
      )
    end)

    #
    # Execute
    #
    uri = URI.parse("http://localhost:#{bypass.port}")
    {:ok, supervisor} = JWKStore.start_link(uri)

    #
    # Check
    #
    assert %{active: 2} = Supervisor.count_children(supervisor)
    assert div(JWKStore.get_millisec_to_next_update(), 1000) in (max_age() - 1)..(max_age() + 60)
    assert JWKStore.lookup("8c58e138614bd58742172bd5080d197d2b2dd2f3")
  end

  defp jwks do
    %{
      "keys" => [
        %{
          "kid" => "8c58e138614bd58742172bd5080d197d2b2dd2f3",
          "e" => "AQAB",
          "kty" => "RSA",
          "alg" => "RS256",
          "n" =>
            "yf3ymX8X1Q-vGALjH5eW56DQY2eJMoVzIn35IsxqSRpDEdoC-mp7EmC63feBp_1uRR9ITCwliuNYAV1yOmpSOstGDRknhp5mzmc_EovqDH4jwI_TWmsDMDZ7rHTKq5DFKzAVJlkk85OLbbt1PU1ZCF2eYtCzb57STrhvhmuAPgmoqROmNUKF5BcBQw7pvKqV2CjJRdKUmxs_zW9qNUYyDZaPYMfiloGjytsFsPp-lyQyxbXJoUbUD7jA6cUb3mOtzpROAgkYZyS740g-GZcVLapqAwC6UZxlCN-lXbGab7c-QrCMvDwfu2U3AQSvI38u95MabrjHZWsWRCbqJVfHIw",
          "use" => "sig"
        },
        %{
          "kid" => "ee4dbd06c06683cb48dddca6b88c3e473b6915b9",
          "e" => "AQAB",
          "kty" => "RSA",
          "alg" => "RS256",
          "n" =>
            "uNTSxjyvT0YtCoxUyEPahIq43tiK5lksGe5ZoE88AOJqXOLag5-wH1Ex5rsoQ628HhqtsEHmCQ2wT0-bl_Ol3EIAHLuCM0rmRiWevAEmDllpSldL2I3-lv_b-97BiRcW5KAAfF-0B_3zfNEGKF70l_iMDZ3j56IpDJwLDYma5C6Kh7r-fmoToKQTeasryoJWrDYlxqb_BC_egim_p5jLnc6cqY20ByVKdpnw7zok1-iLkl8nmEZMsznl-8KqVdZfk1NwPKKzMpTXvHvqC_9pgGFcwgvVpNZ6thk-L0UZs669hluHiq_eduSUHuwSgSpAtlloShPhJqj5tmRZ0P365Q",
          "use" => "sig"
        }
      ]
    }
  end

  defp max_age do
    22_431
  end
end
