defmodule ExConfigSimple.Config do
  use ExConfig, otp_app: :ex_config_simple

  alias ExConfig.Type.{Boolean, Integer, String}

  env :auth_enabled, Boolean, default: false
  env :request_timeout, Integer, default: 10_000
  env :server_id, String, required: true

end
